# PLua
This module provides parallel Luau accessibility within module-oriented script frameworks.
Parallel execution can be done either by a single thread at a time, or by creating a pool of threads at once and
assigning tasks to be executed by the first available pooled thread.

PLua can be used to create two types of objects: Threads and ThreadPools.
Threads are a single thread of parallel execution, and ThreadPools represent a collection of threads being used
to achieve some collective task.

The function body of a thread is read from a module script. This module script is passed as a constructor argument,
which will then be cloned into an actor for execution. The script is expected to have a module.Run(...) function, which
can take any parameters and return any values. NOTE: Tables will be passed by value, not by reference, when passed as an
argument to a thread. Table metatables will also be stripped when sent to a thread. This is by technical limitation.
However, instances *can* be passed by value.

##Constructors:
###`PLua.CreateThread(module: ModuleScript, ...: any...): Thread`
Creates a single Thread of the given `module`, and immidiately begins executing it in parallel with the parameters given in `...`
Returns a Thread object.

###`PLua.CreateThreadPool(n: number): ThreadPool`
Creates a ThreadPool with `n` Threads. Threads do not execute anything until given a task to complete.
Returns a ThreadPool object.

##Thread:
###`Thread:Run(...: any...): boolean`
Runs the thread again with the same module as before. Arguments passed into `...` will be passed to the thread function.
Returns a boolean indicating if thread execution began successfully. This will be false if the thread is already running.

###`Thread:Join(yield: boolean?): (boolean, any...)`
Checks if the thread has completed execution so that it can be joined back into serial execution. If `yield` is true, the function
will yield until the thread is finished executing.
Returns a boolean indicating if the thread has finished execution (always true when `yield` is true), followed by any values
returned by the thread.

###`Thread:Destroy(): boolean`
Destroys a thread and frees its resources. This call will fail if the thread is currently running.
Returns a boolean indicating if the thread was successfully destroyed.

###`Thread:Status(): string`
Returns "running" if the thread is currently in execution, or "suspended" if not.

##ThreadPool:
###`ThreadPool:Run(module: ModuleScript, ...: any...): boolean`
Attempts to run the given module on the first available thread.
If an available thread is found, it will begin executing immediately with the parameters passed in `...`, and returns true.
Otherwise, returns false.

###`ThreadPool:Join(yield: boolean?): boolean`
Checks if all threads have completed execution. If `yield` is true, the function will yield until all threads are finished executing.
Returns a boolean indicating if the threads have finished execution (always true when `yield` is true). NOTE: Return values cannot
be retrieved from a ThreadPool.

###`ThreadPool:Destroy(): boolean`
Attempts to destroy all Threads in the ThreadPool. If any Thread is currently executing, no threads will be destroyed and the function returns false.
Otherwise, if all Threads are suspended, they will all be destroyed and the function returns true.
