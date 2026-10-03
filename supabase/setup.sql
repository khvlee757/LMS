create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

do $$ begin
  create type public.app_role as enum ('student', 'instructor', 'super_admin');
exception when duplicate_object then null;
end $$;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  email text not null unique,
  full_name text not null default '',
  phone text,
  role public.app_role not null default 'student',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.instructor_applications (
  user_id uuid primary key references public.profiles (user_id) on delete cascade,
  organization text not null check (char_length(organization) between 1 and 160),
  professional_title text not null check (char_length(professional_title) between 1 and 120),
  expertise text not null check (char_length(expertise) between 1 and 160),
  experience_years smallint not null check (experience_years between 0 and 60),
  qualification text not null check (char_length(qualification) between 1 and 1000),
  verification_url text not null check (verification_url ~* '^https?://[^[:space:]]+[.][^[:space:]]+$'),
  teaching_statement text not null check (char_length(teaching_statement) between 1 and 1500),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  review_notes text,
  reviewed_by uuid references public.profiles (user_id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.courses (
  id uuid primary key default gen_random_uuid(),
  instructor_id uuid not null references public.profiles (user_id) on delete restrict,
  title text not null check (char_length(title) between 1 and 160),
  description text not null default '',
  category text not null default 'General',
  level text not null default 'beginner' check (level in ('beginner', 'intermediate', 'advanced')),
  thumbnail_url text,
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.lessons (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses (id) on delete cascade,
  title text not null check (char_length(title) between 1 and 160),
  content_body text not null default '',
  content_url text,
  position integer not null default 0 check (position >= 0),
  duration_minutes integer check (duration_minutes is null or duration_minutes >= 0),
  created_at timestamptz not null default now(),
  unique (id, course_id),
  unique (course_id, position)
);

create table if not exists public.enrollments (
  user_id uuid not null references public.profiles (user_id) on delete cascade,
  course_id uuid not null references public.courses (id) on delete cascade,
  enrolled_at timestamptz not null default now(),
  primary key (user_id, course_id)
);

create table if not exists public.lesson_progress (
  user_id uuid not null references public.profiles (user_id) on delete cascade,
  course_id uuid not null references public.courses (id) on delete cascade,
  lesson_id uuid not null,
  completed boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id, lesson_id),
  foreign key (lesson_id, course_id) references public.lessons (id, course_id) on delete cascade
);

create index if not exists courses_instructor_id_idx on public.courses (instructor_id);
create index if not exists lessons_course_position_idx on public.lessons (course_id, position);
create index if not exists enrollments_course_user_idx on public.enrollments (course_id, user_id);
create index if not exists lesson_progress_course_id_idx on public.lesson_progress (course_id);

create or replace function private.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.user_id = (select auth.uid())
      and p.role = 'super_admin'::public.app_role
  );
$$;

create or replace function private.is_instructor()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.user_id = (select auth.uid())
      and p.role in ('instructor'::public.app_role, 'super_admin'::public.app_role)
  );
$$;

create or replace function private.can_manage_course(target_course_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.courses c
    join public.profiles p on p.user_id = (select auth.uid())
    where c.id = target_course_id
      and (p.role = 'super_admin'::public.app_role
        or (p.role = 'instructor'::public.app_role and c.instructor_id = (select auth.uid())))
  );
$$;

create or replace function private.can_access_course(target_course_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.courses c
    where c.id = target_course_id
      and (
        c.instructor_id = (select auth.uid())
        or (select private.is_super_admin())
        or exists (
          select 1 from public.enrollments e
          where e.course_id = c.id and e.user_id = (select auth.uid())
        )
      )
  );
$$;

revoke all on function private.is_super_admin() from public, anon;
revoke all on function private.is_instructor() from public, anon;
revoke all on function private.can_manage_course(uuid) from public, anon;
revoke all on function private.can_access_course(uuid) from public, anon;
grant execute on function private.is_super_admin() to authenticated;
grant execute on function private.is_instructor() to authenticated;
grant execute on function private.can_manage_course(uuid) to authenticated;
grant execute on function private.can_access_course(uuid) to authenticated;

