# Production Readiness v0.1

Use for any change that may be merged, deployed, or affect production behavior.

## Required Questions

- What can break?
- How do we know it broke?
- How do we roll back or forward-fix?
- Does deployment require ordering?
- Does the change need feature flags or gradual rollout?
- Does it affect data, permissions, billing, integrations, or external clients?

## Risk Levels

- Low: local behavior, no data/API/security impact, easy rollback.
- Medium: user-visible behavior or internal API, tested rollback path.
- High: data migration, permission/security, payment, public API, broad platform behavior.

High-risk changes require explicit user confirmation before archive.
