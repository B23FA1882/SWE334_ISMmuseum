-- ISM Digital Museum — run in a NEW, dedicated Supabase project.
-- DO NOT apply to the existing plant-store project: it already has public.profiles.
create extension if not exists pgcrypto;
create schema if not exists private;

create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default '',
 avatar_url text,
 created_at timestamptz not null default now()
);
create table if not exists public.museum_admins (
 user_id uuid primary key references auth.users(id) on delete cascade,
 created_at timestamptz not null default now()
);
create table if not exists public.exhibition_categories (
 id uuid primary key default gen_random_uuid(),
 name text unique not null,
 description text,
 created_at timestamptz not null default now()
);
create table if not exists public.teachers (
 id text primary key default gen_random_uuid()::text,
 name text not null,
 position text not null default 'Багш',
 degree text,
 courses text[] not null default '{}',
 bio text,
 education text,
 email text,
 office text,
 photo_url text,
 created_at timestamptz not null default now()
);
create table if not exists public.events (
 id text primary key default gen_random_uuid()::text,
 title text not null,
 event_date date not null,
 description text not null default '',
 type text,
 venue text,
 cover_image_url text,
 created_at timestamptz not null default now()
);
create table if not exists public.event_photos (
 id uuid primary key default gen_random_uuid(),
 event_id text not null references public.events(id) on delete cascade,
 image_url text not null,
 caption text,
 created_at timestamptz not null default now()
);
create table if not exists public.exhibits (
 id uuid primary key default gen_random_uuid(),
 title text not null check(length(title)<=160),
 description text not null,
 image_url text,
 category text,
 technology_stack text[] not null default '{}',
 year_created integer check (year_created between 1964 and 2100),
 creator_id uuid not null references auth.users(id) on delete cascade,
 demo_url text,
 github_url text,
 status text not null default 'pending' check(status in ('draft','pending','published')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.milestones (
 id uuid primary key default gen_random_uuid(),
 year integer not null,
 title text not null,
 description text,
 created_at timestamptz not null default now(),
 unique(year,title)
);
create index if not exists exhibits_status_year_idx on public.exhibits(status,year_created desc);
create index if not exists exhibits_creator_idx on public.exhibits(creator_id);
create index if not exists events_date_idx on public.events(event_date desc);
create index if not exists event_photos_event_idx on public.event_photos(event_id);

-- Users are created by Supabase Auth; this internal trigger copies public profile details.
create or replace function private.museum_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
 insert into public.profiles(id, display_name)
 values(new.id, coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email,'@',1),''))
 on conflict (id) do nothing;
 return new;
end; $$;
revoke all on function private.museum_new_user() from public, anon, authenticated;
drop trigger if exists museum_new_user on auth.users;
create trigger museum_new_user after insert on auth.users for each row execute function private.museum_new_user();

-- Authenticated clients may update profile display fields, never role/membership.
revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to anon, authenticated;
grant update(display_name,avatar_url) on public.profiles to authenticated;
grant select on public.museum_admins to authenticated;
grant select on public.teachers, public.events, public.event_photos, public.exhibition_categories, public.milestones, public.exhibits to anon, authenticated;
grant insert,update,delete on public.teachers, public.events, public.event_photos, public.exhibition_categories, public.milestones, public.exhibits to authenticated;

alter table public.profiles enable row level security;
alter table public.museum_admins enable row level security;
alter table public.teachers enable row level security;
alter table public.events enable row level security;
alter table public.event_photos enable row level security;
alter table public.exhibition_categories enable row level security;
alter table public.exhibits enable row level security;
alter table public.milestones enable row level security;

create policy "profiles_public_read" on public.profiles for select to anon, authenticated using (true);
create policy "profiles_owner_update" on public.profiles for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy "admins_read_own" on public.museum_admins for select to authenticated using (user_id = (select auth.uid()));