create or replace function private.create_profile_for_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (user_id, email, full_name, phone)
  values (
    new.id,
    lower(new.email),
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.raw_user_meta_data ->> 'phone'
  )
  on conflict (user_id) do update
    set email = excluded.email,
        full_name = excluded.full_name,
        phone = excluded.phone,
        updated_at = now();

  if new.raw_user_meta_data ->> 'account_type' = 'instructor' then
    insert into public.instructor_applications (
      user_id, organization, professional_title, expertise, experience_years,
      qualification, verification_url, teaching_statement
    ) values (
      new.id,
      new.raw_user_meta_data -> 'instructor_application' ->> 'organization',
      new.raw_user_meta_data -> 'instructor_application' ->> 'professional_title',
      new.raw_user_meta_data -> 'instructor_application' ->> 'expertise',
      (new.raw_user_meta_data -> 'instructor_application' ->> 'experience_years')::smallint,
      new.raw_user_meta_data -> 'instructor_application' ->> 'qualification',
      new.raw_user_meta_data -> 'instructor_application' ->> 'verification_url',
      new.raw_user_meta_data -> 'instructor_application' ->> 'teaching_statement'
    ) on conflict (user_id) do nothing;
  end if;

  return new;
end;
$$;

revoke all on function private.create_profile_for_auth_user() from public, anon, authenticated;
drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
after insert on auth.users
for each row execute function private.create_profile_for_auth_user();

create or replace function private.protect_profile_role()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.user_id is distinct from old.user_id then
    raise exception 'Profile ownership cannot be changed';
  end if;

  if new.role is distinct from old.role then
    if old.role = 'super_admin'::public.app_role
      or new.role = 'super_admin'::public.app_role then
      if (select auth.uid()) is not null then
        raise exception 'Super-admin access can only be provisioned from the database';
      end if;
    elsif new.role = 'instructor'::public.app_role then
      if not (select private.is_super_admin()) or not exists (
        select 1 from public.instructor_applications a
        where a.user_id = new.user_id and a.status = 'approved'
      ) then
        raise exception 'An approved instructor application is required';
      end if;
    elsif not (select private.is_super_admin()) then
      raise exception 'Only the super admin can change account roles';
    end if;
  end if;

  new.updated_at = now();
  return new;
end;
$$;

revoke all on function private.protect_profile_role() from public, anon, authenticated;
drop trigger if exists protect_profile_role on public.profiles;
create trigger protect_profile_role
before update on public.profiles
for each row execute function private.protect_profile_role();

create or replace function private.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke all on function private.touch_updated_at() from public, anon, authenticated;
drop trigger if exists courses_touch_updated_at on public.courses;
create trigger courses_touch_updated_at before update on public.courses
for each row execute function private.touch_updated_at();
drop trigger if exists lesson_progress_touch_updated_at on public.lesson_progress;
create trigger lesson_progress_touch_updated_at before update on public.lesson_progress
for each row execute function private.touch_updated_at();

alter table public.profiles enable row level security;
alter table public.instructor_applications enable row level security;
alter table public.courses enable row level security;
alter table public.lessons enable row level security;
alter table public.enrollments enable row level security;
alter table public.lesson_progress enable row level security;

revoke all on public.profiles, public.instructor_applications, public.courses, public.lessons, public.enrollments, public.lesson_progress from anon, authenticated;
grant usage on schema public to authenticated;
grant select, update on public.profiles to authenticated;
grant select, insert, update on public.instructor_applications to authenticated;
grant select, insert, update, delete on public.courses to authenticated;
grant select, insert, update, delete on public.lessons to authenticated;
grant select, insert, delete on public.enrollments to authenticated;
grant select, insert, update, delete on public.lesson_progress to authenticated;

drop policy if exists profiles_select_self_or_admin on public.profiles;
create policy profiles_select_self_or_admin on public.profiles
for select to authenticated
using (user_id = (select auth.uid()) or (select private.is_super_admin()));

drop policy if exists profiles_update_self_or_admin on public.profiles;
create policy profiles_update_self_or_admin on public.profiles
for update to authenticated
using (user_id = (select auth.uid()) or (select private.is_super_admin()))
with check (user_id = (select auth.uid()) or (select private.is_super_admin()));

drop policy if exists instructor_applications_select_self_or_admin on public.instructor_applications;
create policy instructor_applications_select_self_or_admin on public.instructor_applications
for select to authenticated
using (user_id = (select auth.uid()) or (select private.is_super_admin()));

