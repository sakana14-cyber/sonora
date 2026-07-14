-- Sonora production schema for Supabase
-- Run the complete file once in Supabase Dashboard > SQL Editor.

create extension if not exists pgcrypto;

-- 1. Public profile paired one-to-one with auth.users.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 40),
  avatar_url text,
  created_at timestamptz not null default now()
);

-- 2. Public humming / voice posts.
create table if not exists public.voice_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 120),
  tags text[] not null default '{}',
  audio_path text not null unique,
  visibility text not null default 'public' check (visibility in ('public', 'private')),
  downloads integer not null default 0 check (downloads >= 0),
  created_at timestamptz not null default now()
);

-- 3. Requests made from an AI draft or raw humming.
create table if not exists public.requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null check (kind in ('効果音', 'BGM')),
  title text not null check (char_length(title) between 1 and 120),
  detail text not null check (char_length(detail) between 1 and 2000),
  amount integer not null default 0 check (
    (kind = '効果音' and amount = 0) or
    (kind = 'BGM' and amount >= 1000)
  ),
  tags text[] not null default '{}',
  source_mode text not null check (source_mode in ('ai', 'raw')),
  audio_path text not null unique,
  status text not null default 'open' check (status in ('open', 'adopted', 'closed')),
  deadline timestamptz not null default (now() + interval '7 days'),
  adopted_application_id uuid,
  created_at timestamptz not null default now()
);

-- 4. Creator applications with an audio sample.
create table if not exists public.applications (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.requests(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  message text not null check (char_length(message) between 1 and 2000),
  audio_path text not null unique,
  status text not null default 'submitted' check (status in ('submitted', 'adopted', 'rejected', 'withdrawn')),
  created_at timestamptz not null default now(),
  unique (request_id, user_id)
);

do $$ begin
  alter table public.requests
    add constraint requests_adopted_application_fkey
    foreign key (adopted_application_id) references public.applications(id);
exception when duplicate_object then null;
end $$;

create index if not exists voice_posts_user_id_idx on public.voice_posts(user_id);
create index if not exists voice_posts_downloads_idx on public.voice_posts(downloads desc);
create index if not exists requests_user_id_idx on public.requests(user_id);
create index if not exists requests_status_created_idx on public.requests(status, created_at desc);
create index if not exists applications_request_id_idx on public.applications(request_id);
create index if not exists applications_user_id_idx on public.applications(user_id);

-- Create a profile automatically after email signup.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'display_name', ''), split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Only a request owner can adopt an application belonging to that request.
create or replace function public.adopt_application(
  target_request_id uuid,
  target_application_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.requests
    where id = target_request_id and user_id = (select auth.uid()) and status = 'open'
  ) then
    raise exception 'Only the request owner can adopt an application.';
  end if;

  if not exists (
    select 1 from public.applications
    where id = target_application_id and request_id = target_request_id and status = 'submitted'
  ) then
    raise exception 'Application does not belong to this request.';
  end if;

  update public.applications
  set status = case when id = target_application_id then 'adopted' else 'rejected' end
  where request_id = target_request_id and status = 'submitted';

  update public.requests
  set status = 'adopted', adopted_application_id = target_application_id
  where id = target_request_id;
end;
$$;

revoke all on function public.adopt_application(uuid, uuid) from public;
grant execute on function public.adopt_application(uuid, uuid) to authenticated;

-- Row Level Security is required for browser access with the publishable key.
alter table public.profiles enable row level security;
alter table public.voice_posts enable row level security;
alter table public.requests enable row level security;
alter table public.applications enable row level security;

create policy "Profiles are public"
  on public.profiles for select to anon, authenticated using (true);
create policy "Users update their profile"
  on public.profiles for update to authenticated
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

create policy "Public voice posts are readable"
  on public.voice_posts for select to anon, authenticated
  using (visibility = 'public' or (select auth.uid()) = user_id);
create policy "Users create their voice posts"
  on public.voice_posts for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Users update their voice posts"
  on public.voice_posts for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "Users delete their voice posts"
  on public.voice_posts for delete to authenticated
  using ((select auth.uid()) = user_id);

create policy "Open requests are public"
  on public.requests for select to anon, authenticated
  using (status = 'open' or (select auth.uid()) = user_id);
create policy "Users create requests"
  on public.requests for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Owners update requests"
  on public.requests for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "Owners delete open requests"
  on public.requests for delete to authenticated
  using ((select auth.uid()) = user_id and status = 'open');

create policy "Related users read applications"
  on public.applications for select to authenticated
  using (
    (select auth.uid()) = user_id or exists (
      select 1 from public.requests r
      where r.id = request_id and r.user_id = (select auth.uid())
    )
  );
create policy "Creators submit applications"
  on public.applications for insert to authenticated
  with check (
    (select auth.uid()) = user_id and exists (
      select 1 from public.requests r
      where r.id = request_id and r.status = 'open' and r.user_id <> (select auth.uid())
    )
  );
create policy "Creators update their submitted application"
  on public.applications for update to authenticated
  using ((select auth.uid()) = user_id and status = 'submitted')
  with check ((select auth.uid()) = user_id);

-- Private bucket. Access is granted through policies and signed URLs.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'audio-private',
  'audio-private',
  false,
  52428800,
  array['audio/webm','audio/wav','audio/mpeg','audio/mp4','audio/ogg']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "Users upload into their folder"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'audio-private' and
    (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Visible Sonora audio is readable"
  on storage.objects for select to anon, authenticated
  using (
    bucket_id = 'audio-private' and (
      (storage.foldername(name))[1] = (select auth.uid())::text or
      exists (select 1 from public.voice_posts v where v.audio_path = name and v.visibility = 'public') or
      exists (select 1 from public.requests r where r.audio_path = name and r.status = 'open') or
      exists (
        select 1 from public.applications a
        join public.requests r on r.id = a.request_id
        where a.audio_path = name and
          (a.user_id = (select auth.uid()) or r.user_id = (select auth.uid()))
      )
    )
  );

create policy "Users delete their uploaded audio"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'audio-private' and
    (storage.foldername(name))[1] = (select auth.uid())::text
  );
