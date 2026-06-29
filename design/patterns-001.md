# Matryoshka Zig — Pattern Catalog (001)

Reusable idioms confirmed in the examples and the API reference.
Companion: [rules-001.md](rules-001.md) — what is mandatory.
Companion: [matryoshka-model-001.md](matryoshka-model-001.md) — the thinking model.

How this doc differs from rules.
- Rules constrain. A rule says what you must or must not do.
- Patterns reuse. A pattern is a code shape that solves a recurring problem.
- A pattern is a suggestion grounded in working code, not a constraint.

How to use it.
- Find the topic. Read the "when to use" line.
- Copy the code shape. Adapt names to your domain.
- Open the referenced example for the full working version.

Each pattern lists: name, when to use, code shape, example reference.
Every example path is under `examples/` or `stories/`.

---

## Pool patterns

### Pool mode — .available_or_new

When to use.
- The common case: reuse a stored item if one is free, otherwise create a fresh one.

Code shape.
```zig
var slot: Slot = null;
defer pool.put(ph, &slot);
try pool.get(ph, EventPolyHelper.TAG, .available_or_new, &slot);
```

- `on_get` runs every call. If `slot.*` is non-null it was recycled — reinitialize. If null, create.

Example: `examples/layer4/master_with_pool.zig`.

### Pool mode — .new_only

When to use.
- Seeding. You want a fresh item every time, never a stored one.

Code shape.
```zig
var slot: Slot = null;
try pool.get(ph, EventPolyHelper.TAG, .new_only, &slot);
// fill the new item
pool.put(ph, &slot);
```

Example: `examples/layer3/pool_seeding.zig`.

### Pool mode — .available_only

When to use.
- Consume what is stored. Stop when the pool is empty.
- Empty pool returns `error.NotAvailable` — a normal end condition, not a failure.

Code shape.
```zig
var slot: Slot = null;
pool.get(ph, EventPolyHelper.TAG, .available_only, &slot) catch |err| switch (err) {
    error.NotAvailable => break,
    else => return err,
};
```

Example: `examples/layer3/pool_seeding.zig`.

### Seeding pattern

When to use.
- A fixed-size pool. Pool capacity is set once at startup, no on-demand creation.

Code shape.
```zig
for (0..N_BUFFERS) |_| {
    var slot: Slot = null;
    try VideoBufferPolyHelper.create(allocator, &slot);
    pool.put(ph, &slot);
}
```

- Pair with `on_get` that does nothing — the pool never grows past the seed count.
- The fixed count becomes the backpressure limit.

Example: `stories/video_transcoder/video_transcoder.zig`.

### Backpressure via getWaitResult in Select

When to use.
- A producer must slow down when no buffers are free.
- Pool availability becomes an event source in the same loop as data.

Code shape.
```zig
try sel.concurrent(.buf_ev, pool.getWaitResult, .{ buf_ph, VideoBufferPolyHelper.TAG, null });
// ...
const ev = try sel.await();
switch (ev) {
    .buf_ev => |r| switch (r) {
        .item => |handle| {
            // fill buffer, route it, then re-register for the next free buffer
            try sel.concurrent(.buf_ev, pool.getWaitResult, .{ buf_ph, VideoBufferPolyHelper.TAG, null });
        },
        .closed, .canceled, .timeout, .not_created => break,
    },
}
```

- The loop blocks until a worker returns a buffer.
- No sleep. No poll. The pool wakes the waiter.

Example: `stories/video_transcoder/video_transcoder.zig`.

### on_get and on_put hooks

When to use.
- `on_get`: decide how an item is created or reinitialized.
- `on_put`: decide whether a returned item is kept or destroyed (cap policy).

Code shape.
```zig
fn onGet(_: *anyopaque, _: *const anyopaque, _: usize, _: *Slot) void {}        // fixed-size: never create
fn onPut(_: *anyopaque, _: usize, _: *Slot) void {}                              // keep all
```

- `on_put`: set `slot.* = null` to destroy; leave non-null to keep.
- Hooks run outside the pool lock. Multiple threads may call them at once. Protect shared state with `Io.Mutex.lockUncancelable`.

Example: `examples/layer3/capped_pool.zig` (cap policy), `helpers/helpers.zig` `CappedPoolCtx` (thread-safe reference).

