-- Create chat_sessions table
create table if not exists public.chat_sessions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    title text not null default 'New Chat',
    created_at timestamptz default now() not null,
    updated_at timestamptz default now() not null
);

-- Enable RLS
alter table public.chat_sessions enable row level security;

-- Users can only view their own sessions
create policy "Users can view own sessions"
    on public.chat_sessions for select
    using (auth.uid() = user_id);

-- Users can create their own sessions
create policy "Users can create own sessions"
    on public.chat_sessions for insert
    with check (auth.uid() = user_id);

-- Users can update their own sessions
create policy "Users can update own sessions"
    on public.chat_sessions for update
    using (auth.uid() = user_id);

-- Users can delete their own sessions
create policy "Users can delete own sessions"
    on public.chat_sessions for delete
    using (auth.uid() = user_id);

-- Index for faster lookups
create index if not exists chat_sessions_user_id_idx on public.chat_sessions(user_id);
