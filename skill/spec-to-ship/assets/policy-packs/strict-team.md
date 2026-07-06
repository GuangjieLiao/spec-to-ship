# Policy Pack: strict-team

## Purpose

Turn Spec to Ship into a stronger team engineering protocol for production work.

## Load When

Load when the user asks for strict mode, team policy, production readiness, release discipline, or a high-confidence change.

## Added Gates

- Do not leave open without explicit proposal/spec confirmation.
- Do not leave design without alternatives, rollback notes, and test strategy.
- Do not leave build with unchecked tasks.
- Do not leave verify unless automated checks pass or skipped checks are explicitly accepted.
- Do not archive without user confirmation.

## Required Evidence

- Test or build command output in `verify.md`.
- Review mode recorded as `standard` or `thorough` unless the user accepts direct mode.
- `release.md` includes rollback, monitoring/logging, migration impact, rollout plan, and security/privacy impact.

## Skip Policy

Skipped gates require a named risk owner or explicit user acceptance in `verify.md`.
