-- ==============================================================================
-- DATABASE MIGRATION FOR SWAPMATE MESSAGING SYSTEM
-- ==============================================================================

-- 1. Create the `conversations` table
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    participant_1 UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    participant_2 UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    participant_1_name TEXT,
    participant_2_name TEXT,
    item_id UUID,
    item_name TEXT,
    item_image_url TEXT,
    last_message TEXT,
    last_message_time TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Ensure a conversation only exists between the same two users once
CREATE UNIQUE INDEX IF NOT EXISTS unique_participants_idx 
ON public.conversations (LEAST(participant_1, participant_2), GREATEST(participant_1, participant_2));

-- 2. Create the `messages` table
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Index to speed up fetching messages by conversation and unread queries
CREATE INDEX IF NOT EXISTS messages_conversation_idx ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS messages_receiver_unread_idx ON public.messages(receiver_id, is_read);

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ==============================================================================

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Conversations Policies: Users can view, insert, or update their own conversations
CREATE POLICY "Users can view their conversations" 
ON public.conversations FOR SELECT 
TO authenticated 
USING (auth.uid() = participant_1 OR auth.uid() = participant_2);

CREATE POLICY "Users can insert conversations" 
ON public.conversations FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = participant_1 OR auth.uid() = participant_2);

CREATE POLICY "Users can update their conversations" 
ON public.conversations FOR UPDATE 
TO authenticated 
USING (auth.uid() = participant_1 OR auth.uid() = participant_2);


-- Messages Policies: Users can view, insert, or update their own messages
CREATE POLICY "Users can view their messages" 
ON public.messages FOR SELECT 
TO authenticated 
USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can insert messages" 
ON public.messages FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update their received messages to mark as read" 
ON public.messages FOR UPDATE 
TO authenticated 
USING (auth.uid() = receiver_id OR auth.uid() = sender_id);

-- ==============================================================================
-- TRIGGERS
-- ==============================================================================

-- Create a function to automatically update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Attach the trigger to conversations
DROP TRIGGER IF EXISTS update_conversations_updated_at ON public.conversations;
CREATE TRIGGER update_conversations_updated_at
BEFORE UPDATE ON public.conversations
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ==============================================================================
-- REALTIME
-- ==============================================================================
-- Add tables to the realtime publication
alter publication supabase_realtime add table public.conversations;
alter publication supabase_realtime add table public.messages;
