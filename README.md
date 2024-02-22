![PLua logo](logo/Small/PLua_Banner.png)

# Install
## Wally
Installing with [Wally](https://github.com/UpliftGames/wally) is recommended.

`rodrick160/plua@1.0.2`

# Description
PLua is a Roblox multithreading library created with the intent to provide a simple, effective, and efficient interface for parallel computation.

> [!NOTE]
> This module uses the term "thread" differently than conventional Lua contexts. A Lua thread is technically a coroutine, not a true thread.
> While coroutines and threads both refer to an independent line of code execution with its own stack, local variables, and instruction pointer,
> they are different in that a coroutine is still executed serially, by a single core of the CPU, as scheduled by the task scheduler. A thread,
> meanwhile, has the ability to (but is not guaranteed to) run in a separate CPU core, parallel with other threads.
> "Thread" in this module will be used in the context of multithreading.

> [!NOTE]
> "Dispatching" a thread means the same thing as "running" the thread.

PLua allows the user to create, dispatch, and join threads, either on their own or in a thread pool. Threads are provided with a module upon creation,
which contains the code to be executed by the thread. In the case of a thread pool, all threads in the pool are given the same module. Threads and
thread pools can then be dispatched to execute their code, and optionally (but usually) joined back into serial execution. If the thread returns one
or more values, they can be retrieved by joining them.

Modules given to threads are expected to have a `Run(...)` method. This function will be called when the thread is dispatched. If the thread is part of
a thread pool, it will be assigned a thread index; a number from 1 to n where n is the number of threads in the thread pool. Upon creation of the thread
pool, each thread's module will be required, and the thread index will be assigned to the ThreadIndex field of the module.
Example use case:

```lua
local TerrainGenerator = {}

function TerrainGenerator.Run(width: number)
	local index = TerrainGenerator.ThreadIndex
	local chunk = Vector2.new(
		index % width,
		math.floor(index / width)
	)

	-- Generate the chunk at the calculated position.
end

return TerrainGenerator
```

# Docs
## Thread

> [!WARNING]
> Thread objects do not automatically clean themselves; call `:Destroy()` on Thread objects if they are no longer used.

### `PLua.CreateThread(module: ModuleScript): Thread`
Creates a single thread.

Example usage:
```lua
local terrainGenerator = script.TerrainGenerator
local thread = PLua.CreateThread(terrainGenerator)
thread:Run()
thread:Join(true)
thread:Destroy()
```

Parameters:
ModuleScript `module`:
	The module to be executed in the thread.
	See the top of this document for more information on thread modules.

Returns:
	A newly created Thread object.

### `Thread:Run(...: any...): boolean`
Dispatches the thread and begins code execution.

If the thread is in the new state, the function yields until it leaves the new state.
Otherwise, if the thread is not suspended (i.e. the thread is running), dispatching will fail.

Arguments passed to Run() will be passed to the Run() function of the thread module.

Returns a boolean indicating if the thread was successfully dispatched.

### `Thread:Join(yield: boolean?): (boolean, any...)`
Attempts to join the thread back into serial execution.

An optional yield flag can be passed. If this flag is enabled, and the thread is not
suspended, the function will yield until the thread enters the suspended state. If the
thread is suspended upon calling this function, the yield flag does nothing and the
function will not yield.

Returns a tuple beginning with flag indicating if the thread was successfully joined.
If the yield flag is enabled, this success flag will always be true. This flag will
only be false if the yield flag is not enabled and the thread is not suspended.

Following the success flag, the tuple contains any values returned from the thread module's
Run() function.

### `Thread:Destroy(): boolean`
Attempts to destroy the thread and clean up its used memory.

If the thread is running, destruction will fail.
If necessary, use Join(true) to yield until destruction is permitted.

Returns a flag indicating if destruction was successful.

### `Thread:Status(): string`
Returns the current status of the thread as a string:
"new", "suspended", or "running".

## ThreadPool

> [!WARNING]
> ThreadPool objects do not automatically clean themselves; call :Destroy() on ThreadPool objects if they are no longer used.

### `PLua.CreateThreadPool(n: number, module: ModuleScript): ThreadPool`
Creates a thread pool with `n` threads.

Example usage:
```lua
local width = 5
local length = 10
local terrainGenerator = script.TerrainGenerator
local threadPool = PLua.CreateThreadPool(width * length, terrainGenerator)
threadPool:Run(width)
threadPool:JoinAll(true)
threadPool:Destroy()
```

Parameters:
number `n`: The number of threads to create.
ModuleScript `module`:
	The module to be executed in the threads.
	See the top of this document for more information on thread modules.

Returns:
	A newly created ThreadPool object.


### `ThreadPool:Run(...: any...): boolean`
Attempts to dispatch all threads in the thread pool.
If any threads in the pool are running, dispatching fails immediately.

If any thread is in the new state, the function yields until it leaves the new state.

Arguments passed to `Run()` will be passed to the `Run()` function of the thread module.

Returns a boolean indicating if the threads were successfully dispatched.

### `ThreadPool:Join(yield: boolean?): boolean`
Attempts to join all threads back into serial execution.

The `yield` flag follows the same rules as in `Thread:Join()`, except it will `yield` until all
threads in the pool are joined.

Returns a flag indicating if the threads were successfully joined.
If the `yield` flag is enabled, this success flag will always be true. This flag will
only be false if the `yield` flag is not enabled and at least one thread is not suspended.

### `ThreadPool:JoinAtLeast(n: number, yield: boolean?): boolean`
Functions similarly to `JoinAll()`, except the requirement for success changes from all threads
successfully joining, to only `n` threads needing to join.

### `ThreadPool:GetJoinResult(threadIndex: number): (boolean, ...any)`
Returns any values returned by `Thread:Join()`, including the success flag.

`threadIndex` is used to select which thread in the pool to retrieve the return value(s) of.

If the thread has not yet joined, or failed to join, the success flag will be false.

### `ThreadPool:Size(): number`
Returns the number of threads contained in the thread pool.

### `ThreadPool:Destroy(): boolean`
Attempts to destroy the thread pool and clean up its used memory.

If any thread contained in the pool is running, destruction will fail.
If necessary, use JoinAll(true) to yield until destruction is permitted.

Returns a flag indicating if destruction was successful.
