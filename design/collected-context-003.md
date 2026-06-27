# Collected Context for Matryoshka Zig Implementation (v003)

v003 adds: Stages 4-5 completion findings, owner API changes (null-safe pool.put, PolyHelper comptime selection), Slot Rule, new idiom patterns, INTR 1 plan. All open items carried forward. Supersedes v002.

---

## Key Paths

### Zig 0.16 Standard Library
- `Io.zig`: `/home/g41797/dev/langs/zig-x86_64-linux-0.16.0/lib/std/Io.zig`
- `Io/` directory: `/home/g41797/dev/langs/zig-x86_64-linux-0.16.0/lib/std/Io/`
- `DoublyLinkedList.zig`: `/home/g41797/dev/langs/zig-x86_64-linux-0.16.0/lib/std/DoublyLinkedList.zig`

### Odin Matryoshka (reference implementation)
- Root: `/home/g41797/dev/root/github.com/g41797/matryoshka`
- Core files: `polynode.odin`, `mailbox.odin`, `pool.odin`, `poolhooks.odin`, `dispose.odin`
- Docs: `kitchen/docs/` — layer deepdives, quickrefs, API reference, addendums. Read for idiom patterns.
- Examples: `examples/block1/` through `examples/block4/`
- Tests: `tests/block1/` through `tests/block4/`

### Legacy Mailbox Repo
- Root: `/home/g41797/dev/root/github.com/g41797/mailbox`
- Source: `src/mailbox.zig` — `TypeErasedMailbox`, `condition_waitTimeout` helper

### Tofu Project (scaffolding reference)
- Root: `/home/g41797/dev/root/github.com/g41797/tofu`
- Build: `build.zig` — separate modules (library, test, recipes)
- Test helpers: `src/ampe/helpers.zig` — `RunTasks`, `AutoArrayHashMap`, `SleepMlsec`, `semaphore_waitTimeout`

### Reference Projects
- ICE agent (Io.Select + concurrent pattern): `/home/g41797/Downloads/media-protocols-master/src/ice/agent.zig`

### Working Folder
- `/home/g41797/dev/root/github.com/g41797/matryoshka-zig/design/`
- Current API reference: `matryoshka-api-reference-010.md` — source of truth. Wins over all other sources.
- Current plan: `matryoshka-zig-implementation-plan-010.md`
- This document: `collected-context-003.md`

---

## Current Implementation State (2026-06-27)

### Stages complete
- Stage 0 — Infrastructure. DONE.
- Stage 0.5 — Re-partition scenarios. DONE.
- Stage 1.a — PolyNode impl + tests. DONE.
- Stage 1.b — PolyNode examples. DONE.
- Stage 2.a — Mailbox impl + tests. DONE.
- Stage 2.b — Mailbox examples. DONE.
- Stage 2.5 — Pre-Stage-3 fixes. DONE.
- Stage 3 — Pool (impl + tests + examples). DONE.
- Stage 4.a — Infra as Items: tests. DONE.
- Stage 4.b — Infra as Items: examples. DONE.
- Stage 5.a — Master: tests (task2 scenarios 1-2). DONE.
- Stage 5.b — Master: examples (task2 scenarios 17-24). DONE.

### Test count: 107/107 passing (all 4 optimization modes, 3 cross-compile targets)

### Next
- INTR 1 — Slot-based programming retrofit (api reference revision + example retrofit)
- Stage 6 — Cancellation + Shutdown (task2 scenarios 3-16)

---

## Repo Folder Structure (current)

