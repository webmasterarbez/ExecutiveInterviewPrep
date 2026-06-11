# Milestone 4 — Callbacks & interactive Q&A

You are entering plan mode to plan and then build milestone 4 of this project.

## Context — read before planning

- `@_build_plan/prd.md` — full project context, scope, data model, and tech stack. The **"Build conventions & guardrails (all milestones)"** section is binding for this milestone.
- `@CLAUDE.md` — repo ground truth: Inertia response rules (callback webhooks are raw-`fetch`-style exceptions), page metadata, design system, testing requirements.
- The milestone-log.md files in `@_build_plan/milestones/1-app-setup-auth/`, `@_build_plan/milestones/2-voice-intake-capture/`, and `@_build_plan/milestones/3-research-pipeline/` — what has already been built.

## Working rules (binding)

1. **Think before coding.** State your assumptions explicitly. If multiple interpretations exist, present them — don't pick silently.
2. **Simplicity first.** Minimum code that meets "Done when". Nothing speculative.
3. **Surgical changes.** Touch only milestone 4 scope. Match existing style.
4. **Goal-driven execution.** Plan numbered steps, each with its own verification check.

## Your task

1. Plan the implementation for **only** milestone 4 as defined in the PRD. Do not plan or build anything from later milestones.
2. Surface assumptions and open decisions with the AskUserQuestion tool before locking the plan. At minimum:
   - Q&A answering design (the PRD leaves this open): ElevenLabs agent's own LLM primed with the briefing as context vs. a custom-LLM bridge to Claude — present trade-offs, recommend the simpler one that meets "Done when".
   - How briefing content is delivered to the outbound agent (dynamic variables / conversation overrides) and any size limits.
   - How Q&A pairs are extracted from the callback (post-call webhook/transcript reuse from milestone 2).
3. After the user confirms the plan, build only what is in milestone 4's scope. Callback completion moves the request to `completed`.
4. Verify against milestone 4's "Done when" criteria, and run the full verification checklist from the PRD's guardrails section: `bin/rails test` green (stub external APIs in tests), `npm run check` clean, `bin/rubocop` clean, browser-verify the flows, screenshots in `tmp/screenshots/`.
5. When complete, write `_build_plan/milestones/4-callbacks-qa/milestone-log.md` structured as:
   - **`## What's new in the app`** at the very top — concise, user-facing capabilities for a non-technical reviewer.
   - **`## What was built`** — files, models, routes, migrations, jobs, tests.
   - **`## Decisions made`** — anything decided that wasn't pre-specified in the PRD.
   - **`## For the next milestone`** — anything milestone 5's agent needs to know.
   - **`## Deviations from the PRD`** — what and why (or "none").
