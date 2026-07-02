# Matryoshka Zig — Implementation Plan (029)

Replaces [matryoshka-io-implementation-plan-028.md](matryoshka-io-implementation-plan-028.md).

## Status

API 2 — DONE. 161/161 tests.

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

---

## Next

Stage 9 — Docs + README + autodocs. PLANNED.
