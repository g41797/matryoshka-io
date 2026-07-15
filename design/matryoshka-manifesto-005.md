# Matryoshka Manifesto

Versioned doc. Replaces [matryoshka-manifesto-004.md](matryoshka-manifesto-004.md).  
Change from -004: New Mindset. Dropped the "hybrid car" analogy — it implied  
Matryoshka sometimes uses Io and sometimes doesn't. Replaced with: Io creates  
every task; Matryoshka is the small set of rules some of those tasks follow.  
Change from -003: New Mindset. Master connected to `io.concurrent()` — "Master  
is a role" replaced with "Master is an Io task that follows the Matryoshka  
rules." Task-world diagram replaces the old floating-role diagram.

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

## Master is an Io task

Master is the main concept of Matryoshka.

* Io creates tasks through `io.concurrent()`.
* A Master is an Io task that follows the Matryoshka rules.

Master is **not**:

* a type
* an interface
* a runtime

> A Master runs on its own, as an Io task.
> It owns its state.
> It talks through mailboxes.

Everything that runs in Matryoshka is a Master:

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
* A Master may borrow items from one or more pools.
* Pools may be shared by many Masters.
* Mailboxes and Pools may hold typed or type-erased items.

Nothing else is required.

| Capability          | Primitive                  |
| ------------------- | -------------------------- |
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

Master is an Io task. The other three are code.

### PolyNode

`PolyNode` is the bigger brother of Zig's intrusive `Node`.

* embedded into application items
* works in intrusive lists, queues, and other intrusive containers
* adds simple run-time type identification

Given a `PolyNode`, you can identify the containing object:

* without interfaces
* without virtual dispatch

### Mailbox

`Mailbox`:

* transfers `PolyNode` items between Masters
* transfers the object, not a reference to it
* does not know or care about the concrete object type

### Pool

`Pool`:

* reuses `PolyNode`-based items
* returns items for reuse instead of destroying them
* does not know or care about the concrete object type

### Together

Just three small building blocks.

`Mailbox` and `Pool` are containers on steroids.

The steroids are simple:

* intrusion
* type erasure
* object transfer
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

Io creates every task through `io.concurrent()`.

Matryoshka does not compete with Io. It lives inside the same task world.

* Io answers: how do tasks run?
* Matryoshka answers: how do tasks cooperate?

Start building today.

If Zig Io changes tomorrow—and it will—Matryoshka's rules stay the same.

---

## Start small

There is no big-bang adoption.

* Start your first Master with the simplest building block: `PolyNode`.
* Add `Pool` when object reuse becomes useful.
* Add `Mailbox` when you need message passing.
* Or use your own type-erased queue.

It's up to you.

Each step is useful right away.

Each step remains useful after the next one.

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
