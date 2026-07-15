# Candidate Audit — repo-wide .md corpus (001)

Pass 1 audit, whole-repo recursive sweep. Goal: identify which files carry  
reusable ideas for a later composition stage (README.md, landing-short,  
landing-long). Showcase/post variants (Ziggit/Discord/Reddit) are deferred  
to a later stage — not scoped here.

This audit does not compose those docs. It only extracts candidate ideas  
and marks dead/irrelevant files, per the early-discard rule (skim first,  
no close-read on files with nothing salvageable).

Two sub-sweeps, run in parallel by separate agents, merged here:  
Part A covers `design/` + `design/stories/`. Part B covers  
`kitchen/docs/**` (excluding the auto-generated `kitchen/docs/examples/**`  
mirror tree), `README.md`, and misc kitchen files.

---

## Part A — design/ corpus

This audit does not compose those docs. It only extracts candidate ideas and marks dead files.

## DISCARDED

- `design/collected-context-005.md` — pure process/state tracking (stage checklist, test counts, file paths, changelog); zero persuasive/explanatory content.
- `design/docs-tooling-approach-002.md` — pure process doc describing the mkdocs/kitchen tooling workflow; no content for README or landing pages.
- `design/matryoshka-io-docs-plan-015.md` — pure session log / process changelog for doc tooling work, zero persuasive or explanatory content.
- `design/matryoshka-cookbook-structure.md` — a numbered table of contents (200 recipe titles), no prose, no narrative, nothing quotable.
- `design/rules-024.md` — internal coding/doc process rules for contributors, no persuasive value for external-facing docs.
- `design/matryoshka-io-implementation-plan-041.md` — slim state-only project plan (what's done, what's next), zero persuasive content.
- `design/patterns-015.md` — reference catalog of code patterns; intro is a short utility note, not persuasive framing worth pulling on its own.

Not audited (per scope): `design/STATUS.md`, `design/context.md`, `design/task*.md`, `design/matryoshka-io-implementation-plan-040.md` (superseded by -041).

---

## KEPT FILES

### design/boring-manifesto.md

Mindset tag: neutral

- "I don't want another event loop. / I don't want another scheduler. / I don't want another async framework. / I want to solve business problems." — strong staccato opener, could anchor landing-short intro.
- The infrastructure-vs-business-objects contrast: Customer/Order/Invoice/Payment vs Poll/Await/Callback/Completion/Continuation — a vivid concrete example for landing-long.
- "I care that `CreateOrder` arrived." after listing TCP/UDP/QUIC/IPC/shared memory/file/timer — good line for explaining transport-agnostic message arrival. Feeds README or landing-long "why" section.
- "I don't think in sockets. I think in business events." — reusable tagline-style line.
- "I don't want fifty places touching the same state. I want one place. One decision." (reworded from "owner" per style rules) — good for the "place, not share" framing central to New Mindset.
- "When somebody joins the team, I want them to understand the architecture in a week." — good for landing-long "why this architecture" section.
- "Five years later, I want to add a feature. Not rewrite the shape of the system." (reworded) — long-term maintainability argument, landing-long.
- Closing definition of "boring": "Not slow. Not old. Just predictable. Easy to understand. Easy to change. Easy to keep running." — strong closing tagline candidate for README or landing-short.

Feeds: README, landing-short, landing-long

### design/language-of-matryoshka.md

Mindset tag: new-mindset

- Core principle quote: "Share by communicating." / "Rather than sharing access to application objects, communicate the application objects themselves." — central README/landing-long framing line.
- Attribution: "Share the thing by communicating the thing." (Bryan C. Mills) — good citation for credibility, landing-long.
- "Resource limits are resources too." — compact, quotable, feeds landing-short or README as a Pool-explaining aside.
- Four-concept framing: "A Matryoshka system consists of only four architectural concepts: Master, Item, Mailbox, Pool. Everything else exists to support these four concepts." — strong structural backbone for README's core-concepts section.
- Definitive New Mindset Master definition: "A Master is an Io task that follows the Matryoshka rules. Every Master is created by `io.concurrent()`. Not every task is a Master." — must anchor README/landing-long.
- "A worker is simply a Master with a dedicated responsibility." — useful clarifying line, README.
- Item rule: "An Item is in exactly one place at any moment." — crisp, reusable rule statement, README/landing-short.
- "Instead of sharing an Item, pass the Item itself." — good short instructive line.
- Mailbox description: "A Mailbox receives an Item from one Master. It later delivers that Item to another Master. It simply transfers Items." — clean explainer, README.
- Pool description: "Instead of destroying an Item after use, a Master may return it to a Pool. Another Master may later obtain the same Item and use it again." — README.
- Architectural rule block: "Do not share Items. Communicate Items. Move Items between Masters. Reuse Items through Pools. The default operation is movement. Not sharing." — strong staccato closing rule set, landing-short candidate.
- PolyNode framing as implementation detail, not architecture: "PolyNode is no longer the hero of the story — it becomes the elegant implementation technique that makes the architecture possible." — good line for landing-long "how it works" section.
- Reframing tagline: introduce Matryoshka as "an architecture built from Masters that communicate Items," not "a library containing PolyNode, Mailbox and Pool" — strong positioning statement for README opening.

Feeds: README, landing-short, landing-long

### design/master-Io.md

Mindset tag: old-mindset-but-salvageable

Heavy use of "ownership" language throughout; no `io.concurrent()` mention; predates New Mindset framing of Master. Salvage the ideas, not the wording.

- "Io doesn't change how the system is structured. It simply provides additional ways for a Master to receive messages." — feeds README/landing-long "Matryoshka + Io" section.
- "Everything that happens in the system eventually becomes a message delivered to a Master's mailbox." — strong unifying line, README.
- Bridge concept: a component that "waits on Io events and translates them into messages," keeping the Master model pure — feeds landing-long "how event sources work."
- ASCII diagram (Io runtime → Io Bridge (Master) → Master Mailbox → Master) — reusable visual for landing-long.
- "The outside world never calls a Master directly. Everything enters the system as a message delivered to a mailbox." — strong positioning statement, README.
- "Io is just another producer of messages." — good compact tagline.
- "Matryoshka defines how the system is structured. Io defines when work becomes runnable." (reworded) — feeds README's "why both" section.
- "Io is the engine. Matryoshka is the shape of the machine." — good compact metaphor for landing-short.
- "If a developer has to mention Io while designing their system, it is already too visible." — strong design-goal statement, landing-long "philosophy" section.
- "Keep Io powerful. Keep it hidden. Keep Matryoshka clean." — strong closing triad, landing-short/README closing.

Feeds: README, landing-short, landing-long

### design/matryoshka-io-model.md

Mindset tag: neutral

