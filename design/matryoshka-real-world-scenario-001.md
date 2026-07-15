# Real-World Scenario: Massive Scale Video Transcoder

This document shows how a complex, large-scale system is designed. First, the architects define the domain flow and formalize the software requirements. Then, the programmers translate those requirements into Matryoshka patterns.

## Part 1: The Architects

Two architects are designing a high-throughput video streaming router.   
The system has strict boundaries:
- **Inputs**: 10,000 external IP cameras sending live RTMP streams.
- **Outputs**: Encoded HLS video segments written to a storage cluster.

They have a 64-core server. They divide the problem into three decoupled stages:
- **Network Architect (N)**: Handles incoming sockets.
- **Encoding Architect (E)**: Handles video decoding.
- **Storage Architect (S)**: Handles disk I/O. (Not present, but their boundary is defined).

**N**: We have 10,000 incoming streams. If I push raw video frames into a single queue, your workers will pull them concurrently. Frames from the same camera will be processed out of order.

**E**: Video encoding requires strict sequential state. We cannot mix frames from the same stream across multiple workers simultaneously.

**N**: We have to multiplex 10,000 streams over 64 CPU cores. We cannot assign a dedicated thread per stream.

**E**: Correct. We route the state, not the data. We create a `StreamContext` for each camera. The context holds the encoder state and its own internal queue of pending frames.

**N**: For the frames themselves, continuous allocation will cause severe memory fragmentation and allocator contention. We must reuse buffers.

**E**: I will provide a shared Memory Recycler. When my worker finishes encoding a frame, it returns the buffer to the recycler. 

**N**: What happens if your workers fall behind and the recycler runs empty? We need strict backpressure.

**E**: The empty recycler is your backpressure signal. The implementation must treat memory availability as an asynchronous event. 

**N**: So the network ingest will listen for empty buffers exactly like it listens for network data. If the recycler is empty, the ingest naturally pauses reading from the cameras. 

**E**: Exactly. When my worker returns a buffer, the event fires, your ingest resumes, and you fill the buffer.

**N**: Once the buffer is filled with a new frame, I lock the `StreamContext` for that camera and append the frame to its internal queue.

**E**: And if that `StreamContext` was idle, you push the entire `StreamContext` into a `ReadyQueue`. 

**N**: I see. The 64 workers pull from the `ReadyQueue`. A worker gets the `StreamContext`, which gives it exclusive ownership of that stream. No locks needed during encoding.

**E**: Exactly. The worker processes the internal queue sequentially, updates the encoder state, and sends the finished segments to the Storage Master. When the internal queue is empty, the worker marks the context as idle and goes back to wait on the `ReadyQueue`.

**N**: Clean multiplexing, lock-free encoding, and event-driven backpressure. I will draft the software requirements and the diagram.

---

## Part 2: Software Requirements

Based on the discussion, the architects formalize the following requirements:
1. **Decoupled Architecture**: The system must be divided into three independent stages: Network Ingest, Encoding Cluster, and Storage I/O.
2. **Memory Recycling**: The system must reuse video buffers from a shared free-list to prevent memory fragmentation and allocator contention.
3. **Event-Driven Backpressure**: Network Ingest must treat the availability of empty memory buffers as an asynchronous event, pausing socket reads when no buffers are available.
4. **Stateful Stream Routing**: Video frames must be routed inside a `StreamContext` object to ensure frames from the same stream are processed strictly sequentially.
5. **Lock-Free Concurrency**: A fixed pool of exactly 64 workers must multiplex the 10,000 streams. A worker gains exclusive, lock-free ownership of a `StreamContext` by pulling it from a shared ready queue.
6. **Graceful Shutdown**: The system must support a clean flush where network ingestion stops, workers finish their current contexts, and all memory is freed cleanly.

---

## Part 3: The Domain Flow

