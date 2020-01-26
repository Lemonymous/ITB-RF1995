
--------------------------------------------------------------
-- Tile State - code library
--------------------------------------------------------------
-- provides functions for saving and restoring
-- tiles' terrain, acid, fire, smoke, ice and mountain states
--------------------------------------------------------------
--------------------------------------------------------------

-----------------------------------------------------------------------
-- loading:
--[[-------------------------------------------------------------------
	
	-- when loading you must provide a unique id for each instance
	-- you need to use. your mod's id is a good place to start.
	local tileState = require(self.scriptPath .."tileState")(uniqueId)
	
]]---------------------------------------------------------------------

------------------
-- function list:
------------------

----------------------------------
-- tileState:Save(tile)
--[[------------------------------
	saves a tile's current state.
	
	example:
	
	tileState:Save(Point(0,0))
	
--]]------------------------------

-------------------------------------------------
-- tileState:Restore(tile)
--[[---------------------------------------------
	restores a tile's state to it's saved state.
	
	example:
	
	tileState:Restore(Point(0,0))
	
--]]---------------------------------------------

---------------------------------------------------------
-- tileState:GetCurrent(tile)
--[[-----------------------------------------------------
	returns a table of a tile's current state
	
	example:
	
	local state = tileState:GetCurrent(Point(0,0))
	LOG("terrain = ".. state.terrain)
	LOG("acid = ".. tostring(state.acid))
	LOG("fire = ".. tostring(state.fire))
	LOG("smoke = ".. tostring(state.smoke))
	LOG("ice health = ".. state.ice)
	LOG("mountain health = ".. state.mountain)
	
--]]-----------------------------------------------------

---------------------------------------------------------
-- tileState:GetSaved(tile)
--[[-----------------------------------------------------
	returns a table of a tile's saved state
	
	example:
	
	local state = tileState:GetSaved(Point(0,0))
	LOG("terrain = ".. state.terrain)
	LOG("acid = ".. tostring(state.acid))
	LOG("fire = ".. tostring(state.fire))
	LOG("smoke = ".. tostring(state.smoke))
	LOG("ice health = ".. state.ice)
	LOG("mountain health = ".. state.mountain)
	
--]]-----------------------------------------------------

---------------------------------
-- tileState:Clear(tile)
--[[-----------------------------
	clears a tile's saved state.
	
	example:
	
	tileState:Clear(Point(0,0))
	
--]]-----------------------------

-----------------------------------------------------------------
-- tileState:IsEqual(tileState1, tileState2)
--[[-------------------------------------------------------------
	returns true if every tracked state of
	both tables are equal.
	
	example:
	
	local tile = Point(0,0)
	
	if tileState:IsEqual(
		tileState:GetCurrent(tile),
		tileState:GetSaved(tile))
	then
		LOG("tile's current state is equal to it's saved state)
	else
		LOG("tile's current state differs from it's saved state)
	end
	
--]]-------------------------------------------------------------

local this = {}

-- a crude way to detect tipImage.
local function IsTipImage()
	return Board:GetSize() == Point(6,6)
end

-- move all pawns away from a tile.
-- use RepopulateTile to revert changes.
local function ClearTile(tile)
	this.displaced = {}
	local pawn = Board:GetPawn(tile)
	while pawn do
		pawn:SetSpace(Point(-1, -1))
		table.insert(this.displaced, pawn:GetId())
		pawn = Board:GetPawn(tile)
	end
end

-- moves all displaced pawns back to it's tile.
-- used after ClearTile
local function RepopulateTile(tile)
	for _, id in ipairs(this.displaced) do
		Board:GetPawn(id):SetSpace(tile)
	end
end

-- returns the ice/mountain hp state of a tile {0, 1, 2}
local function GetTileState(tile, terrain)
	local state = 0
	if Board:GetTerrain(tile) == terrain then
		if
			IsTestMechScenario()	or
			IsTipImage()			or
			not modApiExt_internal
		then
			return 1
		else
			local modApiExt = modApiExt_internal.getMostRecent()
			state = modApiExt.board:getTileHealth(tile)
		end
	end
	return state
end

function this:Save(tile)
	local mission = GetCurrentMission()
	if not mission then return end
	
	mission[self.id] = mission[self.id] or {}
	mission[self.id].tiles = mission[self.id].tiles or {}
	
	mission[self.id].tiles[p2idx(tile)] = self:GetCurrent(tile)
end

function this:GetCurrent(tile)
	return {
		terrain  = Board:GetTerrain(tile),
		acid     = Board:IsAcid(tile),
		fire     = Board:IsFire(tile),
		smoke    = Board:IsSmoke(tile),
		ice      = GetTileState(tile, TERRAIN_ICE),
		mountain = GetTileState(tile, TERRAIN_MOUNTAIN)
	}
end

function this:GetSaved(tile)
	local mission = GetCurrentMission()
	if not mission then return self:GetCurrent(tile) end
	
	mission[self.id] = mission[self.id] or {}
	mission[self.id].tiles = mission[self.id].tiles or {}
	
	return mission[self.id].tiles[p2idx(tile)] or self:GetCurrent(tile)
end

function this:IsEqual(state1, state2)
	assert(type(state1) == 'table')
	assert(type(state2) == 'table')
	
	return
		state1.terrain  == state2.terrain  and
		state1.acid     == state2.acid     and
		state1.fire     == state2.fire     and
		state1.smoke    == state2.smoke    and
		state1.ice      == state2.ice      and
		state1.mountain == state2.mountain
end

function this:Clear(tile)
	local mission = GetCurrentMission()
	if not mission then return end
	
	mission[self.id] = mission[self.id] or {}
	mission[self.id].tiles = mission[self.id].tiles or {}
	
	mission[self.id].tiles[p2idx(tile)] = nil
end

function this:Restore(tile)
	local mission = GetCurrentMission()
	if not mission then return end
	
	mission[self.id] = mission[self.id] or {}
	mission[self.id].tiles = mission[self.id].tiles or {}
	
	local origState = mission[self.id].tiles[p2idx(tile)]
	if not origState then return end
	
	ClearTile(tile)
	
	Board:SetTerrain(tile, TERRAIN_WATER)
	
	Board:SetTerrain(tile, origState.terrain)
	Board:SetSmoke(tile, origState.smoke, false)
	Board:SetAcid(tile, origState.acid)
	
	if origState.fire then
		local d = SpaceDamage(tile)
		d.iFire = EFFECT_CREATE
		Board:DamageSpace(d)
	end
	
	if origState.ice > 0 then
		Board:SetTerrain(tile, origState.terrain)
		if origState.ice == 1 then
			Board:DamageSpace(SpaceDamage(tile, 1))
		end
	end
	
	if origState.mountain > 0 then
		Board:SetTerrain(tile, origState.terrain)
		if origState.mountain == 1 then
			Board:DamageSpace(SpaceDamage(tile, 1))
		end
	end
	
	RepopulateTile(tile)
end

function new(id)
	assert(type(id) == 'string')
	
	local this = shallow_copy(this)
	this.id = id .."_tileState"
	
	return this
end

return new