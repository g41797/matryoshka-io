# Matryoshka-Io — A practical way to build concurrent software systems with Zig Io

Hello everyone.

I'd like to introduce **Matryoshka-Io**.

It is an architectural layer built on top of Zig Io.

Not a framework.

Not another runtime.

Not another event loop.

Its goal is simple.

Help organize concurrent software systems.

## The main idea

Most concurrent systems process application objects:

- requests
- connections
- jobs
- sessions
- buffers
- timers

Those objects are created.

Processed.

Transferred.

Reused.

Eventually destroyed.

Matryoshka gives them one common lifecycle.

The architecture is built from only four concepts:

```
Master
Item
Mailbox
Pool
```

A **Master** is simply an Io task that follows a small set of architectural rules.

Items move between Masters through Mailboxes.

Reusable Items return to Pools.

Ownership is transferred together with the Item.

The guiding principle is simple:

> Share by communicating.

Instead of sharing application objects, communicate the application objects themselves.

## Why?

Many concurrent applications solve the same problems again and again:

- ownership
- communication
- object reuse
- resource lifetime

Matryoshka does not solve your business logic.

It provides a small architectural vocabulary for solving those recurring problems in a consistent way.

## Current state

The project is still evolving.

The architecture is stable enough to discuss and experiment with.

Feedback is very welcome, especially on:

- the architectural model
- terminology
- API design
- documentation

I would be happy to hear your thoughts.

Repository:  
<repository link>

Documentation:  
<documentation link>

