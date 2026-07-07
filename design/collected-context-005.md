# Collected Context for Matryoshka Zig Implementation (v005)

v005 holds project state only: stages, test counts, slot rule, idiom patterns, Io primitives, bug fixes, open items, key decisions. Supersedes v004.
Change from v004: API 4 renamed `NodeHandle` → `ItemHandle` — the old name
leaked the intrusive-node implementation detail. No other content changed.

Model and rules moved to permanent docs:
- [matryoshka-model-001.md](matryoshka-model-001.md) — thinking model, three-category model, story structure.
- [rules-001.md](rules-001.md) — coding, doc, and process rules.
- [patterns-002.md](patterns-002.md) — reusable coding patterns.

---

## Key Paths

### Zig 0.16 Standard Library
- `Io.zig`: `/home/g41797/dev/langs/zig-x86_64-linux-0.16.0/lib/std/Io.zig`
- `Io/` directory: `/home/g41797/dev/langs/zig-x86_64-linux-0.16.0/lib/std/Io/`
- `DoublyLinkedList.zig`: `/home/g41797/dev/langs/zig-x86_64-linux-0.16.0/lib/std/DoublyLinkedList.zig`

### Odin Matryoshka (reference implementation)
- Root: `/home/g41797/dev/root/github.com/g41797/matryoshka`
- Core files: `polynode.odin`, `mailbox.odin`, `pool.odin`, `poolhooks.odin`, `dispose.odin`
- Docs: `kitchen/docs/` — layer deepdives, quickrefs, API reference, addendums
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
- `/home/g41797/dev/root/github.com/g41797/matryoshka-io/design/`
- Current API reference: `matryoshka-api-reference-015.md` — source of truth. Wins over all other sources.
- Current plan: `matryoshka-io-implementation-plan-018.md` (slim, state-only; rules in `rules.md`)
- This document: `collected-context-004.md`

---

## Current Implementation State (2026-06-28)

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
- Stage 5.a — Master: tests. DONE.
- Stage 5.b — Master: examples. DONE.
- INTR 1 — Slot-based programming retrofit. DONE.
- Stage 6 — Cancellation + Shutdown. DONE.
- INTR 2 — Thread-safe hooks + multi-thread example. DONE.
- Stage 7.a — Event sources: implementation. DONE.
- INTR 3 — ASCII ownership diagrams retrofit. DONE.
- Stage 7.b — Event sources: examples. DONE.
- INTR 4 — Bug fixes + doc corrections. DONE.
- Stage 8 — Mailbox-less patterns + cross-layer. DONE.

### Test count: 160/160 passing (all 4 optimization modes, 3 cross-compile targets)

### Next
- INTR 5 — Stories infrastructure + pilot

---

## Repo Folder Structure (current)

```
matryoshka-io/
├── build.zig
├── build.zig.zon
├── README.md
├── src/
│   ├── matryoshka.zig
│   ├── polynode.zig
│   ├── mailbox.zig          ← ConcurrentError, ReceiveResult, receiveResult, receive_future
│   ├── pool.zig             ← ConcurrentError, PoolResult, getWaitResult, get_wait_future
│   └── internal/
│       └── cond_timeout.zig
├── helpers/
│   ├── helpers.zig          ← expect, clearList, freeItem, freeList, freeSlot, createByTag,
│   │                           destroyByTag, AlwaysCreateCtx, CappedPoolCtx
│   └── types.zig            ← Event, Sensor, ShutdownCommand, Timer + PolyHelpers
├── tests/
│   ├── matryoshka_tests.zig ← root: imports all test files
│   ├── layer1_polynode.zig
│   ├── layer1_examples.zig
│   ├── layer2_mailbox.zig
│   ├── layer2_examples.zig
│   ├── layer3_pool.zig
│   ├── layer3_examples.zig
│   ├── layer4_infra.zig
│   ├── layer4_examples.zig
│   ├── layer4_master.zig
│   ├── layer4_cancel.zig    ← Stage 6 + INTR 4 (16 tests, scenarios 3-16)
│   ├── layer4_select.zig    ← Stage 7.b (22 tests, scenarios 25-31, 42-56)
│   └── layer4_cross.zig     ← Stage 8 (15 tests, scenarios 32-41, 57-61)
├── examples/
│   ├── examples.zig
│   ├── layer1/              ← 5 examples (scenarios 21-25)
│   ├── layer2/              ← 10 examples (scenarios 53-62)
│   ├── layer3/              ← 4 examples (scenarios 89-92)
│   └── layer4/              ← 37 examples (scenarios 17-24, 25-31, 32-41, 42-61, 95-96)
├── stories/                 ← NEW (INTR 5)
│   └── video_transcoder/
│       └── video_transcoder.zig
├── kitchen/
│   ├── build_and_test_debug.sh
│   ├── build_and_test_all.sh
│   └── build_cross_debug.sh
└── design/
    ├── STATUS.md
    ├── context.md
    ├── stories/             ← NEW (INTR 5)
    │   └── video-transcoder-001.md
    └── *.md
```

