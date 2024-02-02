-- PLua
-- Quantum Maniac
-- Jan 10 2024

--[[
    PLua is a Roblox multithreading library created with the intent to provide a simple, effective, and efficient interface for parallel computation.

    NOTE: This module uses the term "thread" differently than conventional Lua contexts. A Lua thread is technically a coroutine, not a true thread.
          While coroutines and threads both refer to an independent line of code execution with its own stack, local variables, and instruction pointer,
          they are different in that a coroutine is still executed serially, by a single core of the CPU, as scheduled by the task scheduler. A thread,
          meanwhile, has the ability to (but is not guaranteed to) run in a separate CPU core, parallel with other threads.
          "Thread" in this module will be used in the context of multithreading.

    NOTE: "Dispatching" a thread means the same thing as "running" the thread.

    PLua allows the user to create, dispatch, and join threads, either on their own or in a thread pool. Threads are provided with a module upon creation,
    which contains the code to be executed by the thread. In the case of a thread pool, all threads in the pool are given the same module. Threads and
    thread pools can then be dispatched to execute their code, and optionally (but usually) joined back into serial execution. If the thread returns one
    or more values, they can be retrieved by joining them.

    Modules given to threads are expected to have a Run(...) method. This function will be called when the thread is dispatched. If the thread is part of
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

    WARNING: Thread and ThreadPool objects do not automatically clean themselves; call :Destroy() on these objects if they are no longer used.
]]

--\\ Dependencies //--

local ActorInit = require(script.ActorInit)
local SharedTypes = require(script.SharedTypes)
local Thread = require(script.Thread)
local ThreadPool = require(script.ThreadPool)

--\\ Module //--

local PLua = {}

--\\ Types //--

export type Thread = Thread.Thread
export type ThreadPool = ThreadPool.ThreadPool

export type SharedTable = SharedTypes.SharedTable

--\\ Private //--

local function newActorScript(parent: Instance): Actor
    local actor = Instance.new("Actor", parent)
    local actorInit = ActorInit.GetActorInit()
    actorInit.Parent = actor
    actorInit.Enabled = true
    return actor
end

--\\ Public //--

--[[
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
]]
function PLua.CreateThread(module: ModuleScript): Thread
    local callingScript = getfenv(2).script
    local actor = newActorScript(callingScript)
    local thread = Thread._new(actor, module)

    return thread
end

--[[
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
]]
function PLua.CreateThreadPool(n: number, module: ModuleScript): ThreadPool
    local threads = table.create(n)
    local callingScript = getfenv(2).script
    for i = 1, n do
        local actor = newActorScript(callingScript)
        local thread = Thread._new(actor, module, i)
        threads[i] = thread
    end
    local threadPool = ThreadPool._new(threads)

    return threadPool
end

--\\ Return //--

return PLua