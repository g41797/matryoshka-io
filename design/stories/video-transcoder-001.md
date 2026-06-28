# Story: Massive Scale Video Transcoder

A complete system design — from domain problem to Matryoshka implementation.

---

## Part 1 — Arch Design

Two architects design a high-throughput video streaming router.

**Boundaries:**
- Inputs: 10,000 external IP cameras sending live RTMP streams.
- Outputs: Encoded HLS video segments written to a storage cluster.
- Hardware: 64-core server.

**N (Network Architect)**: We have 10,000 incoming streams. If I push raw video frames into a single queue, your workers pull them concurrently. Frames from the same camera will be processed out of order.

**E (Encoding Architect)**: Video encoding requires strict sequential state. We cannot mix frames from the same stream across multiple workers simultaneously.

**N**: We cannot assign a dedicated thread per stream. We must multiplex 10,000 streams over 64 CPU cores.

**E**: Correct. We route the state, not the data. We create a `StreamContext` per camera. The context holds the encoder state. Workers receive the context — exclusive ownership, no locks needed during encoding.

**N**: For the frames themselves, continuous allocation causes memory fragmentation and allocator contention. We must reuse buffers.

**E**: I will provide a shared Memory Pool. When a worker finishes encoding a frame, it returns the buffer to the pool.

**N**: What happens if your workers fall behind and the pool runs empty? We need backpressure.

**E**: The empty pool is the backpressure signal. Network ingest waits for a buffer exactly the same way it waits for network data. One event loop, two sources. If the pool is empty, the ingest pauses. When a worker returns a buffer, the pool signals availability, and the ingest resumes.

**N**: Once a buffer is filled with a new frame, I attach it to the camera's `StreamContext` and push the context into the `ReadyQueue`.

**E**: A fixed pool of 64 workers loops on `ReadyQueue`. A worker that receives a `StreamContext` owns it entirely — no locks needed while encoding. When the internal queue is empty, the worker sends the `StreamContext` back and loops.

**N**: Clean multiplexing, lock-free encoding, and event-driven backpressure. I will draft the requirements and the diagram.

---

## Part 2 — SRS (Software Requirements)

1. **Decoupled Architecture**: Three independent stages — Network Ingest, Encoding Cluster, Storage I/O.
2. **Memory Reuse**: Video buffers come from a shared pool. No per-frame allocation.
3. **Event-Driven Backpressure**: Network Ingest waits for a free buffer as an async event — not a blocking poll, not a sleep loop.
4. **Stateful Stream Routing**: A `StreamContext` per camera carries encoder state. Frames for the same camera are processed sequentially.
5. **Lock-Free Concurrency**: A fixed worker pool multiplexes all streams. A worker gains exclusive ownership of a stream by receiving its `StreamContext`. No locks during encoding.
6. **Graceful Shutdown**: Network stops ingestion. Workers finish current contexts. All memory freed cleanly.

---

## Part 3 — Matryoshka Translation

Two senior programmers map the requirements to Matryoshka patterns.

**P1**: Requirement 2 (Memory Reuse) maps directly to a `Pool`. We define `VideoBuffer` as a PolyNode-based struct. The pool holds buffers. Workers return them after encoding.

**P2**: Requirement 3 (Event-Driven Backpressure) maps to `pool.getWaitResult` inside `Io.Select`. The Network Master has one event loop with two sources: buffer available from pool, and incoming network data. Whichever arrives first drives the next action. When the pool is empty, the event loop simply does not fire for that source. No sleep, no poll.

**P1**: Requirements 4 and 5 (Stateful Routing and Lock-Free Concurrency) are the core insight. `StreamContext` is a PolyNode-based struct carrying encoder state. The ready queue is a `Mailbox` holding `StreamContext` nodes — not raw frame data. Workers loop on `mailbox.receive(ready_queue)`. A worker that receives a context owns it exclusively.

**P2**: The slot rule applies everywhere. `defer pool.put(buf_ph, &sc.buffer_slot)` inside the worker returns the buffer automatically. When put succeeds, the slot clears and the pool fires — waking the Network Master.

**P1**: Requirement 6 (Graceful Shutdown). Network Master sends all frames, then closes the ready queue mailbox. Workers get `error.Closed` on the next receive and exit cleanly. Then we close the storage mailbox. The storage task exits. Then `pool.close` frees any remaining buffers via `on_close`.

**P2**: We built a large-scale actor model with zero custom locks and zero custom thread management. Matryoshka handles the lifecycle.

---

## Part 4 — Flow Diagram

```text
  [ Cameras (simulated) ]
        │
        ▼
  NETWORK MASTER (Io.Select)
  ├── pool.getWaitResult ──► VideoBuffer available? (backpressure signal)
  │   (blocks when all buffers in use)
  │
  │   on buffer available:
  │     fill buffer (camera_id, frame_id)
  │     attach to StreamContext
  │     send StreamContext to ready_queue
  │
  ▼
  [ ready_queue: Mailbox of StreamContext ]
        │
        ▼
  ENCODING WORKERS (Io.Group)
  ├── mailbox.receive(ready_queue) ──► StreamContext (exclusive ownership)
  │     encode frame (sequential, lock-free)
  │     pool.put buffer ──────────────────────────────────► [ buf_pool ]
  │     create EncodedSegment                                    │
  │     mailbox.send to storage_mbh                             pool fires
  │     destroy StreamContext                                     │
  │     loop back to receive                              Network Master wakes
  │
  ▼
  [ storage_mbh: Mailbox of EncodedSegment ]
        │
        ▼
  STORAGE TASK (io.concurrent)
  ├── mailbox.receive(storage_mbh) ──► EncodedSegment
  │     write to disk (simulated: log)
  │     free segment
  │     loop back to receive
  ▼
  [ File System (simulated) ]

  Shutdown sequence:
  Network closes ready_queue ──► workers get error.Closed ──► exit
  group.await ──────────────────────────────────────────────────────►
  close storage_mbh ──► storage task gets error.Closed ──► exit
  pool.close ──► on_close ──► free remaining buffers
```

---

## Part 5 — Implementation

See `stories/video_transcoder/video_transcoder.zig`.

Scale used in pilot: 3 cameras, 2 frames each, 2 video buffers (forces backpressure), 2 encoding workers.

Key patterns demonstrated:
- `pool.getWaitResult` in `Io.Select` — pool availability as async event.
- `StreamContext` as routed state machine — exclusive ownership via mailbox.
- `Io.Group` of workers — no shared state, no locks.
- Slot rule — `defer pool.put` and `defer StreamContextPolyHelper.destroy` as null-safe cleanup.
- Graceful shutdown — `mailbox.close` cascade.
