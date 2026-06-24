# Matryoshka API Reference — Zig 0.16

> Function descriptions in this reference serve as the source for `///` Zig doc comments in the implementation.

Matryoshka is a small ownership-oriented infrastructure toolkit.
It provides three independent building blocks:

- **polynode** — ownership identity
- **mailbox** — ownership transport
- **pool** — ownership lifecycle

Applications combine these blocks to create coordinators, workers, services, pipelines, and other higher-level architectures.
All objects follow the same ownership rules based on `PolyNode` and `NodeHandle`.

Matryoshka is a system for moving ownership of handles.
Everything transported — events, requests, mailboxes, pools — is a `NodeHandle` (`*PolyNode`).
A `Slot` (`?NodeHandle`) is where a handle lives while you own it.

Module: `@import("matryoshka")`

---

## Ownership model

```text
Slot (holds a handle)            Empty Slot

+-------------------+            +-------------------+
|                   |            |                   |
|    NodeHandle     |            |       null        |
|                   |            |                   |
+-------------------+            +-------------------+

  Slot = ?NodeHandle               Slot = null
```

### send — ownership moves out

```text
Before                           After

sender Slot                      sender Slot
+-------------------+            +-------------------+
|    NodeHandle     |            |       null        |
+-------------------+            +-------------------+

mailbox.send(mbh, &slot)  ───►      Mailbox owns NodeHandle
```

### receive — ownership moves in

```text
Before                           After

receiver Slot                    receiver Slot
+-------------------+            +-------------------+
|       null        |            |    NodeHandle     |
+-------------------+            +-------------------+

mailbox.receive(mbh, &slot, null)   Receiver owns NodeHandle
```

### What is a NodeHandle?

Every user type embeds a `PolyNode`.
A `NodeHandle` is a pointer to that embedded node.
Matryoshka does not care what the surrounding type is — it only sees the handle.

```text
User object                      Infrastructure object

+------------------+             +------------------+
|      Event       |             |     Mailbox      |
|------------------|             |------------------|
| poly: PolyNode   |             | poly: PolyNode   |
| code: i32        |             | ...              |
+------------------+             +------------------+
        |                                |
        v                                v
   NodeHandle                     MailboxHandle
   (*PolyNode)                    (= NodeHandle)
```

All handles are `NodeHandle`. Specialized names are aliases:

```text
NodeHandle = *PolyNode
    ├── MailboxHandle = NodeHandle
    ├── PoolHandle    = NodeHandle
    └── (any user handle)

Slot = ?NodeHandle
```

---

## polynode

Types and functions for ownership identity.

```zig
const polynode = @import("matryoshka").polynode;

// typical usage:
var slot: polynode.Slot = &event.poly;   // owns the node
slot = null;                              // releases ownership
```

### Types

```zig
pub const PolyTag = struct { _: u8 = 0 };

pub const PolyNode = struct {
    node: std.DoublyLinkedList.Node,
    tag:  *const anyopaque,
};

pub const NodeHandle = *PolyNode;
pub const Slot = ?NodeHandle;
```

### Functions

```zig
pub fn reset(n: *PolyNode) void
```
- Clears intrusive link pointers (`prev`, `next` to null).

```zig
pub fn is_linked(n: *PolyNode) bool
```
- Returns true if node is currently linked into a list.

### Ownership rule

Tag checks, typed casts, and `@fieldParentPtr` recovery never transfer ownership.
These are read-only inspections of an existing node.

### Defining user types

User types embed `poly: PolyNode` and define a unique tag address for runtime identity:

```zig
pub const Event = struct {
    poly: PolyNode,
    code: i32,
};

var _event_tag: PolyTag = .{};
pub const EVENT_TAG: *const anyopaque = &_event_tag;
```

Tag check, typed cast, and initialization are user code — see `tests/helpers/types.zig` for the pattern.

### stdlib compatibility

PolyNode embeds `std.DoublyLinkedList.Node`.
Every PolyNode-based item participates in standard `std.DoublyLinkedList` operations — no custom list type, no adapter.

Batch operations like `mailbox.close()`, `mailbox.receive_batch()`, and `pool.put_all()` use plain `std.DoublyLinkedList`.
Walk results with `popFirst()` — standard Zig, nothing Matryoshka-specific.

---

