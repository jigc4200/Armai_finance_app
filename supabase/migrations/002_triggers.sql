-- 1. TRIGGER FUNCTION FOR PORTFOLIOS AND GOALS METRICS
CREATE OR REPLACE FUNCTION public.update_portfolio_and_goal_metrics()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- =========================================================================
    -- A. PORTFOLIO METRICS UPDATES
    -- =========================================================================
    
    -- If a transaction was deleted or updated to another portfolio, reduce old portfolio metrics
    IF (TG_OP = 'DELETE' OR TG_OP = 'UPDATE') AND OLD.cartera_id IS NOT NULL THEN
        UPDATE public.portfolios
        SET 
            total_invertido = GREATEST(0, total_invertido - CASE WHEN OLD.tipo = 'gasto' THEN OLD.monto ELSE 0 END),
            total_retorno = GREATEST(0, total_retorno - CASE WHEN OLD.tipo = 'ingreso' THEN OLD.monto ELSE 0 END)
        WHERE id = OLD.cartera_id;

        UPDATE public.portfolios
        SET roi_calculado = CASE WHEN total_invertido = 0 THEN 0 ELSE ((total_retorno - total_invertido) / total_invertido) * 100 END
        WHERE id = OLD.cartera_id;
    END IF;

    -- If a transaction was inserted or updated, increase new portfolio metrics
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') AND NEW.cartera_id IS NOT NULL THEN
        UPDATE public.portfolios
        SET 
            total_invertido = total_invertido + CASE WHEN NEW.tipo = 'gasto' THEN NEW.monto ELSE 0 END,
            total_retorno = total_retorno + CASE WHEN NEW.tipo = 'ingreso' THEN NEW.monto ELSE 0 END
        WHERE id = NEW.cartera_id;

        UPDATE public.portfolios
        SET roi_calculado = CASE WHEN total_invertido = 0 THEN 0 ELSE ((total_retorno - total_invertido) / total_invertido) * 100 END
        WHERE id = NEW.cartera_id;
    END IF;

    -- =========================================================================
    -- B. GOALS PROGRESS UPDATES
    -- =========================================================================
    
    -- If a transaction was deleted or updated to another goal, reduce old goal progress
    -- We assume 'ingreso' increases goal savings, and 'gasto' reduces or spends from goal savings
    IF (TG_OP = 'DELETE' OR TG_OP = 'UPDATE') AND OLD.meta_id IS NOT NULL THEN
        UPDATE public.goals
        SET 
            monto_actual = GREATEST(0, monto_actual - CASE WHEN OLD.tipo = 'ingreso' THEN OLD.monto ELSE -OLD.monto END)
        WHERE id = OLD.meta_id;

        UPDATE public.goals
        SET completada = (monto_actual >= monto_objetivo)
        WHERE id = OLD.meta_id;
    END IF;

    -- If a transaction was inserted or updated, increase new goal progress
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') AND NEW.meta_id IS NOT NULL THEN
        UPDATE public.goals
        SET 
            monto_actual = monto_actual + CASE WHEN NEW.tipo = 'ingreso' THEN NEW.monto ELSE -NEW.monto END
        WHERE id = NEW.meta_id;

        UPDATE public.goals
        SET completada = (monto_actual >= monto_objetivo)
        WHERE id = NEW.meta_id;
    END IF;

    IF (TG_OP = 'DELETE') THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;

-- 2. CREATE THE TRIGGER
CREATE OR REPLACE TRIGGER on_transaction_changes
AFTER INSERT OR UPDATE OR DELETE ON public.transactions
FOR EACH ROW
EXECUTE FUNCTION public.update_portfolio_and_goal_metrics();

-- 3. CREATE COMPOSITE INDEX FOR DASHBOARD TRANSACTIONS
CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON public.transactions(user_id, fecha DESC);
