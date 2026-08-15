-- ============================================================
-- YOUTH OF THE NATION 2026 — SUPABASE FIX FOR REGISTRATIONS
-- Run this in your Supabase SQL Editor:
-- Project: https://yqdtvfsxffhrxfabstsk.supabase.co
-- ============================================================

-- Step 1: Ensure the registrations table exists
CREATE TABLE IF NOT EXISTS public.registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT,
    church TEXT,
    gender TEXT,
    occupation TEXT,
    address TEXT,
    contact TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Step 2: Allow public anon users to insert into registrations
ALTER TABLE public.registrations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public insert to registrations" ON public.registrations;
CREATE POLICY "Allow public insert to registrations"
ON public.registrations
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- (Optional) If you prefer completely open access without RLS:
-- ALTER TABLE public.registrations DISABLE ROW LEVEL SECURITY;