## mailbox

Ownership transport between execution contexts.

```zig
const mailbox = @import("matryoshka").mailbox;

// typical usage:
var slot: polynode.Slot = &event.poly;
try mailbox.send(inbox, &slot);              // slot is now null
try mailbox.receive(inbox, &slot, null);     // slot is now non-null
```

### Types

```zig
pub const MailboxHandle = NodeHandle;
```

MailboxHandle is itself a PolyNode.
A mailbox can be:
- sent through another mailbox
- stored in pools
- embedded into larger ownership graphs

Same rules as application objects.

### Functions

```zig
pub fn new(io: Io, alloc: std.mem.Allocator) !MailboxHandle
```
- Creates a new mailbox.
- Stores `io` internally.

```zig
pub fn send(mbh: MailboxHandle, m: *Slot) error{Closed}!void
```
- Appends handle to tail.
- Transfers ownership — `m.*` set to null.
- Assert:
  - `mailbox.is_it_you(mbh.*.tag)`
  - `m.* != null`
  - `!polynode.is_linked(m.*)`

```zig
pub fn send_oob(mbh: MailboxHandle, m: *Slot) error{Closed}!void
```
- Inserts handle after last OOB handle.
- FIFO among OOBs, all OOBs before regular handles.
- Transfers ownership — `m.*` set to null.
- Assert:
  - `mailbox.is_it_you(mbh.*.tag)`
  - `m.* != null`
  - `!polynode.is_linked(m.*)`

```zig
pub fn receive(mbh: MailboxHandle, m: *Slot, timeout_ns: ?u64) (error{ Closed, Timeout } || Cancelable)!void
```
- Blocks until handle available.
- `null` timeout = wait forever.
- Transfers ownership — `m.*` set to non-null.
- OOB handles arrive first (front of queue).
- Assert:
  - `mailbox.is_it_you(mbh.*.tag)`
  - `m.* == null`

```zig
pub fn try_receive(mbh: MailboxHandle, m: *Slot) error{Closed}!bool
```
- Non-blocking.
- Returns true if handle received, false if queue empty.
- Assert:
  - `mailbox.is_it_you(mbh.*.tag)`
  - `m.* == null`

```zig
pub fn receive_batch(mbh: MailboxHandle) (error{Closed} || Cancelable)!std.DoublyLinkedList
```
- Non-blocking.
- Snapshots entire queue under one lock acquisition.
- Returns empty `std.DoublyLinkedList` if queue is currently empty — does not wait, does not return error for empty.
- Resets OOB tracking.
- Assert:
  - `mailbox.is_it_you(mbh.*.tag)`

```zig
pub fn close(mbh: MailboxHandle) std.DoublyLinkedList
```
- Idempotent.
- Snapshots remaining handles, broadcasts to wake blocked receivers.
- Returns remaining handles as list (empty list on second call).
- Uses `lockUncancelable`.
- Resets OOB tracking.
- Assert:
  - `mailbox.is_it_you(mbh.*.tag)`

```zig
pub fn destroy(mbh: MailboxHandle, alloc: std.mem.Allocator) void
```
- Frees the mailbox.
- Must be closed first.
- Calling destroy on an open mailbox is a programming error (panic).
- Assert:
  - `mailbox.is_it_you(mbh.*.tag)`

```zig
pub fn is_it_you(tag: *const anyopaque) bool
```
- Returns true if tag identifies a MailboxHandle.

### Error sets

| Error | Meaning |
|-------|---------|
| `error.Closed` | Mailbox was closed via `close()` |
| `error.Timeout` | `timeout_ns` expired (only when non-null) |
| `error.Canceled` | Waiting operation was canceled |

### Event source helpers

Mailbox can participate in `Io.Select` as an event source via `Future`.
The helper converts blocking `receive` calls to Future results.

`mailbox.receive` handles cancel and close correctly in concurrent tasks:
- When a mailbox is closed, blocked receivers wake with `error.Closed`.
- When a task is canceled, the operation returns `error.Canceled`.

#### Types

```zig
pub const ReceiveResult = union(enum) {
    item: NodeHandle,
    closed: void,
    timeout: void,
    canceled: void,
};
```

Result carries the handle by value — no cross-thread `*Slot` pointer.
When `select.await()` returns `.item`, the caller is sole owner.