---

## Model and Rules — Moved

The thinking model, three-category model, and story structure moved to permanent docs.
- [matryoshka-model-001.md](matryoshka-model-001.md) — thinking model, three-category model, story structure.
- [rules-001.md](rules-001.md) — coding, doc, and process rules.
- [patterns-002.md](patterns-002.md) — reusable coding patterns.

This document keeps project state only.

---

## INTR 5 Plan

Three stages. No code before Stage 1 is complete.

### Stage 1 — Requirements (this document)
- Define the matryoshka thinking model. DONE (above).
- Define the three-category model. DONE (above).
- Define story structure. DONE (above).
- Write collected-context-004.md. DONE (this file).
- Update design/context.md to point to collected-context-004.

### Stage 2 — Design
- Wire stories module in build.zig.
- Add stories/ folder to repo structure.
- Add tests/stories_test.zig skeleton.
- Verify build still passes with empty stories module.

### Stage 3 — Pilot (video transcoder)
- Source: `design/matryoshka-real-world-scenario-001.md` (Parts 1-4 already written).
- Write `design/stories/video-transcoder-001.md` — refine narrative, confirm all 4 parts present.
- Write `stories/video_transcoder/video_transcoder.zig`:
  - `VideoBuffer` struct + `VideoBufferPolyHelper` (Pool)
  - `StreamContext` struct + `StreamContextPolyHelper` (Mailbox item carrying encoder state)
  - Network Master: `Io.Select` loop — pool event (buffer available) + mock socket source
  - Encoding workers: `Io.Group` — `mailbox.receive(ready_queue)`, process, `pool.put` buffer
  - Storage Master: `Io.Select` loop — storage mailbox + file write
  - Graceful shutdown: Network Master stops → closes ready mailbox → workers exit → pool.close
- Add wrapper to `tests/stories_test.zig`.
- Verify: all kitchen scripts pass (160 + story tests).

---

## THE SLOT RULE (carried from v003)

**Never overwrite a non-null slot.**

- All slots start as `var slot: Slot = null`.
- All acquisition APIs assert `slot.* == null` on entry.
- Transfer clears the slot: `slot.* = null`.
- Cleanup defers are safe to place before acquisition — all cleanup operations are no-ops on null slots.
- Applies universally: pool get/put, mailbox receive, heap allocation, every combination.

---

## API Reference — Key Types and Patterns (carried from v003)

### src/polynode.zig
- `PolyTag`, `PolyNode`, `ItemHandle`, `Slot`, `reset`, `is_linked`
- `PolyHelper(T)` — comptime branches on `@hasDecl(T, "no_create_destroy")`
- Full helper: `TAG`, `isIt`, `cast`, `mustCast`, `init`, `create`, `destroy`
- Reduced helper (infra types): `TAG`, `isIt`, `cast`, `mustCast`, `init`

### src/mailbox.zig additions (Stage 7.a)
- `ConcurrentError`, `ReceiveResult`, `receiveResult`, `receive_future`

