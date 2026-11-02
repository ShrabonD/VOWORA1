-- Run after supabase_birthday_schema.sql in the Supabase SQL Editor.
BEGIN;

ALTER TABLE IF EXISTS public.birthday_bookings
    ADD COLUMN IF NOT EXISTS amount_paid NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS balance_due_at DATE;

ALTER TABLE IF EXISTS public.birthday_payments
    ADD COLUMN IF NOT EXISTS idempotency_key TEXT;

DO $$
BEGIN
    IF to_regclass('public.birthday_bookings') IS NOT NULL THEN
        ALTER TABLE public.birthday_bookings
            DROP CONSTRAINT IF EXISTS birthday_bookings_payment_status_check;
        ALTER TABLE public.birthday_bookings
            ADD CONSTRAINT birthday_bookings_payment_status_check
            CHECK (payment_status IN (
                'pending', 'successful', 'partially_paid', 'fully_paid',
                'failed', 'cancelled', 'refunded'
            ));

        ALTER TABLE public.birthday_bookings ENABLE ROW LEVEL SECURITY;
        DROP POLICY IF EXISTS "Users can view their own birthday bookings"
            ON public.birthday_bookings;
        DROP POLICY IF EXISTS "Users can insert their own birthday bookings"
            ON public.birthday_bookings;
        DROP POLICY IF EXISTS "Users can update their own birthday bookings"
            ON public.birthday_bookings;
        CREATE POLICY "Users can view their own birthday bookings"
            ON public.birthday_bookings FOR SELECT TO authenticated
            USING (user_id = auth.uid());
        REVOKE INSERT, UPDATE, DELETE ON public.birthday_bookings
            FROM anon, authenticated;
        GRANT SELECT ON public.birthday_bookings TO authenticated;
    END IF;

    IF to_regclass('public.birthday_payments') IS NOT NULL THEN
        ALTER TABLE public.birthday_payments
            DROP CONSTRAINT IF EXISTS birthday_payments_payment_method_check;
        ALTER TABLE public.birthday_payments
            ADD CONSTRAINT birthday_payments_payment_method_check
            CHECK (payment_method IN (
                'bkash', 'nagad', 'visa', 'mastercard', 'card', 'bank_transfer'
            ));

        ALTER TABLE public.birthday_payments ENABLE ROW LEVEL SECURITY;
        DROP POLICY IF EXISTS "Payments are viewable by all authorized"
            ON public.birthday_payments;
        DROP POLICY IF EXISTS "Users can view their own birthday payments"
            ON public.birthday_payments;
        CREATE POLICY "Users can view their own birthday payments"
            ON public.birthday_payments FOR SELECT TO authenticated
            USING (user_id = auth.uid());
        REVOKE INSERT, UPDATE, DELETE ON public.birthday_payments
            FROM anon, authenticated;
        GRANT SELECT ON public.birthday_payments TO authenticated;
        CREATE UNIQUE INDEX IF NOT EXISTS birthday_payments_idempotency_key_unique
            ON public.birthday_payments (idempotency_key)
            WHERE idempotency_key IS NOT NULL;
    END IF;
END $$;

NOTIFY pgrst, 'reload schema';
COMMIT;