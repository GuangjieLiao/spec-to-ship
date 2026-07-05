# Spec Writing v0.1

Write specs for agent execution and human review, not for decoration.

## proposal.md

Required sections:

- Problem
- Goal
- Non-goals
- Scope
- Risks and unknowns
- Acceptance scenarios

## spec.md

Use concrete behavior rules.

For each behavior:

```markdown
### Requirement: <capability>

The system shall <observable behavior>.

#### Scenario: <name>
- Given <state>
- When <action>
- Then <observable result>
```

## design.md

Required sections:

- Chosen approach
- Alternatives considered
- Module/file impact
- Data/API/security impact
- Test strategy
- Rollback or mitigation notes

## tasks.md

Each task must be independently checkable:

```markdown
- [ ] <task>
  - Evidence: <test/build/manual check>
```

## verify.md

Do not write "verified" without evidence. Include command, result, and any skipped check reason.

## release.md

For production-impacting changes, include rollout, rollback, monitoring, and migration impact.
