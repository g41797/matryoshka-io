I have the relevant context from this project's previous conversations, including the current README direction (Master, PolyNode, Mailbox, Pool, the "Shape of a Real System", and the shift to `io.concurrent()` tasks).

However, I **don't** have the actual `README.md` file text available line-by-line.

For a document titled **"Establish and Explain Terminology of Matryoshka"**, it would be much better if you upload the current `README.md`. That way I can:

* establish terminology that is **100% consistent** with the README,
* avoid introducing conflicting definitions,
* reuse existing wording where appropriate,
* identify terms that are currently used but never formally defined,
* produce a terminology section that can become the canonical reference for all other documentation.

The result can be structured roughly like:

```text
# Terminology

## Master
What it is.
What it is not.
Responsibilities.

## Task
(io.concurrent result)
How it differs from Master.

## PolyNode
...

## Item
...

## Mailbox
...

## Pool
...

## Builder
...

## Ownership
...

## Transfer
...

## Reuse
...

## Handle
...

## Runtime type
...

## Matryoshka System
...
```

Given how much the terminology has evolved recently (especially Master vs Task), I'd prefer to work from the latest README rather than rely on memory. Uploading it will produce a much cleaner and authoritative document.


Possibly we need such document as addendum

Now i am talking about README and landing/first page of doc site



We know Master is task

PolyNode as "super" Node

Mailbox

Pool



and everywhere we mess pointers, references, items , polynode, send item or send polynore or send ptr to etc



User does not understand this mess

I don't think that many devs will read it at all, but as profi i can not provide such documentation



Some thinkinh - and i don't force you to agree



Need reminder how to work with intrusive Node and all staff possibly reference to addedndum?



Also Why PolyNode is main block ? May be Item ?

May be ItemHandle?

We don't explain that Matryoshka style is "handle based code"

And all API looks like C like posix API

I actually agree with the direction you're thinking, but I think the problem is even deeper.

The README currently introduces **implementation objects before introducing the language of the architecture**.

A newcomer sees:

* Master
* PolyNode
* Mailbox
* Pool

but has never learned what an **item** is.

Then the documentation starts alternating between:

* item
* object
* PolyNode
* node
* pointer
* handle
* reference
* message

Sometimes all on the same page.

That makes every sentence slightly ambiguous.

---

## I think the terminology should have layers

Not alphabetical.

Conceptual.

### Layer 1 — System vocabulary

Teach people how to read the documentation.

```
Task
Master
Item
Ownership
Handle
```

After five minutes the reader should understand every later sentence.

---

### Layer 2 — Building blocks

Now explain

```
PolyNode
Mailbox
Pool
```

because now they already know what an Item is.

---

### Layer 3 — Implementation vocabulary

Only now explain

```
pointer
embedded node
type erasure
intrusive
runtime type
```

These are implementation details.

---

# The biggest issue is PolyNode

I actually think this is the wrong first concept.

Not because PolyNode is wrong.

Because **users don't build PolyNodes.**

They build

```
Connection
Request
Response
Timer
Buffer
Session
...
```

Those are **Items**.

Every Item contains a PolyNode.

The user mentally works with Items.

Matryoshka works with PolyNodes.

Those are different viewpoints.

---

Today README effectively says

> PolyNode is the primary building block.

But I think the truth is

> Item is the primary architectural building block.

PolyNode is what allows Items to participate in Matryoshka.

That is a huge difference.

---

# Then Handle becomes obvious

Right now

```
NodeHandle
PoolHandle
MailboxHandle
```

look like API names.

But they're actually a programming model.

I'd explicitly state

> Matryoshka is a handle-based architecture.

Then explain

```
Items are owned.

Items are transferred.

Items are never copied.

Items are accessed through handles.

Handles identify ownership, not lifetime.
```

That suddenly explains why almost every API looks like C.

It isn't trying to imitate C.

It's expressing ownership explicitly.

---

# I would almost ban the word "pointer"

Instead of saying

> send a pointer

say

> transfer an Item

Internally,

yes,

it's a pointer.

Architecturally,

it's an Item changing owner.

Likewise,

don't say

> Pool returns pointer

say

> Pool returns an Item.

Only in the API reference mention that the handle contains a pointer.

---

# I also think Mailbox documentation is backwards

Instead of

> Mailbox transfers PolyNodes

I'd write

> Mailbox transfers ownership of Items.

Then immediately explain

> Every Item contains a PolyNode.
>
> Mailbox operates on that embedded PolyNode.
>
> Therefore Mailbox never needs to know the concrete Item type.

