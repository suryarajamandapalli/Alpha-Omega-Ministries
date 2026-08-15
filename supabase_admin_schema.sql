-- ============================================================
-- YOUTH OF THE NATION 2026 — COMPLETE ADMIN & POLLS SCHEMA
-- Run this in your Supabase SQL Editor:
-- Project: https://yqdtvfsxffhrxfabstsk.supabase.co
-- ============================================================

-- 1. Unlock RLS on all poll tables so Admin & Public operate seamlessly
ALTER TABLE public.polls DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.poll_options DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.poll_votes DISABLE ROW LEVEL SECURITY;

-- 2. Ensure status column exists in polls table
ALTER TABLE public.polls ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'UPCOMING';

-- 3. Stored Procedure to instantly Reset All Votes
CREATE OR REPLACE FUNCTION public.reset_all_votes()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    TRUNCATE TABLE public.poll_votes;
    RETURN jsonb_build_object('success', true, 'message', 'All votes reset');
END;
$$;

-- 4. Enable Realtime Replication
ALTER PUBLICATION supabase_realtime ADD TABLE public.polls;
ALTER PUBLICATION supabase_realtime ADD TABLE public.poll_votes;

-- 5. Seed all 6 Questions & Options (including Question 6 Emoji Reaction)
DO $$
DECLARE
    p1 UUID; p2 UUID; p3 UUID; p4 UUID; p5 UUID; p6 UUID;
BEGIN
    -- Question 1
    INSERT INTO public.polls (question_number, question, is_active, status) 
    VALUES (1, 'India at 80 Years of Independence – Are We Truly Free?', true, 'LIVE')
    ON CONFLICT (question_number) DO UPDATE SET question = EXCLUDED.question, is_active = true, status = 'LIVE'
    RETURNING id INTO p1;
    DELETE FROM public.poll_options WHERE poll_id = p1;
    INSERT INTO public.poll_options (poll_id, option_key, option_text, display_order) VALUES
    (p1, 'A', 'Yes, completely free', 1),
    (p1, 'B', 'Free on paper, not in practice', 2),
    (p1, 'C', 'Free in some ways, restricted in others', 3),
    (p1, 'D', 'Not sure', 4);

    -- Question 2
    INSERT INTO public.polls (question_number, question, is_active, status) 
    VALUES (2, 'Do you think every Indian citizen enjoys the same level of freedom, regardless of religion, gender, or class?', false, 'UPCOMING')
    ON CONFLICT (question_number) DO UPDATE SET question = EXCLUDED.question, is_active = false, status = 'UPCOMING'
    RETURNING id INTO p2;
    DELETE FROM public.poll_options WHERE poll_id = p2;
    INSERT INTO public.poll_options (poll_id, option_key, option_text, display_order) VALUES
    (p2, 'A', 'Yes, freedom is equal for all', 1),
    (p2, 'B', 'No, some enjoy more freedom than others', 2),
    (p2, 'C', 'It depends on where you live', 3),
    (p2, 'D', 'I''ve never really thought about it', 4);

    -- Question 3
    INSERT INTO public.polls (question_number, question, is_active, status) 
    VALUES (3, 'Is freedom the same as doing whatever you want, whenever you want?', false, 'UPCOMING')
    ON CONFLICT (question_number) DO UPDATE SET question = EXCLUDED.question, is_active = false, status = 'UPCOMING'
    RETURNING id INTO p3;
    DELETE FROM public.poll_options WHERE poll_id = p3;
    INSERT INTO public.poll_options (poll_id, option_key, option_text, display_order) VALUES
    (p3, 'A', 'Yes', 1),
    (p3, 'B', 'No. Freedom comes with responsibility', 2),
    (p3, 'C', 'Freedom is more about having choices, not doing everything', 3),
    (p3, 'D', 'I''m not sure', 4);

    -- Question 4
    INSERT INTO public.polls (question_number, question, is_active, status) 
    VALUES (4, 'How do you define the idea of freedom?', false, 'UPCOMING')
    ON CONFLICT (question_number) DO UPDATE SET question = EXCLUDED.question, is_active = false, status = 'UPCOMING'
    RETURNING id INTO p4;
    DELETE FROM public.poll_options WHERE poll_id = p4;
    INSERT INTO public.poll_options (poll_id, option_key, option_text, display_order) VALUES
    (p4, 'A', 'No one controlling my decisions', 1),
    (p4, 'B', 'Being able to speak my mind without fear', 2),
    (p4, 'C', 'Freedom from my own fears, guilt, and habits', 3),
    (p4, 'D', 'Something deeper than any of the above', 4);

    -- Question 5
    INSERT INTO public.polls (question_number, question, is_active, status) 
    VALUES (5, 'Do you think that the youth can actually change the nation?', false, 'UPCOMING')
    ON CONFLICT (question_number) DO UPDATE SET question = EXCLUDED.question, is_active = false, status = 'UPCOMING'
    RETURNING id INTO p5;
    DELETE FROM public.poll_options WHERE poll_id = p5;
    INSERT INTO public.poll_options (poll_id, option_key, option_text, display_order) VALUES
    (p5, 'A', 'Yes', 1),
    (p5, 'B', 'No', 2);

    -- Question 6 (Final Emoji Reaction)
    INSERT INTO public.polls (question_number, question, is_active, status)
    VALUES (6, 'How did you like the Polls and Interaction?', false, 'UPCOMING')
    ON CONFLICT (question_number) DO UPDATE SET question = EXCLUDED.question, is_active = false, status = 'UPCOMING'
    RETURNING id INTO p6;
    DELETE FROM public.poll_options WHERE poll_id = p6;
    INSERT INTO public.poll_options (poll_id, option_key, option_text, display_order) VALUES
    (p6, 'love', '😍 Love it', 1),
    (p6, 'clap', '👏🏻 Great', 2),
    (p6, 'like', '👍 Like', 3),
    (p6, 'happy', '😀 Good', 4),
    (p6, 'dislike', '👎 Didn''t like it', 5);
END $$;
