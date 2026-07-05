# Context Management v0.2

This workflow uses Comet-inspired context controls without requiring Comet.

## Mechanisms

- **Progressive loading**: Keep `SKILL.md` short. Read only the reference file that matches the current risk: API, database, testing, security, production.
- **Context pack**: Before moving from design to build, run `scripts/spec-to-ship-context.sh write <change-dir> build`. The generated pack is a compact, hash-tracked view of artifacts.
- **Hash-on-demand**: Before re-reading long artifacts, compare `context_hash` with `scripts/spec-to-ship-context.sh hash <change-dir>`. If unchanged, prefer the existing context pack and targeted reads.
- **Checkpointing**: After design decisions, plan creation, task batches, and verification attempts, run `scripts/spec-to-ship-checkpoint.sh <change-dir> <stage> "<note>"`.
- **Active compression**: After a checkpoint is written and before heavy build work, trigger the platform's native context compaction if available. If the platform cannot do this programmatically, tell the user the safe recovery files.
- **Passive recovery**: After any context loss, reload `.spec-to-ship.yaml`, the latest checkpoint, and the current `context_pack` before continuing.

## Required Recovery Reads

On resume:

1. Read `.spec-to-ship.yaml`.
2. Read the current stage artifact: `design.md`, `tasks.md`, `verify.md`, or `release.md`.
3. Read `context_pack` if it exists.
4. Read the stage checkpoint if the matching state field is set.
5. Run `scripts/spec-to-ship-state.sh next <change-dir>` to determine whether to continue automatically or pause.

## Active Compression Prompt

Use this when asking the user to compact manually:

```text
Checkpoint is written. Safe recovery files:
- <change-dir>/.spec-to-ship.yaml
- <context_pack>
- <stage_checkpoint>

Please compact the current context if your tool supports it, then ask me to continue.
```