### on_close hook

When to use.
- Free all stored items when the pool shuts down.

Code shape.
```zig
fn onClose(ctx: *anyopaque, list: *std.DoublyLinkedList) void {
    const self: *VideoBufCtx = @ptrCast(@alignCast(ctx));
    while (list.popFirst()) |node| {
        const poly: *polynode.PolyNode = @fieldParentPtr("node", node);
        polynode.reset(poly);
        var s: Slot = poly;
        VideoBufferPolyHelper.destroy(self.alloc, &s);
    }
}
```

- Always call `polynode.reset(poly)` after `popFirst` before destroy.

Example: `examples/layer3/pool_teardown.zig`, `stories/video_transcoder/video_transcoder.zig`.

---

## Io.Select patterns

### Event loop — register, await, re-register

When to use.
- Wait on several sources at once: mailbox, pool, timer, external push.

Code shape.
```zig
var buf: [8]MasterEvent = undefined;
var sel: std.Io.Select(MasterEvent) = std.Io.Select(MasterEvent).init(io, &buf);

try sel.concurrent(.inbox, mailbox.receiveResult, .{ mbh, null });
try sel.concurrent(.pool_ev, pool.getWaitResult, .{ ph, TAG, null });
try sel.concurrent(.timer, sleepFn, .{ sleep_t, io });

while (true) {
    const event: MasterEvent = try sel.await();
    switch (event) {
        .inbox => |r| switch (r) {
            .item => |handle| {
                // process, then re-register the source
                try sel.concurrent(.inbox, mailbox.receiveResult, .{ mbh, null });
            },
            .closed, .canceled, .timeout => break,
        },
        // ...
    }
}
```

- Re-register the source after each item. A source delivers one result per `concurrent` call.

Example: `examples/layer4/select_graceful_shutdown.zig`, `examples/layer4/select_mixed_sources.zig`.

### Direct push — putOneUncancelable

When to use.
- A result is already available, or an external thread or callback must inject one without spawning.

Code shape.
```zig
select.queue.putOneUncancelable(select.io, .{ .field = value }) catch {};
```

Example: `examples/layer4/select_direct_push.zig`.

### Graceful cancel walk — recover in-flight items

When to use.
- Shutting down a Select loop. Spawned sources may still hold items. None must leak.

Code shape.
```zig
while (sel.cancel()) |event| {
    switch (event) {
        .inbox => |r| switch (r) {
            .item => |handle| {
                var slot: Slot = handle;
                helpers.freeSlot(&slot, allocator);   // recover the item
            },
            .canceled, .closed, .timeout => {},
        },
        .pool_ev => |r| switch (r) {
            .item => |handle| {
                var slot: Slot = handle;
                pool.put(ph, &slot);                   // recycle it
            },
            .canceled, .closed, .timeout, .not_created => {},
        },
        .timer => {},
    }
}
```

Example: `examples/layer4/select_graceful_shutdown.zig`.

### cancelDiscard — timer-only or no-item sources

When to use.
- The remaining spawned sources carry no owned item (e.g. a timer). Discard them.

Code shape.
```zig
sel.cancelDiscard();
```

Example: `stories/video_transcoder/video_transcoder.zig`.

---

## Io.Group patterns

### Worker set — concurrent then await

When to use.
- Run several workers. Wait for all to finish.

Code shape.
```zig
var group: Io.Group = .init;
try group.concurrent(io, workerFn, .{&ctx0});
try group.concurrent(io, workerFn, .{&ctx1});
try group.await(io);
```

- Worker return type must coerce to `Cancelable!void`.

Example: `stories/video_transcoder/video_transcoder.zig`.

### Shutdown signal — close the source mailbox

When to use.
- Stop a Group of workers that block on `mailbox.receive`.

Code shape.
```zig
// workers exit when receive returns error.Closed
var rem: std.DoublyLinkedList = mailbox.close(ready_queue);
// walk rem, recover any unreceived items
try group.await(io);
```

- Close is the end-of-stream signal. Workers return on `error.Closed`.

Example: `stories/video_transcoder/video_transcoder.zig`.

### Shutdown signal — group.cancel

When to use.
- Stop a Group of workers that block on `pool.get_wait`, with no mailbox to close.

