# Building Blocks — Mailbox

Everything communicates.

---

## What a Mailbox does

A Mailbox moves a handle from one owner to another.

```text
Before                           After

sender Slot                      sender Slot
+-------------------+            +-------------------+
|      Handle       |            |       empty        |
+-------------------+            +-------------------+

send  ───────────────────►      Mailbox holds the handle
```

```text
Before                           After

receiver Slot                    receiver Slot
+-------------------+            +-------------------+
|       empty       |            |      Handle        |
+-------------------+            +-------------------+

receive   ◄──────────────────    Receiver holds the handle
```

- Send moves a handle in. Receive moves a handle out.
- The Mailbox never copies the object — it moves the handle to it.
- The Mailbox never inspects what the handle points to. Any PolyNode-based object
  can travel through any Mailbox.

## One owner at a time

- While a handle sits in a Mailbox, the Mailbox owns it — not the sender, not the
  receiver.

- Exactly one party holds the handle at any moment: sender, then Mailbox, then
  receiver.

- No locks needed while a receiver processes what it received — nobody else has it.

## Mailboxes are themselves exchangeable

A Mailbox is built from a `PolyNode`, same as any application object.

- A Mailbox can be sent through another Mailbox.
- A Mailbox can be stored in a Pool.
- A Mailbox can be embedded into a larger structure.

This is how a worker signals "I'm done": it sends its own Mailbox back to whoever is
coordinating it, instead of a separate finished-message.

## Why this matters

- Mailbox and Pool are containers on steroids — the steroid here is ownership
  transfer without copying.

- A design that routes every cross-boundary interaction through Mailboxes never
  needs a shared status table. Whoever holds the handle owns the problem right now.

---

Next: [Pool](pool.md) — how items get reused instead of allocated fresh each time.

See also: [API Reference — Mailbox](../api/mailbox.md) for the actual Zig functions.
