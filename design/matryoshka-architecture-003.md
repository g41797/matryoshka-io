# Matryoshka Architecture

> Source material for future GitHub MkDocs pages.

---

## Chapter 1 — Why Matryoshka exists

### The problem

Concurrent systems are built from independent components.  
These components need to exchange work items:

- A sensor produces readings.
- A processor transforms them.
- A logger writes them to disk.
- A monitor watches for anomalies.

Each component runs in its own thread or task.  
They must communicate without stepping on each other.

```text
┌──────────┐     ┌───────────┐     ┌──────────┐     ┌──────────┐
│  Sensor  │ ──► │ Processor │ ──► │  Logger  │     │ Monitor  │
└──────────┘     └───────────┘     └──────────┘     └──────────┘
                                         ▲               ▲
                                         │               │
                                    How do items    How does Monitor
                                    move safely?    see the same items?
```

### The constraints

Real systems impose hard constraints:

- No shared mutable state between components.
- No allocations on the hot path — the allocator is too slow.
- Components should not know each other's concrete types.
- Each item's place must be clear — who holds it, at every moment.

### Ad-hoc solutions and why they break

**Raw pointers, no place discipline.**

```text
Component A                    Component B
     │                              │
     ├── creates item ──────────►   │ uses item
     │                              │
     ├── frees item                 │ uses item ← use-after-free
     │                              │
```

- No rule about who frees.
- No rule about when.
- Bugs appear under load, not in tests.

**Allocator-per-message.**

```text
     send:    allocate → fill → enqueue
     receive: dequeue → use → free

     Every message = one allocation + one free.
```

- Allocation pressure under high throughput.
- Allocator contention between threads.
- GC pauses in managed languages.

**Type-specific queues.**

```text
     Queue<Event>
     Queue<Request>
     Queue<Response>
     Queue<Heartbeat>
     Queue<Metric>
     ...
```

- One queue type per message type.
- Every new type = new queue, new synchronization, new bugs.
- Cannot mix types in a single pipeline stage.

**Manual lifecycle.**

```text
     create → use → ... → forget to return → leak
     create → use → ... → return twice → double-free
```

- No enforcement of acquire/release discipline.
- Pool exhaustion under sustained load.
- Silent resource leaks.

### What was needed

One mechanism that solves all four problems:

```text
┌─────────────────────────────────────────────────────────┐
│                   What was needed                       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  • Universal transfer.                                  │
│    Works for any item type, any pattern.                │
│                                                         │
│  • Zero allocations after initialization.               │
│    Items are pre-allocated, then moved — never copied.  │
│                                                         │
│  • Type-safe recovery without generics pollution.       │
│    One queue carries all types. Receiver recovers the   │
│    concrete type safely.                                │
│                                                         │
│  • Each item in exactly one place, always.               │
│    The system enforces it.                              │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Before and after

**Before — ad-hoc wiring:**

```text
┌──────────┐         ┌──────────┐         ┌──────────┐
│ Sensor   │         │Processor │         │  Logger  │
│          │         │          │         │          │
│ alloc ──►├─ ptr ──►│ copy ──► ├─ ptr ──►│ free     │
│          │         │ alloc    │         │          │
└──────────┘         └──────────┘         └──────────┘

  • Each link uses a different mechanism.
  • Each type needs its own queue.
  • Where an item is stays implicit — bugs hide.
```

**After — matryoshka:**

```text
┌──────────┐         ┌──────────┐         ┌──────────┐
│ Sensor   │         │Processor │         │  Logger  │
│          │         │          │         │          │
│  Slot ──►├─ mbox ─►│  Slot ──►├─ mbox ─►│  Slot    │
│          │         │          │         │          │
└──────────┘         └──────────┘         └──────────┘

  • Every link uses the same mechanism.
  • One queue carries all types.
  • Where an item is stays explicit — Slot is full or empty.
