## The model

A Matryoshka system consists of Masters.


> A Master can:
>
> * receive work/alert/chunk/...
> * send work/alert/chunk/...
> * schedule itself
> * cooperate with other Masters
> * borrow shared resources
> * share communication channels
> * share resource pools

Matryoshka mapping:

| Capability          | Primitive                  |
| ------------------- | -------------------------- |
| Receive         | Mailbox                    |
| Send            | Mailbox                    |
| Share communication | Shared Mailbox             |
| Borrow resources    | Pool                       |
| Share resources     | Shared Pool                |
| Heterogeneous data  | Type-erased Mailbox / Pool |

---

> **Imagine your application consists only of independent Masters communicating through mailboxes and borrowing objects from pools.**
>
> If you can picture your system that way, you're already thinking in Matryoshka.

---

* **Master** — the active unit of behavior.
* **Mailbox** — where work arrives.
* **Pool** — where shared resources come from.

Everything else—dispatchers, routers, schedulers, timers, services, actors, pipelines, reactors—is just a Master or a composition of Masters using those three primitives.


### Down to ground

A Master has one input mailbox.

A Master processes one message at a time.

A Master may send messages to any mailbox.

Including its own mailbox.

Masters may share the same mailbox.

A Master may borrow objects from one or more pools.

Pools may be shared by many Masters.

Mailboxes and Pools may store typed or type-erased objects.

Nothing else is required.

---

> **Can you build your system using only these capabilities?**

If the answer is yes, Matryoshka is probably a good fit.

---
