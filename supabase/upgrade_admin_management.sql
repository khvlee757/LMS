-- ==============================================================================
-- Upgrade: Allow Super Admins to provision other Super Admins
-- ==============================================================================

-- 1. Update trigger to allow existing super_admin to grant/manage all roles
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
    if not (select private.is_super_admin()) then
      raise exception 'Only an existing super administrator can change user roles';
    end if;

    if new.role = 'instructor'::public.app_role then
      if not exists (
        select 1 from public.instructor_applications a
        where a.user_id = new.user_id and a.status = 'approved'
      ) then
        raise exception 'An approved instructor application is required';
      end if;
    end if;
  end if;

  new.updated_at = now();
  return new;
end;
$$;

revoke all on function private.protect_profile_role() from public, anon, authenticated;

-- 2. Secure RPC to grant super_admin to any registered user by email
create or replace function public.add_super_admin(target_email text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_user record;
begin
  if not (select private.is_super_admin()) then
    raise exception 'Unauthorized: Only an existing super admin can grant administrator clearance';
  end if;

  select * into target_user from public.profiles
  where email = lower(trim(target_email));

  if not found then
    raise exception 'No user account found with email "%". Make sure they have registered first.', target_email;
  end if;

  update public.profiles
  set role = 'super_admin'::public.app_role,
      updated_at = now()
  where user_id = target_user.user_id;

  return jsonb_build_object(
    'success', true,
    'user_id', target_user.user_id,
    'email', target_user.email,
    'full_name', target_user.full_name
  );
end;
$$;

-- 3. Secure RPC to demote an administrator back to learner
create or replace function public.demote_super_admin(target_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not (select private.is_super_admin()) then
    raise exception 'Unauthorized: Only an existing super admin can manage administrator clearance';
  end if;

  if target_user_id = (select auth.uid()) then
    raise exception 'Cannot demote your own active super admin account';
  end if;

  update public.profiles
  set role = 'student'::public.app_role,
      updated_at = now()
  where user_id = target_user_id;

  return jsonb_build_object('success', true, 'user_id', target_user_id);
end;
$$;

revoke all on function public.add_super_admin(text) from public, anon;
grant execute on function public.add_super_admin(text) to authenticated;
revoke all on function public.demote_super_admin(uuid) from public, anon;
grant execute on function public.demote_super_admin(uuid) to authenticated;


-- ==============================================================================
-- 4. Allow Super Admins to insert/upsert instructor applications without RLS violation
-- ==============================================================================
drop policy if exists instructor_applications_insert_self_pending on public.instructor_applications;
drop policy if exists instructor_applications_insert_self_or_admin on public.instructor_applications;
create policy instructor_applications_insert_self_or_admin on public.instructor_applications
for insert to authenticated
with check (
  (select private.is_super_admin())
  or (
    user_id = (select auth.uid())
    and status = 'pending'
    and reviewed_by is null
    and reviewed_at is null
  )
);

-- ==============================================================================
-- 5. Secure RPC to review/approve an instructor application atomically
-- ==============================================================================
create or replace function public.admin_review_instructor_application(
  target_user_id uuid,
  new_status text,
  notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_role public.app_role;
begin
  if not (select private.is_super_admin()) then
    raise exception 'Unauthorized: Only an existing super admin can review instructor applications';
  end if;

  if new_status not in ('approved', 'rejected', 'pending') then
    raise exception 'Invalid status: %', new_status;
  end if;

  -- Upsert application record with security definer privileges
  insert into public.instructor_applications (
    user_id, organization, professional_title, expertise,
    experience_years, qualification, verification_url, teaching_statement,
    status, review_notes, reviewed_by, reviewed_at
  ) values (
    target_user_id,
    'Verified Educator', 'Instructor', 'General',
    1, 'Verified by Super Admin', '', 'Verified by Super Admin',
    new_status::public.application_status,
    notes,
    (select auth.uid()),
    now()
  )
  on conflict (user_id) do update set
    status = excluded.status,
    review_notes = excluded.review_notes,
    reviewed_by = excluded.reviewed_by,
    reviewed_at = excluded.reviewed_at,
    updated_at = now();

  -- Update profiles role
  target_role := case when new_status = 'approved' then 'instructor'::public.app_role else 'student'::public.app_role end;
  update public.profiles
  set role = target_role,
      updated_at = now()
  where user_id = target_user_id;

  return jsonb_build_object(
    'success', true,
    'user_id', target_user_id,
    'status', new_status,
    'role', target_role
  );
end;
$$;

revoke all on function public.admin_review_instructor_application(uuid, text, text) from public, anon;
grant execute on function public.admin_review_instructor_application(uuid, text, text) to authenticated;
