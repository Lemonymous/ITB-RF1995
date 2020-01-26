
-----------------------------------------------------
-- Mine Detection - code library
-----------------------------------------------------
-- tracks mines and provides hooks related to mines.
-- all hooks should be registered once, in init.
-----------------------------------------------------
-----------------------------------------------------

-----------------------------------------------------------------------
-- initialization and loading:
--[[-------------------------------------------------------------------
	
	-- in init.lua
	local mineDetection

	-- in init.lua - function init:
	mineDetection = require(self.scriptPath .."mineDetection")
	mineDetection:init(self)
	
	-- in init.lua - function load:
	mineDetection:load(self)
	
	-- after you have initialized and loaded it,
	-- you can request it again anywhere with:
	local mineDetection = require(self.scriptPath .."mineDetection")
	
]]---------------------------------------------------------------------

------------------
-- function list:
------------------

-----------------------------------------------------------------
-- mineDetection:AddMineCreatedHook(func)
--[[-------------------------------------------------------------
	calls the function 'func' when a mine is added to the Board,
	including mines already present at the start of a mission.
	
	example:
	
	mineDetection:AddMineCreatedHook(function(tile)
		LOG("mine created on tile ".. tile:GetString())
	end)
	
--]]-------------------------------------------------------------

---------------------------------------------------------------------
-- mineDetection:AddMineRemovedHook(func)
--[[-----------------------------------------------------------------
	calls the function 'func' when a mine is removed from the Board.
	
	example:
	
	mineDetection:AddMineRemovedHook(function(tile)
		LOG("mine removed from tile ".. tile:GetString())
	end)
	
--]]-----------------------------------------------------------------

----------------------------------------------------------------------------------------
-- mineDetection:AddMineExplodedHook(func)
--[[------------------------------------------------------------------------------------
	calls the function 'func' when a pawn triggers a damaging mine
	
	example:
	
	mineDetection:AddMineExplodedHook(function(pawn)
		LOG(pawn:GetMechName() .." triggered a mine at ".. pawn:GetSpace():GetString())
	end)
	
--]]------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------
-- mineDetection:AddFreezeMineExplodedHook(func)
--[[------------------------------------------------------------------------------------
	calls the function 'func' when a pawn triggers a freezing mine
	
	example:
	
	mineDetection:AddFreezeMineExplodedHook(function(pawn)
		LOG(pawn:GetMechName() .." triggered a mine at ".. pawn:GetSpace():GetString())
	end)
	
--]]------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------
-- mineDetection:AddMineTileStateChangedHook(func)
--[[-----------------------------------------------------------------------------------
	calls the function 'func' if the tile state of a mine's location changes.
	
	*see the library tileState.lua for more details.
	
	example:
	
	mineDetection:AddMineTileStateChangedHook(function(tile, currentState, savedState)
		LOG("tile change detected at ".. tile:GetString())
	end)
	
--]]-----------------------------------------------------------------------------------

--------------------------------------------------------------
-- mineDetection:RestoreTile(tile)
--[[----------------------------------------------------------
	restores a tile to it's saved state.
	intended to be used within hooks to revert a tile's state
	back to what it was before the hook fired.
	
	example:
	
	mineDetection:AddMineExplodedHook(function(pawn)
		mineDetection:RestoreTile(pawn:GetSpace())
	end)
	
--]]----------------------------------------------------------

local this = {
	explosive = {},
	freezing = {},
	created = {},
	removed = {},
	tileChange = {}
}

function this:AddMineExplodedHook(func)
	assert(type(func) == 'function')
	
	table.insert(this.explosive, func)
end

function this:AddFreezeMineExplodedHook(func)
	assert(type(func) == 'function')
	
	table.insert(this.freezing, func)
end

function this:AddMineCreatedHook(func)
	assert(type(func) == 'function')
	
	table.insert(this.created, func)
end

function this:AddMineRemovedHook(func)
	assert(type(func) == 'function')
	
	table.insert(this.removed, func)
end

