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
local threadStatuses = SharedTable.new()
SharedTableRegistry:SetSharedTable("ThreadStatuses", threadStatuses)
local threadReturnValues = SharedTable.new()
SharedTableRegistry:SetSharedTable("ThreadReturnValues", threadReturnValues)

--[[
	Thread constructor.

	Parameters:
	Actor actor: The Actor instance the thread will run under.
	number? threadIndex: The thread index assigned to the thread, if it is part of a thread pool.
]]
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
	Dispatches the thread and begins code execution.

	If the thread is in the new state, the function yields until it leaves the new state.
	Otherwise, if the thread is not suspended (i.e. the thread is running), dispatching will fail.

	Arguments passed to Run() will be passed to the Run() function of the thread module.

	Returns a boolean indicating if the thread was successfully dispatched.
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
]]
function Thread:Join(yield: boolean?): (boolean, any...)
	while self:Status() ~= "suspended" do
		if not yield then return false end
		self._statusChanged.Event:Wait()
	end
	local sharedReturnValue = threadReturnValues[self._threadId]
	local returnValue = {}
	for i, v in sharedReturnValue do
		returnValue[i] = v
	end
	return true, table.unpack(returnValue)
end

--[[
	Attempts to destroy the thread and clean up its used memory.

	If the thread is running, destruction will fail.
	If necessary, use Join(true) to yield until destruction is permitted.

	Returns a flag indicating if destruction was successful.
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
	Returns the current status of the thread as a string:
	"new", "suspended", or "running".
]]
function Thread:Status(): string
    return threadStatuses[self._threadId]
end

--\\ Return //--

return Thread