#### Functions

```zig
pub fn receive_future(mbh: MailboxHandle, timeout_ns: ?u64) ConcurrentError!Io.Future(ReceiveResult)
```
- Spawns a concurrent task that:
  - Creates a local `Slot`
  - Calls `receive`
  - Converts the result to `ReceiveResult`
- Uses the mailbox's stored `io`.
- Returns a Future that can be:
  - Awaited directly
  - Passed to `Io.Select`
  - Passed to `Io.Group`
- Returns `error.ConcurrencyUnavailable` on single-threaded backends.

#### Cancel behavior

- Cancel never triggers close.
- On `error.Canceled`, the adapter returns `.canceled` — the mailbox remains open.
- Closing is the Master's responsibility.

#### When to use

**Inside Matryoshka**: when handles carry ownership, use fan-in.
- Many senders send tagged PolyNodes to one mailbox.
- Master dispatches on tag.
- One queue, one ownership model, one shutdown model.

**Bridging to external Io**: use `receive_future`.
- Mailbox traffic alongside timers, sockets, files, or pool availability in one `Io.Select` loop.

### Advanced: OOB ordering

```
send(R1), send(R2):       [R1, R2]                oob=0
send_oob(O1):             [O1, R1, R2]            oob=1
send(R3):                 [O1, R1, R2, R3]        oob=1
send_oob(O2):             [O1, O2, R1, R2, R3]   oob=2
receive → O1:             [O2, R1, R2, R3]        oob=1
receive → O2:             [R1, R2, R3]            oob=0
```

---

## pool

Lifecycle management with hooks.

```zig
const pool = @import("matryoshka").pool;

// typical usage:
var slot: polynode.Slot = null;
try pool.get(ph, EVENT_TAG, .available_or_new, &slot);   // slot is now non-null
pool.put(ph, &slot);                                      // slot is now null (if kept)
```

### Types

```zig
pub const PoolHandle = NodeHandle;
```

PoolHandle is itself a PolyNode.
A pool can be:
- sent through a mailbox
- embedded into larger ownership graphs

Same rules as application objects.

```zig
pub const GetMode = enum {
    available_or_new,    // use stored handle if available, otherwise call on_get to create
    new_only,            // always call on_get with m.* == null to create fresh
    available_only,      // use stored handle only; if empty, return error.NotAvailable
};

pub const GetError = error{
    Closed,
    NotAvailable,
    NotCreated,
};
```

### PoolHooks

```zig
pub const PoolHooks = struct {
    ctx:      *anyopaque,
    tags:     []const *const anyopaque,
    on_get:   *const fn (ctx: *anyopaque, tag: *const anyopaque, in_pool_count: usize, m: *Slot) void,
    on_put:   *const fn (ctx: *anyopaque, in_pool_count: usize, m: *Slot) void,
    on_close: *const fn (ctx: *anyopaque, list: *std.DoublyLinkedList) void,
};
```

### Functions

```zig
pub fn new(io: Io, alloc: std.mem.Allocator) !PoolHandle
```
- Creates a new pool.
- Stores `io` internally.

```zig
pub fn destroy(ph: PoolHandle, alloc: std.mem.Allocator) void
```
- Frees the pool.
- Must be closed first.
- Calling destroy on an open pool is a programming error (panic).
- Assert:
  - `pool.is_it_you(ph.*.tag)`

```zig
pub fn init(ph: PoolHandle, hooks: PoolHooks) !void
```
- Registers hooks and tag set.
- Called once after `new`.
- Assert:
  - `pool.is_it_you(ph.*.tag)`
  - Hooks tags not empty, each tag not null.
  - Pool not already closed.

```zig
pub fn get(ph: PoolHandle, tag: *const anyopaque, mode: GetMode, m: *Slot) GetError!void
```
- Non-blocking acquisition.
- Calls `on_get` hook.
- Transfers ownership — `m.*` set to non-null on success.
- Assert:
  - `pool.is_it_you(ph.*.tag)`
  - `m.* == null`
  - Pool initialized.
  - Tag registered.

```zig
pub fn get_wait(ph: PoolHandle, tag: *const anyopaque, m: *Slot, timeout_ns: ?u64) (GetError || Cancelable || error{Timeout})!void
```
- Blocking acquisition.
- `null` timeout = wait forever.
- Calls `on_get` hook.
- Assert:
  - `pool.is_it_you(ph.*.tag)`
  - `m.* == null`
  - Pool initialized.
  - Tag registered.

