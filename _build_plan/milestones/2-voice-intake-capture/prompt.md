# Milestone 2 — Voice intake & information capture

You are entering plan mode to plan and then build milestone 2 of this project.

## Context — read before planning

- `@_build_plan/prd.md` — full project context, scope, data model, and tech stack. The **"Build conventions & guardrails (all milestones)"** section and the ElevenLabs integration notes are binding for this milestone.
- `@CLAUDE.md` — repo ground truth: Inertia response rules (the ElevenLabs webhook endpoint is a raw-`fetch`-style exception — CSRF-exempt, non-Inertia response), page metadata, design system, testing requirements.
- `@_build_plan/milestones/1-app-setup-auth/milestone-log.md` — what has already been built.

## Working rules (binding)

1. **Think before coding.** State your assumptions explicitly. If multiple interpretations exist, present them — don't pick silently.
2. **Simplicity first.** Minimum code that meets "Done when". Nothing speculative.
3. **Surgical changes.** Touch only milestone 2 scope. Match existing style.
4. **Goal-driven execution.** Plan numbered steps, each with its own verification check.

## Your task

1. Plan the implementation for **only** milestone 2 as defined in the PRD. Do not plan or build anything from later milestones.
2. Surface assumptions and open decisions with the AskUserQuestion tool before locking the plan. At minimum:
   - Structured-field extraction: ElevenLabs built-in data-collection vs. a Claude extraction pass over the transcript (PRD leaves this open — present trade-offs, recommend the simpler one).
   - Development webhook reachability: which tunnel (ngrok/cloudflared) and how the webhook URL gets configured in ElevenLabs.
   - Confirm the ElevenLabs agent/phone-number setup steps the user must perform in the ElevenLabs dashboard vs. what the app automates.
3. After the user confirms the plan, build only what is in milestone 2's scope. The webhook endpoint must verify the ElevenLabs signature and be idempotent (re-delivered webhooks must not duplicate Interview Requests).
4. Verify against milestone 2's "Done when" criteria, and run the full verification checklist from the PRD's guardrails section: `bin/rails test` green, `npm run check` clean, `bin/rubocop` clean, browser-verify the flows, screenshots in `tmp/screenshots/`.
5. When complete, write `_build_plan/milestones/2-voice-intake-capture/milestone-log.md` structured as:
   - **`## What's new in the app`** at the very top — concise, user-facing capabilities for a non-technical reviewer.
   - **`## What was built`** — files, models, routes, migrations, tests.
   - **`## Decisions made`** — anything decided that wasn't pre-specified in the PRD.
   - **`## For the next milestone`** — anything milestone 3's agent needs to know.
   - **`## Deviations from the PRD`** — what and why (or "none").