drop policy if exists instructor_applications_insert_self_pending on public.instructor_applications;
create policy instructor_applications_insert_self_pending on public.instructor_applications
for insert to authenticated
with check (
  user_id = (select auth.uid())
  and status = 'pending'
  and reviewed_by is null
  and reviewed_at is null
);

drop policy if exists instructor_applications_update_admin on public.instructor_applications;
create policy instructor_applications_update_admin on public.instructor_applications
for update to authenticated
using ((select private.is_super_admin()))
with check ((select private.is_super_admin()));

drop policy if exists courses_select_available on public.courses;
create policy courses_select_available on public.courses
for select to authenticated
using (published or instructor_id = (select auth.uid()) or (select private.is_super_admin()));

drop policy if exists courses_insert_instructor_or_admin on public.courses;
create policy courses_insert_instructor_or_admin on public.courses
for insert to authenticated
with check (
  (select private.is_super_admin())
  or (instructor_id = (select auth.uid()) and (select private.is_instructor()))
);

drop policy if exists courses_update_manager on public.courses;
create policy courses_update_manager on public.courses
for update to authenticated
using ((select private.can_manage_course(id)))
with check ((select private.can_manage_course(id)));

drop policy if exists courses_delete_manager on public.courses;
create policy courses_delete_manager on public.courses
for delete to authenticated
using ((select private.can_manage_course(id)));

drop policy if exists lessons_select_accessible_course on public.lessons;
create policy lessons_select_accessible_course on public.lessons
for select to authenticated
using ((select private.can_access_course(course_id)));

drop policy if exists lessons_insert_course_manager on public.lessons;
create policy lessons_insert_course_manager on public.lessons
for insert to authenticated
with check ((select private.can_manage_course(course_id)));

drop policy if exists lessons_update_course_manager on public.lessons;
create policy lessons_update_course_manager on public.lessons
for update to authenticated
using ((select private.can_manage_course(course_id)))
with check ((select private.can_manage_course(course_id)));

drop policy if exists lessons_delete_course_manager on public.lessons;
create policy lessons_delete_course_manager on public.lessons
for delete to authenticated
using ((select private.can_manage_course(course_id)));

drop policy if exists enrollments_select_self_or_admin on public.enrollments;
create policy enrollments_select_self_or_admin on public.enrollments
for select to authenticated
using (user_id = (select auth.uid()) or (select private.is_super_admin()));

drop policy if exists enrollments_insert_self_published on public.enrollments;
create policy enrollments_insert_self_published on public.enrollments
for insert to authenticated
with check (
  user_id = (select auth.uid())
  and exists (
    select 1 from public.courses c
    where c.id = course_id and c.published
  )
);

drop policy if exists enrollments_delete_self_or_admin on public.enrollments;
create policy enrollments_delete_self_or_admin on public.enrollments
for delete to authenticated
using (user_id = (select auth.uid()) or (select private.is_super_admin()));

drop policy if exists progress_select_self_or_admin on public.lesson_progress;
create policy progress_select_self_or_admin on public.lesson_progress
for select to authenticated
using (user_id = (select auth.uid()) or (select private.is_super_admin()));

drop policy if exists progress_insert_self_enrolled on public.lesson_progress;
create policy progress_insert_self_enrolled on public.lesson_progress
for insert to authenticated
with check (
  user_id = (select auth.uid())
  and exists (
    select 1 from public.enrollments e
    where e.user_id = (select auth.uid()) and e.course_id = course_id
  )
);

drop policy if exists progress_update_self_enrolled on public.lesson_progress;
create policy progress_update_self_enrolled on public.lesson_progress
for update to authenticated
using (user_id = (select auth.uid()) or (select private.is_super_admin()))
with check (
  (user_id = (select auth.uid()) and exists (
    select 1 from public.enrollments e
    where e.user_id = (select auth.uid()) and e.course_id = course_id
  ))
  or (select private.is_super_admin())
);

drop policy if exists progress_delete_self_or_admin on public.lesson_progress;
create policy progress_delete_self_or_admin on public.lesson_progress
for delete to authenticated
using (user_id = (select auth.uid()) or (select private.is_super_admin()));

-- After the owner has registered and confirmed their email, run this once in
-- the Supabase SQL Editor with the owner's email address substituted below.
-- The trigger blocks super-admin promotion from authenticated client requests.
-- update public.profiles
-- set role = 'super_admin'
-- where email = lower('owner@example.com');
