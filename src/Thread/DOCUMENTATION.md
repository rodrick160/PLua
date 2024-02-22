# Thread
Threads are an isolated line of code execution that can run in parallel to other threads.

All threads have a state value which represents what the thread is currently doing. The state of the thread affects what actions can be performed with it.
The state of a thread can be accessed by calling [`Thread:Status()`](./DOCUMENTATION.md#status).
Threads can be in one of three states:
- new:
	The thread has just been created and is still being initialized. The thread is not yet ready to begin executing code.
	The thread will be in the new state immediately upon creation, and will remain in the new state until the next resumption cycle.
	If [`Thread:Run()`](./DOCUMENTATION.md#run) is called while the thread is in the new state, the function will yield until the status changes to suspended.
- suspended:
	The thread is idle, not executing any code, not initializing itself, and is ready to be dispatched.
- running:
	The thread is actively executing code. In the running state, the thread cannot be dispatched, joined, or destroyed.

> [!TIP]
> To create a Thread object, call [`PLua.CreateThread()`](/README.md#pluacreatethreadpooln-number-module-modulescript-threadpool).

## Run

### Description
Dispatches the thread and begins code execution.

### Parameters
- `...: any...` - A list of parameters to pass to the thread module's `Run()` function.

### Return Value
Returns a boolean indicating if the thread was successfully dispatched.

> [!IMPORTANT]
> If the thread is in the new state, the function yields until it leaves the new state.

> [!IMPORTANT]
> If the thread is running, dispatching will fail.

## Join

### Description
Attempts to join the thread back into serial execution.

### Parameters
- `yield: boolean` (optional) - If true, yields until the thread is suspended.
### Return Value
- A `boolean` flag indicating if the thread was successfully joined.
- Any values returned from the thread module's `Run()` function.

> [!TIP]
> If the `yield` flag is enabled, the success flag will always be `true`.
> The success flag will only be `false` if the `yield` flag is not enabled and the thread is not suspended.

## Destroy

### Description
Attempts to destroy the thread and clean up its used memory.

### Return Value
Returns a `boolean` flag indicating if destruction was successful.

> [!CAUTION]
> If the thread is running, destruction will fail.
> If necessary, use [`Join(true)`](./DOCUMENTATION.md#join) to yield until destruction is permitted.

## Status

### Description
Returns a string describing the current status of the thread.

### Return Value
One of the following strings:
- `"new"` - The thread has just been created and is initializing.
- `"suspended"` - The thread is not currently running.
- `"running"` - The thread is currently running.