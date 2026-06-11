# Executive Interview Prep

> **About these build-plan files:** Everything in `_build_plan/` (this PRD and the per-milestone folders) is a **temporary documentation and guidance artifact** for the initial build-out of this codebase. These files are not functional — no code, configuration, runtime logic, tests, or deployment process should import, read, reference, or depend on anything in `_build_plan/`. Once the initial milestones are built and shipped, the entire `_build_plan/` folder is expected to be deleted from the codebase. Do not treat it as long-living documentation.

## What we're building

Executive Interview Prep is a voice-activated research agent powered by ElevenLabs that allows executives to call in, describe an upcoming interview or informational meeting, and receive comprehensive research, talking points, and preparation insights to help them succeed.

The core flow is simple: an executive dials in and briefs the agent on their upcoming meeting. The app immediately begins researching the company, the person they're meeting with, industry context, and recent news. Once research is complete, the app calls the executive back, verbally walks them through key talking points and likely questions, and lets them ask follow-up questions. The executive also receives both an audio file and a written briefing they can reference anytime before the meeting.

Built on Rails 8 with React 19 frontend, PostgreSQL database, and integrated with ElevenLabs (voice), Claude API (synthesis), Perplexity (research), and AWS SES (email). The build is broken into 5 focused milestones, each delivering visible, testable functionality.

---

### What the app does

- **Voice call intake** — Executives dial a dedicated phone number, describe their meeting, and the agent records the full conversation with confirmation.
- **Information capture** — The app extracts structured details (company, person, date, objectives) and lets executives review and add context on the dashboard.
- **Deep research** — Automatic background research on the company, person, industry trends, and recent news via Perplexity.
- **Insight synthesis** — Claude synthesizes research into talking points, likely questions, opportunities, and risks tailored to the specific meeting.
- **Callback & verbal briefing** — Once synthesis is complete, the app calls back and the ElevenLabs agent verbally walks through the briefing in a coaching style.
- **Interactive Q&A** — During the callback, executives can ask follow-up questions and get immediate, conversational answers from the agent.
- **Audio briefing file** — A downloadable, high-quality audio version of the full briefing for anytime listening (in the car, on a flight, etc.).
- **Written preparation materials** — A comprehensive PDF briefing with company/person overview, talking points, likely questions, opportunities/risks, and key facts.

---

### Already provided by the Build New starter (Rails 8)

Verified against the actual codebase — treat this list as ground truth:

- User authentication (signup, login, logout, password reset) using Rails 8 built-in sessions + `has_secure_password` — **not Devise**
- `users` table with `email`, `password_digest`, `timezone`, `admin` (no name or phone number yet — milestone 1 adds those)
- Authenticated app shell with sidebar nav, dashboard page, settings page, and profile pages (email/password editing)
- Admin area (`/admin/users`, `/admin/design-system`)
- Custom design system (tokens + primitives under `app/frontend/components/ui/`, dark mode) — **not shadcn**; see CLAUDE.md "Design system"
- Inertia.js bridging Rails ↔ React 19 (no API layer), with SSR wired up
- PostgreSQL with Solid Queue / Solid Cache / Solid Cable sharing the one database
- Minitest + system tests, RuboCop (omakase), Brakeman

---

### Out of scope (v1)

- **Multi-user accounts & team collaboration** — v1 is single-user per executive; team sharing and collaboration move to v2
- **Calendar & CRM integrations** — No auto-pulling data from LinkedIn, Salesforce, or calendar tools; executives provide context directly
- **Historical briefing archive** — The dashboard lists past requests and their briefings, but versioning, side-by-side comparison, and re-running old briefings are v2 features
- **Premium research sources** — v1 uses public web research only; access to Bloomberg, CapIQ, or paid research databases is v2+
- **Mobile app** — v1 is voice-native (works on any phone) but no dedicated mobile UI beyond the web dashboard
- **Scheduling & calendar integration** — No built-in scheduler; executives manually trigger calls and callbacks
- **Customizable research templates** — v1 has one standard research approach; custom themes/templates are v2+

---

### External integrations

#### ElevenLabs
Voice calls, speech synthesis, and callback mechanism.
Handles inbound calls from executives, records and transcribes conversations, generates natural-sounding verbal briefings, and initiates callbacks with the agent.
**Credentials:** `ELEVENLABS_API_KEY` env var.
**Operational notes:** Inbound calls and post-call webhooks require a publicly reachable URL — use a tunnel (ngrok/cloudflared) in development. Webhook endpoints must skip CSRF and verify the ElevenLabs webhook signature.