```
matryoshka-zig/
├── build.zig
├── build.zig.zon
├── README.md
├── src/
│   ├── matryoshka.zig
│   ├── polynode.zig
│   ├── mailbox.zig
│   ├── pool.zig
│   └── internal/
│       └── cond_timeout.zig
├── helpers/
│   ├── helpers.zig
│   └── types.zig
├── tests/
│   ├── matryoshka_tests.zig
│   ├── layer1_polynode.zig
│   ├── layer1_examples.zig
│   ├── layer2_mailbox.zig
│   ├── layer2_examples.zig
│   ├── layer3_pool.zig
│   ├── layer3_examples.zig
│   ├── layer4_infra.zig
│   ├── layer4_examples.zig
│   └── layer4_master.zig
├── examples/
│   ├── examples.zig
│   ├── layer1/
│   ├── layer2/
│   ├── layer3/
│   └── layer4/
├── kitchen/
│   ├── build_and_test_debug.sh
│   ├── build_and_test_all.sh
│   └── build_cross_debug.sh
└── design/
    ├── STATUS.md
    └── *.md
```

---

## Source Files — Current State

### src/polynode.zig

Key types: `PolyTag`, `PolyNode`, `NodeHandle`, `Slot`, `reset`, `is_linked`.

`PolyHelper(T)` branches at comptime on `@hasDecl(T, "no_create_destroy")`:

**Without `no_create_destroy`** — full helper:
- `TAG: *const anyopaque` — unique type identifier
- `isIt(tag) bool` — tag comparison
- `cast(node) ?*T` — safe cast, returns null on tag mismatch
- `mustCast(node) *T` — cast, panics on mismatch
- `init(self: *T) void` — sets `self.poly.tag = TAG`
- `create(allocator, slot: *Slot) !void` — allocates, zero-inits, calls init, writes to slot. Asserts `slot.* == null`.
- `destroy(allocator, slot: *Slot) void` — no-op if `slot.* == null`. Asserts node not linked. Clears slot before freeing.

**With `no_create_destroy = void{}`** — reduced helper (no create/destroy):
- `TAG`, `isIt`, `cast`, `mustCast`, `init` only

`_Mailbox` and `_Pool` declare `const no_create_destroy = void{}` — they own their own lifecycle. Infrastructure handles must not be created/destroyed via PolyHelper.

### helpers/types.zig

```zig
pub const Event = struct { poly: polynode.PolyNode = .{}, code: i32 = 0 };
pub const Sensor = struct { poly: polynode.PolyNode = .{}, value: f64 = 0.0 };
pub const ShutdownCommand = struct { poly: polynode.PolyNode = .{} };
pub const Timer = struct { poly: polynode.PolyNode = .{} };

pub const EventPolyHelper = polynode.PolyHelper(Event);
pub const SensorPolyHelper = polynode.PolyHelper(Sensor);
pub const ShutdownCommandPolyHelper = polynode.PolyHelper(ShutdownCommand);
pub const TimerPolyHelper = polynode.PolyHelper(Timer);
```

None of these declare `no_create_destroy` — all get full PolyHelper (create + destroy available).

### helpers/helpers.zig

```zig
pub fn expect(comptime err: anyerror, ok: bool, comptime msg: []const u8) anyerror!void

pub fn clearList(list: *std.DoublyLinkedList) void   // walk + discard nodes

pub fn freeItem(poly: *polynode.PolyNode, alloc: std.mem.Allocator) void
// tag-dispatch free: Event, Sensor, Timer, ShutdownCommand

pub fn freeList(list: *std.DoublyLinkedList, alloc: std.mem.Allocator) void
// walk list + freeItem each node

pub fn createByTag(tag: *const anyopaque, alloc: std.mem.Allocator, slot: *polynode.Slot) void
// Event branch: uses EventPolyHelper.create (NEW PATTERN)
// Sensor branch: still uses old manual alloc+init+slot-assign (NEEDS UPDATE in INTR 1.c)
```

`AlwaysCreateCtx` and `CappedPoolCtx` — pool hook context structs for common patterns.

### INTR 1.c will add
- Finish `createByTag`: Sensor branch → `SensorPolyHelper.create`
- Add `destroyByTag(tag, alloc, slot)` using PolyHelper.destroy per type

---

## THE SLOT RULE

**Never overwrite a non-null slot.**

