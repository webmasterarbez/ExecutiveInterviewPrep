# Milestone 3 — Research pipeline — Log

## What's new in the app

- **Confirming a request now starts real research automatically.** The app researches the company, recent news, the contact person, and the industry (Perplexity), then has Claude synthesize it all into a briefing.
- **The briefing appears on the request page**: 5–10 talking points, likely questions grouped by topic, opportunities, risks, and key facts. Clicking any talking point or question expands it to show the research behind it.
- **The raw research is browsable too** — company overview, news, person bio, public profiles, industry context, and all sources, each expandable.
- **Live status updates**: while research runs, the request page polls and flips automatically from "Research queued" → "Researching" → "Briefing ready" without a manual refresh.
- **Failures are visible and recoverable**: if the pipeline fails permanently, the page shows a human-readable error and a **Retry research** button that re-queues the whole pipeline.

## What was built

**Gem:** `anthropic` (~1.48.1, official SDK).

**Pipeline (user-approved topology — two chained Solid Queue jobs):**
- `app/services/perplexity_client.rb` — `Net::HTTP` wrapper for `POST https://api.perplexity.ai/chat/completions` (model `sonar-pro`); returns `{content:, sources:}`; maps 429/5xx/timeouts to `TransientError`, everything else to `Error`. `ENV.fetch("PERPLEXITY_API_KEY")` at point of use.
- `app/jobs/research_job.rb` — guards (`pending_research`/`researching` only), sets `researching`, runs 4 queries (company overview, recent news, person, industry), upserts `ResearchData` (`find_or_initialize_by` on the unique-indexed FK → idempotent), fills `person_social_profiles` from the person query's LinkedIn/X source URLs and `research_sources` from all queries' deduped citations, enqueues `SynthesisJob`.
- `app/jobs/synthesis_job.rb` — guards (`researching` + research present), calls Claude `claude-opus-4-8` with `thinking: {type: :adaptive}`, `max_tokens: 16_000`, and **structured outputs** (`output_config: {format_: {type: :json_schema, schema: BRIEFING_SCHEMA}}` — note the Ruby SDK attribute is `format_`, wire name `format`), upserts `Briefing`, sets `briefing_ready`.
- Both jobs: `retry_on` transients (3 attempts, polynomial backoff) with exhaustion → `failed` + `error_message`; `rescue_from` permanent errors (+ `KeyError` for missing env) → `failed` + message. **Declaration order is load-bearing**: `rescue_from` is declared *before* `retry_on` because later-declared handlers win and the transient classes are subclasses of the permanent ones (`PerplexityClient::TransientError < Error`; `Anthropic::Errors::RateLimitError/InternalServerError/APIConnectionError < APIError`).

**Model:** `Briefing` now `serialize ... coder: JSON` for the 5 content fields (still `text` columns); item shapes: talking_points `{point, detail, supporting_research}`, likely_questions `{topic, question, suggested_context, supporting_research}`, opportunities/risks `{title, detail}`, key_facts `[string]`.

**Controller/routes:** `confirm` now enqueues `ResearchJob`; new member `post :retry` → `InterviewRequestsController#retry` (only from `failed`; clears `error_message`, sets `pending_research`, enqueues). `show` passes `briefing` and `research` props.

**Frontend (`interview_requests/Show.tsx`):** briefing sections with click-to-expand items (`ExpandableItem` — local component, design-system tokens only), research accordion, in-progress callout + 5s `router.reload({only: [...]})` polling while `pending_research`/`researching`, Retry button in the failed callout.

**Tests** (81 runs, 230 assertions, green): PerplexityClient parsing/fallback/error mapping (stubbed `Net::HTTP`); ResearchJob happy path/idempotent re-run/guard/permanent→failed/transient→re-enqueued; SynthesisJob happy path/overwrite/guards/unparseable→failed (stubbed `Anthropic::Client`); controller confirm-enqueues, retry-resets+enqueues, retry-rejected-when-not-failed.

## Decisions made

- All four planning decisions user-approved: two-job topology, `claude-opus-4-8`, structured outputs, auto-retry + manual Retry button.
- Perplexity model `sonar-pro` (not asked — picked for research quality; trivially changeable in `PerplexityClient::MODEL`).
- Briefing content stored as JSON in existing text columns via `serialize` (no migration; frontend gets arrays).
- `person_social_profiles` derived from the person-query source URLs rather than a 5th research query.
- Polling via `setInterval` + `router.reload` partial reload (5s) rather than Inertia `usePoll` (equivalent, explicit control).
- Failure handling never re-raises after marking `failed` — the PRD wants visible failure + retry, not a Solid Queue dead job.

## For the next milestone

- **Callback trigger point:** the briefing page (Show.tsx) is where the "Call me now" button goes — render when status is `briefing_ready`. Status flow continues `briefing_ready → completed` (M4 sets `completed` when the callback finishes; `callback_completed_at` column already exists on briefings).
- Briefing content for the voice agent: `request.briefing.talking_points` etc. are arrays of hashes (shapes above) — serialize them into the agent's conversation context.
- `FollowUpQa` model + `follow_up_qas` table ready since M1; nothing writes to them yet.
- The webhook controller (`Webhooks::ElevenlabsController`) currently assumes every `post_call_transcription` is an **intake** call — M4's callback post-call webhook will arrive at the same endpoint, so it must learn to distinguish intake vs callback conversations (e.g. by `agent_id` or by matching `conversation_id` against an expected-callback record).
- **Dev environment warning:** the user runs their own dev server in a VS Code terminal (auto-restarts; it does NOT have `ELEVENLABS_WEBHOOK_SECRET`/API keys set). Don't kill it or fight it for port 5000 — use it for browsing, and create test data via `rails runner` instead of the webhook when the secret is missing. `tmp/run_pipeline_stubbed.rb <id>` runs the full pipeline with stubbed external clients; `tmp/verify_m3.mjs <id> confirm|briefing` drives the browser checks.
- Real-API end-to-end run (actual Perplexity + Claude calls) has **not** been exercised — needs `PERPLEXITY_API_KEY` + `ANTHROPIC_API_KEY` in the server/jobs environment. The failure path (missing key → `failed` + message + Retry) was verified live through the real jobs daemon.

## Deviations from the PRD

- None.
