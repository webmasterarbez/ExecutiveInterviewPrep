# Milestone 2 — Voice intake & information capture — Log

## What's new in the app

- **Calling in now works end-to-end (app side).** When an executive calls the ElevenLabs agent and describes a meeting, the post-call webhook turns that conversation into an Interview Request on their dashboard, matched to their account by the phone number they call from.
- **Review screen.** Clicking a "Needs review" request opens a page showing everything captured from the call — meeting title, date, company, contact person and title, objectives, context — in an editable form, plus the full call transcript and a link to the recording on ElevenLabs.
- **Correct and confirm.** The executive can fix any detail, add background and context, save, and then hit **"Confirm — start research"**. The request flips to "Research queued" and the form locks into a read-only summary.
- **Callback number visible everywhere it matters.** The review page shows the phone number on file with a link to edit it in the profile.
- Dashboard rows are now clickable links into each request.
- A step-by-step guide (`docs/elevenlabs-setup.md`) covers the one-time ElevenLabs dashboard setup: agent prompt, data-collection fields, phone number, webhook + secret, and the ngrok dev tunnel.

## What was built

**Migration:** `add_elevenlabs_conversation_id_to_interview_requests` — nullable string + **unique index** (webhook idempotency key).

**Webhook endpoint** — `POST /webhooks/elevenlabs` → `app/controllers/webhooks/elevenlabs_controller.rb`:
- Raw (non-Inertia) endpoint: `allow_unauthenticated_access` + `skip_before_action :verify_authenticity_token`; auth is the HMAC signature.
- Signature scheme (verified against the official `elevenlabs-python` SDK source): header `ElevenLabs-Signature: t=<unix>,v0=<hex>`, where hex = HMAC-SHA256(`ELEVENLABS_WEBHOOK_SECRET`, `"<t>.<raw_body>"`); timestamps older than 30 minutes rejected; constant-time compare. Secret read via `ENV.fetch` — missing secret fails loudly.
- Only `post_call_transcription` events processed; other types ack 200.
- Caller matched via `data.metadata.phone_call.external_number` (fallback `dynamic_variables.system__caller_id`) against `users.phone_number`. No match → log + 200, nothing created.
- Extracted fields read from `data.analysis.data_collection_results` (handles both `{value: ...}` objects and bare values): `meeting_title`, `company_name`, `contact_person_name`, `contact_person_title`, `meeting_date` (unparseable → nil), `executive_objectives`, `executive_context`.
- Transcript turns formatted as `Agent:` / `You:` text into `call_transcript`; `audio_recording_url` set to `https://elevenlabs.io/app/agents/history/<conversation_id>`.
- Idempotent: `find_or_create_by!` on conversation id + `RecordNotUnique` rescue; re-delivery returns 200 without duplicating.
- Malformed JSON → 400. Processing is inline (no external API calls happen in this webhook, so the jobs guardrail doesn't apply).

**Review/confirm flow:**
- Routes: `resources :interview_requests, only: %i[show update]` + member `post :confirm`.
- `InterviewRequestsController` — all queries scoped `Current.user.interview_requests` (cross-user access 404s). `update` and `confirm` only allowed in `intake_review` (otherwise redirect with alert). `confirm` → `pending_research`. Inertia mutation rules followed (redirects, errors via `inertia: { errors: }`).
- `app/javascript/pages/interview_requests/Show.tsx` — editable form (intake_review) / read-only `<dl>` (after), status badge, failed-state callout, phone-on-file callout linking to `/profile`, scrollable transcript `<pre>`, recording link, all four head tags.
- `Dashboard.tsx` — rows wrapped in Inertia `<Link>`; status badge map extracted to shared `app/frontend/lib/status.ts` (`statusBadge()`), used by both pages.

**Design-system addition:** `<Textarea>` primitive (`app/frontend/components/ui/textarea.tsx`, classes `form-control form-control-textarea` already existed in the CSS) + documented in the Forms section of `/admin/design-system`.

**Crawler files:** `robots.txt` adds `Disallow: /interview_requests` and `Disallow: /webhooks`.

**Docs:** `docs/elevenlabs-setup.md` — agent system prompt, data-collection field identifiers (must match webhook parsing names exactly), phone number attach, post-call webhook config + HMAC secret, ngrok static-domain command (`ngrok http --domain=... 5000`), production URL `https://eip.vrtcl.network/webhooks/elevenlabs`, smoke-test checklist.

**Tests** (63 runs, 175 assertions, green): webhook — valid signed payload creates request with all extracted fields; re-delivery idempotent; invalid signature 401; missing header 401; stale timestamp (>30 min) 401; unknown caller acks 200 + creates nothing; non-transcription type acks 200; malformed JSON 400. Interview requests — show own / 404 other's; update persists in intake_review; update rejected after; confirm → pending_research; confirm rejected outside intake_review; auth required.

## Decisions made

- All four planning decisions user-approved: ElevenLabs built-in data collection (no Claude in M2), ngrok static domain, manual dashboard setup + doc, caller-ID matching with unmatched-call drop.
- `elevenlabs_conversation_id` column added beyond the PRD data model — required by the binding idempotency rule.
- "Meeting type" (PRD intake list, no data-model field) folds into `executive_context` via the data-collection field description.
- `audio_recording_url` holds the ElevenLabs conversation-history URL (external reference, not a file).
- Review form locks after confirm (read-only summary) — edits post-confirm would race the research pipeline.
- `<Textarea>` added as a design-system primitive rather than a one-off (CSS classes pre-existed).

## For the next milestone

- **Trigger point for research:** `confirm` action (`InterviewRequestsController#confirm`) currently just sets `pending_research`. M3 should enqueue the research job right there, and the job should move `pending_research → researching → briefing_ready` (or `failed` + `error_message`).
- `ELEVENLABS_WEBHOOK_SECRET` is the only new env var; `ANTHROPIC_API_KEY` / `PERPLEXITY_API_KEY` are still unused — M3 introduces them (fail loudly via `ENV.fetch` at point of use).
- Show page already renders `failed` status + `error_message` in a danger callout; M3 needs to add the **retry action** the PRD requires.
- Read-only `<dl>` view on the Show page is where briefing content will slot in (new sections below "Meeting details").
- Status badge map lives in `app/frontend/lib/status.ts` — no changes needed for M3 statuses (all six already mapped).
- Dev server: port 3000 occupied on this machine → `bin/rails-dev foreman start -f Procfile.dev` (Rails :5000). Beware stale Puma: `tmp/pids/server.pid` + `pkill -f puma` if foreman exits with "A server is already running".
- Local webhook simulation: `tmp/send_webhook.sh <conversation_id>` (signed payload, secret `dev-verify-secret`, targets :5000) — handy for creating fresh `intake_review` requests without a real call. Caller number in the script must match `user@test.com`'s phone (`+12125550123`, as seeded).
- Real-call E2E (actual phone call through ElevenLabs + ngrok) was **not** exercised — requires the user's one-time dashboard setup per `docs/elevenlabs-setup.md`.

## Deviations from the PRD

- `elevenlabs_conversation_id` column added to Interview Request (not in the PRD data model) — needed for webhook idempotency, which the PRD itself mandates.
- None otherwise.
