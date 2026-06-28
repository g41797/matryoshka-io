# Matryoshka Foreign Advices 002

## 1. API Reference Analysis

### 1.1 `pool.put_all` Atomicity Contradiction
**Problem**: The thread-safety contract table states that `pool.put_all` "Batch is atomic". However, the function description for `put_all` states: "Transfer is not atomic with respect to close(). If the pool closes mid-batch, items already transferred are passed to on_close; items not yet transferred remain in the caller's list."
**Advice/Fix**: Resolve this direct contradiction. Either `put_all` acquires the pool lock once for the entire batch (making it atomic with respect to `close()`), or it acquires the lock per item (non-atomic). If it is truly atomic, the description should be updated to reflect that. If it is non-atomic, the thread-safety table must be updated to clarify that it's thread-safe but the batch transfer itself is not atomic.

### 1.2 The `pool.put` Closed Pool Leak (Missing Fallback Defer)
**Problem**: The `pool.put` function on a closed pool returns immediately and leaves `slot.*` non-null, forcing the caller to retain ownership. However, the "Cooperative cleanup patterns" (Pattern 1) only shows `defer pool.put(ph, &slot);`. If the pool is closed, `pool.put` leaves the slot non-null, and since there is no secondary cleanup `defer`, the item will silently leak.
**Advice/Fix**: Update Pattern 1 in the API reference to show the double-defer pattern required for full safety:
```zig
var slot: Slot = null;
defer EventPolyHelper.destroy(alloc, &slot); // Fallback cleanup for closed pool
defer pool.put(ph, &slot);                   // Primary cleanup (clears slot on success)
```
Alternatively, change `pool.put` to automatically destroy the item if the pool is closed, eliminating the need for the fallback defer.

### 1.3 `pool.get_wait` Timeout Error Inconsistency
**Problem**: The API reference says `pool.get_wait` with `timeout_ns = 0` returns `error.Timeout`, and explicitly notes it is "equivalent to get with available_only". However, `pool.get` with `available_only` returns `error.NotAvailable`.
**Advice/Fix**: Harmonize the error semantics. If they are logically equivalent, they should return the same error (e.g., `error.NotAvailable` for a zero-timeout on `get_wait`), or the documentation should explicitly explain why the error type diverges for the exact same logical condition.

### 1.4 `ReceiveResult` and the Slot Rule
**Problem**: The Slot rule strongly asserts that "Transfer clears the slot: `slot.* = null`". However, the event-source helpers like `receiveResult` and `getWaitResult` bypass the `*Slot` pattern entirely by returning the item inside a union (`ReceiveResult.item`), without taking a slot pointer as an argument.
**Advice/Fix**: Add a small clarification to the "Slot-based programming" section explaining that the event-source helpers (`receiveResult`, `getWaitResult`) are an intended exception to the slot-pointer rule, as they transfer ownership via the union value rather than a slot pointer.

---

## 2. Tests and Examples Analysis

### 2.1 Outdated Examples Using `receive_select` and `get_wait_select`
**Problem**: In `task2-examples-001.md`, numerous scenarios (25, 26, 27, 28, 31, 42, 43, 44, 45, 46, 47, and 48) refer to `mailbox.receive_select` and `pool.get_wait_select`. However, the API Reference Change Manifest (004) explicitly states: "Select adapters removed (Proposal 30)". 
**Advice/Fix**: Update the `task2-examples-001.md` scenarios to reflect the new `receiveResult` and `getWaitResult` APIs used with `select.concurrent` (e.g., `select.concurrent(.inbox, mailbox.receiveResult, .{mbh, null})`).

### 2.2 Flawed Logic in Task 2 Test Scenario 8
**Problem**: Scenario 8 states: "pool.put on closed pool — Worker holds item when pool.close fires. pool.put returns item to caller (Slot stays non-null). Worker disposes item via on_close hook."
**Contradiction**: The worker cannot dispose of the item "via on_close hook" because `on_close` is executed by the thread calling `pool.close()`, and it only iterates over items currently in the free-list. Items held in-flight by the worker are missed by `on_close`.
**Advice/Fix**: Rewrite Scenario 8 to clarify that the worker itself must manually free the item (e.g., via `PolyHelper.destroy`) after `pool.put` returns and leaves the slot non-null.

### 2.3 Clarification Needed for `std.DoublyLinkedList.popFirst()`
**Problem**: Task 1 Test Scenario 42 correctly notes: "DoublyLinkedList does NOT clear links on pop — caller must call polynode.reset before checking is_linked." 
**Advice/Fix**: This is a critical insight that should be promoted to the API reference. Under the `stdlib compatibility` section, add a warning that walking a returned `std.DoublyLinkedList` (e.g. from `mailbox.close`) via `popFirst()` leaves stale `prev`/`next` pointers. Users must call `polynode.reset(poly)` on each popped node before it can be safely transferred again or checked with `is_linked`.

---

## 3. Implementation Bugs

### 3.1 `pool.get_wait` Condition Variable Bug (Lost Signal on Multiple Tags)
**Problem**: The `_Pool` implementation uses a single `Io.Condition` variable (`cond`) for the entire pool. When `pool.put` is called for a specific tag, it calls `p.cond.signal(io)`, which wakes exactly *one* waiting thread. 

If multiple threads are waiting on different tags:
- Thread A calls `get_wait` for Tag A.
- Thread B calls `get_wait` for Tag B.
- `pool.put` is called for Tag B.
- `cond.signal()` wakes Thread A (spurious wakeup).
- Thread A checks Tag A, finds it empty, and goes back to sleep.
- The signal is now lost. Thread B remains blocked indefinitely even though the item for Tag B is available in the pool.

**Advice/Fix**: Change `p.*.cond.signal(io)` to `p.*.cond.broadcast(io)` inside `pool.put`. This will wake all waiting threads, allowing them to independently check their respective tags.

> **Note**: The system architect explicitly prefers fixing this via `p.cond.broadcast(io)` rather than implementing per-tag condition variables. The reasoning is that high thread contention (many threads simultaneously blocked on `pool.get_wait` at the same time) is unrealistic for the intended architecture, making the minimal "thundering herd" overhead of a broadcast perfectly acceptable and structurally simpler.
