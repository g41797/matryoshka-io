# Matryoshka Zig — Rules (019)

Versioned doc. Replaces [rules-018.md](rules-018.md).
All coding, doc, and process rules for the project.
Companion: [matryoshka-model-003.md](matryoshka-model-003.md) — the thinking model.
Companion: [patterns-012.md](patterns-012.md) — reusable coding patterns.

Change from rules-018: new Handle naming rule (API 4) — `NodeHandle` renamed
to `ItemHandle` (leaked the intrusive-node implementation detail); short
variable name `ih` (was `nh`); bare `handle` documented as acceptable
shorthand. See "Handle naming" under Coding Standards below.

Change from rules-017: adds a mkdocs-site formatting rule, found while
building `kitchen/docs/`. `mkdocs`'s Python-Markdown renderer requires a
blank line between a lead-in paragraph and the bullet/numbered list that
follows it. Without the blank line, the list renders as flat inline prose
with literal `-`/`1.` characters — GitHub markdown tolerates the missing
blank line, mkdocs does not. 145 such spots were found and fixed across
`kitchen/docs/*.md` in one pass. See "Documentation Rules" below.

Change from rules-016: rules-016's blank-line hypothesis was wrong — tested
empirically against a real headless-Chrome render of `zig build docs` output
and disproved. The actual cause: Zig's autodoc container/module page always
splices the **first declaration's** `///` doc comment onto the container
page, directly after the `//!` module overview, with no heading or
separator — regardless of blank lines, and regardless of which declaration
is first (confirmed by reordering: the merge just follows whichever
declaration becomes first). Fix: place an undocumented, non-`pub` stub
declaration (`const _doc_stub = void;`) as the first thing after the `//!`
header in any file whose first real declaration carries a `///` comment.
The stub absorbs the splice — it has no doc comment, so nothing bleeds, and
being non-`pub` it is invisible in the sidebar/nav. Verified on all 3
affected files (`src/mailbox.zig`, `src/pool.zig`, `src/polynode.zig`) via
headless-Chrome DOM dump of the rebuilt docs; `src/matryoshka.zig` and all
67 `examples/`/`stories/` files need no stub — none has a `///` comment on
its first declaration (examples/stories have no `///` comments at all; the
whole description lives in `//!` per rules-015).

Known trade-off, not fixed by the stub: doc comments on plain alias consts
(`pub const MailboxHandle = polynode.NodeHandle;`) never render on their own
dedicated page either — visiting that page shows the aliased type's doc
instead (`NodeHandle`'s, not `MailboxHandle`'s). The stub stops the comment
from garbling the container page; it does not make the comment appear
anywhere. Accepted as a separate, unfixed Zig autodoc limitation — same
precedent as the rules-014 quoted-identifier limitation.

Change from rules-014: two example doc-comment fixes, confirmed against a
from-scratch autodoc rebuild.
- The example's description + Ownership diagram is a `//!` file-level doc
  comment, placed at the top of the file (right after the SPDX header,
  before the entry point) — not a `///` comment on the entry point. Reason:
  every example file has exactly one public entry point, so the file-level
  description is sufficient; `///` immediately above the entry point and
  `//!` at the top of the file are different token kinds to the autodoc
  parser, and mixing them truncates the function's own doc to whatever
  trails the last `//!` line.
