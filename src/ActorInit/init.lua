-- ActorInit
-- Quantum Maniac
-- Jan 10 2023

--\\ Dependencies //--

local RunService = game:GetService("RunService")

--\\ Module //--

local ActorInit = {}

--\\ Private //--

local actorFolder = Instance.new("Folder")
actorFolder.Name = "Actors"
actorFolder.Parent = if RunService:IsClient() then game.Players.LocalPlayer.PlayerScripts else game.ServerScriptService

local actorInit = if RunService:IsClient() then script.ActorInitClient else script.ActorInitServer

--\\ Public //--

function ActorInit.GetActorFolder(): Folder
	return actorFolder
end

function ActorInit.GetActorInit(): Script | LocalScript
	return actorInit:Clone()
end

--\\ Return //--

return ActorInit