function this:AddMineTileStateChangedHook(func)
	assert(type(func) == 'function')
	
	table.insert(this.tileChange, func)
end

function this:RestoreTile(tile)
	self.tileState:Restore(tile)
end

function this:init(mod)
	assert(type(mod) == 'table')
	assert(type(mod.id) == 'string')
	
	self.id = mod.id .."_mineDetection"
	
	self.tileState = require(mod.scriptPath .."tileState")(self.id)
end

function this:load(modApiExt)
	assert(type(self.id) == 'string')
	
	local tripped = self.id .. "_tripped"
	local mines = self.id .."_mines"
	
	modApiExt:addPawnDamagedHook(function(mission, pawn)
		mission[tripped] = mission[tripped] or {}
		
		local id = pawn:GetId()
		if mission[tripped][id] then
			mission[tripped][id] = nil
			
			for _, func in ipairs(self.explosive) do
				func(pawn)
			end
		end
	end)
	
	modApiExt:addPawnIsShieldedHook(function(mission, pawn, isShield)
		if not isShield then
			mission[tripped] = mission[tripped] or {}
			
			local id = pawn:GetId()
			if mission[tripped][id] then
				mission[tripped][id] = nil
				
				for _, func in ipairs(self.explosive) do
					func(pawn)
				end
			end
		end
	end)
	
	modApiExt:addPawnIsFrozenHook(function(mission, pawn, isFrozen)
		if isFrozen then
			mission[tripped] = mission[tripped] or {}
			
			local id = pawn:GetId()
			if mission[tripped][id] then
				mission[tripped][id] = nil
				
				for _, func in ipairs(self.freezing) do
					func(pawn)
				end
			end
		end
	end)
	
	modApiExt:addPawnPositionChangedHook(function(mission, pawn)
		local id = pawn:GetId()
		local tile = pawn:GetSpace()
		
		mission[tripped] = mission[tripped] or {}
		mission[tripped][id] = nil
		
		-- check if there is a mine on the tile we are moving to
		if Board:IsDangerousItem(tile) then
			mission[tripped][id] = true
			
		-- or if we just stepped on an explosive mine
		elseif pawn:GetHealth() < GAME.trackedPawns[id].curHealth then
			for _, func in ipairs(self.explosive) do
				func(pawn)
			end
			
		elseif pawn:IsShield() ~= GAME.trackedPawns[id].isShield then
			for _, func in ipairs(self.explosive) do
				func(pawn)
			end
		
		-- or if we just stepped on a freezing mine
		elseif pawn:IsFrozen() and not GAME.trackedPawns[id].isFrozen then
			for _, func in ipairs(self.freezing) do
				func(pawn)
			end
		end
	end)
	
	modApi:addMissionUpdateHook(function(mission)
		if not GetCurrentMission() then return end
		
		mission[mines] = mission[mines] or {}
		
		for id, v in pairs(mission[mines]) do
			local tile = idx2p(id)
			if not Board:IsDangerousItem(tile) then
				mission[mines][id] = nil
				
				for _, func in ipairs(self.removed) do
					func(tile)
				end
				
				self.tileState:Clear(tile)
			else
				local currentState = self.tileState:GetCurrent(tile)
				local savedState = self.tileState:GetSaved(tile)
				
				if not self.tileState:IsEqual(currentState, savedState) then
					
					for _, func in ipairs(self.tileChange) do
						func(tile, currentState, savedState)
					end
					
					self.tileState:Save(tile)
				end
				
			end
		end
		
		local size = Board:GetSize()
		for x = 0, size.x - 1 do
			for y = 0, size.y - 1 do
				local tile = Point(x, y)
				local id = p2idx(tile)
				
				if
					Board:IsDangerousItem(tile)		and
					not mission[mines][id]
				then
					mission[mines][id] = self.tileState:GetCurrent(tile)
					self.tileState:Save(tile)
					
					for _, func in ipairs(self.created) do
						func(tile)
					end
				end
			end
		end
	end)
end

return this