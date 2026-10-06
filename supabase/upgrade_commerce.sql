alter table public.courses add column if not exists is_free boolean not null default true;
alter table public.courses add column if not exists price_minor bigint not null default 0 check (price_minor >= 0);
alter table public.courses add column if not exists currency text not null default 'NGN' check (char_length(currency) = 3);

do $$ begin
  alter table public.courses
    add constraint courses_paid_price_positive check (is_free or price_minor > 0);
exception when duplicate_object then null;
end $$;

create table if not exists public.books (
  id uuid primary key default gen_random_uuid(),
  instructor_id uuid not null references public.profiles (user_id) on delete restrict,
  title text not null check (char_length(title) between 1 and 180),
  description text not null default '',
  category text not null default 'General',
  is_free boolean not null default true,
  price_minor bigint not null default 0 check (price_minor >= 0),
  currency text not null default 'NGN' check (char_length(currency) = 3),
  file_path text,
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (is_free or price_minor > 0)
);

create table if not exists public.instructor_payout_accounts (
  user_id uuid primary key references public.profiles (user_id) on delete cascade,
  paystack_subaccount_code text not null unique,
  created_at timestamptz not null default now()
);
alter table public.instructor_payout_accounts enable row level security;
revoke all on public.instructor_payout_accounts from public, anon, authenticated;

create table if not exists public.payment_orders (
  id uuid primary key default gen_random_uuid(),
  receipt_number text not null unique default ('NSL-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12))),
  buyer_id uuid not null references public.profiles (user_id) on delete restrict,
  instructor_id uuid not null references public.profiles (user_id) on delete restrict,
  product_type text not null check (product_type in ('course', 'book')),
  course_id uuid references public.courses (id) on delete restrict,
  book_id uuid references public.books (id) on delete restrict,
  amount_minor bigint not null check (amount_minor > 0),
  platform_fee_minor bigint not null check (platform_fee_minor >= 0),
  currency text not null check (char_length(currency) = 3),
  provider text not null default 'paystack' check (provider = 'paystack'),
  provider_reference text not null unique,
  status text not null default 'pending' check (status in ('pending', 'paid', 'failed', 'refunded')),
  created_at timestamptz not null default now(),
  paid_at timestamptz,
  check (
    (product_type = 'course' and course_id is not null and book_id is null)
    or (product_type = 'book' and book_id is not null and course_id is null)
  )
);

create table if not exists public.book_access (
  book_id uuid not null references public.books (id) on delete cascade,
  student_id uuid not null references public.profiles (user_id) on delete cascade,
  payment_order_id uuid references public.payment_orders (id) on delete set null,
  granted_at timestamptz not null default now(),
  primary key (book_id, student_id)
);

create index if not exists books_instructor_created_idx on public.books (instructor_id, created_at desc);
create index if not exists payment_orders_buyer_created_idx on public.payment_orders (buyer_id, created_at desc);
create index if not exists payment_orders_instructor_created_idx on public.payment_orders (instructor_id, created_at desc);
create index if not exists payment_orders_status_created_idx on public.payment_orders (status, created_at desc);
create index if not exists book_access_student_idx on public.book_access (student_id, granted_at desc);

alter table public.books enable row level security;
alter table public.payment_orders enable row level security;
alter table public.book_access enable row level security;

revoke all on public.books, public.payment_orders, public.book_access from anon, authenticated;
grant select, insert, update, delete on public.books to authenticated;
grant select on public.payment_orders, public.book_access to authenticated;

drop policy if exists books_select_published_or_owner on public.books;
create policy books_select_published_or_owner on public.books
for select to authenticated
using (
  published
  or instructor_id = (select auth.uid())
  or (select private.is_super_admin())
  or exists (
    select 1 from public.book_access a
    where a.book_id = id and a.student_id = (select auth.uid())
  )
);
drop policy if exists books_insert_instructor on public.books;
create policy books_insert_instructor on public.books
for insert to authenticated
with check (
  instructor_id = (select auth.uid())
  and (select private.is_instructor())
);
drop policy if exists books_update_manager on public.books;
create policy books_update_manager on public.books
for update to authenticated
using (instructor_id = (select auth.uid()) or (select private.is_super_admin()))
with check (instructor_id = (select auth.uid()) or (select private.is_super_admin()));
drop policy if exists books_delete_manager on public.books;
create policy books_delete_manager on public.books
for delete to authenticated
using (instructor_id = (select auth.uid()) or (select private.is_super_admin()));

drop policy if exists payment_orders_select_participant on public.payment_orders;
create policy payment_orders_select_participant on public.payment_orders
for select to authenticated
using (
  buyer_id = (select auth.uid())
  or instructor_id = (select auth.uid())
  or (select private.is_super_admin())
);

drop policy if exists book_access_select_owner_or_student on public.book_access;
create policy book_access_select_owner_or_student on public.book_access
for select to authenticated
using (
  student_id = (select auth.uid())
  or (select private.is_super_admin())
  or exists (
    select 1 from public.books b
    where b.id = book_id and b.instructor_id = (select auth.uid())
  )
);

-- Paid courses cannot be enrolled in until a verified payment has been recorded.
drop policy if exists enrollments_insert_self_published on public.enrollments;
create policy enrollments_insert_self_published on public.enrollments
for insert to authenticated
with check (
  user_id = (select auth.uid())
  and exists (
    select 1 from public.courses c
    where c.id = course_id
      and c.published
      and (
        c.is_free
        or exists (
          select 1 from public.payment_orders p
          where p.course_id = c.id
            and p.buyer_id = (select auth.uid())
            and p.status = 'paid'
        )
      )
  )
);

-- Create this private bucket if Storage is enabled for the project.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'lms-private-files',
  'lms-private-files',
  false,
  6291456,
  array[
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'image/jpeg', 'image/png', 'image/webp', 'text/plain', 'text/markdown', 'video/mp4'
  ]
)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Material paths: course-id/materials/uploader-id/file.
drop policy if exists lms_private_files_select on storage.objects;
create policy lms_private_files_select on storage.objects
for select to authenticated
using (
  bucket_id = 'lms-private-files'
  and (
    exists (
      select 1 from public.courses c
      where c.id::text = (storage.foldername(name))[1]
        and (storage.foldername(name))[2] = 'materials'
        and (select private.can_access_course(c.id))
    )
    or exists (
      select 1 from public.assignments a
      join public.enrollments e on e.course_id = a.course_id
      where a.id::text = (storage.foldername(name))[3]
        and a.course_id::text = (storage.foldername(name))[1]
        and (storage.foldername(name))[2] = 'assignment-resources'
        and a.published
        and e.user_id = (select auth.uid())
    )
    or exists (
      select 1 from public.assignments a
      where a.id::text = (storage.foldername(name))[3]
        and a.course_id::text = (storage.foldername(name))[1]
        and (storage.foldername(name))[2] = 'assignment-resources'
        and (select private.can_manage_course(a.course_id))
    )
    or exists (
      select 1 from public.assignments a
      where a.id::text = (storage.foldername(name))[3]
        and a.course_id::text = (storage.foldername(name))[1]
        and (storage.foldername(name))[2] = 'submissions'
        and (select private.can_manage_course(a.course_id))
    )
    or exists (
      select 1 from public.books b
      where b.id::text = (storage.foldername(name))[1]
        and (storage.foldername(name))[2] = 'books'
        and (
          b.is_free
          or b.instructor_id = (select auth.uid())
          or (select private.is_super_admin())
          or exists (
            select 1 from public.book_access ba
            where ba.book_id = b.id and ba.student_id = (select auth.uid())
          )
        )
    )
    or (
      (storage.foldername(name))[2] = 'submissions'
      and (storage.foldername(name))[4] = (select auth.uid())::text
      and exists (
        select 1 from public.assignments a
        join public.enrollments e on e.course_id = a.course_id
        where a.id::text = (storage.foldername(name))[3]
          and a.course_id::text = (storage.foldername(name))[1]
          and a.published
          and e.user_id = (select auth.uid())
      )
    )
  )
);

