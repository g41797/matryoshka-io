# API Reference — PolyNode, NodeHandle, Slot

New to the concepts? See [Building Blocks — PolyNode](../building-blocks/polynode.md) first.
This page covers the actual Zig types and functions.

Module: `@import("matryoshka").polynode`

```zig
const polynode = @import("matryoshka").polynode;

// typical usage:
var slot: polynode.Slot = &event.poly;   // slot holds the node
slot = null;                              // slot is empty
```

## Types

```zig
pub const PolyTag = struct { _: u8 = 0 };

pub const PolyNode = struct {
    node: std.DoublyLinkedList.Node,
    tag:  *const anyopaque,
};

pub const NodeHandle = *PolyNode;
pub const Slot = ?NodeHandle;
```

`PolyNode` is the type every application object embeds. `NodeHandle` is a pointer to
that embedded field — the only thing Matryoshka moves. `Slot` is where a handle lives
while it is yours.

## Functions

```zig
pub fn reset(n: *PolyNode) void
```
- Clears intrusive link pointers (`prev`, `next` to null).

```zig
pub fn is_linked(n: *PolyNode) bool
```
- Returns true if node is currently linked into a list.

### One place, one state — read-only ops

These operations never move a handle:
- tag checks
- typed casts
- `@fieldParentPtr` recovery

Read-only inspections of an existing node.

---

## Defining user types — manual step by step

Every PolyNode-based type needs four things:
- A struct with an embedded `poly: PolyNode` field.
- A unique tag address for runtime type identity.
- A way to check the tag before casting.
- A way to cast from `*PolyNode` back to `*YourType`.

This section builds each piece manually. Understanding this is the foundation
for everything in Matryoshka.

### Step 1 — Define the struct

Embed `poly: PolyNode`. This is the hook that lets Matryoshka see your type.

```zig
pub const Event = struct {
    poly: PolyNode,
    code: i32,
};
```

What the memory looks like:

```text
Event instance
+---------------------------+
| poly: PolyNode            |
|   +---------------------+ |
|   | node: List.Node     | |
|   |   prev: ?*List.Node | |
|   |   next: ?*List.Node | |
|   | tag: *const anyopaque| |
|   +---------------------+ |
| code: i32                 |
+---------------------------+
```

Why: Matryoshka never sees `Event`. It only sees `*PolyNode`.
The `poly` field is the bridge between your type and the infrastructure.

### Step 2 — Create a unique tag

A tag is just an address. Two different variables have two different addresses.
Same variable always has the same address.

```zig
var _event_tag: PolyTag = .{};
pub const EVENT_TAG: *const anyopaque = &_event_tag;
```

Why `var` not `const`: a mutable global has a guaranteed unique runtime address.
`const` may be deduplicated by the linker.

Why it's unique: each `var` declaration occupies its own memory location.
`&_event_tag` is that location's address. No two `var` declarations share an address.

```text
Memory layout (two types):

_event_tag:  [address 0x1000]  PolyTag
_sensor_tag: [address 0x1008]  PolyTag

EVENT_TAG  = 0x1000   (unique)
SENSOR_TAG = 0x1008   (unique, different from EVENT_TAG)
```

### Step 3 — Set the tag at construction

When you create an instance, store the tag in `poly.tag`.

```zig
var ev: Event = .{ .code = 42 };
ev.poly = .{ .node = .{}, .tag = EVENT_TAG };
```

What happened:

```text
Before                          After

Event                           Event
+------------------+            +------------------+
| poly: PolyNode   |            | poly: PolyNode   |
|   node: {null}   |            |   node: {null}   |
|   tag: undefined  |            |   tag: EVENT_TAG  |
| code: 42         |            | code: 42         |
+------------------+            +------------------+
```

Why: the tag is how you identify what type a `*PolyNode` points into.
Without it, you cannot safely cast.

### Step 4 — Get a pointer to the embedded PolyNode

This is how your type enters the Matryoshka world.

```zig
const poly: *PolyNode = &ev.poly;
```

Now Matryoshka can work with `poly`. It does not know about `Event`.

```text
ev: Event                        poly: *PolyNode
+------------------+                    |
| poly: PolyNode   | <-----------------+
|   node: {null}   |
|   tag: EVENT_TAG |
| code: 42         |
+------------------+
```

### Step 5 — Check the tag before casting

You have a `*PolyNode`. You need to know what it points into.
Compare the tag:

```zig
if (poly.tag == EVENT_TAG) {
    // safe to cast to *Event
}
```

