I think you need a **migration plan**, but not a code migration plan first.

You need an **architecture migration plan**.

Right now there are several assumptions scattered through Matryoshka:

* Master == thread
* Mailbox blocks a thread
* Examples spawn threads
* Documentation talks about threads
* Tests use threads as the execution model

Before changing code, I'd settle the architecture.

A good sequence for Claude Code would be:

1. **Inventory**

   * Find every place where Matryoshka assumes `std.Thread`.
   * Classify each occurrence:

     * architecture
     * public API
     * implementation
     * tests
     * examples
     * documentation

2. **Architecture review**

   * Decide what a Master is in the `std.Io` world.
   * Decide whether "Master == execution context" or "Master runs on an execution context."
   * Define what remains Matryoshka's responsibility and what belongs to `std.Io`.

3. **Public API review**

   * Verify that `PolyNode`, `Mailbox`, and `Pool` APIs still make sense.
   * Identify any APIs that unnecessarily expose thread concepts.

4. **Implementation review**

   * Determine whether thread creation should be replaced by `io.concurrent()`.
   * Determine whether tests should continue using `std.Thread` or use `io.concurrent()` where appropriate.
   * Verify synchronization assumptions against the `std.Io` contracts.

5. **Documentation rewrite**

   * Remove "thread" where it's describing an architectural concept rather than an implementation detail.
   * Introduce "execution context" where appropriate.
   * Clearly describe the relationship:

     * `std.Io` provides execution.
     * Matryoshka provides ownership, communication, and reuse.

6. **Examples**

   * Rewrite examples to use the modern `std.Io` style if that's the intended direction.
   * Keep one example showing integration with raw threads if it's still supported and useful.

---

I would **not** ask Claude to immediately rewrite everything.

I'd first ask it to produce a report answering questions like:

* Where does Matryoshka currently assume "Master == thread"?
* Which of those assumptions are conceptual versus implementation details?
* Which assumptions conflict with `std.Io`?
* Which documentation sections would become misleading if Matryoshka adopts `std.Io` as its execution model?

That report becomes the roadmap. Only after you agree with it should you start changing code and documentation.

Given how foundational this change is, treating it as an **architecture migration** rather than a refactoring will help preserve the concepts that make Matryoshka distinct while adapting it to Zig's evolving concurrency model.


Main migration Master is role and does not matter how you run it -> Master is role anmd you should run it using cuncurrent Io 

I would **not** confirm that claim as written.

The first half is architectural. The second half is an implementation recommendation.

Instead, I'd state it like this:

> **A Master is a role, not a thread.**
>
> In a `std.Io`-based system, the preferred way to execute a Master is via an `Io` concurrent execution context.

That leaves room for other execution models while aligning with the direction of `std.Io`.

If your goal is to embrace `std.Io` as the foundation of Matryoshka, then the migration becomes:

```text
Old

Master
    ==
OS thread


New

Master
    ==
role

Role is executed by

Io.concurrent(...)
```

That's a cleaner separation of architecture from implementation.

---

# Matryoshka → std.Io Migration Plan

## Phase 1 — Architecture

**Goal**

Separate execution from ownership.

**Tasks**

* Define Master as a role.
* Remove "Master == thread".
* Introduce "execution context" terminology.
* State that Matryoshka delegates execution to `std.Io`.

Deliverable:

```
Architecture updated.
No thread terminology in core concepts.
```

---

## Phase 2 — Execution Model

**Goal**

Adopt `std.Io` as the execution engine.

**Tasks**

* Replace thread-based examples with `io.concurrent()`.
* Define Master startup using `Io`.
* Define Master shutdown using `Future`/`Group`.

Deliverable:

```
Masters execute via std.Io.
```

---

## Phase 3 — Mailbox

**Goal**

Verify mailbox assumptions.

**Tasks**

* Audit every use of `Io.Mutex`.
* Audit every use of `Io.Condition`.
* Verify assumptions against `std.Io` contracts.
* Remove any thread-specific wording.

Deliverable:

```
Mailbox described as Io-based synchronization.
```

---

## Phase 4 — Documentation

Rewrite documentation around the new layering.

```
std.Io
    execution

Matryoshka
    ownership
    communication
    recycling
```

Update:

* README
* Manifesto
* Design documents
* API Reference
* Tutorials

Replace

```
thread
```

with

```
execution context
```

where appropriate.

---

## Phase 5 — Examples

Rewrite every example.

Old:

