---
name: spec-to-ship
description: Spec to Ship workflow for AI-assisted software changes that need to move from clarified requirements to verified, release-minded code. Use when a user wants production-minded AI coding, team engineering discipline, OpenSpec + Superpowers coordination, spec-first development, requirement clarification, technical design, implementation planning, verification evidence, release readiness checks, or a reusable workflow for features, bug fixes, refactors, and production changes.
---

# Spec to Ship

Run a production-minded spec coding workflow. Prefer OpenSpec as the WHAT source of truth and Superpowers as the HOW execution discipline when they are available; otherwise use the local `spec-to-ship/` fallback artifacts in this skill.

This first version is intentionally runnable before team standards are finalized. Treat `references/engineering-constitution.md` as the default policy, then replace or extend it with real company rules after trial runs.

## Mental Model

- OpenSpec owns WHAT: problem, scope, capability spec, scenarios, archive.
- Superpowers owns HOW: brainstorming, planning, TDD, debugging, review, branch finish.
- This skill owns FLOW: mode routing, stage state, required human confirmations, verification evidence, release readiness.

Do not ask the user to understand schema or workflow internals before using the skill. Route the request, create the artifacts, and explain only the next decision point.

## Stage Flow

```text
open -> design -> build -> verify -> release-ready -> archive
```

Use `scripts/spec-to-ship-state.sh` to initialize and update state, and `scripts/spec-to-ship-guard.sh` before leaving a stage.

Comet-inspired mechanisms included in this skill:

- Context pack and hash-based reread avoidance: `references/context-management.md`
- Active/passive context compression recovery: `references/context-management.md`
- Auto transition control: `references/auto-transition.md`
- Phase drift guard rules: `references/phase-guard.md`
- Optional OpenSpec custom schema: `references/openspec-schema.md`
- Optional semantic code index check through `scripts/spec-to-ship-doctor.sh`

## Mode Routing

Pick one mode at the start and record it in state.

| Mode | Use when | Required stages |
|---|---|---|
| `tweak` | Copy/docs/config value/style-only, no behavior change, usually <= 2 files | open, build, verify, archive |
| `hotfix` | Focused bug fix, no new capability/API/schema, usually <= 3 files | open, build, verify, release-ready, archive |
| `normal` | Default feature/refactor/business change | all stages |
| `epic` | Multiple capabilities, multiple services, roadmap/PRD, or likely > 8 tasks | open, split into smaller changes |

If unsure, choose `normal`. If a `tweak` or `hotfix` expands beyond its limits, pause and ask whether to upgrade to `normal`.

## Artifact Location

Use the first available location:

1. Existing OpenSpec change: `openspec/changes/<change-name>/`
2. New OpenSpec change if OpenSpec is installed and initialized.
3. Local fallback: `spec-to-ship/changes/<change-name>/`

Every change must contain:

```text
.spec-to-ship.yaml
proposal.md
spec.md
design.md
tasks.md
verify.md
release.md
```

For OpenSpec projects, `proposal.md`, `design.md`, `tasks.md`, and `specs/**/spec.md` remain canonical if they already exist. `spec.md` may be a short index pointing at OpenSpec delta specs.

State defaults created by `spec-to-ship-state.sh init` include:

- `auto_transition: true`
- `context_compression: pack`
- `context_pack: null`
- `context_hash: null`
- `review_mode: null`
- `tdd_mode: null`
- `verify_fail_count: 0`

Do not mutate `phase` directly. Use guard `--apply` or `spec-to-ship-state.sh transition`.

## Open Stage

Goal: make the request clear enough to safely design or implement.

1. Classify mode.
2. Pick a kebab-case English change name.
3. Create the artifact directory and initialize `.spec-to-ship.yaml`.
4. Draft or update `proposal.md` and `spec.md`.
5. Pause for user confirmation before leaving open.

`proposal.md` must include:

- Problem
- Goal
- Non-goals
- Scope
- Risks and unknowns
- Acceptance scenarios