```zig
pub fn put(ph: PoolHandle, m: *Slot) void
```
- Returns handle to pool.
- Cancel-protected (`lockUncancelable`).
- **Open pool**:
  - Calls `on_put` hook.
  - Policy decides keep or destroy.
  - Keep: `m.*` stays non-null, pool owns it.
  - Destroy: `m.*` set to null.
- **Closed pool**:
  - Returns immediately, no hook call.
  - `m.*` stays non-null — caller retains ownership.
- Assert:
  - `pool.is_it_you(ph.*.tag)`
  - `m.* != null`
  - `!polynode.is_linked(m.*)`

```zig
pub fn put_all(ph: PoolHandle, list: *std.DoublyLinkedList) void
```
- Returns batch of handles to pool.
- Cancel-protected.
- Pops from caller's list.
- Assert:
  - `pool.is_it_you(ph.*.tag)`
  - Each node's tag registered in pool's tag set.

```zig
pub fn close(ph: PoolHandle) void
```
- Idempotent.
- Collects all handles from all per-tag free-lists.
- Calls `on_close` once with the full list.
- Broadcasts to wake blocked `get_wait` callers.
- Cancel-protected (`lockUncancelable`).
- Assert:
  - `pool.is_it_you(ph.*.tag)`

```zig
pub fn is_it_you(tag: *const anyopaque) bool
```
- Returns true if tag identifies a PoolHandle.

### Error sets

| Error | Meaning |
|-------|---------|
| `error.Closed` | Pool was closed via `close()` |
| `error.NotAvailable` | `available_only` mode, no stored handle |
| `error.NotCreated` | `on_get` was called but did not return a handle |
| `error.Timeout` | `timeout_ns` expired (only when non-null, `get_wait` only) |
| `error.Canceled` | Waiting operation was canceled (`get_wait` only) |

### Event source helpers

Pool can participate in `Io.Select` as an event source via `Future`.
The helper converts blocking `get_wait` calls to Future results.

`pool.get_wait` handles cancel and close correctly in concurrent tasks:
- When a pool is closed, blocked callers wake with `error.Closed`.
- When a task is canceled, the operation returns `error.Canceled`.

Pool availability as an event enables the job-pool pattern:
- Worker returns a handle.
- Master is notified.
- Master submits new work.

#### Types

```zig
pub const PoolResult = union(enum) {
    item: NodeHandle,
    closed: void,
    timeout: void,
    canceled: void,
    not_created: void,
};
```

Result carries the handle by value — no cross-thread `*Slot` pointer.
The `.item` arm hands ownership to the caller: the `get_wait` that produced it has already removed the handle from the pool.
Re-spawn the event source only after deciding the handle's fate.

#### Functions

```zig
pub fn get_wait_future(ph: PoolHandle, tag: *const anyopaque, timeout_ns: ?u64) ConcurrentError!Io.Future(PoolResult)
```
- Spawns a concurrent task that:
  - Creates a local `Slot`
  - Calls `get_wait`
  - Converts the result to `PoolResult`
- Uses the pool's stored `io`.
- Returns a Future that can be:
  - Awaited directly
  - Passed to `Io.Select`
  - Passed to `Io.Group`
- Returns `error.ConcurrencyUnavailable` on single-threaded backends.

#### Cancel behavior

- Cancel never triggers close.
- On `error.Canceled`, the adapter returns `.canceled` — the pool remains open.
- Closing is the Master's responsibility.

### Hook discipline

- Hooks run outside the pool mutex.
- `on_get`:
  - Must either leave `m.* == null` (creation failed) OR set `m.*` to a valid node (created or reinitialized).
  - No other state is permitted.
- `on_put`:
  - Set `m.*` to null = destroy.
  - Leave non-null = keep in pool.
- `on_close`:
  - Receives `*std.DoublyLinkedList`.
  - Walks via `popFirst()`, frees each handle.
- Do NOT call pool functions on the same pool from inside hooks.
  - Contract violation, not deadlock — hooks run outside the mutex, but calling back collapses the infrastructure/policy separation.

---

