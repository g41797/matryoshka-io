# Corpus Index — repo-wide .md corpus (001)

Durable reference describing what each KEPT `.md` file actually contains.  
Not a verdict, not a reuse plan — see `audit-001.md` for that. Meant to  
outlive this DOC stage and be reusable for future doc work, including the  
deferred showcase-post stage.

Discarded files are not indexed here — see `audit-001.md` for the full  
discard list and one-line reasons per file.

---

## Part A — design/ corpus

Discarded files (see `audit-001.md` for reasons) are not indexed here: `collected-context-005.md`, `docs-tooling-approach-002.md`, `matryoshka-io-docs-plan-015.md`, `matryoshka-cookbook-structure.md`, `rules-024.md`, `matryoshka-io-implementation-plan-041.md`, `patterns-015.md`.

## design/boring-manifesto.md

A first-person, staccato-style manifesto arguing for a "boring enterprise programmer" stance toward system design.

It never mentions Master/Item/Mailbox/Pool by name — it's pure motivation/values content, written as short declarative one-liners grouped into thematic blocks separated by horizontal rules.

- Rejects event loops, schedulers, and async frameworks as the goal — the goal is solving business problems.
- Domain objects (Customer, Order, Invoice, Payment) as the mental model developers want, contrasted against infrastructure objects (Poll, Await, Callback, Completion, Continuation).
- Networking, databases, timers, files framed as infrastructure that shouldn't leak into every function.
- Transport-agnostic events: whatever produces a message (TCP, UDP, QUIC, IPC, shared memory, file, timer), the app only cares that e.g. `CreateOrder` arrived.
- Single-place-of-decision principle stated as "one owner, one place, one decision" (source uses "owner," needs rewording if quoted).
- Closes by defining a "boring system" as predictable, easy to understand, change, and keep running — not slow or old.

## design/language-of-matryoshka.md

A vocabulary-defining design doc that establishes the fixed meaning of each core Matryoshka term, explicitly written in New Mindset terms (Master = Io task via `io.concurrent()`).

Structured as a glossary-with-rationale: states the founding principle first, then walks through the four building blocks one by one, then separates architecture from implementation.

- States the founding principle "share by communicating," crediting Bryan C. Mills, and extends it to reusable resources via Pools.
- Defines all four building blocks — Master, Item, Mailbox, Pool — each with a short rule and example list (e.g. Item examples: Request, Response, Connection, Session, Timer, Buffer).
- States the core invariant: an Item is in exactly one place at any moment; Matryoshka prevents shared use of Items.
- Lays out "the architectural rule": don't share Items, communicate/move/reuse them — movement is the default, not sharing.
- Separates architecture from implementation: explains PolyNode and Handles as implementation mechanisms (intrusive containers, runtime type ID, type-erased communication), explicitly not part of the architectural vocabulary.
- Closes with a "reading guide" fixing what each term always means in the docs, plus a reframing pitch to introduce Matryoshka as "an architecture built from Masters that communicate Items," not "a library containing PolyNode, Mailbox and Pool."

## design/master-Io.md

A conversational/exploratory design note (reads like a captured brainstorm dialogue) working out how Matryoshka relates to Zig's `Io` runtime — specifically, how Masters receive Io-originated events (sockets, timers, signals, cancellation) without Io leaking into the application-facing model.

Predates the New Mindset's `io.concurrent()`-based Master definition and uses "ownership" language throughout, but the underlying bridge/positioning ideas still hold.

- Maps Io capabilities (event sources, timers, signals, cancellation, scheduling, completion) to the idea that all of them ultimately become messages delivered to a Master's mailbox.
- Introduces the "Io Bridge" concept: a Master-like component that waits on Io events and translates them into ordinary Matryoshka messages, with an ASCII diagram of the flow.
- Frames the Matryoshka/Io split repeatedly: Matryoshka answers "how is the system structured," Io answers "when does work run."
- Argues Io must stay invisible to application developers — they should only ever think in Masters, Mailboxes, Pools, never in select loops, event sources, or readiness states.
- Lists what Io alone lacks (system boundaries, communication structure, resource-sharing model, isolation) versus what Matryoshka adds (Masters, Mailboxes, Pools as structural constraints).
- Closes with a design rule: if a developer has to mention Io while designing, it's already too visible — Io should be powerful but hidden.

## design/matryoshka-io-model.md

A short, dense reference note that reduces the whole model to a capability list, a mapping table, and a tight ruleset — no prose exposition, meant as a distilled reference rather than an introduction.

Doesn't explicitly use `io.concurrent()` language but is compatible with New Mindset (no old "ownership"/"role" framing).

- Opens with what a Master "can" do, phrased as a bullet capability list (receive, send, schedule itself, cooperate, borrow/share resources).
- Gives a capability-to-primitive mapping table (e.g. Receive → Mailbox, Borrow resources → Pool, Heterogeneous data → Type-erased Mailbox/Pool).
- A "picture-test" framing: if you can imagine your app as independent Masters + mailboxes + pools, you're already thinking in Matryoshka.
- Claims that dispatchers, routers, schedulers, timers, services, actors, pipelines, reactors all reduce to Masters composed via the three primitives.
- A "down to ground" precise ruleset: one input mailbox per Master, one message processed at a time, sends to any mailbox (including its own), mailboxes/pools may be shared, items may be typed or type-erased.
- Closes with a self-check question for whether Matryoshka fits a given system.

## design/matryoshka-io-readme.md

A full draft README for the project, written entirely in New Mindset terms (`io.concurrent()`-based Master), covering intent, the four core concepts, the Matryoshka/Io relationship, incremental adoption, and philosophy — essentially a complete top-to-bottom README shape already.

- Opens with a "first rule" framing quote and a positioning statement ("we know how to write Zig libraries, still learning to build Zig systems").
- Defines the four concepts (Master, Item, Mailbox, Pool) each with rule statements and example lists, closely paralleling `language-of-matryoshka.md` but as flowing README prose rather than a glossary.
- Adds a unique Item/ItemHandle explainer using a "file vs file handle" analogy not present in other design docs.
- Explains the Matryoshka/Io division of labor ("Io answers how tasks run, Matryoshka answers how tasks cooperate") and notes Io still provides concurrency, timers, cancellation, event-waiting underneath.
- Has a unique "Adoption" section describing an incremental no-big-bang-migration path: start with Items, add Pools, then Mailboxes, then organize long-running tasks as Masters.
- Closes with a "Philosophy" section (small vocabulary, no framework/runtime/interfaces/inheritance) and the tagline "Be Master of your systems."

