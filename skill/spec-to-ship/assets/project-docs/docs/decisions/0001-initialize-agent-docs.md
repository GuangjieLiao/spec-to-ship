# Decision 0001: Initialize Agent Docs

## Status

Accepted

## Context

This project uses Spec to Ship to make AI-assisted development easier to inspect, resume, and verify.

## Decision

Maintain project-level agent documentation alongside per-change Spec to Ship artifacts.

## Consequences

- Future agents should read `AGENTS.md` and `docs/agent-map.md` before broad changes.
- Changes that alter project structure, commands, tests, architecture, deployment, or known debt must update the relevant docs.
- Blank placeholders must be replaced with evidence as the project develops.

