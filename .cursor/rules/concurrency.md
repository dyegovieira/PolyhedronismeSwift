# Swift 6.2 Concurrency Rules

## Strict Concurrency Requirements

- Use structured concurrency everywhere: async/await, actors, isolated state.
- Avoid DetachedTask; prefer Task(priority:) usage.
- All cross-actor types must conform to Sendable.
- No @unchecked Sendable except test mocks created externally.

