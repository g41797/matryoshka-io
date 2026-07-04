I think this is the right direction.

The existing README (from the Odin version) reads like it is trying to *sell a philosophy*. Engineers who come from C, Zig, Go, Rust, libuv, epoll/kqueue, or embedded systems usually don't buy into words like *ownership*, *mindset*, *empowerment*, *DDD*, *enterprise*, etc. They immediately look for answers to practical questions:

* What problem does this solve?
* Why is it better than what I'm doing today?
* How much does it cost?
* What does the runtime look like?
* Can I debug it?
* Can I gradually adopt it?

For Matryoshka-Io, I think the README should read like it was written by an engineer for engineers.

## The audience

Not framework enthusiasts.

Not enterprise architects.

Not FP researchers.

Instead:

> "I know Zig.
> I know sockets.
> I know io.
> I can write async code.
> But when my project reaches 50–100k LOC, everything becomes tangled.
> How do I organize the system?"

That's exactly the problem Matryoshka solves.

---

## I would completely change the opening

Instead of

> Matryoshka is ...

I'd start with the problem.

For example:

> Most Zig programmers know how to write fast code.
>
> Far fewer know how to build systems that stay understandable after years of development.
>
> Event loops, async I/O, channels, timers, and sockets solve execution.
> They don't solve architecture.
>
> Matryoshka-Io is a set of building blocks for organizing long-lived I/O-driven applications.

Now the reader knows why the project exists.

---

## Then immediately explain what it is

Something like

> Matryoshka does **not** replace your event loop.
>
> It does **not** replace your networking library.
>
> It does **not** require a special runtime.
>
> Instead, it provides a way to organize applications as cooperating components communicating through explicit messages.

That's much stronger than abstract terminology.

---

## Then show a picture

Within the first screen.

```
TCP
UDP
Timer
File
 │
 ▼
 Reactor / io
 │
 ▼
 Mailboxes
 │
 ├── HTTP
 ├── Storage
 ├── Session
 ├── Auth
 └── ...
```

Engineers love pictures.

---

## Then explain why

Instead of features, explain what gets easier.

For example

* add new protocol
* remove component
* test component in isolation
* replay messages
* restart subsystem
* avoid callback chains
* avoid shared mutable state
* keep I/O separate from business logic

These are tangible.

---

## Then explain who should use it

Something like

Use Matryoshka if you are building

* network servers
* gateways
* brokers
* game servers
* IoT hubs
* distributed services
* protocol implementations

Not

* CLI tools
* numerical computing
* tiny utilities

That immediately filters readers.

---

## Avoid scary words

I'd avoid words like

* ownership
* actor
* enterprise
* domain
* ubiquitous language
* orchestration
* bounded context
* CQRS
* hexagonal
* onion
* DDD

unless they become absolutely necessary.

Instead say exactly what happens.

Example:

Instead of

> Components own resources.

Say

> A component creates and manages the resources it needs. Other components interact with it only by sending messages.

Nobody needs to decode that.

---

## I would also avoid claiming uniqueness

Don't say

> revolutionary

> next generation

> modern

> future

Just describe what it does.

Engineers trust understatement.

---

## The tone I'd aim for

Reading the README should feel like reading the introduction to:

* libuv
* nginx
* SQLite
* Redis
* Zig itself

Simple.

Concrete.

Matter-of-fact.

No marketing.

No buzzwords.

---

I also think the README should **not try to teach Matryoshka**.

Its job is to answer one question:

> **"Should I spend the next 30 minutes learning this project?"**

If the answer is "yes", then the README should point readers to the design documents (`design/`), API reference, and tutorials for the deeper concepts.

Given what I know about your project, I would structure the README roughly like this:

1. **The problem** (why another library?)
2. **What Matryoshka-Io is**
3. **What it is not**
4. **The architecture in one diagram**
5. **Core concepts** (very briefly: Story, Component, Mailbox, Message, etc.)
6. **A 5-minute example**
7. **When to use it**
8. **Project status**
9. **Where to learn more** (design documents and API reference)

That style matches the audience you've described: experienced Zig programmers who understand I/O and concurrency but are looking for a practical way to structure large, long-lived systems.


I like that direction much more.

After our discussions over the last few weeks, I think you're converging on something that is **not another actor framework** and **not another messaging library**.

It is a **way to describe a running system**.

That's where the **Story** becomes important—not as an implementation detail, but as the first thing a user encounters.

