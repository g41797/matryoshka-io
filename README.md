# matryoshka-io

## Intent

We know how to write Zig libraries.

We are still learning how to build Zig systems.

Zig Io makes developers' lives even more interesting.

Matryoshka is my attempt to make them a little more **_boring_**.

---

## Three small building blocks

Matryoshka-io is built on only three small source files.

### PolyNode

`PolyNode` is the bigger brother of Zig's intrusive `Node`.

Like `Node`, it is:

- embedded into application objects
- suitable for:
    - intrusive lists
    - intrusive queues
    - other intrusive containers

In addition, it:

- provides simple run-time type identification.

Given a `PolyNode`, you can:

- safely identify the containing object
- without interfaces
- without virtual dispatch

### Mailbox

`Mailbox`:

- transfers `PolyNode` objects between Masters
- transfers ownership together with the object
- does not know or care about the concrete object type

### Pool

`Pool`:

- reuses `PolyNode`-based objects
- does not know or care about the concrete object type
- returns objects for reuse instead of destroying them

### Intrusive containers on steroids

Think of them this way.

`PolyNode` is the bigger brother of Zig's intrusive `Node`.

`Mailbox` and `Pool` are intrusive containers on steroids.

The steroids are simple:

- ownership transfer;
- object reuse.

Nothing else.

- No interfaces.
- No framework.

Just three small source files.

> Together, this troika provides two powerful capabilities:
>
> - move objects;
> - reuse objects.

---

## One architectural concept

Matryoshka introduces one architectural concept.

**Master**.

Master is a role.

Master is **not**:

- a type
- an interface
- a runtime

A Master:

- typically has a long lifetime
- owns Matryoshka building blocks
- owns internal state

Some Masters also:

- coordinate other Masters
- own shared resources

A _worker_ is simply a Master with a single dedicated responsibility.

---

## Matryoshka-based system

A Matryoshka-based system is built from Masters.

Masters:

- own state;
- communicate through Mailboxes;
- share reusable objects through Pools.

Matryoshka does not dictate the implementation.

---

## The role of Zig Io

Matryoshka-io uses Zig Io in two situations.

### Required by Zig

Some operations must use Zig Io because Zig exposes them only through the Io API.

Matryoshka uses Io where it is required.

The architecture remains unchanged.

### Additional Io capabilities

Matryoshka also uses Zig Io where it provides useful functionality.

Examples include:

- waiting for multiple event sources
- timers
- cancellation
- integration with other Io-based libraries

These capabilities extend Matryoshka.

They do not define it.

---

## Why Matryoshka-io?

Think about cars.

- A traditional threaded application is a conventional car
- A pure Io-based application is an electric car
- Matryoshka-io is a hybrid

Matryoshka:

- keeps the architecture simple
- uses Zig Io where Zig requires it
- uses Zig Io where it provides additional functionality

Start building today.

If Zig Io changes tomorrow—**and it will**—your architecture stays the same.

## Try Matryoshka without fear

There is no big-bang commitment.

Start with the simplest building block: `PolyNode`.

Add `Pool` when object reuse becomes useful.

Add `Mailbox` when you need 'message' passing.

Or use your type-erased queue.

It's up to you.

The **Master** concept comes naturally as the application grows.

Each step provides immediate value.

Each step remains useful after the next one.

The whole troika is only 582 lines of code.

Don't be afraid.

Go ahead.