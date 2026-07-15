# Architecture

This section explains how a Matryoshka system works.

The API is intentionally small.

The architecture is even smaller.

Everything is built from four concepts.

```
Master
Item
Mailbox
Pool
```

Everything else is implementation.

---

# Master

A **Master** is an Io task.

It owns one responsibility.

It owns its application state.

It processes Items.

A Master never reaches into another Master's state.

Masters cooperate only by communicating.

---

# Item

An **Item** is an application object.

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

An Item may:

- belong to a Master
- wait in a Mailbox
- wait in a Pool

At every moment, an Item belongs to exactly one of them.

Ownership is always clear.

---

# Mailbox

A Mailbox transfers Items between Masters.

The sender gives ownership to the Mailbox.

The receiver becomes the new owner.

The Item itself moves.

Not a shared reference.

Communication replaces shared ownership.

---

# Pool

A Pool stores reusable Items.

Finished Items do not have to be destroyed.

They can return to a Pool.

Another Master may later reuse them.

Pools communicate reusable resources.

---

# Ownership

Ownership is the central rule of Matryoshka.

Every Item has exactly one owner.

```
Master
     │
     ▼
 Mailbox
     │
     ▼
 Master
     │
     ▼
   Pool
     │
     ▼
 Master
```

An Item moves.

It is never intended to be processed simultaneously by multiple Masters.

This greatly simplifies concurrent programming.

---

# The programming model

Matryoshka follows one concurrency principle.

> Share by communicating.

Instead of sharing application objects, communicate the application objects themselves.

The default operations are:

- create
- process
- move
- reuse

Not:

- share
- lock
- synchronize

Synchronization happens naturally through ownership transfer.

---

# Internal implementation

The architecture is implemented with a small set of internal building blocks.

Most application code never needs to use them directly.

## PolyNode

Every Item embeds a `PolyNode`.

`PolyNode` provides:

- intrusive containers
- runtime type identification
- type-erased communication

It is an implementation detail.

Application code thinks in terms of Items.

Matryoshka internally works with the embedded `PolyNode`.

---

# Putting everything together

A typical flow looks like this.

```
Pool
  │
  ▼
Master A
  │
  ▼
Mailbox
  │
  ▼
Master B
  │
  ▼
Pool
```

The Item is created once.

It moves through the system.

It is reused many times.

Very little allocation is required after startup.

Ownership is always obvious.

The architecture stays simple as the system grows.

