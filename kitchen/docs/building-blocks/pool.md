# Building Blocks — Pool

Everything reusable lives here.

---

## What a Pool does

A Pool hands out objects for reuse instead of forcing a fresh allocation every time.

```text
new()
  ↓
empty pool

get() [pool empty]                get() [pool has items]
  ↓ a fresh item is created          ↓ an item is reused
with caller                        with caller

put() [kept]              put() [destroyed]
  ↓                          ↓
back in the pool          caller frees it

close()
  ↓ every stored item is handed back for the caller to free
```

- `get` hands a handle to the caller — reused if one is free, freshly made otherwise.
- `put` returns the handle — the Pool decides whether to keep it or let it go.
- `close` hands back everything still stored, so nothing leaks.

## A Pool resource is an empty container

Whatever the previous owner wrote has already been consumed or reset by the time you
get an item back — it carries no work intent on its own.

- A Pool resource alone never defines a complete pattern.
- Useful work always needs at least one other input too: a Mailbox message, a
  network read, a timer tick, some shared state.

## An empty Pool is a signal, not an error

- When nothing is free, the caller waits — that's backpressure, not a failure.
- No separate rate limiter, no manual throttling code.
- One event loop can watch "a Mailbox message arrived" and "a Pool item became free"
  side by side. When a worker returns an item, whoever was waiting resumes.

## Why this matters

- Reuse and backpressure come from the same mechanism: a fixed number of slots.
- The constraint is structural — nobody has to remember to check capacity.

---

Next: [Master](master.md) — who coordinates all of this.

See also: [API Reference — Pool](../api/pool.md) for the actual Zig functions.
