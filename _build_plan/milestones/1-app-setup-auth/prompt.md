# Milestone 1 — App setup & domain foundation

You are entering plan mode to plan and then build milestone 1 of this project.

## Context — read before planning

- `@_build_plan/prd.md` — full project context, scope, data model, and tech stack. The **"Build conventions & guardrails (all milestones)"** section and the data model are binding for this milestone.
- `@CLAUDE.md` — repo ground truth: Inertia response rules, page metadata (four head tags on every page), design system usage, SSR constraints, and testing requirements.
- This is milestone 1, so there are no prior milestone logs. The starter already provides auth, the app shell, dashboard, settings, and profile pages — verify what exists in the codebase before planning, and build only the delta described in the PRD's milestone 1 section.

## Working rules (binding)

1. **Think before coding.** State your assumptions explicitly. If multiple interpretations of the PRD exist, present them — don't pick silently.
2. **Simplicity first.** Minimum code that meets "Done when". No features beyond milestone 1 scope, no speculative abstractions or configurability.
3. **Surgical changes.** Touch only what milestone 1 requires. Don't refactor or restyle starter code. Match existing style.
4. **Goal-driven execution.** Plan numbered steps, each with its own verification check.

## Your task

1. Plan the implementation for **only** milestone 1 as defined in the PRD. Do not plan or build anything from later milestones.
2. Surface assumptions and open decisions with the AskUserQuestion tool before locking the plan (e.g. phone number validation approach, seed data shape).
3. After the user confirms the plan, build only what is in milestone 1's scope.
4. Verify against milestone 1's "Done when" criteria, and run the full verification checklist from the PRD's guardrails section: `bin/rails test` green, `npm run check` clean, `bin/rubocop` clean, browser-verify the flows, screenshots in `tmp/screenshots/`.
5. When complete, write `_build_plan/milestones/1-app-setup-auth/milestone-log.md` structured as:
   - **`## What's new in the app`** at the very top — a concise, human-readable bulleted list of user-facing capabilities added in this milestone, written for a non-technical reviewer.
   - **`## What was built`** — files created, models added, routes added, migrations, tests.
   - **`## Decisions made`** — anything decided during implementation that wasn't pre-specified in the PRD.
   - **`## For the next milestone`** — anything milestone 2's agent needs to know.
   - **`## Deviations from the PRD`** — what and why (or "none").
