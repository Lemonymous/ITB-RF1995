
--------------------------------------
-- Effect Burst - helper library
--------------------------------------
-- provides function allowing you to
-- add burst to water and ice tiles.
-- requires modApiExt loaded.
--------------------------------------

local this = {}

local function GetModApiExt()
	assert(modApiExt_internal, "Requires modApiExt installed.")
	
	return modApiExt_internal:getMostRecent()
end

-- adds an emitter to a tile,
-- even if it is (unbroken) ice or water.
-- should not be used while in tipimage.
function this.Add(effect, tile, emitter, dir, isTipImage, avoidIce)
	if not isTipImage then
		local terrain = Board:GetTerrain(tile)
		
		if terrain == TERRAIN_ICE then
			local tileHealth = IsTestMechScenario() and 0 or GetModApiExt().board:getTileHealth(tile)
			if tileHealth == 1 or avoidIce then
				terrain = nil
			end
		end
		
		if terrain == TERRAIN_WATER or terrain == TERRAIN_ICE then
			effect:AddScript("Board:SetTerrain(Point(".. tile.x ..",".. tile.y .."), TERRAIN_ROAD)")
		end
		
		effect:AddBurst(tile, emitter, dir)
		
		if terrain == TERRAIN_WATER or terrain == TERRAIN_ICE then
			effect:AddScript("Board:SetTerrain(Point(".. tile.x ..",".. tile.y .."), ".. terrain ..")")
		end
	else
		effect:AddBurst(tile, emitter, dir)
	end
end

return this