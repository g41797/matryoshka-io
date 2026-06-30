# Matryoshka Zig 0.16 — Staged Implementation Plan (021)

Slim plan. State only.
All process and coding rules live in [rules-001.md](rules-001.md). Not repeated here.

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
Stage 9     Docs + README + autodocs                        NEXT
```

---

## 2. Story Rhythm Fixes

Deliverables.
- `design/stories/video-transcoder-003.md` — rewritten SRS + Translation + Central Insight.
- `design/stories/print-server-002.md` — rewritten SRS + Translation + Central Insight.
- `design/stories/video-transcoder-002.md` — preserved, untouched.
- `design/stories/print-server-001.md` — preserved, untouched.

What changed.
- SRS: flat bullets, one observable fact per bullet. No numbered+bold+prose format.
- Translation: table of mappings. Requirement label → short bullets of Matryoshka primitives. No P1/P2 dialogue.
- Central Insight: state the insight, then illustrate with short bullets. No essay.

What stayed.
- Discussion (Part 1): unchanged in both stories.
- Flow Diagram (Part 4): unchanged in both stories.
- Implementation files: untouched.

Why.
- `kitchen/docs/matryoshka-storytelling-001.md` updated with `# Storytelling Rule` section.
- The section adds explicit rhythm rules for SRS, Translation, Central Insight.
- Both stories violated those rules — SRS was prose, Translation was dialogue, Insight was an essay.
- The collection should have one voice and one rhythm throughout.

Storytelling rule summary.
- Discussion: short sentences, questions, negotiation, one idea at a time.
- SRS: checklist of independently verifiable facts. No explanations.
- Translation: table of mappings. One requirement → one block of short bullets.
- Central Insight: state then illustrate. No paragraphs.

---

## 3. Open Items / Next Up

- Stage 9 (README + autodocs) is next. See `matryoshka-io-docs-plan-001.md`.

Carried open items.
- 5 — `condition_waitTimeout` workaround (codeberg/zig#31278).
- 6 — `Io.Evented` backend not tested.
- 10 — Which Layer 2-3 examples need real threads.
- 11 — Panic test style in Zig 0.16 (scenarios 15-16 deferred).
- 12 — Real-Io examples are integration tests, gate by platform.

---

## 4. References

- [rules-001.md](rules-001.md) — all process and coding rules. Source of truth for process.
- [matryoshka-model-001.md](matryoshka-model-001.md) — thinking model and story structure.
- [matryoshka-storytelling-001.md](../kitchen/docs/matryoshka-storytelling-001.md) — storytelling philosophy and rhythm rules.
- [patterns-001.md](patterns-001.md) — reusable coding patterns.
- [matryoshka-io-docs-plan-001.md](matryoshka-io-docs-plan-001.md) — documentation work plan.
- `matryoshka-api-reference-015.md` — primary source of truth for signatures, types, errors.
- `collected-context-004.md` — project state, idiom patterns, Io primitives, bug fixes.
