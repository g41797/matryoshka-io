# Matryoshka-Io

## First rule of building great software systems

> If you want to build a great software system, start by building a software system.

---

## Intent

We know how to write Zig libraries.

We are still learning how to build Zig systems.

Zig Io makes developers' lives even more interesting.

Matryoshka is an attempt to make them a little more ***boring***.

---

## Main concept

Zig creates tasks through `io.concurrent()`.

Matryoshka introduces one main concept: **Master**.

* A Master is an Io task.
* Created by `io.concurrent()`.
* Follows the Matryoshka rules.

Master is **not**:

* a type
* an interface
* a runtime

A task becomes a Master when it:

* typically has a long lifetime
* owns application state
* owns Matryoshka building blocks

Some Masters also:

* coordinate other Masters
* own shared resources

A *worker* is simply a Master with a single dedicated responsibility.

* Not every task is a Master.
* Every Master is a task.

---

## Matryoshka-based system

A Matryoshka-based system is built from Masters.

Masters:

* own state
* communicate through Mailboxes
* share reusable objects through Pools

Matryoshka does not dictate the implementation.

---

## Three small building blocks

A Master uses only three small building blocks.

### PolyNode

`PolyNode` is the bigger brother of Zig's intrusive `Node`.

Like `Node`, it is:

* embedded into application objects
* suitable for:

  * intrusive lists
  * intrusive queues
  * other intrusive containers

In addition, it:

* provides simple run-time type identification

Given a `PolyNode`, you can:

* safely identify the containing object
* without interfaces
* without virtual dispatch

### Mailbox

`Mailbox`:

* transfers `PolyNode` objects between Masters
* transfers the object, not a reference to it
* does not know or care about the concrete object type

### Pool

`Pool`:

* reuses `PolyNode`-based objects
* does not know or care about the concrete object type
* returns objects for reuse instead of destroying them

### Together

Just three small building blocks.

> Together, this troika allows you to:
>
> * transfer objects
> * reuse objects
> * stay type-agnostic

Exactly what the doctor ordered.

### Containers on steroids

If it's still hard to grasp, think of them this way.

`PolyNode` is the bigger brother of Zig's intrusive `Node`.

`Mailbox` and `Pool` are containers on steroids.

The steroids are simple:

* intrusion
* type erasure
* object transfer
* object reuse

Nothing else.

* No interfaces.
* No framework.

---

## The role of Zig Io

Io creates every task through `io.concurrent()`.

Matryoshka lives inside that task world. Not beside it.

A Master is one of those tasks. It follows the Matryoshka rules.

Io still does the rest:

* waiting for multiple event sources
* timers
* cancellation
* integration with other Io-based libraries

Matryoshka does not compete with these.

* Io answers: how do tasks run?
* Matryoshka answers: how do tasks cooperate?

---

## Why Matryoshka-Io?

Io is large. Io does a lot.

Matryoshka is small on purpose:

* a handful of rules
* a few hundred lines of code

It gives your Io tasks a simple, repeatable shape.

* keeps the architecture simple
* one way to create a task: `io.concurrent()`
* one small set of rules for Masters to follow

Start building today.

If Zig Io changes tomorrow—and it will—Matryoshka's rules stay the same.

---

## Try Matryoshka without fear

There is no big-bang commitment.

Start your first Master with the simplest building block: `PolyNode`.

Add `Pool` when object reuse becomes useful.

Add `Mailbox` when you need message passing.

Or use your own type-erased queue.

It's up to you.

Each step provides immediate value.

Each step remains useful after the next one.

The whole troika is only 582 lines of code.

Don't be afraid.

Go ahead.

**Be Master of your systems.**