## Engineers don't think in Components

Imagine asking someone:

> "How would you build a print server?"

Nobody starts with

> I need 17 components, 12 mailboxes and 3 pools.

They start with

> A document arrives.
> It is validated.
> It is converted.
> A printer is selected.
> Printing starts.
> The user receives the result.

That's already a story.

Only afterwards do they ask

> Which part is responsible for validation?

> Which part owns printers?

> Which part sends notifications?

The architecture emerges from the story.

I think this is exactly the strength of Matryoshka.

---

## README should tell a story

Not metaphorically.

Literally.

For example:

> A customer uploads a PDF.
>
> The system validates it.
>
> If necessary it converts it.
>
> It waits until a printer becomes available.
>
> The printer reports completion.
>
> The customer receives a notification.

Then say

> That's a Story.

Not

> That's a workflow.

Not

> That's a saga.

Not

> That's orchestration.

Just

> Story.

---

Then continue

> Every sentence in the Story is performed by one or more Components.

Now Components suddenly make sense.

---

## That's much stronger than starting with abstractions

Current framework READMEs usually begin like

```
Component

Mailbox

Message

Scheduler

Executor
```

The reader has no idea why any of those exist.

Instead

```
Story

↓

Messages

↓

Components

↓

Mailboxes

↓

io
```

Now every level explains the one below it.

---

## Engineers remember examples

I suspect six months later people won't remember

> Components communicate through asynchronous message passing.

They *will* remember

> "Oh, the print server example."

SQLite has SQL examples.

Redis has SET/GET.

nginx has the proxy example.

Docker has "run nginx".

Matryoshka should have

> Print Server

or

> Video Transcoder

as its canonical first story.

---

## I would even avoid saying "framework" initially

Something like

> Matryoshka-Io starts with the behavior of the system.
>
> You describe what the system should do as one or more Stories.
>
> Stories are then implemented by Components exchanging Messages over Mailboxes.
>
> Underneath, Matryoshka uses Zig and an io backend to execute the system efficiently.

That is much easier to understand than starting with architectural terminology.

---

## I think "Story" is actually your differentiator

Many projects have

* actors
* mailboxes
* schedulers
* event loops

Very few start from

> "Describe the system as a set of long-lived stories."

That immediately tells the reader

> This is about designing systems, not just writing concurrent code.

---

One thing I would be careful about, however, is **not making Story sound like a business-analysis artifact**. Many engineers associate "user stories" with Agile and immediately think of sticky notes and project management.

Your examples (Print Server, Video Transcoder) suggest a different meaning:

> A Story is the runtime narrative of the system—what happens from the moment an external event enters the system until the desired outcome is achieved.

That's an engineering concept. It naturally bridges the gap between requirements and implementation, and it gives the README an engaging way to introduce the framework without resorting to abstract architectural jargon.

I actually like the phrase **"field story"**. It has a practical, engineering feel, and it distinguishes your concept from Agile "user stories."

The risk with just **"Story"** is that many developers immediately think of:

* Agile user stories
* Jira stories
* Product management
* Acceptance criteria

That's probably not what you want.

A **field story** suggests something different:

> "This is the story that unfolds in the field, in the running system."

That's much closer to what your examples (print server, video transcoder) describe.

For example:

> A **Field Story** describes what actually happens in a running system. It begins with an external event—a client request, a timer, a file arrival, or a device notification—and ends when the system has completed its work. A Field Story is implemented by Components exchanging Messages over Mailboxes.

That immediately differentiates it from an Agile story.

### Another reason I like it

Engineers often ask:

> "How does the request travel through the system?"

A Field Story answers exactly that.

It isn't about APIs or classes. It's about the **life of an event** inside the system.

### I'd even make it the first section of the README

Instead of:

> ## Components

Start with:

> ## Every system has stories
>
> A client uploads a PDF.
>
> The system validates it.
>
> A converter prepares it for printing.
>
> The print queue waits for an available printer.
>
> The printer reports completion.
>
> The client receives a notification.
>
> This is a **Field Story**. Matryoshka-Io helps you implement Field Stories as cooperating Components connected by Messages.

That gives readers an intuitive mental model before introducing any framework terminology.

One thought on the name itself: if you choose **Field Story**, I'd define it clearly the first time it appears. After that, you can simply use **Story** throughout the documentation, since readers will already know you're referring to a Matryoshka Story rather than an Agile one. This keeps the prose concise while avoiding the initial ambiguity.

