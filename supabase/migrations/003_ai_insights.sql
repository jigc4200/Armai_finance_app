-- 1. TABLA DE INSIGHTS DE IA (SMART CARDS)
CREATE TABLE IF NOT EXISTS public.ai_insights (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  tipo_tarjeta text NOT NULL,
  titulo text NOT NULL,
  mensaje_corto text NOT NULL,
  accion_texto text DEFAULT 'Revisar progreso',
  icono text DEFAULT 'psychology',
  activa boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- 2. ROW LEVEL SECURITY (RLS)
ALTER TABLE public.ai_insights ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'ai_insights' AND policyname = 'usuarios solo ven sus insights'
    ) THEN
        CREATE POLICY "usuarios solo ven sus insights"
          ON public.ai_insights FOR ALL
          USING (auth.uid() = user_id);
    END IF;
END
$$;

-- 3. ÍNDICES
CREATE INDEX IF NOT EXISTS idx_ai_insights_user_id ON public.ai_insights(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_insights_created_at ON public.ai_insights(created_at DESC);
