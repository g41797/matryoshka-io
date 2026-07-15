# Matryoshka-Io

*A practical way to build concurrent software systems with Zig Io.*

---

> Io answers: How do tasks run?
>
> Matryoshka answers: How do tasks cooperate?

---

## The problem

Zig Io tells your code **when** to run.

It does not tell you where the boundaries are, which part holds which state, or how the parts combine into a system.

So concurrent code drifts. The structure just happens — nobody chose it.

## The answer

One idea:

> **Share by communicating.**

Instead of sharing an application object, pass the object itself.

- Do not share Items. Pass Items. Reuse Items.
- Communication is the default. Sharing is the exception.
- An Item is in exactly one place at any moment.

That single rule removes a whole category of shared-state problems.

## Not another runtime

Matryoshka is not a framework, a runtime, or an event loop.

It does not replace Io. It uses it.

- Io is the engine.
- Matryoshka is the shape of the machine.

The whole thing is a handful of rules and four concepts: **Master, Item, Mailbox, Pool**.

Small enough to read in one sitting.

---

Can you describe your application using only Masters, Mailboxes, and Pools?

If yes, you are already thinking in Matryoshka.

**Be Master of your systems.**

- [Read the full picture →](landing-long-001.md)
- [The repository →](https://github.com/g41797/matryoshka-io)