- Capability list framed as questions a Master can do (receive, send, schedule itself, cooperate, borrow/share resources) — compact summary for a README "what a Master does" bullet list.
- Capability-to-primitive mapping table (Receive→Mailbox, Borrow resources→Pool, Heterogeneous data→Type-erased Mailbox/Pool) — reusable reference table for landing-long.
- "Imagine your application consists only of independent Masters communicating through mailboxes and borrowing items from pools. If you can picture your system that way, you're already thinking in Matryoshka." — excellent landing-short hook.
- "Everything else — dispatchers, routers, schedulers, timers, services, actors, pipelines, reactors — is just a Master or a composition of Masters using those three primitives." — strong breadth-of-applicability claim for README.
- Tight ruleset: one input mailbox, process one message at a time, may send to any mailbox including its own, mailboxes/pools may be shared, items may be typed or type-erased — good README "the rules" section.
- Closing self-check: "Can you build your system using only these capabilities? If the answer is yes, Matryoshka is probably a good fit." — good landing-short CTA.

Feeds: README, landing-short, landing-long

### design/matryoshka-io-readme.md

Mindset tag: new-mindset

- "If you want to build a great software system, start by building a software system." — good README opener.
- "We know how to write Zig libraries. We are still learning how to build Zig systems." — strong, distinctive README intro line.
- "Zig Io gives us an excellent foundation for concurrent execution. Matryoshka provides a simple architecture for organizing that execution. It does not replace Io." — clean explainer of the Matryoshka/Io relationship.
- Master definition, alternate phrasing: "Zig creates concurrent tasks through `io.concurrent()`. Matryoshka introduces one architectural concept: Master... Every Master is created by `io.concurrent()`. Not every Io task is a Master." — good phrasing variety for README vs landing pages.
- "Matryoshka is therefore not another runtime. It is a way to organize Io tasks." — strong positioning line, README.
- Item/ItemHandle analogy: "Think about a file. You say: create a file, open a file, close a file. The API actually works with a file handle... you can simply read Item as ItemHandle." — concrete, teachable analogy, unique to this file; good for README or landing-long "API note."
- "Do not share Items. Pass Items. Reuse Items. Communication is the default. Sharing is the exception." — tight staccato rule block, landing-short.
- "Io answers: How do tasks run? Matryoshka answers: How do tasks cooperate?" — good compact contrast, README.
- Incremental-adoption section: "There is no big-bang migration. Start with Items. Introduce Pools when reuse becomes useful. Introduce Mailboxes when communication becomes useful. Organize long-running Io tasks as Masters." — unique "how to adopt" content, strong for landing-long "getting started."
- "It does not introduce: a framework, a runtime, interfaces, inheritance, virtual dispatch." — good README "what this is not" section.
- Closing tagline: "Be Master of your systems." — distinctive, punchy closer, strong candidate for README/landing-short closing line or project tagline.

Feeds: README, landing-short, landing-long

### design/matryoshka-manifesto-005.md

Mindset tag: new-mindset

This is the richest single source in the corpus — nearly every section maps to one of the three targets.

- "If you want to build a great software system, start by building a software system." — strong opener for landing-short or README top.
- Problem framing as a bare question list: "Where are the system boundaries? Who holds which state? How do parts talk to each other? Who controls shared resources? How do parts combine into a system?" — great staccato problem statement for landing-long.
- "Io answers one question well: when does work run?" paired with "Matryoshka answers: how do tasks cooperate?" — the core two-line contrast, reusable everywhere.
- "Matryoshka's promise: make building Zig systems a little more boring." — good tagline, very quotable, landing-short.
- One-constraint framing: "Everything is a Master communicating via Mailboxes" + Pools add "Shared resources are explicit and controlled." — good structural device for README.
- Task-world ASCII diagram (Io tasks → ordinary task / Master → single-job / coordinator / resource-holding Master) — reusable in README and landing-long.
- "A worker is simply a Master with one job." — crisp one-liner, good for README glossary.
- "Down to earth" bullet list (one input mailbox, one message at a time, may send to any mailbox including its own, multiple Masters may share one mailbox, may borrow from pools) — near-verbatim reusable for README "how it works" section.
- Four fundamental concepts block (PolyNode/Mailbox/Pool/Master, "Everything exchanged / Everything communicates / Everything reusable lives here / Everything runs inside one") — strong compact device, reuse in landing-short as a visual/callout.
- "The whole troika is only 582 lines of code." — concrete credibility stat, good for README and landing pages.
- "Where Io fits" bridge diagram: "A timer expired. A socket became readable. A background job finished... Inside the system, all of these are the same thing: a message in a mailbox." — excellent explanatory passage for landing-long.
- "If you have to mention Io while designing your system, it is already too visible." — strong quotable line for landing-short.
- "Start small" incremental adoption section (PolyNode → Pool → Mailbox) — good for README "getting started."
- Closing self-test ("Can you describe your application using only Masters/Mailboxes/Pools") + "Be Master of your systems." — good closer for landing pages.

Feeds: README, landing-short, landing-long

### design/matryoshka-mindset-changing.md

Mindset tag: mixed (transitional document; the "Expanded version" and final "Design" section are the useful new-mindset parts). Treat as a secondary source — mostly confirms/rephrases ideas already in manifesto-005.md and matryoshka-new-mindset-001.md.

- "Io provides execution. Matryoshka provides architecture." — strong two-line summary, reuse in landing-short.
- Old/new stack diagrams — an alternate, simpler rendering of the task-world diagram, useful if the manifesto-005 one feels too dense for landing-long.
- "Matryoshka is no longer running beside Io. It is a layer inside the Io task world." (reworded) — good one-liner for README.
- "Matryoshka requires only Io.Mutex and Io.Condition. Everything else comes from Io itself." — strong stability/credibility argument, reusable in README and landing-long.
- Reframe suggestion: replace "Matryoshka introduces Masters" with "Matryoshka defines a way for Io tasks to cooperate" — good phrasing for README intro.
- Summary line: "Io executes tasks. Matryoshka gives those tasks a small set of rules. Tasks become Masters by adopting those rules." (reworded) — good README closer candidate.

Feeds: README, landing-short (secondary source)

### design/matryoshka-model-003.md

Mindset tag: old-mindset-but-salvageable (heavy "ownership"/"owns" language throughout — needs a place/hold rewrite — but the technical content is sound and not tied to pre-io.concurrent thinking)

- The Mantra, reworded: "Every Matryoshka design starts with one question: Who holds this item right now?" — strong organizing device for a "how to think in Matryoshka" section in landing-long.
- "Route state, not data" principle: pass the object that carries the state, not raw data through a queue — good concrete technical explainer for landing-long's "how it works" walkthrough.
- Transfer rule: an item is held in exactly one place at any moment — user code (in flight), mailbox (held), pool (held); `slot.* = null` is the transfer protocol, "the null is the proof of transfer." — vivid, concrete technical credibility passage.
- "Transfer = lock-free concurrency": one holder at a time means no mutex during processing — strong selling point for landing-long.
- "Pool availability = backpressure signal": `pool.getWaitResult` inside `Io.Select` as first-class event source, "no sleep, no poll, no explicit backpressure code." — strong concrete mechanism for landing-long technical section.
- "Layers compose" diagram (PolyNode → Mailbox → Pool → Master, each answering one question) — reusable structural device, complements the "four fundamental concepts" block in manifesto-005.

