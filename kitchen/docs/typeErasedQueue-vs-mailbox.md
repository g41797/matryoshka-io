# TypeErasedQueue vs Mailbox

| `std.Io.TypeErasedQueue`                        | Matryoshka Mailbox                                         |
| ----------------------------------------------- | ---------------------------------------------------------- |
| Queue owns storage                              | Queue owns only synchronization                            |
| Elements copied into queue                      | Existing objects moved into queue                          |
| Bounded capacity                                | Unbounded transport                                        |
| Backpressure inside queue                       | Backpressure outside queue (Pool/application)              |
| Queue == storage + synchronization + scheduling | Mailbox == synchronization + ownership transfer            |
| Producers may wait for space                    | Producers only wait for mutex/receiver, never for capacity |
| Consumer receives copied value                  | Consumer receives ownership of object                      |

This is almost opposite philosophies.

---

## TypeErasedQueue is a synchronization primitive

Its purpose is

> "I have N slots. Coordinate access to them."

Therefore it naturally has

* waiting producers
* waiting consumers
* capacity
* per-waiter conditions
* wake one producer when space appears
* wake one consumer when data appears

Everything revolves around **slots**.

Objects are secondary.

---

## Mailbox is a transport primitive

Matryoshka says

> "Object already exists."

```
allocate
    ↓
send
    ↓
receive
    ↓
destroy / reuse
```

Mailbox never creates storage.

It never owns capacity.

It only changes ownership.

That is a much narrower responsibility.

---

## Therefore Pool becomes the backpressure mechanism

Instead of

```
Producer
        ↓
 bounded queue
        ↓
Consumer
```

Matryoshka says

```
Producer
     ↓
Pool ---> object
     ↓
Mailbox
     ↓
Consumer
     ↓
Pool
```

If Pool is empty...

Producer waits.

Mailbox doesn't care.

That separation is elegant.

---

## This is actually a stronger architecture

Instead of one object doing

* synchronization
* storage
* capacity
* allocation policy

you have

Mailbox

* synchronization
* ownership transfer

Pool

* lifecycle
* capacity
* reuse

Allocator

* memory

Master

* scheduling

Each component has one responsibility.

---

## About waiter lists

You mentioned another important difference.

TypeErasedQueue likely keeps something conceptually like

```
waiting_putters
waiting_getters
```

Each waiter owns its own Condition.

That is a common implementation for bounded queues.

Because the queue must decide

```
who may put?

who may get?

who wakes next?
```

---

Mailbox doesn't have producer admission.

Only receiver blocking.

Therefore its state is much smaller.

Conceptually

```
list
closed
condition
mutex
```

Nothing else.

That simplicity is one of its strengths.

---

## Should Mailbox adopt TypeErasedQueue ideas?

Only selectively.

Some ideas are universally good:

* minimize time under mutex
* avoid unnecessary broadcasts
* careful wake-up ordering
* good cancellation handling
* reduce contention

Those are implementation improvements.

But I would **not** copy architectural ideas such as:

* bounded capacity
* waiting producer lists
* slot management
* embedded storage
* copying values

because they solve a different problem.

---

## One thing I would study carefully

There is one area where `TypeErasedQueue` may still contain useful implementation techniques:

* cancellation-safe waiter management
* avoiding lost wakeups
* fairness under heavy contention
* lock ordering
* cache locality
* minimizing broadcasts
* handling many blocked receivers efficiently

These are implementation techniques, not architectural decisions.

---

### Bottomn line

| Component         | Responsibility                                            |
| ----------------- | --------------------------------------------------------- |
| **Mailbox**       | Move ownership of objects between execution contexts      |
| **Pool**          | Regulate availability and reuse of objects                |
| **Allocator**     | Allocate and free memory                                  |
| **Master**        | Coordinate the system, scheduling, and application policy |
| **PolyNode/Slot** | Represent transportable ownership                         |

The **Mailbox is not really a queue** in the architectural sense.

Internally it uses a queue (a `std.DoublyLinkedList`), but that's an implementation detail.

Architecturally it is an **ownership transport**.

That's why API is:

```zig
mbox.send(...)
mbox.receive(...)
```

not

```zig
enqueue(...)
dequeue(...)
```

The semantics are different:

* A queue usually stores values.
* A mailbox transfers ownership of existing objects.


* **PolyNode/Slot** — the transferable object.
* **Mailbox** — transports ownership.
* **Pool** — controls when transferable objects are available.
* **Allocator** — controls memory.
* **Master** — orchestrates the application.

TypeErasedQueue must coordinate three resources:

* items
* free slots
* waiters

Mailbox coordinates only one:

* ownership

Everything else belongs elsewhere:

* Pool       -> availability
* Allocator  -> memory
* Io         -> scheduling
* Mailbox    -> ownership transfer
