# Matryoshka Zig 0.16 — Staged Implementation Plan (027)

Slim plan. State only.
All process and coding rules live in [rules-006.md](rules-006.md). Not repeated here.

- Repo: `matryoshka-io`. Module name: `matryoshka`.
- Zig 0.16.0. Target backend: `Io.Threaded`.
- Both Mailbox and Pool are optional.

---

## 1. Project State

Test count.
- 161/161 passing across 4 optimization modes and 3 cross-compile targets.

Stages.
- Stages 0–8: complete.

INTR.
- INTR 1–5: complete.

Build order (reference).

```text
Stage 0     infrastructure                                  DONE
Stage 0.5   re-partition scenarios                          DONE
Stage 1     Layer 1  PolyNode                               DONE
Stage 2     Layer 2  Mailbox                                DONE
Stage 3     Layer 3  Pool                                   DONE
Stage 4     Layer 2+3  Infra as items                       DONE
Stage 5     Layer 4  Master (concurrency)                   DONE
INTR 1      Slot-based programming retrofit                 DONE
Stage 6     Cancellation + shutdown                         DONE
INTR 2      Thread-safe hooks + multi-thread example        DONE
Stage 7.a   Event sources — implementation                  DONE
INTR 3      ASCII ownership diagrams retrofit               DONE
Stage 7.b   Event sources — examples                        DONE
INTR 4      Bug fixes + doc corrections                     DONE
Stage 8     Mailbox-less patterns + cross-layer             DONE
INTR 5      Stories + doc infrastructure                    DONE
STORY 2     Print Server narrative                          DONE
STORY 1     Video Transcoder narrative rewrite              DONE
Story Rhythm  Both stories SRS+Translation+Insight          DONE
EXMPL 1     Example completeness audit + rule addition      DONE
EXMPL 2     Master pattern: pilot + doc update              DONE
EXMPL 3a    7 semantic rewrites (empty-container rule)      DONE
EXMPL 3b    Rename NNN- prefix + Master pattern (6 files)   DONE
EXMPL 3c    Observable by human rule + 3 Master fixes       DONE
EXMPL 3d    Observable: extract steps in flat examples      IN PROGRESS
Stage 9     Docs + README + autodocs                        PLANNED
```

---

## 2. EXMPL 1–3c — Completed

EXMPL 1: Doc-only. "Pool items are empty containers" rule added.
EXMPL 2: Master pattern rule added. `master_with_pool.zig` rewritten as canonical reference.
EXMPL 3a: 7 files rewritten (flat style) — pool items as empty containers.
EXMPL 3b: 47 files renamed to `NNN-name.zig`. 6 Master pattern rewrites.
EXMPL 3c: Observable by human MUST rule. `rules-005.md` + `patterns-004.md`. Fixed 020, 031, 048.

---

## 3. EXMPL 3d — Observable: flat example step extraction

### Scope

34 files were audited. 3 are excluded after re-audit:
- **019**: only comment explains close API behavior (1-2 line operation) — common sense, stays inline.
- **043**: two comments each explain a 1-line operation — common sense, stays inline.
- **044**: comment is inside defer block, explains subtle double-close behavior — not a block header.

**31 files to change.**

### Execution Order

**Step 0 — Plan doc (this file).**

**Step 1 — Edit all 31 files.**
For each file: remove section comment, extract block to named private function, call function from `run`.

**Step 2 — Run kitchen scripts.**
```
bash kitchen/build_and_test_debug.sh > zig-out/build_and_test_debug.log 2>&1
bash kitchen/build_and_test_all.sh > zig-out/build_and_test_all.log 2>&1
bash kitchen/build_cross_debug.sh > zig-out/build_cross_debug.log 2>&1
```
Confirm 161/161 × 4 modes. Read log files.

**Step 3 — Update `context.md` and `STATUS.md`.**

**Step 4 — AI-sh + banned words scan on changed files.**

---

### Intent per file

Each row: file → extracted function names (params abbreviated).

