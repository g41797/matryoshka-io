# Story: Network Print Server — Matryoshka Translation

Previous: [Requirements](requirements.md).

Requirement: Non-blocking submission.

Matryoshka:
- `PrintJob` — PolyNode-based struct.
- `mailbox.send(job_queue, &job_slot)`.
- Ownership transferred immediately.
- Client continues.

---

Requirement: Ordered dispatch.

Matryoshka:
- Spool Master.
- `job_queue` mailbox.
- `mailbox.receive` — FIFO preserved.

---

Requirement: Result notification.

Matryoshka:
- `reply_mbh: MailboxHandle` embedded in `PrintJob`.
- Printer Master sends `PrintResult` directly to `job.reply_mbh`.
- Spool Master not involved.

---

Requirement: Exclusive ownership during printing.

Matryoshka:
- Printer Master holds one job.
- Single slot: `var slot: Slot = null`.
- No shared access. No locks.

---

Requirement: Cancellation with priority.

Matryoshka:
- `mailbox.send_oob(job_queue, &cancel_slot)`.
- `CancelSignal` arrives at queue front.
- If job already forwarded: `mailbox.send_oob(printer_inbox, &cancel_slot)`.

---

Requirement: Clean shutdown.

Matryoshka:
- Spool Master closes `job_queue`.
- Remaining jobs in `printer_inbox` receive canceled result via `job.reply_mbh`.
- Closes `printer_inbox`.
- Printer Master gets `error.Closed` on next receive. Exits.

---

**The central insight.**

At any moment, whoever holds the job owns the problem.

- No shared status table.
- No polling.
- No ownership ambiguity.
- Responsibility follows location.

Where the job is.

- Job in `job_queue` — Spool Master owns it.
- Job in `printer_inbox` — moving between Masters.
- Job in Printer slot — Printer Master owns it.
- Result in `reply_mbh` — client owns the outcome.

---

Next: [Flow Diagram](flow.md).