## matryoshka (root)

```zig
pub const polynode = @import("polynode.zig");
pub const mailbox = @import("mailbox.zig");
pub const pool = @import("pool.zig");
```

No generic `dispose`.
Use `mailbox.destroy` and `pool.destroy` directly.
Application types destroy themselves.

---

## Master (Layer 4) — intentionally not part of the API

There is no `master` module.
There is no `Master` struct.
This is by design.

Master is an architectural role — the coordination boundary that owns and composes the lower layers.
Applications build Masters from:

| What | Where it comes from |
|------|-------------------|
| Transport | `mailbox.MailboxHandle` — one or more mailboxes |
| Lifecycle | `pool.PoolHandle` + `pool.PoolHooks` — handle reuse and policy |
| Memory | `std.mem.Allocator` — who allocates and frees |
| Scheduling | `std.Io` — passed to `mailbox.new` and `pool.new` |
| Worker coordination | `io.concurrent()` → `Future`, or `Io.Group` |
| Cancellation | `Future.cancel(io)` or `group.cancel(io)` |
| Application state | Domain-specific — whatever the subsystem needs |

Both mailbox and pool are optional. Valid combinations:

```text
PolyNode only                        ownership without infrastructure
PolyNode + Mailbox                   ownership + transport
PolyNode + Pool                      ownership + lifecycle
PolyNode + Pool + Io.Select          lifecycle + event sources (no mailbox)
PolyNode + Mailbox + Pool            transport + lifecycle
PolyNode + Mailbox + Pool + Io.Select   full stack
```

A Master may be:
```zig
const Server = struct { inbox: mailbox.MailboxHandle, pool: pool.PoolHandle, ... };
const Scheduler = struct { pool: pool.PoolHandle, ... };  // no mailbox
const Pipeline = struct { stages: [3]mailbox.MailboxHandle, ... };
fn main(init: std.process.Init) !void { ... }
```

Matryoshka provides the building blocks. The application assembles them.

### Event sources

In `std.Io`, an event source is anything that produces a `Future`.
`Io.Select` multiplexes multiple Futures and returns the first one that completes.

Typical event sources:

```text
  Timer ──────► Future(void)  ──┐
  Socket read ─► Future([]u8) ──┼──► Io.Select ──► Master dispatch
  File I/O ───► Future([]u8) ──┘
```

A blocking operation becomes an event source by wrapping it in `io.concurrent()`:
- The operation runs in a spawned task.
- The task produces a `Future`.
- The `Future` is passed to `Io.Select`.
- `select.await()` returns the first completed result.
- Master handles the result and re-arms the source if needed.

Matryoshka uses this pattern to make mailbox and pool into event sources:

```text
  receive_future ──► Future(ReceiveResult) ──┐
  get_wait_future ─► Future(PoolResult)    ──┼──► Io.Select ──► Master dispatch
  Timer ───────────► Future(void)          ──┤
  Socket read ─────► Future([]u8)          ──┘
```

Mailbox and pool event sources follow the same `Future` → `Io.Select` pattern as any other `std.Io` source.
See `mailbox.receive_future` and `pool.get_wait_future` for details.

---

## Cancel indicator

A function is cancelable if and only if its return type includes `Cancelable` in the error union.
The signature is the single source of truth.

If `Cancelable` is not in the return type, the function is not cancelable.

## Cancel contract summary

| Function | Cancelable | Cancel-protected | Notes |
|----------|-----------|-----------------|-------|
| `mailbox.send` | no | no | non-blocking |
| `mailbox.send_oob` | no | no | non-blocking |
| `mailbox.receive` | yes | no | primary cancel point |
| `mailbox.try_receive` | no | no | non-blocking |
| `mailbox.receive_batch` | yes | no | non-blocking |
| `mailbox.close` | no | yes (`lockUncancelable`) | cleanup |
| `pool.get` | no | no | non-blocking |
| `pool.get_wait` | yes | no | primary cancel point |
| `pool.put` | no | yes (`lockUncancelable`) | cleanup |
| `pool.put_all` | no | yes (`lockUncancelable`) | cleanup |
| `pool.close` | no | yes (`lockUncancelable`) | cleanup |
| `mailbox.receive_future` | yes | no | spawns `receive` concurrently |
| `pool.get_wait_future` | yes | no | spawns `get_wait` concurrently |