```

---

## Chapter 2 — How the solution grows

Each section introduces one concept.  
Each concept answers the question the previous one creates.

### Step 1 — Intrusive node

**Why lists?**

Concurrent components process items in order.  
The natural data structure is a queue — first in, first out:

- Producer appends to the tail.
- Consumer removes from the head.
- The queue is a linked list.

**Why intrusive?**

A non-intrusive list allocates a wrapper node for each item:

```text
Non-intrusive:

  ┌────────────┐     ┌────────────┐     ┌────────────┐
  │ ListNode   │     │ ListNode   │     │ ListNode   │
  │ ┌────────┐ │     │ ┌────────┐ │     │ ┌────────┐ │
  │ │  next ─┼─┼────►│ │  next ─┼─┼────►│ │  next  │ │
  │ │  prev  │ │     │ │  prev  │ │     │ │  prev  │ │
  │ │  data ─┼─┼──┐  │ │  data ─┼─┼──┐  │ │  data ─┼─┼──┐
  │ └────────┘ │  │  │ └────────┘ │  │  │ └────────┘ │  │
  └────────────┘  │  └────────────┘  │  └────────────┘  │
                  ▼                  ▼                  ▼
              UserItem           UserItem           UserItem

  Each enqueue = allocate a ListNode.
  Each dequeue = free a ListNode.
```

An intrusive list embeds the link pointers inside the item itself:

```text
Intrusive:

  ┌────────────┐     ┌────────────┐     ┌────────────┐
  │ UserItem   │     │ UserItem   │     │ UserItem   │
  │ ┌────────┐ │     │ ┌────────┐ │     │ ┌────────┐ │
  │ │  next ─┼─┼────►│ │  next ─┼─┼────►│ │  next  │ │
  │ │  prev  │ │     │ │  prev  │ │     │ │  prev  │ │
  │ └────────┘ │     │ └────────┘ │     │ └────────┘ │
  │  payload   │     │  payload   │     │  payload   │
  └────────────┘     └────────────┘     └────────────┘

  Zero allocations for list operations.
  The item IS the node.
```

In Zig, the intrusive node comes from the standard library:

```zig
std.DoublyLinkedList.Node
```

- `prev` and `next` pointers.
- Nothing else.

At this point:
- No tags.
- No mailbox.
- No pool.
- No transfer rule yet.

Just an intrusive linked list node.

### Step 2 — Runtime identity (Tag)

The question from Step 1:

> I have a `*Node`. How do I know what type of item it belongs to?

Different item types can live in the same list.  
The node itself carries no type information.  
We need a runtime identity marker.

**Solution: attach a tag.**

```text
┌─────────────────┐
│    PolyNode      │
│ ┌─────────────┐ │
│ │    Node      │ │    Node = list links (prev, next)
│ │  (prev/next) │ │
│ └─────────────┘ │
│ ┌─────────────┐ │
│ │     Tag      │ │    Tag = pointer to a unique address
│ └─────────────┘ │
└─────────────────┘

  PolyNode = Node + Tag
```

Each type gets a unique tag — a pointer to a distinct static variable:

```zig
var _event_tag: PolyTag = .{};
pub const EVENT_TAG: *const anyopaque = &_event_tag;

var _sensor_tag: PolyTag = .{};
pub const SENSOR_TAG: *const anyopaque = &_sensor_tag;
```

Now you can check identity:

```text
  node.tag == EVENT_TAG   → this is an Event
  node.tag == SENSOR_TAG  → this is a Sensor
```

And recover the concrete type:

```zig
const event = @fieldParentPtr(Event, "poly", node);
```

**Tag identifies class, not instance or role.**

- Every instance of `Event` carries the same `EVENT_TAG` — it says "this is an Event", not "which Event" or "what kind of Event".
- For user-defined types, the user adds a `kind` or `role` field to the struct for per-instance discrimination.
- For infra handles (`MailboxHandle`, `PoolHandle`): the internal structs are private. No fields can be added. Tag identifies the class only.
  - Instance identity is resolved by pointer comparison against known handles.
  - Role is established by protocol: the channel an infra handle arrived on, message ordering, or prior agreement.
- See `matryoshka-api-reference-010.md` § "Tag identity — class, not instance" for the worker-finish-signal and wrapper patterns.

Summary so far:

```text
  Node     = list links
  Tag      = runtime identity (class, not instance)
  PolyNode = Node + Tag
```

### Step 3 — Place (Slot)

The question from Step 2:

> I have a `*PolyNode`. Where is it right now?

Passing raw pointers around leaves the item's place implicit.  
Two components might both think they hold the same item.

**Solution: a slot.**

A `ItemHandle` is a pointer to a PolyNode:

```zig
pub const ItemHandle = *PolyNode;
```

A `Slot` is where a handle lives while you hold it:

```zig
pub const Slot = ?ItemHandle;
```

Two states:

```text
┌─────────────────┐          ┌─────────────────┐
│   Full Slot     │          │   Empty Slot     │
│                 │          │                 │
│   ItemHandle    │          │      null       │
│                 │          │                 │
└─────────────────┘          └─────────────────┘
     You hold it.              You don't hold it.