- Any ASCII diagram inside a doc comment (Ownership diagrams, flow
  diagrams) is wrapped in a ` ``` ` fenced code block. Reason: the autodoc
  viewer renders doc comments as CommonMark markdown, which collapses
  single line breaks into one flat paragraph — box-drawing diagrams need
  a fenced (or indented) code block to keep their line breaks.
See "Coding Rules — Examples" and "Description as code" below.

Change from rules-013: example/story entry points use a plain snake_case
identifier (`pub fn <snake_case>(...)`), not a quoted identifier
(`pub fn @"<description>"(...)`). Reason: Zig's built-in `zig build docs`
autodoc viewer cannot resolve declaration links for quoted identifiers —
clicking such a name in the generated `examplesdocs` shows "Declaration
not found." The staccato description text is unchanged; only the
entry-point's identifier syntax changes. See "Coding Rules — Examples"
and "Description as code" below.

Change from rules-012: adds a verification rule for sweep/scan claims
("done" must be backed by a live grep, not a prior pass's claim) and a
concrete staccato file-header standard modeled on `std.Io`. See "Comment and
Doc Comment Rules" below.

---

## Observable by human — MUST

Every function with distinct phases or steps is written in two levels.

Level 1 — the coordinator (`run`, any sequencing function).
- Dominant structure: calls to named step functions.
- Simple glue stays inline: a guard, a `helpers.expect`, a `std.log.info` line.
- Inline logic blocks with distinct purpose — extract to a named step.
- The full flow is visible in a few lines without opening anything.

Level 2 — the step functions.
- Each implements exactly one step.
- Named for what they do. The name IS the documentation.
- `var`/`const` declarations are fine anywhere they are needed.

Development order.
- Write the coordinator first. Name the steps before implementing them.
- Add stub step functions that compile but do nothing.
- Fill in steps one by one, sequentially or iteratively.
- The flow is known and visible from the start.

The signal.
- If you feel the need to place a comment explaining a block of code: stop.
- That block must be a named step function instead.
- A comment marks a step you should have named before writing.
- Common sense: a 1-2 line guard or log between step calls stays inline.
- Only blocks with distinct, nameable purpose are extracted.

Structural extraction signals.
- These patterns are always violations — no comment needed to trigger extraction.
- 1. Any `while` loop with a `switch` body inside a coordinator.
  - Name: `runEventLoop`, `eventLoop`, or domain equivalent.
  - The loop is the step. Extract it regardless of length.
- 2. Any `Io.Select` setup block inside a coordinator (`buf` + `sel.init` + `sel.concurrent` calls).
  - Name: `setupSelect`, or fold into `runEventLoop` if trivially short.
  - `buf` and `sel` are declared at coordinator scope and passed as `*Sel` to steps,
    or held as struct fields in a Master.
- 3. Any cluster of `io.concurrent` / `group.concurrent` / `Thread.spawn` calls inside a coordinator.
  - Name: `spawnWorkers`, `runWorkers`, `spawnSenders`, or equivalent.
  - `await` calls belong in the same step or in a paired `awaitWorkers` step.
- 4. Any for-loop or sequential block that sends, fills, or seeds items inside a coordinator.
  - Name: `sendItems`, `fillMailbox`, `seedPool`, `sendEvents`, or equivalent.
  - Already covered by the comment signal but now also structural — no comment required.

Step function parameters.
- Pass only state that is transient between specific steps (output of one step, input to the next).
- State shared by the coordinator and most steps belongs in a struct field.
  - Masters: `self.field` — already in the struct, no parameter needed.
  - Flat coordinators with 3+ shared params: introduce a local value struct. No heap allocation.
- A step function with 3+ parameters that are all coordinator-scope state signals: introduce a struct.
- Simple extractions with 1-2 params: explicit parameters are fine.

Applies to all code: `src/`, `helpers/`, `examples/`, `tests/`, `stories/`.
Small functions with no distinct phases need no extraction.

---

## Description as code — MUST

An example's or story's description is written like its code, not like prose about its code.

Applies to.
- Every `//!` description block at the top of an example's or story's file.
- `task1-examples-*.md` / `task2-examples-*.md` catalog entries (see Catalog docs below).

Same shape as Observable by human.
- One-line intent — what the example demonstrates. This is the coordinator line.
- Named steps as bullets — one step per bullet, in the order they run.
- A bullet names a step the same way a step function is named: what it does, not how.
- No single long sentence chaining multiple facts with commas — that is an unextracted
  block, same violation as an unextracted code block.

Staccato rhythm applies.
- Short intro line, then bullets.
- One fact per bullet.
- No prose paragraphs.

Placement — `//!` file-level doc comment, not `//`.
- The description + ASCII ownership diagram is a `//!` doc comment, placed at the
  very top of the file, directly after the SPDX header, before any declaration.
- `//!` is autodoc-extractable and renders on the file's own container page. Plain
  `//` is not extracted at all.
- Not `///` on the entry point: every example file has exactly one public entry
  point, so the file-level `//!` description is sufficient. Mixing `//!` (file)
  and `///` (declaration) above the same function is a bug, not a style choice —
  they are different token kinds to the autodoc parser, and the function's own
  doc silently truncates to whichever kind sits immediately above it.
