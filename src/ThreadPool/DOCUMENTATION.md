# ThreadPool

Thread pools are a collection of threads, all of which are identical except for their unique thread index.

> [!TIP]
> To create a ThreadPool object, call [`PLua.CreateThreadPool()`](/README.md#createthreadpool).

## Run

### Description
Attempts to dispatch all threads in the thread pool.

### Parameters
- `...: any...` - A list of parameters to pass to the thread modules' `Run()` function.

### Return Value
Returns a boolean indicating if the threads were successfully dispatched.

> [!IMPORTANT]
> If any thread is in the new state, the function yields until it leaves the new state.

> [!IMPORTANT]
> If any thread is running, dispatching will fail for all threads.

## JoinAll

### Description
Attempts to join all threads in the pool back into serial execution.

### Parameters
- `yield: boolean` (optional) - If true, yields until all threads are suspended.

### Return Value
A `boolean` flag indicating if the threads were successfully joined.

> [!TIP]
> If the `yield` flag is enabled, the success flag will always be `true`.
> The success flag will only be `false` if the `yield` flag is not enabled and a thread is not suspended.

## JoinAtLeast

### Description
Attempts to join a minimum number of threads in the pool back into serial execution.

### Parameters
- `n: number` - The minimum number of threads to be joined.
- `yield: boolean` (optional) - If true, yields until the join requirements are met.

### Return Value
A `boolean` flag indicating if the threads were successfully joined.

> [!TIP]
> If the `yield` flag is enabled, the success flag will always be `true`.
> The success flag will only be `false` if the `yield` flag is not enabled and less than `n` threads are suspended.

## GetJoinResult

### Description
Returns any values returned by [`Thread:Join()`](/src/Thread/DOCUMENTATION.md#join), including the success flag.

### Parameters
- `threadIndex: number` - Selects which thread in the pool to retrieve the return values of.

### Return Value
- A `boolean` flag indicating if the thread is successfully joined.
- Any values returned from the thread module's `Run()` function.

> [!IMPORTANT]
> If the thread has not yet joined, or failed to join, the success flag will be false.

> [!CAUTION]
> The behavior of calling `GetJoinResult()` after getting a `false` success flag from [`JoinAll()`](./DOCUMENTATION.md#joinall) or [`JoinAtLeast()`](./DOCUMENTATION.md#joinatleast) is undefined.

## Size

### Description
Returns the number of threads contained in the thread pool.

### Return Value
A `number` indicating the numebr of threads contained in the thread pool.

## Destroy

### Description
Attempts to destroy the thread pool and all of its threads, and clean up their used memory.

### Return Value
Returns a `boolean` flag indicating if destruction was successful.

> [!CAUTION]
> If any thread is running, destruction will fail.
> If necessary, use [`JoinAll(true)`](./DOCUMENTATION.md#joinall) to yield until destruction is permitted.