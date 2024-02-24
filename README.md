![PLua logo](/logo/Small/PLua_Banner.png)

# PLua

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
a thread pool, it will be assigned a thread index; a number from 1 to `n` where `n` is the number of threads in the thread pool. Upon creation of the thread
pool, each thread's module will be required, and the thread index will be assigned to the `ThreadIndex` field of the module.
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

# Install

Installing with [Wally](https://github.com/UpliftGames/wally) is recommended.

`rodrick160/plua@1.0.2`

# Docs

## CreateThread

### Description
Creates a single thread.

### Parameters
- `module: ModuleScript` - The module to be executed in the thread. See [the top of this page](./README.md#plua) for more information on thread modules.

### Return Value
A newly created [`Thread`](/src/Thread/DOCUMENTATION.md) object.

### Usage Examples
```lua
local terrainGenerator = script.TerrainGenerator
local thread = PLua.CreateThread(terrainGenerator)
thread:Run()
thread:Join(true)
thread:Destroy()
```
	
> [!CAUTION]
> Thread objects do not automatically clean themselves; call [`Thread:Destroy()`](/src/Thread/DOCUMENTATION.md#destroy) on Thread objects if they are no longer used.

## CreateThreadPool

### Description
Creates a thread pool with `n` threads.

### Parameters
- `n: number` - The number of threads to create.
- `module: ModuleScript` - The module to be executed in the threads. See [the top of this page](./README.md#plua) for more information on thread modules.

### Return Value
A newly created [`ThreadPool`](/src/ThreadPool/DOCUMENTATION.md) object.

### Usage Examples
```lua
local width = 5
local length = 10
local terrainGenerator = script.TerrainGenerator
local threadPool = PLua.CreateThreadPool(width * length, terrainGenerator)
threadPool:Run(width)
threadPool:JoinAll(true)
threadPool:Destroy()
```

> [!CAUTION]
> ThreadPool objects do not automatically clean themselves; call [`ThreadPool:Destroy()`](/src/ThreadPool//DOCUMENTATION.md#destroy) on ThreadPool objects if they are no longer used.
