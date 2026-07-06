# Policy Pack: default-light

## Purpose

Keep Spec to Ship usable in unfamiliar projects with light but reliable engineering discipline.

## Load When

Load for every change unless a project-specific default replaces it.

## Added Gates

- Keep open-stage clarification proportional to risk.
- Allow direct mode for docs-only, copy-only, or low-risk style/config changes.
- Require at least one verification artifact before completion.

## Required Evidence

- `verify.md` records changed files, commands or manual checks, acceptance result, skipped checks, and residual risk.
- `release.md` can mark items as `N/A` for low-risk or local-only changes, with reasons.

## Skip Policy

Do not skip this pack unless the project provides a replacement baseline policy.
