
Naming issue that comes from carrying Odin terminology into Zig.

Current:

```zig
pub const PolyNode = struct { ... };

pub const MayItem = ?*PolyNode;

pub const MailboxHandle = *PolyNode;
pub const PoolHandle = *PolyNode;
````

The problem is not the handles.

```zig
MailboxHandle = *PolyNode
PoolHandle    = *PolyNode
```

is actually quite good because it communicates:

* this is a handle
* internally it is transportable as a PolyNode
* API speaks in domain terms

The weak name is:

```zig
MayItem
```

because a Zig programmer immediately sees:

```zig
?*PolyNode
```

and thinks:

"optional pointer"

not

"ownership slot"

The concept is not "maybe item".

The concept is:

```text
A variable that may or may not currently own an Item.
```

That is a SLOT.

Visual model:

```text
Slot

+-------------------+
|                   |
|       ITEM        |
|                   |
+-------------------+

Slot = ?Item
```

or

```text
Empty Slot

+-------------------+
|                   |
|       null        |
|                   |
+-------------------+

Slot = null
```

send():

```text
Before

sender Slot
+-------------------+
|       ITEM        |
+-------------------+

mailbox.send(...)
```

After:

```text
sender Slot
+-------------------+
|       null        |
+-------------------+

Mailbox owns ITEM
```

receive():

```text
Mailbox owns ITEM
```

After:

```text
receiver Slot
+-------------------+
|       ITEM        |
+-------------------+
```

This maps perfectly to Zig:

```zig
pub const Item = *PolyNode;
pub const Slot = ?Item;
```

Then APIs become:

```zig
pub fn send(
    mbh: MailboxHandle,
    slot: *Slot,
) !void
```

```zig
pub fn receive(
    mbh: MailboxHandle,
    slot: *Slot,
    timeout_ns: ?u64,
) !void
```

which reads naturally:

```zig
var slot: Slot = item;

try mailbox.send(mbh, &slot);

// slot == null
```

and

```zig
var slot: Slot = null;

try mailbox.receive(mbh, &slot);

// slot contains item
```

For handles:

```zig
pub const Item = *PolyNode;
pub const Slot = ?Item;

pub const MailboxHandle = Item;
pub const PoolHandle = Item;
```

or explicitly:

```zig
pub const MailboxHandle = *PolyNode;
pub const PoolHandle = *PolyNode;
```

I would NOT introduce:

```zig
ItemHandle
```

because every item already is a handle:

```zig
Item == *PolyNode
```

and then you get:

```zig
ItemHandle
MailboxHandle
PoolHandle
```

which blurs the distinction between:

* generic item
* mailbox handle
* pool handle

My recommendation:

```zig
pub const Item = *PolyNode;
pub const Slot = ?Item;

pub const MailboxHandle = *PolyNode;
pub const PoolHandle = *PolyNode;
```

This gives the cleanest mental model:

```text
PolyNode
   │
   ▼

Item = *PolyNode

   │
   ▼

Slot = ?Item

   ├── empty  (null)
   └── owns Item

MailboxHandle = Item
PoolHandle    = Item
```

For documentation and diagrams, "Slot" is substantially clearer than "MayItem" because it describes ownership state rather than optionality syntax.
