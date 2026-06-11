# Milestone 1 — App setup & domain foundation — Log

## What's new in the app

- Your profile now has a **Name** and **Phone number** field (Profile → My details). The phone number is the one the app will call you back on, and it's automatically cleaned up into the international dialing format (e.g. "(415) 555-2671" becomes "+14155552671"). Invalid numbers are rejected with a visible error.
- The **dashboard now lists your interview requests** — each row shows the meeting title, company, contact person, meeting date, and a colored status badge (Needs review, Research queued, Researching, Briefing ready, Completed, Failed). Failed requests show a human-readable error message.
- New users with no requests see a friendly **empty state** explaining that requests will appear after calling in.
- Sample data: `user@test.com` has six example requests (one in every status); `admin@test.com` has none, demonstrating the empty state.

## What was built

**Gem:** `phonelib` (Google libphonenumber port) + `config/initializers/phonelib.rb` (`default_country = "US"`).

**Migrations** (`db/migrate/20260611*`):
- `add_name_and_phone_number_to_users` — nullable `name`, `phone_number` strings.
- `create_interview_requests` — all PRD fields; `status` string `null: false, default: "intake_review"`; FK to users.
- `create_research_data` — all PRD fields; FK to interview_requests with **unique index** (has_one).
- `create_briefings` — all PRD fields + `callback_completed_at`; FK with **unique index** (has_one). No file columns — `audio_file`/`pdf_file` are milestone 5 Active Storage attachments.
- `create_follow_up_qas` — `question`, `answer`, FK to interview_requests.

**Models:**
- `InterviewRequest` — `belongs_to :user`, `has_one :research_data`, `has_one :briefing`, `has_many :follow_up_qas` (all `dependent: :destroy`); string-backed `enum :status` with the six lifecycle values, `validate: true`.
- `ResearchData`, `Briefing` — `belongs_to :interview_request` + uniqueness validation on `interview_request_id`.
- `FollowUpQa` — `belongs_to :interview_request`.
- `User` — `has_many :interview_requests, dependent: :destroy`; `before_validation` E.164 normalization via Phonelib; `validates :phone_number, phone: { allow_blank: true }`.

**Routes/controllers:**
- `PATCH /profile/details` → `ProfilesController#update_details` (name + phone, Inertia redirect-with-errors pattern).
- `DashboardController#show` passes `interview_requests` prop (id, meeting_title, company_name, contact_person_name, meeting_date, status, error_message, created_at).
- `ApplicationController` shared `current_user` prop now includes `name` and `phone_number` (mirrored in `app/frontend/types/inertia.ts`).

**Frontend:**
- `app/javascript/pages/profile/Details.tsx` — new "details" form (Name, Phone number with helper text) above the email form.
- `app/javascript/pages/Dashboard.tsx` — request list using the design-system listing pattern, status → badge tone map, failed-row error message, empty state. Meeting dates rendered with explicit `en-US` + UTC formatting to avoid SSR hydration mismatches.
- **Design-system addition:** new `danger` badge tone (`.badge-danger` in `design-system.css`, `danger` variant in `components/ui/badge.tsx`, documented in the Badges section of `/admin/design-system`).

**Seeds:** `db/seeds.rb` — `user@test.com` gets name/phone + six requests (one per status, failed one with `error_message`), idempotent via `find_or_create_by!` on user + meeting_title. `admin@test.com` left empty for the empty state.

**Tests** (48 runs, 121 assertions, all green): model tests for User (normalization, invalid/blank phone, dependent destroy), InterviewRequest (associations, default status, all six statuses, invalid status, predicates, dependent destroy), ResearchData/Briefing (one-per-request), FollowUpQa; controller tests for `update_details` (success + invalid phone + auth required) and dashboard (lists own requests, scopes to current user, auth required). Fixtures for all four new tables.

## Decisions made

- **phonelib gem** over regex-only validation (user-approved during planning).
- **Name/phone editing on Profile → My details** rather than the stub Settings page (user-approved during planning).
- `Phonelib.default_country = "US"` so national-format US numbers normalize; `+`-prefixed international numbers work unchanged.
- `name`/`phone_number` are nullable and not required — signup doesn't collect them; phone is validated only when present.
- Status enum stored as a **string** column with `default: "intake_review"`; no state-machine gem — transitions are owned by specific actors in later milestones.
- Research/Briefing content fields are `text` (not jsonb); milestone 3 owns the content shape and can migrate if it needs structure.
- All tables use standard Rails `t.timestamps` even where the PRD listed only `created_at`.
- Status badge tones: intake_review→signal, pending_research→neutral, researching→accent, briefing_ready→solid, completed→muted, failed→danger (new tone).
- `test/fixtures/research_data.yml` needs `_fixture: model_class: ResearchData` because Rails inflects "research_data" → "ResearchDatum" for fixture class lookup.

## For the next milestone

- **Port 3000 is held by an unrelated local service** on this machine. The dev server must run on another port: `bin/rails-dev foreman start -f Procfile.dev` boots Rails on **:5000** and Vite on **:5174** (Vite dev port is pinned in `config/vite.json`). `bin/dev` fails here because foreman isn't on the default PATH — use `bin/rails-dev foreman start -f Procfile.dev` instead.
- Webhook-created Interview Requests get status `intake_review` by default — milestone 2's webhook does not need to set it explicitly.
- `InterviewRequest` has **no presence validations** on content fields; voice extraction can save partial data, and the confirm flow (milestone 2) is where required fields should be enforced if needed.
- The dashboard list links nowhere yet — milestone 2 adds the request detail/review page; wrap the row in a `Link` then (the design-system listing pattern in `/admin/design-system#listings` shows the anchor variant).
- `users.phone_number` is guaranteed E.164 when present; milestone 4 can dial it verbatim. It can still be **null** — the callback flow must handle users who never set one.
- Seed login: `user@test.com` / `test123` (six requests), `admin@test.com` / `test123` (empty dashboard, admin area access).
- Browser verification used `playwright-core` (installed with `npm install --no-save`, not in package.json) driving system Chrome at `/usr/bin/google-chrome`; script pattern in `tmp/verify_m1.mjs`.

## Deviations from the PRD

- None functionally. Minor: tables include `updated_at` where the PRD data model listed only `created_at` (Rails convention; no behavior impact).
