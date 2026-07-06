# Roadmap

## v0.1

- Installable Codex skill.
- Fallback Markdown artifacts.
- Phase state and guard scripts.
- Context pack and checkpoints.
- Optional OpenSpec schema.
- Production readiness checklist.
- Indexed policy packs for default, strict-team, frontend, backend API, database, and security-sensitive flows.
- `$spec-to-ship init` for project-level agent docs and configuration.

## v0.2

- Add richer examples for frontend, backend, API, database, and hotfix flows.
- Add integration tests for OpenSpec-backed projects.
- Improve schema compatibility across OpenSpec versions.
- Expand project-level configuration for default mode, review mode, release policy, and default policy packs.

## v0.3

- Add deeper CodeGraph integration when available.
- Add multi-agent plan handoff examples.
- Add reusable external company policy packs.
- Add dashboard or report generator for active changes.

## Open Questions

- Which OpenSpec schema fields should become stable project configuration?
- How strict should release-ready be for internal-only projects?
- Should review mode default to `standard` for `normal` changes?
- Should strict-team policy default review mode to `standard` or `thorough`?
- What evidence format works best for pull request descriptions?
