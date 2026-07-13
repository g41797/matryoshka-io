### 1. README (canonical)

This is where the full text belongs.

Someone who opens the repository wants to understand:

* what Matryoshka is
* why it exists
* how to think about it

Your current text is almost exactly the right length.

---

### 2. Documentation site

I'd make it even shorter.

The first page should answer only three questions:

* What is Matryoshka?
* Should I keep reading?
* Where do I start?

Everything else should be links.

People don't arrive at documentation to read a manifesto. They arrive to solve a problem.

---

### 3. Ziggit Showcase

Completely different audience.

Don't explain.

Show.

The first post should be something like:

> I wasn't trying to build another framework.
>
> I was trying to make large Zig Io systems easier to reason about.
>
> Matryoshka is the result.

Then immediately show a small diagram or a simple flow:

```text
Master
   │
Mailbox
   │
Master
```

or

```text
Pool → Master → Mailbox → Master → Pool
```

Engineers trust examples much more than philosophy.

---

### About AI

I think your instinct is right.

Don't mention AI.

Don't mention that it was edited.

Don't mention "LLM assisted."

The Zig community generally reacts well to:

* original thinking
* working code
* honest limitations

They react poorly to polished, generic prose.

Ironically, the best way to avoid sounding AI-generated is exactly what you've been doing for months:

* short sentences
* imperfect but honest English
* admitting limitations
* saying "today this only works with Threaded Io"
* saying "this is an attempt"

That doesn't read like AI.

It reads like an engineer.

---

One thing I would preserve everywhere is your sentence:

> **Start from a whiteboard. Not from code. Not from a prompt.**

That's yours.

It's memorable.

It's not marketing.

It's a philosophy.

If people remember one sentence about Matryoshka a year from now, I think it should be that one.