---

## Ownership lifecycle

```
FREE       — allocated, not in any system
IN_FLIGHT  — owned by user code (Slot non-null)
HELD       — owned by infrastructure (in mailbox queue or pool free-list)
```

| Operation | Before → After |
|-----------|---------------|
| `mailbox.send` | IN_FLIGHT → HELD |
| `mailbox.receive` | HELD → IN_FLIGHT |
| `pool.get` | HELD → IN_FLIGHT |
| `pool.put` (keep) | IN_FLIGHT → HELD |
| `pool.put` (destroy) | IN_FLIGHT → FREE |
| `mailbox.close` | HELD → returned to caller |
| `pool.close` | HELD → passed to on_close |

---

## Contract violations

The following are programming errors.
Checked via `std.debug.assert` (active in Debug and ReleaseSafe, removed in ReleaseFast and ReleaseSmall):

- **Wrong handle type** — passing a PoolHandle where MailboxHandle is expected, or vice versa.
  - Checked via `is_it_you` on every API call.
- **Non-empty slot on receive/get** — slot must be null before receiving or getting a handle.
- **Linked node on send/put** — node must not be linked into a list before transfer.
- **Foreign tag** — pool operation with a tag not registered in the pool's tag set.
- **Uninitialized pool** — calling get/get_wait before init.
- **Double insertion** — pushing a linked node into a list.
- **Corrupted or invalid tag** — tag does not match any known type.

The following are unconditional panics (all build modes):

- **Destroying an open mailbox or pool** — must close first.
- **Use after free** — using a node after its memory was freed.

---

## Layer dependencies

```
             Layer 4
             Master
                |
      +---------+---------+
      |                   |
   Layer 2            Layer 3
   Mailbox              Pool
      |                   |
      +---------+---------+
                |
            Layer 1
           Ownership
```

Mailbox and Pool are independent — neither depends on the other.
Both depend only on the ownership model.
Master is where they are combined.

Valid combinations:
- Layer 1 only — ownership without infrastructure
- Layer 1 + Layer 2 — ownership + transport, no lifecycle
- Layer 1 + Layer 3 — ownership + lifecycle, no transport
- Layer 1 + Layer 2 + Layer 3 + Io — full stack (Master)

---

## Change log

| Version | Date | Changes |
|---------|------|---------|
| 001 | 2026-06-20 | Initial API reference (Proposal 8) |
| 002 | 2026-06-23 | Proposal 27: `MayItem` → `Slot`, `*PolyNode` → `NodeHandle`. Visual ownership model added to intro. `MailboxHandle = NodeHandle`, `PoolHandle = NodeHandle`. All "item" language updated to "handle" in descriptions. |
| 003 | 2026-06-23 | Proposal 28: Validation/assert specifications. `std.debug.assert` on every API function. `AlreadyInUse` removed from `GetError` (contract violation, not runtime error). Contract Violations section expanded. |
| 004 | 2026-06-23 | Proposal 29: `pool.put` open/closed behavior clarified. Proposal 30: `receive_select` and `get_wait_select` removed — `Future` composes directly with `Io.Select`, dedicated Select adapters are unnecessary API surface. |
| 005 | 2026-06-24 | Proposal 31: Reformat for readability and `///` doc comment use. Cancel indicator rule. Cancel table corrected. Event source concept added to Master with diagrams. Mailbox Integration section merged into Event source helpers. Informal terms cleaned up. |

---

## Change manifest (005) — for downstream propagation

### Readability reformat (Proposal 31)

- All function descriptions reformatted: one fact per bullet, nested sub-bullets for asserts and lists.
- Descriptions are now `///` Zig doc comment ready.
- Added doc-comment source note in document header.

### Event source concept added to Master

- New subsection "Event sources" in Master section.
- ASCII diagram: general `Future` → `Io.Select` → dispatch pattern.
- Second diagram: mailbox and pool as event sources alongside timers and sockets.
- Explains how blocking operations become event sources via `io.concurrent()`.

### Mailbox "Integration with std.Io" merged into "Event source helpers"

- Removed standalone "Integration with std.Io" section.
- Cancel/close behavior moved into "Event source helpers" intro.
- Removed vague "compose with concurrency primitives" sentence.