Note: the line "Master is a concept, not a type... Any `Io.Select` loop is a Master" is superseded by New Mindset's "Master is an Io task" framing — do not reuse as-is, but the surrounding "no required struct/interface" point still holds.

Feeds: landing-long (primary), README (mantra, layers-compose diagram) — not landing-short (too technical)

### design/matryoshka-new-mindset-001.md

Mindset tag: new-mindset

This is the mindset backbone doc — primary source for README.

- Old vs new stack diagrams (Application/Matryoshka/Io/OS vs. Application/Io tasks [ordinary task / ordinary task / matryoshka task]/Io/OS) — cleaner and simpler than manifesto-005's version; good for landing-short.
- "Io answers: how do tasks run? Matryoshka answers: how do tasks cooperate?" — confirms this is the stable canonical phrasing across the corpus.
- "A Master is not a separate kind of thing next to a task. A Master is an Io task that follows the Matryoshka rules." + "Not every task is a Master. Every Master is a task." — the cleanest, most quotable statement of the New Mindset core claim in the whole corpus. Use verbatim in README and landing-short.
- "`std.Thread.spawn` is banned... Matryoshka code, examples, tests, and stories create tasks one way: `io.concurrent()`." — useful for README's "how to use it" section.
- "Io is large. Io does a lot. Io is easy to get lost in. Matryoshka is small on purpose." — strong staccato passage for landing-short's contrast/value-prop section.
- Minimal dependency: depends only on `Io.Mutex` and `Io.Condition`; "Io may grow new schedulers, executors, or task styles. Matryoshka does not need to change." — reuse in README credibility section.
- "Not a framework" section, cleanest version in the corpus: "Matryoshka does not provide a runtime, Io already does. Matryoshka does not replace `io.concurrent()`. It uses it." (reworded to drop "own") — direct reusable copy for README.
- Closing summary: "Io creates tasks through `io.concurrent()`. A Master is a task that adopts the Matryoshka rules... Matryoshka is not beside Io. It is a small, stable layer... A simple way to start building a large Zig system." — strong closer for README or landing-long.

Feeds: README (primary), landing-short, landing-long

### design/matryoshka-real-world-scenario-001.md

Mindset tag: old-mindset-but-salvageable ("ownership"/"owns" language in requirements and dialogue needs a place/hold rewrite, but the scenario mechanics are current — `Io.Group`, `Io.Select`, `pool.getWaitResult`)

- Whole document is a strong candidate as a worked example/case study for landing-long: a concrete high-stakes domain problem (10,000 camera streams, 64-core server) walked from architect dialogue through SRS through Matryoshka translation to a flow diagram.
- "We route the state, not the data. We create a `StreamContext`... the context holds the encoder state." — reinforces the "route state" principle from matryoshka-model-003.md.
- "The empty recycler is your backpressure signal... the network ingest will listen for empty buffers exactly like it listens for network data." — vivid, concrete restatement of pool-as-backpressure-source.
- Requirement 5 needs a place/hold rewrite ("gains exclusive, lock-free ownership" → "holds a StreamContext exclusively") but the underlying mechanism (fixed pool of 64 workers multiplexing 10,000 streams via a ready queue) is a strong concrete scale story.
- Closing line: "We built a massive-scale actor model without writing a single custom lock or thread manager. Matryoshka handles the lifecycle entirely." — strong, quotable payoff line for a landing-long pull-quote.

Feeds: landing-long (primary — worked case study), README (sparingly — "route state not data," backpressure snippets)

### design/matryoshka-terminology.md

Mindset tag: mixed (a raw brainstorm transcript, not a polished doc — but it contains the most advanced thinking in the corpus on eliminating "ownership" language, arriving independently at "place"/"held" phrasing)

- Three-layer terminology structure: system vocabulary (Task/Master/Item/Handle) first, building blocks (PolyNode/Mailbox/Pool) second, implementation vocabulary (pointer/intrusive/type erasure) last — directly useful for README's terminology section or a glossary appendix.
- Proposed reframe: introduce **Item** as the primary architectural concept before PolyNode. "An Item is a heap-allocated application object that participates in the Matryoshka architecture. Every Item embeds a PolyNode..." — strong candidate for README's opening definition.
- Simpler one-line Item definition: "An Item is a movable application object." — landing-short-friendly.
- Mailbox reframe: "Mailbox transfers Items... Mailbox operates on the embedded PolyNode. Therefore Mailbox never needs to know the concrete Item type." — good README passage.
- Already-worked-out anti-ownership language: "An Item can belong to only one place at a time." — near-exact match for this audit's own style rules; reusable in README and both landing pages as the core invariant statement.
- "Sharing is the exception. Moving is the default." — excellent short slogan for landing-short.
- "One Master uses an Item, or one Mailbox holds it, or one Pool holds it. Never multiple places simultaneously." — reusable near-verbatim.
- Verb-swap guidance directly actionable for future composition: replace "owns Items" → "uses Items"/"works with Items"; replace "transfers ownership" → "passes an Item"/"hands an Item to another Master." Worth carrying forward as a rule, not just content.
- Design-lineage section citing Bryan C. Mills: "Share resources by communicating the resources themselves. Resource limits are resources too." Proposed README passage: "Matryoshka is built around a simple concurrency principle: Share by communicating." — strong credibility/lineage section for README.
- Architecture-role table: Master = execution and holding, Item = state, Mailbox = communication, Pool = resource reuse — clean four-row summary for README or landing-short.
- Phrasing caution worth preserving: prefer "Items are designed to outlive the function that created them" over "Items are long lived," to avoid implying they can't be single-use.

Feeds: README (primary — solves the exact terminology problem README needs), landing-short (slogans), landing-long (Share-by-communicating lineage section)

### design/matryoshka-architecture-003.md

Mindset tag: new-mindset

- Opening frame: concurrent systems built from independent components exchanging work items (sensor, processor, logger, monitor example) — good README/landing-long scene-setter.
- Four hard constraints: no shared mutable state, no allocations on the hot path, components should not know each other's concrete types, each item's place must be clear at every moment — strong bullet list for landing-long or README "why."
- Four named ad-hoc failure modes ("Raw pointers, no place discipline," "Allocator-per-message," "Type-specific queues," "Manual lifecycle") each with a crisp one-line diagnosis — good for a "problems we avoid" section.
- "What was needed" box: universal transfer, zero allocations after initialization, type-safe recovery without generics pollution, each item in exactly one place always — reads like a tagline list, feeds README and landing-short directly.
- Before/after contrast: "Where an item is stays implicit — bugs hide" vs "Where an item is stays explicit — Slot is full or empty." — quotable contrast for landing-short.
- Six-step concept build (Node → Tag → Slot → Mailbox → Pool → Master/Select) — this progression is a great structure for a landing-long "how it works" section.
- "You hold it." / "You don't hold it." — visceral one-liners for a landing-short callout.
- Transfer rule: "send: Full → Empty (you gave it away). receive: Empty → Full (you got one). No ambiguity. No double hold." — good README snippet.
- Mailbox framing: "Not messages — the item itself. Not copies — the original handle moves." — valuable differentiator line vs typical message-passing systems.
- "The component does not poll. It reacts." — punchy, quotable.
- Layer map (matryoshka root → master → mailbox/pool → polynode → std.DoublyLinkedList), "dependencies flow down, never up" — simple, strong architectural claim for README.
- "No dependencies beyond std.DoublyLinkedList" — nice minimalism claim for landing-short.