- If the example uses a Master, the Master's own `run` method is the real
  coordinator, but it is private (`fn`, not `pub fn`) — no doc comment on it. Its
  steps are still named, self-documenting per Observable by human; no separate
  doc block needed.

ASCII diagrams — fenced code block.
- Any ASCII diagram inside a `//!` block (Ownership diagrams, flow diagrams) is
  wrapped in a ` ``` ` fenced code block: ` ``` ` on its own `//!` line, the
  diagram lines, then ` ``` ` on its own `//!` line to close.
- Reason: the autodoc viewer renders doc comments as CommonMark markdown, which
  collapses single line breaks into one flat paragraph. A fenced (or 4-space
  indented) code block is the only way box-drawing diagrams keep their shape.
- Trailing prose after a diagram (a summary sentence, not the diagram itself)
  stays outside the fence, as a normal paragraph.

File layout — flow descriptors at the top.
- The entry point (`pub fn <snake_case>`) sits at the top of the file, directly
  after the `//!` description + diagram block.
- Where a Master exists, its `run` method also moves up, directly after the entry
  point, ahead of struct fields, `init`, `destroy`, and step functions.
- These two functions are the file's flow descriptors — a reader sees the whole shape
  first, then drops into detail only if needed.
- Imports stay at the bottom (LE style, unchanged).

Catalog docs (`task1-examples-*.md`, `task2-examples-*.md`) are an index, not a copy.
- One line per scenario: number, name, one-line hook, link to the source file.
- The full staccato description lives in the source `//!` block only.
- Do not duplicate the description in both places — the source is the single source
  of truth; the catalog just routes to it.

---

## Code quality — all categories

Tests, examples, and stories follow one quality bar.

- Same bar as production code: structured, reusable, well-named.
- No throwaway code in any category.
- Quality, modularity, and naming are identical to production code.

They differ only in visibility and job.

- Tests check correctness. Internal. Not in generated docs.
- Examples show one pattern. Part of generated docs.
- Stories show matryoshka thinking across multiple layers. Part of narrative docs.

The difference is the job, never the quality.

---

## Coding Rules — Tests

What a test must do.
- Check correctness of the implementation.
- Cover one behavior at a time.
- Cover edge cases, error paths, state transitions, contract violations.
- Be structured, reusable, well-named. Same quality as production code.

What a test must not do.
- No throwaway code.
- No story flows. That is the job of examples.

Allocator and io source.
- Tests supply `std.testing.allocator`.
- Tests supply `std.Io`, usually via `std.Io.Threaded.init`.
- Tests set `std.testing.log_level = .debug`.
- Tests use `testing.expect` for verification.

---

## Coding Rules — Examples

Checks.
- Use `helpers.expect(error.XxxFailed, condition, "description")` for invariant checks.
- Works in all build modes, unlike `std.debug.assert` which is removed in ReleaseFast and ReleaseSmall.
- Each example uses its own error name, e.g. `error.BuilderFailed`.

No testing APIs.
- No `std.testing` anything inside example code.
- No `testing.allocator`, no `testing.expect*`, no `testing.log_level`.
- No `std.debug.assert`.
- Use `std.log` for diagnostic output.

Test wrappers live in `tests/`.
- Every example is runnable code.
- A test wrapper calls the example and verifies it.
- Test wrappers supply `std.testing.allocator` and `std.Io`.
- Test wrappers set `std.testing.log_level = .debug`.
- Test wrappers catch errors with `@errorName(err)` for diagnostics.

Scope and shape.
- One pattern. One layer.
- Entry point uses a descriptive name, not `run`.
- Signature: `pub fn <snake_case>(allocator: std.mem.Allocator, io: std.Io) !void`.
- `<snake_case>` is a plain identifier derived from the example's one-line staccato
  description (lowercase, words joined with `_`) — never a quoted identifier
  (`@"..."`). Zig's built-in `zig build docs` autodoc viewer cannot resolve
  declaration links for quoted identifiers; using one breaks the generated
  `examplesdocs` page for that example.
- The staccato description text itself is unchanged and still lives verbatim as
  the first line of the file's `//!` doc comment.
- Master's own `run` method (private, inside the Master struct) is unaffected — this
  rule targets only the example's public entry point.