create policy "teachers_public_read" on public.teachers for select to anon, authenticated using (true);
create policy "teachers_admin_insert" on public.teachers for insert to authenticated with check (exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid())));
create policy "teachers_admin_update" on public.teachers for update to authenticated using (exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid()))) with check (exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid())));
create policy "teachers_admin_delete" on public.teachers for delete to authenticated using (exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid())));

create policy "events_public_read" on public.events for select to anon, authenticated using (true);
create policy "events_admin_insert" on public.events for insert to authenticated with check (exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid())));
create policy "events_admin_update" on public.events for update to authenticated using (exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid()))) with check (exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid())));
create policy "events_admin_delete" on public.events for delete to authenticated using (exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid())));

create policy "photos_public_read" on public.event_photos for select to anon, authenticated using (true);
create policy "photos_admin_insert" on public.event_photos for insert to authenticated with check (exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid())));
create policy "photos_admin_update" on public.event_photos for update to authenticated using (exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid()))) with check (exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid())));
create policy "photos_admin_delete" on public.event_photos for delete to authenticated using (exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid())));

create policy "categories_public_read" on public.exhibition_categories for select to anon, authenticated using (true);
create policy "categories_admin_insert" on public.exhibition_categories for insert to authenticated with check (exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid())));
create policy "categories_admin_update" on public.exhibition_categories for update to authenticated using (exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid()))) with check (exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid())));
create policy "categories_admin_delete" on public.exhibition_categories for delete to authenticated using (exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid())));
create policy "milestones_public_read" on public.milestones for select to anon, authenticated using (true);
create policy "milestones_admin_insert" on public.milestones for insert to authenticated with check (exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid())));
create policy "milestones_admin_update" on public.milestones for update to authenticated using (exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid()))) with check (exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid())));
create policy "milestones_admin_delete" on public.milestones for delete to authenticated using (exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid())));

create policy "exhibits_read_published_or_own_or_admin" on public.exhibits for select to anon,authenticated using (
 status = 'published' or creator_id = (select auth.uid()) or exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid()))
);
create policy "exhibits_create_own_pending" on public.exhibits for insert to authenticated with check (
 creator_id = (select auth.uid()) and status in ('draft','pending')
);
create policy "exhibits_edit_own_or_admin" on public.exhibits for update to authenticated
 using (creator_id = (select auth.uid()) or exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid())))
 with check ((creator_id = (select auth.uid()) and status in ('draft','pending')) or exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid())));
create policy "exhibits_delete_own_or_admin" on public.exhibits for delete to authenticated
 using (creator_id = (select auth.uid()) or exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid())));

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
 values('museum-assets','museum-assets',true,5242880,array['image/jpeg','image/png','image/webp','image/gif'])
 on conflict (id) do nothing;
create policy "museum_assets_upload_own_or_admin" on storage.objects for insert to authenticated
 with check(bucket_id='museum-assets' and (
 ((storage.foldername(name))[1]='exhibits' and (storage.foldername(name))[2]=(select auth.uid())::text)
 or ((storage.foldername(name))[1]='admin' and exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid())))
 ));
create policy "museum_assets_list_owner_or_admin" on storage.objects for select to authenticated
 using(bucket_id='museum-assets' and (owner_id=(select auth.uid())::text or exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid()))));
create policy "museum_assets_update_owner_or_admin" on storage.objects for update to authenticated
 using(bucket_id='museum-assets' and (owner_id=(select auth.uid())::text or exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid()))))
 with check(bucket_id='museum-assets' and (owner_id=(select auth.uid())::text or exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid()))));
create policy "museum_assets_delete_owner_or_admin" on storage.objects for delete to authenticated
 using(bucket_id='museum-assets' and (owner_id=(select auth.uid())::text or exists(select 1 from public.museum_admins a where a.user_id = (select auth.uid()))));

-- First sign up via the app; then, in the Supabase SQL editor (trusted admin only), grant yourself the admin role:
-- insert into public.museum_admins(user_id) select id from auth.users where email = 'YOUR_EMAIL@example.com' on conflict do nothing;
