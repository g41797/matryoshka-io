
# Cast improvements

I think your intuition is correct. Almost every call site probably looks like:

```zig
const event = EventPolyHelper.cast(slot.?) orelse return;
```

or

```zig
const event = EventPolyHelper.cast(slot.?).?;
```

which exposes the implementation detail that a `Slot` is `?*PolyNode`.

The abstraction is leaking.

## Option 1 — overload for Slot (my preferred)

Keep the existing API and add another overload-like function (with a different name because Zig has no overloads):

```zig
pub inline fn castSlot(slot: *const Slot) ?*T {
    const poly = slot.* orelse return null;
    return cast(poly);
}
```

Usage:

```zig
if (EventPolyHelper.castSlot(&slot)) |event| {
    ...
}
```

or

```zig
const event = EventPolyHelper.castSlot(&slot).?;
```

Advantages

* hides `slot.?`
* keeps `cast()` useful for linked lists and raw PolyNodes
* minimal API change
* very explicit

I like this solution.

---

## Option 2 — make Slot the primary API

```zig
pub inline fn cast(slot: *const Slot) ?*T
```

and rename the current one

```zig
castNode(node: *PolyNode)
```

Usage becomes

```zig
const event = EventPolyHelper.cast(&slot).?;
```

This is even nicer for application code.

The downside is that many places inside mailbox/pool implementations naturally have `*PolyNode`, not `Slot`.

So you'd end up calling

```zig
castNode(...)
```

inside infrastructure.

That isn't terrible.

---

## Option 3 — support both

```zig
castNode(node: *PolyNode)

castSlot(slot: *const Slot)
```

This is probably the cleanest public API.

Application code almost never touches `PolyNode`.

Infrastructure almost never touches `Slot`.

Each layer gets its natural API.

---

## I would also add mustCastSlot()

If you have

```zig
mustCast()
```

then symmetry suggests

```zig
mustCastSlot(slot: *const Slot) *T {
    return castSlot(slot) orelse unreachable;
}
```

Then most code becomes

```zig
const ev = EventPolyHelper.mustCastSlot(&slot);
```

instead of

```zig
const ev = EventPolyHelper.cast(slot.?).?;
```

Much nicer.

---

## One thing I would *not* do

I would not change

```zig
Slot = ?*PolyNode
```

into a wrapper struct just to get methods.

The alias is simple and efficient.

Instead, let `PolyHelper` expose Slot-oriented helpers.

---

### My recommendation

I'd expose four functions:

```zig
castNode(node: *PolyNode) ?*T
mustCastNode(node: *PolyNode) *T

castSlot(slot: *const Slot) ?*T
mustCastSlot(slot: *const Slot) *T
```

Then:

* **Infrastructure code** (mailbox, pool, intrusive lists) naturally uses `castNode()`.
* **Application code** almost exclusively uses `castSlot()`.

That better matches the abstraction: application code owns `Slot`s, while the infrastructure owns `PolyNode`s.
