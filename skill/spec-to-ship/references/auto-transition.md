# Auto Transition v0.1

`auto_transition` controls whether the workflow automatically continues after a guard advances the phase.

- `true`: after guard `--apply`, continue to the next stage unless a user decision point is reached.
- `false`: after guard `--apply`, stop and tell the user the next command/stage.

Run:

```bash
bash <skill-dir>/scripts/spec-to-ship-state.sh next <change-dir>
```

The output is:

```text
NEXT: auto|manual|done
SKILL: spec-to-ship <stage>
HINT: ...
```

Decision points always block, even when `auto_transition: true`.
