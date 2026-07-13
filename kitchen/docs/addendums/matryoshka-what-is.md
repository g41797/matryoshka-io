## What is Matryoshka?

Matryoshka is:

- a practical way
- to build software systems
- on top of Zig Threaded Io

It is not:

- a framework
- a runtime
- another event loop

It is a small frame:

- visible code
- simple rules
- restricted Io usage
- common way of thinking

The idea is simple:

- tasks become Masters
- application objects become Items
- Items come from Pools
- Items move through Mailboxes
- unused Items return to Pools

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

It simply brings a little more order to your thinking.

---

## What kind of systems is it for?

Today, Matryoshka is best suited for:

- CPU-bound systems
- built on Zig Threaded Io

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

Start from a whiteboard.

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


