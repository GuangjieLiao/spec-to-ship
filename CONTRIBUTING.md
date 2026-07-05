# Contributing

Spec to Ship is intended to evolve through real project trials.

## Good Contributions

- clearer workflow instructions;
- better guard checks;
- real examples from safe, non-sensitive projects;
- OpenSpec schema compatibility fixes;
- production readiness improvements;
- documentation that helps teams understand tradeoffs.

## Development

Run validation before submitting changes:

```bash
bash scripts/validate.sh
```

Keep `SKILL.md` concise. Put detailed guidance in `skill/spec-to-ship/references/`.

## Design Rule

If a rule is mechanical and repeatable, prefer a script.

If a rule requires engineering judgment, document it in the skill or references.