- `//!` doc comment at the top of the file: staccato description + ASCII ownership
  circuit diagram, diagram wrapped in a ` ``` ` fenced code block. No doc comment =
  not done. See Description as code above.
- The entry point (and Master `run` method, if any) placed at the top of the file, right
  after that doc comment.
- Show correct resource cleanup. `errdefer` on error paths, `defer` on all-path cleanup.
- Examples become docs. Leaky examples teach leaky habits.
- Reference model: tofu `recipes/cookbook.zig`.

Completeness.
- Show where work input originates: caller seeds, network provides, timer triggers, worker's own accumulated state.
- Show what the worker does with a pool resource and any additional input.
- Show where results go after processing.
- A lifecycle-only example (get → put, no input source, no output destination) is not complete.
- Pool items are empty containers on acquisition. Work intent must come from outside the pool item.
- See "Pool items are empty containers" in [matryoshka-model-003.md](matryoshka-model-003.md).

Master pattern.
- Small examples: flat function. All state fits in local variables. No Master needed.
- Big examples: allocate a Master struct on the heap.
- The same two-tier rule applies to worker functions inside any example or story.

When to stay flat (simple case).
- Minimal functionality: one loop, one action per iteration.
- All state fits in local variables.
- Short lifecycle: exits cleanly on close or cancel.
- No shared state between steps.

When to allocate a Master (complex case).
- Multiple steps or phases with state shared between them.
- Complex lifecycle: distinct init / work / shutdown phases.
- `run` method needs named private steps to remain readable.
- Growing functionality that would make a flat function hard to follow.

Master struct shape.
- The entry point and the Master's `run` method sit at the top of the file (see
  Description as code above), directly after the doc comment:

```zig
pub fn <snake_case>(allocator: std.mem.Allocator, io: std.Io) !void {
    const master = try MasterXYZ.init(allocator, io);
    defer master.destroy();
    try master.run();
}
```

- `init(allocator, io) !*MasterXYZ` — allocates on heap, acquires all resources, can fail.
- `destroy` — releases resources in correct order, frees the allocation last.
- Master's `run` — readable main flow: sequenced calls to private step functions.
- Private functions — each implements one internal step.
- Fields — shared state between steps; replace scattered locals.

Canonical reference: `examples/layer4/018-master_with_pool.zig`.

---

## Coding Rules — Stories

- Signature: `pub fn run(allocator: std.mem.Allocator, io: std.Io) !void`.
- Must show multiple layers composing into a real flow.
- `///` doc comment at the top of the file: staccato description + ASCII ownership
  circuit diagram (see Description as code above).
- Test wrapper in single `tests/stories_test.zig`, using `std.Io.Threaded.init`.
- SPDX header required if placed under `src/`-style ownership; owner adds SPDX headers.
- Stories always use the Master pattern. A story is never a flat function.

### Story structure — Master composition rule

A story composes Masters. This rule is derived from matryoshka's own Master concept.

What a Master is.
- A Master is a coordination boundary.
- It owns its resources: mailboxes, pools, allocator, application state.
- It coordinates startup order, shutdown order, and cancellation policy for those resources.
- An `Io.Select` loop is a Master. An `Io.Group` of workers under one coordinator is a Master.
- There is no required Master struct or interface. The responsibility defines it, not the type.

How a story is structured around Masters.
- A story composes more than one Master.
- Each Master is its own structured unit: a Master struct allocated on the heap.
- Master struct has `init`, `destroy`, `run`, and private step functions.
- A Master's fields hold the handles it owns and the state it tracks.
- A Master's `run` function does the coordination: receive, dispatch, re-spawn, shut down.
- Do not inline a Master's coordination logic into the top-level `run`.

What `pub fn run` does.
- `run` is thin.
- `run` initializes shared resources.
- `run` starts the Masters.
- `run` awaits the Masters' shutdown in the mandatory order.
- `run` does not hold a Master's per-event coordination logic.

Why this shape.
- It mirrors how matryoshka separates the coordination boundary from the entry point.
- The reader sees one Master at a time, each with its owned resources.
- Shutdown order is visible in `run`, not buried inside a loop.

---

## Coding Standards

Import order (LE style).
- "LE" means "_Little-endian_" - imports are placed at the bottom of the file, after the code.
- Package and local imports first.
- `const std = @import("std")` always last.
- Do NOT flag std-last as a violation.

