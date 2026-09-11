<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase" />
  <img src="https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL" />
  <img src="https://img.shields.io/badge/DeepSeek_AI-0A0A0A?style=for-the-badge&logo=openai&logoColor=white" alt="DeepSeek AI" />
</div>

<h1 align="center">Copiloto Financiero 🚀</h1>

<p align="center">
  <strong>Un analizador de decisiones financieras impulsado por IA para iOS y Android.</strong>
</p>

<p align="center">
  <i>"¿Qué decisiones financieras de mi vida realmente aumentaron mi patrimonio y cuáles solo parecían inversiones?"</i>
</p>

---

## 📖 Acerca del Proyecto

**Copiloto Financiero** no es una aplicación de presupuestos tradicional ni un simple rastreador de gastos (como YNAB o Fintonic). Es un **analizador de decisiones patrimoniales**.

La aplicación ayuda a los usuarios a registrar transacciones, conectarlas a carteras de inversión y metas, calcular el Retorno de Inversión (ROI) personal, revisar recibos mediante OCR y, lo más importante, consultar a un **agente de inteligencia artificial (IA)** que actúa como tu CFO personal para analizar tus decisiones financieras.

### Propuesta de Valor
Mientras que los competidores responden *"¿Cuánto gasté?"*, Copiloto Financiero responde ***"¿Qué decisiones me hicieron ganar dinero?"***.

## ✨ Características Principales

- 📊 **Panel de Decisiones (Dashboard):** Visualiza tu balance, actividad reciente, insights de la IA y el progreso de tu meta principal ("Jefe Final").
- 🤖 **Agente de IA (DeepSeek):** Un CFO personal en tu bolsillo que analiza tus decisiones. Cuenta con un **Modo Brutal** (opcional) que te habla directo basándose en tu propio historial.
- 📸 **Captura por OCR:** Toma una foto a tus recibos y la app extraerá automáticamente el comercio, monto, fecha y sugerirá una categoría (con revisión manual obligatoria).
- 💼 **Carteras de Inversión:** Rastrea tus inversiones con cálculos de `total invertido`, `retorno` y `ROI`.
- 🎯 **Metas (Jefe Final):** Gamificación financiera. Convierte tu meta de ahorro principal en un "Jefe Final" a derrotar mediante tus aportes.
- 🎮 **Gamificación y Logros:** Gana puntos de experiencia (XP) y sube de rango (desde *Gastador Novato* hasta *Magnate*) al tomar decisiones financieras sólidas.

## 🛠️ Stack Tecnológico

El proyecto está construido con tecnologías modernas, asegurando rendimiento, escalabilidad y una experiencia de usuario fluida en múltiples plataformas.

### Frontend
- **Flutter:** Desarrollo multiplataforma (iOS + Android).
- **Riverpod:** Gestión de estado reactiva y segura.
- **Go Router:** Navegación robusta.
- **FL Chart:** Visualización de datos y gráficos interactivos.

### Backend & Infraestructura
- **Supabase:** Base de datos as a Service (BaaS).
- **PostgreSQL:** Base de datos relacional con **Row Level Security (RLS)** para aislar los datos de los usuarios.
- **Supabase Edge Functions:** Funciones serverless para integración segura con la IA y lógica de negocio.

### Inteligencia Artificial
- **DeepSeek V3:** El cerebro detrás del agente financiero.
- **Google ML Kit:** Extracción de texto (OCR) on-device para mayor privacidad.

## 🔒 Seguridad y Privacidad

La privacidad de los datos financieros es prioritaria:
1. **API Keys Protegidas:** La llave de la IA NUNCA se almacena en la app cliente; todo pasa por el proxy seguro de Supabase Edge Functions.
2. **Aislamiento (RLS):** Las políticas de Row Level Security garantizan que cada usuario solo pueda ver e interactuar con su propia información.
3. **Revisión Humana:** El OCR nunca guarda una transacción automáticamente sin tu confirmación.

## 🚀 Guía de Instalación Local

Para ejecutar el proyecto en tu entorno local, asegúrate de tener [Flutter](https://flutter.dev/docs/get-started/install) instalado.

1. **Clona el repositorio:**
   ```bash
   git clone https://github.com/tu-usuario/copiloto-financiero.git
   cd copiloto-financiero
   ```

2. **Instala las dependencias:**
   ```bash
   flutter pub get
   ```

3. **Configura las variables de entorno:**
   Configura las credenciales de Supabase en tu entorno o archivo de configuración (normalmente en un `.env` u objeto de configuración interno).

4. **Ejecuta la app:**
   ```bash
   flutter run
   ```

## 📚 Documentación Adicional

- [DESIGN.md](./DESIGN.md) - Sistema de diseño, tokens visuales e interfaz de usuario (UI/UX).
- [copiloto-financiero.md](./copiloto-financiero.md) - Documento maestro con la visión completa, modelo de datos, arquitectura y roadmap.

---
<div align="center">
  Construido con pasión y disciplina para revolucionar tus finanzas personales. 📈
</div>