Feeds: README, landing-short, landing-long

### design/matryoshka-architecture-foundation-4-004.md

Mindset tag: new-mindset

The deepest foundation document in the corpus. Very long, mine it hard.

- Opening thesis: "Hold should always be visible." And: "Most concurrency systems focus on execution... Matryoshka focuses on hold." — strong landing-short tagline candidate.
- Recurring organizing question: "Who holds this item right now?" — excellent recurring motif for README/landing pages.
- "The goal is not to build a framework. The goal is to provide a small set of concepts that can be combined into larger systems while preserving visible hold." — good README mission statement.
- Why-it-exists framing: different subsystems answering the same lifecycle questions differently produces "multiple rule sets inside the same application" — strong pain-point paragraph for landing-long.
- "The goal is not maximum abstraction. The goal is not maximum performance. The goal is reducing ambiguity." — reusable three-line rhetorical structure for landing-short.
- Bug classes visible-hold helps with: forgotten cleanup, double destruction, use-after-free, accidental sharing, unclear shutdown ordering, lifecycle leaks — good README bullet list.
- Four core rules of Hold: "At any moment an item has exactly one holder. Hold may belong to user code, mailbox, or pool. Hold must never be shared. Hold may only move." — core doctrine, feeds README and both landing pages.
- MayItem: "held item or nothing" — "a programmer can see hold simply by looking at the variable state." — concrete illustration of visible-hold in practice.
- Four hold states (FREE, HELD, IN_FLIGHT, INVALID) with crisp one-line definitions — good glossary material for README reference section.
- "Hold always moves. It never duplicates. That single rule removes an entire category of shared-state problems." — strong closing-punch sentence, landing-short candidate.
- Layer-by-layer "why stop here" framing: each layer is explicitly optional, "Matryoshka does not require adopting all layers." — distinctive composability-as-a-feature framing, worth README emphasis (nested-doll metaphor payoff).
- Mailbox definition, tight: "not actor framework, scheduler, service bus, or workflow engine. Its only purpose is moving hold." — good differentiation line.
- No-silent-data-loss guarantee at shutdown: "Every item ends up in exactly one holder's hands." — valuable correctness claim for landing-long/README trust-building section.
- Pool reframed sharply: "Pool is not storage — it is a backpressure signal for reuse." — strong differentiator vs typical "object pool" mental model, good for README/landing-short.
- "Open the third doll only when allocation and destruction become painful enough to justify it." — great nested-doll metaphor sentence, ties directly to the project name.
- Master definition: "A bounded execution domain that coordinates hold movement, lifecycle management, and subsystem policy... think of Master as subsystem, not object." — core New Mindset framing.
- Valid Master shapes table (PolyNode only / +Mailbox / +Pool / +Mailbox+Pool / +Pool+Select / full stack) — demonstrates flexibility/composability concretely for landing-long.
- Sharp rule: "Interrupt != Cancel. Interrupt means wake up and do something. Cancel means stop." — good technical-credibility snippet, landing-long "how it works" page.
- "A mailbox can be an item. A pool can be an item... The goal is not abstraction. The goal is consistency." — distinctive idea worth a callout.
- Non-goals list (not an actor framework, not a messaging framework, not a scheduler, not a runtime, not a DI framework, not a service container, not a GC, not a replacement for application architecture) — excellent README "what this is not" section, honest scope-setting.
- Closing architecture summary: each layer introduces exactly one new capability, "a system may stop at any layer" — probably the single best distilled paragraph in the corpus for a README "at a glance" box.
- Mantra, repeated twice in the doc: "acquire, transfer, recycle, dispose" — good compact tagline/footer.

Feeds: README, landing-short, landing-long

### design/matryoshka-api-reference-025.md

Mindset tag: new-mindset (explicitly: "Io creates tasks through `io.concurrent()`. Master is an Io task that follows the Matryoshka rules")

Note: the bulk of this file (steps 1-7, PolyHelper mechanics, error tables, cancel model) is mechanical reference material, not narrative — skip that for composition. Kept specifically for the framing sections below.

- Opening pitch: "Matryoshka is a small infrastructure toolkit. It provides three independent building blocks: polynode (type identity), mailbox (message passing), pool (object lifecycle)." — clean one-line pitch usable almost verbatim.
- "Applications combine these blocks to create: coordinators, workers, services, pipelines, other higher-level architectures." — good "what you can build" line.
- Core rule: "Every object follows the same rule: one place, one state, at any moment." — single-sentence distillation of the whole design, no jargon.
- "Matryoshka moves handles from one place to another." — plain-language mechanism description.
- "A Slot is where a handle lives while it is yours." — accessible explanation of Slot for a general reader.
- Master section: "No `master` module. No `Master` struct. By design." followed by "Master is an Io task that follows the Matryoshka rules — the coordination boundary. It holds and composes the lower layers." — the cleanest existing statement of the New Mindset Master model in the whole corpus.
- Pool framing: "Pool is not storage. It answers one question: is a reusable item available right now. It signals backpressure through that answer." — strong "why pool matters" line, reusable standalone.

Feeds: README, landing-short, landing-long

### design/matryoshka-io-0.16-implementation-guide-001.md

Mindset tag: mixed — framing section is old-mindset-but-salvageable ("ownership" language throughout, needs rewording), later sections correctly reference `io.concurrent()`.

Caution: large (2200+ line) implementation/porting guide; only the framing paragraphs below are non-mechanical. The rest (constraint tables, struct definitions, cancellation mechanics, porting notes) is pure implementation detail — skip for composition.

- "Matryoshka is a handle-transfer and lifecycle system. It is not an I/O framework." (reworded from "ownership-transfer") — sharp positioning line.
- "`std.Io` carries the wait operations. It controls how suspension happens, not what it means." — good line distinguishing Matryoshka's role from `std.Io`'s.
- "Master is a role, not a type... Mailbox and Pool are concrete infrastructure — specific structs, specific APIs. Master is different. Master is a coordination boundary." — strong explanatory paragraph, reinforces api-reference's framing with different wording, good for variety.
- "Mailbox and Pool are infrastructure. Master is architecture." — pull-quote-worthy contrast line.
- "Mailbox-less coordination" — "Mailbox is optional. Pool + Io can be the primary coordination model," with concrete examples (job scheduling, resource management, capacity-controlled pipelines) — illustrates flexibility, Matryoshka isn't one rigid shape.

Feeds: landing-long (primary), README, landing-short (pull-quote lines)

### design/stories/print-server-002.md

Mindset tag: new-mindset (mailbox/pool/handle vocabulary correct, no `Thread.spawn`; dialogue uses "owns"/"ownership" — needs a place/hold pass before reuse, scenario itself is sound)

