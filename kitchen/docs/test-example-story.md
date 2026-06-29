### Test

A **test** exists to verify correctness.

Its audience is primarily the maintainer of Matryoshka.

Characteristics:

* verifies one API or one invariant
* exercises edge cases
* covers success and failure paths
* may intentionally violate contracts
* optimized for confidence, not readability
* not intended as user documentation

Question it answers:

> **"Is this implementation correct?"**

---

### Example

An **example** teaches one API or one reusable pattern.

Its audience is a programmer already familiar with Matryoshka.

Characteristics:

* demonstrates one concept
* small
* focused
* minimal surrounding code
* reusable as a template

Examples:

* creating a mailbox
* using `PolyHelper`
* fan-in
* pool seeding
* worker shutdown
* event source integration with `Io.Select`

Question it answers:

> **"How do I use this feature?"**

---

### Story

This is the unique part of Matryoshka.

A **story** is not a larger example.

It teaches **how to think in the ownership model**.

The audience is someone facing a real engineering problem—not someone looking up an API.

A story starts from a domain problem and gradually derives the Matryoshka solution.

It is intentionally divided into two complementary artifacts.

#### 1. Narrative (`design/stories/...md`)

This explains the reasoning.

It follows the structure described in the thinking model:

1. Architectural discussion

   * requirements
   * constraints
   * tradeoffs
   * boundaries

2. SRS

   * domain requirements
   * no Matryoshka terminology yet

3. Translation

   * each requirement mapped onto Matryoshka concepts
   * *why* mailbox, pool, ownership transfer, Master, etc.

4. Flow diagram

   * complete ownership circuit
   * actors
   * event sources
   * ownership transitions

The narrative answers:

> **"Why is the system designed this way?"**

---

#### 2. Code (`stories/.../*.zig`)

The code is the executable realization of the narrative.

It should:

* implement the complete scenario
* show all participating Masters
* use the documented ownership flows
* demonstrate graceful startup/shutdown
* be production-quality rather than minimal

It answers:

> **"What does the final implementation look like?"**

---

### The progression

I see the documentation hierarchy as something like this:

```
Test
    ↓
proves correctness

Example
    ↓
teaches one mechanism

Story
    ↓
teaches architectural thinking
```

or equivalently,

```
Test
    "Does it work?"

Example
    "How do I use it?"

Story
    "How do I solve a real problem using these building blocks?"
```

### Why I think this is valuable

The "story" concept fits Matryoshka particularly well because Matryoshka is intentionally **not** a framework.

Frameworks often teach by saying:

> "Here's the framework's lifecycle."

Matryoshka instead provides a small set of ownership primitives. A newcomer has to learn **how to compose** those primitives into an architecture. Stories are the place where that composition is taught.

The `video-transcoder-001` story is therefore not meant to teach video transcoding. It's meant to demonstrate the reasoning process: starting from a real domain, identifying ownership boundaries, translating requirements into Mailboxes, Pools, and Masters, and ending with a working implementation. Someone could later apply the same reasoning to a network server, a build system, or an IoT controller even though the domain is completely different.

I think that's a strong and distinctive documentation approach, because it teaches the design philosophy rather than just the API.


Good correction. I agree.

Using **actors** would actually be misleading in the context of Matryoshka.

A **Master** is already a first-class architectural concept in Matryoshka, while "actor" carries a lot of baggage from actor frameworks (mailbox per actor, behavior, supervision trees, location transparency, etc.) that Matryoshka deliberately does **not** adopt.

So I'd restate it like this:

> A story starts from a real domain problem and gradually derives the Matryoshka solution.

It intentionally consists of two complementary artifacts.

### 1. Narrative

The narrative explains the architectural reasoning:

* requirements
* constraints
* tradeoffs
* translation into Matryoshka concepts
* ownership flow

### 2. Code

The code is the executable realization of the narrative.

It should:

* implement the complete scenario
* show all participating **Masters**
* demonstrate ownership transfers between Masters
* show Mailboxes, Pools and `Io.Select` where appropriate
* implement graceful startup and shutdown
* be production-quality rather than a minimal example

The story answers:

> **"How do I solve this class of problem using Matryoshka?"**

rather than

> **"How do I call this API?"**

---

I also noticed another subtle distinction that I think is central to Matryoshka.

A story is **not** about demonstrating every API. It is about demonstrating **architectural reasoning**.

