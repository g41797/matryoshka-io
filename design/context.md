# Matryoshka Zig — Context Entry Point

## Writing rules
- Short intro, then bullets. Like staccato music.
- One fact per bullet.
- No prose paragraphs with comma-separated lists.

API reference: [matryoshka-api-reference-016.md](matryoshka-api-reference-016.md) — signatures, types, error sets, cancel contract, PolyHelper (+ identifyNodeAs/identifySlotAs + create/destroy + no_create_destroy), slot-based programming, cooperative cleanup patterns, tag identity, infra transport patterns, invariants, thread-safety, complexity, Select internals, receiveResult/getWaitResult

Architecture: [matryoshka-architecture-001.md](matryoshka-architecture-001.md) — why matryoshka exists, concept progression, flows, layers

Latest context: [collected-context-004.md](collected-context-004.md) — project state only

Thinking model: [matryoshka-model-003.md](matryoshka-model-003.md) — ownership mantra, three-category model, story structure, pool items are empty containers, when to allocate a Master

Rules: [rules-010.md](rules-010.md) — coding, doc, and process rules (+ example completeness rule + Master pattern rule + Observable by human rule + step function parameter rule + structural extraction signals + rules audit checklist item + Description as code rule + descriptive entry-point name rule)

Patterns: [patterns-008.md](patterns-008.md) — reusable coding patterns (Observable function shapes, pool, Select, Group, shutdown, dispatch, Master composition + Select event loop and spawn+await coordinator templates)

Plan: [matryoshka-io-implementation-plan-031.md](matryoshka-io-implementation-plan-031.md) — slim state-only plan; rules live in rules-010.md

Storytelling: [../kitchen/docs/matryoshka-storytelling-001.md](../kitchen/docs/matryoshka-storytelling-001.md) — storytelling philosophy and rhythm rules (Discussion, SRS, Translation, Central Insight)

Docs plan: [matryoshka-io-docs-plan-002.md](matryoshka-io-docs-plan-002.md) — documentation work plan (mkdocs + autodocs, tofu audit, iterative DOC stages)

Tests (Layers 1-3): [task1-tests-001.md](task1-tests-001.md) — 73 scenarios (Layer1: 1-20, Layer2: 26-52, Layer3: 63-88), correctness/edge cases/contract violations

Examples (Layers 1-4): [task1-examples-003.md](task1-examples-003.md) — 29 scenarios (Layer1: 21-25, Layer2: 53-62, Layer3: 89-92, Layer4: 17-24, 95-96), index only — full description in each source file's `///` doc comment

Tests (Layer 4): [task2-tests-001.md](task2-tests-001.md) — 16 scenarios (1-16), worker lifecycle/shutdown/cancellation. All done.

Examples (Layer 4 + cross-layer): [task2-examples-003.md](task2-examples-003.md) — 45 scenarios (17-31, 32-41, 42-61), index only — full description in each source file's `///` doc comment

Scenarios (historical): [task1-scenarios-001.md](task1-scenarios-001.md), [task2-scenarios-001.md](task2-scenarios-001.md) — original unsplit sources