`spec.md` must include behavior rules and edge cases. For UI/API/data/security changes, include the relevant scenario format from `references/spec-writing.md`.

Guard:

```bash
bash <skill-dir>/scripts/spec-to-ship-guard.sh <change-dir> open
```

Apply transition and inspect next step:

```bash
bash <skill-dir>/scripts/spec-to-ship-guard.sh <change-dir> open --apply
```

## Design Stage

Skip only for `tweak` and simple `hotfix`.

1. Read `references/engineering-constitution.md`.
2. Read relevant standards only when triggered:
   - API change: `references/api-standards.md`
   - Database change: `references/database-standards.md`
   - Test strategy: `references/testing-standards.md`
   - Security-sensitive change: `references/security-review.md`
   - Production risk: `references/production-readiness.md`
3. Use Superpowers `brainstorming` when available. If unavailable, conduct the same design discussion manually.
4. Present 1-3 viable approaches, recommendation, tradeoffs, test strategy, and risks.
5. Pause for user confirmation before writing the final design.
6. Write `design.md`.
7. Write a design checkpoint and context pack before moving to build.

`design.md` must include:

- Chosen approach
- Alternatives considered
- Module/file impact
- Data/API/security impact
- Test strategy
- Rollback or mitigation notes for production-sensitive changes

Guard:

```bash
bash <skill-dir>/scripts/spec-to-ship-guard.sh <change-dir> design
```

Context handoff:

```bash
bash <skill-dir>/scripts/spec-to-ship-checkpoint.sh <change-dir> design "Design confirmed; ready for build planning"
bash <skill-dir>/scripts/spec-to-ship-context.sh write <change-dir> build
```

After the context pack is written, prefer active context compression before heavy build work. If the current platform cannot compact programmatically, tell the user the recovery files from `references/context-management.md`.

## Build Stage

Goal: implement without expanding scope silently.

1. Write or refine `tasks.md`.
2. Ask for execution choices when risk is non-trivial:
   - branch or worktree
   - TDD or direct
   - review mode: off, standard, thorough
3. Use Superpowers `writing-plans`, `executing-plans`, `test-driven-development`, `systematic-debugging`, and `requesting-code-review` when available and relevant.
4. If CodeGraph is installed and indexed, use it for semantic navigation before broad file reads.
5. Implement tasks.
6. Keep `tasks.md` checked off as tasks complete.
7. Write a build checkpoint after every meaningful task batch.
8. If implementation changes scope, update `spec.md` and `design.md`; for medium/large scope drift, pause for user confirmation.

`tasks.md` must include tasks with evidence expectations, for example:

```markdown
- [ ] Add service validation
  - Evidence: unit test for invalid input and successful build
```

Guard:

```bash
bash <skill-dir>/scripts/spec-to-ship-guard.sh <change-dir> build
```

Checkpoint example:

```bash
bash <skill-dir>/scripts/spec-to-ship-checkpoint.sh <change-dir> build "Completed task batch: <summary>"
```

## Verify Stage

Goal: produce evidence, not claims.

1. Run appropriate project checks: build, tests, lint/typecheck, focused manual checks.
2. Run code review when review mode is `standard` or `thorough`.
3. Fill `verify.md` with exact commands and results.
4. Use hash-on-demand before rereading long artifacts: compare `context_hash` with `spec-to-ship-context.sh hash`.
5. If any critical check fails, return to build after user confirmation.

`verify.md` must include:

- Changed files summary
- Commands run
- Test/build/lint results
- Acceptance scenario result
- Review findings and disposition
- Known residual risk

Guard:

```bash
bash <skill-dir>/scripts/spec-to-ship-guard.sh <change-dir> verify
```

Verification failure policy:

- Do not loop indefinitely.
- Each verify failure should increment `verify_fail_count` via `spec-to-ship-state.sh transition <change-dir> verify-fail` after user chooses to fix.
- After 3 failures, stop and ask the user whether to narrow scope, accept non-critical risk, or redesign.

## Release-Ready Stage

Skip only for `tweak` unless the user requests a release check.

Goal: decide whether the change is safe to merge or ship.

