# Matryoshka Zig — Implementation Plan (032)

Replaces [matryoshka-io-implementation-plan-031.md](matryoshka-io-implementation-plan-031.md).

## Status

API 3 — DONE. 167/167 tests.

---

## Completed stages (summary)

- Stage 0–8: API, tests, examples layers 1–3 done.
- Stage 9 (Layer 4 infrastructure): pool, mailbox, select, group done.
- EXMPL 3a: 45 layer4 examples written (layer4.zig registration, test wrappers).
- EXMPL 3b: renamed all layer4 examples; Master pattern applied to 6 complex files.
- EXMPL 3c: Observable by human rule (rules-005 → rules-006); fixed 3 Master violations (020, 031, 048).
- EXMPL 3d: extracted step functions from 31 flat layer4 files with section comments.
- EXMPL 3e: structural extraction signals (rules-007); fixed 24 Observable violations; patterns-006 → patterns-007 (coordinator templates).
- API 2: renamed `cast`→`identifyNodeAs`, `mustCast`→`mustIdentifyNodeAs`; added `identifySlotAs` / `mustIdentifySlotAs` to `PolyHelper`. Updated all call sites (src, examples, tests, stories, helpers). api-reference-015 → api-reference-016. patterns-006 → patterns-007 (Slot identification pattern). rules-007 → rules-008 (stale patterns ref fix). 161/161 tests.
- EXMPL 4: "Description as code" rule (rules-008 → rules-009). Staccato descriptions moved
  from catalog docs into each example's `///` doc comment; `pub fn run` / Master `run`
  moved to top of file. `examples/layer1` (5), `layer2` (10), `layer3` (4) renamed with
  `NNN-` prefix, matching layer4's existing convention. All 47 `examples/layer4/*.zig`
  files rewritten with the same doc-comment + flow-descriptor treatment. `task1-examples`
  and `task2-examples` docs (-002 → -003) reduced to index-only (number, name, hook, link).
  patterns-007 → patterns-008 (companion link fix only). 161/161 tests, all 4 opt modes,
  cross-compile clean.
- EXMPL 4b: descriptive entry-point names rule (rules-009 → rules-010). Every example's
  `pub fn run` renamed to `pub fn @"<description>"`, using the example's own one-line
  staccato description as the Zig quoted identifier. All 66 example files (layer1: 5,
  layer2: 10, layer3: 4, layer4: 47) renamed; all ~66 test-wrapper call sites
  (`tests/layer1_examples.zig`, `layer2_examples.zig`, `layer3_examples.zig`,
  `layer4_examples.zig`, `layer4_select.zig`, `layer4_cross.zig`) updated to match.
  No logic changed. 161/161 tests, all 4 opt modes, cross-compile clean.
- API 3: added `mailbox.wakeUpAll()` — wakes every receiver currently blocked in `receive()`
  with `error.Wakeup`, no item sent, mailbox stays open, future receivers unaffected.
  Implemented with one `wake_epoch: u64` field on `_Mailbox`, read/written only under the
  existing mutex (no new atomics). `receive()`'s error set gains `error.Wakeup`;
  `ReceiveResult` gains `wakeup: void`. All existing exhaustive switches on `receive()`/
  `receiveResult()` errors across tests/examples/stories updated to handle the new arm.
  5 new tests in `tests/layer2_mailbox.zig` (unnumbered, outside the original scenario
  catalog — same precedent as the pre-existing OOB invariant test). New example
  `examples/layer2/097-wake_up_all.zig` (fresh number beyond the existing 17-96 catalog
  range, avoiding collision with Layer3's test scenarios 63-88). api-reference-016 → -017.
  patterns-008 → -009 (new "Wake blocked receivers without a message" pattern). 167/167
  tests, all 4 opt modes, cross-compile clean.

---

## Next

Stage 9 — Docs + README + autodocs. PLANNED.

Open: owner to decide on removing old-named (pre-`NNN-`) layer1-3 example files, currently
unreferenced and left in place.
