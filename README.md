![](kitchen/_logo/matryoshka-io-logo.png)

---

# Matryoshka-Io — a practical way to build great software systems

---  
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Linux](https://github.com/g41797/matryoshka-io/actions/workflows/linux.yml/badge.svg)](https://github.com/g41797/matryoshka-io/actions/workflows/linux.yml)
[![Windows](https://github.com/g41797/matryoshka-io/actions/workflows/windows.yml/badge.svg)](https://github.com/g41797/matryoshka-io/actions/workflows/windows.yml)
[![macOS](https://github.com/g41797/matryoshka-io/actions/workflows/mac.yml/badge.svg)](https://github.com/g41797/matryoshka-io/actions/workflows/mac.yml)
[![Deploy Documentation](https://github.com/g41797/matryoshka-io/actions/workflows/docs.yml/badge.svg)](https://github.com/g41797/matryoshka-io/actions/workflows/docs.yml)


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

Matryoshka-Io is that *fishing rod* for *building software systems*.

- It does not think for you.
- You still design the system.
- You still solve the hard problems.

It simply brings a *little more order* to your thinking.

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

## Four building blocks. One principle. Common language.

Every Matryoshka-Io system is built from _four building blocks_:

- **Master** — execution
- **Item** — state/data/command/...
- **Mailbox** — communication
- **Pool** — resource reuse

They all follow one _principle_:

> **Share by communicating.**

You stop talking about:

- tasks
- futures
- mutexes
- queues

You start talking on Matryoshka-Io language:

- Masters
- Items
- Mailboxes
- Pools


---


### Master

A **Master** is

- an _Threaded_ Io _task_
- created by _concurrent()_
- follows the Matryoshka-Io rules
- holds its own state
- works with Items
- communicate with another Masters and/or application


---


### Item

An **Item** is

- movable application object
  - Request
  - Connection
  - Session
  - Buffer
  - Job
  - ...
- **allocated** (as all building blocks)
- outlive the function that created them

The one rule that matters:

> An Item is in exactly one place at any moment.

**ONE PLACE**:

- or Master uses it
- or a Mailbox holds it
- or a Pool holds it

> **Never several at once**.

---

### Item and ItemHandle.

The documentation talks about _Item(s)_.      
The API works with an **ItemHandle**.  

You are thinking in terms of:

- read _file_
- write _file_
- close _file_

on API level one of the arguments is _file handle_.

The same is for Matryoshka-Io API

- you are thinking in terms of _Item_ - Application entity
- API is working with _ItemHandle_ - Matryoshka-Io entity


---


### Mailbox

A **Mailbox** moves an Item from one Master to another:

- One Master places an Item in
  - Mailbox ensures that it's only owner of Item
- Another Master later receives it
  - Mailbox ensures that receiver is only owner of Item

---


### Pool

A **Pool**

- create new Items
- holds reusable Items

Usually Master

- gets Item from Pool
- process Item
- on finish
  - send Item to another Master for further processing
  - returns Item to Pool

A Pool is not storage.  
An empty Pool is

- not an error
- it is backpressure.

Matryoshka-Io supports backpressure 'naturally'

---

## You can’t win the lottery if you don’t buy a ticket.

Start with Items.

Add a Pool when reuse becomes useful.

Add a Mailbox when communication becomes useful.

Organize long-running tasks as Masters.

Each step is useful right away.

Each step stays useful after the next one.

Can you describe your application using only

- Masters
- Items
- Mailboxes
- Pools

If
- **yes** - you are on the right way
- no - [you still have the chance](https://github.com/g41797/matryoshka-io)

---

## Master is King

Master is YOUR CODE.  

Only Master

- makes decisions
- owns application state
- talks to building blocks

Another building blocks are "slaves":

- Mailbox - communication
- Pool - storage/reuse
- Item - "data"

---

Be Master **of your** systems.
