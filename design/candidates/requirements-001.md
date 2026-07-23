# Pass 2 — Per-Document Requirements (001)

Requirements for the three CANDIDATES-stage target docs, before Pass 3  
composition. Built from Pass 1 audit (`audit-001.md`, `corpus-index-001.md`)  
plus owner decisions recorded in `design/STATUS.md`'s 2026-07-15 session log.

Scope for this stage: README.md, landing-short, landing-long. Showcase/post  
variants (Ziggit/Discord/Reddit) and story-based material are explicitly out  
of scope — deferred to later stages.

## Cross-cutting constraints (apply to all three docs)

- **Vocabulary**: "Item" / "ItemHandle" is the concept-level term.
  "PolyNode" is implementation detail — not surfaced in these docs.
- **Altitude**: concentrate on mindset and the problem being solved, not
  implementation mechanics. Mailbox/Pool/Slot internals, hook semantics,  
  cancel contracts, etc. stay out or get at most one light mention with a  
  pointer to deeper docs.
- **Voice preservation**: source material carries jokes, rules-of-thumb, and
  distinctive phrasing. Composition must keep this texture, not flatten it  
  into generic propositional summaries. Reuse strong lines close to  
  verbatim where the source already has good phrasing (e.g.  
  `matryoshka-tk-readme.md`'s "Be Master of your systems").
- **No stories**: do not pull from `design/stories/*`, `kitchen/docs/story/print-server/*`.
- **New-mindset only**: no "ownership" framing, no banned/AI-sh words
  (rules-024.md list). Sources tagged old-mindset-but-salvageable need a  
  word-swap pass during reuse, not verbatim copy.
- **Doc rules**: staccato style, blank-line-separated short lines (not
  trailing-space reliant), versioned filename in `design/candidates/`, no  
  overwrite.

## README.md

**Audience**: developer landing on the GitHub repo — evaluating whether to  
try the library, often within seconds.

**Length budget**: short-to-medium. Long enough to establish the mindset and  
show it's not "just another framework," short enough to read in one screen  
or two without scrolling fatigue. `matryoshka-tk-readme.md` is roughly the  
right length — use it as the calibration point.

**Tone**: direct, confident, a little wry. Not corporate, not academic.

**Primary source**: `design/matryoshka-tk-readme.md` — new-mindset, no  
rewrite needed, use as the structural skeleton.

**Supporting sources** (need old-mindset word-swap before reuse):  
`kitchen/docs/misc/what-is-matryoshka-tk.md` (problem-statement paragraph),  
`kitchen/docs/misc/how-matryoshka-system-works.md` (pull-quote: "share by  
communicating").

**Must include**:
- The problem framing: unclear ownership/who-holds-what in concurrent
  code, stated as questions, not lecture.
- "Matryoshka is not another runtime. It's a way to organize Io tasks."
  positioning line (or equivalent) — clarifies relationship to `std.Io`  
  early, before a reader assumes competition/replacement.
- Item / ItemHandle introduced with the file-handle analogy.
- Master connected to `io.concurrent()` explicitly — per New Mindset,
  never left implicit.
- "What this is not" section (no framework, no runtime, no interfaces/
  inheritance/virtual dispatch).
- Incremental-adoption note (start with Items, add Pool/Mailbox/Master as
  needed) — signals low commitment cost.
- A closing line with personality, not a generic "get started" CTA.

**Must exclude**: PolyNode terminology, Slot mechanics, hook lifecycle  
detail, full API surface (link out to the API reference instead).

## landing-short (doc site)

**Audience**: reader arriving at the doc site from a link (forum post, chat  
mention) with low commitment, deciding whether to keep reading.

**Length budget**: shortest of the three — a few short paragraphs plus  
bullets, scannable in under a minute.

**Tone**: punchy, quote-driven. Built more from pull-quotes than  
exposition.

**Primary technique**: lead with the strongest single insight-density  
lines identified in Pass 1, rather than building up an argument slowly.  
Candidates: "Do not share Items. Pass Items. Reuse Items. Communication is  
the default. Sharing is the exception." / "Io answers: How do tasks run?  
Matryoshka answers: How do tasks cooperate?" / "Share by communicating.  
Instead of sharing application objects, communicate the application  
objects themselves." (word-swapped from `how-matryoshka-system-works.md`).

**Must include**: one clear statement of the problem, one clear statement  
of the answer (the "one constraint" framing from the manifesto), a link to  
landing-long and to the README/repo.

**Must exclude**: adoption walkthrough, "what this is not" list (too long  
for this altitude) — those belong in landing-long.

## landing-long (doc site)

**Audience**: reader who clicked through from landing-short, wants the full  
mindset picture before deciding to invest time in the docs/examples.

**Length budget**: longest of the three, but still mindset-level — not an  
API walkthrough. Comparable in scope to `matryoshka-manifesto-005.md` or  
`matryoshka-new-mindset-001.md`, not to the architecture-foundation doc.

**Tone**: builds an argument — problem, then the one-constraint answer,  
then how it plays out (Item/Handle, Master-as-task, incremental adoption),  
then what it deliberately isn't.

**Primary sources**: `matryoshka-manifesto-005.md` (one-constraint framing,  
four fundamental concepts, Io-hidden-behind-Mailboxes), `matryoshka-new-mindset-001.md`  
(Master-is-a-task definition, `io.concurrent()` connection),  
`matryoshka-terminology.md` (vocabulary precision), `design/matryoshka-tk-readme.md`  
(incremental-adoption narrative, file-handle analogy).

**Must include**: everything README has, expanded — plus the "how it plays  
out" walkthrough (start with Items, add Pool when reuse matters, add  
Mailbox when communication matters, add Master for long-running  
coordination) and an explicit "what this is not" section with more room to  
explain each exclusion than README's version.

**Must exclude**: still no PolyNode/Slot/hook mechanics — link to  
building-blocks/API reference docs for that. This is the ceiling of  
mindset-level content in this stage.

## Open items for Pass 3

- Reconcile: `matryoshka-tk-readme.md` vs `kitchen/docs/misc/readme-landing.md`
  vs `kitchen/docs/misc/README-15-07-2026.md` — three files with overlapping  
  purpose. Pass 3 should treat `matryoshka-tk-readme.md` as primary (already  
  new-mindset) and treat the two `misc/` variants as alternate drafts to  
  mine for anything the primary lacks, not as co-equal sources.
- Confirm final filenames before Pass 3 starts: suggest
  `design/candidates/readme-001.md`, `design/candidates/landing-short-001.md`,  
  `design/candidates/landing-long-001.md`.
