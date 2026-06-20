-- 1. TABLA PARA VINCULAR USUARIOS CON TELEGRAM
CREATE TABLE IF NOT EXISTS public.user_telegram_links (
  telegram_chat_id bigint PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now()
);

-- 2. ROW LEVEL SECURITY (RLS)
ALTER TABLE public.user_telegram_links ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'user_telegram_links' AND policyname = 'usuarios ven su propio link'
    ) THEN
        CREATE POLICY "usuarios ven su propio link"
          ON public.user_telegram_links FOR ALL
          USING (auth.uid() = user_id);
    END IF;
END
$$;

-- 3. ÍNDICES
CREATE INDEX IF NOT EXISTS idx_user_telegram_links_user_id ON public.user_telegram_links(user_id);
