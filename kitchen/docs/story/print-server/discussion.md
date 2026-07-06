# Story: Network Print Server — Discussion

A complete system design — from domain problem to Matryoshka implementation.

Three developers design a print server for a shared office network.

**C** owns the client library — the code that submits jobs on behalf of applications.
**S** owns the spooler — the server that queues and manages jobs.
**D** owns the driver — the component that talks to the physical printer.

---

**C**: When my application submits a print job, what do I get back?

**S**: An acknowledgment that the job is queued.

**C**: That's not enough. I need to know when it finishes. Or if it fails.

**S**: You give me a return address when you submit. I send the result there when the job is done.

**C**: So submission and result are separate.

**S**: Yes. You submit, move on, and wait for a result on your own channel.

**C**: Good. My application should not block waiting for a slow printer.

---

**D**: Who hands me the job?

**S**: I do. When you are free, I take the next job from the queue and send it to you.

**D**: What does "send it to you" mean exactly?

**S**: I transfer the job. You own it while you print. I no longer hold it.

**D**: Good. I do not want to share it with anyone while I am working on it.

**S**: You own it completely. When you finish, you send the result back to the client.

**D**: Through you?

**S**: No. Directly. You have the client's return address. You send the result there yourself.

---

**C**: What if I change my mind after submitting?

**S**: If the job is still in my queue, I remove it and send you a canceled result.

**C**: What if it is already with the printer?

**S**: I have to reach the printer.

**D**: How will you reach me? I am printing. I am not listening for new jobs.

**S**: I need a separate signal. Something you see before the next job arrives.

**D**: Use my inbox. But if the cancel waits behind another job, you may send me that job before the cancel arrives. I will start printing the wrong document.

**S**: So the cancel has to reach you before any other job does.

**D**: Yes. Otherwise I cannot honor it reliably.

**C**: What if multiple clients cancel at the same time?

**S**: Each cancel is a separate signal. They all jump the queue. I process them in the order they arrive at the front.

---

**C**: What happens if the printer jams or runs out of paper?

**D**: I detect the error and send a failed result to the client. Then I wait for the operator to clear the fault.

**S**: And the queue keeps accumulating during that time.

**D**: Yes. When the printer is ready again, I signal you, and you send me the next job.

**C**: What signals readiness?

**D**: When I am done with a job — success or failure — I am ready for the next one.

**S**: So readiness is implicit. When you finish, I send the next job. No explicit ready signal needed.

---

**C**: Who owns the document while it is printing?

**D**: I do. From the moment the spooler hands it to me until I send the result to the client.

**C**: And between submission and dispatch to the printer?

**S**: I do. It lives in my queue.

**C**: So at any moment, exactly one party holds the document.

**S**: Yes. The client created it and handed it to me. I hold it until I hand it to the driver. The driver holds it until it sends the result. Nobody shares it.

**D**: That is why I do not need locks while printing. I am the only owner. And I do not need to report progress. Either I finish and send the result, or I fail and send the result. The spooler does not need to know which page I am on.

**S**: And that is why I do not need to track status. If the job is in my queue, I am responsible. If it is not, the driver has it.

At any moment, whoever holds the job owns the problem.

---

Next: [Requirements](requirements.md).
