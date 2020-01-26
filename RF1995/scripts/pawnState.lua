
-------------------------------------------------------
-- Pawn State - code library
-------------------------------------------------------
-- provides functions for saving and restoring
-- pawns' health, shield, acid, frozen and fire states
-------------------------------------------------------
-------------------------------------------------------

-----------------------------------------------------------------------
-- loading:
--[[-------------------------------------------------------------------
	
	-- when loading you must provide a unique id for each instance
	-- you need to use. your mod's id is a good place to start.
	local pawnState = require(self.scriptPath .."pawnState")(uniqueId)
	
]]---------------------------------------------------------------------

------------------
-- function list:
------------------

-------------------------------------
-- pawnState:Save(pawn)
--[[---------------------------------
	saves a pawn's current state.
	
	example:
	
	pawnState:Save(Board:GetPawn(0))
	
--]]---------------------------------

---------------------------------------------------
-- pawnState:Restore(pawn, prevFrame)
--[[-----------------------------------------------
	restores a pawn's state to it's saved state.
	
	example:
	
	pawnState:Restore(Board:GetPawn(0))
	
	----------------------------------------------
	if the optional parameter 'prevFrame' is true:
	it will instead restores the pawn's state to
	the state it had in the previous frame,
	regardless of it's saved state.
	
	example:
	
	pawnState:Restore(Board:GetPawn(0), true)
	
--]]-----------------------------------------------

---------------------------------------------------------
-- pawnState:GetCurrent(pawn)
--[[-----------------------------------------------------
	returns a table of a pawn's current state
	
	example:
	
	local state = pawnState:GetCurrent(Board:GetPawn(0))
	LOG("health = ".. state.curHealth)
	LOG("shield = ".. tostring(state.isShield))
	LOG("acid = ".. tostring(state.isAcid))
	LOG("frozen = ".. tostring(state.isFrozen))
	LOG("fire = ".. tostring(state.isFire))
	
--]]-----------------------------------------------------

-------------------------------------------------------
-- pawnState:GetSaved(pawn)
--[[---------------------------------------------------
	returns a table of a pawn's saved state
	
	example:
	
	local state = pawnState:GetSaved(Board:GetPawn(0))
	LOG("health = ".. state.curHealth)
	LOG("shield = ".. tostring(state.isShield))
	LOG("acid = ".. tostring(state.isAcid))
	LOG("frozen = ".. tostring(state.isFrozen))
	LOG("fire = ".. tostring(state.isFire))
	
--]]---------------------------------------------------

--------------------------------------
-- pawnState:Clear(pawn)
--[[----------------------------------
	clears a pawn's saved state.
	
	example:
	
	pawnState:Clear(Board:GetPawn(0))
	
--]]----------------------------------

-----------------------------------------------------------------
-- pawnState:IsEqual(pawnState1, pawnState2)
--[[-------------------------------------------------------------
	returns true if every tracked state of
	both tables are equal.
	
	example:
	
	local pawn = Board:GetPawn(0)
	
	if pawnState:IsEqual(
		pawnState:GetCurrent(pawn),
		pawnState:GetSaved(pawn))
	then
		LOG("pawn's current state is equal to it's saved state)
	else
		LOG("pawn's current state differs from it's saved state)
	end
	
--]]-------------------------------------------------------------

local this = {}

function this:Save(pawn)
	local mission = GetCurrentMission()
	if not mission then return end
	
	mission[self.id] = mission[self.id] or {}
	mission[self.id].pawns = mission[self.id].pawns or {}
	
	mission[self.id].pawns[pawn:GetId()] = self:GetCurrent(pawn)
end

function this:GetCurrent(pawn)
	return {
		curHealth = pawn:GetHealth(),
		isShield  = pawn:IsShield(),
		isAcid    = pawn:IsAcid(),
		isFrozen  = pawn:IsFrozen(),
		isFire    = pawn:IsFire()
	}
end

function this:GetSaved(pawn)
	local mission = GetCurrentMission()
	if not mission then return self:GetCurrent(pawn) end
	
	mission[self.id] = mission[self.id] or {}
	mission[self.id].pawns = mission[self.id].pawns or {}
	
	return mission[self.id].pawns[pawn:GetId()] or self:GetCurrent(pawn)
end

function this:IsEqual(state1, state2)
	assert(type(state1) == 'table')
	assert(type(state2) == 'table')
	
	return
		state1.curHealth == state2.curHealth and
		state1.isShield  == state2.isShield  and
		state1.isAcid    == state2.isAcid    and
		state1.isFrozen  == state2.isFrozen  and
		state1.isFire    == state2.isFire
end

function this:Clear(pawn)
	local mission = GetCurrentMission()
	if not mission then return end
	
	mission[self.id] = mission[self.id] or {}
	mission[self.id].pawns = mission[self.id].pawns or {}
	
	mission[self.id].pawns[pawn:GetId()] = nil
end

function this:Restore(pawn, prevFrame)
	local mission = GetCurrentMission()
	if not mission then return end
	
	mission[self.id] = mission[self.id] or {}
	mission[self.id].pawns = mission[self.id].pawns or {}
	
	local id = pawn:GetId()
	local origState = mission[self.id].pawns[id]
	
	if prevFrame and modApiExt_internal then
		origState = GAME.trackedPawns[id]
	end
	
	if not origState then return end
	
	lmn_RF_CUtils.SetHealth(pawn, origState.curHealth)
	pawn:SetShield(origState.isShield)
	pawn:SetAcid(origState.isAcid)
	pawn:SetFrozen(origState.isFrozen)
	
	if modApiExt_internal then
		local modApiExt = modApiExt_internal.getMostRecent()
		modApiExt.pawn:setFire(pawn, origState.isFire)
	else
		local d = SpaceDamage(pawn:GetSpace())
		d.iFire = origState.isFire and EFFECT_CREATE or EFFECT_REMOVE
		Board:DamageSpace(d)
	end
end

function new(id)
	assert(type(id) == 'string')
	
	local this = shallow_copy(this)
	this.id = id .."_pawnState"
	
	return this
end

return new