```zig
const polynode = @import("polynode.zig");
const cond_timeout = @import("internal/cond_timeout.zig");
const std = @import("std");
```

SPDX headers.
- Required in all `src/` files.
- Owner-added. Never remove them during edits.
- Do not add SPDX headers to new `src/` files. Owner will add them.

Layer terminology.
- Use "layer" not "block" everywhere — docs, tests, examples, directories.
- Exception: Odin reference paths (`block1/`, `block2/`) are quoted literals naming Odin's own directories.

Handle naming (API 4).
- `ItemHandle` is the canonical name for `*PolyNode` — supersedes `NodeHandle`,
  which leaked the intrusive-list-node implementation detail into a name
  meant to describe what the caller holds.
- Short variable name: `ih` (was `nh` — never actually used in code before
  this rule, so nothing to migrate).
- Bare `handle` is acceptable informal shorthand in prose/comments once the
  type is clear from context — matches existing usage throughout the API
  reference.
- `MailboxHandle` / `PoolHandle` are unaffected — they already name the role,
  not the implementation.

General Zig style.
- Explicit typing: `const x: T = ...` where the type is known.
- Explicit dereference: `ptr.*.field`.
- Check the standard library before adding custom definitions.
- `errdefer` after every `alloc.create` or resource-acquiring `try`.
- `defer` for cleanup that must run on all exit paths.

The Slot Rule.
- Never overwrite a non-null slot.
- Always start with `var slot: Slot = null`.
- All acquisition APIs assert `slot.* == null` on entry.
- Transfer clears the slot: `slot.* = null`.
- Cleanup ops (`pool.put`, `PolyHelper.destroy`, `helpers.freeSlot`) are no-ops on null slots.
- Use defer-before-acquisition — safe because cleanup is null-safe.
- Never use `allocator.create` / `allocator.destroy` directly on PolyNode-based user types in examples or tests. Use `PolyHelper.create`, `PolyHelper.destroy`, or `helpers.freeSlot`.
- Exception: `receiveResult` and `getWaitResult` transfer ownership via the returned union value, not a `*Slot`. The caller extracts the handle and owns it from that point.

Banned words.
- `drain` — use `clear`, `reset`, `empty`, or a domain verb. Example: `clearList` not `drainList`.
- `dll` / `DLL` — clashes with Windows DLL. Use `List.Node`, `list_node_ptr`, or spell out `DoublyLinkedList`.
- "commit" when meaning save/update/write — implies git, which is owner-only. Say "save", "update", or "write".
- AI-sh word list: robust, seamlessly, comprehensive, leverage, efficient, powerful, facilitate, utilize, ensure, performant, ergonomic, idiomatic, streamline, orchestrate, sophisticated, intuitive, scalable, unlock, empower, harness, deliver, fed, arm, leg, idempotent, fires, faces.
- Scan `.zig` and `.md` after any stage that changes them. Report hits to owner. Do not fix without approval.

---

## Comment and Doc Comment Rules

- Short intro line, then bullets. Staccato rhythm.
- One fact per bullet.
- No prose paragraphs with comma-separated lists.
- No dense multi-fact sentences.
- Do not explain WHAT — names do that.
- Explain WHY only if non-obvious.
- No multi-paragraph docstrings.
- No "used by X" / "added for Y flow" comments.
- `///` and `//!` allowed in `src/` (lifted in rules-011, was banned in rules-010).
  - `//!` at the top of each file: high-level module description, staccato style.
  - `///` on every `pub` declaration: function, type, error set, const.
  - Same staccato/comment rules as everywhere else in this section.
  - `examples/` and `stories/` entry-point functions keep their own rule — see
    Description as code above.
- No "ownership" / "ownership transfer" / "owner" language in `src/` comments
  (added in rules-012). Too abstract, reads like a computer-science paper.
  - Say what happens: an operation sends an object, a handle, or a slot from
    one place to another.
  - The invariant to state: an object sits in exactly one place, in exactly
    one state, at any moment. Not "one owner."
  - Staccato style allows an extra bullet line if plain language needs more
    room than the abstract term did.