#### Claude API
Research parsing, insight synthesis, and interactive Q&A.
Extracts structured information from call transcripts, synthesizes research into talking points and questions, and answers follow-up questions during callbacks.
**Credentials:** `ANTHROPIC_API_KEY` env var.

#### Perplexity API
Real-time web research on companies, people, and industry trends.
Gathers up-to-date information about the company, the person, recent news, and relevant industry context to fuel the briefing synthesis.
**Credentials:** `PERPLEXITY_API_KEY` env var.

#### AWS SES
Email delivery for sending briefing documents to executives.
Sends the written briefing document via email so executives can receive and reference it easily.
**Credentials:** AWS SES access key + secret key env vars.
**Operational notes:** The sender domain/address must be verified in SES before production sends. Development uses the starter's `letter_opener` — no SES needed locally.

---

### Data model

#### User
The executive using the app. Starter provides email/password/timezone/admin; milestone 1 adds the rest.
- email — login identifier (starter)
- password — hashed via `has_secure_password` (starter)
- timezone — user's time zone (starter)
- name — executive's full name (milestone 1)
- phone_number — the number the agent calls back to, stored in E.164 format (milestone 1)

#### Interview Request
A single briefing request: the meeting or interview an executive is preparing for.
- user — which executive
- meeting_title — name/description of the meeting (e.g., "Board meeting with Acme CEO")
- meeting_date — when the meeting is scheduled
- company_name — organization being visited
- contact_person_name — who the executive is meeting with
- contact_person_title — their role/title
- contact_person_background — context about them (LinkedIn highlights, career history)
- executive_context — notes the executive provided during the intake call
- executive_objectives — what the executive wants to achieve
- call_transcript — the full transcript from the intake call
- audio_recording_url — URL of the intake-call recording hosted by ElevenLabs (external URL, not a stored file)
- status — lifecycle enum, each transition set by exactly one actor:
  - `intake_review` — details extracted from the call, awaiting executive confirmation (set by the intake webhook/extraction)
  - `pending_research` — executive confirmed, research queued (set by the confirm action)
  - `researching` — research/synthesis jobs running (set by the research job)
  - `briefing_ready` — synthesis complete, briefing viewable (set by the synthesis job)
  - `completed` — callback delivered (set when the callback finishes)
  - `failed` — unrecoverable pipeline error; store a human-readable error message alongside (set by any job on permanent failure)
- error_message — populated when status is `failed`, shown on the dashboard
- created_at, updated_at

#### Research Data
The gathered research for an Interview Request.
- interview_request — which request this research belongs to
- company_overview — company size, sector, structure, recent announcements
- company_news — recent press releases, major announcements, market moves
- person_bio — the contact person's background, education, career history
- person_social_profiles — LinkedIn, Twitter, or other relevant profiles
- industry_context — relevant trends, market dynamics, competitive landscape
- research_sources — URLs and summaries of sources used
- created_at

#### Briefing
The synthesized briefing document for an Interview Request.
- interview_request — which request
- talking_points — key messages (5–10 points the executive should lead with)
- likely_questions — probable questions organized by topic, with suggested context
- opportunities — outcomes to push for, key wins to target
- risks — potential pitfalls, topics to tread carefully on
- key_facts — quick reference facts about company/person
- audio_file — the downloadable audio briefing (Active Storage attachment, not a URL column; generated in milestone 5)
- pdf_file — the downloadable written briefing (Active Storage attachment, not a URL column; generated in milestone 5)
- created_at
- callback_completed_at

#### Follow-up Q&A
Questions asked during the callback conversation.
- interview_request — which request this Q&A is for
- question — what the executive asked
- answer — what the agent answered
- created_at (ordering within the callback session)

---

## Build conventions & guardrails (all milestones)

These apply to every milestone below; milestone prompts reference this section instead of repeating it.

**Follow CLAUDE.md.** It is the repo's ground truth for: Inertia response rules (mutations redirect — never `head :ok` / `render json:` from Inertia-routed actions, except raw-`fetch` webhook/API endpoints), page metadata (all four head tags on every page, no exceptions), the design system (use existing tokens/primitives, bare semantic HTML for text, no ad-hoc styles), SSR constraints (no browser globals at module top-level or during render), and crawler files (all pages built in these milestones are auth-gated — keep them out of `config/sitemap.rb` and `public/llms.txt`, and add `Disallow:` lines to `public/robots.txt` for new route prefixes).

**Working guidelines** (condensed from the karpathy-guidelines skill):

