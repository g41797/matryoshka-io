# Matryoshka API Reference — Zig 0.16

Matryoshka is a small ownership-oriented infrastructure toolkit. It provides three independent building blocks:

- **polynode** — ownership identity
- **mailbox** — ownership transport
- **pool** — ownership lifecycle

Applications combine these blocks to create coordinators, workers, services, pipelines, and other higher-level architectures. All objects follow the same ownership rules based on `PolyNode` and `NodeHandle`.

Matryoshka is a system for moving ownership of handles. Everything transported — events, requests, mailboxes, pools — is a `NodeHandle` (`*PolyNode`). A `Slot` (`?NodeHandle`) is where a handle lives while you own it.

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

Every user type embeds a `PolyNode`. A `NodeHandle` is a pointer to that embedded node. Matryoshka does not care what the surrounding type is — it only sees the handle.

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
Clears intrusive link pointers (`prev`, `next` to null).

```zig
pub fn is_linked(n: *PolyNode) bool
```
Returns true if node is currently linked into a list.

### Ownership rule

Tag checks, typed casts, and `@fieldParentPtr` recovery never transfer ownership. These are read-only inspections of an existing node.

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

PolyNode embeds `std.DoublyLinkedList.Node`. Every PolyNode-based item participates in standard `std.DoublyLinkedList` operations — no custom list type, no adapter.

Batch operations like `mailbox.close()`, `mailbox.receive_batch()`, and `pool.put_all()` use plain `std.DoublyLinkedList`. Walk results with `popFirst()` — standard Zig, nothing Matryoshka-specific.

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

MailboxHandle is itself a PolyNode. A mailbox can be sent through another mailbox, stored in pools, or embedded into larger ownership graphs using the same rules as application objects.

### Functions

```zig
pub fn new(io: Io, alloc: std.mem.Allocator) !MailboxHandle
```
Creates a new mailbox. Stores `io` internally.

```zig
pub fn destroy(mbh: MailboxHandle, alloc: std.mem.Allocator) void
```
Frees the mailbox. Must be closed first. Calling destroy on an open mailbox is a programming error (panic).

```zig
pub fn send(mbh: MailboxHandle, m: *Slot) error{Closed}!void
```
Appends handle to tail. Transfers ownership — `m.*` set to null. Cancelable (work path).

```zig
pub fn send_oob(mbh: MailboxHandle, m: *Slot) error{Closed}!void
```
Inserts handle after last OOB handle (FIFO among OOBs, all OOBs before regular handles). Transfers ownership — `m.*` set to null. Cancelable (work path).

```zig
pub fn receive(mbh: MailboxHandle, m: *Slot, timeout_ns: ?u64) (error{ Closed, Timeout } || Cancelable)!void
```
Blocks until handle available. `null` timeout = wait forever. Transfers ownership — `m.*` set to non-null. OOB handles arrive first (front of queue).

```zig
pub fn try_receive(mbh: MailboxHandle, m: *Slot) error{Closed}!bool
```
Non-blocking. Returns true if handle received, false if queue empty.

```zig
pub fn receive_batch(mbh: MailboxHandle) (error{Closed} || Cancelable)!std.DoublyLinkedList
```
Non-blocking. Snapshots entire queue under one lock acquisition. Returns empty `std.DoublyLinkedList` if queue is currently empty — does not wait, does not return error for empty. Resets OOB tracking.

```zig
pub fn close(mbh: MailboxHandle) std.DoublyLinkedList
```
Idempotent. Snapshots remaining handles, broadcasts to wake blocked receivers. Returns remaining handles as list (empty list on second call). Uses `lockUncancelable`. Resets OOB tracking.

```zig
pub fn is_it_you(tag: *const anyopaque) bool
```
Returns true if tag identifies a MailboxHandle.

### Error sets

| Error | Meaning |
|-------|---------|
| `error.Closed` | mailbox was closed via `close()` |
| `error.Timeout` | `timeout_ns` expired (only when non-null) |
| `error.Canceled` | Waiting operation was canceled |

### Integration with std.Io