- No references to design docs (`.md` files: rules, plans, api-reference,
  STATUS, patterns) inside `src/*.zig` comments (added in rules-012).
  - Readers of source or generated docs only see the `.zig` files.
  - Comments must be self-contained — explain the fact, don't point at a doc.
- File-header (`//!`) staccato standard (added in rules-013): model on
  `std.Io`'s own file header — short intro line, then a flat bullet list of
  concrete facts, one per bullet.
  - A header that reads as one run-on paragraph across several `//!` lines
    is a violation even if each individual line is short — packing more
    than one distinct fact into unbulleted lines is still dense prose.
  - Applies to any doc comment (not just headers) naming more than one
    distinct fact.
- Verification rule (added in rules-013): a sweep or scan (banned words,
  terminology bans, `.md`-reference check, line-length/staccato check)
  is only "done" when re-run live against current file contents at the
  moment of the claim.
  - A prior pass's claim of completion is not sufficient — re-run the
    grep/check yourself before reporting a sweep as complete.
  - Reason: a DOC 16 pass claimed the ownership-terminology sweep was
    complete across `src/*.zig`; a live re-check found 6 remaining hits
    the earlier pass had missed in `polynode.zig`, `mailbox.zig`, and
    `pool.zig`.
- First-declaration doc-stub rule (added in rules-017, supersedes the
  rules-016 blank-line rule — that hypothesis was tested and disproved):
  if a file's first declaration after the `//!` header carries a `///` doc
  comment, Zig's autodoc container page splices that comment onto the
  module overview page with no separator, regardless of blank lines.
  - Fix: insert `const _doc_stub = void;` (no doc comment, non-`pub`) as
    the first declaration after the `//!` header. It absorbs the splice;
    being undocumented and private, it does not appear in the rendered
    docs at all.
  - Only needed when the first declaration would otherwise carry a `///`
    comment. Files with no `///` comments at all (every `examples/`/
    `stories/` file — description lives entirely in `//!`) need no stub.
  - Verified empirically via headless-Chrome render of `zig build docs`
    output, not assumed from source alone — a plain source-level fix here
    is unverifiable without checking the actual rendered page.

---

## Documentation Rules

* Document is not a novel.

* Do not use prose style.

* Use simple English.

* Use short sentences.

* Prefer bullets over long paragraphs.

* One fact per bullet.

* Use a staccato rhythm.

   * Start with a short introduction.
   * Follow with a bullet list.
   * One bullet. One fact.
   * Keep the introduction short.
   * Do not chain multiple ideas into one sentence.
   * Do not replace bullet lists with many standalone one-line sentences.

* Story narrative uses the 4-part structure:

   * Architecture dialogue.
   * SRS.
   * Matryoshka translation.
   * Flow diagram.

* Use ASCII diagrams.

* Make diagrams human-readable.

* Do not optimize diagrams for compactness.

* Prefer clarity over brevity.

* Do not save space in files.

* Cross-reference instead of duplicating.

* Link to:

   * `matryoshka-model-003.md`
   * `rules-009.md`
   * `patterns-008.md`

* When extending an existing document:

   * Match the heading levels already in use.

* mkdocs site pages (`kitchen/docs/*.md`) — blank line before every list.

   * Always put a blank line between a lead-in paragraph/heading and the
     bullet or numbered list that follows it.
   * mkdocs's Python-Markdown renderer needs the blank line to recognize the
     list. Without it, the list renders as flat inline text with literal
     `-`/`1.` characters instead of an actual list.
   * GitHub markdown renders such a list correctly even without the blank
     line — do not rely on that as a check. Verify with
     `mkdocs build --strict` (or by eye in `mkdocs serve`), not by reading
     the raw `.md` source.

---

## Process / Workflow Rules

Auto-mode.
- No git. All git operations go through the owner.
- No file deletions - ask owner.

Per-stage finish checklist.
1. `kitchen/build_and_test_debug.sh` — quick build + Debug test.
2. `kitchen/build_and_test_all.sh` — full build + all 4 optimization modes.
3. `kitchen/build_cross_debug.sh` — cross-compile Debug for mac + windows.
4. Post-stage cleanup: revise code for obsolete parts, wrong comments, repeated code that can be extracted.
5. Re-run all three kitchen scripts after cleanup.
6. After kitchen scripts pass: scan changed `.zig` files for patterns not yet in `patterns-008.md`.
   - Report candidate new patterns to owner. Owner decides.
   - Do not auto-document or auto-extract. Report only.
