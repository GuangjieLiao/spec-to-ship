# Policy Packs

Policy packs layer optional engineering rules on top of the Spec to Ship core workflow. The core remains general-purpose; packs add team or domain-specific gates only when they are selected or triggered.

## Loading Rule

Always start with `assets/policy-packs/default-light.md`.

During open and design, load only the additional packs that match the change:

- `strict-team.md`: user asks for strict mode, production discipline, team policy, or non-negotiable gates.
- `frontend-prototype.md`: prototype, screenshot, Figma, HTML mockup, visual fidelity, responsive UI, or user-facing UI behavior.
- `backend-api.md`: public/internal API behavior, request/response contracts, auth boundaries, compatibility, or service integration.
- `database-change.md`: schema, migration, data backfill, data integrity, retention, or rollback-sensitive persistence.
- `security-sensitive.md`: auth, permissions, secrets, PII, privacy, payments, tenant isolation, policy enforcement, or abuse risk.

If multiple packs match, compose them. The stricter requirement wins when packs disagree.

## Precedence

1. User instructions and explicit project rules.
2. Selected policy packs.
3. `references/engineering-constitution.md`.
4. Default Spec to Ship stage rules.

Do not load every pack by default. Use this index as the map and read only the matching pack files.

## Bundled Packs

| Pack | Default | Purpose |
|---|---:|---|
| `default-light.md` | yes | General adoption defaults for low-friction use. |
| `strict-team.md` | no | Stronger gates for real team production work. |
| `frontend-prototype.md` | no | Prototype and user-facing UI fidelity rules. |
| `backend-api.md` | no | API compatibility, examples, and contract evidence. |
| `database-change.md` | no | Migration, rollback, and data-safety expectations. |
| `security-sensitive.md` | no | Security, privacy, permissions, and sensitive data review. |

## Recording Selection

When a change uses packs, record them in the change state when practical:

```yaml
policy_packs: default-light,backend-api,security-sensitive
```

If state support is unavailable, record selected packs in `design.md` under policy assumptions and in `verify.md` under review evidence.

## Skip Policy

A stricter pack can be skipped only when the user explicitly accepts the risk or the trigger does not apply after clarification. Record skipped packs and the reason in `verify.md`.
