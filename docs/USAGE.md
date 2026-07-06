# Usage Guide

This guide explains how to use Spec to Ship in a new project.

## 1. Install Or Update The Skill

From this repository:

```bash
bash scripts/install.sh
```

Verify it exists:

```bash
ls ~/.codex/skills/spec-to-ship/SKILL.md
```

Restart or reload Codex so the skill is discoverable.

To update an existing installation:

```bash
git pull
bash scripts/install.sh
```

On Windows PowerShell, if `bash` is not available directly:

```powershell
& 'C:\Program Files\Git\bin\bash.exe' scripts/install.sh
```

The installer replaces the installed copy at `~/.codex/skills/spec-to-ship` with the current repository version.

## 2. Start A Change

For a new or existing project, first initialize project-level agent docs:

```text
$spec-to-ship init
```

The init flow scans the target project, creates missing files only, and preserves existing docs by default:

```text
AGENTS.md
docs/agent-map.md
docs/architecture-index.md
docs/decisions/0001-initialize-agent-docs.md
docs/tech-debt.md
docs/quality-score.md
spec-to-ship/config.yaml
```

For existing projects, it records facts it can infer from files such as `package.json`, lockfiles, `pyproject.toml`, `go.mod`, `Cargo.toml`, common source/test directories, `.github/workflows/`, and Docker files. For blank projects, the generated files intentionally use placeholders such as "No run command has been confirmed yet." Do not treat those placeholders as final architecture. Future Spec to Ship changes should replace them with observed facts.

By default, project docs are generated with Chinese body text while filenames such as `AGENTS.md` and `docs/agent-map.md` stay stable in English.

For English project documentation:

```text
$spec-to-ship init --lang en
```

The selected language is recorded in `spec-to-ship/config.yaml` as `agent_docs.language`.

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

## 3. Select Policy Packs

Spec to Ship starts with the lightweight default policy. Additional policy packs are loaded only when they match the change or when you ask for them:

- `strict-team`: stricter team or production gates.
- `frontend-prototype`: screenshot, Figma, mockup, responsive UI, or visual fidelity work.
- `backend-api`: API contracts, request/response behavior, auth boundaries, or service integrations.
- `database-change`: schema, migration, backfill, retention, or data-integrity work.
- `security-sensitive`: permissions, secrets, PII, privacy, tenant isolation, or abuse risk.

Example:

```text
Use $spec-to-ship in strict-team mode for this API change: add CSV export for admin reports.
```

Equivalent explicit examples:

```text
Use $spec-to-ship with backend-api policy for this change: add CSV export for admin reports.
Use $spec-to-ship with database-change policy for this change: add an index to report exports.
Use $spec-to-ship with security-sensitive policy for this change: restrict report export permissions.
```

When multiple packs apply, the stricter rule wins. Skipped policy checks should be recorded in `verify.md` with a reason.

## 4. Work Through The Stages

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
- agent docs impact: updated docs or reason no update was needed
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

## 5. Useful Commands

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

## 6. What To Expect

The workflow is intentionally more disciplined than ordinary AI coding. It should stop at decision points instead of silently deciding:

- scope confirmation
- design confirmation
- execution mode selection
- failed verification
- unresolved release risk
- archive confirmation

For small tweaks this should still stay lightweight. For production changes it should produce enough evidence for review.
