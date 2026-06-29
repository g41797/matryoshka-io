# Matryoshka Zig 0.16 — Staged Implementation Plan (020)

Slim plan. State only.
All process and coding rules live in [rules-001.md](rules-001.md). Not repeated here.

- Repo: `matryoshka-zig`. Module name: `matryoshka`.
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
Story Rhythm  Both stories SRS+Translation+Insight          NEXT
Stage 9     Docs + README + autodocs                        FUTURE
```

---

## 2. STORY 1 Rewrite — Video Transcoder Narrative

Deliverable.
- `design/stories/video-transcoder-002.md` — rewritten narrative only, no code.
- `design/stories/video-transcoder-001.md` — preserved, untouched.

What changes.
- Part 1: rewritten with human voices first, then developer negotiation, no Matryoshka terminology.
- Part 2 (SRS): observable behavior only, no implementation hints.
- Part 3 (Translation): inevitable tone — each requirement maps to one primitive.
- Part 5 removed: replaced with one-line implementation pointer.

What stays.
- Architecture: Pool + Io.Select + Io.Group + Mailbox.
- Implementation file: `stories/video_transcoder/video_transcoder.zig` — untouched.
- Flow diagram (Part 4): kept, minor label cleanup only.
- Central insight: pool exhaustion is backpressure.

Why rewrite.
- Story 1 was written before the storytelling model matured.
- Story 2 established a stronger model: start with people, conversations first, delay Matryoshka, SRS domain-only.
- The collection should feel like one book.

Story theme.
- Theme: continuous flow.
- Question: "How does work move through a pipeline?"
- Contrast with Story 2 (ownership): "Who is responsible right now?"

---

## 3. Open Items / Next Up

- STORY 1 rewrite in progress. Deliverable: `design/stories/video-transcoder-002.md`.
- Stage 9 (README + autodocs) is next after STORY 1. See `matryoshka-zig-docs-plan-001.md`.

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
- [patterns-001.md](patterns-001.md) — reusable coding patterns.
- [matryoshka-zig-docs-plan-001.md](matryoshka-zig-docs-plan-001.md) — documentation work plan.
- `matryoshka-api-reference-015.md` — primary source of truth for signatures, types, errors.
- `collected-context-004.md` — project state, idiom patterns, Io primitives, bug fixes.
