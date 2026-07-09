# The System: A Network Print Server

A shared office printer. Three roles.

- **Client** — submits print jobs on behalf of applications.
- **Spooler** — queues and manages jobs.
- **Driver** — talks to the physical printer.

No implementation detail yet. Just what the system must do.

---

## The requirements

- Client submits a print job and receives an immediate acknowledgment.
- Submission never waits for printer availability.
- Jobs are dispatched to the printer in submission order.
- Exactly one party holds a job at any moment.
- No job is shared between the spooler and the printer.
- Each client receives one final result — success, failure, or canceled.
- Result is delivered to a return channel provided at submission time.
- A client can cancel a job at any time.
- Cancel removes the job if it is still queued.
- Cancel reaches the printer before any queued job if the job is already with the printer.
- Shutdown loses no jobs.
- All pending clients receive a canceled result on shutdown.

## The reasoning behind it

Submission and result are separate. A client submits, moves on, and waits for a
result on its own channel — an application should never block on a slow printer.

Ownership moves in a straight line:

- The client creates the job and hands it to the spooler.
- The spooler holds it until it hands it to the driver.
- The driver holds it until it sends the result.
- Nobody shares it.

- The driver needs no locks while printing — it is the only owner.
- The driver needs no progress reporting — it either finishes or fails, and sends
  the result either way. The spooler doesn't need to know which page it's on.

- The spooler needs no status tracking — if the job is in its queue, it's
  responsible. If not, the driver has it.

Readiness is implicit. When the driver finishes a job, it is ready for the next one —
no explicit signal required.

Cancellation is the hard part.

- If the job is still queued, the spooler just removes it.
- If the job has already reached the driver, the cancel has to get there before any job queued behind it — otherwise the driver may start printing the wrong document.
- The cancel has to jump the queue.

**At any moment, whoever holds the job owns the problem.**

## Next

[The same system, built with Matryoshka](print-server-with-matryoshka.md).