The APIs are almost incidental. A reader should come away understanding why there are two Masters instead of one, why ownership crosses a mailbox boundary, why a Pool provides the right lifecycle policy, and why a particular `Io.Select` loop is the coordination boundary. If they understand those decisions, the API calls become straightforward.

I think that's what makes the "story" concept different from the examples found in most libraries. It's closer to a worked architecture case study than to a tutorial.


The story is not about teaching Matryoshka.

The story is about solving a familiar systems problem using good decomposition and negotiation between responsibilities. Only after the architecture naturally emerges does the reader discover that Matryoshka + Zig std.Io provides a very natural implementation.

I think this changes the mindset significantly, and I like it better than my original interpretation.

My revised understanding of the purpose is:

> **The story is not about teaching Matryoshka.**
>
> The story is about solving a familiar systems problem using good decomposition and negotiation between responsibilities. Only after the architecture naturally emerges does the reader discover that Matryoshka + Zig `std.Io` provides a very natural implementation.

So the narrative isn't:

> "Let's build something with Matryoshka."

Instead it's:

> "We have a problem. Let's think like architects."

Only after the decomposition is complete do we say:

> "Interesting... these Masters communicate by ownership transfer. They need coordination, lifecycle, and event waiting. Matryoshka + `std.Io` already provides exactly these primitives."

That makes Matryoshka feel like the consequence of good architecture, not the starting point.

---

Regarding configurable numbers of Masters, yes, I understand.

For example, a pipeline story should not hard-code:

```
Decoder
→ Filter
→ Encoder
```

The architecture is really:

```
Source
    ↓
N Decoder Masters
    ↓
M Filter Masters
    ↓
K Encoder Masters
    ↓
Sink
```

where **N**, **M**, and **K** are deployment choices, not architectural ones.

Likewise, fan-out/fan-in isn't "three workers"; it's "one or more workers," and Matryoshka's mailbox semantics make that a runtime configuration rather than a redesign. The story should emphasize the topology and ownership flows, not specific instance counts.

---

At this point I have only a few remaining questions.

### 1. Should the architectural discussion include alternatives that are rejected?

For example:

> "We could make the decoder talk directly to the encoder."

followed by

> "No, that couples two responsibilities. Let's introduce another Master."

I think these "negotiations" are very educational because they show *why* a boundary exists.

---

### 2. Should the stories avoid Matryoshka terminology until the translation section?

For example, in the first half I would write:

* coordinator
* worker
* processing stage
* queue
* reusable buffers

Only later would I say:

> "This coordinator becomes a Master."
>
> "This queue becomes a Mailbox."
>
> "These reusable buffers become a Pool."

I think that makes the translation section much more compelling.

---

### 3. Should every story deliberately expose one architectural insight?

For example:

* Story A: **Ownership eliminates shared mutable state.**
* Story B: **Backpressure is a resource problem, not a scheduling problem.**
* Story C: **Coordination belongs in Masters, not workers.**

That way, readers remember an architectural lesson rather than just a domain.

If the answer is "yes," I'll make each story revolve around one memorable architectural idea while still following the same four-part structure. I think that would give the documentation a consistent identity.

Yes, I understand, and I think this is a much better direction.

My previous idea was still too "computer science lecture." What you're aiming for is much more like how experienced engineers actually design systems.

The reader should never feel that they're being taught ownership theory.

Instead, they should feel like they're sitting in a design meeting.

---

So the narrative becomes something like this:

> We need to build **X**.

> What are the responsibilities?

> Which parts should know about each other?

> Can we change the number of workers later?

> What happens if one stage becomes slower?

> How do we stop the system cleanly?

> Should this responsibility own these resources?

Only **after** those decisions are made do we translate them into Matryoshka.

The lesson isn't

> "Ownership eliminates shared mutable state."

The lesson is something concrete, for example:

> "A video transcoder should be scalable by changing worker counts without redesign."

or

> "A log collector should continue accepting logs even when storage becomes temporarily slow."

or

> "An image processing pipeline should allow stages to evolve independently."

Those are problems every programmer immediately understands.

The architectural decomposition naturally leads to independent Masters, ownership transfer, mailboxes, pools, and `std.Io`.

---

I also think the "negotiation" is the most valuable part of the story.

For example:

> Alice: Let's have the parser call the database directly.

