import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req: Request) => {
  try {
    const telegramToken = Deno.env.get('TELEGRAM_BOT_TOKEN')
    if (!telegramToken) {
      return new Response('Telegram Token not configured', { status: 500 })
    }

    const payload = await req.json()
    console.log('Webhook payload received:', JSON.stringify(payload))

    // Validar que sea un mensaje de texto de Telegram
    if (!payload.message || !payload.message.text) {
      return new Response('OK', { status: 200 })
    }

    const chat_id = payload.message.chat.id
    const text = payload.message.text.trim()

    // Instanciar cliente de Supabase con Service Role Key para poder gestionar usuarios y transacciones
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Comando /start
    if (text.startsWith('/start')) {
      await enviarMensajeTelegram(telegramToken, chat_id, 
        '¡Hola! Soy tu Copiloto Financiero Omnicanal 🤖.\n\n' +
        'Para registrar tus gastos por aquí, primero vincula tu cuenta enviando tu correo registrado así:\n' +
        '/email tu-correo@ejemplo.com'
      )
      return new Response('OK', { status: 200 })
    }

    // Comando /email
    if (text.startsWith('/email')) {
      const email = text.replace('/email', '').trim()
      if (!email || !email.includes('@')) {
        await enviarMensajeTelegram(telegramToken, chat_id, '❌ Correo inválido. Envía: /email tu-correo@ejemplo.com')
        return new Response('OK', { status: 200 })
      }

      // Buscar el usuario por email
      const { data: user, error: userError } = await supabase
        .from('users')
        .select('id')
        .eq('email', email)
        .maybeSingle()

      if (userError || !user) {
        await enviarMensajeTelegram(telegramToken, chat_id, '❌ No encontré ningún usuario registrado con ese correo en la aplicación.')
        return new Response('OK', { status: 200 })
      }

      // Crear o actualizar la vinculación
      const { error: linkError } = await supabase
        .from('user_telegram_links')
        .upsert({ telegram_chat_id: chat_id, user_id: user.id })

      if (linkError) {
        await enviarMensajeTelegram(telegramToken, chat_id, '❌ Error al vincular tu cuenta. Intenta más tarde.')
        return new Response('OK', { status: 200 })
      }

      await enviarMensajeTelegram(telegramToken, chat_id, '🎉 ¡Vinculación exitosa! Ya puedes enviarme tus gastos o ingresos en texto natural (ej: "gasté 5000 en comida" o "ingreso 2000 Sueldo").')
      return new Response('OK', { status: 200 })
    }

    // Si no es un comando de inicio, procesamos el mensaje como transacción
    // 1. Obtener la vinculación del chat_id
    const { data: link, error: linkError } = await supabase
      .from('user_telegram_links')
      .select('user_id')
      .eq('telegram_chat_id', chat_id)
      .maybeSingle()

    if (linkError || !link) {
      await enviarMensajeTelegram(telegramToken, chat_id, '❌ Tu chat de Telegram no está vinculado. Por favor envía primero: /email tu-correo@ejemplo.com')
      return new Response('OK', { status: 200 })
    }

    const userId = link.user_id

    // 2. Procesar el texto con la IA (DeepSeek V3) para parsear el gasto/ingreso
    await enviarMensajeTelegram(telegramToken, chat_id, '🤔 Analizando tu mensaje...')
    const transaccionParseada = await parsearTransaccionConIA(text)

    if (!transaccionParseada || transaccionParseada.monto <= 0) {
      await enviarMensajeTelegram(telegramToken, chat_id, '❌ No pude identificar un monto o tipo de transacción válido en tu mensaje. Intenta con algo más claro (ej: "gasté $4500 en transporte").')
      return new Response('OK', { status: 200 })
    }

    // 3. Insertar la transacción en Supabase
    const { error: insertError } = await supabase
      .from('transactions')
      .insert({
        user_id: userId,
        monto: transaccionParseada.monto,
        tipo: transaccionParseada.tipo,
        categoria: transaccionParseada.categoria,
        descripcion: transaccionParseada.descripcion,
        fecha: new Date().toISOString().split('T')[0],
        fuente: 'email' // Marcar como origen externo
      })

    if (insertError) {
      console.error('Error al insertar transacción:', insertError.message)
      await enviarMensajeTelegram(telegramToken, chat_id, '❌ Error al guardar la transacción en la base de datos.')
      return new Response('OK', { status: 200 })
    }

    // 4. Responder con éxito
    const tipoEmoji = transaccionParseada.tipo === 'ingreso' ? '💰' : '💸'
    const mensajeExito = `✅ *¡Transacción Registrada!*\n\n` +
      `${tipoEmoji} *Detalle:* ${transaccionParseada.tipo.toUpperCase()}\n` +
      `💵 *Monto:* $${transaccionParseada.monto.toFixed(2)}\n` +
      `🏷️ *Categoría:* ${transaccionParseada.categoria}\n` +
      `📝 *Descripción:* ${transaccionParseada.descripcion}`

    await enviarMensajeTelegram(telegramToken, chat_id, mensajeExito)

    return new Response('OK', { status: 200 })
  } catch (error) {
    console.error('Webhook error:', error.message)
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})

async function enviarMensajeTelegram(token: string, chat_id: number, texto: string) {
  try {
    await fetch(`https://api.telegram.org/bot${token}/sendMessage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chat_id: chat_id,
        text: texto,
        parse_mode: 'Markdown'
      })
    })
  } catch (e) {
    console.error('Error al enviar mensaje a Telegram:', e.message)
  }
}

async function parsearTransaccionConIA(mensaje: string) {
  const deepseekKey = Deno.env.get('DEEPSEEK_API_KEY')
  if (!deepseekKey) return null

  const promptSistema = `Eres un procesador de lenguaje natural financiero. Tu único objetivo es leer el mensaje del usuario y extraer la información en un formato JSON estructurado.

Debes categorizar el movimiento en una de las siguientes opciones:
- General
- Comida
- Transporte
- Vivienda
- Salud
- Educación
- Entretenimiento
- Ropa
- Tecnología
- Hogar
- Servicios

Responde exclusivamente con el siguiente objeto JSON válido:
{
  "monto": 1500.50, // número decimal del monto
  "tipo": "gasto", // "gasto" o "ingreso"
  "categoria": "Comida", // Debe ser exactamente una de la lista provista
  "descripcion": "Almuerzo de trabajo" // Breve descripción o comercio
}

Si el mensaje no contiene un monto o no es una transacción financiera, retorna {"monto": 0, "tipo": "gasto", "categoria": "General", "descripcion": ""}`

  try {
    const response = await fetch('https://api.deepseek.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${deepseekKey}`
      },
      body: JSON.stringify({
        model: 'deepseek-chat',
        messages: [
          { role: 'system', content: promptSistema },
          { role: 'user', content: mensaje }
        ],
        temperature: 0.1,
        response_format: { type: 'json_object' }
      })
    })

    const data = await response.json()
    const content = data.choices?.[0]?.message?.content || '{}'
    return JSON.parse(content)
  } catch (e) {
    console.error('Error al parsear con DeepSeek:', e.message)
    return null
  }
}