Run:

```bash
bash <skill-dir>/scripts/verify-production-ready.sh <change-dir>
```

Fill `release.md` with:

- CI status or local substitute
- Migration impact
- Feature flag or rollout plan
- Rollback plan
- Monitoring/logging impact
- Security/privacy impact
- Deployment notes

For low-risk local-only changes, explicitly mark non-applicable items as `N/A` with a reason.

Guard:

```bash
bash <skill-dir>/scripts/spec-to-ship-guard.sh <change-dir> release-ready
```

## Archive Stage

Goal: close the loop so future agents can trust the artifacts.

1. Confirm with the user before archive.
2. Ensure `verify.md` and `release.md` are complete enough for the mode.
3. If using OpenSpec, archive through OpenSpec when appropriate.
4. If using fallback artifacts, run `scripts/archive-change.sh` to move the change to `spec-to-ship/archive/YYYY-MM-DD-<change-name>/`.
5. Mark state as archived.

Do not archive if verification failed or production readiness is unresolved.

## Context And Token Policy

Read `references/context-management.md` before long design/build work or after any resume/compaction event.

Token-saving defaults:

- Load only the relevant reference docs.
- Create context packs instead of rereading all artifacts.
- Use checkpoints before active compaction.
- Use `grep`/targeted reads for `tasks.md` completion checks.
- Use hash comparison to decide whether to reread artifacts.
- Use a subagent for large implementation plans when available, so the main session keeps less planning context.

## Custom Schema Policy

Fallback Markdown artifacts remain supported and are enough for trial runs. A starter OpenSpec schema is now included for completeness:

```bash
bash <skill-dir>/scripts/install-openspec-schema.sh <repo-root>
```

Use it when the repo already uses OpenSpec and the team wants OpenSpec to formally track `verify.md` and `release.md`. If OpenSpec rejects the schema because its local schema format differs, continue with fallback artifacts and adapt the schema for that OpenSpec version.

## Decision Points

Pause and wait for explicit user choice at these points:

- proposal/spec confirmation
- final technical design confirmation
- execution mode selection for non-trivial changes
- scope expansion or mode upgrade
- failed verification: fix or accept non-critical risk
- release readiness with unresolved production risk
- archive confirmation

Do not use historical preference or your own recommendation as user confirmation.

## Resume Protocol

On every resume:

1. Read `.spec-to-ship.yaml`.
2. Run `spec-to-ship-state.sh next <change-dir>`.
3. Read `references/phase-guard.md`.
4. If `context_pack` exists, read it before rereading full artifacts.
5. If a stage checkpoint exists, read it before continuing.
6. Continue only from the detected phase.

## Quick Commands

Initialize fallback state:

```bash
bash <skill-dir>/scripts/spec-to-ship-state.sh init spec-to-ship/changes/<name> <mode>
```

Set a field:

```bash
bash <skill-dir>/scripts/spec-to-ship-state.sh set <change-dir> phase build
```

Check current state:

```bash
bash <skill-dir>/scripts/spec-to-ship-state.sh get <change-dir>
```

Transition safely:

```bash
bash <skill-dir>/scripts/spec-to-ship-state.sh transition <change-dir> open-complete
bash <skill-dir>/scripts/spec-to-ship-state.sh next <change-dir>
```

Create context pack:

```bash
bash <skill-dir>/scripts/spec-to-ship-context.sh write <change-dir> build
```

Write checkpoint:

```bash
bash <skill-dir>/scripts/spec-to-ship-checkpoint.sh <change-dir> build "checkpoint note"
```

Check optional tools:

```bash
bash <skill-dir>/scripts/spec-to-ship-doctor.sh <repo-root>
```

Install optional OpenSpec schema:

```bash
bash <skill-dir>/scripts/install-openspec-schema.sh <repo-root>
```

Collect simple evidence:

```bash
bash <skill-dir>/scripts/collect-evidence.sh <change-dir>
```

Archive fallback artifacts:

```bash
bash <skill-dir>/scripts/archive-change.sh <change-dir>
```
