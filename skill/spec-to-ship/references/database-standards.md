# Database Standards v0.1

Read when the change touches schema, migrations, persistence, queries, or data backfills.

## Checklist

- Describe schema change and data migration path.
- Include rollback or forward-fix strategy.
- Avoid destructive migrations unless explicitly approved.
- Consider index impact and query performance.
- Keep application code compatible during rollout when deployments are staged.
- Add tests or verification queries for critical data behavior.

## Release Notes

`release.md` must mention migration ordering, expected duration, and data-risk level.
