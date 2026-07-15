````md
![](kitchen/_logo/matryoshka-io-logo.png)

# Matryoshka-Io

*A practical way to build concurrent software systems with Zig Io.*

---

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Linux](https://github.com/g41797/matryoshka-io/actions/workflows/linux.yml/badge.svg)](https://github.com/g41797/matryoshka-io/actions/workflows/linux.yml)
[![Windows](https://github.com/g41797/matryoshka-io/actions/workflows/windows.yml/badge.svg)](https://github.com/g41797/matryoshka-io/actions/workflows/windows.yml)
[![macOS](https://github.com/g41797/matryoshka-io/actions/workflows/mac.yml/badge.svg)](https://github.com/g41797/matryoshka-io/actions/workflows/mac.yml)
[![Documentation](https://github.com/g41797/matryoshka-io/actions/workflows/docs.yml/badge.svg)](https://github.com/g41797/matryoshka-io/actions/workflows/docs.yml)

---

# First rule

> If you want to build a great software system,
> start by building a software system.

---

# Intent

We know how to write Zig libraries.

We are still learning how to build Zig systems.

Zig Io gives us an excellent foundation for concurrent execution.

Matryoshka provides a simple architecture for organizing that execution.

It does not replace Zig Io.

It gives Io tasks a common language and a repeatable structure.

---

# What is Matryoshka?

Matryoshka is not:

- a framework
- a runtime
- another event loop

It is a small architectural model for Zig Io applications.

It gives long-running Io tasks clear responsibilities.

It gives application objects a clear lifecycle.

It gives concurrent systems a common vocabulary.

---

# Main concept

Zig creates concurrent tasks through `io.concurrent()`.

Matryoshka introduces one architectural concept.

## Master

A **Master** is an Io task that follows the Matryoshka rules.

Every Master is created by `io.concurrent()`.

Not every Io task is a Master.

A Master typically:

- owns one responsibility
- owns application state
- processes Items
- communicates through Mailboxes
- reuses Items through Pools

Some Masters coordinate other Masters.

A worker is simply a Master with one dedicated responsibility.

Matryoshka is therefore not another runtime.

It is a way to organize Io tasks.

---

# Four concepts

Every Matryoshka system is built from only four concepts.

```
Master  
Item  
Mailbox  
Pool  
```

Everything else is implementation.

---

# Why Matryoshka?

Concurrent software repeatedly solves the same problems.

Application objects must be:

- created
- processed
- transferred
- reused
- eventually destroyed

Matryoshka provides one simple model for all of them.

Move Items.

Do not share Items.

Reuse Items.

Keep responsibilities local.

---

# The role of Zig Io

Io provides concurrent execution.

Matryoshka provides architectural structure.

Io answers:

> How do tasks run?

Matryoshka answers:

> How do tasks cooperate?

Io still provides:

- concurrent tasks
- waiting on multiple event sources
- timers
- cancellation
- integration with other Io-based libraries

Matryoshka simply gives those tasks a common architecture.

---

# Adoption

There is no big-bang migration.

Start with one Master.

Add Pools when reuse becomes useful.

Add Mailboxes when communication becomes useful.

Grow the system one responsibility at a time.

---

# Documentation

The documentation starts with the architecture.

You will learn:

- what a Master is
- what an Item is
- how Mailboxes communicate
- how Pools reuse Items
- how the pieces fit together

No frameworks.

No magic.

Just a small architectural vocabulary for building concurrent software.

---

# Be Master of your systems.
````

