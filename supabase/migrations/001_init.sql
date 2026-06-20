-- Copiloto Financiero - Esquema inicial
-- Ejecutar en Supabase SQL Editor

-- 1. TABLAS PRINCIPALES

CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  nivel integer DEFAULT 1,
  xp integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE portfolios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  nombre text NOT NULL,
  tipo text NOT NULL CHECK (tipo IN ('activo', 'gasto_recurrente', 'proyecto')),
  total_invertido numeric(12,2) DEFAULT 0,
  total_retorno numeric(12,2) DEFAULT 0,
  roi_calculado numeric(6,2) DEFAULT 0,
  activa boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  monto numeric(12,2) NOT NULL,
  tipo text NOT NULL CHECK (tipo IN ('ingreso', 'gasto')),
  categoria text NOT NULL,
  cartera_id uuid REFERENCES portfolios(id) ON DELETE SET NULL,
  descripcion text,
  fecha date NOT NULL DEFAULT CURRENT_DATE,
  fuente text NOT NULL DEFAULT 'manual' CHECK (fuente IN ('manual', 'ocr', 'email')),
  imagen_url text,
  meta_id uuid,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE goals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  nombre text NOT NULL,
  monto_objetivo numeric(12,2) NOT NULL,
  monto_actual numeric(12,2) DEFAULT 0,
  fecha_objetivo date NOT NULL,
  completada boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE achievements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  tipo text NOT NULL,
  desbloqueado_en timestamptz DEFAULT now(),
  mostrado boolean DEFAULT false
);

-- 2. ROW LEVEL SECURITY

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE portfolios ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "usuarios solo ven su perfil"
  ON users FOR ALL
  USING (auth.uid() = id);

CREATE POLICY "usuarios solo ven sus carteras"
  ON portfolios FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "usuarios solo ven sus transacciones"
  ON transactions FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "usuarios solo ven sus metas"
  ON goals FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "usuarios solo ven sus logros"
  ON achievements FOR ALL
  USING (auth.uid() = user_id);

-- 3. TRIGGER: crear usuario automáticamente al registrarse

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.users (id, email)
  VALUES (NEW.id, NEW.email);
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 4. ÍNDICES

CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_fecha ON transactions(fecha DESC);
CREATE INDEX idx_portfolios_user_id ON portfolios(user_id);
CREATE INDEX idx_goals_user_id ON goals(user_id);
CREATE INDEX idx_achievements_user_id ON achievements(user_id);
