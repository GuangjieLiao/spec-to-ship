# Policy Pack: database-change

## Purpose

Make persistence changes recoverable and data-safe.

## Load When

Load for schema changes, migrations, backfills, retention changes, data integrity rules, indexing, or persistence behavior.

## Added Gates

- Document migration plan, rollback plan, and data-safety assumptions in `design.md`.
- Prefer backward-compatible migration sequencing when application and schema deploys are separate.
- Include data validation or migration dry-run evidence when practical.
- Record expected performance or locking impact for large tables.

## Required Evidence

- Migration files or schema diff summary.
- Rollback or mitigation notes in `release.md`.
- Verification command, dry-run output, or explicit local substitute.

## Skip Policy

Skipping migration verification requires explicit user acceptance and a documented rollback or restore path.