`mailbox.receive` may be used from tasks spawned through `io.concurrent()`, `Io.Group`, or `Io.Select`. When a mailbox is closed, blocked receivers wake with `error.Closed`. When a task is canceled while blocked in `mailbox.receive`, the operation returns `error.Canceled`. This allows mailbox operations to compose naturally with Zig's `std.Io` concurrency primitives.

### Event source helpers

Mailbox can participate directly in `Io.Select` as an event source. These helpers bridge the blocking API to the Future/Select world.

#### Types

```zig
pub const ReceiveResult = union(enum) {
    item: NodeHandle,
    closed: void,
    timeout: void,
    canceled: void,
};
```

Result carries the handle by value — no cross-thread `*Slot` pointer. When `select.await()` returns `.item`, the caller is sole owner.

#### Functions

```zig
pub fn receive_select(mbh: MailboxHandle, timeout_ns: ?u64) ReceiveResult
```
Adapter from error-union API to `ReceiveResult`. Creates a local `Slot`, calls `receive`, maps the result to the union. Use as a Select event source via `select.concurrent(.tag, mailbox.receive_select, .{mbh, timeout})`.

```zig
pub fn receive_future(mbh: MailboxHandle, timeout_ns: ?u64) ConcurrentError!Io.Future(ReceiveResult)
```
Spawns `receive_select` as a concurrent task using the mailbox's stored `io`. Returns a Future that can be awaited directly, fed to Select, or fed to Group. Returns `error.ConcurrencyUnavailable` on single-threaded backends.

#### Cancel behavior

Cancel never triggers close. On `error.Canceled`, the adapter returns `.canceled` — the mailbox remains open. Closing is the Master's responsibility.

#### When to use

**Inside Matryoshka**: when handles carry ownership, use fan-in — many senders send tagged PolyNodes to one mailbox, Master dispatches on tag. One queue, one ownership model, one shutdown model.

**Bridging to external Io**: use `receive_select` / `receive_future` — mailbox traffic alongside timers, sockets, files, or pool availability in one `Io.Select` loop.

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

PoolHandle is itself a PolyNode. A pool can be sent through a mailbox or embedded into larger ownership graphs using the same rules as application objects.

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
    AlreadyInUse,
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
Creates a new pool. Stores `io` internally.

```zig
pub fn destroy(ph: PoolHandle, alloc: std.mem.Allocator) void
```
Frees the pool. Must be closed first. Calling destroy on an open pool is a programming error (panic).

```zig
pub fn init(ph: PoolHandle, hooks: PoolHooks) !void
```
Registers hooks and tag set. Called once after `new`.

```zig
pub fn get(ph: PoolHandle, tag: *const anyopaque, mode: GetMode, m: *Slot) GetError!void
```
Non-blocking acquisition. Calls `on_get` hook. Transfers ownership — `m.*` set to non-null on success.

```zig
pub fn get_wait(ph: PoolHandle, tag: *const anyopaque, m: *Slot, timeout_ns: ?u64) (GetError || Cancelable || error{Timeout})!void
```
Blocking acquisition. `null` timeout = wait forever. Calls `on_get` hook.

```zig
pub fn put(ph: PoolHandle, m: *Slot) void
```
Returns handle to pool. Calls `on_put` hook (policy decides keep or destroy). Cancel-protected (`lockUncancelable`). If pool is closed, `m.*` stays non-null (caller still owns it).

```zig
pub fn put_all(ph: PoolHandle, list: *std.DoublyLinkedList) void
```
Returns batch of handles to pool. Cancel-protected. Pops from caller's list.

```zig
pub fn close(ph: PoolHandle) void
```
Idempotent. Collects all handles from all per-tag free-lists, calls `on_close` once with the full list. Broadcasts to wake blocked `get_wait` callers. Cancel-protected (`lockUncancelable`).

```zig
pub fn is_it_you(tag: *const anyopaque) bool
```
Returns true if tag identifies a PoolHandle.

### Error sets

| Error | Meaning |
|-------|---------|
| `error.Closed` | pool was closed via `close()` |
| `error.NotAvailable` | `available_only` mode, no stored handle |
| `error.NotCreated` | `on_get` was called but did not return a handle |
| `error.AlreadyInUse` | Entry contract violation: `m.*` was not null on call |
| `error.Timeout` | `timeout_ns` expired (only when non-null, `get_wait` only) |
| `error.Canceled` | Waiting operation was canceled (`get_wait` only) |

