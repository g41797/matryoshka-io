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


## What is Matryoshka-Io?

Matryoshka-Io (or shortly Matryoshka) is:

- a practical way
- to build software systems
- on top of Zig Threaded Io

It is not:

- a framework
- a runtime
- another event loop

It is a small '**_frame_**':

- visible code
- several rules
- restricted Io usage
- common way of thinking

The idea is simple:

- _tasks_ become **Masters**
- _application objects_ become **Items**
- _Items_ come from **Pools**
- _Items_ move through **Mailboxes**
- unused _Items_ return to _Pools_

The goal is not an easy system.    

It never was.    

The goal is a system with:

- a common frame
- common rules
- a common way of thinking

That makes the system:

- easier to explain
- easier to discuss
- easier to draw on a whiteboard
- easier to change
- easier to maintain

Matryoshka does not think for you.  

You still design the system.  

You still solve the hard problems.  

It simply brings a _little more order_ to your thinking.

---

## What kind of systems is it for?

Today, Matryoshka is best suited for:

- CPU-bound systems
- built on Zig **Threaded** Io

Typical examples:

- data processing
- background workers
- job schedulers
- pipelines
- business applications
- modular monoliths

Anywhere application Items are:

- created
- processed
- communicated
- reused

## How to start

Start from a 'whiteboard'.  

If you are

- _old-fashion_(my case) it will be real whiteboard or paper
- otherwise - sky is the limit

Not from code.

Not from a prompt.

Draw one Master.

Draw the Items.

Draw how they move.

Then write the code.

Start with one Master.

As the system grows, add:

- more Masters
- more Mailboxes
- more Pools

Do not change the way of thinking.

Keep the rules simple.

If you cannot explain the new flow on a whiteboard:

- stop
- think
- simplify

Then update the drawing.

Only then update the code.

## Where are code snippets and diagrams?

You don't need them , just follow the rule below.  

## First rule of building great software systems

> If you want to build a great software system, start by building a software system.


