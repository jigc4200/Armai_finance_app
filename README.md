# Copiloto Financiero

Copiloto Financiero is a Flutter mobile app for personal financial decision analysis. The project is not centered on classic budgeting or expense tracking; its product question is:

> ¿Qué decisiones financieras de mi vida realmente aumentaron mi patrimonio y cuáles solo parecían inversiones?

The app helps a user record transactions, connect them to portfolios and goals, calculate personal ROI, review OCR-parsed receipts, and ask an AI agent for decision analysis in Spanish.

## Product Focus

The main value proposition comes from `copiloto-financiero.md`: competitors usually answer "¿cuánto gasté?", while this product answers "¿qué decisiones me hicieron ganar dinero?".

The core product shape is a financial cockpit:

- `Inicio` shows the dashboard for decisions, activity, AI insights, the current "Jefe Final" goal, portfolio previews, and recent transactions.
- `Transacciones` records `ingreso` and `gasto` movements from manual entry or OCR.
- `Carteras` tracks personal investment buckets with `total_invertido`, `total_retorno`, and `roi_calculado`.
- `Metas` tracks financial goals with `monto_objetivo`, `monto_actual`, and `completada`.
- `IA` sends financial context to a Supabase Edge Function, which calls DeepSeek and can return both a chat answer and a dashboard insight card.

## Current Stack

- Flutter with Material 3 for the app shell and screens.
- Riverpod for state management.
- Supabase for auth, database access, storage-ready backend structure, and Edge Functions.
- PostgreSQL with Row Level Security for user data isolation.
- DeepSeek through Supabase Edge Functions for the financial agent and receipt parsing.
- Google ML Kit text recognition for on-device OCR.
- FL Chart for dashboard visualizations.

## Critical Files

- `copiloto-financiero.md` is the master product brief: product vision, data model, AI architecture, roadmap, security rules, gamification, KPIs, and non-negotiable project rules.
- `DESIGN.md` documents the intended UI/UX, screen flow, design tokens, and Spanish product terminology.
- `lib/main.dart` initializes Flutter, locks portrait orientation, initializes Supabase, switches between auth and the main app shell, and defines the bottom navigation plus the Manual/OCR/IA action pill.
- `lib/core/theme/app_theme.dart` is the implemented visual identity. The current app uses a light minimal bento style: `#F2F2F2` scaffold, white surfaces, `#2D20D8` primary, `#10B981` success, `#FF3B30` error, `#E6E6E6` borders, Plus Jakarta Sans, Inter, and Share Tech Mono.
- `lib/core/constants/app_constants.dart` defines the app name, Supabase project URL/key, session duration, and the `maxTransactionsContext` value of 30.
- `lib/screens/home/home_screen.dart` is the main dashboard composition and best source for current labels such as `Decisiones`, `Actividad`, `Todo en orden`, `Preguntar algo`, `Jefe Final`, and the cockpit layout.
- `lib/screens/transactions/` contains manual transaction creation, transaction list, OCR capture, and OCR review flows.
- `lib/screens/portfolios/portfolio_list_screen.dart` manages portfolios and ROI display.
- `lib/screens/goals/goal_list_screen.dart` manages goals and progress.
- `lib/screens/agent/agent_chat_screen.dart` contains the user-facing AI chat experience.
- `lib/models/` defines the domain objects: `Transaction`, `Portfolio`, `Goal`, `UserProfile`, and `AiInsight`.
- `lib/providers/` connects Riverpod state to repositories and services.
- `lib/repositories/` wraps Supabase table access for auth, transactions, portfolios, goals, profiles, and AI insights.
- `lib/services/agent_service.dart` calls the `agente` Edge Function and maps responses into `AgentResponse` and `AiInsight`.
- `lib/services/ocr_service.dart`, `image_picker_service.dart`, and `receipt_parser_service.dart` support receipt image capture, OCR, and parsed transaction review.
- `supabase/migrations/001_init.sql` creates users, portfolios, transactions, goals, achievements, RLS policies, and the auth user trigger.
- `supabase/migrations/002_triggers.sql` updates portfolio ROI and goal progress when transactions change.
- `supabase/migrations/003_ai_insights.sql` adds active AI dashboard insight cards.
- `supabase/migrations/004_telegram_bot.sql` adds Telegram bot support.
- `supabase/functions/agente/index.ts` builds the authenticated financial context and calls DeepSeek for Spanish decision analysis.
- `supabase/functions/parse-receipt/index.ts` parses OCR text into `monto`, `fecha`, `comercio`, `categoria`, and `tipo`, with a local fallback parser.
- `supabase/functions/telegram-bot/index.ts` handles Telegram bot integration.

