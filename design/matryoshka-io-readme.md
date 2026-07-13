# Matryoshka-Io

*A practical way for building concurrent software systems with Zig Io.*

---

# First rule

> If you want to build a great software system,
> start by building a software system.

---

# Intent

We know how to write Zig libraries.

We are still learning how to build Zig systems.

Zig Io gives us an excellent foundation for concurrent execution.

Matryoshka provides a simple architecture for organizing that execution.

It does not replace Io.

It gives Io tasks a common language and a repeatable structure.

---

# Design foundation

Matryoshka is based on a simple concurrency principle.

> **Share by communicating.**

Instead of sharing application objects,
communicate the application objects themselves.

An Item moves from one Master to another.

The Item is never intended to be used simultaneously by multiple Masters.

This follows the principle described by Bryan C. Mills:

> **Share the thing by communicating the thing.**

The same idea applies to reusable resources.

Resource limits are resources too.

---

# Main concept

Zig creates concurrent tasks through `io.concurrent()`.

Matryoshka introduces one architectural concept:

## Master

A **Master** is an Io task that follows the Matryoshka rules.

Every Master is created by `io.concurrent()`.

Not every Io task is a Master.

A Master typically:

- performs one responsibility
- maintains application state
- creates and processes Items
- communicates through Mailboxes
- reuses Items through Pools

Some Masters coordinate other Masters.

A worker is simply a Master with one dedicated responsibility.

Matryoshka is therefore not another runtime.

It is a way to organize Io tasks.

---

# Four architectural building blocks

Every Matryoshka system is built from only four concepts.

```
Master
Item
Mailbox
Pool
```

Everything else is implementation.

---

# Item

An **Item** is an application object participating in a Matryoshka system.

Examples include:

- Request
- Response
- Connection
- Session
- Buffer
- Timer
- Job

Items are allocated.

They usually live much longer than the function that created them.

Items may:

- move between Masters
- wait inside Mailboxes
- be reused through Pools
- participate in intrusive containers

The fundamental rule is simple.

> **An Item is in exactly one place at any moment.**

Matryoshka deliberately encourages moving Items instead of sharing them.


## Item and ItemHandle

The documentation talks about **Items**.

The API uses **ItemHandle**.

Think about a file.

You say:

- create a file
- open a file
- close a file

The API actually works with a file handle.

Matryoshka is similar.

Logically, Masters communicate **Items**.

In code, they pass **ItemHandles**.

In most places, you can simply read **Item** as **ItemHandle**.


---

# Mailbox

A **Mailbox** communicates Items between Masters.

A Master places an Item into a Mailbox.

Another Master later receives that Item.

Mailboxes communicate Items.

Nothing more.

---

# Pool

A **Pool** stores reusable Items.

Instead of destroying an Item after use,
it can be returned to a Pool.

Another Master may later reuse that Item.

Pools communicate reusable resources.

---

# The programming model

Matryoshka encourages one style of concurrent programming.

Do not share Items.

Pass Items.

Reuse Items.

Communication is the default.

Sharing is the exception.

---

# The role of Zig Io

Io provides concurrent execution.

Matryoshka provides architectural structure.

Io answers:

> How do tasks run?

Matryoshka answers:

> How do tasks cooperate?

Io still provides everything it was designed for.

- concurrent tasks
- waiting on multiple event sources
- timers
- cancellation
- integration with other Io-based libraries

Matryoshka simply gives those tasks a common architecture.

---

# Why Matryoshka?

Real software systems have the same recurring problems.

Application objects must be:

- created
- processed
- transferred
- reused
- eventually destroyed

Most code bases solve these problems differently.

Matryoshka provides one simple, repeatable model.

It consists of only four concepts.

```
Master

Item

Mailbox

Pool
```

Small enough to understand.

Powerful enough to build systems.

---

# How it works

The architectural concepts above are implemented using a small number of internal building blocks.

Most users do not need to think about them.

## PolyNode

Every Item embeds a `PolyNode`.

`PolyNode` is an implementation mechanism.

It makes the architecture possible by providing:

- intrusive containers
- runtime type identification
- type-erased communication

This approach uses composition because Zig has no inheritance or base classes.

Application code works with Items.

Matryoshka internally works with the embedded `PolyNode`.

---

# Adoption

There is no big-bang migration.

Start with Items.

Introduce Pools when reuse becomes useful.

Introduce Mailboxes when communication becomes useful.

Organize long-running Io tasks as Masters.

Each step provides immediate value.

Each step remains useful after the next one.

---

# Philosophy

Matryoshka is intentionally small.

It does not introduce:

- a framework
- a runtime
- interfaces
- inheritance
- virtual dispatch

It introduces a small architectural vocabulary.

```
Master

Item

Mailbox

Pool
```

Everything else exists to support these four concepts.

---

# Be Master of your systems.
````
