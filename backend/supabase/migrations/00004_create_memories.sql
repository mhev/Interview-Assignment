-- Create memories table
create table if not exists public.memories (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles(id) on delete cascade,
    session_id uuid references public.chat_sessions(id) on delete set null,
    summary text not null,
    created_at timestamptz default now() not null
);

-- Enable RLS
alter table public.memories enable row level security;

-- Users can only view their own memories
create policy "Users can view own memories"
    on public.memories for select
    using (auth.uid() = user_id);

-- Users can create their own memories
create policy "Users can insert own memories"
    on public.memories for insert
    with check (auth.uid() = user_id);

-- Index for faster lookups
create index if not exists memories_user_id_idx on public.memories(user_id);
create index if not exists memories_session_id_idx on public.memories(session_id);
