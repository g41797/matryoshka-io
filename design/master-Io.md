A Master can participate in the Io runtime by:

* wait for I/O readiness
* receive I/O events
* receive timer events
* receive signals
* receive cancellation notifications
* spawn asynchronous operations
* await completion of asynchronous operations
* schedule itself for later execution
* wake other Masters
* react to custom event sources

Or, mapped to capabilities rather than specific APIs:

| Capability                 | Io primitive                |
| -------------------------- | --------------------------- |
| Wait for external events   | Event Source                |
| Network I/O                | Socket event source         |
| File I/O                   | File event source           |
| Timers                     | Timer event source          |
| Process signals            | Signal event source         |
| Cancellation               | Cancellation token / source |
| Deferred execution         | Scheduler                   |
| Async operation completion | Completion event            |
| Custom integration         | Custom event source         |

The key idea is that **Io doesn't change the computational model**. It simply provides additional ways for a Master to receive messages.  
  
In other words:

> Everything that happens in the system eventually becomes a message delivered to a Master's mailbox.

Whether that message originated from another Master, a timer, a socket becoming readable, a completed asynchronous operation, or a signal is an implementation detail. The Master still processes one message at a time using the same model. That is a strong conceptual bridge between Matryoshka and Matryoshka-Io.

Exactly. I think you've identified the missing architectural piece.

The bridge is **not** that a Master directly "participates in Io." Instead, the bridge is a component that **waits on Io events and translates them into messages**.

That keeps the Master model pure.

For example:

```text
           +----------------+
           |   Io runtime   |
           +----------------+
                  │
       wait/select/poll/epoll/...
                  │
                  ▼
          +---------------+
          | Io Bridge     |
          | (Master)      |
          +---------------+
                  │
          send message/job
                  │
                  ▼
             Master Mailbox
                  │
                  ▼
               Master
```

The bridge itself is just another Master.

Its responsibilities are:

* wait for one or more Io event sources
* translate an event into a job/message/chunk
* send that message to one or more mailboxes
* optionally borrow buffers from pools
* return buffers when processing completes

This fits your philosophy perfectly:

> **The outside world never calls a Master directly.**
>
> Everything enters the system as a message delivered to a mailbox.

Then Matryoshka-Io becomes simply a collection of bridge Masters:

* Socket Bridge
* Timer Bridge
* Signal Bridge
* File Bridge
* Process Bridge
* Custom Event Bridge

Each one converts external events into ordinary Matryoshka messages.

I actually think this is one of the strongest architectural messages for the project:

> **Io is just another producer of messages.**

Nothing special happens inside the application because the source was a socket, a timer, or another Master. Once the event crosses the bridge, it is simply another message in the system. That's a very clean separation of concerns.


I agree. Going down to sockets, timers, or specific event sources is too low-level for the manifesto.

The architectural point is simpler:

> **Matryoshka defines the application model.**
>
> **Io defines the execution model.**

Or, even more concretely:

* Matryoshka answers: **How is the system structured?**
* Io answers: **When does work become runnable?**

The bridge between them is minimal:

* wait for work in Io
* convert readiness/completion into a message
* deliver the message to a Master's mailbox

That's all.

I would avoid mentioning sockets, files, timers, or epoll in the manifesto. Those are implementation details. The important idea is that **Io introduces another way work enters the system**, but it doesn't change the Master/Mailbox/Pool model.

So your manifesto could simply add one sentence after "Down to earth":

> **With Matryoshka-Io, external work is translated into ordinary messages and delivered to Masters through their mailboxes. The application model remains unchanged.**

That keeps the separation very clear:

* **Matryoshka** → architecture.
* **Io** → execution.
* **Bridge** → translation between the two.

Io and Matryoshka are solving different problems. That’s the key point.

Io answers: **how work is scheduled and executed over time**.

Matryoshka answers: **how the system is structured so work stays manageable as it grows**.

So the real question is not “why Matryoshka if there is Io”, but:

> **What do you do when Io is not enough to keep system complexity under control?**

---

## Io alone

Io gives you:

* event waiting
* async execution
* readiness/completion notifications
* scheduling of work over time

That is enough to *run* a system.

But it does not define:

* system boundaries
* ownership of state
* communication structure
* composition rules
* resource sharing model
* isolation between parts of the system

So Io tells you *when things happen*, but not *what the system is made of*.

---

## Matryoshka adds structure

Matryoshka defines:

* **Masters** → isolated units of behavior
* **Mailboxes** → controlled communication boundaries
* **Pools** → controlled shared resource access

This gives you:

* explicit ownership boundaries
* predictable communication patterns
* composable components
* isolation by default
* systems that can be reasoned about locally

---

## The relationship

* Io is the **engine**
* Matryoshka is the **shape of the machine**

Or more precisely:

* Io drives execution
* Matryoshka defines system topology

---

## Why not just Io?

Because without a structural model:

* async systems become ad-hoc
* concurrency becomes implicit
* components couple through hidden assumptions
* scaling architecture becomes accidental

Io does not prevent any of that. It just executes it faster.

---

## Why Matryoshka matters

Matryoshka forces one constraint:

> Everything is a Master communicating via Mailboxes.

That constraint gives you:

* uniform communication model
* explicit boundaries
* predictable concurrency
* replaceable components
* easier reasoning under load

Pools add a second constraint:

> shared resources are explicit and controlled

---

## The real answer

You don’t use Matryoshka instead of Io.

You use Matryoshka to make Io-based systems:

* structured
* composable
* understandable
* scalable without architectural collapse

---

If Io is “how do I run this work asynchronously?”

then Matryoshka is:

> “how do I design the system so async work doesn’t turn into chaos?”

Yes, and that’s a very realistic constraint.

If Matryoshka-Io requires developers to constantly “think in Io”, it will lose most users immediately.

So the important conclusion is:

> **Matryoshka should not expose Io as a mental model to application developers.**

---

## What developers actually want

Most developers don’t want:

* event loops
* readiness models
* scheduling abstractions
* async execution semantics

They want:

* “my component receives work”
* “my component sends work”
* “I can compose things”
* “I can isolate state”
* “I can reuse patterns”

---

## So Io must disappear from the model

Io should be:

* runtime infrastructure
* not a programming model
* not part of the mental API

So developers see:

* Masters
* Mailboxes
* Pools

Not:

* select loops
* event sources
* readiness states

---

## What Io becomes in Matryoshka

Io becomes:

> **a hidden delivery mechanism for Mailboxes**

That’s it.

Not a feature.

Not a concept.

Not a layer developers reason about.

---

## The correct abstraction boundary

* Developer level → Matryoshka model
* Runtime level → Io execution system
* Bridge level → message delivery into mailboxes

So:

* Io exists
* but it is not “used”
* it is only “there”

---

## Why this matters

If Io leaks into the model:

* you couple architecture to execution details
* you increase cognitive load
* you lose portability of the mental model
* you turn a structural system into an async framework

That is exactly what you want to avoid.

---

## The real positioning

Matryoshka is:

> A structural model for systems

Io is:

> One possible engine that delivers messages into that structure

---

## A good rule for the manifesto

If a developer has to mention Io while designing their system, it is already too visible.

They should be able to design everything using only:

* Masters
* Mailboxes
* Pools

And never think:

> “how does Io do this?”

---

So yes — your intuition is correct:

> exposing Io as a concept in the developer model would likely hurt adoption more than help it.

Keep Io powerful.

Keep it hidden.

Keep Matryoshka clean.
