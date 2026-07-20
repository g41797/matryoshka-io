# Matryoshka-Io — the full picture

*A practical way to build concurrent software systems with Zig Io.*

We know how to write Zig libraries.

We are still learning how to build Zig systems.

This page is the longer story.

- The problem Matryoshka addresses.
- The one idea it is built on.
- How that idea plays out in real code.
- What it deliberately is not.

---

## The problem

Zig Io answers one question well: **when does work run?**

It does not answer:

- Where are the system boundaries?
- Which part holds which state?
- How do parts talk to each other?
- Who controls a shared resource?
- How do the parts combine into a system?

Without answers, async systems drift:

- nobody knows which code runs in parallel
- parts depend on each other in hidden ways
- the structure just happens — nobody chose it

Io does not prevent any of that.

It simply runs it faster.

The goal here is not maximum abstraction. It is not maximum performance.

The goal is reducing ambiguity — making a system predictable, easy to understand, easy to change, easy to keep running.

That is what "boring" means. Matryoshka's promise is to make building Zig systems a little more boring.

---

## One constraint

Matryoshka asks you to accept one constraint.

> Everything is a Master communicating via Mailboxes.

Pools extend the same idea.

> Shared resources are explicit and controlled.

In return:

- you always know which part holds what
- parts talk in one way only: messages
- you know what runs in parallel
- you can swap one Master for another
- you can understand one Master without reading the whole system

The constraint itself comes from a well-known concurrency principle, described by Bryan C. Mills:

> **Share by communicating.** Share the thing by communicating the thing.

Instead of sharing access to an application object, pass the object itself. The object moves from one place to another. At any moment, it is in exactly one place.

The same idea covers reusable resources — because resource limits are resources too.

---

## Item — what moves

An **Item** is a movable application object.

Examples: Request, Response, Connection, Session, Buffer, Timer, Job.

Items are allocated.

They are designed to outlive the function that created them.

They are passed.

They are reused.

Eventually, they are destroyed.

The rule that holds the whole model together:

> An Item is in exactly one place at any moment.

One Master uses an Item, or one Mailbox holds it, or one Pool holds it. Never several places at once.

That single rule removes an entire category of shared-state problems — no "who is modifying this?", no accidental races, no lifetime puzzles.

**Item and ItemHandle.** The architecture talks about Items. The API works with an **ItemHandle**. It is the same relationship a file API has with a file handle: you think "create a file, open a file, close a file," and the code passes a handle. In most places you can simply read Item as ItemHandle.

Matryoshka's model is closer to passing a parcel from hand to hand than to a shared object graph everyone can see at once.

---

## Master — where work happens

Zig creates concurrent tasks through `io.concurrent()`.

A **Master** is an Io task that follows the Matryoshka rules.

- Every Master is created by `io.concurrent()`.
- Not every Io task is a Master. Every Master is a task.

A Master is **not** a type, an interface, or a runtime.

It is a task.

It holds its own state.

It works with Items.

It talks through Mailboxes.

```text
io.concurrent()
        │
        V
     Io task
        │
follows Matryoshka rules
        │
        V
     Master
```

- Some Masters do one job. A worker is simply a Master with one job.
- Some Masters coordinate other Masters.
- Some Masters hold shared resources.

A Master is whatever shape your problem needs, built from a few small, fixed pieces.

---

## Mailbox and Pool — the other two pieces

A **Mailbox** moves an Item from one Master to another.

It transfers the Item itself — not a copy, not a reference. The original moves. A Mailbox is not really a queue. A queue stores values; a Mailbox moves the object that already exists from one holder to the next.

Receiving the Item *is* the notification. There is no separate "data ready" signal to forget or race.

A **Pool** holds reusable Items.

A Pool is not storage. An empty Pool is a signal, not an error.

**Waiting on an empty Pool is backpressure.** It appears naturally. Reuse and backpressure come from the same mechanism: a fixed number of slots. The constraint is structural. Nobody has to remember to check capacity.

---

## How Io fits

Matryoshka and Io solve different problems.

- Matryoshka answers: what is my system made of?
- Io answers: when does my code run?

The bridge between them is one idea:

> Everything that happens in the system becomes a message in a Master's mailbox.

A timer expired. A socket became readable. A background job finished. Another Master sent a job.

Inside the system, all of these are the same thing: a message in a mailbox.

The component that connects Io to the system is just another Master — it waits on Io events and turns them into ordinary messages. So for application developers, Io stays out of the way:

> A good design test: if you have to mention Io while designing your system, it is already too visible.

Keep Io capable. Keep it hidden. Keep Matryoshka clean.

And because Matryoshka needs only `Io.Mutex` and `Io.Condition`, if Zig Io changes tomorrow — and it will — Matryoshka's rules stay the same.

---

## How it plays out

There is no big-bang migration. The layers are nested dolls: open the next one only when the current one starts to hurt.

- **Start with Items.** Model your application objects. Give each one a clear place.
- **Add a Pool** when allocating and destroying the same kind of object becomes painful enough to justify reuse.
- **Add a Mailbox** when parts need to hand work to each other.
- **Organize long-running Io tasks as Masters** when coordination becomes the hard part.

Each step is useful right away. Each step stays useful after the next one.

A worked example makes this concrete. Picture a print server: a client, a spooler, a printer driver.

- The client submits, moves on, and waits for a result on its own channel — an application should never block on a slow printer.
- The job moves in a straight line: client → spooler → driver. Whoever holds the job holds the problem.
- The driver needs no locks while printing. It is the only holder. Either it finishes and sends the result, or it fails and sends the result.

No shared status table. No polling. Responsibility follows location.

---

## What this is not

Matryoshka is intentionally small. It is deliberately **not**:

- **a framework** — it does not take over your application.
- **a runtime** — Io already provides one. Matryoshka does not replace `io.concurrent()`. It uses it.
- **an actor or messaging framework** — the four concepts are building blocks, not a fixed topology you must adopt whole.
- **a scheduler or event loop** — that is Io's job. The `std.Io` box has not moved. Matryoshka uses it. Matryoshka does not replace it.
- **interfaces, inheritance, or virtual dispatch** — Items participate through composition, because Zig has no base classes.

The goal is not an easy system.  
It never was.

The goal is a system with:

- a common frame
- common rules
- a common way of thinking

That makes the system:

- easier to explain
- easier to discuss
- easier to draw on a whiteboard
- easier to change
- easier to maintain

Matryoshka does not think for you.  
You still design the system.  
You still solve the hard problems.  

It simply brings a *little more order* to your thinking.

It introduces a small architectural vocabulary — Master, Item, Mailbox, Pool — and nothing else that you have to learn before you can start.

The concepts matter more than the implementation.

---

## Where to start

Start from a whiteboard.

Draw the Masters. Draw the Items. Draw how they move.

Not from code. Not from a prompt.

Then ask one question: can you describe your application using only Masters, Mailboxes, and Pools?

If the answer is yes, you are already thinking in Matryoshka.

**Be Master of your systems.**

- [The repository →](https://github.com/g41797/matryoshka-io)
