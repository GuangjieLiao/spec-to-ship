# Design Rationale

This document explains why Spec to Ship is designed this way.

## 1. Keep WHAT And HOW Separate

Requirements drift happens when agents mix product intent, technical choices, and implementation notes in one place.

Spec to Ship keeps:

- `proposal.md` and `spec.md` for WHAT;
- `design.md` for HOW;
- `tasks.md` for execution;
- `verify.md` for proof;
- `release.md` for production risk.
- `prototype.md` for visual reference fidelity when a UI prototype exists.

Benefit: reviewers can inspect the right artifact for the right question.

## 2. Treat Prototypes As Contracts, Not Inspiration

When a user provides a prototype, screenshot, or Figma frame, ordinary AI coding often implements the "idea" but misses exact layout, spacing, wording, responsive behavior, and interaction states.

Spec to Ship adds prototype mode:

- capture the prototype source in `prototype.md`;
- inventory visible text, layout, assets, states, and viewports;
- require screenshot-based verification;
- record accepted deviations explicitly.

Benefit: visual fidelity becomes a checkable requirement instead of subjective feedback after the fact.

## 3. Add A Flow Layer Above OpenSpec And Superpowers

OpenSpec handles spec lifecycle well. Superpowers handles execution discipline well. The missing piece is coordination.

Spec to Ship provides that coordination:

- mode routing;
- state file;
- guard scripts;
- checkpoints;
- context packs;
- release readiness.

Benefit: users do not need to remind the agent to update documents, verify evidence, or pause at decision points.

## 4. Keep Core General, Put Strict Rules In Policy Packs

A reusable workflow should not assume every team has the same CI, release, monitoring, API, database, or security process.

Spec to Ship keeps the core workflow general and adds optional policy packs:

- `default-light` for low-friction adoption.
- `strict-team` for stronger production discipline.
- domain packs for frontend prototypes, backend APIs, database changes, and security-sensitive work.

Benefit: new users can start lightly, while real teams can layer stricter rules without forking the skill or bloating `SKILL.md`.

## 5. Initialize Project Knowledge Before Change Work

Per-change artifacts are not enough for long-lived projects. Future agents also need stable project-level entry points: how to run the project, where code lives, what architecture is known, and what debt has been observed.

Spec to Ship adds `$spec-to-ship init` to create:

- `AGENTS.md`
- `docs/agent-map.md`
- `docs/architecture-index.md`
- `docs/decisions/`
- `docs/tech-debt.md`
- `docs/quality-score.md`
- `spec-to-ship/config.yaml`

Benefit: blank projects start with a maintenance contract instead of invented architecture, and existing projects get a safe adoption path that preserves current docs.

## 6. Make Context Loss A Normal Case

Long AI coding tasks often hit context pressure. Spec to Ship treats that as expected.

Mechanisms:

- `context_pack`;
- `context_hash`;
- stage checkpoints;
- resume protocol.

Benefit: the agent can recover from files, not memory.

## 7. Use Scripts For Mechanical Rules

The agent still makes engineering judgments, but mechanical rules belong in scripts:

- phase transition;
- required artifact checks;
- policy-pack discoverability;
- release checklist;
- schema installation;
- evidence collection.

Benefit: deterministic checks are easier to trust and improve.

## 8. Keep Schema Optional

OpenSpec schema is useful, but forcing it too early makes adoption harder.

Spec to Ship supports both:

- fallback Markdown artifacts;
- optional OpenSpec schema.

Benefit: teams can start using the workflow immediately and formalize schema later.

## 9. Optimize For Reviewable Work

The workflow is not just about producing code. It is about producing code that another engineer can review.

That is why `verify.md` and `release.md` are first-class artifacts.

Benefit: "AI did it" becomes less important than "the evidence is inspectable."