- All slots start as `var m: Slot = null`.
- All acquisition APIs assert `slot.* == null` on entry. Writing to a non-null slot = programming error = panic.
- Transfer clears the slot: `m.* = null`. After transfer, the slot is null again.
- Cleanup defers are safe to place before acquisition because all cleanup operations (pool.put, PolyHelper.destroy) are no-ops on null slots.
- Applies universally: pool get/put, mailbox receive, heap allocation, every combination.
- Violation = item loss or double-free.

### Why all acquisition APIs assert null

`pool.get`, `mailbox.receive`, `PolyHelper.create` — all check:
```zig
std.debug.assert(slot.* == null);
```
Overwriting a non-null slot would lose the previous item with no error signal. The assert catches this immediately.

### Why cleanup operations accept null

`pool.put`, `PolyHelper.destroy` — all check null and return early:
```zig
if (m.* == null) return;
```
This makes defer-before-acquisition safe. If acquisition fails (or item is transferred), the defer fires as a no-op.

---

## API Changes (Owner-Applied, not yet in api-reference-010)

### pool.put — null slot is now a no-op

```zig
pub fn put(ph: PoolHandle, m: *polynode.Slot) void {
    if (m.* == null) return;
    // ...
}
```

Old precondition `m.* != null` removed. `pool.put` with null slot is a silent no-op. This makes defer-put-early safe.

### PolyHelper.create and PolyHelper.destroy — new functions

`create(allocator, slot: *Slot) !void`
- Asserts `slot.* == null`.
- Allocates T, zero-inits, calls init, sets `slot.* = &object.poly`.

`destroy(allocator, slot: *Slot) void`
- If `slot.* == null`, returns (no-op).
- Asserts node not linked.
- Clears slot to null before freeing memory.

Both exist only on the full PolyHelper (no `no_create_destroy` declaration).

---

## New Idiom Patterns

These patterns are the canonical way to write safe ownership code in Matryoshka Zig. All examples must use them.

### Pattern 1 — defer-put-early (pool item)

```zig
var m: Slot = null;
defer pool.put(ph, &m);              // safe: no-op if m == null
try pool.get(ph, TAG, .new_only, &m);
// ... work with m ...
// transfer: m = null → defer fires as no-op
```

Place `defer pool.put` BEFORE `pool.get`. If get fails, defer is a no-op. If item is transferred, defer is a no-op. If not transferred, defer recycles.

### Pattern 2 — defer-destroy-early (heap item via PolyHelper)

```zig
var m: Slot = null;
defer types.EventPolyHelper.destroy(allocator, &m);   // safe: no-op if m == null
try types.EventPolyHelper.create(allocator, &m);
// ... work with m ...
// transfer: m = null → defer fires as no-op
```

### Pattern 3 — defer for received mailbox item

```zig
var m: Slot = null;
defer if (m) |poly| helpers.freeItem(poly, allocator);
try mailbox.receive(mbh, &m, null);
// dispatch on m.?.tag, process
// no transfer → defer frees item
```

### Pattern 4 — transfer clears the slot

```zig
var m: Slot = null;
defer pool.put(ph, &m);
try pool.get(ph, TAG, .new_only, &m);
// ...
try mailbox.send(mbh, &m);   // send clears m.* = null
// now defer fires as no-op — item transferred, not recycled
```

---

## Stage 4 Key Findings

- Tag identifies class (type), not instance or role.
- Infra handles (`_Mailbox`, `_Pool` are private) have no user-visible fields.
- Instance identity: pointer comparison. Role: protocol between sender and receiver.
- Documented in `matryoshka-api-reference-010.md` § "Tag identity — class, not instance".
- Infrastructure handles are PolyNodes and can be transported as items (scenario 95-96 examples).

---

## Stage 5 Key Findings

