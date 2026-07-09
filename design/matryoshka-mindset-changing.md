# Changing mindset in Matryoshka-Io

Latest changes - Master is result of io.concurrent() let's call it task

It completely change all mindset - Matryoshka not is not side car, it's integral part of Io world

Master difference to regular task - it works with PolyNode based items(objects), Has usually in Mailboxe, uses Mailbox(es) and Pool(s)

Now Matryoshka is one of the ways to build Zig based system.

Because it defines some restrictions, rules, provides several features , idioms and patterns - it simplifies development of systems.

It is not framework, but definitely it's frame/canvas

In 1000 variants Io provides it shows simple way - just 3 building blocks + task(io.concurrent()), code of matrusoshka itself depends only on Io.Mutex and Io.Condition

Io will change, but Matryoshka depends on very basic Io features - it will; be stable.

# Expanded version

What changed is not just wording. The architectural model changed.

Previously the mental model was:

> Matryoshka + Io

Now it is:

> Io provides execution.
> Matryoshka provides system architecture.

That deserves its own design document first. 

After that, README, Manifesto and API docs become much easier to update.

I would write something like:

> **Design: The New Matryoshka Mindset**
>
> This document explains what changed and why.

Then structure it roughly like this:

1. Why this document exists
2. The old mental model
3. The new mental model
4. What a Task is
5. What makes a Task become a Master
6. Why Matryoshka is not a framework
7. Why Matryoshka depends only on Io primitives
8. What this means for application architecture
9. Consequences for documentation

---

The important conceptual shift, as I understand it, is this:

Old:

```
Application
    │
Matryoshka
    │
Io
    │
OS
```

New:

```
Application
    │
Io Tasks
    │
┌───────────────────────┐
│ Some tasks are Masters│
│                       │
│ Mailboxes             │
│ Pools                 │
│ PolyNodes             │
└───────────────────────┘
    │
Io
    │
OS
```

Matryoshka is no longer "running beside" Io.

It is a programming model *inside* the Io task world.

---

I also think the definition of Master changes.

Previously:

> A Master is an architectural concept.

Now it can become much more concrete.

Something like:

> A Master is an Io task that follows the Matryoshka object model.

Not every task is a Master.

A task becomes a Master when it adopts Matryoshka rules.

Typically it:

* owns application state
* owns one or more Mailboxes
* owns one or more Pools
* exchanges PolyNode objects
* transfers items instead of sharing 

That is an extremely simple definition.

---

I would also stop saying

> "Matryoshka introduces Masters."

Instead say

> "Matryoshka defines a way for Io _tasks_ to cooperate."

because now `io.concurrent()` already creates the _task_.

Matryoshka defines how those tasks communicate and own objects(PolyNode based items).

---

Another important shift is dependency direction.

Previously readers could think:

```
Matryoshka
    uses
Io
```

Now I'd explicitly show:

```
Matryoshka requires only

• Io.Mutex
• Io.Condition

Everything else comes from Io itself.
```

That is a very powerful statement.

It explains why Matryoshka should survive future Io evolution.

Whether Io gains new schedulers, executors, networking models or task implementations is largely irrelevant.

As long as those synchronization primitives exist, Matryoshka stays unchanged.

---

I would also introduce the idea of a **programming model**.

Instead of saying

> "Matryoshka is not a framework."

say something stronger:

> Matryoshka is a **set of rules** and several hundreds LOC for building Zig systems on top of Io.


It does not own execution.

It does not own your application.

It does not provide a runtime.

It provides conventions that make large systems easier to reason about.

That describes Matryoshka much better than "not a framework."

---

Finally, I think the README should become significantly simpler.

Instead of trying to explain everything, it could reduce to one central idea:

> Io answers:
>
> **How do tasks execute?**
>
> Matryoshka answers:
>
> **How do tasks cooperate?**

Everything else—PolyNode, Mailbox, Pool, Master—is just the implementation of that answer.

Earlier versions positioned Matryoshka as infrastructure alongside Io. 

The new model positions Io as the execution substrate and Matryoshka as an architectural layer built on top of Io tasks. 

That makes the overall story both simpler and more aligned with Zig's direction.


# Design: The New Matryoshka Mindset

## Why

Matryoshka was originally presented as infrastructure alongside Zig Io.

That is no longer the best way to think about it.

The introduction of `io.concurrent()` changes the mental model.

Io provides execution.

Matryoshka provides architecture.

---

## Execution belongs to Io

Tasks are created by Io.

```zig
const task = try io.concurrent(run, .{context});
```

Io decides how tasks execute.

Matryoshka does not replace or extend this model.

It builds on top of it.

---

## A Master is an Io task

A Master is not a special runtime object.

A Master is an Io task that follows the Matryoshka object model.

Typically a Master:

- owns application state
- owns one or more Mailboxes
- owns one or more Pools
- exchanges PolyNode objects
- transfers ownership instead of sharing mutable objects

Not every Io task is a Master.

Every Master is an Io task.

---

## Matryoshka defines cooperation

Io answers:

> How do tasks execute?

Matryoshka answers:

> How do tasks cooperate?

Instead of sharing mutable state, Masters exchange ownership of objects.

This keeps object lifetime and ownership explicit.

---

## Three building blocks

Matryoshka adds only three concepts:

- PolyNode
- Mailbox
- Pool

Everything else is ordinary Zig and Io.

---

## Not a framework

Matryoshka does not own your application.

It does not provide a runtime.

It does not replace Io.

It defines a set of rules for building systems on top of Io.

---

## Minimal dependency

Matryoshka - several hundreds LOC. 

It depends only on basic Io synchronization primitives.

- `Io.Mutex`
- `Io.Condition`

As Io evolves, Matryoshka should require little or no change.

---

## Summary

Io executes tasks.

Matryoshka gives those tasks a simple object model.

Tasks become Masters by adopting a small set of rules.

The result is a consistent way to build Zig systems from a few reusable building blocks.