| File | Extracted functions |
|------|-------------------|
| **022** timer_via_mailbox | `sendEvents(mbh, alloc, count) !void` |
| **023** oob_signal | `sendItems(mbh, alloc) !void` · `sendOobItem(mbh, alloc) !void` · `processingLoop(mbh, alloc) !void` |
| **024** multi_source_mailbox | `awaitSendersAndClose(mbh, alloc, *fut_timer, *fut_events, *fut_signal, *fut_worker, io) void` |
| **025** select_two_mailboxes | `seedMailboxes(mbh1, mbh2, alloc) !void` — extracted from inside `.timer` handler |
| **028** select_mixed_sources | `seedMailbox(mbh, alloc, count) !void` · `seedPool(ph, count) !void` |
| **029** select_cancel_recycle | `seedPool(ph, alloc, count) !void` · `eventLoop(ph, *sel, *processed) !void` · `cancelAndRecycle(ph, *sel, *recycled) void` |
| **030** mailbox_timeout | `receiveTimeouts(mbh, alloc, io) !usize` · `sendAndReceive(mbh, alloc) !void` |
| **032** cross_layer_pool_mailbox_roundtrip | `getAndSend(ph, mbh, alloc) !*Event` · `receiveAndVerify(ph, mbh, alloc, sent_ptr) !void` · `verifyRecycle(ph, sent_ptr) !void` |
| **033** cross_layer_mixed_types_mailbox | `sendEvent(mbh, alloc) !void` · `sendSensor(mbh, alloc) !void` · `receiveAndDispatch(mbh, alloc) !void` |
| **034** cross_layer_batch_receive_pool_return | `fillMailboxFromPool(ph, mbh, alloc, count) !void` · `batchReceiveToPool(ph, mbh) !void` · `verifyPool(ph) !void` |
| **035** cross_layer_pool_hooks_mailbox_flow | `round1(ph, mbh, alloc) !void` · `round2(ph, mbh, alloc) !void` · `verifyRecycled(ph) !void` |
| **036** cross_layer_close_pool_then_mailbox | `seedPool(ph, alloc, count) !void` · `seedMailbox(mbh, alloc, count) !void` · `closePool(ph, alloc) void` · `closeMailboxAndFree(mbh, alloc) usize` |
| **037** cross_layer_close_mailbox_then_pool | `seedPool(ph, alloc) !void` · `seedMailbox(mbh, alloc) !void` · `closeMailboxToPool(mbh, ph, alloc) usize` |
| **038** cross_layer_pool_mailbox_flow | `poolGetAndSend(ph, mbh, alloc) !void` · `receiveAndVerify(ph, mbh, alloc) !void` |
| **039** master_shutdown_stdlib_cleanup | `seedMailbox(mbh, alloc, count) !void` · `seedPool(ph, alloc, count) !void` · `closeMailbox(mbh, alloc) usize` · `closePool(ph, alloc) void` |
| **040** master_batch_drain_receive_to_pool | `fillMailbox(mbh, alloc, count) !void` · `batchDrainToPool(ph, mbh) !void` · `verifyPool(ph) !void` |
| **041** master_multi_mailbox_collect | `fillMailboxA(mbh, alloc, count) !void` · `fillMailboxB(mbh, alloc, count) !void` · `collectAndFree(mbh_a, mbh_b, alloc) usize` |
| **046** select_pool_event | `seedPool(ph, alloc, count) !void` |
| **050** get_wait_future_direct | `seedPool(ph) !void` |
| **051** receive_future_timeout | `receiveWithTimeout(mbh, io) !void` · `sendAndReceiveItem(mbh, alloc, io) !void` |
| **052** future_single_threaded | `testFutureUnavailable(mbh) !void` · `testSynchronousReceive(mbh, alloc) !void` |
| **054** pool_fan_out | `seedPool(ph, count) !void` |
| **055** producer_consumer_recycle | `produce(ph, mbh, alloc) !*Event` · `consume(ph, mbh, alloc, sent_ptr) !void` · `verifyRecycle(ph, sent_ptr) !void` |
| **056** job_pool_circular | `seedContainer(ph) !void` · `closeAndAwait(mbh, alloc, *worker_fut, io) !void` |
| **057** mailbox_less_pool_future_worker | `seedContainer(ph) !void` |
| **058** mailbox_less_pool_select_scheduler | `seedPool(ph, alloc, count) !void` |
| **059** mailbox_less_pool_group_workers | `seedContainers(ph, count) !void` |
| **060** mailbox_less_pool_select_network | `seedPool(ph, alloc, count) !void` |
| **061** mailbox_less_to_mailbox_transition | `seedPool(ph, alloc, count) !void` · `spawnClients(mbh, alloc, io, *ctxs, *futs, delay) !void` · `awaitClients(*futs, io) void` · `closeMailbox(mbh, alloc) void` |
| **095** mailbox_as_item | `cleanupReturnedMailbox(*slot, alloc) void` |
| **096** pool_as_item | `createAndStoreInnerPools(carrier, alloc, io, n) !void` · `closeCarrier(carrier, *ctx, alloc, n) !void` |

### Notes

- `alloc` = `std.mem.Allocator`, `io` = `std.Io`, `ph` = `PoolHandle`, `mbh` = `MailboxHandle`.
- `sel` = `*std.Io.Select(MasterEvent)` — pointer because step modifies it via `concurrent`/`await`.
- `*processed`, `*recycled`, `*futs`, `*ctxs` — pointer to caller's local, updated in step.
- File-level constants (`TIMER_NS`, `N_ITEMS`, etc.) used directly inside extracted functions — no param needed.
- Common sense applied: 1-2 line guards and inline comments between calls stay in `run`.

---

## 4. Open Items / Next Up

- EXMPL 3d: flat example step extraction (31 files) — IN PROGRESS.
- Stage 9: Docs + README + autodocs. See `matryoshka-io-docs-plan-001.md`.

Carried open items.
- 5 — `condition_waitTimeout` workaround (codeberg/zig#31278).
- 6 — `Io.Evented` backend not tested.
- 10 — Which Layer 2-3 examples need real threads.
- 11 — Panic test style in Zig 0.16 (scenarios 15-16 deferred).
- 12 — Real-Io examples are integration tests, gate by platform.

---

## 5. References

- [rules-006.md](rules-006.md) — all process and coding rules. Source of truth for process.
- [matryoshka-model-003.md](matryoshka-model-003.md) — thinking model and story structure.
- [matryoshka-storytelling-001.md](../kitchen/docs/matryoshka-storytelling-001.md) — storytelling philosophy and rhythm rules.
- [patterns-005.md](patterns-005.md) — reusable coding patterns.
- [matryoshka-io-docs-plan-001.md](matryoshka-io-docs-plan-001.md) — documentation work plan.
- `matryoshka-api-reference-015.md` — primary source of truth for signatures, types, errors.
- `collected-context-004.md` — project state, idiom patterns, Io primitives, bug fixes.
