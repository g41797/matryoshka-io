# Building Blocks — Master

Everything runs inside one.

---

## A Master is an Io task

- Io creates tasks through `io.concurrent()`.
- A Master is an Io task that follows the Matryoshka rules.
- Not a special runtime object.

Master is **not**:

- a type
- an interface
- a runtime

> A Master runs on its own, as an Io task.
> It owns its state.
> It talks through Mailboxes.

```text
Io tasks
    │
    ├── ordinary task
    ├── ordinary task
    └── Master
             │
    ┌────────┼────────┐
    │        │         │
Single-job Coordinator Resource owner
 Master      Master       Master
```

- Some Masters do one job. A *worker* is simply a Master with one job.
- Some Masters coordinate other Masters.
- Some Masters own shared resources — a Pool, a shared Mailbox.

There is no required Master struct, and no required interface.

- The responsibility defines a Master, not a particular shape of code.

## Two tiers of structure

- **Flat** — one loop, one action per step, all state fits in local variables, short
  lifecycle. A plain function is enough.

- **Coordinator** — multiple phases with shared state between them, a distinct
  startup / work / shutdown lifecycle. Worth its own struct once a flat function
  would get hard to follow.

Both are Masters. The difference is how much structure the job needs, not a
different concept.

## Cancel and close are different signals

A Master tells these apart:

- **Cancel** — the scheduler says stop waiting right now. An external signal. A
  Master that gets it reports the fact; it decides what happens next.

- **Close** — the Master itself says this Mailbox or Pool is shutting down. That's a
  deliberate decision, not something imposed from outside.

Cancel never triggers close on its own — they answer different questions.

## Why Master is not in the API

There is no `Master` type to import.

- The task comes from `io.concurrent()`.
- Transport comes from Mailbox.
- Reuse comes from Pool.
- Identity comes from PolyNode.
- Everything else — startup order, shutdown order, cancellation policy, how many
  workers, what they coordinate — is the application's own design, expressed by
  composing the three building blocks.

That's the whole point: a Master is whatever shape your problem needs, built from
three small, fixed pieces.

---

Next: [API Reference](../api/polynode.md) — the actual Zig types and functions behind
PolyNode, Mailbox, and Pool.

<!-- Temporarily hidden — Story section commented out of mkdocs.yml nav.
See also: [Story — Print Server](../story/print-server/discussion.md) for these four
concepts working together in a real system. -->

