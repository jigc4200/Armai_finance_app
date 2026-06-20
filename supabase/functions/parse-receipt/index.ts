import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'

interface ParseRequest {
  rawText: string
}

interface ParseResponse {
  monto: number | null
  fecha: string | null
  comercio: string | null
  categoria: string | null
  tipo: 'ingreso' | 'gasto'
}

serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  try {
    const { rawText }: ParseRequest = await req.json()

    if (!rawText || rawText.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: 'rawText es requerido' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const deepseekKey = Deno.env.get('DEEPSEEK_API_KEY')
    if (!deepseekKey) {
      return await fallbackParse(rawText)
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
            {
              role: 'system',
              content: `Eres un extractor de datos de recibos y facturas LATAM.
Analiza el texto OCR y devuelve SOLO un JSON con:
- monto: número (null si no se detecta)
- fecha: string ISO (null si no se detecta)
- comercio: string (null si no se detecta)
- categoria: string (una de: Comida, Transporte, Vivienda, Salud, Educación, Entretenimiento, Ropa, Tecnología, Hogar, Servicios, General)
- tipo: "gasto" (default)

Responde ÚNICAMENTE el JSON, sin explicaciones.`,
            },
            { role: 'user', content: rawText },
          ],
          temperature: 0.1,
          max_tokens: 200,
        }),
      })

      const data = await response.json()
      const content = data.choices?.[0]?.message?.content

      if (content) {
        const jsonMatch = content.match(/\{.*\}/s)
        if (jsonMatch) {
          const parsed = JSON.parse(jsonMatch[0])
          return new Response(JSON.stringify(parsed), {
            headers: { 'Content-Type': 'application/json' },
          })
        }
      }
    } catch (_e) {
      // fallback si falla DeepSeek
    }

    return await fallbackParse(rawText)
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

async function fallbackParse(rawText: string): Promise<Response> {
  const lines = rawText.split('\n').map(l => l.trim().toLowerCase())
  let monto: number | null = null
  let fecha: string | null = null
  let comercio: string | null = null

  for (const line of lines) {
    if (!comercio && line.length > 3 && !line.match(/^\d/)) {
      comercio = line.charAt(0).toUpperCase() + line.slice(1)
    }

    const amountMatch = line.match(/(?:total|importe|monto|\$)\s*:?\s*\$?\s*(\d+[.,]\d{2})/)
    if (amountMatch) {
      monto = parseFloat(amountMatch[1].replace(',', '.'))
    }

    if (!monto) {
      const simpleMatch = line.match(/(\d+[.,]\d{2})\s*$/)
      if (simpleMatch) {
        monto = parseFloat(simpleMatch[1].replace(',', '.'))
      }
    }

    const dateMatch = line.match(/(\d{1,2})[\/-](\d{1,2})[\/-](\d{2,4})/)
    if (dateMatch) {
      const d = parseInt(dateMatch[1])
      const m = parseInt(dateMatch[2])
      let y = parseInt(dateMatch[3])
      if (y < 100) y += 2000
      fecha = `${y}-${String(m).padStart(2, '0')}-${String(d).padStart(2, '0')}`
    }
  }

  return new Response(JSON.stringify({
    monto,
    fecha,
    comercio,
    categoria: 'General',
    tipo: 'gasto',
  }), {
    headers: { 'Content-Type': 'application/json' },
  })
}
