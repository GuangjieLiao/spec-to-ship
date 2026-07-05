# API Standards v0.1

Read when the change adds, removes, or modifies an API.

## Checklist

- Document endpoint, method, request, response, and error behavior.
- Preserve backward compatibility unless explicitly approved.
- Validate input at the boundary.
- Return stable error codes/messages where clients rely on them.
- Consider authentication, authorization, rate limits, and audit logs.
- Add or update API tests for success and failure paths.

## Spec Notes

Include example request/response for externally visible APIs. For internal APIs, record callers and migration impact.