- `Io.Threaded.init` returns `Io.Threaded` directly — no `try`.
- `group.concurrent` worker must return exactly `error{Canceled}!void`. Non-Canceled errors caught inside worker.
- `mailbox.receive` returns `error.Closed` immediately on closed mailbox, even if items remain. "Close as signal" only works after all items consumed. Use ShutdownCommand sentinel for pipelines.
- `helpers.freeItem` handles all 4 types: Event, Sensor, Timer, ShutdownCommand.
- AI-sh scan finding: "undelivered" in `minimal_master.zig:39` — natural technical vocabulary, not AI-speak. Owner decided: keep.

---

## INTR 1 Plan Summary

Stage between 5 and 6. Three sub-stages. No stage number — named INTR 1.

### INTR 1.a — collected-context-003.md (Sonnet)
- This document. Complete context for Opus.

### INTR 1.b — api-reference-011 (Opus)
New sections to add to api-reference-010:

**Slot-based programming** section:
- The slot rule
- Why acquisition APIs assert null
- ASCII diagram: slot lifecycle
- ASCII diagram: ownership transfer clearing the slot

**Cooperative cleanup patterns** section:
- Pattern 1: defer-put-early
- Pattern 2: defer-destroy-early
- Pattern 3: defer for mailbox receive
- Pattern 4: transfer clears the slot
- Each: 3-5 line code snippet + one-line explanation

**PolyHelper.create and PolyHelper.destroy** section:
- Signatures
- Preconditions
- When to use vs manual alloc+init

**Updates to existing sections:**
- `pool.put` — remove old `m.* != null` precondition, add null no-op note
- `PolyHelper` — add `no_create_destroy` comptime selection explanation

**Diagrams are mandatory.** ASCII. Human-readable.

### INTR 1.c — code retrofit (Sonnet)
- Finish `createByTag` in helpers.zig
- Add `destroyByTag` in helpers.zig
- Audit all examples, apply defer-early patterns where missing
- Kitchen scripts, AI-sh scan, session log
- Plan version 011

---

## Process Rules (summary for quick reference)

- Show intent before execution. Owner approves before code changes.
- Coding style: LE imports, explicit types, explicit dereference, stdlib first, errdefer/defer for cleanup.
- Doc style: short sentences, bullets, no AI-sh words, no "drain" (use clear/reset/empty).
- Banned words scan after every stage that changes *.md or *.zig.
- Tests before examples (N.a then N.b). No mixing.
- Kitchen scripts for verification: `build_and_test_debug.sh`, `build_and_test_all.sh`, `build_cross_debug.sh`.
- No git operations. Owner handles git.
- Plan versioning: new file after each completed stage.
- SPDX headers in src/ files — never remove.

---

## Key Decisions (carried from v002)

### Layer Boundaries
- Layers 1-3: pure building blocks, no Master, no cancellation.
- Layer 4 (Master): coordination concept, where `std.Io` concurrency primitives live.
- "Master" must not appear in layers 1-3.

### Cancellation is New
- Odin has no cancellation.
- Zig 0.16 `Io.Mutex.lock()` and `Io.Condition.wait()` return `Cancelable!void`.
- `error.Canceled` is never remapped to `error.Closed`.

### Master is a Concept, not a Type
- Master = coordination boundary: owns mailbox, lifecycle policy, cancellation policy, worker coordination.
- Not a mandatory struct or PolyNode.
- Layer 4 examples demonstrate Master patterns, not a Master type.

### Mailbox Is Optional
- Pool + Io is a complete coordination model.
- Mailbox is right for: fan-in from independent senders, pipelines, heterogeneous ownership streams.
- Valid combinations: PolyNode only, PolyNode+Mailbox, PolyNode+Pool, full stack.

### Cancel Never Triggers Close
- `error.Canceled` is Io scheduler operation.
- `mailbox.close` / `pool.close` is Master/application decision.
- Cancel/close separation applies equally to Mailbox and Pool.

