-- ActorInit
-- Quantum Maniac
-- Jan 10 2024

local SharedTableRegistry = game:GetService("SharedTableRegistry")

local actor: Actor = script.Parent
local module: ModuleScript = nil
local threadId = 0
local threadIndex: number? = nil
local statusChanged = script.StatusChanged

local threadStatuses = SharedTableRegistry:GetSharedTable("ThreadStatuses")
local threadReturnValues = SharedTableRegistry:GetSharedTable("ThreadReturnValues")

local function setStatus(status: string)
	threadStatuses[threadId] = status
	statusChanged:Fire()
end

actor:BindToMessage("Initialize", function(_module: ModuleScript, _threadId: number, _threadIndex: number?)
	module = _module
	threadId = _threadId
	threadIndex = _threadIndex
end)

actor:BindToMessage("Start", function(...)
	local threadModule = require(module)

	task.desynchronize()
	threadModule.ThreadIndex = threadIndex
	threadReturnValues[threadId] = table.pack(threadModule.Run(...))
	setStatus("suspended")
	task.synchronize()
end)