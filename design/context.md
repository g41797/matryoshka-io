# Matryoshka Zig — Context Entry Point

## Writing rules
- Short intro, then bullets. Like staccato music.
- One fact per bullet.
- No prose paragraphs with comma-separated lists.

API reference: [matryoshka-api-reference-019.md](matryoshka-api-reference-019.md) — signatures, types, error sets, cancel contract, PolyHelper (+ identifyNodeAs/identifySlotAs + create/destroy + no_create_destroy), slot-based programming, cooperative cleanup patterns, tag identity, infra transport patterns, invariants, thread-safety, complexity, receiveResult/getWaitResult, mailbox.wakeUpAll — dependency-ordered (DOC 9 + DOC 10): nothing is used before it is introduced; generic std.Io material lives in a trailing Addendums/Io 101 section

Manifesto: [matryoshka-manifesto-003.md](matryoshka-manifesto-003.md) — persuasion-first mindset doc (DOC 11 + DOC 12 plain-language pass): one constraint, Master is a role, four fundamental concepts, Io hidden behind Mailboxes; consolidates README + matryoshka-io-model + matryoshka-master + master-Io; supersedes matryoshka-manifesto.md and -002

Architecture: [matryoshka-architecture-001.md](matryoshka-architecture-001.md) — why matryoshka exists, concept progression, flows, layers

Latest context: [collected-context-004.md](collected-context-004.md) — project state only

Thinking model: [matryoshka-model-003.md](matryoshka-model-003.md) — ownership mantra, three-category model, story structure, pool items are empty containers, when to allocate a Master

Rules: [rules-015.md](rules-015.md) — coding, doc, and process rules (+ example completeness rule + Master pattern rule + Observable by human rule + step function parameter rule + structural extraction signals + rules audit checklist item + Description as code rule + descriptive entry-point name rule (plain snake_case, not a quoted identifier — DOC 17) + example doc comment is file-level `//!`, not `///` on the entry point, and ASCII diagrams are fenced code blocks (DOC 17b/17c) + src/ doc comment rule + src/ terminology rule + src/ header staccato standard + sweep verification rule)

Patterns: [patterns-011.md](patterns-011.md) — unified pattern and idiom catalog (DOC 13 + DOC 14): slot/ownership idioms, PolyNode, Mailbox, Topology patterns (Request-Response, Pipeline, Fan-In, Fan-Out), Pool, Futures, Select, Group, cancellation, graceful shutdown, Master patterns — one entry per concept, absorbs the api-reference pattern idioms and the Odin-docs audit findings

Plan: [matryoshka-io-implementation-plan-038.md](matryoshka-io-implementation-plan-038.md) — slim state-only plan; rules live in rules-015.md

Storytelling: [../kitchen/docs/matryoshka-storytelling-001.md](../kitchen/docs/matryoshka-storytelling-001.md) — storytelling philosophy and rhythm rules (Discussion, SRS, Translation, Central Insight)

Docs plan: [matryoshka-io-docs-plan-012.md](matryoshka-io-docs-plan-012.md) — documentation work plan (mkdocs + autodocs, tofu audit, iterative DOC stages, top-down site skeleton + first Concepts story + Building Blocks topics: rule/pattern pairing, four core concepts + API reference re-partitioning + manifesto-002 + pattern catalog unification + Odin-docs pattern audit)

Docs tooling approach: [docs-tooling-approach-001.md](docs-tooling-approach-001.md) — content-authoring method for DOC stages (audit-first parallel source review, triage ad-hoc dumps, narrow top-down scoping)

Tests (Layers 1-3): [task1-tests-001.md](task1-tests-001.md) — 73 scenarios (Layer1: 1-20, Layer2: 26-52, Layer3: 63-88), correctness/edge cases/contract violations

Examples (Layers 1-4): [task1-examples-003.md](task1-examples-003.md) — 29 scenarios (Layer1: 21-25, Layer2: 53-62, Layer3: 89-92, Layer4: 17-24, 95-96), index only — full description in each source file's `///` doc comment

Tests (Layer 4): [task2-tests-001.md](task2-tests-001.md) — 16 scenarios (1-16), worker lifecycle/shutdown/cancellation. All done.

Examples (Layer 4 + cross-layer): [task2-examples-003.md](task2-examples-003.md) — 45 scenarios (17-31, 32-41, 42-61), index only — full description in each source file's `///` doc comment

Scenarios (historical): [task1-scenarios-001.md](task1-scenarios-001.md), [task2-scenarios-001.md](task2-scenarios-001.md) — original unsplit sources
