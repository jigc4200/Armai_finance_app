import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface AgentRequest {
  mensaje: string
  modo?: 'conversacional' | 'brutal'
  simulacion?: {
    descripcion: string
    monto: number
    cartera_id?: string
  }
}

interface AgentInsight {
  tipo_tarjeta: string
  titulo: string
  mensaje_corto: string
  accion_texto?: string
  icono?: string
}

interface AgentResult {
  respuesta: string
  insight: AgentInsight | null
}

serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response('Unauthorized', { status: 401 })
    }

    const token = authHeader.replace('Bearer ', '')
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY')!

    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: { headers: { Authorization: authHeader } },
    })

    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    if (authError || !user) {
      return new Response('Unauthorized', { status: 401 })
    }

    const { mensaje, modo = 'conversacional', simulacion }: AgentRequest = await req.json()

    const contexto = await obtenerContexto(supabase, user.id)

    const result = await llamarDeepSeek(mensaje, contexto, modo, simulacion)

    // Si la respuesta de la IA generó un insight válido, guardarlo en la base de datos
    if (result.insight) {
      try {
        // Desactivar insights anteriores del usuario
        await supabase
          .from('ai_insights')
          .update({ activa: false })
          .eq('user_id', user.id)

        // Insertar el nuevo insight activo
        await supabase
          .from('ai_insights')
          .insert({
            user_id: user.id,
            tipo_tarjeta: result.insight.tipo_tarjeta,
            titulo: result.insight.titulo,
            mensaje_corto: result.insight.mensaje_corto,
            accion_texto: result.insight.accion_texto || 'Revisar progreso',
            icono: result.insight.icono || 'psychology',
            activa: true
          })
      } catch (dbError) {
        console.error('Error al guardar el insight en base de datos:', dbError.message)
      }
    }

    return new Response(JSON.stringify(result), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

async function obtenerContexto(supabase: any, userId: string) {
  const [transacciones, carteras, metas] = await Promise.all([
    supabase.from('transactions')
      .select('*')
      .eq('user_id', userId)
      .order('fecha', { ascending: false })
      .limit(30),
    supabase.from('portfolios')
      .select('*')
      .eq('user_id', userId)
      .eq('activa', true),
    supabase.from('goals')
      .select('*')
      .eq('user_id', userId)
      .eq('completada', false),
  ])

  const carterasConROI = (carteras.data || []).map((c: any) => ({
    ...c,
    roi: c.total_invertido > 0
      ? ((c.total_retorno - c.total_invertido) / c.total_invertido * 100).toFixed(1)
      : 0,
  }))

  const totalIngresos = (transacciones.data || [])
    .filter((t: any) => t.tipo === 'ingreso')
    .reduce((s: number, t: any) => s + Number(t.monto), 0)

  const totalGastos = (transacciones.data || [])
    .filter((t: any) => t.tipo === 'gasto')
    .reduce((s: number, t: any) => s + Number(t.monto), 0)

  return {
    resumen: {
      total_ingresos: totalIngresos,
      total_gastos: totalGastos,
      balance: totalIngresos - totalGastos,
      total_transacciones: (transacciones.data || []).length,
    },
    carteras: carterasConROI,
    metas: metas.data || [],
    ultimas_transacciones: (transacciones.data || []).slice(0, 10),
  }
}

async function llamarDeepSeek(
  mensaje: string,
  contexto: any,
  modo: string,
  simulacion?: { descripcion: string; monto: number; cartera_id?: string }
): Promise<AgentResult> {
  const deepseekKey = Deno.env.get('DEEPSEEK_API_KEY')
  if (!deepseekKey) {
    return {
      respuesta: 'El agente no está disponible (falta configurar la API key).',
      insight: null
    }
  }

  let promptSistema = `Eres un copiloto financiero personal. Tu trabajo es analizar decisiones financieras, no solo gastos. Hablas directo, como un CFO personal, no como un chatbot motivacional.

Contexto del usuario:
- Balance del período: $${contexto.resumen.balance}
- Ingresos: $${contexto.resumen.total_ingresos}
- Gastos: $${contexto.resumen.total_gastos}
- Carteras activas: ${JSON.stringify(contexto.carteras)}
- Metas vigentes: ${JSON.stringify(contexto.metas)}
- Últimas 10 transacciones: ${JSON.stringify(contexto.ultimas_transacciones.map((t: any) => ({
    descripcion: t.descripcion,
    monto: t.monto,
    tipo: t.tipo,
    categoria: t.categoria,
    fecha: t.fecha,
  })))}

Responde siempre en español. Sé específico con números.
Cuando detectes un patrón negativo, nómbralo sin rodeos.
Cuando detectes una buena decisión, cuantifica el impacto.

IMPORTANTE: Tu respuesta DEBE ser exclusivamente un objeto JSON válido con la siguiente estructura:
{
  "respuesta": "La respuesta textual y completa en español, formateada con markdown. Aquí das los consejos de combate, análisis y explicaciones.",
  "insight": {
    "tipo_tarjeta": "plan_accion", // Opciones: "plan_accion", "alerta", "daily_briefing", "consejo"
    "titulo": "Título corto de la Bento Smart Card (ej: '🎯 Plan Activo: Ahorro para Auto')",
    "mensaje_corto": "Mensaje de máximo 150 caracteres para la Bento Smart Card (ej: 'Llevas $120 gastados. Tu límite sugerido es $150. ¡Ojo este fin de semana!')",
    "accion_texto": "Revisar progreso", // Texto del enlace de acción
    "icono": "car" // Icono alusivo. Opciones: "car", "trending_up", "warning", "auto_awesome", "emoji_events", "savings", "shopping_cart", "psychology"
  }
}

Si la consulta es conversacional común y no justifica cambiar el Dashboard con un plan activo o alerta relevante (por ejemplo, si el usuario dice 'hola', 'gracias', 'qué tal'), el campo 'insight' DEBE ser null.`

  if (modo === 'brutal') {
    promptSistema += `\n\nEstás en MODO BRUTAL. Sé especialmente directo y confrontacional. Usa los datos históricos del usuario para señalar patrones de comportamiento. No insultes, pero no suavices la verdad. Usa emojis solo cuando sea para enfatizar un punto.`
  }

  if (simulacion) {
    promptSistema += `\n\nEl usuario está simulando la siguiente compra:
- Descripción: ${simulacion.descripcion}
- Monto: $${simulacion.monto}
- Cartera: ${simulacion.cartera_id || 'Sin cartera'}

Analizá el impacto de esta compra en su balance, metas y carteras. Decí si es una buena o mala decisión basándote en sus datos históricos.`
  }

  try {
    const response = await fetch('https://api.deepseek.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${deepseekKey}`,
      },
      body: JSON.stringify({
        model: 'deepseek-chat',
        messages: [
          { role: 'system', content: promptSistema },
          { role: 'user', content: mensaje },
        ],
        temperature: modo === 'brutal' ? 0.8 : 0.5,
        max_tokens: 1000,
        response_format: { type: 'json_object' }
      }),
    })

    const data = await response.json()
    const rawContent = data.choices?.[0]?.message?.content || '{}'
    
    return parsearRespuestaIA(rawContent)
  } catch (e) {
    return {
      respuesta: `Error al conectar con el agente: ${e.message}`,
      insight: null
    }
  }
}

function parsearRespuestaIA(contenido: string): AgentResult {
  try {
    let textoLimpio = contenido.trim()
    if (textoLimpio.startsWith('```json')) {
      textoLimpio = textoLimpio.substring(7)
    } else if (textoLimpio.startsWith('```')) {
      textoLimpio = textoLimpio.substring(3)
    }
    if (textoLimpio.endsWith('```')) {
      textoLimpio = textoLimpio.substring(0, textoLimpio.length - 3)
    }
    textoLimpio = textoLimpio.trim()
    
    const parsed = JSON.parse(textoLimpio)
    return {
      respuesta: parsed.respuesta || contenido,
      insight: parsed.insight || null
    }
  } catch (err) {
    console.error('Error al parsear JSON del LLM:', err, 'Contenido:', contenido)
    return {
      respuesta: contenido,
      insight: null
    }
  }
}