Why check first: `@fieldParentPtr` does not validate anything.
If you cast a Sensor's PolyNode to `*Event`, you get garbage.
The tag check is the only runtime safety you have.

```text
poly.tag == EVENT_TAG ?

  YES → this PolyNode is inside an Event → safe to cast
  NO  → this PolyNode is inside something else → do not cast
```

### Step 6 — Cast back to the outer type

`@fieldParentPtr` recovers the containing struct from a pointer to its field.

```zig
const recovered: *Event = @fieldParentPtr("poly", poly);
```

What `@fieldParentPtr` does:

```text
poly: *PolyNode
      |
      v
+------------------+
| poly: PolyNode   |  <-- poly points here
|   ...            |
| code: 42         |
+------------------+
^
|
recovered: *Event      <-- @fieldParentPtr subtracts the field offset
```

The field name `"poly"` is validated at compile time.
The offset calculation is done at compile time.
Runtime cost: one pointer subtraction.

### Step 7 — Two-level recovery (from list node)

Inside a mailbox or pool, items are linked via `std.DoublyLinkedList`.
The list operates on `*DoublyLinkedList.Node`, not `*PolyNode`.

Recovery is two steps:

```zig
// Step 1: List.Node → PolyNode (done inside mailbox/pool)
const poly: *PolyNode = @fieldParentPtr("node", list_node_ptr);

// Step 2: PolyNode → user type (done in user code, after tag check)
const ev: *Event = @fieldParentPtr("poly", poly);
```

```text
list_node_ptr: *List.Node
      |
      v
+---------------------------+
| poly: PolyNode            |
|   +---------------------+ |
|   | node: List.Node     | | <-- list_node_ptr points here
|   |   prev, next        | |
|   | tag: EVENT_TAG       | |
|   +---------------------+ |
| code: 42                 |
+---------------------------+
^           ^
|           |
|           poly: *PolyNode    (Step 1: @fieldParentPtr("node", dll_node_ptr))
|
ev: *Event                     (Step 2: @fieldParentPtr("poly", poly))
```

### Complete manual example

All steps together:

```zig
// Define type
pub const Event = struct {
    poly: PolyNode,
    code: i32,
};

// Create unique tag
var _event_tag: PolyTag = .{};
pub const EVENT_TAG: *const anyopaque = &_event_tag;

// Create and initialize
var ev: Event = .{ .code = 42 };
ev.poly = .{ .node = .{}, .tag = EVENT_TAG };

// Get PolyNode pointer
const poly: *PolyNode = &ev.poly;

// Check tag
if (poly.tag == EVENT_TAG) {
    // Cast back
    const recovered: *Event = @fieldParentPtr("poly", poly);
    // recovered.code == 42
}
```

This works. But every type needs the same boilerplate:
- A `var _xxx_tag` declaration.
- A `const XXX_TAG` pointer.
- A tag check before every cast.
- An init that sets the tag.

---

## PolyHelper — all of the above, generated

`PolyHelper` generates the tag, check, identification functions, and init for any PolyNode type.
One call replaces all the manual boilerplate.

```zig
pub fn PolyHelper(comptime T: type) type
```

- `T` must have a field `poly: PolyNode`. Compile error otherwise.
- Returns a namespace with four members.

### What PolyHelper generates

```zig
pub const TAG: *const anyopaque
```
- Unique runtime address for type `T`.
- Same as the manual `var _tag: PolyTag = .{}; const TAG = &_tag;` pattern.

```zig
pub fn isIt(tag: *const anyopaque) bool
```
- Returns `tag == TAG`.
- Same as the manual `poly.tag == EVENT_TAG` check.

```zig
pub fn identifyNodeAs(node: *PolyNode) ?*T
```
- Returns `null` if the runtime tag does not match.
- Returns `@fieldParentPtr("poly", node)` if it does.
- For infrastructure code that works with `*PolyNode` directly (mailbox, pool, list walks).

```zig
pub fn mustIdentifyNodeAs(node: *PolyNode) *T
```
- Same as `identifyNodeAs`, but panics (`orelse unreachable`) if the tag does not match.

```zig
pub fn identifySlotAs(slot: *const Slot) ?*T
```
- Returns `null` if the Slot is empty or the tag does not match.
- For application code that works with Slots (examples, tests, stories).

```zig
pub fn mustIdentifySlotAs(slot: *const Slot) *T
```
- Same as `identifySlotAs`, but panics if the Slot is empty or the tag does not match.

```zig
pub fn init(self: *T) void
```
- Sets `self.poly = .{ .node = .{}, .tag = TAG }`.
- Same as the manual init in Step 3.

### Usage