### Pool event source intro updated

- Added cancel/close behavior parallel to mailbox.
- Consistent structure between mailbox and pool event source sections.

### Cancel indicator rule added

- New section "Cancel indicator" before "Cancel contract summary".
- Rule: a function is cancelable if and only if its return type includes `Cancelable`.

### Cancel contract table corrected

| Function | Was | Now | Reason |
|----------|-----|-----|--------|
| `mailbox.send` | Cancelable: yes | Cancelable: no | Signature has no `Cancelable` |
| `mailbox.send_oob` | Cancelable: yes | Cancelable: no | Signature has no `Cancelable` |
| `mailbox.try_receive` | Cancelable: yes | Cancelable: no | Signature has no `Cancelable` |
| `pool.get` | Cancelable: yes | Cancelable: no | Signature has no `Cancelable` |

### False annotations removed

- `send` description: "Cancelable (work path)." removed.
- `send_oob` description: "Cancelable (work path)." removed.

### Informal terms cleaned up

| Was | Now |
|-----|-----|
| "fed to `Io.Select`" | "passed to `Io.Select`" |
| "bridges the blocking API to the Future world" | "converts blocking calls to Future results" |
| "maps the result to" | "converts the result to" |

---

## Change manifest (004) — for downstream propagation

### pool.put behavior clarified (Proposal 29)

- `put` description split into open/closed paths
- **Open pool**: calls `on_put` hook, policy decides keep or destroy
- **Closed pool**: returns immediately, no hook call, caller retains ownership
- No signature change — `put` remains `void` return (defer-compatible)

### Select adapters removed (Proposal 30)

| Removed | Replacement |
|---------|-------------|
| `mailbox.receive_select` | `mailbox.receive_future` (Future composes with Select directly) |
| `pool.get_wait_select` | `pool.get_wait_future` (Future composes with Select directly) |

- `receive_future` description updated — no longer references `receive_select`
- `get_wait_future` description updated — no longer references `get_wait_select`
- Cancel contract summary: 2 rows removed (`receive_select`, `get_wait_select`), 2 rows updated
- "When to use" section: `receive_select` reference removed
- Rationale: `Future` is the fundamental `Io` abstraction. It composes with `Io.Select`, `Io.Group`, and plain `await`. A dedicated Select adapter adds API surface and couples Matryoshka to a specific coordination pattern without additional capability.

---

## Change manifest (003) — for downstream propagation

### New asserts added

| Function | Asserts |
|----------|---------|
| `mailbox.send` | `is_it_you(mbh)`, `m.* != null`, `!is_linked(m.*)` |
| `mailbox.send_oob` | `is_it_you(mbh)`, `m.* != null`, `!is_linked(m.*)` |
| `mailbox.receive` | `is_it_you(mbh)`, `m.* == null` |
| `mailbox.try_receive` | `is_it_you(mbh)`, `m.* == null` |
| `mailbox.receive_batch` | `is_it_you(mbh)` |
| `mailbox.close` | `is_it_you(mbh)` |
| `mailbox.destroy` | `is_it_you(mbh)` |
| `pool.destroy` | `is_it_you(ph)` |
| `pool.init` | `is_it_you(ph)`, hooks tags not empty, each tag not null, not closed |
| `pool.get` | `is_it_you(ph)`, `m.* == null`, initialized, tag registered |
| `pool.get_wait` | `is_it_you(ph)`, `m.* == null`, initialized, tag registered |
| `pool.put` | `is_it_you(ph)`, `m.* != null`, `!is_linked(m.*)` |
| `pool.put_all` | `is_it_you(ph)`, each node tag registered |
| `pool.close` | `is_it_you(ph)` |

### Errors removed

- `error.AlreadyInUse` removed from `GetError` and pool error sets table
- Non-empty slot is now a contract violation (`std.debug.assert`), not a runtime error

### Contract violations section changes

- Split into `std.debug.assert` (Debug/ReleaseSafe) and unconditional panic categories
- Added: wrong handle type, non-empty slot, linked node, foreign tag, uninitialized pool
- Moved: destroy-on-open and use-after-free to unconditional panic

### Principle

Errors for runtime conditions (Closed, Timeout, NotAvailable, NotCreated, Canceled). Asserts for contract violations (wrong type, wrong state, programming bugs).
