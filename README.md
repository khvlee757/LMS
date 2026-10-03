# Northstar Learning

Vue 3 LMS frontend with Supabase Auth and Postgres. Learners can enroll in published courses and track completed lessons. Instructors can author courses and lessons. The super-admin manages publishing and instructor roles.

## Local setup

1. Create a Supabase project.
2. Copy `.env.example` to `.env.local` and set `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` from the project's API settings. A legacy anon key can be used as `VITE_SUPABASE_ANON_KEY` if necessary. Never put a service-role or secret key in a `VITE_` variable.
3. In the Supabase SQL Editor, run [`supabase/setup.sql`](supabase/setup.sql).
4. Run [`supabase/upgrade_learning_tools.sql`](supabase/upgrade_learning_tools.sql) in the SQL Editor to add daily login activity, quizzes, assignments, submissions, and reviews.
5. In project API settings, ensure the `public` schema is exposed to the Data API. RLS remains enabled for all app tables.
6. In Authentication > URL Configuration, set the Site URL to `http://localhost:5173` and add `http://localhost:5173/login` to the redirect URLs. Add your production domain and its `/login` URL before deployment.
7. Enable email/password sign-in and email confirmation in Authentication > Sign In / Providers. Configure a production SMTP provider before inviting real users.
8. Run `npm install` and `npm run dev`.
9. Register your owner account as a learner and confirm its email. Then, in the Supabase SQL Editor, run the one-time bootstrap query at the bottom of `supabase/setup.sql`, replacing `owner@example.com` with your confirmed account email. This is the only supported way to create a super-admin.

## Routes

- `/dashboard`: learner overview, enrollment/progress counts, daily sign-ins, and current streak.
- `/courses`: published course catalog and enrollment.
- `/courses/:id`: lessons, completion tracking, quizzes, and assignments; participation requires enrollment.
- `/learning`: a learner's enrolled courses.
- `/register`: choose learner signup or submit an instructor application.
- `/instructor`: course, lesson, publishing, and lesson-order management for instructors and the owner.
- `/admin`: super-admin course publishing and instructor application review.

## Test accounts

The app intentionally does not ship shared test credentials. Create each account with a different email in the registration form and enter its password directly in the browser:

1. Run both SQL scripts and configure email confirmation.
2. Register your owner email as a learner, confirm it, and run the owner bootstrap SQL. This becomes your real super-admin login.
3. Register a second email as a learner. Use the Learner sign-in option to test the catalog, enrollment, and lesson progress.
4. Register a third email as an instructor and complete the verification application. It remains a learner while pending.
5. Sign in as super-admin, approve the application under Administration > Instructor applications, then sign in with the Instructor option to test course authoring.

Never share test passwords in chat. Account creation and email confirmation happen through Supabase Auth.

## Security and deployment

The SQL scripts enable RLS on every app table, grant only authenticated access, create each profile server-side with a `student` role, and store instructor requests as pending applications. Only the super-admin can review applications; an approved application is required before the database permits the instructor role. Quiz answer keys live in the private schema and are graded server-side. Daily login activity is unique per account and day. Client-side signup cannot grant instructor or super-admin access. User-editable Auth metadata is used only for profile/application data, never for authorization. Password hashing and email confirmation are handled by Supabase Auth. Phone numbers use international E.164 format with a country calling code.

Email confirmation delivery, CAPTCHA, abuse limits, and production SMTP are configured in the Supabase dashboard. Configure Auth's CAPTCHA and rate limits before opening public registration. This is a browser-only Vue SPA, so Supabase JS manages sessions in browser storage; use a server-side cookie integration if your deployment requires HttpOnly session cookies. Deploy with SPA history fallback enabled so direct links such as `/courses/:id` resolve to `index.html`.

This is the recovered LMS foundation: courses, lessons, enrollments, lesson progress, daily login streaks, instructor applications, quizzes, assignments, and assignment grading are implemented. Certificates, payments, and notification delivery are not included yet.