```

Transfer has a simple rule:

```text
  send:     Full  →  Empty     (you gave it away)
  receive:  Empty →  Full      (you got one)
```

- After send, your slot is null. You cannot use the item.
- After receive, your slot holds a handle. You hold it.
- No ambiguity. No double hold.

At this point:
- Identity is solved (PolyNode).
- Place is explicit (Slot).
- Transfer has clear rules (full ↔ empty).

But there is no mechanism to move items between components yet.

### Step 4 — Transport (Mailbox)

The question from Step 3:

> How do I move an item from one component to another?

A mailbox moves an item between tasks.

- Not messages — the item itself.
- Not copies — the original handle moves.
- Thread-safe — producer and consumer can be on different threads.

```text
  Producer                   Mailbox                   Consumer
  ┌──────────┐              ┌──────────┐              ┌──────────┐
  │          │              │          │              │          │
  │  Slot ───┼── send() ──►│  queue   │◄── recv() ──┼── Slot   │
  │  (→null) │              │          │              │  (→full) │
  │          │              │          │              │          │
  └──────────┘              └──────────┘              └──────────┘

  Producer's slot becomes null.
  Consumer's slot becomes full.
  The handle moved — not copied.
```

Key properties:

- One handle, one place, always.
- The mailbox is temporary storage during transit.
- Send and receive are the only ways to move an item.

### Step 5 — Lifecycle (Pool)

The question from Step 4:

> Items are pre-allocated. After the consumer is done, how do I reuse them?

A pool recycles items.

```text
                    ┌─────────────────────────────────────┐
                    │                                     │
                    ▼                                     │
  ┌──────────┐   get()   ┌──────────┐  work   ┌──────────┐
  │   Pool   │ ────────► │  Slot    │ ──────► │   done   │
  │          │           │  (full)  │         │          │
  └──────────┘           └──────────┘         └──────────┘
                                                   │
                                                put()
                                                   │
                                              back to Pool
```

- `get()` — take a pre-allocated item from the pool.
- Use the item (send through mailboxes, process, transform).
- `put()` — return the item to the pool for reuse.

No allocations. No frees. Items cycle through the system forever.

### Step 6 — Coordination (Master / Select)

The question from Step 5:

> A component receives from a mailbox and gets items from a pool. How does it wait on both?

A master coordinates multiple sources.

```text
  ┌─────────────┐
  │   Mailbox   │──┐
  └─────────────┘  │
                   │    ┌──────────┐     ┌──────────┐
                   ├───►│  Master  │────►│  Select  │── waits for any
                   │    └──────────┘     └──────────┘
  ┌─────────────┐  │
  │    Pool     │──┘
  └─────────────┘
```

- Master registers mailboxes and pools as event sources.
- Select waits on multiple sources simultaneously.
- When any source has an item, the component wakes up and processes it.

This is the final piece.  
The component does not poll. It reacts.

### The full picture

```text
  PolyNode         = identity      (what is it?)
  Tag              = type marker   (which kind?)
  Slot             = place         (who has it?)
  Mailbox          = transport     (move it)
  Pool             = lifecycle     (reuse it)
  Master / Select  = coordination  (wait for it)
```

Each concept answers one question.  
Together they form a complete transfer system.

---

## Chapter 3 — Flows and patterns

Each pattern uses only the concepts from Chapter 2.  
Diagrams show item movement.

### Simple producer-consumer

The simplest pattern.  
One producer, one consumer, one mailbox:

```text
  ┌──────────┐         ┌──────────┐         ┌──────────┐
  │ Producer │         │ Mailbox  │         │ Consumer │
  │          │         │          │         │          │
  │  Slot ───┼─send()─►│  queue   │◄─recv()─┼── Slot   │
  │          │         │          │         │          │
  └──────────┘         └──────────┘         └──────────┘

  1. Producer fills slot with a handle.
  2. Producer sends — slot becomes null.
  3. Consumer receives — slot becomes full.
  4. Consumer processes the item.
