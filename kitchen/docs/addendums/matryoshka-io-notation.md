# Matryoshka-Io Notation

> A visual language for discussing concurrent software systems.

---

# Why

Matryoshka-Io is built around four architectural building blocks:

- Master
- Item
- Mailbox
- Pool

The same architecture deserves a simple visual language.

The notation is intentionally small.

It should work equally well in

- README files
- Markdown
- whiteboards
- presentations
- code comments

The goal is simple:

> Someone should understand the architecture before reading the explanation.

---

# Design principles

## Architecture first

The notation describes architecture.

Never implementation.

---

## One symbol. One meaning.

Every primitive has exactly one responsibility.

Never overload symbols.

---

## Symbols represent behavior

| Symbol | Represents |
|---------|------------|
| Master | execution |
| Item | movable object |
| Mailbox | communication |
| Pool | reusable storage |

---

## ASCII first

Everything should be drawable using plain text.

If a symbol cannot be drawn in ASCII,  
it is probably too complicated.

---

## Composition instead of complexity

Only four primitive symbols exist.

Everything else is built from them.

---

# Primitive symbols

## Master

A Master is the only active building block.

It executes.

It owns state.

It makes decisions.

```
+-----------+
|    --     |
|   /  \    |
|  |----|   |
|   \  /    |
|    --     |
+-----------+
|  Master   |
+-----------+
```

The loop means

> execution.

It does **not** imply

- thread
- coroutine
- actor
- event loop

Those are implementation details.

---

## Item

An Item is the object that moves through the architecture.

```
+------+
| Item |
+------+
```

Examples:

- Request
- Connection
- Buffer
- Session
- Job

Architecturally they are identical.

---

## Mailbox

A Mailbox represents communication.

```
======
```

Unlike queues in UML,  
the notation emphasizes communication,  
not the container.

---

## Pool

A Pool stores reusable Items.

```
 _________
/         \
|  Pool   |
\_________/
```

Pools retain.

They never execute.

---

# Mailbox variants

Sharing belongs to the Mailbox.

Not to the Master.

---

## One producer

```
>======
```

One Master sends.

One Master receives.

---

## Many producers

```
>>>======
```

Several Masters send to the same Mailbox.

Only one Master receives.

Typical examples:

- logging
- event aggregation
- request collection

---

## Many consumers

```
======>>>
```

One Master sends.

Several Masters receive from the same Mailbox.

Typical examples:

- worker pools
- job distribution

---

## Many producers and many consumers

```
>>>======>>>
```

Shared communication on both sides.

---

# Composition

## Communication

```
+-----------+

  Master

     |

>======

     |

+-----------+

  Master
```

An Item moves through the Mailbox.

The Mailbox transports.

It never owns application logic.

---

## Shared input mailbox

Several Masters send to one Mailbox.

```
Master

   |

\
 \
  >>>======

            |

      +-----------+
      |  Master   |
      +-----------+
```

The sharing belongs to the Mailbox.

Not to the receiving Master.

---

## Shared worker mailbox

One Master distributes work.

```
      +-----------+
      |  Master   |
      +-----------+

            |

      ======>>>

           / \
          /   \

      Master  Master
```

Again,

the Mailbox is shared.

Not the sender.

---

## Pool

```
        _________
       /         \
      |   Pool   |
       \_________/

          ▲
          │

      +-----------+
      |  Master   |
      +-----------+
```

Masters borrow Items.

Masters return Items.

Pools simply retain them.

---

## Item movement

```
+------+
| Item |
+------+

    │

>======

    │

+-----------+
|  Master   |
+-----------+
```

An Item always has exactly one owner.

Either

- a Master
- a Mailbox
- a Pool

Never more than one.

---

# Reading diagrams

Readers should gradually stop reading labels.

Instead they should recognize

Loop

→ execution

Rectangle

→ Item

Channel

→ Mailbox

Container

→ Pool

The notation becomes another language,  
alongside the words

- Master
- Item
- Mailbox
- Pool

---

# Non-goals

The notation does not describe

- scheduling
- async implementation
- mutexes
- futures
- synchronization primitives
- memory allocation
- Zig APIs

Those belong to implementation.

---

# Future extensions

Future documents may define notation for

- request pipelines
- cancellation
- recycler
- timers
- master hierarchy
- system boundaries
- ownership transfer

These should be expressed by composing the existing symbols,  
not by introducing many new ones.

---

# Design goal

The notation should be learnable in five minutes.

Someone should be able to sketch a Matryoshka system on a whiteboard,  
and another Matryoshka user should immediately understand it.
