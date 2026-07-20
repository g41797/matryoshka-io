# The Same System, Built With Matryoshka

Read [the system](print-server-the-system.md) first. Every requirement below maps to  
one of the four Matryoshka concepts: `PolyNode`, `Mailbox`, `Pool`, `Master`.

---

**Non-blocking submission.**

- `PrintJob` — a `PolyNode`-based struct.
- `mailbox.send(job_queue, &job_slot)`.
- Ownership transfers immediately. The client continues.

**Ordered dispatch.**

- A Spool Master owns the `job_queue` mailbox.
- `mailbox.receive` preserves FIFO order.

**Result notification.**

- Each `PrintJob` embeds `reply_mbh: MailboxHandle` — the client's return channel.
- The Printer Master sends `PrintResult` directly to `job.reply_mbh`.
- The Spool Master is not involved in delivering the result.

**Exclusive ownership during printing.**

- The Printer Master holds one job in a single slot: `var slot: Slot = null`.
- No shared access. No locks.

**Cancellation with priority.**

- `mailbox.send_oob(job_queue, &cancel_slot)` — an out-of-band send that arrives at
  the front of the queue.

- If the job has already been forwarded to the printer:
  `mailbox.send_oob(printer_inbox, &cancel_slot)`.

**Clean shutdown.**

- The Spool Master closes `job_queue`.
- Remaining jobs in `printer_inbox` get a canceled result sent to `job.reply_mbh`.
- `printer_inbox` closes. The Printer Master gets `error.Closed` on its next
  receive and exits.

---

## Where the job lives, who owns it

- Job in `job_queue` — the Spool Master owns it.
- Job in `printer_inbox` — moving between Masters.
- Job in the Printer Master's slot — the Printer Master owns it.
- Result in `reply_mbh` — the client owns the outcome.

No shared status table. No polling. No ownership ambiguity.  
Responsibility follows location.

## Flow

```text
  [ Client A ]  [ Client B ]  [ Client C ]
       │               │               │
       │ mailbox.send(job_queue, &job_slot)        ← non-blocking, ownership transferred
       │ mailbox.send_oob(job_queue, &cancel_slot) ← OOB: arrives at queue front
       └───────────────┴───────────────┘
                       │
                       V
           SPOOL MASTER (mailbox.receive loop on job_queue)
           ├── on PrintJob:
           │     mailbox.send(printer_inbox, &job_slot)   ← forward, ownership transferred
           │
           ├── on CancelSignal (OOB — arrives before regular jobs):
           │     job still in job_queue?
           │       yes → remove, send PrintResult{.canceled} → job.reply_mbh
           │     job already forwarded to printer_inbox?
           │       yes → mailbox.send_oob(printer_inbox, &cancel_slot)
           │       no  → job already printing; Printer Master handles it
           │
           V
           [ printer_inbox ]
                       │
                       V
           PRINTER MASTER (mailbox.receive loop on printer_inbox)
           ├── on PrintJob:
           │     var slot: Slot = job           ← exclusive ownership, no locks
           │     print(job)                     ← process pages
           │     send PrintResult{.ok} → job.reply_mbh
           │     destroy job
           │
           ├── on CancelSignal (OOB — arrives before next regular job):
           │     if currently printing: abort
           │     send PrintResult{.canceled} → current_job.reply_mbh
           │     destroy current job
           │
           V
           [ reply_mbh — per client ]
                       │
                       V
              Client calls mailbox.receive(reply_mbh, ...)
              receives PrintResult{.ok} or PrintResult{.canceled} or PrintResult{.failed}

  Shutdown sequence:
  Spool Master closes job_queue
    → walks printer_inbox close list: sends .canceled to each job.reply_mbh
    → closes printer_inbox
  Printer Master finishes current job
    → gets error.Closed on next receive
    → exits
```
