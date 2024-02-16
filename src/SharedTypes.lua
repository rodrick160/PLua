-- SharedTypes
-- Quantum Maniac
-- Jan 10 2023

--[[
	This only exists because Roblox LSP doesn't have the SharedTable type as of the time of this module's creation.
]]

--\\ Module //--

local SharedTypes = {}

--\\ Types //--

export type SharedTable = {
	new: () -> SharedTable,
	new: (t: table) -> SharedTable,
	clear: (st: SharedTable) -> (),
	clone: (st: SharedTable, deep: boolean?) -> SharedTable,
	cloneAndFreeze: (st: SharedTable, deep: boolean?) -> SharedTable,
	increment: (st: SharedTable, key: string | number, delta: number) -> number,
	isFrozen: (st: SharedTable) -> boolean,
	size: (st: SharedTable) -> number,
	update: (st: SharedTable, key: string | number, f: (any...) -> (any...)) -> (),
}

--\\ Return //--

return SharedTypes