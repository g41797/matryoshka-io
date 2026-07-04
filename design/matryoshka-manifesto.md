# Manifesto

A Matryoshka system consists of **Masters**.

A Master can:

* receive job/alert/chunk/...
* send job/alert/chunk/...
* cooperate with other Masters
* borrow shared resources
* share communication channels
* share resource pools

A Master may also participate in an Io flow.

## Matryoshka mapping

| Capability          | Primitive                  |
| ------------------- | -------------------------- |
| Receive             | Mailbox                    |
| Send                | Mailbox                    |
| Share communication | Shared Mailbox             |
| Borrow resources    | Pool                       |
| Share resources     | Shared Pool                |
| Heterogeneous data  | Type-erased Mailbox / Pool |

---

Everything else

- Dispatchers
- Routers
- Schedulers
- Timers
- Services
- Actors
- Pipelines
- Reactors

 is a Master, or a composition of Masters.

...


## Down to earth

A Master has one input mailbox.

A Master processes one message at a time.

A Master may send a message to any mailbox.

Including its own.

Multiple Masters may share one mailbox.

A Master may borrow objects from one or more pools.

Pools may be shared by many Masters.

Mailboxes and Pools may contain typed or type-erased objects.

Nothing else is required.

---

## A simple question

Can you describe your application using only:

* Masters
* Mailboxes
* Pools

If the answer is **yes**, you're already thinking in Matryoshka.

---