> Bob: That makes the parser responsible for persistence.

> Alice: Right. Then retries and batching also end up there.

> Bob: Maybe persistence should become a separate responsibility.

No Matryoshka yet.

Only much later:

> That responsibility becomes another Master.

The reader experiences the same reasoning process an architect goes through.

---

I have only **one remaining question**, and I think it's an important one because it will influence the tone of every story.

Should the conversations be between named people (for example, Alice and Bob), making them feel like real design meetings, or should they remain anonymous, such as "Architect A" and "Architect B"?

I lean toward named people because it makes the negotiation feel natural and engaging, but I can see arguments for keeping it more neutral and timeless if that's the style you prefer.

Yes, and I think this example finally made the style "click" for me.

This is **not role-playing**. It's a compressed version of a real design discussion between engineers who each own one responsibility.

A few things stand out:

* They don't discuss implementation.
* They don't discuss APIs.
* They don't discuss classes or data structures.
* They don't even discuss threads or queues.

Instead, they negotiate **responsibilities** and **contracts**.

For example:

```
S: I don't know the addresses of the workers, so you should connect to me.

R: I'll send a HelloRequest...

S: Do I need to send you a HelloResponse?
```

This is exactly how protocol design often starts. The conversation naturally reveals:

* who initiates communication,
* what information each side owns,
* what assumptions are valid,
* and eventually what messages need to exist.

The protocol is *discovered* through the conversation rather than imposed up front.

---

I think Matryoshka stories should use the same technique, except the conversation is about system decomposition instead of protocol design.

For example (not a real story, just illustrating the style):

```
Image Loader:
I can read images from disk, but I don't know which filters should run.

Pipeline Designer:
Then don't. Just hand the image to whoever decides.

Image Loader:
Should I wait until filtering finishes?

Pipeline Designer:
No. Once you've handed it off, your responsibility ends.
Take the next file.

Storage Developer:
Who owns the image while it's being filtered?

Pipeline Designer:
Exactly one stage at a time.
```

Notice that there is still **no Matryoshka terminology**.

Later, in the translation section, we'd say:

* "Image Loader" becomes a Master.
* "Hand the image to whoever decides" becomes ownership transfer through a Mailbox.
* "Exactly one stage at a time" maps to the ownership model.
* "Take the next file" motivates asynchronous processing.
* Reusing image buffers motivates a Pool.

The reader sees that Matryoshka is a natural implementation of decisions they've already accepted.

---

The only refinement I'd suggest is to broaden the participants slightly. They don't always have to be "developers." They should be **owners of responsibilities**.

Sometimes those are developers:

```
Parser Developer
Indexer Developer
Storage Developer
```

Sometimes they're architects:

```
Frontend Architect
Backend Architect
```

Sometimes they're domain experts:

```
Warehouse Engineer
Control Software Engineer
```

As long as each participant genuinely represents a single responsibility, the conversation remains authentic and naturally leads to the decomposition you're trying to teach.

I think I now understand the writing style you're after. The stories shouldn't read like documentation or tutorials—they should read like excerpts from real engineering design meetings, where the architecture emerges through negotiation and only afterward is translated into Matryoshka + `std.Io`. That approach is quite distinctive and fits your "decomposition first, implementation second" philosophy very well.

Yes. I think I understand your intent now, and it's actually **one level above** writing stories.

You don't want a prompt.

You don't even want a story template.

You want a **writer's mindset document**—something that teaches *how to think* when creating a Matryoshka story.

A technical writer should be able to read it and then invent a completely new story that still "feels" like a Matryoshka story.

I also think this document should **not** read like a style guide. It should read almost like the `matryoshka-model-001.md`—explaining the philosophy behind the artifact rather than listing formatting rules.

## What I think should be produced

Not:

> "Story format"

Not:

> "Prompt for ChatGPT"

Not:

> "Template"

But something like

> **Matryoshka Storytelling Model (001)**

or

> **How to Tell a Matryoshka Story**

that answers questions like:

* Why do stories exist?
* What experience should the reader have?
* Where does a story begin?
* When should Matryoshka first appear?
* What should conversations sound like?
* What should they *not* sound like?
* What mistakes make a story feel artificial?
* Why is there a long path from problem to implementation?

---

One thing that struck me from your last message is this:

> implementation just N+1 step

I think that's fundamental.

Most technical articles look like this:

