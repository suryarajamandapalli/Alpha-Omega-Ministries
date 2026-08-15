-- ============================================================
-- YOUTH OF THE NATION 2026 — ADMIN POLL CONTROL SCHEMA
-- Run this in your Supabase SQL Editor:
-- Project: https://yqdtvfsxffhrxfabstsk.supabase.co
-- ============================================================

-- 1. Ensure status column exists in polls table
ALTER TABLE public.polls ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'UPCOMING';

-- 2. Ensure initial states: Question 1 is LIVE, others UPCOMING
UPDATE public.polls SET is_active = false, status = 'UPCOMING' WHERE question_number != 1;
UPDATE public.polls SET is_active = true, status = 'LIVE' WHERE question_number = 1;

-- 3. Enable Realtime Replication on polls
ALTER PUBLICATION supabase_realtime ADD TABLE public.polls;

-- 4. Enable RLS and add policies
ALTER TABLE public.polls ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read polls" ON public.polls;
CREATE POLICY "Allow public read polls" ON public.polls FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Allow public update polls" ON public.polls;
CREATE POLICY "Allow public update polls" ON public.polls FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);

-- (Optional) If you prefer completely unlocked RLS:
-- ALTER TABLE public.polls DISABLE ROW LEVEL SECURITY;
