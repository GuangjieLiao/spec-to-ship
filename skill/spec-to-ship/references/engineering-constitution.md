# Company Constitution v0.1

Use these principles until the team replaces them with real company rules.

## Non-Negotiables

- Clarify intent before code for any non-trivial change.
- Keep requirements and implementation decisions separate.
- Do not silently expand scope.
- Prefer small independently verifiable changes.
- Evidence beats claims: completion requires commands, results, or explicit manual checks.
- Production-impacting changes require rollback and monitoring consideration.
- Security, privacy, permissions, and data integrity concerns override speed.

## Default Engineering Bar

- Business logic changes need focused tests unless the user explicitly accepts direct mode.
- Public API changes need compatibility notes and example request/response impact.
- Database changes need migration, rollback, and data-safety notes.
- UI changes need responsive/manual verification notes.
- Bug fixes need a reproduction note and a regression check.
- Refactors need behavior-preservation evidence.

## AI Collaboration Rules

- Ask for confirmation at decision points.
- State assumptions in artifacts, not only chat.
- Record skipped checks with a reason.
- If a check cannot be run locally, document the blocker and the substitute evidence.