```
spawn thread
run master
join
```

New:

```
create Io
start Master via io.concurrent()
await completion
```

---

## Phase 6 — Tests

Review every test.

Classify:

* ownership tests
* mailbox tests
* pool tests
* integration tests

Convert thread orchestration to `std.Io` where appropriate.

---

## Phase 7 — API Audit

Verify that public APIs remain independent of the execution model.

Expected result:

```
PolyNode
    unchanged

Mailbox
    mostly unchanged

Pool
    unchanged

Master
    execution model updated
```

---

# Success Criteria

After the migration:

* **`std.Io` answers:** *How does code execute?*
* **Master answers:** *Who owns and processes objects?*
* **Mailbox answers:** *How is ownership transferred?*
* **Pool answers:** *How are objects reused?*
* **PolyNode answers:** *What is the movable object?*

That division of responsibilities is clean and gives Matryoshka a focused purpose alongside `std.Io`, rather than overlapping with it.


That's actually a very strong architectural property, and I **wouldn't change it**.

In fact, I'd argue this is one place where Matryoshka adds value **on top of** `std.Io`.

`std.Io` provides execution and cancellation.

Your mailbox provides **control**.

Those are different.

For example:

```text
Client
    │
    ▼
Mailbox
    │
    ├── ReloadConfig
    ├── OpenListener
    ├── CloseListener
    ├── RotateLog
    ├── Shutdown
    └── User messages
```

The Master remains event-driven. Everything—including administrative actions—is just another message.

Contrast that with cancellation:

```text
Cancel
    │
    ▼
Task stops
```

Cancellation is about **termination**, not about controlling the application.

---

I would preserve this distinction:

* `std.Io.cancel` → "stop executing."
* `Mailbox` → "tell the Master to do something."

Those are complementary.

---

In fact, I think your documentation should make this explicit:

```text
std.Io
    How execution happens.

Mailbox
    What the execution should do.
```

A `Shutdown` message sent through the mailbox is a domain decision.

Calling `Future.cancel()` is a runtime decision.

Those should not be conflated.

So I would **not** migrate examples that manage Masters via mailbox to use cancellation. If anything, I'd add a note explaining why the mailbox-based approach is intentional:

> A Master is controlled by messages. Cancellation is reserved for aborting execution, not for normal application behavior.

That preserves one of the core ideas of Matryoshka even as it adopts `std.Io` for execution.

I wouldn't call it a "thread migration."

You're changing the **execution model** while keeping the architecture.

Some good names, from most to least fitting:

1. **Execution Model Migration** ⭐⭐⭐⭐⭐

   * Clear.
   * Accurate.
   * Says exactly what is changing.

2. **std.Io Integration**

   * Good if the goal is to align Matryoshka with Zig's new runtime.

3. **Execution Context Migration**

   * Highlights the terminology shift from "thread" to "execution context."

4. **Master Execution Refactoring**

   * Appropriate if the changes are mostly internal.

5. **Runtime Integration**

   * Emphasizes that `std.Io` becomes the execution runtime.

---

For a GitHub milestone or design document, I'd use:

> **Execution Model Migration**

with a subtitle such as:

> *Adopt `std.Io` as the execution runtime while preserving the Matryoshka ownership model.*

That captures the essence:

* **Not changing**

  * PolyNode
  * Mailbox
  * Pool
  * Ownership
  * Message passing

* **Changing**

  * How Masters are started
  * How Masters execute
  * Examples
  * Documentation
  * Tests

In other words, the architecture stays the same; only the execution engine changes. That's why "Execution Model Migration" is an accurate and appropriately scoped name.

Yes, I think I understand what you're asking.

You're not asking **how to spawn work**.

You're asking:

> **What is the lifetime of an `io.concurrent()` task?**
>
> Is it analogous to:
>
> * `std.Thread.spawn()` (detached),
> * `std.Thread.spawn()` + `join()`,
> * or something else?

That's the critical question.

With threads you have:

```text
spawn()
    ↓
Thread
    ↓
join()
```

Ownership is explicit.

With `std.Io`, it looks more like:

```text
future = io.concurrent(...)
```

Now who owns that `Future`?

Someone has to.

Typically it's:

```text
Master A
    |
    +-- starts Master B
            |
            +-- Future
```

and later

```text
try future.await(io);
```

or

```text
group.add(future);
```

So the "attachment" is not to a parent thread—it's to the **owner of the `Future`**.

That's a different ownership model.

