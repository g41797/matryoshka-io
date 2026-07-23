# What is Matryoshka-Tk?

Matryoshka-Tk (or simply **Matryoshka**) is a practical way to build concurrent software systems with Zig Io.

It is not:

- a framework
- a runtime
- another event loop

It is a small architectural model.

It helps you organize concurrent tasks and the application objects they process.

---

# The idea

Every concurrent system has application objects.

Requests.

Connections.

Jobs.

Sessions.

Buffers.

Timers.

Those objects are created.

Processed.

Transferred.

Reused.

Eventually destroyed.

Matryoshka gives all of them one common lifecycle.

---

# Four concepts

Everything is built from only four concepts.

```
Master
Item
Mailbox
Pool
```

## Master

A Master is an Io task.

It owns one responsibility.

It owns application state.

It processes Items.

## Item

An Item is an application object.

It moves between Masters.

An Item is always owned by exactly one Master, one Mailbox, or one Pool.

Never by several at the same time.

## Mailbox

A Mailbox transfers Items between Masters.

Communication transfers ownership.

Not shared access.

## Pool

A Pool stores reusable Items.

Instead of destroying an Item, return it to the Pool.

Another Master can reuse it later.

---

# The programming model

Matryoshka follows one simple rule.

> Share by communicating.

Instead of sharing application objects, communicate the application objects themselves.

Move Items.

Do not share Items.

Reuse Items whenever possible.

---

# Why?

Concurrent programming becomes difficult when ownership is unclear.

Who owns this object?

Who may modify it?

Who destroys it?

Can another task use it now?

Matryoshka answers these questions with simple architectural rules instead of conventions.

---

# Think about architecture first

Start with a whiteboard.

Draw the Masters.

Draw the Items.

Draw how the Items move.

Then write the code.

As the system grows:

- add more Masters
- add more Mailboxes
- add more Pools

Do not change the way of thinking.

Keep the architecture simple.

---

# The role of Zig Io

Zig Io provides concurrent execution.

Matryoshka provides architectural structure.

Io answers:

> How do tasks run?

Matryoshka answers:

> How do tasks cooperate?

Together they provide a practical way to build concurrent software systems.

