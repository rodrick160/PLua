-- ActorInit
-- Quantum Maniac
-- Nov 1 2022

local stoppedEvent = Instance.new("BindableEvent")
local returnValue = {}
local status = "suspended"

script.Join.OnInvoke = function(yield: boolean?): (boolean, ...any)
    if status == "running" then
        if yield then
            stoppedEvent.Event:Wait()
        else
            return false
        end
    end

    return true, table.unpack(returnValue)
end

script.Status.OnInvoke = function(): string
    return status
end

script.Start.Event:Connect(function(...)
    local actorThread = require(script.ActorThread)

    status = "running"
    task.desynchronize()
    returnValue = table.pack(actorThread.Run(...))
    status = "suspended"
    task.synchronize()
    stoppedEvent:Fire()
end)