That explains *why* PolyNode exists.

---

# I would add one addendum

Exactly as you suggested.

```
Appendix A

Reading Matryoshka Documentation
```

One page.

```
Item
    Your application object.

PolyNode
    Embedded into every Item.

Handle
    A typed way to access an Item.

Ownership
    Exactly one Master owns an Item.

Transfer
    Ownership moves from one Master to another.

Mailbox
    Transfers ownership.

Pool
    Stores reusable Items.

Master
    Owns Items.
```

Every other document could simply link to this glossary instead of redefining terms.

---

## One sentence that I think should become a design rule

I would put this near the beginning of the README:

> **Matryoshka is written in terms of Items. PolyNode, pointers, and handles are implementation mechanisms that allow Items to move safely between Masters.**

That one sentence changes the reader's mental model from "this is a library about intrusive nodes" to "this is an architecture for moving ownership of application objects."

I think that's much closer to what Matryoshka actually is.

Looks like we should use Item instead of ItemHandle

ALso stress the fact that all Matryoshka Items are long lived (not must) and allocated (MUST)

Looks like we should use Item instead of ItemHandle

ALso stress the fact that all Matryoshka Items are long lived (not must) and allocated (MUST)

PolyNode - internals that need to understand

 pointers, and handles - possibly "don't exists"



Item allows to move between tasks, be part of intrusive collections and recognise real "object"/"structure"



PolyNode - internal implementation, becuase Zig has not base classes derivations and all done via composition

Yes. I think this is a much stronger direction.

I would actually go one step further and deliberately hide `PolyNode` from the reader until they need it.

The architecture is **not about PolyNodes**. It's about **Items**.

## Item becomes the central concept

Everything becomes simpler if every sentence can be written in terms of Items.

Instead of

> Mailbox transfers PolyNodes.

say

> Mailbox transfers Items.

Instead of

> Pool stores PolyNodes.

say

> Pool stores reusable Items.

Instead of

> PolyNode-based object.

say

> Matryoshka Item.

Then define what an Item is.

> **Item** is a heap-allocated application object that participates in the Matryoshka architecture. Every Item embeds a `PolyNode`, allowing it to move between Masters, participate in intrusive collections, and be identified at runtime without interfaces or inheritance.

That single definition explains almost everything.

---

## Allocation should become part of the definition

I agree with stressing this.

I would make it a rule.

> A Matryoshka Item is allocated.
>
> Items are expected to have a lifetime much longer than a function call.
>
> They are transferred, reused, and eventually destroyed.

This distinguishes Items from temporary stack values.

---

## Long-lived is a consequence, not a requirement

I would be careful with wording.

Not

> Items are long lived.

Instead

> Items are designed to outlive the function that created them.

or

> Items usually live much longer than individual function calls.

Otherwise someone will immediately ask

> "Can I allocate one, send it once and destroy it?"

The answer should still be yes.

---

## PolyNode becomes an implementation detail

I'd almost move it to a separate section.

Something like

> ### How does this work?
>
> Zig has no inheritance or base classes.
>
> Every Item embeds a `PolyNode`.
>
> `PolyNode` provides the runtime information needed by Mailboxes, Pools, and intrusive collections.
>
> This is an implementation mechanism, not the architectural concept.

That feels much closer to how people think.

Nobody builds a `PolyNode`.

They build a `Request`.

---

## Handles almost disappear

This is the part I like most.

Instead of documenting

```
NodeHandle
MailboxHandle
PoolHandle
```

document

```
Item
Mailbox
Pool
Master
```

Handles become API types.

Not architectural concepts.

The documentation can simply state:

> Most Matryoshka APIs operate on handles rather than raw pointers. This keeps ownership explicit while hiding implementation details.

After that, you rarely need to mention them again.

---

## The mental model becomes

```
Application
    builds Items

Items
    move between Masters

Mailbox
    transfers Items

Pool
    reuses Items

PolyNode
    makes all of this possible
```

Notice that `PolyNode` is now at the bottom instead of the top.

---

I think this also changes the README's opening. Instead of introducing `PolyNode` as the first building block, I'd introduce **Item** first, even though it isn't a library type:

> **Item** is the fundamental building block of a Matryoshka system.
>
> An Item is your application object. It owns your data and behavior.
>
> Every Item embeds a `PolyNode`, which enables ownership transfer, intrusive collections, and runtime type identification.
>
> Mailboxes move Items between Masters.
>
> Pools recycle Items.
>
> Masters own Items.

