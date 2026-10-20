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
