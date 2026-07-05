# Phase Guard v0.1

Use this to avoid phase drift in long AI sessions.

## Rules

- Do not edit source code in `open` or `design` except for explicit exploration requested by the user.
- Do not enter `build` without confirmed requirements and design, except `tweak` or focused `hotfix`.
- Do not enter `verify` while `tasks.md` has unchecked tasks.
- Do not enter `release-ready` without verification evidence.
- Do not archive without user confirmation.
- Never directly set `phase`; use guard `--apply` or `spec-to-ship-state.sh transition`.

## Recovery

If you are unsure where you are:

```bash
bash <skill-dir>/scripts/spec-to-ship-state.sh get <change-dir>
bash <skill-dir>/scripts/spec-to-ship-state.sh next <change-dir>
```

Then read the checkpoint and context pack described in `references/context-management.md`.
