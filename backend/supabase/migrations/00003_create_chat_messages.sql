-- Create chat_messages table
create table if not exists public.chat_messages (
    id uuid primary key default gen_random_uuid(),
    session_id uuid not null references public.chat_sessions(id) on delete cascade,
    role text not null check (role in ('user', 'assistant')),
    content text not null,
    created_at timestamptz default now() not null
);

-- Enable RLS
alter table public.chat_messages enable row level security;

-- Users can only view messages from their own sessions
create policy "Users can view own messages"
    on public.chat_messages for select
    using (
        exists (
            select 1 from public.chat_sessions
            where chat_sessions.id = chat_messages.session_id
            and chat_sessions.user_id = auth.uid()
        )
    );

-- Users can insert messages to their own sessions
create policy "Users can insert own messages"
    on public.chat_messages for insert
    with check (
        exists (
            select 1 from public.chat_sessions
            where chat_sessions.id = chat_messages.session_id
            and chat_sessions.user_id = auth.uid()
        )
    );

-- Index for faster lookups
create index if not exists chat_messages_session_id_idx on public.chat_messages(session_id);
create index if not exists chat_messages_created_at_idx on public.chat_messages(created_at);
