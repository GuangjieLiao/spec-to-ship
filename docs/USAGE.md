# Usage Guide

This guide explains how to use Spec to Ship in a new project.

## 1. Install The Skill

From this repository:

```bash
bash scripts/install.sh
```

Verify it exists:

```bash
ls ~/.codex/skills/spec-to-ship/SKILL.md
```

Restart or reload Codex so the skill is discoverable.

## 2. Start A Change

In any project, ask:

```text
Use $spec-to-ship for this change: add CSV export for admin reports.
```

Codex should classify the change:

- `tweak`
- `hotfix`
- `normal`
- `prototype`
- `epic`

If the project does not have OpenSpec, the fallback artifact directory is used:

```text
spec-to-ship/changes/<change-name>/
```

## 3. Work Through The Stages

### open

Clarifies the request and creates:

- `proposal.md`
- `spec.md`
- `.spec-to-ship.yaml`

The agent must pause for confirmation before moving on.

### design

Creates technical design:

- chosen approach
- alternatives
- module impact
- test strategy
- rollback or mitigation notes

The stage writes a checkpoint and context pack before build.

For prototype-driven UI work, this stage also creates or updates `prototype.md` with the source prototype, target viewport sizes, visible text inventory, layout/component inventory, assets, interaction states, responsive behavior, and accepted deviations.

### build

Creates tasks and implements them.

For non-trivial changes, the agent asks for:

- branch or worktree
- TDD or direct mode
- review mode: `off`, `standard`, or `thorough`

### verify

Writes evidence into `verify.md`:

- changed files
- commands run
- results
- acceptance scenario checks
- review findings
- residual risk

For prototype mode, verification must include visual evidence: source prototype path, implementation screenshot path, viewport size, visual mismatches, accepted deviations, and final fidelity result.

### release-ready

Writes `release.md`:

- risk level
- CI or local substitute
- migration impact
- rollout or feature flag plan
- rollback
- monitoring/logging
- security/privacy impact

### archive

After user confirmation, archives the change so future work can trust the artifacts.

## 4. Useful Commands

Initialize fallback artifacts:

```bash
bash ~/.codex/skills/spec-to-ship/scripts/spec-to-ship-state.sh init spec-to-ship/changes/my-change normal
```

Check state:

```bash
bash ~/.codex/skills/spec-to-ship/scripts/spec-to-ship-state.sh get spec-to-ship/changes/my-change
```

Create a context pack:

```bash
bash ~/.codex/skills/spec-to-ship/scripts/spec-to-ship-context.sh write spec-to-ship/changes/my-change build
```

Run a guard:

```bash
bash ~/.codex/skills/spec-to-ship/scripts/spec-to-ship-guard.sh spec-to-ship/changes/my-change verify
```

Install optional OpenSpec schema:

```bash
bash ~/.codex/skills/spec-to-ship/scripts/install-openspec-schema.sh .
openspec schema validate spec-to-ship
```

## 5. What To Expect

The workflow is intentionally more disciplined than ordinary AI coding. It should stop at decision points instead of silently deciding:

- scope confirmation
- design confirmation
- execution mode selection
- failed verification
- unresolved release risk
- archive confirmation

For small tweaks this should still stay lightweight. For production changes it should produce enough evidence for review.