1. **Think before coding.** State assumptions explicitly. If multiple interpretations or approaches exist, present them — don't pick silently. If something is unclear, stop and ask.
2. **Simplicity first.** Minimum code that satisfies the milestone's "Done when". No features beyond the milestone scope, no abstractions for single-use code, no speculative configurability, no error handling for impossible scenarios.
3. **Surgical changes.** Touch only what the milestone requires. Don't refactor or "improve" adjacent starter code. Match existing style. Every changed line should trace to the milestone scope.
4. **Goal-driven execution.** Treat each "Done when" bullet as a verifiable check. Plan as numbered steps, each with its own verification.

**Secrets.** All API keys come from env vars (see "External integrations"). Never commit keys. Fail loudly at the point of use when a key is missing — don't add stub/fake modes that mask missing credentials.

**External API calls run in Solid Queue jobs**, never in the request/response cycle. Jobs must be idempotent (safe to retry) and on permanent failure set the Interview Request to `failed` with a human-readable `error_message` instead of failing silently.

**Verification before reporting done** (every milestone): `bin/rails test` green, `npm run check` clean, `bin/rubocop` clean, browser-verify the milestone's user flows end-to-end, screenshots in `tmp/screenshots/`.

---

## Milestone 1 — App setup & domain foundation

The starter already provides auth, the app shell, dashboard, settings, profile pages, and Solid Queue (see "Already provided by the Build New starter" above — verified against the codebase). Milestone 1 is the **delta**: the domain models and the profile fields the voice flow needs.

### What gets built

- Migrations + models for Interview Request, Research Data, Briefing, and Follow-up Q&A per the data model above — associations, the status enum, and validations
- `name` and `phone_number` columns on User, with the settings/profile page extended so users can view and edit both (phone number validated and normalized to E.164 — milestone 4's callback agent dials this value exactly)
- Dashboard lists the current user's Interview Requests with status badges, including an empty state (there's no way to create a request until milestone 2, so seed data demonstrates the populated list)
- Model tests covering validations, associations, and status transitions

### What this milestone explicitly does NOT include

- ElevenLabs phone integration
- Research or synthesis pipelines
- Callback mechanism or voice features
- Briefing generation or documents
- Any external API integrations

### Done when

- You can sign up, log in, and edit your name and phone number in settings; values persist and invalid phone numbers are rejected with a visible error.
- The dashboard lists seeded Interview Requests with correct status badges, and shows a sensible empty state for a fresh user.
- All pages follow the design system and set the four required head tags.
- `bin/rails test`, `npm run check`, and `bin/rubocop` all pass.

---

## Milestone 2 — Voice intake & information capture

Build the voice call interface with ElevenLabs integration and the information capture dashboard. Executives can now call in, describe their meeting, and review extracted details.

### What gets built

- ElevenLabs phone agent that accepts inbound calls
- Voice agent interviews executives: collects company name, contact person, meeting date, meeting type, objectives, and context
- Call recording and transcription (via ElevenLabs)
- Agent confirms extracted details back to the executive before hanging up
- Webhook endpoint receiving ElevenLabs post-call data — CSRF-exempt, verifies the ElevenLabs webhook signature, and is idempotent (a re-delivered webhook must not create a duplicate Interview Request). Development requires a tunnel (ngrok/cloudflared) so ElevenLabs can reach the app.
- Information extraction: structured fields (company, person, date, objectives, etc.) from the conversation — either ElevenLabs' built-in data-collection or a Claude extraction pass over the transcript; present both options during planning and pick the simpler one that works
- Interview Request created from call data with status `intake_review`
- Dashboard page to view all past calls and their transcripts
- Dashboard form for executives to review extracted information, make corrections, add context, and **confirm** — confirmation moves the request to `pending_research`
- Status badges distinguish `intake_review` from `pending_research`
- Phone number on file is displayed and editable (from milestone 1 settings)

### What this milestone explicitly does NOT include

- Research or synthesis
- Callbacks or follow-up calls
- Audio or document generation
- Q&A functionality
- Email sending

### Done when

You can call the app's dedicated phone number, have a natural voice conversation with the ElevenLabs agent describing a meeting, and after hanging up, see that call logged on your dashboard. You can click into the call, see the extracted company/person/date/objectives information in a form, edit any details, add additional notes, and confirm the information is correct. The Interview Request is now ready for research.

---

## Milestone 3 — Research pipeline

Build the automated research pipeline. Once an Interview Request is ready, the app researches the company, person, and context, then synthesizes the findings into talking points, questions, and insights.

### What gets built

