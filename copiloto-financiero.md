# Copiloto Financiero — Documento Maestro del Proyecto

> **La pregunta central del producto:**
> ¿Qué decisiones financieras de mi vida realmente aumentaron mi patrimonio y cuáles solo parecían inversiones?

---

## Índice

1. [Visión del producto](#1-visión-del-producto)
2. [Stack tecnológico](#2-stack-tecnológico)
3. [Modelo de datos](#3-modelo-de-datos)
4. [Arquitectura de la IA](#4-arquitectura-de-la-ia)
5. [Roadmap por fases](#5-roadmap-por-fases)
6. [Seguridad](#6-seguridad)
7. [Gamificación](#7-gamificación)
8. [Metas y KPIs](#8-metas-y-kpis)
9. [Riesgos y mitigaciones](#9-riesgos-y-mitigaciones)
10. [Reglas del proyecto](#10-reglas-del-proyecto)
11. [Anexo — Arquitectura patrimonial proactiva](#11-anexo--arquitectura-patrimonial-proactiva)
12. [Anexo — Artesanía móvil y sprint pro](#12-anexo--artesanía-móvil-y-sprint-pro)

---

## 1. Visión del producto

### Qué es

Una app móvil (iOS + Android) que actúa como copiloto financiero personal. No es una app de presupuesto. No es un tracker de gastos. Es un **analizador de decisiones financieras**.

### Qué NO es (v1)

- ❌ Conexión bancaria automática
- ❌ Criptomonedas o trading
- ❌ Presupuestos al estilo YNAB
- ❌ Multiusuario o cuentas familiares
- ❌ Planificación fiscal
- ❌ Integraciones con 50 servicios

### Propuesta de valor única

Ningún competidor actual (YNAB, Copilot Money, Fintonic) responde la pregunta del ROI personal. Todos responden "¿cuánto gasté?". Este producto responde "¿qué decisiones me hicieron ganar dinero?".

---

## 2. Stack tecnológico

### Frontend
| Tecnología | Rol |
|---|---|
| Flutter | App iOS + Android desde un solo codebase |
| Riverpod | Gestión de estado |
| Go Router | Navegación |
| FL Chart | Gráficos y visualizaciones |

### Backend
| Tecnología | Rol |
|---|---|
| Supabase | BaaS principal (auth, DB, storage, edge functions) |
| PostgreSQL | Base de datos relacional |
| Row Level Security | Aislamiento de datos por usuario |
| Supabase Edge Functions | Lógica serverless + proxy de IA |

### Inteligencia artificial
| Tecnología | Rol |
|---|---|
| **DeepSeek V3** | Agente financiero principal (MVP) |
| Google ML Kit (on-device) | OCR de facturas y recibos |
| Embeddings (DeepSeek) | Clasificación automática de transacciones |

> **Nota de migración:** DeepSeek es la elección del MVP por costo (~$0.27/1M tokens input vs $3.00 de Claude Sonnet). La llamada a la IA SIEMPRE pasa por una Edge Function. Cambiar de modelo en el futuro = cambiar una variable de entorno, sin tocar Flutter.

### Infraestructura
| Tecnología | Rol |
|---|---|
| Supabase Storage | Almacenamiento de imágenes de recibos (buckets privados) |
| Firebase FCM | Push notifications |
| Sentry | Crashlytics y monitoreo de errores |
| RevenueCat | Gestión de suscripciones _(Fase 3)_ |

---

## 3. Modelo de datos

### Entidades principales

```sql
-- Usuarios
users
  id              uuid PRIMARY KEY
  email           text UNIQUE
  nivel           integer DEFAULT 1
  xp              integer DEFAULT 0
  created_at      timestamptz

-- Transacciones (núcleo del sistema)
transactions
  id              uuid PRIMARY KEY
  user_id         uuid REFERENCES users(id)
  monto           numeric(12,2)
  tipo            text  -- 'ingreso' | 'gasto'
  categoria       text
  cartera_id      uuid REFERENCES portfolios(id)
  descripcion     text
  fecha           date
  fuente          text  -- 'manual' | 'ocr' | 'email'
  imagen_url      text  -- URL firmada al recibo (si aplica)
  meta_id         uuid REFERENCES goals(id)  -- opcional
  created_at      timestamptz

-- Carteras de inversión personal
portfolios
  id              uuid PRIMARY KEY
  user_id         uuid REFERENCES users(id)
  nombre          text  -- "Laptop IA", "Finca Café", "Educación"
  tipo            text  -- 'activo' | 'gasto_recurrente' | 'proyecto'
  total_invertido numeric(12,2) DEFAULT 0
  total_retorno   numeric(12,2) DEFAULT 0
  roi_calculado   numeric(6,2)  -- porcentaje
  activa          boolean DEFAULT true
  created_at      timestamptz

-- Metas financieras
goals
  id              uuid PRIMARY KEY
  user_id         uuid REFERENCES users(id)
  nombre          text  -- "Llegar a $15,000", "Comprar terreno"
  monto_objetivo  numeric(12,2)
  monto_actual    numeric(12,2) DEFAULT 0
  fecha_objetivo  date
  completada      boolean DEFAULT false
  created_at      timestamptz

-- Logros desbloqueados
achievements
  id              uuid PRIMARY KEY
  user_id         uuid REFERENCES users(id)
  tipo            text  -- slug del logro
  desbloqueado_en timestamptz
  mostrado        boolean DEFAULT false
```

### Reglas de Row Level Security (RLS)

Cada tabla debe tener una política RLS que garantice:

```sql
-- Ejemplo para transactions
CREATE POLICY "usuarios solo ven sus transacciones"
ON transactions FOR ALL
USING (auth.uid() = user_id);
```

Aplicar el mismo patrón a `portfolios`, `goals`, `achievements`.

---

## 4. Arquitectura de la IA

### Principio fundamental

> La clave de API de DeepSeek **NUNCA** llega al cliente Flutter. Siempre pasa por una Edge Function de Supabase.

### Flujo de una consulta al agente

```
Flutter  →  POST /functions/v1/agente  →  Edge Function  →  DeepSeek API
                                              ↑
                                     Lee contexto de Supabase
                                     (últimas 30 transacciones,
                                      carteras activas, metas)
```

### Estructura del prompt del agente

La Edge Function construye el contexto así:

```javascript
const sistemaPrompt = `
Eres un copiloto financiero personal. Tu trabajo es analizar decisiones financieras,
no solo gastos. Hablas directo, como un CFO personal, no como un chatbot motivacional.

Contexto del usuario:
- Nivel actual: ${usuario.nivel}
- Carteras activas: ${JSON.stringify(carteras)}
- Metas vigentes: ${JSON.stringify(metas)}
- Últimas 30 transacciones: ${JSON.stringify(transacciones)}
- ROI por cartera: ${JSON.stringify(roi)}

Responde siempre en español. Sé específico con números. 
Cuando detectes un patrón negativo, nómbralo sin rodeos.
Cuando detectes una buena decisión, cuantifica el impacto.
`;
```

### Dos modos del agente

| Modo | Cuándo | Ejemplo de output |
|---|---|---|
| **Conversacional** | El usuario pregunta algo | "Tu mejor inversión histórica ha sido educación. ROI de +340%." |
| **Brutal (opt-in)** | Antes de registrar un gasto | "Compraste otro gadget. Tus gadgets tienen ROI histórico de -78%. Estadísticamente estás repitiendo un error." |

### OCR — flujo de captura

```
Foto del recibo (Flutter)
  → ML Kit on-device extrae texto
  → Se envía texto a Edge Function
  → DeepSeek parsea: monto, fecha, comercio, categoría sugerida
  → Se muestra al usuario para confirmar/editar
  → Se guarda en transactions con fuente = 'ocr'
```

---

## 5. Roadmap por fases

### Fase 1 — Núcleo funcional (Semanas 1–4)

**Semana 1: Fundación**
- [ ] Proyecto Flutter creado con estructura de carpetas limpia
- [ ] Supabase configurado (proyecto, tablas, RLS)
- [ ] Autenticación: magic link + biometría
- [ ] CRUD básico de transacciones (ingresos y gastos)
- [ ] Modelo de datos completo aplicado desde el día 1

**Semana 2: Carteras y metas**
- [ ] Pantalla de carteras con creación y edición
- [ ] Asignación de transacciones a carteras
- [ ] Pantalla de metas con barra de progreso
- [ ] Dashboard principal: balance, últimas transacciones, resumen por cartera

**Semana 3: OCR**
- [ ] Integración de Google ML Kit
- [ ] Flujo de captura: foto → texto → confirmación → guardado
- [ ] Clasificación automática vía DeepSeek (categoría sugerida)
- [ ] Vista de revisión post-OCR (siempre editable)

**Semana 4: Agente IA**
- [ ] Edge Function del agente con contexto financiero
- [ ] Chat dentro de la app (sin historial persistente en v1)
- [ ] Simulación de compras: "¿Qué pasa si compro esto?"
- [ ] Cálculo de ROI por cartera
- [ ] Primeras recomendaciones automáticas en dashboard

**Milestone Fase 1:** App funcional con OCR, carteras, metas y agente. Lista para beta privada con 10 usuarios reales.

---

### Fase 2 — Diferenciación (Semanas 5–8)

**Semana 5: Sistema de niveles**
- [ ] Lógica de XP: qué acciones dan puntos
- [ ] Tabla de niveles (ver sección Gamificación)
- [ ] Perfil de usuario con nivel visible
- [ ] Animación de subida de nivel

**Semana 6: Logros y modo brutal**
- [ ] Sistema de logros (ver lista en sección Gamificación)
- [ ] Notificaciones inteligentes (no spam, solo insights relevantes)
- [ ] Modo brutal como opción opt-in en configuración
- [ ] Test con usuarios beta: ¿el feedback se siente útil o condescendiente?

**Semana 7: Jefe Final**
- [ ] Vista de "campaña": meta principal como boss final
- [ ] Barra de progreso estilo videojuego
- [ ] Historial de ROI por decisión (timeline)
- [ ] "Momentos de quiebre": puntos en el tiempo donde una decisión cambió la trayectoria

**Semana 8: Pulir y lanzar**
- [ ] Onboarding completo (debe generar primer insight en menos de 5 minutos)
- [ ] UX review completa con usuarios beta
- [ ] Corrección de bugs críticos
- [ ] Publicación en TestFlight / Google Play Internal

**Milestone Fase 2:** Producto completo con diferenciación. Listo para lanzamiento público v1.0.

---

### Fase 3 — Monetización (Semanas 9–12)

- [ ] Definir límites del plan free vs premium
- [ ] Integrar RevenueCat (App Store + Play Store)
- [ ] Paywall en puntos de fricción natural (no al abrir la app)
- [ ] Analytics de uso (PostHog o similar, privacy-first)
- [ ] Reportes exportables en PDF
- [ ] Widgets nativos iOS y Android

**Milestone Fase 3:** Primera transacción real de un usuario pagando. MRR > $0.

---

### Fase 4 — Escala (post-validación, Mes 4+)

Solo construir si hay demanda real validada:

- [ ] Conexión bancaria automática (Belvo para LATAM)
- [ ] Multiusuario / finanzas de pareja o familia
- [ ] Migración del agente a Claude Haiku o Sonnet (si el MRR lo justifica)
- [ ] Web app complementaria
- [ ] Exportación a Excel / Google Sheets

---

## 6. Seguridad

### Capas de seguridad — MVP obligatorio

| Capa | Implementación | Cuándo |
|---|---|---|
| Autenticación | Supabase Auth (JWT de corta duración + refresh rotativo) | Semana 1 |
| Aislamiento de datos | Row Level Security en todas las tablas | Semana 1 |
| Biometría | Face ID / Fingerprint como segunda capa en Flutter | Semana 1 |
| API de IA | Clave nunca en el cliente, siempre Edge Function | Semana 4 |
| Imágenes de recibos | Bucket privado + URLs firmadas de corta duración (15 min) | Semana 3 |
| Tránsito | HTTPS/TLS obligatorio, sin excepciones | Siempre |

### Seguridad del agente IA

```javascript
// CORRECTO: el agente solo recibe datos del usuario autenticado
const { data: { user } } = await supabase.auth.getUser(token)
const contexto = await obtenerContexto(user.id)  // solo sus datos

// INCORRECTO (nunca hacer esto):
const contexto = await obtenerContextoGlobal()  // datos de todos
```

### Para Fase 2

- Política de privacidad: los datos NO se usan para entrenar modelos
- Botón de eliminación de cuenta con borrado real en cascada
- Exportación de datos bajo demanda (GDPR-ready)
- Rate limiting en Edge Functions
- Monitoreo de anomalías con Sentry

---

## 7. Gamificación

### Sistema de niveles

| Nivel | Nombre | XP requerido |
|---|---|---|
| 1 | Gastador Novato | 0 |
| 3 | Rastreador | 500 |
| 5 | Administrador | 1,500 |
| 8 | Optimizador | 4,000 |
| 10 | Constructor de Patrimonio | 8,000 |
| 15 | Estratega | 20,000 |
| 20 | Magnate | 50,000 |

### Acciones que dan XP

| Acción | XP |
|---|---|
| Registrar una transacción | +5 |
| Usar OCR | +10 |
| Completar una meta | +200 |
| Rechazar una compra impulsiva (simulación) | +50 |
| 30 días de racha activa | +100 |
| Primera cartera con ROI positivo | +150 |

### Logros

| Logro | Condición |
|---|---|
| 🏆 Primer mes positivo | Balance positivo al cerrar el mes |
| 🏆 Fondo de emergencia completo | Meta de emergencia al 100% |
| 🏆 Primera cartera rentable | ROI de alguna cartera > 0% |
| 🏆 ROI superior al 100% | Alguna cartera supera el 100% de retorno |
| 🏆 90 días sin compras impulsivas | 90 días sin confirmar una compra que el agente marcó como patrón negativo |
| 🏆 Decisión de un millón | Una cartera acumula retorno > $1,000 |
| 🏆 Racha de 30 días | 30 días consecutivos registrando al menos una transacción |

### Jefe Final (meta principal)

La meta más importante del usuario se muestra como campaña de videojuego:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 JEFE FINAL: Terreno propio
 Objetivo: $25,000
 ████████░░░░░░░░░░░░  38%
 Faltan: $15,500
 A tu ritmo actual: 14 meses
 Si ahorras $200 más/mes: 11 meses
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Modo brutal (opt-in, off por defecto)

Activado por el usuario en configuración. El agente puede decir:

```
Compraste otro gadget.
Tus gadgets han generado un ROI histórico de -78%.
Estadísticamente estás repitiendo un error.
```

o bien:

```
Felicidades.
Rechazaste una compra impulsiva de $400.
Acabas de adelantar tu meta principal 9 días.
```

**Regla de implementación:** nunca insultar, siempre usar datos históricos del propio usuario. El modo brutal es un espejo, no un juez.

---

## 8. Metas y KPIs

### KPIs de producto (no vanidad)

| KPI | Objetivo Semana 4 | Objetivo Mes 3 |
|---|---|---|
| Usuarios beta activos | 10 | 50 |
| Transacciones registradas/usuario/semana | 3+ | 5+ |
| Retención semana 2 | — | 40% |
| Satisfacción con respuestas del agente | — | 70% "útil" |

### Las 4 puertas de validación

Antes de avanzar a cada fase, validar la puerta correspondiente:

**Puerta 1 (al final Semana 4):** ¿La gente registra transacciones sin que se lo pidas?
- Métrica: 3+ registros sin reminder en semana 2 de uso.
- Si falla: problema de hábito, rediseñar onboarding antes de continuar.

**Puerta 2 (al final Semana 6):** ¿El agente da respuestas útiles?
- Métrica: 70% de respuestas calificadas como útiles (thumbs up en la app).
- Si falla: mejorar el prompt y el contexto antes de agregar features.

**Puerta 3 (al final Semana 8):** ¿Alguien cambió un comportamiento financiero?
- Métrica: al menos 1 usuario reporta haber rechazado una compra gracias al copiloto.
- Si falla: la propuesta central no está funcionando. Investigar antes de monetizar.

**Puerta 4 (al final Mes 3):** ¿Alguien pagaría por esto?
- Métrica: 5% de usuarios beta dispuestos a pagar $5–10/mes.
- Si falla: NO construir Fase 3 todavía. Volver a investigar.

### La métrica estrella

> ¿Cuántos usuarios cambiaron una decisión financiera gracias al copiloto?

Esta es la única métrica que importa para evaluar si el producto tiene sentido.

---

## 9. Riesgos y mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Feature creep | Alta | Alto | Cada semana revisar el plan. Lo que no cabe en el milestone actual va a lista "post-validación" y se congela. |
| OCR con baja precisión en facturas LATAM | Media | Alto | Siempre permitir edición manual post-OCR. Si tasa de corrección >30%, invertir en mejorar el modelo. |
| Costo de API de IA se dispara | Media | Medio | Cachear resúmenes financieros. Límite de tokens por usuario en plan free. Modelos baratos para clasificación, DeepSeek para el agente. |
| Baja retención en semana 2 | Media | Alto | El onboarding debe generar primer insight en <5 min. Si el usuario no registra 3+ transacciones en día 1, notificación inteligente al día 3. |
| Modo brutal genera rechazo | Baja | Medio | Opt-in explícito. Testear con beta users antes de activar. Siempre basado en datos del propio usuario, nunca como juicio externo. |
| Competencia de apps establecidas | Baja | Bajo | La diferenciación es el ROI personal. Ningún competidor lo responde. Mantener ese foco sin distracción. |

---

## 10. Reglas del proyecto

Estas reglas son no negociables durante las Fases 1 y 2:

1. **No agregar features no planificadas.** Si surge una idea, va al backlog, no al sprint actual.

2. **La clave de IA nunca en el cliente.** Siempre Edge Function como proxy.

3. **RLS desde el día 1.** No es algo que se agrega después.

4. **El OCR siempre tiene revisión manual.** Nunca guardar automáticamente sin confirmación del usuario.

5. **El modo brutal es opt-in.** Nunca se activa sin que el usuario lo pida explícitamente.

6. **Una puerta a la vez.** No se avanza de fase sin validar la puerta correspondiente.

7. **El modelo de datos no cambia después de la Semana 1.** Si necesita cambiar, es señal de que falta pensar antes de codificar.

8. **No hay conexión bancaria en v1.** Sin excepciones. Es una distracción enorme para este momento.

---

## 11. Anexo — Arquitectura patrimonial proactiva

Este anexo reemplaza el enfoque de "registro básico" como ambición de producto. El registro sigue siendo necesario, pero su papel es alimentar un analizador patrimonial proactivo: menos captura manual, más auditoría, más trazabilidad de decisiones y más recomendaciones accionables.

### 11.1 Motor de Auditoría Forense y Captura

**Objetivo:** eliminar fricción de entrada y maximizar el valor de cada recibo, comprobante o mensaje procesado.

#### Ingesta cero-fricción vía bot de Telegram

El bot de Telegram debe evolucionar de registrar mensajes de texto simples a un canal de captura omnicanal. El usuario puede reenviar capturas de pantalla, comprobantes de pago o audios rápidos. El bot actúa como webhook hacia Supabase, y una Edge Function procesa el contenido con DeepSeek para extraer datos estructurados en segundo plano.

Estado actual del repo:

- `supabase/migrations/004_telegram_bot.sql` ya vincula `telegram_chat_id` con `user_id`.
- `supabase/functions/telegram-bot/index.ts` ya procesa texto natural, vincula cuentas por `/email`, usa DeepSeek y guarda una transacción.
- La implementación actual marca el origen externo como `fuente = 'email'`, aunque el canal real sea Telegram.

Ajuste requerido:

- Separar la captura externa en estados: recibido, parseado, pendiente de revisión, aprobado, rechazado.
- Soportar archivos, imágenes y audios además de texto.
- Agregar una fuente explícita `telegram` o una tabla de ingestión para no sobrecargar `transactions`.
- No guardar automáticamente transacciones ambiguas; enviarlas a revisión asistida.

#### Auditor forense de inflación

El OCR debe pasar de detectar solo monto, fecha, comercio y categoría a guardar detalle por producto. Los recibos de supermercado o comercio local deben producir line items con nombre, cantidad, precio unitario, precio total y confianza del parseo.

El objetivo es comparar precios históricos del mismo usuario y detectar:

- Inflación silenciosa por producto.
- Cobros recurrentes disfrazados.
- Cambios de precio anómalos en comercios frecuentes.
- Categorías donde el gasto sube sin que el usuario lo perciba.

Ajuste requerido:

- La tabla `transactions` necesita soporte para line items en `jsonb`, o una tabla dedicada `transaction_line_items` si se necesita consulta fina por producto.
- `supabase/functions/parse-receipt/index.ts` debe devolver un JSON más rico con `line_items`.
- El pipeline debe comparar el JSON extraído contra el historial del usuario antes de guardar o generar un `ai_insight`.

#### Revisión asistida rápida

La app debe tener una interfaz de aprobación por lotes para capturas de OCR y Telegram. La revisión debe permitir aprobar, editar o rechazar con mínima fricción.

Ajuste requerido:

- Crear un flujo de "bandeja de revisión" en Flutter para transacciones pendientes.
- Usar gestos rápidos como swipe to approve cuando el parseo tenga alta confianza.
- Mantener edición manual obligatoria para casos ambiguos, siguiendo la regla del proyecto: OCR nunca guarda sin confirmación.

### 11.2 Trazabilidad de Decisiones y ROI

**Objetivo:** responder directamente la pregunta central del producto con líneas de tiempo de impacto, no con gráficos de pastel tradicionales.

#### Clasificación "Gasto vs. Decisión Estratégica"

Cuando el usuario registra un movimiento fuerte, puede etiquetarlo como una decisión estratégica: comprar equipo técnico, pagar educación, invertir en un negocio, mejorar infraestructura, lanzar un proyecto.

Ajuste requerido:

- Agregar un concepto explícito de decisión. Puede empezar como campos en `transactions`, pero a mediano plazo conviene una tabla `decisions` vinculada con `transactions` y `portfolios`.
- Distinguir movimientos operativos de decisiones con potencial de retorno.
- Permitir que una decisión esté conectada a una cartera, una meta o ambas.

#### Línea de tiempo de retorno

El producto debe mostrar cuándo una decisión se pagó a sí misma. Usando FL Chart, la app puede enlazar ingresos futuros a una decisión inicial y mostrar el mes de break-even, la ganancia neta acumulada y el impacto en patrimonio.

Ajuste requerido:

- Definir cómo se atribuyen ingresos futuros a una decisión.
- Guardar relaciones entre transacciones de egreso inicial, ingresos posteriores y cartera asociada.
- Crear un componente visual de línea de tiempo de ROI en vez de depender solo de resúmenes estáticos.

#### Re-clasificación implacable de la IA

Si una inversión lleva 6 meses sin retorno en `portfolios`, la IA debe generar una tarjeta en el dashboard sugiriendo auditar esa cartera y asumir la pérdida si corresponde.

Ajuste requerido:

- Crear una tarea programada o Edge Function que evalúe carteras sin retorno.
- Insertar tarjetas en `ai_insights` con tipo `alerta` o `plan_accion`.
- Mantener el tono basado en datos propios del usuario, especialmente si está activo el modo brutal.

### 11.3 Cuarto de Guerra Predictivo

**Objetivo:** convertir el agente en un CFO personal que corre simulaciones antes de que el usuario actúe.

#### Simulador de escenarios

El chat ya soporta `simulacion` desde `agent_chat_screen.dart` y `supabase/functions/agente/index.ts`. La evolución natural es que el agente calcule impacto exacto sobre flujo de caja, carteras y `Jefe Final`.

Ejemplo de salida esperada:

```text
Esta compra retrasará tu Meta Principal en 3.5 meses.
```

Ajuste requerido:

- Calcular ritmo mensual real con transacciones recientes.
- Proyectar fecha objetivo antes y después de la compra.
- Enviar al agente números ya calculados, no pedirle que invente la matemática.

#### Tarjetas de acción proactivas

El dashboard debe pivotar de saldo estático a feed predictivo. La tabla `ai_insights` ya permite tarjetas activas; debe convertirse en el canal principal para alertas asíncronas.

Ejemplo:

```text
Riesgo alto de sobregiro en tu cartera "Operaciones" para fin de mes basado en tu ritmo actual.
```

Ajuste requerido:

- Generar insights desde eventos de transacción, OCR, Telegram y tareas programadas.
- Agregar prioridad, severidad, vencimiento y estado de resolución a `ai_insights`.
- Diseñar el dashboard como feed de decisiones pendientes y riesgos, no como historial pasivo.

#### Modo brutal dinámico

El modo brutal debe ser una configuración de tono y presentación. En la UI usa acentos `#FF3B30`; en el agente exige respuestas directas, sin insultar y siempre con datos históricos del usuario.

Ajuste requerido:

- Persistir preferencia de modo brutal por usuario.
- Aplicar el tono al agente, a las tarjetas de insight y a la UI.
- Pedir justificación para gastos no presupuestados solo si el usuario activó el modo.

### 11.4 Sistema de Conquista Patrimonial

**Objetivo:** convertir la disciplina financiera en un bucle de retención sofisticado, sin estética infantil.

#### Jefe Final reactivo

La meta principal (`monto_objetivo`) no debe verse como una barra estática. Su estado visual debe responder a las decisiones de la semana: avances, retrasos, compras simuladas, gastos fuertes y aportes reales.

Ajuste requerido:

- Calcular cambios semanales sobre la fecha estimada de cumplimiento.
- Mostrar impacto reciente: adelantaste, retrasaste o mantuviste el avance.
- Conectar el estado visual con insights y decisiones estratégicas.

#### Desbloqueo de arquitectura analítica

Los usuarios empiezan como `Gastador Novato` con análisis básicos. Al subir de nivel por registros limpios, OCR revisado y decisiones de ROI positivo, desbloquean proyecciones avanzadas y simulaciones del Cuarto de Guerra.

Ajuste requerido:

- Asociar capacidades analíticas a rangos existentes: `Gastador Novato`, `Rastreador`, `Administrador`, `Optimizador`, `Constructor de Patrimonio`, `Estratega`, `Magnate`.
- Definir qué acciones dan XP por calidad de datos y decisiones, no solo por volumen de registros.
- Evitar bloquear funciones esenciales de seguridad financiera; los desbloqueos deben aumentar profundidad, no ocultar lo básico.

### 11.5 Ajustes estratégicos al stack actual

| Área | Modificación requerida |
|---|---|
| Base de datos | Agregar soporte para line items de recibos, decisiones estratégicas, transacciones pendientes de revisión, preferencias de modo brutal y metadatos de prioridad en `ai_insights`. |
| Edge Functions | Extender `parse-receipt` y `telegram-bot` para producir JSON estructurado, comparar contra historial, crear insights y enviar casos ambiguos a revisión. |
| Flutter | Pivotar `home_screen.dart` hacia un feed predictivo, agregar bandeja de revisión asistida y construir visualizaciones de break-even con FL Chart. |
| Estado | Separar estado confirmado de estado pendiente; Riverpod debe manejar lotes de revisión, insights activos, simulaciones y actualizaciones optimistas con invalidación clara. |

### 11.6 Mayor desafío técnico para la primera fase

El mayor desafío técnico no es Flutter; es el diseño de datos para trazabilidad y captura pendiente.

La razón: si `transactions` sigue siendo la única tabla para todo, se mezclan registros confirmados, OCR ambiguo, capturas de Telegram, line items, decisiones estratégicas y simulaciones. Eso complica RLS, triggers de ROI, cálculo de metas, auditoría de inflación y estado en Flutter.

La primera fase debería introducir una frontera clara:

- `transactions` conserva movimientos confirmados que afectan balances, carteras y metas.
- Una tabla de ingestión o revisión guarda capturas pendientes desde OCR, Telegram y audios.
- Los line items viven como `jsonb` en la captura inicial o en una tabla dedicada cuando ya estén aprobados.
- Las decisiones estratégicas se modelan aparte de los gastos comunes para poder calcular break-even.
- `ai_insights` se vuelve el canal de salida proactiva, con prioridad y estado.

Con esa base, Flutter se vuelve más manejable: Riverpod puede separar "pendiente de revisar", "confirmado", "insight activo" y "simulación". Sin esa separación, cada pantalla termina preguntándose si una transacción es real, parcial, inferida, pendiente o estratégica, y ese es el tipo de complejidad que luego se paga caro.

---

## 12. Anexo — Artesanía móvil y sprint pro

Este anexo define el salto de "app funcional" a "app móvil pro". El backend ya tiene un motor útil: Supabase Auth, RLS, transacciones, carteras, metas, OCR, Edge Functions, agente IA, insights y Telegram. El siguiente nivel no es sumar funciones de backend sin control; es hacer que la app se sienta nativa, inmediata, táctil y confiable aunque la red falle.

### 12.1 Principio de producto

Una app móvil premium se diferencia por:

- Fluidez al abrir y navegar.
- Respuesta táctil clara.
- Estado offline y caché local.
- Animaciones con propósito.
- Gráficos que se pueden tocar.
- Notificaciones que traen al usuario de vuelta al contexto correcto.

El objetivo es que Copiloto Financiero deje de sentirse como un CRUD financiero y empiece a sentirse como un copiloto vivo.

### 12.2 Pilar 1 — Artesanía móvil

#### Offline First con caché agresivo

Problema: si el usuario abre la app sin señal y ve un spinner vacío, la app se siente frágil.

Solución: usar Riverpod con almacenamiento local para mostrar el último dashboard conocido de inmediato. Las transacciones creadas sin red deben guardarse localmente y sincronizarse cuando vuelva la conexión.

Ajuste recomendado:

- Agregar una capa de caché local para `transactions`, `portfolios`, `goals`, `user_profile` y `ai_insights`.
- Empezar con lectura cacheada antes de construir sincronización completa.
- Evaluar `Hive` o `Isar` para almacenamiento local; si el objetivo inicial es velocidad, `Hive` es suficiente para un primer sprint.
- Mostrar estados explícitos: sincronizado, pendiente de sync, error de sync.

#### Micro-interacciones y haptics

La app ya usa `HapticFeedback` en varias acciones. El siguiente paso es convertirlo en regla de diseño:

- `lightImpact()` para taps exitosos y navegación clave.
- `selectionClick()` para segmentados, tabs y cambios de modo.
- `mediumImpact()` para aprobar, eliminar o completar.
- `heavyImpact()` solo para momentos de alta carga emocional: modo brutal, alerta crítica o gran avance del Jefe Final.

Casos prioritarios:

- Aprobar una transacción OCR o Telegram.
- Rechazar una captura pendiente.
- Subir el progreso del `Jefe Final`.
- Activar `modo brutal`.
- Confirmar una decisión estratégica.

#### Animaciones con significado

Las animaciones no deben decorar; deben explicar continuidad.

Ajuste recomendado:

- Usar `Hero` entre tarjetas de listas y pantallas de detalle.
- Animar el progreso del `Jefe Final` cuando cambia por una transacción o simulación.
- Considerar Rive para estados del Jefe Final si se busca una animación ligera y 60fps.
- Evitar animaciones que oculten latencia real; si hay espera, mostrar progreso honesto.

### 12.3 Pilar 2 — Bandeja de revisión estilo swipe

El roadmap ya necesita una bandeja de revisión para OCR, Telegram y futuras capturas externas. La experiencia pro no debe ser una lista pesada.

Propuesta:

- Crear `ReviewInboxScreen`.
- Mostrar cada captura pendiente como tarjeta grande.
- Swipe derecha: aprobar y guardar como transacción confirmada.
- Swipe izquierda: rechazar.
- Tap: editar campos si OCR o DeepSeek se equivocaron.
- Haptics verdes/rojos según acción.

Dependencia técnica:

- Primero debe existir una tabla o entidad de capturas pendientes. No conviene usar `transactions` para datos todavía no confirmados.

Resultado esperado:

- Revisar 10 transacciones del fin de semana debe tomar segundos, no minutos.

### 12.4 Pilar 3 — Gráficos interactivos

El timeline de break-even no debe ser una imagen estática. En móvil, el usuario espera tocar sus datos.

Propuesta:

- Usar FL Chart con scrubbing táctil.
- Al arrastrar el dedo, actualizar tooltip y resumen lateral/inferior.
- Mostrar mensajes específicos por punto:
  - `Mes 4: Aún estás $300 abajo.`
  - `Mes 7: Recuperaste la inversión.`
  - `Mes 9: Ganancia neta de $420.`

Ajuste requerido:

- Crear una estructura de datos para puntos de ROI por decisión.
- Separar cálculo financiero de presentación visual.
- Mantener accesibilidad: el dato activo debe poder leerse fuera del gráfico.

### 12.5 Pilar 4 — Push predictivo y deep linking

`ai_insights` no debe depender de que el usuario abra la app. Si el sistema detecta riesgo o una oportunidad, debe llevar al usuario al contexto correcto.

Propuesta:

- Implementar Firebase Cloud Messaging o push compatible con Supabase.
- Cuando una Edge Function genere un insight crítico, enviar notificación.
- Usar deep linking para abrir directamente:
  - chat del agente,
  - insight específico,
  - cartera en riesgo,
  - meta/Jefe Final afectado.

Ejemplo:

```text
Modo Brutal: Tus viajes en Uber superaron tu presupuesto semanal. Abre para ver el daño a tu Jefe Final.
```

Ajuste requerido:

- Guardar tokens de dispositivo por usuario.
- Definir severidad en `ai_insights`.
- Agregar rutas profundas con GoRouter o una librería de deep links.
- Evitar spam: solo enviar alertas accionables y con alto valor.

### 12.6 Recomendación de próximo sprint

Entre:

- Opción A: Bandeja de revisión swipe.
- Opción B: Infraestructura Offline First.

La recomendación es empezar con **Opción B: Offline First Lite**.

Razón: la app ya tiene varias pantallas conectadas a Supabase y algunas actualizaciones optimistas, pero todavía depende de red para reconstruir el estado. Una bandeja swipe se verá espectacular, pero necesita una base de datos de capturas pendientes y un estado local confiable. Offline First Lite crea la base para ambas cosas.

Alcance recomendado para el sprint:

1. Cachear último dashboard conocido: perfil, transacciones recientes, carteras, metas e insight activo.
2. Mostrar datos cacheados inmediatamente al abrir la app.
3. Refrescar Supabase en segundo plano y actualizar cache.
4. Marcar transacciones creadas localmente como `pendiente_sync` si falla la red.
5. Añadir indicadores visuales discretos de sync.

Después de eso, la **Opción A: ReviewInboxScreen** será más segura de construir, porque ya existirá una forma clara de manejar datos pendientes, confirmados y sincronizados.

---

## Apéndice — Comandos útiles para el asistente de consola

```bash
# Crear proyecto Flutter
flutter create copiloto_financiero --org com.tudominio

# Agregar dependencias clave
flutter pub add supabase_flutter
flutter pub add flutter_riverpod
flutter pub add go_router
flutter pub add fl_chart
flutter pub add google_mlkit_text_recognition
flutter pub add local_auth  # biometría

# Supabase CLI
supabase init
supabase start
supabase functions new agente
supabase functions deploy agente
```

---

*Última actualización: artesanía móvil y sprint pro anexados — Fase 1 pendiente*
