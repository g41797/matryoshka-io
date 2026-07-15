# Matryoshka-Io

*A practical way to build concurrent software systems with Zig Io.*

---

## First rule

> If you want to build a great software system,
> start by building a software system.

We know how to write Zig libraries.

We are still learning how to build Zig systems.

---

## The problem

Zig Io answers one question well: **when does work run?**

It does not answer the questions that decide whether a system holds together:

- Where are the boundaries?
- Which part holds which state?
- How do parts talk to each other?
- Who controls a shared resource?
- How do the parts combine into a system?

Without answers, concurrent code drifts.

Nobody knows what runs in parallel.

Parts depend on each other in hidden ways.

The structure just happens — nobody chose it.

Io does not prevent any of that. It runs it faster.

Matryoshka's promise is to make building Zig systems a little more **boring**.

Not slow. Not old. Just predictable — easy to understand, easy to change, easy to keep running.

---

## Not another runtime

Matryoshka is not another runtime.

It is a way to organize Io tasks.

Zig Io gives you an excellent foundation for concurrent execution.

Matryoshka gives that execution a common language and a repeatable shape.

- Io answers: **How do tasks run?**
- Matryoshka answers: **How do tasks cooperate?**

It does not replace Io. It uses it.

---

## Design foundation

Matryoshka is built around one concurrency principle:

> **Share by communicating.**

Instead of sharing access to an application object, pass the object itself.

The object moves from one Master to another.

At any moment, it is in exactly one place.

This follows the principle described by Bryan C. Mills:

> Share the thing by communicating the thing.

The same idea applies to reusable resources.

Resource limits are resources too.

---

## Four concepts

Every Matryoshka system is built from only four concepts.

- **Master** — execution
- **Item** — state
- **Mailbox** — communication
- **Pool** — resource reuse

Everything else is implementation.

### Master

Zig creates concurrent tasks through `io.concurrent()`.

A **Master** is an Io task that follows the Matryoshka rules.

Every Master is created by `io.concurrent()`.

Not every Io task is a Master.

A Master typically performs one responsibility, holds its own state, and works with Items.

Some Masters coordinate other Masters.

A worker is simply a Master with one dedicated responsibility.

### Item

An **Item** is a movable application object — a Request, a Connection, a Session, a Buffer, a Job, a Timer.

Items are allocated.

They are designed to outlive the function that created them.

The one rule that matters:

> An Item is in exactly one place at any moment.

A Master uses it, or a Mailbox holds it, or a Pool holds it. Never several at once.

**Item and ItemHandle.** The documentation talks about Items. The API works with an **ItemHandle** — the same way a file API works with a file handle even though you think in terms of "create a file, open a file, close a file." In most places you can simply read Item as ItemHandle.

### Mailbox

A **Mailbox** moves an Item from one Master to another.

One Master places an Item in. Another Master later receives it.

It transfers the Item — not a copy, not a reference. Nothing more.

### Pool

A **Pool** holds reusable Items.

Instead of destroying an Item after use, a Master may return it to a Pool for another Master to reuse.

A Pool is not storage. An empty Pool is a signal, not an error — it is backpressure, and it costs no extra code to get.

---

## The programming model

Matryoshka encourages one style.

Do not share Items.

Pass Items.

Reuse Items.

Communication is the default.

Sharing is the exception.

---

## What this is not

Matryoshka is intentionally small. It does not introduce:

- a framework
- a runtime
- interfaces
- inheritance
- virtual dispatch

It does not think for you. You still design the system. You still solve the hard problems.

It simply brings a little more order to your thinking.

One implementation detail, mentioned once and then left alone: every Item embeds a `PolyNode`, which is how a type-erased Item moves safely without base classes or virtual dispatch. You rarely need to think about it. The building-blocks docs cover it when you do.

---

## Start without fear

There is no big-bang migration.

Start with Items.

Add a Pool when reuse becomes useful.

Add a Mailbox when communication becomes useful.

Organize long-running Io tasks as Masters.

Each step is useful right away.

Each step stays useful after the next one.

A simple question: can you describe your application using only Masters, Mailboxes, and Pools? If yes, you are already thinking in Matryoshka.

---

**Be Master of your systems.**
