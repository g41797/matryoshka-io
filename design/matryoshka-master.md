I think that's the missing piece.

I kept treating **Master** as a special object.

You're treating it as a **role**.

That's a much more powerful idea.

I'd state it like this:

> **Every running entity in Matryoshka is a Master.**

Some Masters have a **single responsibility**.

Some Masters also **coordinate** other Masters.

Some Masters additionally **own shared resources**.

So the hierarchy is not:

```text
Master
└── Worker
```

It's:

```text
            Master (role)
                 │
      ┌──────────┼──────────┐
      │          │          │
 Single-role  Coordinator  Resource owner
    Master       Master        Master
```

A "Worker" is simply:

> **A Master with one dedicated responsibility.**

It owns:

* its mailbox
* its private state
* its execution

It may own no shared resources.

It may coordinate nobody.

But conceptually it is still a Master.

---

Then the "Master" concept becomes beautifully simple:

> **A Master is an independently executing component that owns state and communicates through mailboxes.**

Everything else is optional.

Additional responsibilities may include:

* coordinating other Masters
* owning shared Pools
* creating Masters
* destroying Masters
* routing messages
* interacting with the outside world

---

I actually like this much more than the actor terminology.

Actors tend to imply that every actor is equal.

Matryoshka says:

> Every component is autonomous, but some components naturally become coordinators.

That feels much closer to how real systems are built.

---

So perhaps the four fundamental concepts become:

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

Everything else—threads, Io, Select, Future, Group—is infrastructure used to implement Masters efficiently.

I think that's a very strong conceptual foundation because it separates **what the system is** (Masters, Mailboxes, Pools, PolyNodes) from **how it executes** (threads, Io, scheduling). That distinction is much easier to explain and much less tied to any particular runtime implementation.