## design/matryoshka-manifesto-005.md

This is the current, canonical persuasion document for the project. It explicitly supersedes manifesto-002/003/004 and states its own changelog at the top: dropped the old "hybrid car" analogy, connected Master to `io.concurrent()`, replaced the "Master is a role" framing with "Master is an Io task that follows the Matryoshka rules," and swapped an old floating-role diagram for a task-world diagram.

- States the problem Matryoshka solves: Io answers "when does work run" but not where system boundaries are, who holds state, or how parts combine.
- Frames Matryoshka as "one constraint" (everything is a Master communicating via Mailboxes) plus a second constraint from Pools (shared resources are explicit).
- Defines Master as an Io task created via `io.concurrent()` that follows the rules — not a type, interface, or runtime — and shows a task-world ASCII diagram with single-job / coordinator / resource-holding Master variants.
- Lays out ground rules for Masters (one input mailbox, one message at a time, can send anywhere including itself, pools/mailboxes can be shared or type-erased) and a capability-to-primitive mapping table.
- Introduces "four fundamental concepts" (PolyNode, Mailbox, Pool, Master) with one-line descriptions each, plus a short technical description of each block and the total LOC count (582).
- Explains how Io and Matryoshka relate via a "bridge" Master pattern that turns Io events into mailbox messages, includes a design self-test, and closes with an incremental-adoption pitch and a call-to-action.

## design/matryoshka-mindset-changing.md

This file documents the mindset shift itself, in three layers stacked in one document: a short raw note, an "Expanded version" discussion, and a final polished "Design: The New Matryoshka Mindset" draft. It reads like a working conversation that ends in a near-final design doc — likely an earlier draft of what became `matryoshka-new-mindset-001.md`.