## Data Model

The database revolves around these tables:

- `users`: app profile with `email`, `nivel`, and `xp`.
- `transactions`: the core ledger with `monto`, `tipo`, `categoria`, optional `cartera_id`, optional `meta_id`, `fuente`, and receipt image URL.
- `portfolios`: personal investment buckets with calculated ROI.
- `goals`: financial goals and completion state.
- `achievements`: unlocked gamification achievements.
- `ai_insights`: active dashboard cards created by the AI agent.

Important domain values already used in the code and schema include:

- Transaction types: `ingreso`, `gasto`.
- Transaction sources: `manual`, `ocr`, `email`.
- Portfolio types: `activo`, `gasto_recurrente`, `proyecto`.
- Agent modes: `conversacional`, `brutal`.
- AI insight card types: `plan_accion`, `alerta`, `daily_briefing`, `consejo`.
- User ranks: `Gastador Novato`, `Rastreador`, `Administrador`, `Optimizador`, `Constructor de Patrimonio`, `Estratega`, `Magnate`.

## AI And OCR Flow

The AI API key must never be present in the Flutter client. The app calls Supabase Edge Functions, and those functions call DeepSeek.

Agent flow:

```text
Flutter -> Supabase function agente -> authenticated Supabase context -> DeepSeek -> JSON response
```

The agent reads recent transactions, active portfolios, and open goals. It responds in Spanish as a direct personal CFO, not as a generic motivational chatbot. It can also create an active insight card for the dashboard.

OCR flow:

```text
Receipt photo -> ML Kit OCR -> parse-receipt Edge Function -> editable OCR review -> transactions
```

OCR output is always reviewed before saving.

## Design Ground Rules

Read the repo before designing new screens. The source of truth is the current code plus `copiloto-financiero.md` and `DESIGN.md`.

Use real names, labels, values, and terminology from this repo. Do not introduce placeholder product copy when existing labels already exist.

Inherit the implemented visual identity from `lib/core/theme/app_theme.dart` unless a task explicitly asks to revisit the design system. Current UI patterns include:

- Light bento dashboard cards with 1px borders and no elevation.
- Rounded cards and inputs, usually 18px to 24px.
- High-weight headings with tight spacing.
- Primary action color `#2D20D8`.
- Success/income color `#10B981`.
- Error/expense/brutal-mode color `#FF3B30`.
- Main text `#0A0A0A`, muted text `#8A8A8A`, borders `#E6E6E6`.
- Spanish labels and financial terminology throughout the interface.

Let the product structure organize UI work: decisions, transactions, portfolios, goals, AI insights, OCR review, ROI, XP, and "Jefe Final" progress.

## Project Goals

Phase 1 targets a functional beta with OCR, portfolios, goals, and the AI agent for 10 real users. The milestone is a usable app where users can register transactions, classify them, track ROI, review receipts, and receive first recommendations on the dashboard.

Phase 2 adds differentiation: XP levels, achievements, opt-in `modo brutal`, the "Jefe Final" campaign view, ROI timeline, and behavior-changing insights.

Phase 3 is monetization through free/premium limits, RevenueCat, natural paywall moments, analytics, PDF exports, and native widgets.

Phase 4 is only for validated demand: bank connection, multi-user finance, web app, and exports.

The master brief now includes an "Arquitectura patrimonial proactiva" annex that pivots the product toward forensic capture, line-item inflation auditing, ROI decision timelines, predictive AI action cards, and a reactive "Jefe Final".

It also includes a mobile craftsmanship annex that recommends the next sprint: start with Offline First Lite, then build the swipe-based review inbox for OCR and Telegram captures.

The metric that matters most is:

> ¿Cuántos usuarios cambiaron una decisión financiera gracias al copiloto?

## Non-Negotiable Rules

These rules come from the project brief:

1. Do not add unplanned features to the active phase.
2. The AI key never goes in the client; always use an Edge Function proxy.
3. RLS is required from day one.
4. OCR always has manual review before saving.
5. `modo brutal` is opt-in and must be based on the user's own data.
6. Validate one phase gate before moving to the next.
7. No automatic bank connection in v1.
