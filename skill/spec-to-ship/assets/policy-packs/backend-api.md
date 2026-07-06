# Policy Pack: backend-api

## Purpose

Protect API behavior, compatibility, and integration contracts.

## Load When

Load for public or internal API changes, request/response shape changes, auth boundary changes, webhooks, service integrations, or client-visible behavior.

## Added Gates

- Document compatibility impact in `design.md`.
- Include request/response examples for new or changed behavior.
- Add focused tests for success and failure paths when practical.
- Record auth, permission, rate-limit, idempotency, and error-format assumptions when relevant.

## Required Evidence

- API acceptance scenarios in `spec.md`.
- Test or manual request evidence in `verify.md`.
- Backward compatibility notes and migration guidance when behavior changes.

## Skip Policy

Skipping API tests requires a reason and substitute evidence such as manual curl output, contract review, or local integration notes.
