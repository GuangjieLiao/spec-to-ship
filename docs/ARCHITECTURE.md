# Architecture

Spec to Ship is a skill plus a small workflow runtime.

## Core Idea

The workflow separates responsibility:

```text
OpenSpec      -> WHAT
Superpowers   -> HOW
Spec to Ship  -> FLOW
```

This separation prevents one document from becoming a mix of requirements, implementation choices, task state, and release risk.

## Main Components

### `SKILL.md`

The main instruction surface. It contains only the workflow and routing rules that an agent needs at runtime.

Design choice: keep the main skill readable and load detailed references only when needed.

Benefit: saves context and reduces the chance that irrelevant rules distract the agent.

### `references/`

Detailed policies and mechanisms:

- `engineering-constitution.md`: default engineering principles.
- `context-management.md`: context pack, checkpoints, active/passive compression.
- `phase-guard.md`: rules that prevent phase drift.
- `openspec-schema.md`: optional OpenSpec schema usage.
- `prototype-fidelity.md`: screenshot, Figma, HTML prototype, and mockup implementation fidelity.
- API, database, testing, security, and production readiness guides.

Design choice: progressive disclosure.

Benefit: an API-only change should not load database and security policy unless triggered.

### `scripts/spec-to-ship-state.sh`

Owns state transitions in `.spec-to-ship.yaml`.

Important behavior:

- initializes default fields;
- blocks direct `phase` mutation;
- supports explicit transitions like `open-complete`, `verify-pass`, `release-pass`;
- emits the next stage through `next`.

Design choice: state transitions live in a script, not only prompt text.

Benefit: agents cannot casually jump from `open` to `build`; drift becomes detectable.

### `scripts/spec-to-ship-guard.sh`

Checks whether a stage can be exited.

Examples:

- `open` requires proposal/spec content.
- `build` requires all tasks checked.
- `verify` requires commands, acceptance checks, and residual risk notes.
- `release-ready` requires rollback and monitoring/security notes.

Design choice: stage exit is guarded.

Benefit: "done" must be backed by artifacts.

### `scripts/spec-to-ship-context.sh`

Creates a compact context pack:

```text
.spec-to-ship/handoff/<stage>-context.md
.spec-to-ship/handoff/<stage>-context.json
```

It records source artifact hashes and truncates long files unless `--full` is used.

Design choice: recover from long sessions with durable context, not chat history.

Benefit: saves tokens and makes context compaction safer.

### `scripts/spec-to-ship-checkpoint.sh`

Appends stage checkpoints:

```text
.spec-to-ship/checkpoints/design.md
.spec-to-ship/checkpoints/build.md
.spec-to-ship/checkpoints/verify.md
```

Design choice: checkpoint after design decisions and task batches.

Benefit: after context loss, the agent can resume from facts on disk.

### `references/prototype-fidelity.md`

Defines how to treat screenshots, Figma frames, HTML prototypes, and mockups as implementation contracts.

Design choice: prototype fidelity is a mode and a verification gate, not a vague instruction.

Benefit: UI work can be checked with source screenshots, implementation screenshots, viewport sizes, mismatch lists, and accepted deviations.

### `scripts/verify-production-ready.sh`

Checks that `release.md` contains the minimum production readiness sections.

Design choice: release readiness is a first-class stage.

Benefit: release risk is considered before archive, not after code is already considered complete.

### Optional OpenSpec Schema

The starter schema is in:

```text
skill/spec-to-ship/assets/openspec-schema/spec-to-ship/
```

It adds `verify` and `release` artifacts after OpenSpec's normal proposal/spec/design/tasks flow.

Design choice: schema is optional.

Benefit: teams can trial the workflow without committing to OpenSpec schema customization, then adopt it once stable.

## Data Flow

```text
User request
  -> open artifacts
  -> prototype artifact when visual reference exists
  -> design artifact
  -> context pack + checkpoint
  -> tasks
  -> implementation
  -> verify evidence
  -> release readiness
  -> archive
```

## Why Not Just A Prompt?

A prompt can tell the agent what to do, but it cannot reliably:

- preserve state across sessions;
- enforce phase transitions;
- compare context hashes;
- create repeatable evidence snapshots;
- validate release readiness;
- install OpenSpec schema assets.

Spec to Ship uses prompt instructions for judgment and scripts for repeatable workflow mechanics.