### Event source helpers

Pool can participate directly in `Io.Select` as an event source. Pool availability as an event enables the job-pool pattern: worker returns a handle → Master is notified → Master submits new work.

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

Result carries the handle by value — no cross-thread `*Slot` pointer. The `.item` arm hands ownership to the caller: the `get_wait` that produced it has already removed the handle from the pool. Re-spawn the event source only after deciding the handle's fate.

#### Functions

```zig
pub fn get_wait_select(ph: PoolHandle, tag: *const anyopaque, timeout_ns: ?u64) PoolResult
```
Adapter from error-union API to `PoolResult`. Creates a local `Slot`, calls `get_wait`, maps the result to the union. Use as a Select event source via `select.concurrent(.tag, pool.get_wait_select, .{ph, node_tag, timeout})`.

```zig
pub fn get_wait_future(ph: PoolHandle, tag: *const anyopaque, timeout_ns: ?u64) ConcurrentError!Io.Future(PoolResult)
```
Spawns `get_wait_select` as a concurrent task using the pool's stored `io`. Returns a Future. Returns `error.ConcurrencyUnavailable` on single-threaded backends.

#### Cancel behavior

Cancel never triggers close. On `error.Canceled`, the adapter returns `.canceled` — the pool remains open. Closing is the Master's responsibility.

### Hook discipline

- Hooks run outside the pool mutex
- `on_get`: must either leave `m.* == null` (creation failed) OR set `m.*` to a valid node (created or reinitialized). No other state is permitted
- `on_put`: set `m.*` to null = destroy. Leave non-null = keep in pool
- `on_close`: receives `*std.DoublyLinkedList`, walks via `popFirst()`, frees each handle
- Do NOT call pool functions on the same pool from inside hooks (contract violation, not deadlock — hooks run outside the mutex, but calling back collapses the infrastructure/policy separation)

---

## matryoshka (root)

```zig
pub const polynode = @import("polynode.zig");
pub const mailbox = @import("mailbox.zig");
pub const pool = @import("pool.zig");
```

No generic `dispose`. Use `mailbox.destroy` and `pool.destroy` directly. Application types destroy themselves.

---

## Master (Layer 4) — intentionally not part of the API

There is no `master` module. There is no `Master` struct. This is by design.

Master is an architectural role — the coordination boundary that owns and composes the lower layers. Applications build Masters from:

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

---

## Cancel contract summary

| Function | Cancelable | Cancel-protected | Notes |
|----------|-----------|-----------------|-------|
| `mailbox.send` | yes | no | work path |
| `mailbox.send_oob` | yes | no | work path |
| `mailbox.receive` | yes | no | primary cancel point |
| `mailbox.try_receive` | yes | no | non-blocking |
| `mailbox.receive_batch` | yes | no | non-blocking |
| `mailbox.close` | no | yes (`lockUncancelable`) | cleanup |
| `pool.get` | yes | no | non-blocking |
| `pool.get_wait` | yes | no | primary cancel point |
| `pool.put` | no | yes (`lockUncancelable`) | cleanup |
| `pool.put_all` | no | yes (`lockUncancelable`) | cleanup |
| `pool.close` | no | yes (`lockUncancelable`) | cleanup |
| `mailbox.receive_select` | yes | no | adapter — inherits from `mailbox.receive` |
| `mailbox.receive_future` | yes | no | spawns `receive_select` concurrently |
| `pool.get_wait_select` | yes | no | adapter — inherits from `pool.get_wait` |
| `pool.get_wait_future` | yes | no | spawns `get_wait_select` concurrently |

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

The following are programming errors (panic):

- Double insertion — pushing a linked node into a list
- Use after free — using a node after its memory was freed
- Destroying an open mailbox or pool — must close first
- Corrupted or invalid tag — tag does not match any known type

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

Mailbox and Pool are independent — neither depends on the other. Both depend only on the ownership model. Master is where they are combined.

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