- Solid Queue job that triggers when an Interview Request is confirmed; sets status to `researching`, is idempotent, and on permanent failure sets `failed` + `error_message` (surfaced on the dashboard with a retry action)
- Perplexity API integration to research company, person, industry trends, and recent news
- Research results stored in Research Data entity
- Dashboard displays research status for each request (driven by the status enum)
- Claude API integration to synthesize research into:
  - Talking points (5–10 key messages)
  - Likely questions (organized by topic)
  - Opportunities (outcomes to target)
  - Risks (potential pitfalls)
  - Key facts (quick reference)
- Briefing entity created with synthesized insights
- Dashboard displays the complete briefing with all sections (talking points, questions, opportunities, risks, facts)
- Expandable sections: clicking a talking point or question shows supporting research behind it
- Status update: Interview Request moves to `briefing_ready` when synthesis completes

### What this milestone explicitly does NOT include

- Callbacks or voice delivery
- Audio or PDF file generation
- Q&A functionality
- Email sending

### Done when

You confirm an Interview Request and the research pipeline kicks off automatically. Within a few minutes, research and synthesis complete and you see a dashboard page with all the synthesized briefing content: talking points, likely questions, opportunities, risks, and key facts. Each section is clear, scannable, and expandable to show the research behind it. If a pipeline job fails permanently, the dashboard shows the failure and lets you retry.

---

## Milestone 4 — Callbacks & interactive Q&A

Build the callback mechanism and interactive Q&A. Once a briefing is ready, the app calls the executive back and delivers the briefing verbally with live Q&A.

### What gets built

- Callback trigger: a "Call me now" button on a `briefing_ready` request (on-demand only in v1 — no scheduling)
- ElevenLabs outbound call to the executive's E.164 phone number on file
- Agent verbally walks through the briefing: talking points, likely questions, opportunities, risks, key context (in a conversational coaching style) — the briefing content is passed to the agent as conversation context
- After verbal delivery, agent opens for questions: "What would you like to know more about?"
- Executive asks follow-up questions via voice; the agent answers from the briefing + research context. Two viable designs — the ElevenLabs agent's own LLM primed with the briefing, or a custom-LLM bridge to Claude — present both during planning and pick the simpler one that meets "Done when"
- Questions and answers are captured (via the post-call webhook/transcript) and stored in the Follow-up Q&A entity
- Executive can ask multiple questions in one callback session
- Request moves to `completed` when the callback finishes
- Dashboard displays the Q&A transcript from the callback for reference

### What this milestone explicitly does NOT include

- Audio file generation for the briefing
- PDF or document generation
- Email sending
- Scheduled callbacks (only on-demand in v1)
- Recording storage of callbacks beyond the Q&A transcript

### Done when

A briefing is ready, you request a callback (or it's triggered automatically), and the app calls you back. The ElevenLabs agent verbally briefs you on talking points, questions, opportunities, and risks in a natural, conversational way. After the briefing, you can ask follow-up questions by voice, and the agent answers in real-time. When the call ends, you can review the Q&A transcript on the dashboard.

---

## Milestone 5 — Audio & written briefings

Generate and deliver the audio and written briefing documents so executives have reference materials to review anytime before the meeting.

### What gets built

- Audio briefing generation: convert the full briefing (talking points, questions, opportunities, risks, facts) into high-quality speech using ElevenLabs TTS
- Audio file is downloadable from the dashboard
- Audio is structured clearly: labeled sections (Talking Points, Likely Questions, Opportunities, Risks, Key Facts) so the user knows where they are while listening
- Written briefing PDF generation with:
  - Executive summary
  - Company/person overview (pulled from research data)
  - Talking points
  - Likely questions with suggested context
  - Opportunities & risks
  - Key facts and statistics
  - Research sources/references
- PDF is clean, scannable, professional layout (server-side PDF library — pick during planning)
- PDF is downloadable from the dashboard
- Both files are generated by a Solid Queue job after synthesis completes and stored as Active Storage attachments on the Briefing
- Dashboard displays download links for both files
- Email the written briefing (PDF attached or download link) to the executive via Action Mailer — AWS SES in production, the starter's `letter_opener` in development

### What this milestone explicitly does NOT include

- Scheduling delivery for later
- Multiple narrator voices or voice customization
- Streaming audio playback (download only)
- Custom branding or logo insertion
- Export to formats other than PDF

### Done when

After a briefing is synthesized, you see download buttons on the dashboard for both an audio file and a PDF. You can download the audio, listen to it in any player, and download the PDF to read or print. The audio is clear and professional, the PDF is well-formatted and easy to reference, and both contain the full briefing content (talking points, questions, opportunities, risks, key facts). The briefing email arrives (visible in `letter_opener` in development) with the PDF attached or linked.