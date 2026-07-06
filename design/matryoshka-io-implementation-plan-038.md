# Matryoshka Zig — Implementation Plan (038)

Replaces [matryoshka-io-implementation-plan-037.md](matryoshka-io-implementation-plan-037.md).

## Status

DOC 14 — DONE (doc-only, 167/167 tests unchanged).

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
- DOC 9: re-partitioned and logically reordered `matryoshka-api-reference-017.md`
  (development-order) into `-018.md` (teachable order: intro → ownership model → slot
  rule → cleanup patterns → polynode → mailbox → pool → root → Master → cancel/
  invariants/thread-safety/complexity/violations/layer-deps → Change log). Generic
  `std.Io` runtime material (Prolog, `io.concurrent`/`Io.Group`/`Io.Select` internals)
  moved to a new trailing `## Addendums` / `### Io 101` section. Dropped the 16
  `Change manifest (NNN)` sections — downstream-propagation notes already fully
  reflected in the current main body; verified via term-frequency diff, no information
  lost. Doc-only — no `.zig` touched, 167/167 tests unaffected.
- DOC 10: dependency-ordered `matryoshka-api-reference-018.md` → `-019.md`. Fixed
  remaining forward references one level below top sections: send/receive ownership
  diagrams moved from Ownership model into mailbox; Tag identity (class, not
  instance + Transporting infra handles) moved out of polynode to its own section
  after pool; Slot-based programming and Cooperative cleanup patterns moved after
  pool — every function they reference is now introduced first. Byte-exact block
  moves (sed line-range reassembly); term-frequency counts identical between -018
  and -019; only additions: one Change-log row, one separator, heading-level
  promotion of the two relocated blocks. Doc-only — 167/167 tests unaffected.
- DOC 11: wrote `matryoshka-manifesto-002.md` — consolidated the mindset from
  `README.md`, `matryoshka-io-model.md`, `matryoshka-manifesto.md` (original,
  untouched), `matryoshka-master.md`, and `master-Io.md` into one persuasion-first
  manifesto: problem → one constraint → Master is a role → down to earth → four
  fundamental concepts → where Io fits (hidden transport behind Mailboxes, bridge
  Masters) → start small → the simple question. Staccato style, banned-word clean.
  docs-plan-008 → -009. Doc-only — 167/167 tests unaffected.
- DOC 12: de-smarted the manifesto (`matryoshka-manifesto-002.md` → `-003.md`).
  Owner flagged abstract architect-speak ("application model", "execution model",
  "autonomous", "reason about locally") as AI-sh; rewritten into plain human
  language ("Matryoshka answers: what is my system made of? Io answers: when does
  my code run?"). Structure, diagrams, tables unchanged. docs-plan-009 → -010.
  Doc-only — 167/167 tests unaffected.
- DOC 13: unified pattern/idiom catalog (`patterns-009.md` → `patterns-010.md`).
  patterns-009 was two glued catalogs — the full "(008)" catalog plus an appended
  older "(002)" idiom catalog — with heavy repetition; more pattern material lived
  only in api-reference-019 (cooperative cleanup 1–4, transporting infra handles,
  no-raw-allocator). patterns-010 holds every pattern/idiom once, in logical order:
  slot/ownership idioms → PolyNode → Mailbox → Pool → Futures → Select → Group →
  cancellation → graceful shutdown → Master patterns. Error-handling-on-receive
  gains the `error.Wakeup` branch. -009 and api-reference-019 untouched.
  docs-plan-010 → -011. Doc-only — 167/167 tests unaffected.
- DOC 14: audited the sibling Odin `matryoshka/kitchen/docs` project for
  patterns/idioms missing from our Zig catalog. 31 named patterns inventoried;
  most already covered (Bucket A, no action). 7 had a matching Zig example but no
  catalog entry (Bucket B) — added to `patterns-011.md`: Request-Response,
  Pipeline, Fan-In, Fan-Out (new "Topology patterns" section), Shutdown via Exit
  message (alternative to the close-based shutdown sequence), Thread-is-container
  (Master patterns), Intrusive node embedding (PolyNode idioms). 3 advanced/niche
  patterns with no existing example (self-send, function-pointer-as-tag,
  descriptor-struct-as-tag) explicitly skipped, owner confirmed (Bucket C).
  patterns-010 → -011. docs-plan-011 → -012. Doc-only — 167/167 tests unaffected.

---

## Next

Stage 9 — Docs + README + autodocs. PLANNED. DOC 15+ candidate: split
`matryoshka-api-reference-019.md` into mkdocs Reference pages under
`kitchen/docs/reference/`.

Open: owner to decide on removing old-named (pre-`NNN-`) layer1-3 example files, currently
unreferenced and left in place.
