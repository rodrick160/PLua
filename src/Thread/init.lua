-- Thread
-- Quantum Maniac
-- Jan 10 2024

--[[
	Threads are an isolated line of code execution that can run in parallel to other threads.

	All threads have a state value which represents what the thread is currently doing. The state of the thread affects what actions can be performed with it.
	The state of a thread can be accessed by calling Thread:State().
	Threads can be in one of three states:
	- new:
		The thread has just been created and is still being initialized. The thread is not yet ready to begin executing code.
	    The thread will be in the new state immediately upon creation, and will remain in the new state until the next resumption cycle.
		If Thread:Run() is called while the thread is in the new state, the function will yield until the status changes to suspended.
	- suspended:
		The thread is idle, not executing any code, not initializing itself, and is ready to be dispatched.
	- running:
		The thread is actively executing code. In the running state, the thread cannot be dispatched, joined, or destroyed.
]]

--\\ Dependencies //--

local SharedTableRegistry = game:GetService("SharedTableRegistry")

local SharedTypes = require(script.Parent.SharedTypes)

--\\ Module //--

local Thread: Thread = {}
Thread.__index = Thread

--\\ Types //--

export type Thread = typeof(Thread) & {
	_actor: Actor,
	_threadId: number,
	_threadIndex: number?,
	_statusChanged: BindableEvent,
}

type SharedTable = SharedTypes.SharedTable

--\\ Private //--

local nextThreadId = 1
local threadStatuses: SharedTable = SharedTable.new()
SharedTableRegistry:SetSharedTable("ThreadStatuses", threadStatuses)
local threadReturnValues: SharedTable = SharedTable.new()
SharedTableRegistry:SetSharedTable("ThreadReturnValues", threadReturnValues)

--[[
	# _new

	## Description
	`Thread` constructor.

	## Parameters
	- `actor: Actor` - The Actor instance the thread will run under.
	- `module: ModuleScript` - The module script containing the code for the thread to execute.
	- `threadIndex: number` (optional) - The thread index assigned to the thread, if it is part of a thread pool.

	## Return Value
	Returns a newly constructed `Thread` object.
]]
---@private
function Thread._new(actor: Actor, module: ModuleScript, threadIndex: number?): Thread
    local self = {}
    setmetatable(self, Thread)

    self._actor = actor
	self._threadIndex = threadIndex
	self._threadId = nextThreadId
	nextThreadId += 1
	if nextThreadId >= 0xFFFF_FFFF then
		nextThreadId = 1
	end

	self._statusChanged = self._actor:FindFirstChild("StatusChanged", true)

	threadStatuses[self._threadId] = "new"
	threadReturnValues[self._threadId] = {}

	task.defer(function()
		actor:SendMessage("Initialize", module, self._threadId, self._threadIndex)
		threadStatuses[self._threadId] = "suspended"
		self._statusChanged:Fire()
	end)

    return self
end

--\\ Public //--

--[[
	# Run

	## Description
	Dispatches the thread and begins code execution.

	## Parameters
	- `...: any...` - A list of parameters to pass to the thread module's `Run()` function.

	## Return Value
	Returns a boolean indicating if the thread was successfully dispatched.

	> [!IMPORTANT]
	> If the thread is in the new state, the function yields until it leaves the new state.

	> [!IMPORTANT]
	> If the thread is running, dispatching will fail.
]]
function Thread:Run(...: any...): boolean
	while self:Status() == "new" do
		self._statusChanged.Event:Wait()
	end
    if self:Status() == "suspended" then
		threadStatuses[self._threadId] = "running"
        self._actor:SendMessage("Start", ...)
        return true
    end
    return false
end

--[[
	# Join

	## Description
	Attempts to join the thread back into serial execution.

	## Parameters
	- `yield: boolean` (optional) - If true, yields until the thread is suspended.
	## Return Value
	- A `boolean` flag indicating if the thread was successfully joined.
	- Any values returned from the thread module's `Run()` function.

	> [!TIP]
	> If the `yield` flag is enabled, the success flag will always be `true`.
	> The success flag will only be `false` if the `yield` flag is not enabled and the thread is not suspended.
]]
function Thread:Join(yield: boolean?): (boolean, any...)
	while self:Status() ~= "suspended" do
		if not yield then return false end
		self._statusChanged.Event:Wait()
	end
	local sharedReturnValue = threadReturnValues[self._threadId]
	-- selene: allow(manual_table_clone)
	local returnValue = {}
	for i, v in sharedReturnValue do
		returnValue[i] = v
	end
	return true, table.unpack(returnValue)
end

--[[
	# Destroy

	# Description
	Attempts to destroy the thread and clean up its used memory.

	# Return Value
	Returns a `boolean` flag indicating if destruction was successful.

	> [!CAUTION]
	> If the thread is running, destruction will fail.
	> If necessary, use `Join(true)` to yield until destruction is permitted.
]]
function Thread:Destroy(): boolean
    if self:Status() ~= "running" then
        self._actor:Destroy()

		threadStatuses[self._threadId] = nil
		threadReturnValues[self._threadId] = nil
        return true
    end
    return false
end

--[[
	# Status

	## Description
	Returns a string describing the current status of the thread.

	## Return Value
	One of the following strings:
	- `"new"` - The thread has just been created and is initializing.
	- `"suspended"` - The thread is not currently running.
	- `"running"` - The thread is currently running.
]]
function Thread:Status(): string
    return threadStatuses[self._threadId]
end

--\\ Return //--

return Thread