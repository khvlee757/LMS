create table if not exists public.login_activity (
  user_id uuid not null references public.profiles (user_id) on delete cascade,
  activity_date date not null default current_date,
  created_at timestamptz not null default now(),
  primary key (user_id, activity_date)
);

create table if not exists public.quizzes (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses (id) on delete cascade,
  title text not null check (char_length(title) between 1 and 160),
  instructions text not null default '',
  time_limit_minutes integer check (time_limit_minutes is null or time_limit_minutes between 1 and 1440),
  published boolean not null default false,
  created_at timestamptz not null default now(),
  unique (id, course_id)
);

create table if not exists public.quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes (id) on delete cascade,
  prompt text not null check (char_length(prompt) between 1 and 3000),
  options jsonb not null check (
    case when jsonb_typeof(options) = 'array'
      then jsonb_array_length(options) between 2 and 8
      else false
    end
  ),
  position integer not null check (position >= 0),
  points smallint not null default 1 check (points between 1 and 100),
  unique (quiz_id, position)
);

create table if not exists private.quiz_answer_keys (
  question_id uuid primary key references public.quiz_questions (id) on delete cascade,
  correct_option smallint not null check (correct_option between 0 and 7)
);
revoke all on table private.quiz_answer_keys from public, anon, authenticated;

create table if not exists public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes (id) on delete cascade,
  user_id uuid not null references public.profiles (user_id) on delete cascade,
  answers jsonb not null,
  score integer not null check (score >= 0),
  possible_score integer not null check (possible_score >= score),
  submitted_at timestamptz not null default now()
);

create table if not exists public.assignments (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses (id) on delete cascade,
  title text not null check (char_length(title) between 1 and 160),
  instructions text not null default '',
  due_at timestamptz,
  points integer not null default 100 check (points between 1 and 10000),
  published boolean not null default false,
  created_at timestamptz not null default now(),
  unique (id, course_id)
);

create table if not exists public.assignment_submissions (
  assignment_id uuid not null references public.assignments (id) on delete cascade,
  student_id uuid not null references public.profiles (user_id) on delete cascade,
  response text not null default '',
  attachment_url text,
  submitted_at timestamptz not null default now(),
  primary key (assignment_id, student_id)
);

create table if not exists public.assignment_reviews (
  assignment_id uuid not null references public.assignments (id) on delete cascade,
  student_id uuid not null references public.profiles (user_id) on delete cascade,
  grade numeric(8, 2) not null check (grade >= 0),
  feedback text not null default '',
  reviewed_by uuid not null references public.profiles (user_id) on delete restrict,
  reviewed_at timestamptz not null default now(),
  primary key (assignment_id, student_id)
);

create index if not exists login_activity_user_date_idx on public.login_activity (user_id, activity_date desc);
create index if not exists quizzes_course_created_idx on public.quizzes (course_id, created_at desc);
create index if not exists quiz_questions_quiz_position_idx on public.quiz_questions (quiz_id, position);
create index if not exists quiz_attempts_user_submitted_idx on public.quiz_attempts (user_id, submitted_at desc);
create index if not exists quiz_attempts_quiz_submitted_idx on public.quiz_attempts (quiz_id, submitted_at desc);
create index if not exists assignments_course_created_idx on public.assignments (course_id, created_at desc);
create index if not exists assignment_submissions_student_idx on public.assignment_submissions (student_id, submitted_at desc);
create index if not exists assignment_reviews_student_idx on public.assignment_reviews (student_id, reviewed_at desc);

create or replace function private.can_manage_quiz(target_quiz_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.quizzes q
    where q.id = target_quiz_id
      and (select private.can_manage_course(q.course_id))
  );
$$;

revoke all on function private.can_manage_quiz(uuid) from public, anon;
grant execute on function private.can_manage_quiz(uuid) to authenticated;

