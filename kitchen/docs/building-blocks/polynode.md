# Building Blocks — PolyNode

Everything exchanged.

---

## What is exchanged?

Every Matryoshka design starts with one question: **who owns this item right now?**

Not what data it holds, not which thread touches it — just who owns it.

Ownership must be visible at the call site. If you need to read the implementation to
know who owns an item, the design is wrong.

```text
Slot (holds a handle)            Empty Slot

+-------------------+            +-------------------+
|                   |            |                   |
|      Handle       |            |       empty       |
|                   |            |                   |
+-------------------+            +-------------------+
```

## PolyNode — the ownership atom

`PolyNode` is a small marker every exchangeable object carries.

- Every user type embeds one `PolyNode`.
- Matryoshka never sees the user type — only the `PolyNode` inside it.
- The `PolyNode` is what lets Matryoshka move the object, without knowing what it is.

```text
User object                      Infrastructure sees
+------------------+
|      Event       |             a handle to the
|------------------|      →      embedded PolyNode
| PolyNode         |             — nothing else
| code: i32        |
+------------------+
```

## Handle — a pointer to the marker

A handle is what Matryoshka actually moves: a pointer to the embedded `PolyNode`, never
the object itself.

- One handle, one object.
- Specialized names exist for handles to specific infrastructure objects — a mailbox
  handle, a pool handle — but they are all the same kind of pointer underneath.

## Slot — where a handle lives while it's yours

A Slot is a place that either holds a handle or is empty.

- An item has exactly one owner at any moment.
- Owners: user code (in flight), a mailbox (held), a pool (held).
- When ownership transfers, the slot becomes empty — that's the proof the transfer
  happened, not just bookkeeping.

## Why this matters

Given a handle, you can identify the object it came from and cast back to it:

- without interfaces
- without virtual dispatch
- with one runtime check (a tag comparison), not a chain of them

That is the whole ownership atom. Everything else in Matryoshka — Mailbox, Pool,
Master — moves handles like this one, never the objects directly.

---

Next: [Mailbox](mailbox.md) — how a handle moves from one owner to another.

See also: [API Reference — PolyNode, ItemHandle, Slot](../api/polynode.md) for the actual
Zig types and functions.