- Opens with a short raw statement that `io.concurrent()` makes Master a task, not a side-car concept, and that Matryoshka is now "an integral part of the Io world."
- The "Expanded version" section proposes an outline for a design document (why this doc exists, old vs new mental model, what a task is, why Matryoshka isn't a framework, dependency direction, consequences for docs) and includes old-vs-new stack diagrams.
- Discusses redefining Master as "an Io task that follows the Matryoshka object model" with a bullet list of what makes a task become a Master (holds state, holds mailboxes/pools, exchanges PolyNode items).
- Argues for restating the Io/Matryoshka relationship as a dependency-direction claim: Matryoshka needs only `Io.Mutex` and `Io.Condition`, so it survives future Io changes.
- Proposes simplifying the README to one central Io-vs-Matryoshka contrast question ("How do tasks execute?" vs "How do tasks cooperate?").
- Closes with a polished "Design: The New Matryoshka Mindset" section covering Why / Execution belongs to Io / A Master is an Io task / cooperation / three building blocks / not a framework / minimal dependency / summary — functionally a compact version of the whole New Mindset argument.

## design/matryoshka-model-003.md

This is a design-rules/process document (companion to earlier rules/patterns versions), not a persuasion piece. It lays out the mental model behind every Matryoshka design decision and a documentation taxonomy (test/example/story) used elsewhere in the project.

- "The Mantra": every design decision starts from "who owns this item right now" (source wording), with a note that this must be visible at the call site, not buried in implementation.
- Core Principles section: routing state instead of data, single-transfer as the source of lock-freedom, pool emptiness as a backpressure signal usable inside `Io.Select`, pool items as empty containers that need an external input source to do useful work, and a "layers compose" model (PolyNode/Mailbox/Pool/Master each adding one capability).
- Distinguishes cancellation (`error.Canceled`, external scheduler signal) from closing (`mailbox.close`/`pool.close`, Master-driven shutdown signal).
- States "Master is a concept, not a type" — any `Io.Select` loop qualifies (this specific framing is now superseded by New Mindset's "Master is an Io task") — and gives a two-tier rule for when to allocate a heap-based Master struct versus using a flat function.
- Defines a three-category documentation model: Test (correctness, internal artifact), Example (one pattern, part of docs), Story (multi-layer real-domain narrative, part of docs) — including a required four-part story structure (Arch Design, SRS, Matryoshka Translation, Flow Diagram) and code/test file conventions.

## design/matryoshka-new-mindset-001.md

This is the declared source-of-truth document for the New Mindset shift. It states up front that it exists specifically to drive rewrites of README, Manifesto, Patterns, Rules, and API reference in later stages, and that it does not itself rewrite those pages.

- Contrasts "the old understanding" (Matryoshka sitting beside Io, Master described as an independent role) with "the new understanding" (Io creates tasks; Matryoshka lives inside the task world), each with its own stack diagram.
- Defines Master precisely: an Io task created by `io.concurrent()` that holds application state, holds one or more Mailboxes, holds one or more Pools, and exchanges PolyNode-based items — with the rule "not every task is a Master, every Master is a task."
- States a hard technical ban: `std.Thread.spawn` must not appear anywhere in the codebase; already absent from `src/`, still present in some examples/tests pending migration (tracked as follow-up, not covered in this file).
- Frames Matryoshka's role relative to Io's scale/complexity: Io is large and easy to get lost in; Matryoshka is deliberately small (a handful of rules, a few hundred lines) offering a repeatable shape (Mailboxes, Pools, PolyNode) inside that complexity.
- Restates the minimal-dependency claim (`Io.Mutex`, `Io.Condition` only) and the "not a framework" position (no ownership of the app, no runtime, doesn't replace `io.concurrent()`).
- Closes with a "What this changes in the documentation" section flagging README, Manifesto, Patterns/Rules, and API reference as needing updates, followed by a summary restating the core claims.

## design/matryoshka-real-world-scenario-001.md

This is a narrative "story" document (matching the Story format defined in `matryoshka-model-003.md`) walking through the design of a fictional massive-scale video transcoder system, from domain problem to Matryoshka implementation.

- Part 1 is an architect dialogue between a "Network Architect" and "Encoding Architect" designing a system that ingests 10,000 RTMP camera streams on a 64-core server and multiplexes them without per-stream threads, discovering the need for state routing (`StreamContext`), a shared memory pool, and event-driven backpressure.
- Part 2 formalizes six numbered software requirements (decoupled architecture, memory recycling, event-driven backpressure, stateful stream routing, lock-free concurrency via a fixed worker pool, graceful shutdown) in domain language.
- Part 3 gives an ASCII domain-flow diagram: cameras → network ingest → per-stream contexts → ready queue → encoding cluster (64 workers) → storage queue → storage master → HLS storage.
- Part 4 is a second dialogue, this time between two programmers, mapping each requirement onto a concrete Matryoshka construct: Pool for the memory recycler, `select.concurrent(.buffer, pool.getWaitResult, ...)` for backpressure, a `PolyNode`-based `StreamContext` struct routed through a Mailbox acting as the ready queue, `Io.Group` for the 64 workers, `defer pool.put(...)` for buffer return, and `mailbox.close`/`pool.close` for graceful shutdown.
- Part 5 gives a second ASCII diagram, annotated with the actual Matryoshka API calls (`mailbox.receive`, `pool.put`, `mailbox.send`) overlaid on the same data flow as Part 3.
- Note: requirements/dialogue wording still uses "ownership" language even though the mechanics described (`Io.Group`, `Io.Select`, `pool.getWaitResult`) are current New Mindset APIs.

## design/matryoshka-terminology.md

This file is a raw back-and-forth conversation/brainstorm (not a finished doc) about how to fix Matryoshka's terminology problem, specifically the inconsistent use of "item / object / PolyNode / node / pointer / handle / reference / message" across docs, and the word "ownership" specifically, which the author wants removed entirely.

- Opens by noting the document originally intended to be a formal "Terminology" glossary (with a sketched section list: Master, Task, PolyNode, Item, Mailbox, Pool, Builder, Ownership, Transfer, Reuse, Handle, Runtime type, Matryoshka System) but pivots into open discussion instead.
- Proposes a three-layer terminology structure: system vocabulary (Task/Master/Item/Handle) taught first, building blocks (PolyNode/Mailbox/Pool) second, implementation vocabulary (pointer/intrusive/type erasure/runtime type) last — argues the README currently introduces these out of order.
- Argues PolyNode is the wrong "first concept" for the README because users build domain objects (Connection, Request, Session), not PolyNodes; proposes promoting "Item" to the primary architectural concept, with PolyNode demoted to an implementation-detail appendix.
- Works out full replacement definitions for Item, Master, Mailbox, and Pool, each tagged with a one-word architectural role (state / execution / communication / resource reuse), and a rewritten opening for the README that leads with Item rather than PolyNode.
- Contains an extended back-and-forth specifically about eliminating the word "ownership," landing on replacement phrasings ("used by one Master at a time," "belongs to only one place at a time," "sharing is the exception, moving is the default") and general verb-swap guidance (owns→uses/holds, transfers ownership→passes/hands).
- Closes by connecting Matryoshka's design to Bryan C. Mills' "share by communicating" concurrency principle, proposing a "Design foundation" section for the README, and drawing a parallel to a philosophy borrowed from the `kissngoqueue` project ("don't think about the queue, think about the objects flowing through it").

## design/matryoshka-architecture-003.md

Narrative design doc structured as four chapters. Walks a reader from "why does this problem exist" through a step-by-step concept build to concrete flow diagrams and a layer map. Heavy use of ASCII diagrams throughout — this is a "teach the reader" document, not a reference.

- Chapter 1: the problem (independent components exchanging items), the four hard constraints, four named ad-hoc failure modes and why each breaks, a "what was needed" summary, before/after diagrams.
- Chapter 2: six-step concept progression — intrusive node, Tag (runtime identity), Slot (place), Mailbox (transport), Pool (lifecycle), Master/Select (coordination) — each step framed as answering the previous step's open question, with Zig code snippets.
- Tag identity clarified as "class, not instance"; cross-references an earlier api-reference version for the worker-finish-signal and wrapper patterns.
- Chapter 3: four concrete flow patterns — simple producer-consumer, producer-consumer with recycling, pipeline, coordinated service (multi-source wait) — each with a numbered step walkthrough.
- Chapter 4: four-layer map (polynode → mailbox/pool → master → matryoshka root) with per-layer responsibilities and the "dependencies flow down, never up" rule.
- Change log shows this file went through a New Mindset pass (v003): "ownership"/"owner" → "place"/"hold"/"transfer"; "execution context" → "task."

## design/matryoshka-architecture-foundation-4-004.md

The deepest foundation document in the corpus — a twelve-section reference spanning what Matryoshka is, why it exists, the four-layer model in full detail, the concurrency contract, infrastructure-as-items, all named design decisions with reasoning, an explicit non-goals list, and a Zig-specific addendum. Written in short declarative-sentence style throughout, heavy on small code/diagram blocks rather than prose.

- Sections 1-3: what Matryoshka is (small building-block set organized around visible hold, four layers: Hold/Movement/Lifecycle/Coordination), why it exists (avoiding multiple inconsistent lifecycle rule sets across a codebase), and the four problems it solves (Hold, Movement, Lifecycle, Coordination), one per layer.
- Section 4: core concepts — Hold, PolyNode, Tag, MayItem, the four Hold states (FREE/HELD/IN_FLIGHT/INVALID), and Transfers (hold moves, never duplicates).
- Sections 5-8: one section per layer. Layer 1 (Hold: PolyNode+Tag+MayItem, nothing more). Layer 2 (Movement/Mailbox: transport only, no-silent-data-loss shutdown guarantee with two implementation models, fan-in/fan-out/pipeline patterns, when mailbox is/isn't needed). Layer 3 (Lifecycle/Pool: "Pool is not storage — it is a backpressure signal for reuse," hooks on_get/on_put, asymmetric get/put, pool-without-mailbox coordination). Layer 4 (Coordination/Master: Master as a concept not a required structure, typical contents, valid Master shapes, responsibilities across Transport/Resource/Policy domains, startup/shutdown ordering, cancellation belongs to Master, event-source model).
- Section 9: concurrency contract — three channels (DATA/INTERRUPT/CANCEL), the rule that interrupt and cancel are fundamentally different, and how tagged items let a 2-channel model collapse INTERRUPT into DATA.
- Section 10: infrastructure as items — mailboxes/pools can themselves be items, why infrastructure should generally not be recycled, and the "avoid hold cycles / prefer hold trees" guidance.
- Section 11: numbered Design Decisions list, each with a one-line reason — covers explicit hold, one holder per item, PolyNode identity, tags, MayItem, mailbox transfers-not-lifecycle, pool asymmetry, Master as concept, interrupt/cancel separation.
- Section 12: Non-Goals — explicitly not an actor framework, messaging framework, scheduler, runtime, DI framework, service container, GC, or app-architecture replacement. Zig addendum covers language-specific representations kept separate from the architecture proper.
- Change log confirms two New Mindset passes: v002 replaced ownership language with hold/holder/held and "execution context" with "task"; v003 replaced "Pool is storage/warehouse" framing with "Pool is not storage — it is a backpressure signal for reuse."

## design/matryoshka-api-reference-025.md

Matryoshka API reference for Zig 0.16. Function-by-function documentation of the three core modules — polynode, mailbox, pool — written as the source text for `///` doc comments in the actual implementation.

- Defines the "one place, one state" rule and the `ItemHandle`/`Slot` vocabulary, with ASCII diagrams.
- Walks through manually building PolyNode type identity step by step (tag creation, cast, `@fieldParentPtr` recovery), then introduces `PolyHelper` as the generated shortcut for that boilerplate.
- Full mailbox API: `new`, `send`, `receive`, `try_receive`, `receive_batch`, `wakeUpAll`, `close`, `destroy`, OOB (out-of-band) priority sends, error sets, and `Io.Select`/`Io.Future` integration helpers.
- Full pool API: lifecycle state diagram (EMPTY → IN_FLIGHT → HELD/FREE), `PoolHooks` contract (`on_get`/`on_put`/`on_close`), `get`/`get_wait`/`put`/`put_all`/`close`, hook concurrency and reentrancy rules.
- "Tag identity — class, not instance" section explaining how infrastructure handles (mailbox/pool) are distinguished by pointer identity and protocol, not by tag alone, plus the worker-finish-signal and wrapper patterns.
- "Slot-based programming" section: the slot rule, why acquisition APIs assert null, cooperative cleanup/defer patterns.
- Closing "Master (Layer 4)" section stating explicitly that there is no `Master` module/struct — Master is an `io.concurrent()` task that composes the lower layers — plus a table of what Masters are built from, and a note on the cancel model.

## design/matryoshka-io-0.16-implementation-guide-001.md

A porting/feasibility guide for implementing Matryoshka (originally an Odin project) in Zig 0.16. Written as an internal engineering document, not reader-facing prose — its purpose is design decisions and risk analysis for the port, not explanation for newcomers.

- Opens with "What You Are Building" — Matryoshka as four independent blocks (PolyNode+MayItem, Mailbox, Pool, Infrastructure-as-Items) plus a stated build order and a verdict that the port is viable.
- Section 2 catalogs hard Zig-0.16 constraints: `std.Io` as the full concurrency interface, removed `std.Thread.*` sync primitives and their `Io.*` replacements, the two backends (`Io.Threaded` vs `Io.Evented`), `io.async`/`io.concurrent`/`Io.Group` spawning APIs, container migration to unmanaged types, and known stdlib gaps.
- Sections 3-6 walk block-by-block Zig implementation detail for PolyNode, Mailbox (`_Mailbox` struct, send/receive/close code), Pool (`_Pool` struct, get/put/close code, hook discipline), and infra-as-items.
- Section 7 is a full cancellation treatise: cancellation points, two delivery mechanisms (broadcast vs `Future.cancel`), cancel-protected vs cancelable operations, the `error.Canceled` vs `error.Closed` distinction.
- Section 8 covers Master patterns: Master as a role not a type, two Master struct shapes (broadcast-flag vs Future-based), canonical worker loop, shutdown sequencing for both paths, `Io.Group` for multiple workers, and using mailbox/pool as `Io.Select` event sources.
- Sections 9-10 list explicit "what to reuse / what to avoid" engineering rules and Zig-specific comptime opportunities (generated tag mixins, typed `MayItem(T)`, comptime closed-type pools) not available in the original Odin implementation.

## design/stories/print-server-002.md

A complete worked example: designing a network print server from scratch using Matryoshka, told as a four-part story rather than a spec.

- Part 1 is a dialogue between three developers (client-library owner, spooler owner, printer-driver owner) working out the real-world requirements: non-blocking submission, ordered dispatch, exclusive holding while printing, priority cancellation, and clean shutdown — arriving at the insight "whoever holds the job owns the problem" (source wording).
- Part 2 restates the discussion as a formal SRS (software requirements list) — 12 bullet requirements.
- Part 3 translates each SRS requirement into concrete Matryoshka mechanisms: `PrintJob` as PolyNode, `mailbox.send`/`send_oob` for submission and priority cancel, per-client `reply_mbh` for direct result delivery, single-slot exclusive holding during printing, and mailbox close cascading through shutdown.
- Part 4 is a full ASCII flow diagram showing clients → spool master → printer master → per-client reply mailboxes, plus the shutdown sequence.
- Demonstrates two patterns the corpus otherwise lacks a story for: request-response (result flowing back to the originator) and OOB priority signaling (cancel-jumps-the-queue).

## design/stories/print-server-analysis-001.md

A short companion note to the print-server story, explaining why that domain was chosen and what it teaches, plus internal planning notes for future stories.

- States why the print-server domain was picked: it exercises two patterns (request-response, OOB priority) that had no existing story, and it's a domain every reader intuitively understands.
- Summarizes the "teaching point" of Story 2 versus Story 1 (video transcoder) in one paragraph: pool-as-backpressure vs. location-as-synchronization.
- Includes a small pattern-coverage table cross-referencing both existing stories to their central insight and the Matryoshka mechanisms each demonstrates.
- Proposes three options for organizing a future "story registry" doc as more stories accumulate (kept per-story, a dedicated registry file, or a catalog section in another doc) — unresolved, still open.
- Lists three future story candidates (log collector, build pipeline, sensor gateway) with the pattern each would demonstrate that isn't yet central to any existing story.

## design/stories/video-transcoder-003.md

A complete worked example: designing a large-scale video transcoding pipeline (thousands of concurrent camera feeds plus uploads) with Matryoshka, told as a dialogue-driven story.

- Part 1 dialogue among an operator, product, operations, and three engineers (decoder, filter, encoder owners) working through memory constraints, per-camera state ordering, and backpressure — arriving at "pool exhaustion is backpressure" as the design's structural constraint.
- Part 2 restates the discussion as an SRS: concurrent multi-camera ingest, in-order per-camera processing, buffer reuse, automatic slowdown under load, fixed worker pool, clean shutdown with no lost frames.
- Part 3 maps each requirement onto Matryoshka mechanisms: `VideoBuffer` pool for memory reuse, `pool.getWaitResult` inside `Io.Select` for flow control, `StreamContext` carrying per-camera encoder state routed through a mailbox so a fixed `Io.Group` of workers can process many cameras without one-thread-per-camera, and mailbox-close-cascade for shutdown.
- Part 4 is a full ASCII flow diagram: Network Master (`Io.Select` on pool availability) → `ready_queue` mailbox → `Io.Group` of encoding workers → `storage_mbh` → storage task, plus the shutdown sequence.
- Notes its own implementation lives at `stories/video_transcoder/video_transcoder.zig`, run at a small scale (3 cameras, 2 buffers) specifically to force the backpressure condition in tests.

---

## Part B — kitchen/docs + README corpus


## /home/g41797/dev/root/github.com/g41797/matryoshka-io/README.md

The current, live repository README. Persuasion-first document explaining  
what Matryoshka-Io is and why it exists, written in the project's staccato  
house style.

- Opens with the "first rule of building great software systems" quote
  and an "Intent" section framing Matryoshka as an attempt to make Zig Io  
  systems more boring.
- Defines Master as the one main concept: an Io task created by
  `io.concurrent()` that follows the Matryoshka rules; explicitly lists  
  what Master is not (a type, an interface, a runtime).
- Describes a Matryoshka-based system as built from Masters that own
  state, communicate through Mailboxes, and share reusable items through  
  Pools.
- Introduces the three building blocks — PolyNode, Mailbox, Pool — each
  with a short bullet definition, plus a "containers on steroids"  
  explainer section.
- Explains where Zig Io fits (Io answers "how do tasks run", Matryoshka
  answers "how do tasks cooperate") and why Matryoshka is deliberately  
  small.
- Closes with an incremental-adoption pitch ("Try Matryoshka without
  fear") and the "Be Master of your systems" tagline.

## /home/g41797/dev/root/github.com/g41797/matryoshka-io/kitchen/_logo/logo-description.md

An image-generation prompt describing the project's mascot logo (a  
wedding-car scene with a tuxedoed mascot driving a Matryoshka bride away  
from a wedding).

- Scene, driver, bride, and car descriptions for the illustration.
- "Behind the car" section: six wedding cans labeled 0.11–0.16 plus one
  unreadable can, symbolizing unreleased future versions.
- "Small details" section: luggage stickers reading "Matryoshka" and
  "std.Io," no logos.
- "Mood" section explicitly ties the intended feeling back to the
  README's "boring" tagline quote.

## kitchen/docs/addendums/matryoshka-and-rethinking.md

A point-by-point comparison between Matryoshka-Io and the paper  
"Rethinking Classical Concurrency Patterns" (written for Go), arguing  
both reach similar conclusions from different starting points (channels  
vs. object placement).

- 14 numbered "Pattern" sections, each contrasting "Classic" thinking
  with the Matryoshka equivalent (e.g. Pattern 1 "Communicate the  
  object," Pattern 5 "One object, one owner," Pattern 9 "Cancellation is  
  another channel").
- A "Common Philosophy" section listing shared principles between the
  paper and Matryoshka.
- A "Where Matryoshka Goes Further" closing section arguing Matryoshka
  extends the paper's ideas from communication into full architecture.
- Written throughout in "ownership" framing (pre-New-Mindset vocabulary).

## kitchen/docs/addendums/matryoshka-what-is.md

An earlier draft of the "what is Matryoshka" framing that the current  
README now carries — largely overlapping with README.md's opening  
sections but phrased differently in places.

- "What is Matryoshka-Io?" section defining it as a practical way to
  build software systems on top of Zig Threaded Io, explicitly not a  
  framework/runtime/event loop, described as a small "frame."
- "What kind of systems is it for?" section: CPU-bound systems on Zig
  Threaded Io, with example use cases (data processing, background  
  workers, job schedulers, pipelines, business applications, modular  
  monoliths).
- "How to start" section: the "start from a whiteboard, not code, not a
  prompt" instruction, plus incremental-growth advice (add Masters,  
  Mailboxes, Pools as the system grows).
- Repeats the README's "first rule of building great software systems"
  closing quote.

## kitchen/docs/addendums/placement-separation.md

Notes/feedback (reads like a response to the owner) about where different  
pieces of Matryoshka's messaging content should live across three  
distinct audiences/channels.

- Section 1: README should carry the full canonical text (what it is,
  why it exists, how to think about it).
- Section 2: the documentation site's first page should be much shorter,
  answering only "What is Matryoshka? Should I keep reading? Where do I  
  start?" — everything else pushed to links.
- Section 3: a Ziggit Showcase forum post should show rather than explain,
  opening with a short first-person hook and a small diagram.
- "About AI" section: explicit advice never to mention AI/LLM assistance
  anywhere in the project's public writing, and that short, honest,  
  limitation-admitting prose reads as engineer-authored rather than  
  generated.
- Closing note flags "Start from a whiteboard. Not from code. Not from a
  prompt." as the one sentence worth preserving across every surface.

## kitchen/docs/addendums/slot-vs-ref-counting.md

A technical addendum contrasting Matryoshka's Slot model with traditional  
reference counting, aimed at readers wondering why the project doesn't  
use refcounting.

- Defines what a Slot guarantees (exactly one holder, move not copy,
  empty-or-full) versus what refcounting guarantees (multiple holders  
  possible, freed at zero, count doesn't reveal who/why/how-long).
- Explains why Matryoshka uses Slots: every step in the system (Producer
  → Mailbox → Worker → Pool) is a move, never a share — no count field,  
  no atomics, no cycles possible.
- Explains that Pool and Mailbox never need to count, because the current
  holder is a structural fact (free-list membership, queue membership),  
  not something to compute.
- Closes with a "parcel passed hand to hand" analogy versus a shared
  object graph.

## kitchen/docs/addendums/tag-vs-tagged-union.md

A technical addendum contrasting Zig's compile-time tagged unions with  
Matryoshka's runtime PolyNode tags, explaining why the project needs the  
latter.

- Frames tagged unions as solving compile-time type selection (closed
  set of variants, known at compile time) versus PolyNode tags solving  
  runtime identity after type erasure (open set, discovered at runtime).
- Explains why Mailbox/Pool need PolyNode tags: they store `*PolyNode`
  with the concrete type already erased, so a tag is the only thing that  
  survives.
- Argues against putting everything into one giant tagged union (couples
  every store to one closed variant set) in favor of `*PolyNode`  
  everywhere (any type embeds directly, no central registry).
- Comparison table and "when each one fits" guidance: tagged unions for
  small closed application-event sets, PolyNode tags for Matryoshka's own  
  infrastructure.

## kitchen/docs/addendums/typeErasedQueue-vs-mailbox.md

A technical addendum explaining why Matryoshka's Mailbox is not built as  
(or equivalent to) `std.Io.TypeErasedQueue`.

- Comparison table: TypeErasedQueue owns storage/copies elements/bounded
  capacity/backpressure inside the queue, versus Mailbox owning nothing,  
  moving (not copying) elements, unbounded, backpressure pushed outside  
  to Pool or the application.
- Frames TypeErasedQueue as a synchronization primitive (slots are the
  center of the design) versus Mailbox as a transport primitive (the  
  object already exists somewhere; Mailbox only moves a handle).
- Explains that Pool becomes the backpressure mechanism instead of the
  Mailbox having bounded capacity.
- "Four responsibilities, four owners" table: Mailbox = sync + moving,
  Pool = lifecycle/capacity/reuse, Allocator = memory, Master =  
  scheduling/policy.
- Lists implementation techniques worth borrowing from TypeErasedQueue
  (lock discipline, wake-up ordering, fairness) without adopting its  
  architecture.
- Closes explaining Mailbox's API (`send`/`receive`) deliberately avoids
  queue vocabulary (`enqueue`/`dequeue`) because it isn't really a queue.

## kitchen/docs/addendums/why-boring.md

A first-person persona piece — "a boring enterprise programmer mindset" —  
arguing for architecture-first, business-domain-first thinking over  
async/scheduler mechanics.

- Opens rejecting event loops/schedulers/async frameworks as goals in
  themselves; the goal is solving business problems (customers, orders,  
  invoices, payments).
- Argues infrastructure (networking, databases, timers, files) should not
  leak into every function; source trees should show domain types  
  (Customer, Order, Invoice, Payment), not mechanism types (Poll, Await,  
  Callback, Completion, Continuation).
- Argues for thinking in business events (e.g. "CreateOrder arrived")
  rather than transport mechanisms (TCP/UDP/QUIC/IPC/etc.).
- States a preference for "one owner, one place, one decision" and
  optimizing after measuring rather than upfront.
- Argues architecture should let a new team member understand the system
  in a week, and let a five-year-old codebase gain features without  
  rewriting its execution model.
- Closes defining "boring" explicitly as: not slow, not old — predictable,
  easy to understand, easy to change, easy to keep running.

## kitchen/docs/building-blocks/index.md

A short nav page for the Building Blocks section of the doc site, listing  
the four core concept pages.

- One-line summaries for each: PolyNode ("everything exchanged"), Mailbox
  ("everything communicates"), Pool ("everything reusable lives here"),  
  Master ("everything runs inside one. An Io task, not a type").
- Points readers to the API Reference for Zig syntax once ready to code.

## kitchen/docs/building-blocks/mailbox.md

The Building Blocks page dedicated to Mailbox, explaining the concept  
without Zig syntax (syntax lives in the linked API Reference page).

- "What a Mailbox does" section with before/after ASCII diagrams showing
  a handle moving out of a sender's Slot and into a receiver's Slot via  
  send/receive.
- "One owner at a time" section: while a handle sits in the Mailbox, the
  Mailbox itself holds it — exactly one party holds it at any moment.
- "Mailboxes are themselves exchangeable" section: a Mailbox is built
  from a PolyNode too, so it can be sent through another Mailbox, stored  
  in a Pool, or embedded in a larger structure — enabling the  
  worker-signals-completion-by-returning-its-own-mailbox idiom.
- "Why this matters" closing section on avoiding shared status tables.

## kitchen/docs/building-blocks/master.md

The Building Blocks page dedicated to Master.

- Defines Master as an Io task created by `io.concurrent()` that follows
  the Matryoshka rules; explicitly lists what it is not (type, interface,  
  runtime).
- ASCII diagram distinguishing ordinary Io tasks from Masters, and three
  Master sub-kinds: single-job, coordinator, resource-owner.
- "Two tiers of structure" section: flat (plain function, short
  lifecycle) versus coordinator (own struct, distinct startup/work/  
  shutdown phases).
- "Cancel and close are different signals" section distinguishing an
  external stop signal (cancel) from a Master's own shutdown decision  
  (close).
- "Why Master is not in the API" closing section: no Master type to
  import; task/transport/reuse/identity each come from `io.concurrent`/  
  Mailbox/Pool/PolyNode respectively, and everything else is the  
  application's own design.

## kitchen/docs/building-blocks/polynode.md

The Building Blocks page dedicated to PolyNode.

- "What is exchanged?" section framing every design decision around "who
  [holds] this item right now," with a Slot/empty-Slot ASCII diagram.
- Defines PolyNode as a small marker every exchangeable object embeds, so
  infrastructure code only ever sees the marker, never the user type.
- Defines Handle as a pointer to the embedded PolyNode — the thing that
  actually moves, with specialized names (mailbox handle, pool handle)  
  underneath the same pointer kind.
- Defines Slot as a place that either holds a handle or is empty, with
  transfer clearing the Slot as proof of the transfer.
- Closing section on why this matters: identifying/casting the containing
  object without interfaces or virtual dispatch, with one runtime tag  
  check.

## kitchen/docs/building-blocks/pool.md

The Building Blocks page dedicated to Pool.

- "What a Pool does" section with an ASCII lifecycle diagram (new → get →
  put → close) and plain-language descriptions of get/put/close.
- "A Pool resource is an empty container" section: Pool is explicitly not
  storage; what `put` does with a returned item (keep as-is, keep after  
  reset, delete, delete-and-replace) is entirely hook-defined; nothing  
  put in is guaranteed to still be there on the next get.
- "An empty Pool is a signal, not an error" section: waiting on an empty
  pool is backpressure, not failure; one event loop can watch mailbox  
  arrival and pool availability side by side.
- "Why this matters" closing section: reuse and backpressure share one
  mechanism (a fixed number of slots), and the constraint is structural.

## kitchen/docs/concepts/index.md

A short nav page for the (nav-dropped) Concepts section, pointing to the  
two print-server pages: the plain-domain version and the  
Matryoshka-mapped version.

## kitchen/docs/concepts/print-server-the-system.md

Describes a network print server (client/spooler/driver roles) in plain  
domain language, with zero Matryoshka vocabulary — the "before" half of a  
before/after worked example.

- "The requirements" section: 12 bullet requirements (immediate ack,
  non-blocking submission, ordered dispatch, exactly one holder at a  
  time, per-client result channel, cancel-at-any-time semantics including  
  jump-the-queue priority once a job has reached the printer, lossless  
  shutdown).
- "The reasoning behind it" section: walks through why submission/result
  are separate channels, why ownership moves in a straight line  
  (client → spooler → driver), why the driver needs no locks or progress  
  reporting, why the spooler needs no separate status tracking, and why  
  cancellation is the hard part (queue-jumping requirement).
- Closes with the line "At any moment, whoever holds the job owns the
  problem" and a link forward to the Matryoshka-mapped version.

## kitchen/docs/concepts/print-server-with-matryoshka.md

The "after" half of the print-server worked example: the same  
requirements mapped explicitly onto PolyNode/Mailbox/Pool/Master.

- Maps each requirement (non-blocking submission, ordered dispatch,
  result notification, exclusive ownership during printing, priority  
  cancellation, clean shutdown) to specific Matryoshka mechanisms  
  (`mailbox.send`, `mailbox.send_oob`, `reply_mbh` embedded in the job  
  struct, a single Slot, mailbox close cascades).
- "Where the job lives, who owns it" section stating the invariant per
  location (job_queue → Spool Master; printer_inbox → in transit;  
  printer's Slot → Printer Master; reply_mbh → client).
- Full ASCII flow diagram tracing clients through Spool Master, Printer
  Master, and per-client reply mailboxes, including the OOB cancel path  
  and the shutdown sequence.

## kitchen/docs/cookbook/index.md

A stub page: "Content planned for a later DOC stage," noting it will  
eventually draw from `design/stories/` and the Odin `matryoshka` repo's  
cookbook material. No content of its own yet.

## kitchen/docs/deep-dive/video-transcoder.md

A four-part narrative deep dive companion to the print-server story,  
covering a video transcoding pipeline (decode → filter → encode →  
storage) under memory constraints, with a real implementation  
(`stories/video_transcoder/video_transcoder.zig`).

- Part 1 "Discussion": a multi-voice dialogue (Operator, Product,
  Operations, and engineers Dec/Fil/Enc) negotiating responsibilities —  
  memory-bounded buffer pools, per-camera encoder state that must travel  
  with frames, backpressure as the natural throttle, and shutdown  
  ordering.
- Part 2 "SRS": 12 frozen requirements distilled from the discussion
  (per-camera ordering, no cross-camera interference, buffer reuse,  
  backpressure without an explicit signal, lossless shutdown).
- Part 3 "Matryoshka Translation": maps each requirement to Matryoshka
  mechanisms — VideoBuffer Pool, `pool.getWaitResult` inside `Io.Select`  
  as the flow-control event source, StreamContext Mailbox for  
  per-camera-ordered concurrent processing, Io.Group of workers, cascade  
  shutdown — with a "central insight" statement that pool exhaustion is  
  backpressure with no separate coordinator needed.
- Part 4 "Flow Diagram": full ASCII diagram of Network Master → ready
  queue → encoding workers → storage task, plus the shutdown sequence.
- "The real code" section: annotated excerpts from the actual
  `video_transcoder.zig` source — seeding the pool, the Select-based  
  Network Master, the worker function, and the multi-boundary shutdown  
  sequence.

## kitchen/docs/index.md

The doc site's landing/nav page.

- Repeats the README tagline "Matryoshka-Io — a practical way to build
  great software systems," with a subhead "Building Blocks for Modular  
  Monoliths."
- A flat link list to the Manifesto, Building Blocks, API Reference,
  Patterns & Cookbook, Examples Catalog, Addendums, and generated API  
  Docs.

## kitchen/docs/manifesto.md

The most comprehensive persuasion document in the corpus — a longer,  
more argued version of the README's pitch, covering material the README  
doesn't (the two-constraint framing, the Io-as-bridge idea, a closing  
self-test).

- "The problem" section: Zig Io answers "when does work run?" but not
  where system boundaries are, who owns state, how parts talk, who  
  controls shared resources, or how parts combine — leading async  
  systems to drift without anyone choosing the structure.
- "One constraint" section: "Everything is a Master communicating via
  Mailboxes," with Pools adding a second constraint ("shared resources  
  are explicit and controlled"), and a bullet list of what accepting  
  those constraints buys you.
- "Master is an Io task" section: restates the README's Master
  definition, with the same ASCII single-job/coordinator/resource-owner  
  diagram used in building-blocks/master.md.
- "Down to earth" section: a capability-to-primitive table (receive/send/
  share communication/borrow resources/share resources/heterogeneous  
  data), and a list of higher-level patterns (dispatchers, routers,  
  schedulers, timers, services, actors, pipelines, reactors) that are  
  "just Masters, or a composition of Masters."
- "Four fundamental concepts" section: the one-line PolyNode/Mailbox/
  Pool/Master summary, plus a stated total line count for the troika  
  (582 lines at time of writing).
- "Where Io fits" section: the Io-as-bridge idea — external events
  (timers, sockets, background jobs, other Masters) all become messages  
  in a Master's mailbox; includes a design self-test ("if you have to  
  mention Io while designing your system, it is already too visible")  
  and a small ASCII bridge diagram.
- "Start small and where to go next" section: incremental adoption
  advice, matching the README's.
- Closes with "A simple question" self-test (can you describe your
  system using only Masters/Mailboxes/Pools?) and the "Be Master of your  
  systems" tagline.

## kitchen/docs/matryoshka-based-systems.md

A short, compressed top-down entry-point page (nav-dropped/superseded per  
CLEANUP_CANDIDATES.md, kept for content value).

- Opens distinguishing Matryoshka from typical libraries: "Most libraries
  document features. Matryoshka documents architectures."
- Compact restatement of the three building blocks and the Master
  concept, each in 2-4 bullets.
- "What a Matryoshka-based system looks like" and "Where Zig Io fits"
  sections, both shorter versions of content covered at length in  
  manifesto.md and README.md.
- "Next" section listing Concepts/Building Blocks/Cookbook as "planned
  for a later stage" (now populated elsewhere in the site).

## kitchen/docs/the-shape.md

A short page framing Matryoshka's value proposition as solving three  
concrete "pains" that show up once a system outgrows one function,  
illustrated with a TCP request service example and two diagrams.

- Introduces the example system (Acceptor/Session/Journal roles handling
  TCP requests) with an embedded diagram reference  
  (`assets/diagrams/real-system.svg`).
- "Three pains" section: ownership (nobody says who frees a Request),
  allocation (a buffer allocated per request and thrown away), coupling  
  (Session and Journal need an interface or vtable just to pass work).
- Maps each pain to one building block: PolyNode (identifies the
  Request, no interface/vtable needed), Mailbox (moves the Request  
  across roles, ownership travels with it), Pool (leases/reclaims the  
  Request instead of allocate-and-discard) — with a second diagram  
  reference (`assets/diagrams/matryoshka-solution.svg`).
- Notes explicitly that `std.Io` "has not moved" — Matryoshka uses it,
  does not replace it.

## kitchen/docs/story/print-server/discussion.md

A pure-dialogue narrative telling the print-server design story as a  
conversation between three engineers, each owning one component: C  
(client library), S (spooler), D (driver).

- Full back-and-forth dialogue covering: submission/acknowledgment
  separation, ownership handoff from spooler to driver, cancellation  
  semantics (removing a queued job vs. reaching a job already at the  
  printer), what happens on printer error (jam/out-of-paper), implicit  
  readiness signaling, and a closing exchange establishing "at any moment,  
  whoever holds the job owns the problem."
- No Matryoshka vocabulary appears anywhere in this file — it is written
  entirely in domain terms, per the storytelling-methodology's "Discussion"  
  stage rule.
- Distinct from kitchen/docs/concepts/print-server-the-system.md, which
  covers the same ground as prose/bullets rather than as dialogue.

## kitchen/docs/story/print-server/requirements.md

The frozen SRS-stage requirements list for the print-server story — 12  
bullets, identical in content to the requirements list embedded in  
kitchen/docs/concepts/print-server-the-system.md.

## kitchen/docs/story/print-server/translation.md

The Matryoshka-translation stage for the print-server story, formatted as  
compact requirement → Matryoshka-mapping pairs (terser than the prose  
form in kitchen/docs/concepts/print-server-with-matryoshka.md, which  
covers the same content).

- Six requirement→mapping pairs (non-blocking submission, ordered
  dispatch, result notification, exclusive ownership during printing,  
  priority cancellation, clean shutdown).
- Closing "central insight" section repeating "at any moment, whoever
  holds the job owns the problem" plus the per-location ownership  
  summary.

## kitchen/docs/story/print-server/flow.md

The print-server story's ASCII flow diagram as a standalone page —  
identical diagram to the one embedded in kitchen/docs/concepts/  
print-server-with-matryoshka.md, including the full shutdown sequence.

## kitchen/docs/misc/README-15-07-2026.md

A dated snapshot copy of the current README.md, byte-for-byte identical  
in content to the live README at the repo root. No unique content beyond  
what README.md already carries.

## kitchen/docs/misc/readme-landing.md

An alternate, more compressed README draft — shorter and more clipped in  
rhythm than the current README, closer to a "manifesto-lite."

- Subhead: "A practical way to build concurrent software systems with Zig
  Io."
- "Intent," "What is Matryoshka?," and "Main concept" sections covering
  the same ground as the current README, but terser.
- Names the four core concepts as "Master / Item / Mailbox / Pool" — uses
  "Item" as a named concept where the current live corpus (README,  
  manifesto, building-blocks) uses "PolyNode." This is a vocabulary  
  divergence, not an error in this file specifically — several misc/  
  drafts share it.
- "Why Matryoshka?" section: frames the recurring problems (create,
  process, transfer, reuse, destroy) that the model solves.
- "Adoption" and "Documentation" sections restate incremental-adoption
  advice and preview what the docs site will cover.
- Closes with "Be Master of your systems."

## kitchen/docs/misc/how-matryoshka-system-works.md

A from-scratch architecture explainer draft, structured as a sequence of  
short titled sections rather than the README's flowing sections.

- Opens stating the architecture is built from four concepts: Master,
  Item, Mailbox, Pool — "everything else is implementation."
- Separate sections defining each of the four concepts in isolation
  (Master owns one responsibility/state/processes Items; Item is an  
  application object that belongs to exactly one owner at a time;  
  Mailbox transfers Items, replacing shared ownership with communication;  
  Pool stores reusable Items).
- "Ownership" section: states ownership as Matryoshka's central rule,
  with an ASCII diagram showing an Item flowing Master → Mailbox →  
  Master → Pool → Master.
- "The programming model" section: states the "share by communicating"
  principle and contrasts default operations (create/process/move/reuse)  
  against avoided ones (share/lock/synchronize).
- "Internal implementation" section: briefly notes PolyNode as the
  implementation detail application code doesn't need to touch directly.
- "Putting everything together" closing section: a linear flow diagram
  (Pool → Master A → Mailbox → Master B → Pool) summarizing the model.

## kitchen/docs/misc/matryoshka-io-ads.md

A draft first-person forum/community introduction post (matches the  
"Ziggit Showcase" audience described in placement-separation.md).

- Opens as a direct-address introduction: "Hello everyone. I'd like to
  introduce Matryoshka-Io," explicitly denying it is a framework/  
  runtime/event loop.
- "The main idea" section: the same Master/Item/Mailbox/Pool four-concept
  model as the other misc/ drafts, plus the "share by communicating"  
  principle.
- "Why?" section: frames the recurring problems Matryoshka addresses
  (ownership, communication, object reuse, resource lifetime) without  
  claiming to solve business logic itself.
- "Current state" section: an honest, unpolished status note inviting
  feedback on the architectural model, terminology, API design, and  
  documentation — ends with placeholders for repository/documentation  
  links, confirming this is a draft template rather than a finished post.

## kitchen/docs/misc/what-is-matryoshka-io.md

Another from-scratch architecture explainer draft, close in structure to  
how-matryoshka-system-works.md but reordered and with an added  
"architecture first" section.

- "What is Matryoshka-Io?" opening, denying framework/runtime/event-loop
  status, introducing it as a small architectural model.
- "The idea" section: application objects (requests, connections, jobs,
  sessions, buffers, timers) go through one common lifecycle (created,  
  processed, transferred, reused, destroyed).
- "Four concepts" section: Master/Item/Mailbox/Pool defined individually,
  each in 2-4 short lines, same vocabulary as the other misc/ drafts.
- "The programming model" section: "share by communicating" principle,
  restated as "move Items, do not share Items, reuse Items whenever  
  possible."
- "Why?" section: frames the core difficulty of concurrent programming as
  unclear ownership, posed as four rhetorical questions (who owns this,  
  who may modify it, who destroys it, can another task use it now).
- "Think about architecture first" section: the "start with a whiteboard,
  draw the Masters, draw the Items, draw how they move, then write the  
  code" instruction — a third independent occurrence of this idea in the  
  corpus (also present in addendums/matryoshka-what-is.md and referenced  
  in addendums/placement-separation.md).
- "The role of Zig Io" closing section: same Io-answers-how/Matryoshka-
  answers-how-they-cooperate framing used throughout the rest of the  
  corpus.