```text
  [ External Cameras ]
        │ (10,000 RTMP Streams)
        ▼
   NETWORK INGEST
        │ (Waits on Memory Recycler event for empty buffers)
        ▼
   [ Stream Context A ] ────┐
   [ Stream Context B ] ──┐ │
   [ Stream Context C ]   │ │ (If stream becomes active)
        │                 │ │
        ▼                 ▼ ▼
  (Pending Buffers)    [ Ready Queue ]
                             │
                             ▼
   ENCODING CLUSTER (Fixed 64 Workers)
   1. Worker pops active Stream Context
   2. Worker processes pending buffers sequentially (Maintains state)
   3. Worker returns empty buffers to Memory Recycler
   4. Worker passes encoded segments to Storage Queue
                             │
                             ▼
                      [ Storage Queue ]
                             │
                             ▼
   STORAGE MASTER (Disk I/O)
        │
        ▼
   [ HLS Storage ]
```

---

## Part 4: The Programmers Translate to Matryoshka

Two senior Zig programmers look at the Software Requirements. They map the complex domain requirements directly to Matryoshka patterns.

**Programmer 1 (P1)**: Let's look at Requirement 2. The "Memory Recycler" maps directly to a Matryoshka `Pool`. We define a `VideoBuffer` struct and hook it to the pool.

**Programmer 2 (P2)**: For Requirement 3 (Event-Driven Backpressure), we use `select.concurrent(.buffer, pool.getWaitResult, ...)` inside the Network Master's `Io.Select` loop. It waits for an empty buffer exactly like it waits for a socket.

**P1**: Requirements 4 and 5 (Stateful Stream Routing and Lock-Free Concurrency) are the core. We define the `StreamContext` as a custom struct containing a `PolyNode`. The shared ready queue is a Matryoshka `Mailbox` that holds these context nodes, not raw data.

**P2**: That's huge. Matryoshka routes full state machines perfectly. And the 64 workers? They are an `Io.Group`. They loop on `mailbox.receive(ready_queue)`. When a worker receives a context, it owns it entirely.

**P1**: What happens to the empty `VideoBuffer` when the worker finishes encoding it?

**P2**: Standard slot rule. `defer pool.put(pool_handle, &buffer_slot)`. It drops right back into the shared free-list, which instantly fires the pool event and wakes up the Network Master.

**P1**: And the `Storage Queue`?

**P2**: Another `Mailbox`. The Storage Master runs its own `Io.Select` loop, reading from the storage mailbox and writing to disk. That fulfills Requirement 1 (Decoupled Architecture).

**P1**: Finally, Requirement 6 (Graceful Shutdown). The Network Master stops accepting streams and closes the `ReadyQueue` mailbox. The 64 workers wake up with `error.Closed`, finish whatever contexts they hold, and exit cleanly. Then the Master calls `pool.close()` to free all 10,000 contexts and buffers.

**P2**: We built a massive-scale actor model without writing a single custom lock or thread manager. Matryoshka handles the lifecycle entirely.

---

## Part 5: The Matryoshka Flow

```text
  [ Network Sockets ]                                [ Memory Pool ]
        │                                                   │
        ▼                                                   ▼
   NETWORK TASK (Io.Select) ◄───(pool.getWaitResult event)──┘
        │ 
        ▼
   [ StreamContext A ] ─────┐
   [ StreamContext B ] ───┐ │
   [ StreamContext C ]    │ │ (mailbox.send())
        │                 │ │
        ▼                 ▼ ▼
  (Pending Buffers)    [ Ready Mailbox ]
                             │
                             ▼
   ENCODER WORKERS (Io.Group of 64)
   1. mailbox.receive(Ready Mailbox) -> gets StreamContext
   2. Worker processes pending buffers
   3. pool.put() -> returns empty buffers to Pool ──────────┐
   4. mailbox.send() -> passes encoded segments             │
                             │                              │
                             ▼                              │
                     [ Storage Mailbox ]                    │
                             │                              │
                             ▼                              │
   STORAGE TASK (Io.Select)                                 │
        │                                                   │
        ▼                                                   │
   [ File System ]                                          │
        ▲                                                   │
        └───────────────────────────────────────────────────┘
               (Buffers returned to pool for reuse)
```
