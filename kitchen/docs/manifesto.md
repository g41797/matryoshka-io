# Matryoshka Manifesto

## First rule of building great software systems

> If you want to build a great software system, start by building a software system.

---

## The problem

We know how to write Zig libraries.

We are still learning how to build Zig systems.

Zig Io answers one question well: *when does work run?*

It does not answer:

* Where are the system boundaries?
* Who owns which state?
* How do parts talk to each other?
* Who controls shared resources?
* How do parts combine into a system?

Without answers, async systems drift:

* nobody knows which code runs in parallel
* parts depend on each other in hidden ways
* the structure just happens — nobody chose it

Io does not prevent any of that. It just runs it faster.

Matryoshka's promise: make building Zig systems a little more ***boring***.

---

## One constraint

Matryoshka asks you to accept one constraint.

> Everything is a Master communicating via Mailboxes.

Pools add a second one.

> Shared resources are explicit and controlled.

Two constraints. In return you get:

* you always know who owns what
* parts talk in one way only: messages
* you know what runs in parallel
* you can swap one Master for another
* you can understand one Master without reading the whole system

---

## Master is a role

Master is the main concept of Matryoshka.

Master is **not**:

* a type
* an interface
* a runtime

Master is a **role**.

> A Master runs on its own.
> It owns its state.
> It talks through mailboxes.

Everything that runs in Matryoshka is a Master:

```text
            Master (role)
                 │
      ┌──────────┼──────────┐
      │          │          │
 Single-role  Coordinator  Resource owner
    Master       Master        Master
```

* Some Masters do one job.
* Some Masters coordinate other Masters.
* Some Masters own shared resources.

A *worker* is simply a Master with one job.

Every part runs on its own. Some parts grow into coordinators.

That is how real systems are built.

---

## Down to earth

The whole model fits in a few lines.

* A Master has one input mailbox.
* A Master processes one message at a time.
* A Master may send a message to any mailbox.
* Including its own.
* Multiple Masters may share one mailbox.
* A Master may borrow objects from one or more pools.
* Pools may be shared by many Masters.
* Mailboxes and Pools may hold typed or type-erased objects.

Nothing else is required.

| Capability          | Primitive                  |
| ------------------- | --------------------------- |
| Receive             | Mailbox                    |
| Send                | Mailbox                    |
| Share communication | Shared Mailbox             |
| Borrow resources    | Pool                       |
| Share resources     | Shared Pool                |
| Heterogeneous data  | Type-erased Mailbox / Pool |

Everything else is a Master, or a composition of Masters:

* dispatchers
* routers
* schedulers
* timers
* services
* actors
* pipelines
* reactors

---

## Four fundamental concepts

```text
PolyNode
    Everything exchanged.

Mailbox
    Everything communicates.

Pool
    Everything reusable lives here.

Master
    Everything runs inside one.
```

Master is a role. The other three are code.

The one-line summary below is all this page gives you — see
[Building Blocks](building-blocks/index.md) for a full page per concept, still no Zig
syntax, and [API Reference](api/polynode.md) once you're ready to write code.

### PolyNode

`PolyNode` is the bigger brother of Zig's intrusive `Node`.

* embedded into application objects
* works in intrusive lists, queues, and other intrusive containers
* adds simple run-time type identification

Given a `PolyNode`, you can identify the containing object:

* without interfaces
* without virtual dispatch

### Mailbox

`Mailbox`:

* transfers `PolyNode` objects between Masters
* transfers ownership together with the object
* does not know or care about the concrete object type

### Pool

`Pool`:

* reuses `PolyNode`-based objects
* returns objects for reuse instead of destroying them
* does not know or care about the concrete object type

### Together

Just three small building blocks.

`Mailbox` and `Pool` are containers on steroids.

The steroids are simple:

* intrusion
* type erasure
* ownership transfer
* object reuse

Nothing else.

* No interfaces.
* No framework.

The whole troika is only 582 lines of code.

---

## Where Io fits

Matryoshka and Io solve different problems.

* Matryoshka answers: what is my system made of?
* Io answers: when does my code run?

The bridge between them is one idea:

> Everything that happens in the system becomes a message in a Master's mailbox.

A timer expired. A socket became readable. A background job finished. Another
Master sent a job.

Inside the system, all of these are the same thing: a message in a mailbox.

```text
           +----------------+
           |   Io runtime   |
           +----------------+
                  │
            wait for events
                  │
                  ▼
          +---------------+
          | Bridge        |
          | (a Master)    |
          +---------------+
                  │
             send message
                  │
                  ▼
             Master Mailbox
                  │
                  ▼
               Master
```

The bridge is just another Master. It waits on Io events and turns them into
ordinary messages.

So for application developers:

* Io is not a concept.
* You do not think about Io while designing.
* Io just moves messages behind Mailboxes. You never see it.

A good design test:

> If you have to mention Io while designing your system, it is already too visible.

Think about cars.

* A traditional threaded application is a conventional car.
* A pure Io-based application is an electric car.
* Matryoshka-Io is a hybrid.

Start building today.

If Zig Io changes tomorrow—and it will—your architecture stays the same.

See [Addendums — Io 101](addendums/io-101.md) for a deeper primer on Io concepts
(Future, Select, Group, cancellation) once you're building for real.

---

## Start small and where to go next

There is no big-bang adoption.

* Start your first Master with the simplest building block: `PolyNode`.
* Add `Pool` when object reuse becomes useful.
* Add `Mailbox` when you need message passing.
* Or use your own type-erased queue.

It's up to you. Each step is useful right away, and remains useful after the next one.

Keep reading:

<!-- Temporarily hidden — Story section commented out of mkdocs.yml nav.

* [Story — Print Server](story/print-server/discussion.md) — the constraint solving a
  real problem, no Zig required.
-->

* [Building Blocks](building-blocks/index.md) — PolyNode, Mailbox, Pool, Master, named
  and diagrammed.

* [API Reference](api/polynode.md) — signatures and contracts.

---

## A simple question

Can you describe your application using only:

* Masters
* Mailboxes
* Pools

If the answer is **yes**, you're already thinking in Matryoshka.

Don't be afraid.

Go ahead.

**Be Master of your systems.**
