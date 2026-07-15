# Story: Network Print Server — Requirements

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

---

Next: [Matryoshka Translation](translation.md).