```zig
pub const Event = struct {
    poly: PolyNode,
    code: i32,
};

pub const EventPolyHelper = polynode.PolyHelper(Event);
```

Naming convention: `XxxPolyHelper = polynode.PolyHelper(Xxx)`.

### The same example, now with PolyHelper

```zig
// Create and initialize (Step 3 is now one call)
var ev: Event = .{ .code = 42 };
EventPolyHelper.init(&ev);

// Get PolyNode pointer (same as before)
const poly: *PolyNode = &ev.poly;

// Identify and recover (Steps 5+6 combined, returns null on wrong tag)
const recovered: *Event = EventPolyHelper.mustIdentifyNodeAs(poly);
// recovered.code == 42
```

```text
Manual                              With PolyHelper

var _event_tag: PolyTag = .{};      (generated inside PolyHelper)
const EVENT_TAG = &_event_tag;      EventPolyHelper.TAG

poly.tag == EVENT_TAG               EventPolyHelper.isIt(poly.tag)

if (poly.tag == EVENT_TAG)          EventPolyHelper.identifyNodeAs(poly)
  @fieldParentPtr("poly", poly)       → ?*Event (null if wrong tag)

// slot: ?*PolyNode                 EventPolyHelper.identifySlotAs(&slot)
                                       → ?*Event (null if slot empty or wrong tag)

ev.poly = .{.node=.{},.tag=TAG};    EventPolyHelper.init(&ev)
```

Same operations. Same runtime cost. Less boilerplate. Compile-time validation.

See `helpers/types.zig` for the pattern.

## PolyHelper — create and destroy

These two functions exist only when `T` does not declare `no_create_destroy`.
They collapse the three-step alloc+init+slot pattern into one call.

```zig
pub fn create(allocator: std.mem.Allocator, slot: *Slot) !void
```
- Asserts `slot.* == null`.
- Allocates `T`.
- Zero-initializes.
- Calls `init`.
- Sets `slot.*` to point to the new node.

```zig
pub fn destroy(allocator: std.mem.Allocator, slot: *Slot) void
```
- If `slot.* == null`: returns immediately (no-op).
- Asserts node is not linked.
- Sets `slot.*` to null before freeing — prevents use-after-free.
- Frees the memory.

### Old pattern vs new

```text
Old (manual):                        New (PolyHelper.create):

  const ev = try alloc.create(T);     try EventPolyHelper.create(alloc, &slot);
  ev.* = .{};
  EventPolyHelper.init(ev);
  slot.* = &ev.poly;
```

```text
Old (manual):                        New (PolyHelper.destroy):

  alloc.destroy(                       EventPolyHelper.destroy(alloc, &slot);
    EventPolyHelper.mustIdentifySlotAs(&slot));  // null-safe, clears slot
  slot.* = null;
```

### comptime selection — no_create_destroy

Some types must not expose `create`/`destroy`.

```zig
const no_create_destroy = void{};
```

If `T` declares this field, `PolyHelper(T)` generates only: `TAG`, `isIt`, `identifyNodeAs`, `mustIdentifyNodeAs`, `identifySlotAs`, `mustIdentifySlotAs`, `init`.

Infrastructure types (`_Mailbox`, `_Pool`) declare `no_create_destroy`.
They manage their own lifecycle.
Generating `create`/`destroy` for them would be wrong.

```text
PolyHelper(T)
  │
  ├── @hasDecl(T, "no_create_destroy") == false
  │     → TAG, isIt, identifyNodeAs, mustIdentifyNodeAs, identifySlotAs, mustIdentifySlotAs, init, create, destroy
  │
  └── @hasDecl(T, "no_create_destroy") == true
        → TAG, isIt, identifyNodeAs, mustIdentifyNodeAs, identifySlotAs, mustIdentifySlotAs, init
```

## stdlib compatibility

PolyNode embeds `std.DoublyLinkedList.Node`.
- No custom list type.
- No adapter.
- Every PolyNode-based item participates in standard `std.DoublyLinkedList` operations.

Batch operations use plain `std.DoublyLinkedList`:
- `mailbox.close()`
- `mailbox.receive_batch()`
- `pool.put_all()`

Walk results with `popFirst()` — standard Zig, nothing Matryoshka-specific.

**Warning**:
- `std.DoublyLinkedList.popFirst()` does NOT clear the node's `prev`/`next` links.
- Call `polynode.reset(poly)` after popping, before re-sending the item or checking `polynode.is_linked`.
- Skipping reset causes false positives from `is_linked` and assert failures in pool/mailbox assert guards.

---

Next: [API Reference — Mailbox](mailbox.md).
