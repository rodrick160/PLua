-- ThreadPool
-- Quantum Maniac
-- Nov 1 2022

--\\ Module //--

local ThreadPool: ThreadPool = {}
ThreadPool.__index = ThreadPool

--\\ Types //--

export type ThreadPool = {
    Run: (self: ThreadPool, module: ModuleScript, ...any) -> boolean,
    Join: (self: ThreadPool, yield: boolean?) -> boolean,
    Destroy: (self: ThreadPool) -> boolean,
}

--\\ Public //--

function ThreadPool.new(threads: table): ThreadPool
    local self = {}
    setmetatable(self, ThreadPool)

    self._threads = threads

    return self
end

function ThreadPool:Run(module: ModuleScript, ...: any...): boolean
    for _, thread in self._threads do
        if thread:Status() == "suspended" then
            if thread._actorInit:FindFirstChild("ActorThread") then
                thread._actorInit.ActorThread:Destroy()
            end
            module = module:Clone()
            module.Name = "ActorThread"
            module.Parent = thread._actorInit
            thread:Run(...)
            return true
        end
    end
    return false
end

function ThreadPool:Join(yield: boolean?): boolean
    for _, thread in self._threads do
        if not thread:Join(yield) then
            return false
        end
    end
    return true
end

function ThreadPool:Destroy(): boolean
    for _, thread in self._threads do
        local status = thread:Status()
        if status ~= "suspended" then
            return false
        end
    end
    for _, thread in self._threads do
        thread:Destroy()
    end
    return true
end

--\\ Return //--

return ThreadPool