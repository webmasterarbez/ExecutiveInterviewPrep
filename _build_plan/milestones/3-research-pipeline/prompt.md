# Milestone 3 — Research pipeline

You are entering plan mode to plan and then build milestone 3 of this project.

## Context — read before planning

- `@_build_plan/prd.md` — full project context, scope, data model, and tech stack. The **"Build conventions & guardrails (all milestones)"** section is binding — especially: external API calls run in Solid Queue jobs, jobs are idempotent, and permanent failures set `failed` + `error_message` instead of failing silently.
- `@CLAUDE.md` — repo ground truth: Inertia response rules, page metadata, design system, testing requirements.
- The milestone-log.md files in `@_build_plan/milestones/1-app-setup-auth/` and `@_build_plan/milestones/2-voice-intake-capture/` — what has already been built.

## Working rules (binding)

1. **Think before coding.** State your assumptions explicitly. If multiple interpretations exist, present them — don't pick silently.
2. **Simplicity first.** Minimum code that meets "Done when". Nothing speculative.
3. **Surgical changes.** Touch only milestone 3 scope. Match existing style.
4. **Goal-driven execution.** Plan numbered steps, each with its own verification check.

## Your task

1. Plan the implementation for **only** milestone 3 as defined in the PRD. Do not plan or build anything from later milestones.
2. Surface assumptions and open decisions with the AskUserQuestion tool before locking the plan. At minimum:
   - Job topology: one job per research area vs. a single research job followed by a synthesis job (recommend the simpler).
   - Claude model choice and how synthesis output is structured/validated into the Briefing fields.
   - Retry behavior: automatic retries vs. the dashboard retry action only.
3. After the user confirms the plan, build only what is in milestone 3's scope.
4. Verify against milestone 3's "Done when" criteria, and run the full verification checklist from the PRD's guardrails section: `bin/rails test` green (stub external APIs in tests), `npm run check` clean, `bin/rubocop` clean, browser-verify the flows, screenshots in `tmp/screenshots/`.
5. When complete, write `_build_plan/milestones/3-research-pipeline/milestone-log.md` structured as:
   - **`## What's new in the app`** at the very top — concise, user-facing capabilities for a non-technical reviewer.
   - **`## What was built`** — files, models, routes, migrations, jobs, tests.
   - **`## Decisions made`** — anything decided that wasn't pre-specified in the PRD.
   - **`## For the next milestone`** — anything milestone 4's agent needs to know.
   - **`## Deviations from the PRD`** — what and why (or "none").
