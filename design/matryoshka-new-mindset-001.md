# The New Matryoshka

## Why this document exists

Zig added `io.concurrent()`.

- That changes how Matryoshka should be understood.
- This document is the new source of truth for that understanding.
- Downstream docs get rewritten from this document, in later stages.
  - README
  - Manifesto
  - Patterns
  - Rules
  - API reference
- Not rewritten in this document. Rewrite happens later.

---

## The old understanding

Matryoshka sat beside Io.

```text
Application
    |
Matryoshka
    |
Io
    |
OS
```

- Master was described as a role.
  - Independent of any specific Io mechanism.

---

## The new understanding

Io creates tasks.

Matryoshka lives inside that task world, not beside it.

```text
Application
    |
Io tasks
    |
    +-- ordinary task
    +-- ordinary task
    +-- matryoshka task
    |
Io
    |
OS
```

- `io.concurrent()` is the only way a task starts.
- A matryoshka task is still just a task.
  - It uses internally:
    - Mailboxes
    - Pools
    - PolyNodes
  - Called a '_Master_'. Defined next.
- Io answers:
  - how do tasks run?
- Matryoshka answers:
  - how do tasks cooperate?

---

## A Master is a task

- A Master is not a separate kind of thing next to a task.
- A Master is an Io task that follows the Matryoshka rules.
  - Created by `io.concurrent()`.

A task becomes a Master when it:

- owns application state
- owns one or more Mailboxes
- owns one or more Pools
- exchanges PolyNode-based items instead of sharing them

- Not every task is a Master.
- Every Master is a task.

---

## `std.Thread.spawn` is banned

- Matryoshka code, examples, tests, and stories create tasks one way:
  - `io.concurrent()`.
- `std.Thread.spawn` must not appear anywhere in this codebase.
- Today it is already absent from `src/`.
- It still appears in some `examples/` and `tests/` files.
  - Those need to move to `io.concurrent()`.
  - That migration is tracked as follow-up work, not part of this document.

---

## Matryoshka in the mess of mighty Io

- Io is large.
- Io does a lot.
- Io is easy to get lost in.
- Matryoshka is small on purpose:
  - a handful of rules
  - a few hundred lines of code

It declares a simple starting point inside that complexity:

- exchange items through Mailboxes
- reuse items through Pools
- identify items through PolyNode

- Matryoshka does not replace Io.
- It does not hide Io.
- It gives a task-based system a simple, repeatable shape.
  - The shape helps build a large, well-formed Zig system.
  - No need to invent that shape from scratch each time.

---

## Minimal dependency, unchanged

Matryoshka depends on two Io primitives:

- `Io.Mutex`
- `Io.Condition`

- Nothing else from Io is required to build the troika:
  - PolyNode
  - Mailbox
  - Pool
- Io may grow new schedulers, executors, or task styles.
  - Matryoshka does not need to change.
- It only needs:
  - `io.concurrent()` to create tasks
  - the two primitives above to coordinate them

---

## Not a framework

- Matryoshka does not own the application.
- Matryoshka does not provide a runtime. Io already does.
- Matryoshka does not replace `io.concurrent()`. It uses it.
- Matryoshka is a small set of rules.
  - Rules for what a task does once Io has created it.
- The troika — PolyNode, Mailbox, Pool — is a few hundred lines of code.
  - Small enough to read in one sitting.

---

## What this changes in the documentation

These pages describe Master as a role, independent of `io.concurrent()`.
Each needs a second look:

- README
  - "Master is a role" language needs to connect to `io.concurrent()`
    explicitly.
- Manifesto
  - Same connection.
  - The old "Matryoshka beside Io" diagram needs the task-world diagram
    from this document.
- Patterns and rules
  - Any pattern built on `std.Thread.spawn` needs a matching
    `io.concurrent()` pattern.
- API reference
  - Master-related sections need the task connection stated up front.
  - Not left implicit.

- This document does not rewrite those pages.
  - It is the reference the audit and rewrite stages work from.

---

## Summary

- Io creates tasks through `io.concurrent()`.
- A Master is a task that adopts the Matryoshka rules:
  - own state
  - use Mailboxes
  - use Pools
  - exchange PolyNode-based items
- Matryoshka is not beside Io.
  - It is a small, stable layer of rules and code.
  - It lives inside the Io task world.
  - A simple way to start building a large Zig system.
  - Out of Io's complexity.
