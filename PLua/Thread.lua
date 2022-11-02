-- Thread
-- Quantum Maniac
-- Nov 1 2022

--\\ Module //--

local Thread: Thread = {}
Thread.__index = function(self, index)
    if self._destroyed then
        error("Thread is destroyed.", 2)
    else
        return Thread[index]
    end
end

--\\ Types //--

export type Thread = {
    Run: (self: Thread, ...any) -> boolean,
    Join: (self: Thread, yield: boolean?) -> (boolean, ...any),
    Destroy: (self: Thread) -> boolean,
    Status: (self: Thread) -> string,
}

--\\ Public //--

function Thread.new(actorInit: BaseScript): Thread
    local self = {}
    setmetatable(self, Thread)

    self._destroyed = false
    self._actorInit = actorInit

    return self
end

function Thread:Run(...: any...): boolean
    local status = self._actorInit.Status:Invoke()
    if status == "suspended" then
        self._actorInit.Start:Fire(...)
        return true
    end
    return false
end

function Thread:Join(yield: boolean?): (boolean, any...)
    return self._actorInit.Join:Invoke(yield)
end

function Thread:Destroy(): boolean
    local status = self._actorInit.Status:Invoke()
    if status == "suspended" then
        self._actorInit:Destroy()
        self._destroyed = true
        return true
    end
    return false
end

function Thread:Status(): string
    return self._actorInit.Status:Invoke()
end

--\\ Return //--

return Thread