That tells the story in the order that developers naturally think about their code: **their objects first, the infrastructure second**.

Exactly.

I think you're discovering that the **architectural building blocks** are different from the **implementation building blocks**.

The first page should contain only architectural concepts.

Something like:

```
Master
Item
Mailbox
Pool
```

Everything else is implementation.

---

## Master

A **Master** owns part of the application.

It is an Io task that:

* owns state
* owns Items
* communicates with other Masters

Architectural role:  
**execution and ownership**.

---

## Item

An **Item** is an application object.

Examples:

* Request
* Response
* Connection
* Session
* Timer
* Buffer

An Item:

* owns data
* can move between Masters
* can be reused
* participates in Matryoshka

Architectural role:  
**state**.

---

## Mailbox

A **Mailbox** transfers ownership of Items between Masters.

It does not know Item types.

It simply delivers Items.

Architectural role:  
**communication**.

---

## Pool

A **Pool** stores reusable Items.

Instead of destroying an Item,  
it returns it for later reuse.

Architectural role:  
**resource reuse**.

---

Notice something interesting.

These four concepts correspond almost exactly to every software architecture.

```
Execution  -> Master

State      -> Item

Communication -> Mailbox

Resources  -> Pool
```

That's a beautiful architectural model.

---

Then, in an appendix:

# How does this work?

Now you explain:

```
PolyNode

intrusive

type erasure

handles

runtime type

composition
```

These are implementation techniques.

Not architecture.

---

I also think **Item** needs one sentence that distinguishes it from an ordinary object.

Something like:

> An Item is an application object whose ownership can be transferred between Masters.

or even simpler:

> An Item is a movable application object.

Everything else follows from that.

That is far more memorable than "PolyNode is a bigger intrusive node." The latter explains *how* Matryoshka works; the former explains *what* developers build with it.

I don't like term "ownership" and want to remove it completely everywhere.

I think for zig devs it ai-sh, rust ...



First of all we need to describe that Matryoshka does a lot afforts to prevent share usage of Items

This is strong point - without ownership - only one user

I think you're onto something important.

The problem isn't just the word **ownership**. It's that it describes the *mechanism*, not the *benefit*.

A developer doesn't wake up wanting "ownership."

They want:

* no shared mutable state
* no "who is modifying this?"
* no accidental races
* no reference counting
* no lifetime puzzles

Those are the benefits.

---

## I would make the rule about **exclusive use**

Instead of

> Every Item has one owner.

say

> **An Item is used by one Master at a time.**

That's almost plain English.

Then explain:

> A Master may pass an Item to another Master.
>
> After that, it no longer uses that Item.

Notice there's no mention of ownership, but the semantics are identical.

---

## Or even simpler

I like this as a fundamental rule:

> **An Item can belong to only one place at a time.**

"Place" is intentionally vague.

A place may be:

* a Master
* a Mailbox
* a Pool

That matches your original design philosophy from months ago:

> An object sits in exactly one place, in exactly one state, at any moment.

That sentence is still one of the strongest descriptions of Matryoshka.

---

## I would avoid "ownership" entirely in the README

Use verbs instead.

Instead of

> owns Items

say

> uses Items

or

> works with Items

Instead of

> transfers ownership

say

> passes an Item

or

> transfers an Item

or

> hands an Item to another Master

Those are much more natural.

---

## The real invariant

I think this is actually the heart of Matryoshka:

> **Sharing is the exception. Moving is the default.**

Everything else exists to enforce that.

Not ownership.

Not handles.

Not PolyNode.

The architecture says:

> If two Masters need the same Item,
> don't share it.
>
> Move it.

That's the philosophy.

---

## Even stronger

I might state it positively.

> **Matryoshka is designed around exclusive access to Items.**

Then explain:

* one Master uses an Item
* or one Mailbox stores it
* or one Pool stores it

Never multiple places simultaneously.

Now you never had to use the word "ownership."

---

## I think the hierarchy becomes

```
Master
    performs work

Item
    contains application data

Mailbox
    passes Items

Pool
    keeps unused Items

Rule
    An Item is in exactly one place at a time.
```

Everything else—`PolyNode`, handles, intrusive lists—is simply how the library enforces that rule.

To me, **"An Item is in exactly one place at a time."** is a much more distinctive and memorable principle than "ownership," and it better reflects what makes Matryoshka different. It also avoids importing Rust terminology into a Zig project while preserving the same safety property.

