# Matryoshka-Io

*A practical way to build concurrent software systems with Zig Io.*

---
## First rule

> If you want to build a great software system,
> start by building a software system.

We know how to write Zig libraries.  

We are still learning how to build Zig systems.  

Especially after the introduction of `std.Io`.  

---

## Promise

*They say,*

> "Give someone a fish, and you feed them for a day.    
> Teach them to fish, and you feed them for a lifetime."

I can't teach you to fish.  

But I can give you a fishing rod.  

**Matryoshka-Io is that *fishing rod* for *building software systems*.**

---

## The problem

Zig Io gives you excellent tools:

- Tasks.
- Groups.
- Futures.
- Synchronization.
- Cancellation.
- Concurrency.
- Async...
- And much more.

There are many ways to combine them.  

Matryoshka-Io takes a different approach.  

It removes choices:

- a small subset of Io
- a few building blocks
- a few rules
- clear communication
- manageable resource reuse

The hard problems do not disappear.  

But they become easier to discuss.  

Because the system becomes **_visible_**.  


---

## Four building blocks. One principle. Common language.

Every Matryoshka system is built from four building blocks:  

- **Master** — execution
- **Item** — state
- **Mailbox** — communication
- **Pool** — resource reuse

They all follow one principle:

> **Share by communicating.**

You stop talking about: 

- tasks
- futures
- mutexes
- queues

You start talking about: 

- Masters
- Items
- Mailboxes
- Pools

### Master

A **Master** is 

- an _Threaded_ Io task
- created by `_concurrent()_`
- follows the Matryoshka rules
- holds its own state
- works with Items
- communicate with another Masters and/or application



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

A Pool is not storage. An empty Pool is a signal, not an error — it is backpressure. Backpressure appears naturally.

---

## One style

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

One implementation detail, mentioned once and then left alone: every Item embeds a `PolyNode`. That is how a type-erased Item moves safely without base classes or virtual dispatch. You rarely need to think about it. The building-blocks docs cover it when you do.

---

## The library

The repository provides small building blocks.

- Item
- Mailbox
- Pool

They are independent.

Use one.

Use all three.

Or build your own.

The concepts matter more than the implementation.

---

## Start without fear

There is no big-bang migration.

Start with Items.

Add a Pool when reuse becomes useful.

Add a Mailbox when communication becomes useful.

Organize long-running Io tasks as Masters.

Each step is useful right away.

Each step stays useful after the next one.

A simple question: can you describe your application using only Masters, Mailboxes, and Pools?

If yes, you are already thinking in Matryoshka.

---

**Be Master of your systems.**
