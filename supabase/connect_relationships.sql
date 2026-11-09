-- ISM Digital Museum: post-deployment FK relationships (safe to re-run).
-- Applied to Supabase project eycvjafolcdyjrpjxxqh on 2026-11-09.
-- Designed to preserve all existing teachers, events, milestones and exhibits.
alter table public.exhibits add column if not exists category_id uuid;
alter table public.events add column if not exists coordinator_teacher_id text;
alter table public.events add column if not exists created_by uuid;
alter table public.milestones add column if not exists related_event_id text;

update public.exhibits e set category_id=c.id
from public.exhibition_categories c
where e.category_id is null and e.category=c.name;

do $$
begin
 if not exists(select 1 from pg_constraint where conname='exhibits_category_id_fkey' and conrelid='public.exhibits'::regclass) then
  alter table public.exhibits add constraint exhibits_category_id_fkey
    foreign key (category_id) references public.exhibition_categories(id) on update cascade on delete set null;
 end if;
 if not exists(select 1 from pg_constraint where conname='exhibits_creator_profile_fkey' and conrelid='public.exhibits'::regclass) then
  alter table public.exhibits add constraint exhibits_creator_profile_fkey
    foreign key (creator_id) references public.profiles(id) on update cascade on delete cascade;
 end if;
 if not exists(select 1 from pg_constraint where conname='events_coordinator_teacher_id_fkey' and conrelid='public.events'::regclass) then
  alter table public.events add constraint events_coordinator_teacher_id_fkey
    foreign key (coordinator_teacher_id) references public.teachers(id) on update cascade on delete set null;
 end if;
 if not exists(select 1 from pg_constraint where conname='events_created_by_fkey' and conrelid='public.events'::regclass) then
  alter table public.events add constraint events_created_by_fkey
    foreign key (created_by) references public.profiles(id) on update cascade on delete set null;
 end if;
 if not exists(select 1 from pg_constraint where conname='milestones_related_event_id_fkey' and conrelid='public.milestones'::regclass) then
  alter table public.milestones add constraint milestones_related_event_id_fkey
    foreign key (related_event_id) references public.events(id) on update cascade on delete set null;
 end if;
end $$;
create index if not exists exhibits_category_id_idx on public.exhibits(category_id);
create index if not exists events_coordinator_teacher_id_idx on public.events(coordinator_teacher_id);
create index if not exists events_created_by_idx on public.events(created_by);
create index if not exists milestones_related_event_id_idx on public.milestones(related_event_id);