```

### Producer-consumer with recycling

Add a pool to avoid allocation:

```text
  ┌──────────┐  get()  ┌──────────┐  send()  ┌──────────┐
  │   Pool   │────────►│ Producer │─────────►│ Mailbox  │
  └──────────┘         └──────────┘          └──────────┘
       ▲                                          │
       │                                       recv()
     put()                                        │
       │                                          ▼
       │               ┌──────────┐          ┌──────────┐
       └───────────────│  return  │◄─────────│ Consumer │
                       └──────────┘          └──────────┘

  1. Producer gets an item from the pool.
  2. Producer fills it, sends through mailbox.
  3. Consumer receives, processes.
  4. Consumer returns the item to the pool.
  5. The item cycles — no allocation, no free.
```

### Pipeline

A chain of processing stages:

```text
  ┌──────────┐  mbox1  ┌──────────┐  mbox2  ┌──────────┐  mbox3  ┌──────────┐
  │ Stage 1  │────────►│ Stage 2  │────────►│ Stage 3  │────────►│ Stage 4  │
  └──────────┘         └──────────┘         └──────────┘         └──────────┘

  Each stage:
    - Receives from upstream mailbox.
    - Processes the item.
    - Sends to downstream mailbox.
    - The item moves to the next stage.
```

### Coordinated service

A component that reacts to multiple sources:

```text
  ┌──────────────┐
  │  work mbox   │────┐
  └──────────────┘    │
                      │     ┌──────────────┐     ┌──────────┐
  ┌──────────────┐    ├────►│   Master     │────►│  Select  │
  │ control mbox │────┤     │              │     │  (wait)  │
  └──────────────┘    │     └──────────────┘     └──────────┘
                      │            │
  ┌──────────────┐    │            ▼
  │  item pool   │────┘     ┌──────────────┐
  └──────────────┘          │   Worker     │
                            │              │
                            │  recv work   │
                            │  get item    │
                            │  process     │
                            │  put item    │
                            │  loop        │
                            └──────────────┘

  Worker waits on all sources simultaneously.
  Wakes up when any source has something.
  Processes, returns resources, waits again.
```

> Real project examples will be added in later revisions.

---

## Chapter 4 — Layer map

Matryoshka is organized in four layers.  
Each layer builds on the previous one.

```text
  Layer 4    matryoshka root      initialization + cleanup
               │
  Layer 3    master               coordination (Select, Futures)
               │
  Layer 2    mailbox    pool      transport + lifecycle
               │         │
  Layer 1    polynode              identity (PolyNode, Tag, Slot)
               │
             std.DoublyLinkedList  Zig standard library
```

### Layer 1 — polynode (identity)

Foundation of the system:

- `PolyNode` — intrusive node with a type tag.
- `ItemHandle` — pointer to a PolyNode.
- `Slot` — nullable handle representing where the item is.
- `PolyTag` — unique type marker.

No dependencies beyond `std.DoublyLinkedList`.

### Layer 2 — mailbox + pool (transport + lifecycle)

Built on Layer 1:

- `mailbox` — thread-safe transport via queues.
- `pool` — item recycling via get/put.

Both operate on `ItemHandle` and `Slot`.  
Both are independent — you can use either without the other.

### Layer 3 — master (coordination)

Built on Layer 2:

- Registers mailboxes and pools as event sources.
- Exposes them to `Io.Select` for concurrent waiting.
- Manages `Future` items for each source.

### Layer 4 — matryoshka root (initialization)

Built on Layer 3:

- Creates and initializes all infrastructure.
- Provides cleanup on shutdown.
- Entry point for applications.

### Dependencies flow down, never up

```text
  Layer 4 depends on Layer 3.
  Layer 3 depends on Layer 2.
  Layer 2 depends on Layer 1.
  Layer 1 depends on std only.

  No layer references a higher layer.
  No circular dependencies.
```

---

## Change log

| Version | Date       | Description |
|---------|------------|-------------|
| 003     | 2026-07-09 | New Mindset ownership-language pass: "ownership"/"owner" replaced with "place"/"hold"/"transfer" per rules-024's src/ comment invariant (an object sits in exactly one place, at any moment); "execution context" replaced with "task". |
| 002     | 2026-07-07 | API 4. Renamed `NodeHandle` → `ItemHandle` throughout — the old name leaked the intrusive-node implementation detail. |
| 001     | 2026-06-24 | First draft — four chapters: prequel, concept progression, flows, layer map |
| 001     | 2026-06-26 | Step 2 (Tag): added tag-identity clarification — class not instance, infra handles, pointer comparison, protocol for role |