Code shape.
```zig
group.cancel(io);   // injects error.Canceled into all blocked workers, then waits
```

- Blocked workers return `error.Canceled`. A worker that already finished is unaffected.

Example: `examples/layer4/mailbox_less_pool_group_workers.zig`.

---

## Graceful shutdown sequence

When to use.
- Tearing down a Master that owns workers, mailboxes, and a pool.

Mandatory order.
1. Stop the producer loop (the Select Master). Stop registering new work.
2. Close the mailbox that feeds the workers. This signals end-of-stream.
3. Walk the mailbox close list. Recover or recycle every item it returns.
4. `group.await(io)` — wait for all workers to finish their current item.
5. Destroy the worker mailbox.
6. Close any downstream mailbox (e.g. storage). Its task exits on `error.Closed`.
7. Await the downstream task. Destroy its mailbox.
8. `pool.close` — `on_close` frees all stored items.
9. `pool.destroy`.

Why this order.
- Close upstream before awaiting workers, or workers block forever.
- Await workers before closing the pool, or a worker returns an item to a closed pool.
- A pool returns the item to the caller when closed — the worker must free it as a fallback.

Code shape (worker fallback for closed pool).
```zig
pool.put(ctx.buf_ph, &sc.buffer_slot);
if (sc.buffer_slot != null) {
    VideoBufferPolyHelper.destroy(ctx.alloc, &sc.buffer_slot);
}
```

Example: `stories/video_transcoder/video_transcoder.zig`, `examples/layer4/cross_layer_close_mailbox_then_pool.zig`.

---

## Polymorphic dispatch

When to use.
- One mailbox or one list carries more than one item type. The receiver recovers the concrete type.

Code shape.
```zig
if (EventPolyHelper.cast(handle)) |ev| {
    // handle Event
} else if (ShutdownCommandPolyHelper.cast(handle)) |_| {
    // handle ShutdownCommand
} else {
    // unknown — free and move on
}
```

- `cast` returns null on a tag mismatch. Chain casts for each known type.
- Tag identifies class, not instance. Use a `kind`/`role` field or pointer comparison for instance identity.

Example: `examples/layer4/select_graceful_shutdown.zig`, `examples/layer4/cross_layer_mixed_types_mailbox.zig`.

---

## Error handling on receive

When to use.
- A worker blocks on `mailbox.receive` or `pool.get_wait` and must react to each outcome.

Code shape.
```zig
mailbox.receive(ctx.mbh, &slot, null) catch |err| switch (err) {
    error.Canceled => return error.Canceled,   // report up — Master decides
    error.Closed, error.Timeout => return,      // end-of-stream — exit cleanly
};
```

The distinction.
- `error.Canceled` — external stop signal. Propagate it. Do not close anything.
- `error.Closed` — the Master closed the source. End of stream. Exit.
- `error.Timeout` — the wait window passed. Treat per domain.
- Never remap `error.Canceled` to `error.Closed`. They mean different things.

Example: `stories/video_transcoder/video_transcoder.zig`, `examples/layer4/mailbox_less_pool_group_workers.zig`.

---

## Master composition

When to use.
- A story or service has more than one coordination boundary.

The shape.
- Each Master owns its resources and coordinates their lifecycle.
- A Master is a state struct plus a loop function — not inlined into `run`.
- `run` is thin: initialize resources, start Masters, await shutdown in order.

Two Masters in the pilot story.
- Network Master — an `Io.Select` loop. Owns the buffer pool as a backpressure source. Fills buffers, routes `StreamContext` to the ready queue.
- Worker set — an `Io.Group`. Each worker receives a `StreamContext`, encodes, returns the buffer to the pool, sends an `EncodedSegment` to storage.
- Storage task — a single-mailbox loop. Receives `EncodedSegment`, logs, frees.

Code shape (thin run).
```zig
pub fn run(allocator: std.mem.Allocator, io: std.Io) !void {
    // 1. initialize shared resources: pool, mailboxes
    // 2. start Masters: storage task, worker group, network loop
    // 3. await shutdown in mandatory order
}
```

- The coordination logic of each Master lives in its own function.
- `run` shows the startup order and the shutdown order — nothing else.

Example: `stories/video_transcoder/video_transcoder.zig`.
