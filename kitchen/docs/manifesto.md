# Matryoshka Manifesto

## First rule of building great software systems

> If you want to build a great software system, start by building a software system.

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

It _removes choices_:

- a small subset of Threaded Io functionality
- restricted cancellation points
- a few building blocks
- a few rules
- clear communication
- manageable resource reuse

The hard problems do not disappear.

But they become easier to discuss.

Because the system becomes **_visible_**.

---

## One constraint

Matryoshka asks you to accept one constraint.

> Everything is a Master communicating via Mailboxes.

Pools add a second one.

> Shared resources are explicit and controlled.

Two constraints. In return you get:

* parts talk in one way only: messages(items)
* you always sure that item is in one place
* you know what runs in parallel
* you can swap one Master for another
* you can understand one Master without reading the whole system

---

## Master is an Io task

Master is the main concept of Matryoshka.

* Io creates tasks through `*.concurrent()`.
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
    ┌────────┼────────-┐
    │        │         │
Single-job Coordinator Resource owner
 Master      Master       Master
```

* Some Masters do one job.
* Some Masters coordinate other Masters.
* Some Masters own shared resources.

Every part runs on its own. Some parts grow into coordinators.

That is how real systems are built.

---

## Down to earth

The whole model fits in a few lines.

* A Master usually has one input mailbox.
* A Master processes one message at a time
    * Most of Masters has internal loop
* A Master may send a message to any mailbox.
    * Including its own.
* Multiple Masters may share one mailbox.
* A Master may borrow items from one or more Pools.
* Pools may be shared by many Masters.
* Mailboxes and Pools hold type-erased items.

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

Master is an Io task. The other three are code.

The one-line summary below is all this page gives you — see  
[Building Blocks](building-blocks/index.md) for a full page per concept, still no Zig  
syntax, and [API Reference](api/polynode.md) once you're ready to write code.

### Item vs ItemHandle and PolyNode

- Item is allocatable application object.  
- Matryoshka-Io does not work with Items.  
- It works with ItemHandles:  
```zig
pub const ItemHandle = *PolyNode;
```
You will learn internals later.    

For now - just remember

- Item - for application and/or master code
- ItemHandle (actually address of PolyHandle) - for Matryoshka-Io
     - PolyNode is embedded within every Item  


### Mailbox

`Mailbox`:

* transfers Items  between Masters
* does not know or care about the concrete item type

### Pool

`Pool`:

* creates new Items or gets them from available 
* returns items for reuse instead of destroying them
* does not know or care about the concrete item type

### Together

`PolyNode` is 

- small struct within any Item
- used for Item handling

`Mailbox` and `Pool` are ItemHandles containers on steroids.

The steroids are simple:

* intrusion
* type erasure
* object transfer
* object reuse

Nothing else.

* No interfaces.
* No framework.

The whole _troika_ is only several hundreds LOC.

---


## Start small and where to go next

There is no big-bang adoption.

* Start your first Master with the simplest Item
    * don' t forget embed  `PolyNode`
* Add `Pool` when object reuse becomes useful.
* Add `Mailbox` when you need message passing.
* Or use your own type-erased queue. It's up to you.

Each step is useful right away.      
Each step remains useful after the next one.  

Keep reading:

* [Building Blocks](building-blocks/index.md) — PolyNode, Mailbox, Pool, Master, named
  and diagrammed.

* [API Reference](api/polynode.md) — signatures and contracts.

---

## A simple question

Can you describe your application using only:

* Masters
* Items
* Mailboxes
* Pools

If the answer is **yes**, you're already thinking in Matryoshka.

Don't be afraid. Go ahead.