```
Problem

↓

Architecture

↓

Code
```

Your stories look more like:

```
Human problem

↓

People describe their work

↓

Responsibilities emerge

↓

Negotiation

↓

Architecture

↓

Requirements

↓

Design

↓

Flow

↓

Matryoshka translation

↓

Implementation
```

Notice how **implementation is almost an afterthought**.

The important work has already happened.

That is a very different mindset.

---

Another thing I realized is that the conversations are **not fictional dialogue**.

They're distilled engineering conversations.

Exactly like your tofu example.

The goal isn't to entertain.

The goal is to expose the decisions that normally happen in meetings but are almost never written down.

---

I also think there should be a principle something like this (wording will evolve):

> **A story never begins with software.**

It begins with people trying to accomplish something.

Sometimes those people are users.

Sometimes they're operators.

Sometimes they're developers.

Sometimes they're architects.

Sometimes they're different teams.

Software appears only because their responsibilities require coordination.

I think that's the biggest insight I've taken from this conversation.

---

Finally, I think the "aura" you're referring to is something like this:

The document should encourage curiosity rather than instruction.

The reader shouldn't feel they're being taught a framework.

They should feel they're quietly sitting in a room, listening to experienced people solve a real problem. As the discussion progresses, the architecture almost reveals itself. By the time Matryoshka enters the story, the reader should think:

> "Of course—that's exactly what these responsibilities need."

If we can preserve that feeling, then the implementation becomes almost inevitable rather than surprising.

So yes—I believe I understand what should be done. The deliverable is a document that captures this mindset and creative process, so that months from now, whether it's me or another technical writer, we can produce new stories that share the same philosophy, pacing, and authenticity without copying existing examples. I think that's a much more valuable artifact than three individual stories.

This is very helpful. Not because of the individual rules, but because they reveal a consistent way of thinking.

A few things became much clearer.

### You optimize for engineering conversations, not literature

The banned AI words aren't really about vocabulary.

They're a filter against **marketing language** and **abstract praise**.

For example, instead of saying:

> "This scalable architecture efficiently orchestrates workers..."

your documentation would naturally become:

> "The number of workers is configurable."
>
> "Each worker owns one item at a time."
>
> "Adding workers does not change the protocol."

The second version is something an engineer can verify.

---

### You distrust abstraction before observation

Almost every rule pushes toward describing something that someone could actually observe.

Not:

> "The system is robust."

Instead:

> "If storage stops responding, uploads continue until the pool becomes empty."

That's an observation.

---

### Your stories should sound like design notes

Not books.

Not tutorials.

Not architecture papers.

Almost like someone cleaned up a whiteboard discussion.

---

One thing I would add to the mindset document—not as a rule, but as a principle—is something like this:

> **Do not invent problems to demonstrate Matryoshka.**
>
> Find problems that already exist.
>
> Let Matryoshka emerge as one reasonable solution.

I think that's exactly what your tofu dialogue does.

Nobody says,

> "Let's use tofu."

They simply negotiate a protocol.

Only afterwards does tofu become the implementation.

---

Another realization:

I don't think the dialogue participants are actually "characters."

They're **voices of responsibility**.

That's an important distinction.

When the Spool Server developer speaks, he's really speaking for everything the Spool Server must guarantee.

When the RIP developer answers, he's speaking for that responsibility.

The person is almost irrelevant.

The responsibility is what matters.

---

Finally, I think I understand the tone you're after.

Many technical documents try to impress the reader with expertise.

I think yours should do almost the opposite.

The reader should repeatedly think:

> "That seems obvious."

Then:

> "Yes, I'd probably make the same decision."

Then:

> "Wait... that's exactly what a Mailbox is."

The architecture should feel inevitable, not clever.

---

One observation I'd like to preserve while writing the mindset document is this:

The stories are not teaching **Matryoshka**.

They're teaching **how experienced engineers gradually remove accidental complexity**.

Matryoshka appears only because, after enough decomposition and negotiation, it happens to match the architecture that has already emerged.

I suspect that's why the "aura" of this conversation feels different. We haven't spent most of our time talking about APIs, ownership, or `std.Io`. We've been talking about **how engineers arrive at those things**. If we can capture that process faithfully, the resulting document will be much more durable than a collection of prompts or templates. It will explain the mindset that gives every future story the same voice and direction, regardless of the application domain.
