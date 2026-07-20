# Matryoshka-Io Diagram Style Guide

> How to communicate architecture using Matryoshka-Io notation.

---

# Purpose

The notation exists to discuss software architecture.

Not implementation.

Not code.

Not APIs.

Not data structures.

A good diagram

- starts a discussion
- answers a question
- explains one idea
- fits on a whiteboard
- fits in a README

---

# Audience

The primary audience is a software engineer.

The secondary audience is an architect.

The notation should also be readable by

- reviewers
- maintainers
- new team members

---

# Architecture first

Always draw architecture.

Not implementation.

Show

- responsibilities
- ownership
- communication
- concurrency
- boundaries

Do not show

- algorithms
- function calls
- inheritance
- object graphs
- language details

---

# Domain first

The notation is domain-oriented.

Infrastructure stays invisible.

Draw

- Request
- Response
- Chunk
- Stream
- Frame
- VideoBuffer
- Shutdown!

Do not draw

- ItemHandle
- PolyNode
- intrusive list
- queue nodes

Mailbox and Pool operate on ItemHandle.

The reader should never see ItemHandle.

---

# One diagram

One diagram answers one question.

Examples

- What are the Masters?
- How do Items move?
- Where is concurrency?
- Where is ownership?
- Where does backpressure appear?
- How is shutdown propagated?

Do not answer everything at once.

---

# Build progressively

Start simple.

Add details.

One diagram builds on another.

Example progression

- system overview
- main flow
- worker farm
- memory reuse
- ownership
- complete architecture

---

# Keep diagrams small

Prefer

- several small diagrams
- one idea each

Instead of

- one huge diagram
- everything connected

---

# Draw for humans

Imagine a whiteboard.

Imagine paper.

Imagine README.md.

If a human avoids drawing it

it is too complicated.

---

# Orientation has no meaning

Horizontal is valid.

Vertical is valid.

Mixed is valid.

Choose the layout

- that fits
- that reads naturally
- that minimizes crossings

---

# Mailboxes

Mailbox is communication.

Mailbox is passive.

Mailbox may be

- horizontal
- vertical

Mailbox may connect

- one producer
- many producers
- one consumer
- many consumers

Use the layout

that explains the architecture best.

---

# Pools

Pool is ownership.

Pool is passive.

Pool is not communication.

Pool usually appears

- beside the main flow
- below a Master
- near the owner

Pool never communicates directly

with Mailbox.

---

# Masters

Master is execution.

Master is active.

Masters own

- Mailboxes
- Pools
- Items

Masters communicate

through Mailboxes.

Never directly.

---

# Items

Items move.

Ownership moves.

Items are never shared.

Items have application names.

Examples

- Request
- Response
- Job
- Frame
- VideoBuffer
- Shutdown!

---

# Multiple workers

Use one worker

when enough.

Use several workers

when it improves understanding.

Both are valid.

Compact

```text
==========>>>

{ Encoder }
```

Expanded

```text
==========>>>

{ Encoder #1 }

{ Encoder #2 }

{ Encoder #3 }
```

Choose clarity.

Not minimalism.

---

# Fan-in

Draw naturally.

Example

```text
{ Camera #1 }

{ Camera #2 }

{ Camera #3 }

      │
      VVV

      ||
      ||
      ||

      VVV

{ Decoder }
```

---

# Fan-out

Draw naturally.

Example

```text
{ Decoder }

      VVV

      ||
      ||
      ||

      VVV

{ Encoder #1 }

{ Encoder #2 }

{ Encoder #3 }
```

---

# Flow

The diagram should feel

like the system is alive.

Items move.

Masters work.

Pools wait.

Mailboxes wait.

Avoid static box diagrams.

---

# Text

Use simple English.

One idea per line.

Short sentences.

Staccato rhythm.

Example

Good

- Receives video.
- Decodes frames.
- Applies filters.
- Encodes output.
- Stores result.

Avoid

> The service receives compressed video streams, decodes them, optionally filters them, encodes them again and stores the resulting output.

---

# Naming

Prefer domain names.

Not technical names.

Good

- VideoBuffer
- Request
- Chunk
- Connection
- Shutdown!

Avoid

- Node
- Object
- Data
- Struct
- Message

---

# Abstraction

Hide implementation.

Reveal intent.

A reader should understand

what the system does.

Not how the library works.

---

# Whiteboard test

A diagram passes

if another engineer can redraw it

from memory

after a short discussion.

If not

simplify it.

---

# README test

A diagram passes

if it remains readable

- in plain Markdown
- without colors
- without fonts
- without rendering
- in a terminal

---

# Final checklist

Before publishing

ask yourself

- Does this explain architecture?
- Does it answer one question?
- Can it be drawn by hand?
- Can it fit in a README?
- Are Item names domain-oriented?
- Is implementation hidden?
- Are Pools separated from communication?
- Are Mailboxes only communication?
- Is concurrency obvious?
- Can someone understand it in one minute?

