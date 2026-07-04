# Matryoshka Based Systems

Most libraries document features.

Matryoshka documents architectures.

Read this page and think: "that's how my server looks." Not: "that's how their queue works."

---

## Three small building blocks

- `PolyNode` — embedded in application objects. Gives them a place in intrusive lists and queues. Gives them safe run-time type identification.
- `Mailbox` — moves `PolyNode` objects between Masters. Transfers ownership with the object.
- `Pool` — reuses `PolyNode` objects. Returns them for reuse instead of destroying them.

Together they provide two capabilities: move objects, reuse objects. Nothing else.

## One architectural concept: Master

Master is a role, not a type, not an interface, not a runtime.

Every running entity in a Matryoshka-based system is a Master.

- A Master owns state and communicates through Mailboxes.
- A worker is a Master with one dedicated responsibility.
- Some Masters also coordinate other Masters.
- Some Masters also own shared Pools.

Additional responsibilities — coordinating, owning Pools, creating and destroying Masters, routing messages, talking to the outside world — are optional, layered on top of the same role.

## What a Matryoshka-based system looks like

A system built from Masters:

- owns state inside each Master;
- communicates through Mailboxes;
- shares reusable objects through Pools.

Matryoshka does not dictate how you compose them. Start with `PolyNode`. Add `Pool` when reuse becomes useful. Add `Mailbox` when you need message passing. The Master concept comes naturally as the system grows.

## Where Zig Io fits

Matryoshka uses Zig Io in two situations: where Zig requires it, and where it adds real capability — waiting on multiple event sources, timers, cancellation, integration with other Io-based libraries.

The architecture does not depend on Zig Io's shape. If Zig Io changes, your Masters, Mailboxes, and Pools stay the same.

## Next

- Concepts — page planned for a later stage.
- Building blocks — page planned for a later stage.
- Cookbook — page planned for a later stage.