---

## Your real question

I think what you're looking for is whether `std.Io` has the equivalent of:

```text
Master.startAttached(...)
```

where the runtime guarantees:

* the task starts,
* someone owns its lifetime,
* someone waits for its completion,
* resources are reclaimed.

I haven't seen such a concept in the parts of `std.Io` you've shown.

What I *have* seen is `Future` and `Group`, which suggest that attachment is expressed by **holding the returned `Future`**, not by the runtime automatically attaching tasks.

---

## This is worth investigating

Before redesigning Matryoshka, I'd answer these questions from the `std.Io` API:

1. What happens if the `Future` returned by `io.concurrent()` is dropped?
2. Is there a detached mode?
3. Is there an equivalent of `join()`?
4. Is `Io.Group` the intended parent-child lifetime mechanism?

Those answers determine how a Master should be started and owned in the `std.Io` world. Until then, I would avoid assuming that `io.concurrent()` is simply a replacement for `Thread.spawn()`.

I agree.

In fact, I think this is the right boundary for Matryoshka.

Matryoshka should say:

* A Master is a role.
* A Master owns a mailbox and other resources.
* A Master executes sequentially.
* A Master communicates via mailboxes.

It should **not** say:

* how an `Io` implementation schedules it,
* whether it's a thread, fiber, coroutine, or task,
* how `io.concurrent()` works internally,
* how `Future`/`Group` manage lifetimes.

Those are responsibilities of `std.Io`.

So instead of saying:

> "A Master runs on a thread."

you can say:

> **A Master runs in an execution context provided by the application.**

Or, if Matryoshka becomes explicitly `std.Io`-based:

> **A Master runs in an execution context provided by an `Io` implementation.**

Then stop there.

That keeps the layering clean:

```text
std.Io
    execution

Matryoshka
    ownership
    communication
    object lifetime
```

That's actually a stronger architecture than before, because Matryoshka no longer has to explain or justify an execution model—it simply builds on one.


Given your writing style (short, direct, no academic language), I'd avoid "execution context." It's correct, but it sounds like specification language.

Here are better options, from my favorite to least favorite:

1. **A Master runs on an Io executor.** *(if Zig eventually uses "executor" consistently)*

   * Short.
   * Familiar to concurrency programmers.

2. **A Master runs under Io.** ⭐

   * Very simple.
   * Doesn't explain Io internals.
   * Similar to "runs under Linux."

3. **A Master runs inside an Io runtime.**

   * Natural if you want to emphasize the runtime.

4. **Io runs the Master.** ⭐⭐⭐

   * Probably my favorite for documentation.
   * Active voice.
   * Human.
   * Makes responsibilities obvious.

For example:

```text
A Master is a role.

Io runs the Master.

The Master owns its mailbox, pool, and objects.
```

Or:

```text
Matryoshka defines what a Master is.

Io runs it.
```

I think **"Io runs the Master."** matches the tone of all your existing documents. It says exactly what changed without introducing new jargon or forcing readers to learn terms like "execution context."

Yes. I think this is the **main architectural change**.

Former Matryoshka said:

```text
A Master is a role.

A thread runs the Master.
```

New Matryoshka would say:

```text
A Master is a role.

Io runs the Master.
```

That's a surprisingly small wording change, but it's a significant architectural shift.

It means Matryoshka no longer owns or defines the execution model. Instead, it assumes one exists and builds on top of it.

I'd even summarize the migration in one sentence:

> **Matryoshka no longer manages execution. It manages ownership. Io manages execution.**

I think that's the key message that should guide the documentation, examples, and tests. Everything else follows from that separation.

Based on the current `std.Io` API, I would call it a **task**.

Why?

Because:

* `Thread` already has a well-defined meaning (OS thread).
* `Future` is the **handle** returned to the caller.
* The thing that is actually executing is naturally called a **task**.

Conceptually:

```text
Master        ← role
Task          ← execution
Future        ← handle to the task
Io            ← starts and schedules the task
```

So:

```zig
const future = try io.concurrent(master.run, .{master});
```

can be described as:

1. `io.concurrent()` **starts a task**.
2. The task **runs the Master**.
3. The returned `Future` **represents that task**.

That terminology is used by many runtimes (Tokio, async-std, TBB, .NET Task, etc.), so it's intuitive.

For Matryoshka, I'd probably write:

> A Master is a role.
>
> An Io task runs the Master.
>
> The application starts and manages the task.

That keeps the distinction clean:

