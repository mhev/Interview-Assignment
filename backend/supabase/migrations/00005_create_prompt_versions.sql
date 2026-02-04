-- Create prompt_versions table for tracking AI prompt changes
create table if not exists public.prompt_versions (
    id uuid primary key default gen_random_uuid(),
    version integer not null unique,
    name text not null,
    system_prompt text not null,
    is_active boolean default false not null,
    created_at timestamptz default now() not null
);

-- Enable RLS (admin-only table, but we enable RLS for consistency)
alter table public.prompt_versions enable row level security;

-- Only allow read access (no user modifications)
create policy "Anyone can view prompt versions"
    on public.prompt_versions for select
    using (true);

-- Add prompt_version_id to chat_sessions to track which prompt was used
alter table public.chat_sessions 
    add column if not exists prompt_version_id uuid references public.prompt_versions(id);

-- Index for faster lookups
create index if not exists prompt_versions_is_active_idx on public.prompt_versions(is_active);
create index if not exists prompt_versions_version_idx on public.prompt_versions(version);

-- Seed initial prompt version
insert into public.prompt_versions (version, name, system_prompt, is_active) values (
    1,
    'NeverGone Companion v1',
    'You are NeverGone, a thoughtful AI companion. You are warm, curious, and genuinely interested in the user. You remember conversations and build rapport over time. You ask follow-up questions and reflect on what users share. Keep responses conversational and natural.',
    true
);
