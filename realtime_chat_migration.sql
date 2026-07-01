-- ==============================================================================
-- SWAPMATE REALTIME CHAT MIGRATION
-- Run this in Supabase SQL Editor (Dashboard → SQL Editor → New Query)
-- This is SAFE to run multiple times (uses IF NOT EXISTS / DO blocks)
-- ==============================================================================

-- ==========================================
-- 1. Add presence columns to profiles
-- ==========================================
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS last_seen TIMESTAMPTZ DEFAULT now();

-- ==========================================
-- 2. Add status column to messages
-- ==========================================
ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'sent'
    CHECK (status IN ('sending', 'sent', 'delivered', 'read', 'failed'));

-- ==========================================
-- 3. Fix conversations column names
--    The schema used participant_1/participant_2
--    but the Flutter code uses user1_id/user2_id.
--    We add alias columns that mirror the originals
--    so both old and new code works without breaking anything.
-- ==========================================
ALTER TABLE public.conversations
  ADD COLUMN IF NOT EXISTS user1_id UUID
    REFERENCES auth.users(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS user2_id UUID
    REFERENCES auth.users(id) ON DELETE CASCADE;

-- Backfill user1_id / user2_id from participant_1 / participant_2
UPDATE public.conversations
SET
  user1_id = participant_1,
  user2_id = participant_2
WHERE user1_id IS NULL OR user2_id IS NULL;

-- Create a trigger to keep them in sync on INSERT/UPDATE
CREATE OR REPLACE FUNCTION sync_conversation_participants()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.participant_1 IS NOT NULL THEN
    NEW.user1_id := NEW.participant_1;
  END IF;
  IF NEW.participant_2 IS NOT NULL THEN
    NEW.user2_id := NEW.participant_2;
  END IF;
  IF NEW.user1_id IS NOT NULL AND NEW.participant_1 IS NULL THEN
    NEW.participant_1 := NEW.user1_id;
  END IF;
  IF NEW.user2_id IS NOT NULL AND NEW.participant_2 IS NULL THEN
    NEW.participant_2 := NEW.user2_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS sync_conversation_participants_trigger ON public.conversations;
CREATE TRIGGER sync_conversation_participants_trigger
BEFORE INSERT OR UPDATE ON public.conversations
FOR EACH ROW EXECUTE FUNCTION sync_conversation_participants();

-- ==========================================
-- 4. Indexes for performance
-- ==========================================
CREATE INDEX IF NOT EXISTS messages_status_idx ON public.messages(status);
CREATE INDEX IF NOT EXISTS profiles_online_idx ON public.profiles(is_online);
CREATE INDEX IF NOT EXISTS conversations_user1_idx ON public.conversations(user1_id);
CREATE INDEX IF NOT EXISTS conversations_user2_idx ON public.conversations(user2_id);

-- ==========================================
-- 5. Enable Realtime on profiles
--    (messages and conversations already enabled in original schema)
-- ==========================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;

-- ==========================================
-- 6. Function: auto mark delivered when receiver comes online
-- ==========================================
CREATE OR REPLACE FUNCTION mark_messages_delivered_for_user(p_user_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.messages
  SET status = 'delivered'
  WHERE receiver_id = p_user_id
    AND status = 'sent'
    AND is_read = false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION mark_messages_delivered_for_user(UUID) TO authenticated;