Matryoshka based on well-known principle:

"Share by communicating"

Bryan C. Mills - Rethinking Classical Concurrency Patterns:

https://drive.google.com/file/d/1nPdvhB0PutEJzdCq5ms6UI58dp50fcAN/view

Share resources by communicating the resources themselves.  
Resource limits are resources too  
Share a thing by communicating the thing.


Yes. In fact, I think this is the missing architectural foundation.

Right now the README presents Matryoshka as **its own idea**. But it is actually an implementation of a well-established concurrency principle.

That immediately gives the reader confidence.

I would explicitly acknowledge it.

For example:

> **Matryoshka is built around a simple concurrency principle:**
>
> **Share by communicating.**
>
> Instead of sharing access to an Item, pass the Item itself.
>
> The Item moves from one Master to another.
>
> At any moment, it is in exactly one place.

Notice that this is **not Go's slogan** ("Do not communicate by sharing memory..."). It's Bryan C. Mills' stronger formulation:

> Share the thing by communicating the thing.

That is almost a perfect description of what Mailbox does.

---

## It also explains Pool

Bryan's second sentence is equally relevant:

> Resource limits are resources too.

Pool isn't just an allocator optimization.

A Pool is communicating reusable resources.

An Item moves

```
Master
    ↓
Mailbox
    ↓
Master
    ↓
Pool
    ↓
Master
```

Every transition is communication.

Nothing is shared.

---

## This may become the first architectural rule

Instead of talking about ownership, I'd simply say:

> **Matryoshka follows the principle "Share by communicating."**
>
> Items are not shared between Masters.
>
> Items move between Masters.
>
> Mailboxes move active Items.
>
> Pools move reusable Items.

That is much more memorable than "ownership transfer."

---

## Even better: explain *why* PolyNode exists

Once you've established this principle, `PolyNode` has a clear purpose:

> To communicate an Item without knowing its concrete type.

That's far stronger than:

> PolyNode is a bigger intrusive node.

It answers the "why," not the "how."

---

## I would cite the influence

I think it's professionally appropriate to have a short "Influences" or "Design Foundation" section:

> **Design foundation**
>
> Matryoshka is based on the concurrency principle *Share by communicating*, as described by Bryan C. Mills.
>
> Rather than sharing access to application objects, Matryoshka communicates the objects themselves. This naturally leads to exclusive access, simpler reasoning, and reusable resources.

That doesn't diminish Matryoshka—it places it in a respected lineage and helps readers immediately understand its philosophy. The originality of Matryoshka is not the principle itself, but **how it realizes that principle in Zig using intrusive composition, type erasure, Mailboxes, Pools, and Masters.**

I know the project from our previous discussions, and I think it actually reinforces the terminology we've been discussing.

`kissngoqueue` is not "just another queue." It's an example of the same architectural principle.

The queue itself doesn't own the application logic.

It simply moves objects.

That leads me to another thought.

## Maybe Item is too generic?

"Item" is good because it's implementation-independent.

But it has a drawback.

Outside Matryoshka, "item" could mean anything.

Inside Matryoshka, an Item has very specific properties:

* allocated
* movable
* participates in intrusive containers
* communicates between Masters
* may be pooled
* exclusive use (not shared)

Those are much stronger semantics than the English word "item."

However, I still think **Item** is the right architectural term because it keeps the README focused on the user's objects instead of the library's internals.

---

## The architecture becomes surprisingly simple

```text
Application
    creates Items

Master
    processes Items

Mailbox
    moves Items

Pool
    keeps reusable Items
```

Notice what's missing.

No `PolyNode`.

No `NodeHandle`.

No pointer.

No intrusive list.

Those belong in the implementation chapter.

---

One of the nice things about separating architecture from implementation is that you can say:

> A Mailbox is a communication mechanism.
>
> Its implementation may use `kissngoqueue`, another intrusive queue, or any equivalent data structure.

Likewise:

> A Pool is a resource management mechanism.
>
> Its implementation is independent of the architectural model.

That keeps Matryoshka from looking tied to a particular queue implementation.

---

## One thing I would still steal from `kissngoqueue`

Its philosophy.

`kissngoqueue` says (implicitly):

> Don't think about the queue.
>
> Think about the objects flowing through it.

I think Matryoshka should adopt exactly the same philosophy:

> **Don't think about PolyNode. Think about Items.**

Everything else exists to move Items efficiently and safely.

To me, that should become one of the project's defining ideas.