7. AI-sh + banned words scan over changed `*.md` and `*.zig`. Report to owner.
8. Update `design/STATUS.md` Session Log. Include a "Post-stage cleanup" row. Absence of that row means the rule was skipped.
9. Sync `README.md` and any touched per-module README.
10. Rules audit: after any stage that changes `*.zig` or `*.md` files, audit all changed files
    against every rule in this document. Report violations to owner before closing the stage.
    Covers: Observable structural signals, Description as code, descriptive entry-point
    names, Slot Rule, import order, banned words, example completeness, Master pattern
    shape, comment rules, doc rules — all rules.

Kitchen script order.
- `build_and_test_debug.sh` → `build_and_test_all.sh` → `build_cross_debug.sh`.
- Build before test. `zig build` must pass before `zig build test`.
- Full verification = all 4 optimization modes: Debug, ReleaseSafe, ReleaseFast, ReleaseSmall.
- A stage is complete only when all 4 modes pass.
- Redirect build/test output to `zig-out/` log files. Analyze via files, not shell stdout.

New plan version vs update.
- Create a new plan version after each completed stage or INTR.
- Plans are new versions of `design/matryoshka-io-implementation-plan-NNN.md`, not separate files.
- Collapse done stages to one-line summaries. Keep active and future stages in full detail.
- Old plan versions stay as historical record. Do not delete them.

Document versioning.
- Never overwrite any doc. Create a new file with incremented suffix.
- All docs require a version suffix (-001, -002, ...). No exceptions.
- Doc link rule: after creating any new doc version, update all cross-references to the old version in every other doc. No exception. Owner never does this manually.
- `design/context.md` is the stable entry point.

Stage discipline.
- Read `design/STATUS.md` Session Log first.
- Show intent before code. Owner approves before code is written.
- Plan approval is NOT code change approval. Each fix needs its own approval.
- One stage at a time. No skipping. Each stage passes before the next.
- No real code before infrastructure (Stage 0) is verified.
- Tests before examples. Stage N.a = impl + tests. Stage N.b = examples. No mixing.
- Architectural changes need explicit owner approval.

Implementation invariants.
- Source of truth for signatures, types, errors: the current API reference. Wins over all other sources.
- Never send a stack-allocated item. Use `alloc.create` or `pool.get`.
- After transfer (`send`, `put`), `slot.* = null`.
- After `close`, walk the returned list. Free heap items or return pool items.
- `mailbox.close`, `pool.close`, `pool.put`, `pool.put_all` use `lockUncancelable`.
- Never use `std.Thread.Mutex` / `std.Thread.Condition` in `_Mailbox` or `_Pool`.
- `error.Canceled` is never remapped to `error.Closed`.
- `condition_waitTimeout` is a private helper copied from the legacy mailbox (codeberg/zig#31278).

---

## Implementation invariants

`std.DoublyLinkedList` and `polynode.reset`.
- `std.DoublyLinkedList` does nothing for node safety. Any removal (`remove`, `pop`, `popFirst`, or any variant) does NOT zero `prev`/`next` on the removed node.
- After any list removal, the node's `prev`/`next` still point into the old list. `polynode.is_linked` returns true. `polynode.destroy` will assert-fail.
- Rule: call `polynode.reset(poly)` immediately after any list removal, before any `PolyHelper.destroy` call.
- This applies everywhere: `on_close` hooks, mailbox close walks, pool close walks, any custom list traversal.
- The list provides no safety net. The developer is solely responsible.

---

## Matryoshka Coding Patterns

The pattern catalog lives in [patterns-008.md](patterns-008.md).

- Observable function shapes: coordinator / step / init / destroy / Select event loop / spawn-await.
- Description as code: example/story doc comments follow the same coordinator/step shape.
- Pool modes, seeding, backpressure, hooks.
- Io.Select event loop and re-register.
- Io.Group worker sets and shutdown.
- Graceful shutdown ordering.
- Polymorphic dispatch on tag.
- Error handling on receive (Closed/Timeout vs Canceled).
- Master composition.

- Rules constrain.
- Patterns reuse.
- Read the catalog for code shapes.
- Read this doc for what is mandatory.
