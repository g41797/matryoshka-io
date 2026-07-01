# Matryoshka Zig 0.16 — Staged Implementation Plan (026)

Slim plan. State only.
All process and coding rules live in [rules-005.md](rules-005.md). Not repeated here.

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
EXMPL 3c    Observable by human rule + 3 Master fixes       IN PROGRESS
EXMPL 3d    Observable: extract steps in 35 flat examples   NEXT
Stage 9     Docs + README + autodocs                        PLANNED
```

---

## 2. EXMPL 1–3b — Completed

EXMPL 1: Doc-only. "Pool items are empty containers" rule added. 7 task2 scenarios revised in spec.
EXMPL 2: Master pattern rule added. `master_with_pool.zig` rewritten as canonical reference.
EXMPL 3a: 7 files rewritten (flat style) — pool items as empty containers.
EXMPL 3b: 47 files renamed to `NNN-name.zig`. 6 Master pattern rewrites. `rules-004.md` + `patterns-003.md` + `context.md` + `STATUS.md` updated.

---

## 3. EXMPL 3c — Observable by human rule + 3 Master fixes

### Rule added

New MUST rule: "Observable by human". Added to `rules-005.md` as first coding rule section.

Two-level structure.
- Coordinator (`run`, any sequencing function): dominant structure is calls to named step functions. Simple glue (a guard, a `helpers.expect`, a `std.log.info`) stays inline. Inline logic blocks with distinct purpose are extracted to named steps.
- Step functions: each implements one step. Name = documentation.

Development order.
- Write the coordinator first. Name the steps before implementing them.
- Add stub step functions that compile but do nothing.
- Fill in steps one by one.

The signal.
- If you feel the need to place a comment explaining a block → extract that block to a named step function.
- `var`/`const` declarations are fine anywhere they are needed.

### Violations fixed — 3 Master files

**020-pipeline_masters.zig** — merged `spawnWorkers` + `awaitWorkers` → `runWorkers`. Futures move inside `runWorkers`.

**031-select_graceful_shutdown.zig** — added `buf` and `sel` as struct fields. Initialized in `init`. `eventLoop` and `gracefulShutdown` access `self.sel` directly.

**048-select_mailbox_pool_timer.zig** — same as 031. Also extracted `sleep_t` construction to private `timerTimeout() std.Io.Timeout`.

### Compliant Master files — no changes

027, 047, 053 — compliant.
017, 018, 019 — canonical references, compliant.

### Flat files audit

6 files with no section comments — no extraction needed: 017, 021, 026, 042, 045, 049.
35 files with section comments — extraction deferred to EXMPL 3d.

---

## 4. EXMPL 3d — Observable: flat example step extraction (NEXT)

35 flat examples have section comments in `pub fn run` marking discrete steps.
Each step comment block → named private function. `run` becomes a thin coordinator.

Files: 019, 022, 023, 024, 025, 028, 029, 030, 032, 033, 034, 035, 036, 037, 038, 039, 040, 041, 043, 044, 046, 050, 051, 052, 054, 055, 056, 057, 058, 059, 060, 061, 095, 096.

---

## 5. Open Items / Next Up

- EXMPL 3d: flat example step extraction (35 files).
- Stage 9: Docs + README + autodocs. See `matryoshka-io-docs-plan-001.md`.

Carried open items.
- 5 — `condition_waitTimeout` workaround (codeberg/zig#31278).
- 6 — `Io.Evented` backend not tested.
- 10 — Which Layer 2-3 examples need real threads.
- 11 — Panic test style in Zig 0.16 (scenarios 15-16 deferred).
- 12 — Real-Io examples are integration tests, gate by platform.

---

## 6. References

- [rules-005.md](rules-005.md) — all process and coding rules. Source of truth for process.
- [matryoshka-model-003.md](matryoshka-model-003.md) — thinking model and story structure.
- [matryoshka-storytelling-001.md](../kitchen/docs/matryoshka-storytelling-001.md) — storytelling philosophy and rhythm rules.
- [patterns-004.md](patterns-004.md) — reusable coding patterns.
- [matryoshka-io-docs-plan-001.md](matryoshka-io-docs-plan-001.md) — documentation work plan.
- `matryoshka-api-reference-015.md` — primary source of truth for signatures, types, errors.
- `collected-context-004.md` — project state, idiom patterns, Io primitives, bug fixes.