* **Master** = architectural concept.
* **Task** = runtime execution unit.
* **Future** = object used to observe or await the task.

This example actually shows the terminology problem clearly.

The code says:

```zig
ws.serve_task = io.concurrent(serve, .{ws}) catch |err| {
    log.err("unable to spawn web server thread: {t}", .{err});
    ...
};
```

The code no longer **spawns a thread**. It starts a **concurrent task**.

The log message is now misleading:

```text
unable to spawn web server thread
```

should become something like:

```text
unable to start web server task
```

or:

```text
unable to start web server
```

depending on how much detail you want exposed.

---

For Matryoshka terminology, this maps nicely:

```text
ws.serve_task
    |
    +-- Io Task
          |
          +-- runs serve()
                |
                +-- operates on Master
```

So I would use:

* `task` → runtime execution unit
* `Future` → handle returned by `io.concurrent`
* `Master` → application role

Example documentation:

> Io starts a task that runs the Master.

Not:

> Io starts a thread that runs the Master.

---

One subtle point: I would avoid naming the field `serve_future` if it represents the running activity. `serve_task` is more readable. The future is the mechanism for waiting on it; the task is what exists conceptually. Your example is already moving toward the right vocabulary.


I think this is the right place to separate **starting a Master task** from **sending work to a Master**.

The pattern would be:

```text
1. Create Master object
2. Create its Mailbox
3. Start Io task running Master loop
4. Transfer handles to the Mailbox
5. Master receives and processes them
```

Conceptually:

```text
                 Io
                 |
                 |
          starts task
                 |
                 v
          +-------------+
          |   Master    |
          |   task      |
          +-------------+
                 |
                 |
             mailbox
                 ^
                 |
          send handles
```

The task does not receive objects directly.

The mailbox is the boundary.

---

Example shape:

```zig
const master = try Master.create(io, allocator);

master.task = try io.concurrent(Master.run, .{master});
```

Then elsewhere:

```zig
var item: polynode.Slot = object;

try mailbox.send(&item);
```

Ownership moves:

Before:

```text
Caller
  owns object
```

After `send()`:

```text
Mailbox
  owns object
```

Then:

```zig
Master.run()
{
    while (true) {
        var slot: polynode.Slot = null;

        mailbox.receive(&slot, null);

        process(slot.?);
    }
}
```

Ownership moves again:

```text
Mailbox
    |
    v
Master
    owns object
```

---

The important architectural point:

`io.concurrent()` starts **the worker**.

`Mailbox` starts **the conversation**.

They solve different problems.

```text
Io task:
    "Where does the code run?"

Mailbox:
    "How do objects move between owners?"
```

So the migration does not replace mailbox communication with `Future` communication.

A Master still lives behind a mailbox. The only change is:

Old:

```text
OS thread
    runs Master loop
```

New:

```text
Io task
    runs Master loop
```

The mailbox remains the object-transfer boundary.


I think you mean:

> When `io.concurrent()` starts the Master task, how does the task get the mailbox handle it should receive from?

The answer is: **pass it as an argument to the function you give to `io.concurrent()`.**

`io.concurrent()` does not know about Master or Mailbox. It just runs a function with arguments.

Example:

```zig
const Master = struct {
    mailbox: MailboxHandle,

    fn run(self: *Master) void {
        while (true) {
            var slot: polynode.Slot = null;
            self.mailbox.receive(&slot, null) catch break;

            self.process(slot.?);
        }
    }
};
```

Start:

```zig
master.task = try io.concurrent(
    Master.run,
    .{master},
);
```

The task receives `master`, and the master already contains the mailbox.

---

Alternative: pass mailbox directly:

```zig
fn masterLoop(mailbox: MailboxHandle) void {
    while (true) {
        var slot: polynode.Slot = null;
        mailbox.receive(&slot, null) catch break;

        process(slot.?);
    }
}

const task = try io.concurrent(
    masterLoop,
    .{mailbox},
);
```

---

Architecturally I prefer the first form:

```text
Io task
    runs
        Master.run()

Master
    owns
        Mailbox
        Pool
        Objects
```

because the mailbox is part of the Master's identity.

The flow becomes:

```text
create Master
    |
    +-- create Mailbox
    |
    +-- start Io task(Master.run)
              |
              +-- receives from Master's mailbox
```

So the mailbox is not "attached" to the task by `Io`.

It is attached to the **Master object**, and the task simply executes the Master's behavior.