create or replace function public.create_quiz_question(
  p_quiz_id uuid,
  p_prompt text,
  p_options jsonb,
  p_correct_option smallint,
  p_position integer,
  p_points smallint default 1
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  question_id uuid;
  quiz_course_id uuid;
  quiz_is_published boolean;
begin
  if (select auth.uid()) is null then
    raise exception 'Authentication required';
  end if;

  select q.course_id, q.published
    into quiz_course_id, quiz_is_published
  from public.quizzes q
  where q.id = p_quiz_id;

  if quiz_course_id is null or not (select private.can_manage_course(quiz_course_id)) then
    raise exception 'You cannot manage this quiz';
  end if;
  if quiz_is_published then
    raise exception 'Unpublish the quiz before changing its questions';
  end if;
  if p_options is null or jsonb_typeof(p_options) is distinct from 'array' then
    raise exception 'Question options must be a JSON array';
  end if;
  if jsonb_array_length(p_options) not between 2 and 8
    or p_correct_option is null
    or p_correct_option < 0
    or p_correct_option >= jsonb_array_length(p_options) then
    raise exception 'Choose a valid answer from 2 to 8 options';
  end if;
  if exists (
    select 1
    from jsonb_array_elements(p_options) as option_item(value)
    where jsonb_typeof(value) is distinct from 'string'
      or btrim(value #>> '{}') = ''
  ) then
    raise exception 'Quiz options must be non-empty strings';
  end if;
  if p_position < 0 or p_points not between 1 and 100 then
    raise exception 'Invalid question position or points';
  end if;

  insert into public.quiz_questions (quiz_id, prompt, options, position, points)
  values (p_quiz_id, p_prompt, p_options, p_position, p_points)
  returning id into question_id;

  insert into private.quiz_answer_keys (question_id, correct_option)
  values (question_id, p_correct_option);

  return question_id;
end;
$$;

revoke all on function public.create_quiz_question(uuid, text, jsonb, smallint, integer, smallint) from public, anon;
grant execute on function public.create_quiz_question(uuid, text, jsonb, smallint, integer, smallint) to authenticated;

create or replace function public.submit_quiz_attempt(p_quiz_id uuid, p_answers jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  learner_id uuid := (select auth.uid());
  quiz_course_id uuid;
  quiz_is_published boolean;
  attempt_id uuid;
  earned_points integer;
  total_points integer;
begin
  if learner_id is null then
    raise exception 'Authentication required';
  end if;
  if p_answers is null or jsonb_typeof(p_answers) is distinct from 'object' then
    raise exception 'Answers must be a JSON object';
  end if;

  select q.course_id, q.published
    into quiz_course_id, quiz_is_published
  from public.quizzes q
  where q.id = p_quiz_id;

  if quiz_course_id is null or not quiz_is_published then
    raise exception 'This quiz is not available';
  end if;
  if not exists (
    select 1 from public.enrollments e
    where e.user_id = learner_id and e.course_id = quiz_course_id
  ) then
    raise exception 'Enroll in the course before submitting this quiz';
  end if;

  select
    coalesce(sum(case
      when coalesce(p_answers ->> q.id::text, '') ~ '^[0-9]+$'
        and (p_answers ->> q.id::text)::integer = k.correct_option
      then q.points else 0 end), 0)::integer,
    coalesce(sum(q.points), 0)::integer
  into earned_points, total_points
  from public.quiz_questions q
  join private.quiz_answer_keys k on k.question_id = q.id
  where q.quiz_id = p_quiz_id;

  if total_points = 0 then
    raise exception 'This quiz has no questions';
  end if;

  insert into public.quiz_attempts (quiz_id, user_id, answers, score, possible_score)
  values (p_quiz_id, learner_id, p_answers, earned_points, total_points)
  returning id into attempt_id;

  return attempt_id;
end;
$$;

revoke all on function public.submit_quiz_attempt(uuid, jsonb) from public, anon;
grant execute on function public.submit_quiz_attempt(uuid, jsonb) to authenticated;

alter table public.login_activity enable row level security;
alter table public.quizzes enable row level security;
alter table public.quiz_questions enable row level security;
alter table public.quiz_attempts enable row level security;
alter table public.assignments enable row level security;
alter table public.assignment_submissions enable row level security;
alter table public.assignment_reviews enable row level security;

revoke all on public.login_activity, public.quizzes, public.quiz_questions, public.quiz_attempts,
  public.assignments, public.assignment_submissions, public.assignment_reviews from anon, authenticated;
grant select, insert on public.login_activity to authenticated;
grant select, insert, update, delete on public.quizzes, public.assignments to authenticated;
grant select, delete on public.quiz_questions to authenticated;
grant select on public.quiz_attempts to authenticated;
grant select, insert, update on public.assignment_submissions to authenticated;
grant select, insert, update on public.assignment_reviews to authenticated;

-- Users can record one sign-in per day and read only their own activity.
drop policy if exists login_activity_select_self_or_admin on public.login_activity;
create policy login_activity_select_self_or_admin on public.login_activity
for select to authenticated
using (user_id = (select auth.uid()) or (select private.is_super_admin()));
drop policy if exists login_activity_insert_self on public.login_activity;
create policy login_activity_insert_self on public.login_activity
for insert to authenticated
with check (user_id = (select auth.uid()));

-- Course managers manage assessments; enrolled learners can read published items.
drop policy if exists quizzes_select_course_access on public.quizzes;
create policy quizzes_select_course_access on public.quizzes
for select to authenticated
using ((published and (select private.can_access_course(course_id))) or (select private.can_manage_course(course_id)));
drop policy if exists quizzes_insert_course_manager on public.quizzes;
create policy quizzes_insert_course_manager on public.quizzes
for insert to authenticated
with check ((select private.can_manage_course(course_id)));
drop policy if exists quizzes_update_course_manager on public.quizzes;
create policy quizzes_update_course_manager on public.quizzes
for update to authenticated
using ((select private.can_manage_course(course_id)))
with check ((select private.can_manage_course(course_id)));
drop policy if exists quizzes_delete_course_manager on public.quizzes;
create policy quizzes_delete_course_manager on public.quizzes
for delete to authenticated
using ((select private.can_manage_course(course_id)));

drop policy if exists quiz_questions_select_course_access on public.quiz_questions;
create policy quiz_questions_select_course_access on public.quiz_questions
for select to authenticated
using (exists (
  select 1 from public.quizzes q
  where q.id = quiz_id
    and ((q.published and (select private.can_access_course(q.course_id))) or (select private.can_manage_course(q.course_id)))
));
drop policy if exists quiz_questions_delete_course_manager on public.quiz_questions;
create policy quiz_questions_delete_course_manager on public.quiz_questions
for delete to authenticated
using (
  (select private.can_manage_quiz(quiz_id))
  and exists (
    select 1 from public.quizzes q
    where q.id = quiz_id and not q.published
  )
);

-- Answer keys stay in the private schema. Only the grading function can read them.
drop policy if exists quiz_attempts_select_self_or_course_manager on public.quiz_attempts;
create policy quiz_attempts_select_self_or_course_manager on public.quiz_attempts
for select to authenticated
using (
  user_id = (select auth.uid())
  or exists (
    select 1 from public.quizzes q
    where q.id = quiz_id and (select private.can_manage_course(q.course_id))
  )
);

-- Assignments are private until published, and submissions are limited to enrolled learners.
drop policy if exists assignments_select_course_access on public.assignments;
create policy assignments_select_course_access on public.assignments
for select to authenticated
using ((published and (select private.can_access_course(course_id))) or (select private.can_manage_course(course_id)));
drop policy if exists assignments_insert_course_manager on public.assignments;
create policy assignments_insert_course_manager on public.assignments
for insert to authenticated
with check ((select private.can_manage_course(course_id)));
drop policy if exists assignments_update_course_manager on public.assignments;
create policy assignments_update_course_manager on public.assignments
for update to authenticated
using ((select private.can_manage_course(course_id)))
with check ((select private.can_manage_course(course_id)));
drop policy if exists assignments_delete_course_manager on public.assignments;
create policy assignments_delete_course_manager on public.assignments
for delete to authenticated
using ((select private.can_manage_course(course_id)));

drop policy if exists assignment_submissions_select_self_or_manager on public.assignment_submissions;
create policy assignment_submissions_select_self_or_manager on public.assignment_submissions
for select to authenticated
using (
  student_id = (select auth.uid())
  or exists (
    select 1 from public.assignments a
    where a.id = assignment_id and (select private.can_manage_course(a.course_id))
  )
);
drop policy if exists assignment_submissions_insert_enrolled on public.assignment_submissions;
create policy assignment_submissions_insert_enrolled on public.assignment_submissions
for insert to authenticated
with check (
  student_id = (select auth.uid())
  and exists (
    select 1 from public.assignments a
    join public.enrollments e on e.course_id = a.course_id
    where a.id = assignment_id
      and a.published
      and e.user_id = (select auth.uid())
      and (a.due_at is null or a.due_at >= now())
  )
);
drop policy if exists assignment_submissions_update_enrolled on public.assignment_submissions;
create policy assignment_submissions_update_enrolled on public.assignment_submissions
for update to authenticated
using (
  student_id = (select auth.uid())
  and not exists (
    select 1 from public.assignment_reviews r
    where r.assignment_id = assignment_submissions.assignment_id
      and r.student_id = assignment_submissions.student_id
  )
)
with check (
  student_id = (select auth.uid())
  and exists (
    select 1 from public.assignments a
    join public.enrollments e on e.course_id = a.course_id
    where a.id = assignment_id
      and a.published
      and e.user_id = (select auth.uid())
      and (a.due_at is null or a.due_at >= now())
  )
);

drop policy if exists assignment_reviews_select_self_or_manager on public.assignment_reviews;
create policy assignment_reviews_select_self_or_manager on public.assignment_reviews
for select to authenticated
using (
  student_id = (select auth.uid())
  or exists (
    select 1 from public.assignments a
    where a.id = assignment_id and (select private.can_manage_course(a.course_id))
  )
);
drop policy if exists assignment_reviews_insert_course_manager on public.assignment_reviews;
create policy assignment_reviews_insert_course_manager on public.assignment_reviews
for insert to authenticated
with check (
  reviewed_by = (select auth.uid())
  and exists (
    select 1 from public.assignments a
    where a.id = assignment_id
      and (select private.can_manage_course(a.course_id))
      and grade <= a.points
  )
  and exists (
    select 1 from public.assignment_submissions s
    where s.assignment_id = assignment_reviews.assignment_id
      and s.student_id = assignment_reviews.student_id
  )
);
drop policy if exists assignment_reviews_update_course_manager on public.assignment_reviews;
create policy assignment_reviews_update_course_manager on public.assignment_reviews
for update to authenticated
using (exists (
  select 1 from public.assignments a
  where a.id = assignment_id and (select private.can_manage_course(a.course_id))
))
with check (
  reviewed_by = (select auth.uid())
  and exists (
    select 1 from public.assignments a
    where a.id = assignment_id
      and (select private.can_manage_course(a.course_id))
      and grade <= a.points
  )
  and exists (
    select 1 from public.assignment_submissions s
    where s.assignment_id = assignment_reviews.assignment_id
      and s.student_id = assignment_reviews.student_id
  )
);