The best "show, don't tell" material in the corpus — a full three-way dialogue (client, spooler, printer driver) walking through a realistic print-server design, no jargon required to follow it.

- Closing line of Part 1 (needs "owns"→"holds" edit): "At any moment, whoever holds the job holds the problem." — strong, quotable takeaway, repeated later as "the central insight."
- "The central insight": "No shared status table. No polling. No ownership ambiguity. Responsibility follows location." (reword "ownership ambiguity") — tight staccato summary of the design philosophy in miniature.
- "You submit, move on, and wait for a result on your own channel." — plain-language explanation of non-blocking submission + reply-channel pattern, no code needed.
- Driver's line (reworded): "That is why I do not need locks while printing. I am the only holder... Either I finish and send the result, or I fail and send the result." — demonstrates why single-place-at-a-time removes the need for locks/status tracking, in relatable terms.
- Part 4's flow diagram (spool → printer → per-client reply) — clean concrete visualization, reusable as a diagram or paraphrased example.

Feeds: landing-long (illustrative walkthrough/embedded excerpt)

### design/stories/print-server-analysis-001.md

Mindset tag: neutral

- "Story 1 teaches: the pool is not storage. It is a backpressure signal... Story 2 teaches: [holding] is not just resource management. It is synchronization. The job's location answers every status question without a shared table, without polling, without locks." (reword "ownership") — crisp two-sentence contrast framing why the two stories matter together.
- Rationale for choosing the print-server domain: "Every engineer knows what a print server does... Neither requires explaining." — useful judgment to carry forward for how landing pages should pick illustrative material (not directly quotable, but informs later composition choices).

Feeds: landing-long (framing rationale, secondary source)

### design/stories/video-transcoder-003.md

Mindset tag: new-mindset (uses `Io.Group`, `io.concurrent`, pool/mailbox vocabulary correctly; no `Thread.spawn`; cleanest of the story files)

- Opening scenario is immediately relatable at scale: "We receive thousands of uploaded videos every day... We have cameras. Thousands of them. Live feeds... memory is the hard constraint." — sets stakes without any Matryoshka vocabulary.
- "No buffer, no decode. The constraint is structural." — turns "backpressure" into a one-line, code-free explanation. Highly quotable.
- "Then we are not routing frames. We are routing state. The frame attaches to the camera state. A worker picks up the state and processes the attached frame." — a nice "aha" moment explaining per-camera-state routing in plain terms.
- "The central insight": "Pool exhaustion is backpressure. No free buffer — no decoded frame. No coordinator. No signal. No rate manager. The constraint is structural." — even starker than the api-reference's pool framing, strong pull-quote candidate.
- Exchange: "A free buffer is the signal. No buffer, no decode." / "You do not need a separate signal to stop?" / "No." — good compact illustration that structural constraints replace explicit coordination, a core selling point.
- Part 4 flow diagram (pool-as-event-source + mailbox-as-transport + `Io.Group` workers) — clean visual reference/paraphrase candidate.

Feeds: README (pull-quotes), landing-short, landing-long (worked case study)

---

## Part B — kitchen/docs + README corpus