### Mailbox Design
- `send_oob` replaces Odin interrupt — FIFO among OOBs via oob_count + oob_last.
- `close` / `put` / `put_all` use `lockUncancelable`.
- `mailbox.send` is cancelable (work path). `pool.put` is cancel-protected (cleanup path).
- `_Mailbox` and `_Pool` store `io: Io` (managed pattern — infrastructure, not container).

### Slot/NodeHandle naming
- `MayItem` (Odin) → `Slot` (Zig): `?NodeHandle` = `?*PolyNode`
- `MailboxHandle = NodeHandle`, `PoolHandle = NodeHandle`

---

## Io Primitives Summary (Layer 4 / Master)

### Task spawning
- `io.async(fn, args)` → `Future(Result)` — may run synchronously; portable
- `io.concurrent(fn, args)` → `ConcurrentError!Future(Result)` — guarantees concurrency
- `Io.Threaded.init(gpa, .{})` → `Io.Threaded` (no try)
- `Future.cancel(io)` — injects `error.Canceled` + awaits
- `Future.await(io)` — waits without cancellation

### Groups and Select
- `Io.Group` — unordered task set; workers return `Cancelable!void` (exactly `error{Canceled}!void`)
- `group.cancel(io)` — cancels all + awaits (returns void)
- `group.await(io)` — waits for all
- `Io.Select(U)` — Group + Queue; typed tasks, await whichever finishes first as tagged union

### Cancellation mechanics
- `error.Canceled` from next cancellation point only — does NOT re-signal
- `io.recancel()` — re-arms for next point (cleanup-then-propagate)
- `io.checkCancel()` — pure cancellation point for CPU-bound work
- `Mutex.lockUncancelable(io)` / `Condition.waitUncancelable` — per-operation uncancelable

### Verified call syntax (from Session 10)
- `var threaded = std.Io.Threaded.init(gpa, .{});` — no try
- `const io: std.Io = threaded.io();`
- `const fut = try io.concurrent(workerFn, .{args});`
- Worker: `fn workerFn(args: T) error{Canceled}!void`
- `group.concurrent` worker: exactly `error{Canceled}!void`

---

## Scenario → Stage Map

| Stage | task1 | task2 |
|-------|-------|-------|
| 1 | 1-17, 21-25 | — |
| 2 | 18, 26-62 | — |
| 3 | 19-20, 63-92 | — |
| 4 | 18-20 (re-proves), 93-96 | — |
| 5 | — | 1-2, 17-24 |
| INTR 1 | — | — (retrofit only) |
| 6 | — | 3-16 |
| 7 | — | 25-31, 42-56 |
| 8 | — | 32-41, 57-61 |

---

## Open Items (carried forward)

- **5** — condition_waitTimeout workaround: Zig 0.16 `Io.Condition` has no `waitTimeout`. Workaround in reference mailbox, copied as private helper for `_Mailbox` and `_Pool`. May become unnecessary if upstream fixes codeberg/zig#31278.
- **6** — `Io.Evented` backend not tested. Design targets both Threaded and Evented; testing is Threaded-only.
- **10** — Which Layer 2-3 examples need real threads vs `global_single_threaded`. Thread-based tests need `Io.Threaded.init` without cancellation testing.
- **11** — Panic test style in Zig 0.16. `@panic` aborts process. No `std.testing.expectPanic`. Scenarios 15-16 (task1) deferred.
- **12** — Real-Io examples (task2 scenarios 25-30) require working layers 1-3 first. Integration tests, not unit tests.

---

## Proposals — all resolved

All 27 proposals from v002 remain applied. No new proposals in v003.

See v002 proposals table for the full list (Proposals 1-27).

---

## External Resources

- Release notes: https://ziglang.org/download/0.16.0/release-notes.html#IO-as-an-Interface
- Zig 0.16 Io source: `Io.zig` (3461 lines), `Io/Threaded.zig` (18902 lines)
- Key line ranges: Future (1176-1206), Group (1218-1303), Select (1367-1537), Mutex (1587-1651), Condition (1653-1763), io.concurrent (2365-2389)
