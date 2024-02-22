-- ThreadPool
-- Quantum Maniac
-- Jan 10 2024

--[[
	Thread pools are a collection of threads, all of which are identical except for their unique thread index.
]]

--\\ Dependencies //--

local Thread = require(script.Parent.Thread)

--\\ Module //--

local ThreadPool: ThreadPool = {}
ThreadPool.__index = ThreadPool

--\\ Types //--

export type ThreadPool = typeof(ThreadPool) & {
	_threads: {Thread},
	_anyStatusChanged: BindableEvent,
	_returnResults: {},
}

type Thread = Thread.Thread

--\\ Private //--

--[[
	# _new

	## Description
	`ThreadPool` constructor.

	## Parameters
	- `threads: {Thread}` - An array of the threads the thread pool will contain.

	## Return Value
	Returns a newly constructed `ThreadPool` object.
]]
---@private
function ThreadPool._new(threads: {Thread}): ThreadPool
    local self = {}
    setmetatable(self, ThreadPool)

	self._threads = threads
	self._anyStatusChanged = Instance.new("BindableEvent")
	self._returnResults = {}

	local function onStatusChanged()
		self._anyStatusChanged:Fire()
	end
	for _, thread in threads do
		thread._statusChanged.Event:Connect(onStatusChanged)
	end

    return self
end

--\\ Public //--

--[[
	# Run

	## Description
	Attempts to dispatch all threads in the thread pool.

	## Parameters
	- `...: any...` - A list of parameters to pass to the thread modules' `Run()` function.

	## Return Value
	Returns a boolean indicating if the threads were successfully dispatched.

	> [!IMPORTANT]
	> If any thread is in the new state, the function yields until it leaves the new state.

	> [!IMPORTANT]
	> If any thread is running, dispatching will fail for all threads.
]]
function ThreadPool:Run(...: any...): boolean
    for _, thread in self._threads do
        if thread:Status() == "running" then
            return false
        end
    end
	for _, thread in self._threads do
		thread:Run(...)
	end
    return true
end

--[[
	# JoinAll

	## Description
	Attempts to join all threads in the pool back into serial execution.

	## Parameters
	- `yield: boolean` (optional) - If true, yields until all threads are suspended.

	## Return Value
	A `boolean` flag indicating if the threads were successfully joined.

	> [!TIP]
	> If the `yield` flag is enabled, the success flag will always be `true`.
	> The success flag will only be `false` if the `yield` flag is not enabled and a thread is not suspended.
]]
function ThreadPool:JoinAll(yield: boolean?): boolean
    for _, thread in self._threads do
		local joinResult = table.pack(thread:Join(yield))
		self._returnResults[thread._threadId] = joinResult
        if not joinResult[1] then
            return false
        end
    end
    return true
end

--[[
	# JoinAtLeast

	## Description
	Attempts to join a minimum number of threads in the pool back into serial execution.

	## Parameters
	- `n: number` - The minimum number of threads to be joined.
	- `yield: boolean` (optional) - If true, yields until the join requirements are met.

	## Return Value
	A `boolean` flag indicating if the threads were successfully joined.

	> [!TIP]
	> If the `yield` flag is enabled, the success flag will always be `true`.
	> The success flag will only be `false` if the `yield` flag is not enabled and less than `n` threads are suspended.
]]
function ThreadPool:JoinAtLeast(n: number, yield: boolean?): boolean
	if n <= 0 then
		error("JoinAtLeast() arg 1 must be > 0.", 2)
	elseif n > self:Size() then
		error("JoinAtLeast() arg 1 must be <= thread count.", 2)
	end

	repeat
		local joinedThreads = 0
		local checkedThreads = 0
		for _, thread in self._threads do
			checkedThreads += 1
			local joinResult = table.pack(thread:Join())
			self._returnResults[thread._threadIndex] = joinResult
			if joinResult[1] then
				joinedThreads += 1
			end
			if joinedThreads >= n then
				return true
			end
			if #self._threads - checkedThreads < n then
				break
			end
		end
		if yield then
			self._anyStatusChanged.Event:Wait()
		end
	until not yield

	return false
end

--[[
	# GetJoinResult

	## Description
	Returns any values returned by `Thread:Join()`, including the success flag.

	## Parameters
	- `threadIndex: number` - Selects which thread in the pool to retrieve the return values of.

	## Return Value
	- A `boolean` flag indicating if the thread is successfully joined.
	- Any values returned from the thread module's `Run()` function.

	> [!IMPORTANT]
	> If the thread has not yet joined, or failed to join, the success flag will be false.

	> [!CAUTION]
	> The behavior of calling `GetJoinResult()` after getting a `false` success flag from `JoinAll()` or `JoinAtLeast()` is undefined.
]]
function ThreadPool:GetJoinResult(threadIndex: number): (boolean, ...any)
	if not self._returnResults[threadIndex] or not self._returnResults[threadIndex][1] then
		return false
	end
	return table.unpack(self._returnResults[threadIndex])
end

--[[
	# Size

	## Description
	Returns the number of threads contained in the thread pool.

	## Return Value
	A `number` indicating the numebr of threads contained in the thread pool.
]]
function ThreadPool:Size(): number
	return #self._threads
end

--[[
	# Destroy

	## Description
	Attempts to destroy the thread pool and all of its threads, and clean up their used memory.

	## Return Value
	Returns a `boolean` flag indicating if destruction was successful.

	> [!CAUTION]
	> If any thread is running, destruction will fail.
	> If necessary, use `JoinAll(true)` to yield until destruction is permitted.
]]
function ThreadPool:Destroy(): boolean
    for _, thread in self._threads do
        if thread:Status() == "running" then
            return false
        end
    end

    for _, thread in self._threads do
        thread:Destroy()
    end
	self._anyStatusChanged:Destroy()

    return true
end

--\\ Return //--

return ThreadPool