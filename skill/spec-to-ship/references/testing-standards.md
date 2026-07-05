# Testing Standards v0.1

Use the narrowest test that proves the behavior, then add broader checks when risk requires it.

## Defaults

- Bug fix: failing/regression test when practical.
- Business logic: unit or service-level tests for main and edge paths.
- API behavior: request/response tests for success and failure paths.
- UI behavior: component or e2e check when behavior is user-visible.
- Refactor: existing test suite plus focused behavior checks.

## When Direct Mode Is Acceptable

- Docs-only or comments-only change.
- Copy/style tweak with manual verification.
- Low-risk config value change with explicit user acceptance.

Record direct mode in `verify.md`.
