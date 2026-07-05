# OpenSpec Schema v0.1

The workflow can run without a custom OpenSpec schema. The fallback Markdown artifacts are enough for trial runs.

Use the optional schema when the team wants OpenSpec itself to know about the extra `verify` and `release` artifacts.

Install the starter schema:

```bash
bash <skill-dir>/scripts/install-openspec-schema.sh <repo-root>
```

This copies:

```text
assets/openspec-schema/spec-to-ship/schema.yaml
```

to:

```text
openspec/schemas/spec-to-ship/schema.yaml
```

After installing, configure OpenSpec according to the OpenSpec version used by the project. If the CLI rejects the schema, keep using fallback artifacts and adjust the schema after checking the project's `openspec` schema format.

## Why Optional

Custom schema is useful for team standardization, but it is not required to validate this workflow. Add it after trial changes prove the artifact set is stable.
