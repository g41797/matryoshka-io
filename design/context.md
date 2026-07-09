# Matryoshka Zig — Context Entry Point

## Writing rules
- Short intro, then bullets. Like staccato music.
- One fact per bullet.
- No prose paragraphs with comma-separated lists.

API reference: [matryoshka-api-reference-022.md](matryoshka-api-reference-022.md) — signatures, types, error sets, cancel contract, PolyHelper (+ identifyNodeAs/identifySlotAs + create/destroy + no_create_destroy), slot-based programming, cooperative cleanup patterns, tag identity, infra transport patterns, invariants, thread-safety, complexity, receiveResult/getWaitResult, mailbox.wakeUpAll — dependency-ordered (DOC 9 + DOC 10): nothing is used before it is introduced; generic std.Io material lives in a trailing Addendums/Io 101 section; humanized (DOC 18): no "ownership" framing, staccato throughout; `ItemHandle` naming (API 4, supersedes `NodeHandle`); New Mindset (022): Master connected to `io.concurrent()` up front, not left implicit

Manifesto: [matryoshka-manifesto-005.md](matryoshka-manifesto-005.md) — persuasion-first mindset doc (DOC 11 + DOC 12 plain-language pass): one constraint, Master is an Io task that follows the Matryoshka rules, four fundamental concepts, Io hidden behind Mailboxes; consolidates README + matryoshka-io-model + matryoshka-master + master-Io; supersedes matryoshka-manifesto.md, -002, -003, and -004; New Mindset (004): task-world diagram replaces the old floating-role diagram; New Mindset (005): dropped the "hybrid car" analogy, replaced with Io-creates-tasks/Matryoshka-lives-inside framing

Architecture: [matryoshka-architecture-003.md](matryoshka-architecture-003.md) — why matryoshka exists, concept progression, flows, layers; New Mindset (003): "ownership"/"owner" language replaced with "place"/"hold" (an object sits in exactly one place at any moment), "execution context" replaced with "task"

Architecture foundation: [matryoshka-architecture-foundation-4-002.md](matryoshka-architecture-foundation-4-002.md) — deep foundation doc: four layers (Hold/Movement/Lifecycle/Coordination), core concepts, concurrency contract, infrastructure as items, design decisions; New Mindset (002): "ownership" language replaced with "hold"/"holder"/"held" throughout (matches the existing HELD state name), "execution context(s)" replaced with "task(s)"

New Mindset: [matryoshka-new-mindset-001.md](matryoshka-new-mindset-001.md) — Io creates tasks via `io.concurrent()`; a Master is an Io task that follows the Matryoshka rules, not a free-floating role; source of truth driving the README/manifesto/patterns/API-reference/building-blocks rewrite

Latest context: [collected-context-005.md](collected-context-005.md) — project state only

Status: [STATUS.md](STATUS.md) — Sources of Truth pointers + Session Log; latest entry: blank-line-before-list auto-fix script (`kitchen/tools/fix_md_lists.sh`), wired into build_site/preview_site/CI

Thinking model: [matryoshka-model-003.md](matryoshka-model-003.md) — ownership mantra, three-category model, story structure, pool items are empty containers, when to allocate a Master

Rules: [rules-024.md](rules-024.md) — coding, doc, and process rules (+ example completeness rule + Master pattern rule + Observable by human rule + step function parameter rule + structural extraction signals + rules audit checklist item + Description as code rule + descriptive entry-point name rule (plain snake_case, not a quoted identifier — DOC 17) + example doc comment is file-level `//!`, not `///` on the entry point, and ASCII diagrams are fenced code blocks (DOC 17b/17c) + src/ doc comment rule + src/ terminology rule + src/ header staccato standard + sweep verification rule + first-declaration doc-stub rule (DOC 18c) + mkdocs blank-line-before-list rule, now script-enforced via `kitchen/tools/fix_md_lists.sh` (rules-018, rules-023) + Handle naming rule: `ItemHandle` supersedes `NodeHandle`, short form `ih` (was `nh`), bare `handle` is acceptable shorthand (API 4) + Doc-generation module size rule updated: example-autodoc targets removed, hand-organized examples catalog instead (DOC 20) + examples-catalog nav sync rule: `examples/`/`stories/` changes must update `kitchen/mkdocs.yml` nav + group pages + "pitch" added to the AI-sh/banned word list (rules-022) + New Mindset banned words added: object model, execution context, execution model, programming model, paradigm, mindset, ownership, gained — usable in owner/agent conversation, banned from documentation and code comments; `ownership` broadens the prior src/-only rule (rules-012/013) to all docs and comments (rules-024)

Patterns: [patterns-013.md](patterns-013.md) — unified pattern and idiom catalog (DOC 13 + DOC 14): slot/ownership idioms, PolyNode, Mailbox, Topology patterns (Request-Response, Pipeline, Fan-In, Fan-Out), Pool, Futures, Select, Group, cancellation, graceful shutdown, Master patterns — one entry per concept, absorbs the api-reference pattern idioms and the Odin-docs audit findings; New Mindset (013): `Thread.spawn` removed as an accepted task-creation option, `io.concurrent()` only

Plan: [matryoshka-io-implementation-plan-040.md](matryoshka-io-implementation-plan-040.md) — slim state-only plan; rules live in rules-022.md

Storytelling: [../kitchen/docs/matryoshka-storytelling-001.md](../kitchen/docs/matryoshka-storytelling-001.md) — storytelling philosophy and rhythm rules (Discussion, SRS, Translation, Central Insight)

Docs plan: [matryoshka-io-docs-plan-015.md](matryoshka-io-docs-plan-015.md) — documentation work plan (mkdocs + autodocs, tofu audit, iterative DOC stages, top-down site skeleton + first Concepts story + Building Blocks topics: rule/pattern pairing, four core concepts + API reference re-partitioning + manifesto-002 + pattern catalog unification + Odin-docs pattern audit + API reference humanization + first-declaration doc-stub autodoc fix + example autodoc removal + hand-organized examples catalog (DOC 20))

Docs tooling approach: [docs-tooling-approach-002.md](docs-tooling-approach-002.md) — content-authoring method for DOC stages (audit-first parallel source review, triage ad-hoc dumps, narrow top-down scoping)

Kitchen notes: [../kitchen/notes.md](../kitchen/notes.md) — running notes on `kitchen/` tooling and generated content (not versioned, edit in place); currently: which `kitchen/docs/` files are generated vs. hand-authored

Tests (Layers 1-3): [task1-tests-001.md](task1-tests-001.md) — 73 scenarios (Layer1: 1-20, Layer2: 26-52, Layer3: 63-88), correctness/edge cases/contract violations

Examples (Layers 1-4): [task1-examples-003.md](task1-examples-003.md) — 29 scenarios (Layer1: 21-25, Layer2: 53-62, Layer3: 89-92, Layer4: 17-24, 95-96), index only — full description in each source file's `///` doc comment

Tests (Layer 4): [task2-tests-001.md](task2-tests-001.md) — 16 scenarios (1-16), worker lifecycle/shutdown/cancellation. All done.

Examples (Layer 4 + cross-layer): [task2-examples-003.md](task2-examples-003.md) — 45 scenarios (17-31, 32-41, 42-61), index only — full description in each source file's `///` doc comment

Scenarios (historical): [task1-scenarios-001.md](task1-scenarios-001.md), [task2-scenarios-001.md](task2-scenarios-001.md) — original unsplit sources
