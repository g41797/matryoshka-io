# Matryoshka Based Systems

Most libraries document features.

Matryoshka documents architectures.

Read this page and think: "that's how my server looks." Not: "that's how their queue works."

---

## Three small building blocks

- `PolyNode` — embedded in application items. Gives them a place in intrusive lists and queues. Gives them safe run-time type identification.
- `Mailbox` — moves `PolyNode` items between Masters. Transfers the object, not a reference to it.
- `Pool` — reuses `PolyNode` items. Returns them for reuse instead of destroying them.

Together they provide two capabilities: move items, reuse items. Nothing else.

## One architectural concept: Master

Io creates every task through `io.concurrent()`.

A Master is an Io task that follows the Matryoshka rules. Not a type, not an interface, not a runtime.

- A Master owns state and communicates through Mailboxes.
- A worker is a Master with one dedicated responsibility.
- Some Masters also coordinate other Masters.
- Some Masters also own shared Pools.

Additional responsibilities — coordinating, owning Pools, creating and destroying Masters, routing messages, talking to the outside world — are optional, layered on top of the same task.

## What a Matryoshka-based system looks like

A system built from Masters:

- owns state inside each Master;
- communicates through Mailboxes;
- shares reusable items through Pools.

Matryoshka does not dictate how you compose them. Start with `PolyNode`. Add `Pool` when reuse becomes useful. Add `Mailbox` when you need message passing. The Master concept comes naturally as the system grows.

## Where Zig Io fits

Matryoshka lives inside the Io task world. Not beside it.

- Io answers: how do tasks run?
- Matryoshka answers: how do tasks cooperate?

Io still does the rest: waiting on multiple event sources, timers, cancellation, integration with other Io-based libraries.

If Zig Io changes, Matryoshka's rules stay the same.

## Next

- Concepts — page planned for a later stage.
- Building blocks — page planned for a later stage.
- Cookbook — page planned for a later stage.
