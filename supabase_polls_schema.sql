-- ============================================================
-- YOUTH OF THE NATION 2026 — REAL-TIME LIVE POLLING SYSTEM
-- Run this script in the Supabase SQL Editor:
-- Project: https://yqdtvfsxffhrxfabstsk.supabase.co
-- ============================================================

-- 1. Create Polls Table
CREATE TABLE IF NOT EXISTS public.polls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_number INTEGER UNIQUE NOT NULL,
    question TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Create Poll Options Table
CREATE TABLE IF NOT EXISTS public.poll_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id UUID REFERENCES public.polls(id) ON DELETE CASCADE,
    option_key TEXT NOT NULL,
    option_text TEXT NOT NULL,
    display_order INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Create Poll Votes Table
CREATE TABLE IF NOT EXISTS public.poll_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id UUID REFERENCES public.polls(id) ON DELETE CASCADE,
    option_id UUID REFERENCES public.poll_options(id) ON DELETE CASCADE,
    voter_id TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_vote_per_voter UNIQUE (poll_id, voter_id)
);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.poll_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.poll_votes ENABLE ROW LEVEL SECURITY;

-- 5. Public RLS Policies
-- Allow public to view polls & options
DROP POLICY IF EXISTS "Allow public read polls" ON public.polls;
CREATE POLICY "Allow public read polls" ON public.polls FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Allow public read poll_options" ON public.poll_options;
CREATE POLICY "Allow public read poll_options" ON public.poll_options FOR SELECT TO anon, authenticated USING (true);

-- Allow public to read votes (for aggregate calculation)
DROP POLICY IF EXISTS "Allow public read poll_votes" ON public.poll_votes;
CREATE POLICY "Allow public read poll_votes" ON public.poll_votes FOR SELECT TO anon, authenticated USING (true);

-- Allow public to submit a vote
DROP POLICY IF EXISTS "Allow public insert poll_votes" ON public.poll_votes;
CREATE POLICY "Allow public insert poll_votes" ON public.poll_votes FOR INSERT TO anon, authenticated WITH CHECK (true);

-- (Optional) If you prefer completely open access:
-- ALTER TABLE public.polls DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.poll_options DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.poll_votes DISABLE ROW LEVEL SECURITY;

-- 6. Enable Realtime Replication for poll_votes
ALTER PUBLICATION supabase_realtime ADD TABLE public.poll_votes;

-- 7. Seed Initial 5 Poll Questions and Options (Idempotent)
DO $$
DECLARE
    p1 UUID; p2 UUID; p3 UUID; p4 UUID; p5 UUID;
BEGIN
    -- Question 1
    INSERT INTO public.polls (question_number, question) 
    VALUES (1, 'India at 80 Years of Independence – Are We Truly Free?')
    ON CONFLICT (question_number) DO UPDATE SET question = EXCLUDED.question
    RETURNING id INTO p1;

    DELETE FROM public.poll_options WHERE poll_id = p1;
    INSERT INTO public.poll_options (poll_id, option_key, option_text, display_order) VALUES
    (p1, 'A', 'Yes, completely free', 1),
    (p1, 'B', 'Free on paper, not in practice', 2),
    (p1, 'C', 'Free in some ways, restricted in others', 3),
    (p1, 'D', 'Not sure', 4);

    -- Question 2
    INSERT INTO public.polls (question_number, question) 
    VALUES (2, 'Do you think every Indian citizen enjoys the same level of freedom, regardless of religion, gender, or class?')
    ON CONFLICT (question_number) DO UPDATE SET question = EXCLUDED.question
    RETURNING id INTO p2;

    DELETE FROM public.poll_options WHERE poll_id = p2;
    INSERT INTO public.poll_options (poll_id, option_key, option_text, display_order) VALUES
    (p2, 'A', 'Yes, freedom is equal for all', 1),
    (p2, 'B', 'No, some enjoy more freedom than others', 2),
    (p2, 'C', 'It depends on where you live', 3),
    (p2, 'D', 'I''ve never really thought about it', 4);

    -- Question 3
    INSERT INTO public.polls (question_number, question) 
    VALUES (3, 'Is freedom the same as doing whatever you want, whenever you want?')
    ON CONFLICT (question_number) DO UPDATE SET question = EXCLUDED.question
    RETURNING id INTO p3;

    DELETE FROM public.poll_options WHERE poll_id = p3;
    INSERT INTO public.poll_options (poll_id, option_key, option_text, display_order) VALUES
    (p3, 'A', 'Yes', 1),
    (p3, 'B', 'No. Freedom comes with responsibility', 2),
    (p3, 'C', 'Freedom is more about having choices, not doing everything', 3),
    (p3, 'D', 'I''m not sure', 4);

    -- Question 4
    INSERT INTO public.polls (question_number, question) 
    VALUES (4, 'How do you define the idea of freedom?')
    ON CONFLICT (question_number) DO UPDATE SET question = EXCLUDED.question
    RETURNING id INTO p4;

    DELETE FROM public.poll_options WHERE poll_id = p4;
    INSERT INTO public.poll_options (poll_id, option_key, option_text, display_order) VALUES
    (p4, 'A', 'No one controlling my decisions', 1),
    (p4, 'B', 'Being able to speak my mind without fear', 2),
    (p4, 'C', 'Freedom from my own fears, guilt, and habits', 3),
    (p4, 'D', 'Something deeper than any of the above', 4);

    -- Question 5
    INSERT INTO public.polls (question_number, question) 
    VALUES (5, 'Do you think that the youth can actually change the nation?')
    ON CONFLICT (question_number) DO UPDATE SET question = EXCLUDED.question
    RETURNING id INTO p5;

    DELETE FROM public.poll_options WHERE poll_id = p5;
    INSERT INTO public.poll_options (poll_id, option_key, option_text, display_order) VALUES
    (p5, 'A', 'Yes', 1),
    (p5, 'B', 'No', 2);

    -- Question 6 (Final Emoji Reaction)
    DECLARE
        p6 UUID;
    BEGIN
        INSERT INTO public.polls (question_number, question)
        VALUES (6, 'How did you like the Polls and Interaction?')
        ON CONFLICT (question_number) DO UPDATE SET question = EXCLUDED.question
        RETURNING id INTO p6;

        DELETE FROM public.poll_options WHERE poll_id = p6;
        INSERT INTO public.poll_options (poll_id, option_key, option_text, display_order) VALUES
        (p6, 'love', '😍 Love it', 1),
        (p6, 'clap', '👏🏻 Great', 2),
        (p6, 'like', '👍 Like', 3),
        (p6, 'happy', '😀 Good', 4),
        (p6, 'dislike', '👎 Didn''t like it', 5);
    END;

END $$;
