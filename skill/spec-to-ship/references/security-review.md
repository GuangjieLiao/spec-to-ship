# Security Review v0.1

Read when the change touches auth, permissions, user data, payments, files, secrets, network access, serialization, or admin behavior.

## Checklist

- Authentication: who can access this?
- Authorization: what can they do?
- Data exposure: what sensitive data is returned, logged, cached, or exported?
- Input handling: validation, injection, path traversal, SSRF, deserialization.
- Secrets: no hardcoded secrets, tokens, or credentials.
- Auditability: important privileged actions are traceable.

Critical security uncertainty blocks release-ready until resolved or explicitly accepted by the user.
