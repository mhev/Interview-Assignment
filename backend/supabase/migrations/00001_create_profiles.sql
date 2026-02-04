-- Create profiles table
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    email text not null,
    display_name text,
    created_at timestamptz default now() not null,
    updated_at timestamptz default now() not null
);

-- Enable RLS
alter table public.profiles enable row level security;

-- Users can only view their own profile
create policy "Users can view own profile"
    on public.profiles for select
    using (auth.uid() = id);

-- Users can update their own profile
create policy "Users can update own profile"
    on public.profiles for update
    using (auth.uid() = id);

-- Users can insert their own profile
create policy "Users can insert own profile"
    on public.profiles for insert
    with check (auth.uid() = id);

-- Function to handle new user signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
    insert into public.profiles (id, email)
    values (new.id, new.email);
    return new;
end;
$$ language plpgsql security definer;

-- Trigger to create profile on signup
create or replace trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();
