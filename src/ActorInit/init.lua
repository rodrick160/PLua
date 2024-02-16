-- ActorInit
-- Quantum Maniac
-- Jan 10 2023

--\\ Dependencies //--

local RunService = game:GetService("RunService")

--\\ Module //--

local ActorInit = {}

--\\ Public //--

function ActorInit.GetActorInit(): BaseScript
	if RunService:IsServer() then
		return script.ActorInitServer:Clone()
	else
		return script.ActorInitClient:Clone()
	end
end

--\\ Return //--

return ActorInit