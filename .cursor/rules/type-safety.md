# Type Safety & Error Modeling

## Rules

- No force unwraps, no `try!`, no implicitly unwrapped optionals.
- Every error uses a dedicated enum/struct; Error types should live in Errors/.
- Avoid [Any], AnyObject, or unchecked type erasure.
- Public APIs require Swift doc comments ///.

