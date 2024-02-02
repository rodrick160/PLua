-- ThreadPool
-- Quantum Maniac
-- Jan 10 2024

--[[
	Thread pools are a collection of threads, all of which are identical except for their unique thread index.
]]

--\\ Dependencies //--

local SharedTypes = require(script.Parent.SharedTypes)
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

type SharedTable = SharedTypes.SharedTable
SharedTable = SharedTable :: SharedTable
type Thread = Thread.Thread

--\\ Private //--

--[[
	ThreadPool constructor.

	Parameters:
	`{Thread} threads`: An array of the threads the thread pool will contain.
]]
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
	Attempts to dispatch all threads in the thread pool.
	If any threads in the pool are running, dispatching fails immediately.

	If any thread is in the new state, the function yields until it leaves the new state.

	Arguments passed to `Run()` will be passed to the `Run()` function of the thread module.

	Returns a boolean indicating if the threads were successfully dispatched.
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
	Attempts to join all threads back into serial execution.

	The `yield` flag follows the same rules as in `Thread:Join()`, except it will `yield` until all
	threads in the pool are joined.

	Returns a flag indicating if the threads were successfully joined.
	If the `yield` flag is enabled, this success flag will always be true. This flag will
	only be false if the `yield` flag is not enabled and at least one thread is not suspended.
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
	Functions similarly to `JoinAll()`, except the requirement for success changes from all threads
	successfully joining, to only `n` threads needing to join.
]]
function ThreadPool:JoinAtLeast(n: number, yield: boolean?): boolean
	if n <= 0 then
		error("JoinAtLeast() arg 1 must be > 0.", 2)
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
	Returns any values returned by `Thread:Join()`, including the success flag.

	`threadIndex` is used to select which thread in the pool to retrieve the return value(s) of.

	If the thread has not yet joined, or failed to join, the success flag will be false.
]]
function ThreadPool:GetJoinResult(threadIndex: number): (boolean, ...any)
	if not self._returnResults[threadIndex] or not self._returnResults[threadIndex][1] then
		return false
	end
	return table.unpack(self._returnResults[threadIndex])
end

--[[
	Returns the number of threads contained in the thread pool.
]]
function ThreadPool:Size(): number
	return #self._threads
end

--[[
	Attempts to destroy the thread pool and clean up its used memory.

	If any thread contained in the pool is running, destruction will fail.
	If necessary, use JoinAll(true) to yield until destruction is permitted.

	Returns a flag indicating if destruction was successful.
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