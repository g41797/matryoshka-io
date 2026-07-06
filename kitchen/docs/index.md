# matryoshka-io

Building Blocks for Modular Monoliths — Zig implementation.

## First rule of building great software systems

> If you want to build a great software system, start by building a software system.

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

## One constraint

Matryoshka asks you to accept one constraint.

> Everything is a Master communicating via Mailboxes.

Pools add a second one.

> Shared resources are explicit and controlled.

Read the full pitch: [The Manifesto](manifesto.md).

## Where to go next

* [The Manifesto](manifesto.md) — the full pitch, one constraint, four concepts.
* [Story — Print Server](story/print-server/discussion.md) — see the constraint solve a
  real problem, no Zig required.
* [Building Blocks](building-blocks/index.md) — PolyNode, Mailbox, Pool, Master, named.
* [API Reference](api/polynode.md) — signatures and contracts, for when you start writing code.
* [Patterns & Cookbook](patterns/index.md) — reusable code shapes.
* [Deep Dive — Video Transcoder](deep-dive/video-transcoder.md) — a harder worked example.
* [Addendums](addendums/slot-vs-ref-counting.md) — design-rationale essays and an Io primer.