Sibling audit covers design/*.md separately.

## KEPT files

### /home/g41797/dev/root/github.com/g41797/matryoshka-io/README.md

Mindset tag: new-mindset

Current, live README — already the target shape for composition, treat as  
baseline rather than raw material.

- "If you want to build a great software system, start by building a
  software system." — strong opening line. Feeds README, landing-short.

- "Zig Io makes developers' lives even more interesting. Matryoshka is an
  attempt to make them a little more boring." — core tagline. Feeds  
  README, landing-short, landing-long.

- "A worker is simply a Master with a single dedicated responsibility." —
  clean one-liner. Feeds README, landing-long.

- "Containers on steroids" section (PolyNode/Mailbox/Pool = Node's bigger
  brother + steroids: intrusion, type erasure, item transfer, item reuse)  
  — good plain-language explainer. Feeds landing-long.

- "Io answers: how do tasks run? Matryoshka answers: how do tasks
  cooperate?" — crisp division of responsibility. Feeds README,  
  landing-short, landing-long.

- "Try Matryoshka without fear" / incremental-adoption section (start with
  PolyNode, add Pool, add Mailbox) — feeds landing-long ("getting  
  started" framing).

- "Be Master of your systems." — closing line/tagline. Feeds README,
  landing-short.

### /home/g41797/dev/root/github.com/g41797/matryoshka-io/kitchen/_logo/logo-description.md

Mindset tag: neutral

Image-generation prompt for the mascot logo, not narrative text — low  
yield, but has two quotable lines.

- Mood framing: not "look at this funny joke" but "these two finally
  found each other" — matches the README "boring" tagline; useful tone  
  reference for landing-long's introduction, not literal copy.

- Version-cans detail (0.11...0.16, one more turned around, unreadable)
  — "the future isn't written yet" — nice metaphor, marginal value,  
  visual/marketing only, not doc prose.

### kitchen/docs/addendums/matryoshka-and-rethinking.md

Mindset tag: old-mindset-but-salvageable

Comparison piece against "Rethinking Classical Concurrency Patterns"  
(Go paper). Every pattern is phrased through banned "ownership" language  
("Ownership is the message", "One object. One owner.") — needs a  
hold/place rewrite pass before reuse, but the underlying arguments are  
strong and on-topic.

- Pattern 1 "Communicate the object" — send the object itself, not a
  pointer+signal or index+signal. Feeds landing-long (differentiator  
  vs. classic channel patterns).

- Pattern 4 "No detached notifications" — condition variables split data
  and notification (forgotten signal, spurious wakeup, starvation,  
  cancellation problems); Matryoshka's Mailbox removes the split because  
  receiving data *is* the notification. Feeds landing-long.

- Pattern 9 "Cancellation is another channel" — three independent paths
  (DATA / INTERRUPT / CANCEL), each with one purpose, no mixing. Feeds  
  landing-long (technical differentiator).

- Pattern 13 "Infrastructure is boring" — "Developers do not build
  synchronization. They build software." Feeds README, landing-short.

- Closing contrast: "The paper communicates values. Matryoshka
  communicates [holding]. ... Concurrency becomes almost boring." — good  
  closing rhythm, needs "ownership"→"holding"/"place" rewrite. Feeds  
  landing-long.

### kitchen/docs/addendums/matryoshka-what-is.md

Mindset tag: new-mindset

Early draft of what became the current README's "What is Matryoshka"  
framing — largely superseded by README.md itself but has a few lines not  
in the current README.

- "It is a small 'frame': visible code, several rules, restricted Io
  usage, common way of thinking." — an alternate framing of "what  
  Matryoshka is" distinct from the current README's wording. Feeds  
  README (alternate phrasing to consider), landing-short.

- "Matryoshka does not think for you. You still design the system. You
  still solve the hard problems. It simply brings a little more order to  
  your thinking." — good expectation-setting paragraph, not in current  
  README. Feeds landing-long.

- "Start from a 'whiteboard'... Not from code. Not from a prompt." —
  the memorable sentence also called out explicitly in  
  placement-separation.md as worth preserving everywhere. Feeds README,  
  landing-short, landing-long.

### kitchen/docs/addendums/placement-separation.md

Mindset tag: neutral (meta/strategic notes, not narrative prose itself)

This is feedback/guidance about *where* content should live — README vs.  
doc-site landing vs. Ziggit showcase post — written for exactly the  
composition stage this repo is planning. Durable strategic input, not  
extractable prose.

- Placement guidance: README = canonical full text; doc site first page
  should answer only "What is Matryoshka? Should I keep reading? Where do  
  I start?" with everything else as links; Ziggit showcase should show,  
  not explain, and open with a short first-person framing line.

- Explicit style guidance: don't mention AI/LLM-assistance anywhere;
  short sentences, imperfect but honest English, admitting limitations  
  ("today this only works with Threaded Io", "this is an attempt") reads  
  like an engineer, not like generated prose.

- Flags "Start from a whiteboard. Not from code. Not from a prompt." as
  the one sentence worth preserving everywhere — corroborates the same  
  find in matryoshka-what-is.md.

Feeds: process input for the later composition stage itself, not README/  
landing-short/landing-long prose directly.

### kitchen/docs/addendums/slot-vs-ref-counting.md

Mindset tag: new-mindset

Technical addendum, no banned-word issues. Good analogy value.

- "A Slot answers: who holds this object right now? Reference counting
  answers: how many holders exist?" — the two-question framing. Feeds  
  landing-long.

- "Matryoshka's model is closer to passing a parcel from hand to hand
  than to a shared object graph everyone can see at once." — strong  
  analogy. Feeds landing-long, possibly landing-short.

### kitchen/docs/addendums/tag-vs-tagged-union.md

Mindset tag: new-mindset

Technical addendum comparing PolyNode tags to Zig tagged unions —  
reference-quality, minor persuasive value.

- "Tagged unions answer 'which variant is this value?' PolyNode tags
  answer 'which concrete object sits behind this type-erased pointer?'"  
  — precise, quotable contrast. Feeds landing-long (technical depth  
  section).

### kitchen/docs/addendums/typeErasedQueue-vs-mailbox.md

Mindset tag: new-mindset

Technical addendum, no banned-word issues. Strongest analogy of the  
addendums set.

- "A Mailbox is not really a queue... A queue stores values. A Mailbox
  moves the object that already exists from one holder to the next." —  
  crisp differentiator. Feeds landing-long.

- Four-responsibilities table (Mailbox = sync + moving, Pool = lifecycle/
  capacity/reuse, Allocator = memory, Master = scheduling/policy) — good  
  compact architecture summary. Feeds landing-long.

### kitchen/docs/addendums/why-boring.md

Mindset tag: mixed (persuasive tone matches New Mindset, but uses literal  
"owner"/"one owner" framing that needs a hold/place rewrite)

The single strongest persuasion-only piece in the whole corpus — written  
as a first-person "boring enterprise programmer" voice. High reuse value  
for README and both landing pages.

- "I don't want another event loop. I don't want another scheduler. I
  don't want another async framework. I want to solve business  
  problems." — strong opening voice. Feeds README, landing-short.

- "Sockets are not my business... Networking is infrastructure... I
  don't want them leaking into every function." Feeds landing-long.

- "When a message arrives, I don't care if it came from TCP/UDP/QUIC/
  IPC/shared memory/a file/a timer. I care that CreateOrder arrived." —  
  concrete, memorable illustration of "business events, not sockets."  
  Feeds landing-long.

- "I don't optimize first. I optimize after measuring. Most engineering
  time is spent understanding code. Not making it 3% faster." Feeds  
  landing-long.

- "Five years later, I want to add a feature. Not rewrite the execution
  model." — needs "execution model" swapped for a non-banned phrase, but  
  the sentiment is strong. Feeds landing-long.

- Closing definition: "That is the mindset behind a 'boring system.' Not
  slow. Not old. Just predictable. Easy to understand. Easy to change.  
  Easy to keep running." — excellent closer, needs "mindset" swapped for  
  something else (banned word except when discussing New Mindset itself).  
  Feeds README, landing-short, landing-long.

### kitchen/docs/building-blocks/index.md

Mindset tag: neutral (near-stub, but has a reusable rhetorical device)

Four one-line nav entries, minimal prose — normally would discard, kept  
for one phrase pattern.

- The four parallel one-liners — "PolyNode: everything exchanged. /
  Mailbox: everything communicates. / Pool: everything reusable lives  
  here. / Master: everything runs inside one." — a strong four-beat  
  rhetorical structure, reusable as a README/landing section skeleton.  
  Feeds README, landing-short.

### kitchen/docs/building-blocks/mailbox.md

Mindset tag: mixed (New Mindset structure, but "owner"/"ownership"  
appears repeatedly — "moves a handle from one owner to another," "the  
ownership atom," "no ownership ambiguity" elsewhere in the set)

- "This is how a worker signals 'I'm done': it sends its own Mailbox back
  to whoever is coordinating it, instead of a separate finished-message."  
  — concrete, memorable idiom. Feeds landing-long.

- "Mailbox and Pool are containers on steroids — the steroid here is
  [transfer] without copying." Feeds landing-long (echoes README, needs  
  ownership-word swap).

### kitchen/docs/building-blocks/master.md

Mindset tag: new-mindset

Closely matches README's Master framing; adds the cancel-vs-close  
distinction cleanly.

- "Cancel — the scheduler says stop waiting right now... Close — the
  Master itself says this Mailbox or Pool is shutting down. That's a  
  deliberate decision, not something imposed from outside." Feeds  
  landing-long.

- "That's the whole point: a Master is whatever shape your problem needs,
  built from three small, fixed pieces." — good closing line for a  
  Master section. Feeds README, landing-long.

### kitchen/docs/building-blocks/polynode.md

Mindset tag: mixed (New Mindset structure, "ownership"/"owner" used  
literally throughout — "the ownership atom," "who owns this item right  
now")

- "Ownership must be visible at the call site. If you need to read the
  implementation to know who [holds] an item, the design is wrong." —  
  strong design-principle sentence, needs word-swap. Feeds landing-long.

- "A handle is what Matryoshka actually moves: a pointer to the embedded
  PolyNode, never the object itself." Feeds landing-long (precise, no  
  banned words).

### kitchen/docs/building-blocks/pool.md

Mindset tag: new-mindset (mostly clean — "Pool is not storage" framing  
already matches current API docs)

- "A Pool is not storage." / "An empty Pool is a signal, not an error." —
  the two-line thesis of the whole Pool concept. Feeds README,  
  landing-short, landing-long.

- "Reuse and backpressure come from the same mechanism: a fixed number of
  slots. The constraint is structural — nobody has to remember to check  
  capacity." Feeds landing-long.

### kitchen/docs/concepts/index.md, print-server-the-system.md, print-server-with-matryoshka.md

Mindset tag: mixed (new-mindset structure, but domain page uses literal  
"owns"/"ownership" heavily — kept for narrative strength despite  
CLEANUP_CANDIDATES.md flagging these as nav-dropped/superseded)

Best worked example in the corpus of "plain domain story, then the same  
story mapped onto the four concepts" — directly reusable as the  
landing-long worked-example section, or as the seed for a future  
cookbook entry.

- "At any moment, whoever holds the job owns the problem." — the central
  insight line, repeated verbatim in kitchen/docs/story/print-server/  
  discussion.md and translation.md. Strongest one-liner candidate for  
  landing-long's "why this shape" section (word-swap "owns" if literal  
  compliance required).

- "Submission and result are separate. A client submits, moves on, and
  waits for a result on its own channel — an application should never  
  block on a slow printer." — clean illustration of async request/  
  response without jargon. Feeds landing-long.

- "No shared status table. No polling. No ownership ambiguity.
  Responsibility follows location." — compact restatement of the  
  insight. Feeds landing-short, landing-long.

- Full requirements list (12 bullets: ack immediately, ordered dispatch,
  one holder at a time, cancel priority via OOB, clean shutdown loses no  
  jobs) — solid worked-example content if a cookbook/worked-example  
  section is built later.

### kitchen/docs/deep-dive/video-transcoder.md

Mindset tag: new-mindset

Rich narrative — a discussion-style dialogue (Dec/Fil/Enc/Operator/  
Operations) about a video pipeline, ending in the same "central insight"  
pattern as the print-server story. Strong second worked-example.

- "A free buffer is the signal. No buffer, no decode. The constraint is
  structural." — direct echo of the Pool thesis in plain narrative form.  
  Feeds landing-long.

- "The central insight. Pool exhaustion is backpressure. No free buffer —
  no decoded frame. No coordinator. No signal. No rate manager. The  
  constraint is structural." Feeds README (as a proof point), landing-  
  long.

- The Discussion format itself (engineers negotiating responsibilities in
  plain dialogue before any Matryoshka vocabulary appears) is a reusable  
  narrative device for a future landing-long "how would this apply to my  
  system" section.

### kitchen/docs/index.md

Mindset tag: neutral (pure nav stub, kept for one line)

- Tagline: "Matryoshka-Io — a practical way to build great software
  systems" / subhead "Building Blocks for Modular Monoliths" — the  
  second phrase doesn't appear in the current README and is a candidate  
  alternate subhead. Feeds README (candidate subhead), landing-short.

### kitchen/docs/manifesto.md

Mindset tag: new-mindset

The single richest source file in the corpus — a full persuasion-first  
document, largely consistent with the current README's voice but longer  
and covering ground the README doesn't. Primary feed for landing-long.

- "Matryoshka's promise: make building Zig systems a little more
  boring." — restates the README tagline as a promise. Feeds README.

- "Everything is a Master communicating via Mailboxes" / "Shared
  resources are explicit and controlled" — the two-constraint framing,  
  more explicit than the README's "one main concept" framing. Feeds  
  landing-long.

- "you always know who owns what... you can swap one Master for another
  ... you can understand one Master without reading the whole system" —  
  concrete payoff list for accepting the constraint (needs "owns" word-  
  swap). Feeds landing-long.

- "The bridge is just another Master. It waits on Io events and turns
  them into ordinary messages... A good design test: if you have to  
  mention Io while designing your system, it is already too visible." —  
  strong, not present in current README. Feeds landing-long.

- "A simple question. Can you describe your application using only:
  Masters / Mailboxes / Pools. If the answer is yes, you're already  
  thinking in Matryoshka." — good closing test/hook. Feeds landing-short,  
  landing-long.

- "The whole troika is only 582 lines of code." — a concrete, credible
  smallness claim not in the current README (verify line count is still  
  accurate before reuse). Feeds README, landing-short.

### kitchen/docs/matryoshka-based-systems.md

Mindset tag: new-mindset (flagged superseded/stub in CLEANUP_CANDIDATES,  
kept — short but well-compressed summary)

- "Most libraries document features. Matryoshka documents architectures.
  Read this page and think: 'that's how my server looks.' Not: 'that's  
  how their queue works.'" — distinctive opening framing, not present  
  elsewhere in the corpus. Feeds README, landing-short.

### kitchen/docs/the-shape.md

Mindset tag: mixed (New Mindset structure; "ownership" used as one of  
three named "pains")

Presents the value proposition as "three pains, three blocks" — a good  
rhetorical structure distinct from the manifesto's approach.

- Pain framing: ownership (who frees this?), allocation (buffer per
  request, thrown away), coupling (interface/vtable needed just to pass  
  work between roles) — mapped 1:1 to PolyNode/Mailbox/Pool. Feeds  
  landing-long (needs "ownership" pain relabeled, e.g. "who holds this,  
  who frees it").

- "The std.Io box has not moved. It still does readiness, wait, cancel.
  Matryoshka uses it. Matryoshka does not replace it." — clean restate of  
  the Io/Matryoshka division of labor. Feeds landing-short, landing-long.

### kitchen/docs/story/print-server/discussion.md

Mindset tag: new-mindset

The best pure-dialogue narrative in the corpus — three engineers (C/S/D)  
negotiating the print-server design with no Matryoshka vocabulary at all  
until the closing line. Distinct file from concepts/print-server-the-  
system.md (that one is prose-summary form; this one is live dialogue).

- Full C/S/D dialogue — strong candidate to excerpt directly into
  landing-long as a "how architecture gets negotiated" example.

- "At any moment, whoever holds the job owns the problem." — same
  closing insight as concepts/print-server-the-system.md and story/  
  translation.md; this file is the original source of the line.

### kitchen/docs/story/print-server/requirements.md

Mindset tag: neutral

Near-duplicate of the requirements list already in kitchen/docs/concepts/  
print-server-the-system.md — kept as the single reference copy of the  
requirements list (12 bullets), not for new extraction. Feeds landing-  
long only if the worked-example section needs the requirements verbatim.

### kitchen/docs/story/print-server/translation.md

Mindset tag: new-mindset

Near-duplicate of concepts/print-server-with-matryoshka.md, formatted as  
compact requirement→Matryoshka-mapping pairs rather than prose. Useful as  
a terser alternate form of the same content if landing-long wants a  
compressed table instead of prose.

### kitchen/docs/story/print-server/flow.md

Mindset tag: neutral

ASCII flow diagram, identical to the one embedded in concepts/print-  
server-with-matryoshka.md — kept as the single reference copy of the  
diagram, not new extraction.

### kitchen/docs/misc/README-15-07-2026.md

Mindset tag: new-mindset

Byte-for-byte snapshot of the current README.md (dated draft copy) — no  
new content versus README.md itself. Kept per instructions (explicitly  
named as important) but yields nothing beyond what's already captured  
under README.md above.

### kitchen/docs/misc/readme-landing.md

Mindset tag: new-mindset

A shorter, more clipped alternate README draft — same ideas as the  
current README but terser, more "manifesto-lite" in rhythm. Good source  
for landing-short specifically, since it's already been compressed once.

- Subhead: "A practical way to build concurrent software systems with Zig
  Io." — terser than the current README's subhead, good landing-short  
  candidate.

- "It gives Io tasks a common language and a repeatable structure." —
  compact restatement of Matryoshka's value, not in current README.  
  Feeds landing-short.

- Four-concept list here is "Master / Item / Mailbox / Pool" (uses
  "Item" instead of "PolyNode") — a naming variant worth flagging: the  
  rest of the live corpus (README, manifesto, building-blocks) uses  
  PolyNode/Mailbox/Pool/Master as the four concepts. This file and the  
  other misc/ drafts below treat "Item" as a named concept in place of  
  PolyNode. Flag for the composition stage — pick one vocabulary.

- "Move Items. Do not share Items. Reuse Items. Keep responsibilities
  local." — punchy four-line summary, good landing-short candidate  
  structure (needs vocabulary reconciled per above).

### kitchen/docs/misc/how-matryoshka-system-works.md

Mindset tag: old-mindset-but-salvageable

Uses "ownership" as the literal named central rule ("Ownership is the  
central rule of Matryoshka") and a section literally titled "The  
programming model" — both hit the banned-word list hard. Salvageable  
structure, needs a full rewrite pass, kept for the "three pains"-style  
compression it offers.

- "Share by communicating. Instead of sharing application objects,
  communicate the application objects themselves." — good one-line  
  restatement of the core idea, reusable once "ownership" framing around  
  it is removed. Feeds landing-short (as a pull-quote), landing-long.

- Four-concept table (Master/Item/Mailbox/Pool) with one-paragraph
  definition each — cleanly separable if rewritten without ownership  
  language and reconciled against the PolyNode-based vocabulary used  
  elsewhere.

### kitchen/docs/misc/matryoshka-io-ads.md

Mindset tag: old-mindset-but-salvageable

Drafted as a first-person Ziggit forum-introduction post — directly  
matches the "Ziggit Showcase" audience placement-separation.md describes.  
Heavy "ownership" language throughout, needs a rewrite pass, but the  
framing device (introduce, then show, not explain) is exactly right for  
that audience per the placement-separation.md guidance.

- Opening framing: "Hello everyone. I'd like to introduce Matryoshka-Io.
  It is an architectural layer built on top of Zig Io. Not a framework.  
  Not another runtime. Not another event loop." — good literal template  
  for a future forum-post landing variant, not README/doc-site material  
  itself but relevant if a third "showcase" doc gets composed later.

- "Current state" section — an honest, unpolished "still evolving,
  feedback welcome" closing, matching the placement-separation.md advice  
  to admit limitations rather than polish them away. Not README material,  
  useful pattern reference only.

### kitchen/docs/misc/what-is-matryoshka-io.md

Mindset tag: old-mindset-but-salvageable

Same four-concept model as the other misc/ drafts (Master/Item/Mailbox/  
Pool), heavy "ownership"/"owned" language, but has the clearest single  
paragraph in the corpus framing the core problem as a set of unanswered  
questions.

- "Concurrent programming becomes difficult when ownership is unclear.
  Who [holds] this object? Who may modify it? Who destroys it? Can  
  another task use it now? Matryoshka answers these questions with  
  simple architectural rules instead of conventions." — strong problem-  
  statement paragraph, needs word-swap, otherwise ready to use. Feeds  
  README, landing-long.

- "Think about architecture first" section — another variant of the
  "start with a whiteboard... then write the code" sentence already  
  flagged as high-value in matryoshka-what-is.md and placement-  
  separation.md. Third independent occurrence — strong signal this line  
  belongs in the final composition.

## DISCARDED files

- `kitchen/docs/examples/**` (entire directory, ~80 files) — auto-
  generated mirror pages of examples/ source, mechanical output not  
  narrative content, out of scope for README/landing composition.

- `kitchen/notes.md` — pure tooling/process notes (generated vs.
  hand-authored file inventory), zero persuasive or explanatory value for  
  README/landing.

- `kitchen/CLEANUP_CANDIDATES.md` — pure process/bookkeeping list of
  files pending deletion, zero narrative content.

- `kitchen/docs/api/cancel-and-lifecycle.md` — API reference (tables,
  cancel contract, object-lifecycle states), code-focused technical  
  reference, not narrative source for README/landing.

- `kitchen/docs/api/cleanup.md` — API reference (cooperative cleanup code
  patterns), same reason.

- `kitchen/docs/api/invariants.md` — API reference (invariants, thread-
  safety table, complexity table, contract violations), same reason.

- `kitchen/docs/api/mailbox.md` — API reference (Zig function
  signatures), same reason.

- `kitchen/docs/api/polyhelper.md` — API reference (PolyHelper generated
  functions), same reason.

- `kitchen/docs/api/polynode.md` — API reference (manual step-by-step Zig
  walkthrough), same reason.

- `kitchen/docs/api/pool.md` — API reference (Pool functions, hooks,
  event source helpers), same reason.

- `kitchen/docs/api/root-and-master.md` — API reference (module layout,
  Master composition table), same reason.

- `kitchen/docs/api/tags-and-slots.md` — API reference (tag identity,
  slot rule, code patterns), same reason.

- `kitchen/docs/api_reference.md` — single-line redirect stub to
  generated Zig autodocs, no content of its own.

- `kitchen/docs/addendums/io-101.md` — std.Io primer (Future/Select/
  Group mechanics), technical reference for people already using  
  std.Io directly, not persuasive/explanatory README/landing material.

- `kitchen/docs/building-blocks/core-concepts.md` — superseded per
  CLEANUP_CANDIDATES.md, heavy "ownership"-as-central-rule framing not  
  updated to New Mindset, content fully superseded by building-blocks/  
  polynode.md + mailbox.md + pool.md + master.md (all kept individually  
  above).

- `kitchen/docs/building-blocks/observable-by-human.md` — superseded per
  CLEANUP_CANDIDATES.md; a coding-style/structure rule (coordinator/step  
  function shape), pure process content, zero persuasive value for  
  README/landing.

- `kitchen/docs/cookbook/index.md` — stub: "Content planned for a later
  DOC stage," no content of its own.

- `kitchen/docs/matryoshka-storytelling-003.md` — storytelling
  methodology/process document (how to write a Discussion/SRS/  
  Translation), meta-guidance for authors, not narrative content itself  
  that could feed README/landing prose.

- `kitchen/docs/patterns/async.md` — code-shape cookbook (Future/Select/
  Group/cancellation patterns), pure technical reference, zero  
  persuasive value.

- `kitchen/docs/patterns/index.md` — nav stub linking to the other
  patterns pages, no content of its own.

- `kitchen/docs/patterns/mailbox-and-topology.md` — code-shape cookbook
  (mailbox idioms, topology patterns), same reason as async.md.

- `kitchen/docs/patterns/master-and-shutdown.md` — code-shape cookbook
  (shutdown sequence, Master composition code shapes), same reason.

- `kitchen/docs/patterns/pool.md` — code-shape cookbook (pool mode/hook
  patterns), same reason.

- `kitchen/docs/patterns/slot-and-polynode.md` — code-shape cookbook
  (slot/PolyNode idioms), same reason.