### src/pool.zig additions (Stage 7.a)
- `ConcurrentError`, `PoolResult`, `getWaitResult`, `get_wait_future`

### helpers/types.zig
- `Event`, `Sensor`, `ShutdownCommand`, `Timer` + PolyHelpers for each

### helpers/helpers.zig
- `expect`, `clearList`, `freeItem`, `freeList`, `freeSlot`
- `createByTag`, `destroyByTag`
- `AlwaysCreateCtx`, `CappedPoolCtx`

---

## Canonical Idiom Patterns (carried from v003)

### Pattern 1 — defer-put-early (pool item)
```zig
var slot: Slot = null;
defer pool.put(ph, &slot);
try pool.get(ph, TAG, .new_only, &slot);
// transfer: slot = null → defer is no-op
```

### Pattern 2 — defer-destroy-early (heap item)
```zig
var slot: Slot = null;
defer EventPolyHelper.destroy(allocator, &slot);
try EventPolyHelper.create(allocator, &slot);
// transfer: slot = null → defer is no-op
```

### Pattern 3 — defer for received mailbox item
```zig
var slot: Slot = null;
defer if (slot) |poly| helpers.freeItem(poly, allocator);
try mailbox.receive(mbh, &slot, null);
// dispatch on slot.?.tag, process
```

### Pattern 4 — transfer clears the slot
```zig
try mailbox.send(mbh, &slot);   // send sets slot.* = null
// defer runs as no-op — item transferred
```

---

## Io Primitives Summary (carried from v003)

### Task spawning
- `io.concurrent(fn, args)` → `ConcurrentError!Future(Result)` — guarantees concurrency; copies args before return
- `Future.cancel(io)` — injects `error.Canceled` + awaits
- `Future.await(io)` — waits without cancellation

### Groups and Select
- `Io.Group` — unordered task set; workers return exactly `error{Canceled}!void`
- `group.cancel(io)` — cancels all + awaits
- `Io.Select(U)` — Group + Queue(U); awaits whichever source finishes first
- `select.concurrent(.field, fn, args)` — spawns fn, wraps result, puts in queue
- `select.queue.putOneUncancelable(io, value)` — direct push from wild thread

### Cancellation mechanics
- `error.Canceled` from next cancellation point — does NOT re-signal
- `io.recancel()` — re-arms cancel for next point
- `io.checkCancel()` — cancellation point for CPU-bound work
- `Mutex.lockUncancelable(io)` — cancel-safe cleanup path

---

## Bug Fixes Applied (INTR 4, carried forward)

- `pool.put`: `cond.signal` → `cond.broadcast` (deadlock when multiple threads wait on different tags)
- `pool.get_wait`, `mailbox.receive`: re-signal after cancel/timeout if item present (item was stranded)
- `pool.close`, `mailbox.close`: check+set closed inside the mutex (close/destroy race)

---

## Open Items (carried from v003)

- **5** — `condition_waitTimeout` workaround (codeberg/zig#31278)
- **6** — `Io.Evented` backend not tested
- **10** — Which Layer 2-3 examples need real threads
- **11** — Panic test style in Zig 0.16 (scenarios 15-16 deferred)
- **12** — Real-Io examples are integration tests, gate by platform

---

## Key Decisions (carried from v003)

### Layer Boundaries
- Layers 1-3: pure building blocks, no Master, no cancellation.
- Layer 4 (Master): coordination concept, where `std.Io` concurrency primitives live.

### Cancellation
- `error.Canceled` is never remapped to `error.Closed`.
- Cancel does not trigger close. Master decides when to close.

### Master is a Concept
- Not a mandatory struct, base type, or PolyNode.
- The responsibility matters. The structure does not.

### Mailbox Is Optional
- Pool + Io is a complete coordination model.
- Add Mailbox when: fan-in from independent senders, pipelines, heterogeneous ownership streams.

### Slot/ItemHandle Naming
- `MayItem` (Odin) → `Slot` (Zig): `?ItemHandle` = `?*PolyNode`
