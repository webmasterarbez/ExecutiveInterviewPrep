# Milestone 5 — Audio & written briefings

You are entering plan mode to plan and then build milestone 5 of this project. This is the final milestone.

## Context — read before planning

- `@_build_plan/prd.md` — full project context, scope, data model, and tech stack. The **"Build conventions & guardrails (all milestones)"** section is binding for this milestone.
- `@CLAUDE.md` — repo ground truth: Inertia response rules, page metadata, design system, testing requirements.
- The milestone-log.md files from milestones 1–4 — what has already been built.

## Working rules (binding)

1. **Think before coding.** State your assumptions explicitly. If multiple interpretations exist, present them — don't pick silently.
2. **Simplicity first.** Minimum code that meets "Done when". Nothing speculative.
3. **Surgical changes.** Touch only milestone 5 scope. Match existing style.
4. **Goal-driven execution.** Plan numbered steps, each with its own verification check.

## Your task

1. Plan the implementation for **only** milestone 5 as defined in the PRD. Do not plan or build anything beyond this milestone.
2. Surface assumptions and open decisions with the AskUserQuestion tool before locking the plan. At minimum:
   - PDF generation library (server-side Ruby — present 1–2 candidates with trade-offs, recommend one).
   - Active Storage backend for the generated files (local disk on the VPS vs. S3) — files attach to the Briefing per the data model.
   - Email shape: PDF attached vs. download link (development verifies via `letter_opener`; production uses AWS SES).
3. After the user confirms the plan, build only what is in milestone 5's scope. Generation runs in a Solid Queue job after synthesis completes.
4. Verify against milestone 5's "Done when" criteria, and run the full verification checklist from the PRD's guardrails section: `bin/rails test` green (stub external APIs in tests), `npm run check` clean, `bin/rubocop` clean, browser-verify the flows (including an actual audio download, PDF download, and the email in `letter_opener`), screenshots in `tmp/screenshots/`.
5. When complete, write `_build_plan/milestones/5-audio-written-briefings/milestone-log.md` structured as:
   - **`## What's new in the app`** at the very top — concise, user-facing capabilities for a non-technical reviewer.
   - **`## What was built`** — files, models, routes, migrations, jobs, mailers, tests.
   - **`## Decisions made`** — anything decided that wasn't pre-specified in the PRD.
   - **`## Deviations from the PRD`** — what and why (or "none").

This is the final milestone. Once complete and verified, the entire `_build_plan/` folder can be deleted — the MVP is shipped.
