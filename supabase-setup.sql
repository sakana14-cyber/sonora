-- Run this in the Supabase SQL editor before connecting the public site.
create table if not exists public.requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  kind text not null check (kind in ('効果音', 'BGM')),
  title text not null,
  detail text not null,
  amount integer not null default 0,
  tags text[] not null default '{}',
  source_mode text not null check (source_mode in ('ai', 'raw')),
  audio_path text not null,
  status text not null default 'open',
  created_at timestamptz not null default now()
);

create table if not exists public.applications (
  id uuid primary key default gen_random_uuid(),
  request_id uuid references public.requests(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  message text not null,
  audio_path text not null,
  status text not null default 'submitted',
  created_at timestamptz not null default now()
);

alter table public.requests enable row level security;
alter table public.applications enable row level security;

create policy "Anyone can read open requests" on public.requests
  for select using (status = 'open' or auth.uid() = user_id);
create policy "Users create their requests" on public.requests
  for insert to authenticated with check (auth.uid() = user_id);
create policy "Owners update their requests" on public.requests
  for update to authenticated using (auth.uid() = user_id);
create policy "Applicants create applications" on public.applications
  for insert to authenticated with check (auth.uid() = user_id);
create policy "Related users read applications" on public.applications
  for select to authenticated using (
    auth.uid() = user_id or exists (
      select 1 from public.requests r
      where r.id = request_id and r.user_id = auth.uid()
    )
  );

insert into storage.buckets (id, name, public)
values ('audio', 'audio', true)
on conflict (id) do nothing;

create policy "Public audio is readable" on storage.objects
  for select using (bucket_id = 'audio');
create policy "Authenticated users upload audio" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'audio' and (storage.foldername(name))[1] = auth.uid()::text
  );
