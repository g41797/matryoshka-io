# Matryoshka Zig — Implementation Plan (030)

Replaces [matryoshka-io-implementation-plan-029.md](matryoshka-io-implementation-plan-029.md).

## Status

EXMPL 4 — DONE. 161/161 tests.

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

---

## Next

Stage 9 — Docs + README + autodocs. PLANNED.

Open: owner to decide on removing old-named (pre-`NNN-`) layer1-3 example files, currently
unreferenced and left in place.
