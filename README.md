# Spec to Ship

Spec to Ship is an AI coding workflow skill for moving from clarified requirements to verified, release-minded code.

It combines three ideas:

- **OpenSpec owns WHAT**: requirements, capability specs, acceptance scenarios, and archive.
- **Superpowers owns HOW**: brainstorming, implementation planning, TDD, debugging, code review, and branch finish.
- **Spec to Ship owns FLOW**: mode routing, phase state, checkpoints, context packs, verification evidence, and release readiness.

The project is designed for teams that want AI-assisted coding to produce reviewable engineering artifacts, not just chat output.

## Why This Exists

OpenSpec and Superpowers are useful together, but using them directly often creates practical gaps:

- requirements and technical design can become mixed together;
- agents may skip clarification, TDD, review, or verification;
- visual prototypes are often treated as loose inspiration instead of implementation contracts;
- long tasks are hard to resume after context loss;
- "done" is often claimed without evidence;
- production release concerns are handled too late.

Spec to Ship adds a lightweight engineering protocol around those tools.

## Repository Layout

```text
skill/spec-to-ship/        # Installable Codex skill
docs/                      # Usage, architecture, and design rationale
examples/                  # Example artifacts for trial runs
scripts/                   # Repository helper scripts
.github/                   # CI and contribution templates
```

## Quick Install

From a clone of this repository:

```bash
bash scripts/install.sh
```

This installs the skill to:

```text
~/.codex/skills/spec-to-ship
```

Then start a new Codex session or reload skills, and invoke:

```text
$spec-to-ship
```

## Use In A New Project

In your target project, ask Codex:

```text
Use $spec-to-ship for this change: <describe the feature, bug fix, or refactor>
```

The workflow will create either OpenSpec-backed artifacts or fallback artifacts:

```text
spec-to-ship/changes/<change-name>/
├── .spec-to-ship.yaml
├── proposal.md
├── spec.md
├── design.md
├── tasks.md
├── verify.md
└── release.md
```

Prototype-driven UI changes also create `prototype.md`.

For projects that already use OpenSpec, optional schema support is included:

```bash
bash ~/.codex/skills/spec-to-ship/scripts/install-openspec-schema.sh .
openspec schema validate spec-to-ship
```

## Workflow

```text
open -> design -> build -> verify -> release-ready -> archive
```

The skill supports five modes:

- `tweak`: docs, copy, config value, or style-only changes.
- `hotfix`: focused bug fix with limited blast radius.
- `normal`: default feature, refactor, or business change.
- `prototype`: UI implementation from a screenshot, Figma frame, HTML prototype, or visual reference.
- `epic`: large PRD or multiple capabilities that should be split.

## Key Mechanisms

- **Phase guard**: prevents jumping from idea to code without confirmed artifacts.
- **Context pack**: compact handoff bundle with hashes for long sessions.
- **Checkpoint**: durable resume points after design, build batches, and verification.
- **Auto transition**: controlled stage continuation with explicit decision points.
- **Policy packs**: optional strict, team, or domain rules layered on top of the general core.
- **Verification evidence**: commands, results, review notes, skipped checks, and residual risk.
- **Release readiness**: rollback, monitoring, migrations, flags, security/privacy impact.
- **Prototype fidelity**: visual target inventory, screenshot comparison, accepted deviations, and design QA.
- **Optional OpenSpec schema**: formalizes verify/release artifacts when OpenSpec is used.

Bundled policy packs include `default-light`, `strict-team`, `frontend-prototype`, `backend-api`, `database-change`, and `security-sensitive`.

## Documentation

- [中文说明手册](docs/zh-CN/MANUAL.md)
- [Usage Guide](docs/USAGE.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Design Rationale](docs/DESIGN_RATIONALE.md)
- [Roadmap](docs/ROADMAP.md)

## Validation

```bash
bash scripts/validate.sh
```

The validation script checks shell syntax, policy-pack indexing, fallback workflow behavior, and optional OpenSpec schema validity when `openspec` is installed.

## License

MIT
