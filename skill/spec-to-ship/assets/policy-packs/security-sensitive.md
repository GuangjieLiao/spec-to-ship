# Policy Pack: security-sensitive

## Purpose

Raise the bar for changes that affect trust boundaries, sensitive data, or abuse risk.

## Load When

Load for auth, authorization, permissions, secrets, PII, privacy, payments, tenant isolation, audit logging, abuse controls, or policy enforcement.

## Added Gates

- Identify protected assets, actors, trust boundaries, and failure modes in `design.md`.
- Prefer deny-by-default behavior for permission or policy changes.
- Add focused negative tests or manual abuse checks when practical.
- Record privacy impact and logging/audit implications in `release.md`.

## Required Evidence

- Security acceptance scenarios in `spec.md` or `design.md`.
- Verification of allowed and denied paths.
- Residual risk statement that names any untested sensitive path.

## Skip Policy

Security review cannot be silently skipped. If no security test is practical, record why and include substitute review evidence.