drop policy if exists lms_private_files_insert on storage.objects;
create policy lms_private_files_insert on storage.objects
for insert to authenticated
with check (
  bucket_id = 'lms-private-files'
  and (
    exists (
      select 1 from public.courses c
      where c.id::text = (storage.foldername(name))[1]
        and (storage.foldername(name))[2] = 'materials'
        and (storage.foldername(name))[3] = (select auth.uid())::text
        and (select private.can_manage_course(c.id))
    )
    or exists (
      select 1 from public.assignments a
      where a.id::text = (storage.foldername(name))[3]
        and a.course_id::text = (storage.foldername(name))[1]
        and (storage.foldername(name))[2] = 'assignment-resources'
        and (storage.foldername(name))[4] = (select auth.uid())::text
        and (select private.can_manage_course(a.course_id))
    )
    or exists (
      select 1 from public.books b
      where b.id::text = (storage.foldername(name))[1]
        and (storage.foldername(name))[2] = 'books'
        and (storage.foldername(name))[3] = (select auth.uid())::text
        and (b.instructor_id = (select auth.uid()) or (select private.is_super_admin()))
    )
    or exists (
      select 1 from public.assignments a
      join public.enrollments e on e.course_id = a.course_id
      where a.id::text = (storage.foldername(name))[3]
        and a.course_id::text = (storage.foldername(name))[1]
        and (storage.foldername(name))[2] = 'submissions'
        and (storage.foldername(name))[4] = (select auth.uid())::text
        and a.published
        and (a.due_at is null or a.due_at >= now())
        and e.user_id = (select auth.uid())
    )
  )
);

drop policy if exists lms_private_files_delete on storage.objects;
create policy lms_private_files_delete on storage.objects
for delete to authenticated
using (
  bucket_id = 'lms-private-files'
  and (
    (storage.foldername(name))[4] = (select auth.uid())::text
    or exists (
      select 1 from public.courses c
      where c.id::text = (storage.foldername(name))[1]
        and (select private.can_manage_course(c.id))
    )
    or exists (
      select 1 from public.books b
      where b.id::text = (storage.foldername(name))[1]
        and (b.instructor_id = (select auth.uid()) or (select private.is_super_admin()))
    )
  )
);
