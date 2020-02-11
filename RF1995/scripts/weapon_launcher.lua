
local this = {attacks = {}}

lmn_Minelayer_Launcher = Skill:new{
	Self = "lmn_Minelayer_Launcher",
	Name = "MR Launcher",
	Class = "Ranged",
	Icon = "weapons/lmn_minelayer_launcher.png",
	Description = "Launches 2 rockets in a straight line, or over obstacles.",
	UpShot = "effects/lmn_minelayer_shotup_missile.png",
	ProjectileArt = "effects/lmn_minelayer_shot_missile",
	Range = INT_MAX,
	Attacks = 2,
	Damage = 1,
	PowerCost = 1,
	Upgrades = 2,
	UpgradeCost = {1, 2},
	UpgradeList = {"+1 Attack", "+2 Attacks"},
	CustomTipImage = "lmn_Minelayer_Launcher_Tip",
	TipImage = {
		CustomPawn = "lmn_MinelayerMech",
		CustomEnemy = "Spiderling1",
		Unit = Point(2,3),
		Enemy = Point(2,2),
		Mountain = Point(2,1),
		Enemy2 = Point(2,0),
		Target = Point(2,2),
		Second_Origin = Point(2,3),
		Second_Target = Point(2,0)
	}
}

lmn_Minelayer_Launcher_A = lmn_Minelayer_Launcher:new{
	Self = "lmn_Minelayer_Launcher_A",
	UpgradeDescription = "Increases number of rockets by 1",
	Attacks = 3,
	CustomTipImage = "lmn_Minelayer_Launcher_Tip_A",
	TipImage = shallow_copy(lmn_Minelayer_Launcher.TipImage)
}
lmn_Minelayer_Launcher_A.TipImage.CustomEnemy = "Scarab1"

lmn_Minelayer_Launcher_B = lmn_Minelayer_Launcher:new{
	Self = "lmn_Minelayer_Launcher_B",
	UpgradeDescription = "Increases number of rockets by 2",
	Attacks = 4,
	CustomTipImage = "lmn_Minelayer_Launcher_Tip_B",
	TipImage = shallow_copy(lmn_Minelayer_Launcher.TipImage)
}
lmn_Minelayer_Launcher_B.TipImage.CustomEnemy = "Scorpion1"

lmn_Minelayer_Launcher_AB = lmn_Minelayer_Launcher:new{
	Self = "lmn_Minelayer_Launcher_AB",
	Attacks = 5,
	CustomTipImage = "lmn_Minelayer_Launcher_Tip_AB",
	TipImage = shallow_copy(lmn_Minelayer_Launcher.TipImage)
}
lmn_Minelayer_Launcher_AB.TipImage.CustomEnemy = "Scarab2"

local function GetYVelocity(distance)
	return 6 + 16 * (distance / 8)
end

-- returns true if pawn will die on this tile
local function InPit(pawn)
	local tile = pawn:GetSpace()
	local terrain = Board:GetTerrain(tile)
	
	local surviveHole = pawn:IsFlying() and not pawn:IsFrozen()
	local surviveWater = _G[pawn:GetType()].Massive or surviveHole
	
	return
		(terrain == TERRAIN_WATER and not surviveWater) or
		(terrain == TERRAIN_HOLE and not surviveHole)
end

local function GetTileHealth(tile, isTipImage)
	if
		GetCurrentMission()			and
		not IsTestMechScenario()	and
		not isTipImage
	then
		return this.modApiExt.board:getTileHealth(tile)
	end
	
	return 1
end

function lmn_Minelayer_Launcher:GetTargetArea(point)
	local ret = PointList()
	
	for i = DIR_START, DIR_END do
		for k = 1, self.Range do
			local curr = DIR_VECTORS[i]*k + point
			if not Board:IsValid(curr) then
				break
			end
			ret:push_back(curr)
		end
	end
	
	return ret
end

-- custom GetProjectileEnd, for multishot purposes.
function lmn_Minelayer_Launcher:GetProjectileEnd(p1, p2)
	assert(type(p1) == 'userdata')
	assert(type(p1.x) == 'number')
	assert(type(p1.y) == 'number')
	assert(type(p2) == 'userdata')
	assert(type(p2.x) == 'number')
	assert(type(p2.y) == 'number')
	
	local dir = GetDirection(p2 - p1)
	local target = p1
	
	for k = 1, self.Range do
		curr = p1 + DIR_VECTORS[dir] * k
		
		if not Board:IsValid(curr) then
			break
		end
		
		target = curr
		
		if Board:IsBlocked(target, PATH_PROJECTILE) then
			local pawn = Board:GetPawn(target)
			if	not pawn					or
				pawn:GetHealth() > 0		or	-- healthy pawns block shots
				pawn:IsMech()				or	-- mechs always block shots
				_G[pawn:GetType()].Corpse		-- corpses always block shots
			then
				break
			end
		end
	end
	
	return target
end

-- recursive function being run through scripts,
-- to ensure proper multishot functionality.
function lmn_Minelayer_Launcher:FireWeapon(p1, p2, useArtillery, isTipImage)
	local shooter = Board:GetPawn(p1)
	if not shooter then
		return
	end
	
	local effect = SkillEffect()
	effect.iOwner = shooter:GetId()
	effect.piOrigin = p1
	
	this.effectBurst.Add(effect, p1, "lmn_Emitter_Minelayer_Launcher_Small", DIR_NONE, isTipImage)
	this.effectBurst.Add(effect, p1, "lmn_Emitter_Minelayer_Launcher_Small_Front", DIR_NONE, isTipImage)
	
	local id = shooter:GetId()
	local dir = GetDirection(p2 - p1)
	local target
	
	----------------------
	-- attack calculation
	----------------------
	local attacksLeft = this.attacks[id]
	local attacks = 1
	
	if useArtillery then
		target = p2
		attacks = attacksLeft
	else
		target = self:GetProjectileEnd(p1, p2)
		
		local pawn = Board:GetPawn(target)
		
		if pawn then
			local health = pawn:GetHealth()
			-- unload shots into dead pawns.
			if health <= 0 then
				attacks = attacksLeft
			else
				local damage = self.Damage
				
				if pawn:IsAcid() then
					health = math.ceil(health / 2)
				elseif this.armorDetection.IsArmor(pawn) then
					damage = damage - 1
				end
				
				if pawn:IsShield() then
					health = health + 1
				end
				
				if pawn:IsFrozen() then
					health = health + 1
				end
				
				if Board:GetTerrain(target) == TERRAIN_ICE then
					local tileHealth = GetTileHealth(target, isTipImage)
					attacks = math.max(1, math.min(tileHealth, attacks))
				else
					if damage > 0 then
						attacks = health / damage
					else
						attacks = attacksLeft
					end
				end
			end
			
		elseif not Board:IsBlocked(target, PATH_PROJECTILE) then
			-- unload shots on empty tiles.
			attacks = attacksLeft
			
		elseif Board:IsUniqueBuilding(target) then
			attacks = attacksLeft
			
		else
			local terrain = Board:GetTerrain(target)
			local health = GetTileHealth(target, isTipImage)
			
			if Board:IsFrozen(target) then
				if terrain == TERRAIN_MOUNTAIN then
					attacks = health + 1
				elseif terrain == TERRAIN_BUILDING then
					attacks = 2
				end
			elseif terrain == TERRAIN_MOUNTAIN then
				attacks = health
			end
		end
	end
	
	local distance = p1:Manhattan(target)
	attacks = math.min(attacksLeft, attacks)
	this.attacks[id] = this.attacks[id] - attacks
	
	local time = 0
	local events = {}
	
	local function AddTrailWhile(func)
		while func() do
			while events[#events] and events[#events].time < time do
				this.effectBurst.Add(effect, events[#events].tile, events[#events].emitter, dir, isTipImage, target == events[#events].tile)
				table.remove(events, #events)
			end
			
			time = time + 0.1
			effect:AddDelay(0.1)
		end
	end
	
	---------------------
	-- damage resolution
	---------------------
	for i = 1, attacks do
		this.effectBurst.Add(effect, p1, "lmn_Emitter_Minelayer_Launcher_Big", DIR_NONE, isTipImage)
		this.effectBurst.Add(effect, p1, "lmn_Emitter_Minelayer_Launcher_Small_Front", DIR_NONE, isTipImage)
		this.effectBurst.Add(effect, p1, "lmn_Emitter_Minelayer_Launcher_Small_Front", DIR_NONE, isTipImage)
		effect:AddSound("/weapons/rocket_launcher")
		effect:AddSound("/weapons/boulder_throw")
		
		local weapon = SpaceDamage(target, self.Damage)
		weapon.sSound = "/impact/generic/explosion"
		
		if useArtillery then
			weapon.sScript = "Board:AddAnimation(Point(".. target.x ..",".. target.y .."), 'ExploArt1', NO_DELAY)"
			this.worldConstants.SetHeight(effect, GetYVelocity(distance) * math.random(80, 120) / 100)
			effect:AddArtillery(weapon, self.UpShot, NO_DELAY)
			this.worldConstants.ResetHeight(effect)
		else
			local speed = math.random(55, 70) / 100
			
			weapon.sScript = "Board:AddAnimation(Point(".. target.x ..",".. target.y .."), 'ExploAir1', NO_DELAY)"
			this.worldConstants.SetSpeed(effect, speed)
			effect:AddProjectile(weapon, self.ProjectileArt, NO_DELAY)
			this.worldConstants.ResetSpeed(effect)
			
			for k = 0, distance do
				local iMax = 3
				for i = 1, iMax do
					table.insert(
						events,
						{
							time = time + 0.1 + (k - 1 + i/iMax) * 0.08 * this.worldConstants.GetDefaultSpeed() / speed,
							tile = p1 + DIR_VECTORS[dir] * k,
							emitter = "lmn_Emitter_Minelayer_Launcher_Trail"
						}
					)
				end
			end
			
			table.sort(events, function(a, b) return a.time > b.time end)
		end
		
		-- minimum delay between shots.
		-- can take longer due to board being resolved.
		local delay = time + math.random(5, 40) / 100
		
		AddTrailWhile(function() return time < delay end)
	end
	
	AddTrailWhile(function() return #events > 0 end)
	
	-------------------
	-- continue attack
	-------------------
	if this.attacks[id] > 0 then
		
		effect:AddScript(string.format([[
			modApi:conditionalHook(
				function()
					return not Board or not Board:IsBusy();
				end,
				function()
					if Board then
						local p1 = %s;
						local p2 = %s;
						_G[%q]:FireWeapon(p1, p2, %s, %s);
					end
				end
			)
		]], p1:GetString(), p2:GetString(), self.Self, tostring(useArtillery), tostring(isTipImage)))
	else
		------------------
		-- end resolution
		------------------
		
		if isTipImage then
			effect:AddDelay(1.3)
		end
		
		this.attacks[id] = nil
	end
	
	Board:AddEffect(effect)
end

function lmn_Minelayer_Launcher:GetSkillEffect(p1, p2, parentSkill, isTipImage)
	local ret = SkillEffect()
	local shooter = Board:GetPawn(p1)
	if not shooter then
		return ret
	end
	
	local id = shooter:GetId()
	local distance = p1:Manhattan(p2)
	local dir = GetDirection(p2 - p1)
	local useArtillery = false
	this.attacks[id] = self.Attacks
	
	for k = 1, distance - 1 do
		if Board:IsBlocked(DIR_VECTORS[dir]*k + p1, PATH_PROJECTILE) then
			useArtillery = true
		end
	end
	
	----------------
	-- damage marks
	----------------
	if isTipImage then
		-- mark tipimage.
		if useArtillery then
			local tile = self.TipImage.Second_Target
			
			this.worldConstants.SetHeight(ret, 0)
			ret:AddArtillery(SpaceDamage(tile), "", NO_DELAY)
			this.worldConstants.ResetHeight(ret)
			
			local mark = SpaceDamage(tile, self.Attacks)
			this.effectPreview:AddDamage(ret, mark)
		else
			this.worldConstants.SetSpeed(ret, 999)
			ret:AddProjectile(SpaceDamage(self.TipProjectileEnd), "", NO_DELAY)
			this.worldConstants.ResetSpeed(ret)
			
			for i, v in ipairs(self.TipMarks) do
				local tile = v[1]
				local damage = v[2]
				local mark = SpaceDamage(tile, damage)
				mark.sImageMark = "combat/lmn_minelayer_preview_"
				
				if tile ~= self.TipProjectileEnd then
					mark.sImageMark = mark.sImageMark .."arrow_"
				end
				
				mark.sImageMark = mark.sImageMark .. damage ..".png"
				
				this.effectPreview:AddDamage(ret, mark)
				
				-- hack to replace mountain we just did damage to.
				if tile == self.TipProjectileEnd then
					ret:AddScript("Board:SetTerrain(".. tile:GetString() ..", TERRAIN_MOUNTAIN)")
				end
			end
		end
	else
		this.hoveredTile = p2
		
		local vBoard = this.virtualBoard.new()
		local target = p1
		for i = 1, self.Attacks do
			
			if useArtillery then
				target = p2
			else
				-- GetProjectileEnd
				for k = 1, self.Range do
					local curr = p1 + DIR_VECTORS[dir] * k
					if not Board:IsValid(curr) then
						break
					end
					
					target = curr
					
					if vBoard:IsBlocked(curr) then
						break
					end
				end
			end
			
			-- apply damage to virtual board.
			vBoard:DamageSpace(SpaceDamage(target, self.Damage))
		end
		
		if useArtillery then
			-- preview projectile path.
			this.worldConstants.SetHeight(ret, 0)
			ret:AddArtillery(SpaceDamage(target), "", NO_DELAY)
			this.worldConstants.ResetHeight(ret)
		else
			-- preview projectile path.
			this.worldConstants.SetSpeed(ret, 999)
			ret:AddProjectile(SpaceDamage(target), "", NO_DELAY)
			this.worldConstants.ResetSpeed(ret)
		end
		
		-- mark tiles with vBoard state.
		vBoard:MarkDamage(ret, id, "lmn_Minelayer_Launcher")
	end
	
	---------------------
	-- damage resolution
	---------------------
	ret:AddScript([[
		local p1 = ]].. p1:GetString() ..[[;
		local p2 = ]].. p2:GetString() ..[[;
		_G[']].. self.Self ..[[']:FireWeapon(p1, p2, ]].. tostring(useArtillery) ..",".. tostring(isTipImage) ..[[);
	]])
	
	return ret
end

lmn_Minelayer_Launcher_Tip = lmn_Minelayer_Launcher:new{
	Self = "lmn_Minelayer_Launcher_Tip",
	TipProjectileEnd = Point(2,1),
	TipMarks = {
		{Point(2,2), 1},
		{Point(2,1), 1}
	}
}

lmn_Minelayer_Launcher_Tip_A = lmn_Minelayer_Launcher_A:new{
	Self = "lmn_Minelayer_Launcher_Tip_A",
	TipProjectileEnd = Point(2,1),
	TipMarks = {
		{Point(2,2), 2},
		{Point(2,1), 1}
	}
}

lmn_Minelayer_Launcher_Tip_B = lmn_Minelayer_Launcher_B:new{
	Self = "lmn_Minelayer_Launcher_Tip_B",
	TipProjectileEnd = Point(2,1),
	TipMarks = {
		{Point(2,2), 3},
		{Point(2,1), 1}
	}
}

lmn_Minelayer_Launcher_Tip_AB = lmn_Minelayer_Launcher_AB:new{
	Self = "lmn_Minelayer_Launcher_Tip_AB",
	TipProjectileEnd = Point(2,1),
	TipMarks = {
		{Point(2,2), 4},
		{Point(2,1), 1}
	}
}

function lmn_Minelayer_Launcher_Tip:GetSkillEffect(p1, p2, parentSkill)
	return lmn_Minelayer_Launcher.GetSkillEffect(self, p1, p2, parentSkill, true)
end

lmn_Minelayer_Launcher_Tip_A.GetSkillEffect = lmn_Minelayer_Launcher_Tip.GetSkillEffect
lmn_Minelayer_Launcher_Tip_B.GetSkillEffect = lmn_Minelayer_Launcher_Tip.GetSkillEffect
lmn_Minelayer_Launcher_Tip_AB.GetSkillEffect = lmn_Minelayer_Launcher_Tip.GetSkillEffect

function this:init(mod)
	local this = self
	
	require(mod.scriptPath .."shop"):addWeapon({
		id = "lmn_Minelayer_Launcher",
		desc = "Adds MR Launcher to the store."
	})
	
	self.armorDetection = require(mod.scriptPath .."armorDetection")
	self.worldConstants = require(mod.scriptPath .."worldConstants")
	self.virtualBoard = require(mod.scriptPath .."virtualBoard")
	self.effectPreview = require(mod.scriptPath .."effectPreview")
	self.effectBurst = require(mod.scriptPath .."effectBurst")
	self.weaponHover = require(mod.scriptPath .."weaponHover")
	self.weaponArmed = require(mod.scriptPath .."weaponArmed")
	
	local function onHover(self, type)
		Values.y_velocity = GetYVelocity(3)
	end
	
	local function onUnhover(self, type)
		if
			not this.weaponArmed:IsCurrent(type) and
			not this.weaponHover:IsCurrent(type)
		then
			Values.y_velocity = this.worldConstants.GetDefaultHeight()
		end
	end
	
	self.weaponHover:Add("lmn_Minelayer_Launcher", onHover, onUnhover)
	self.weaponHover:Add("lmn_Minelayer_Launcher_A", onHover, onUnhover)
	self.weaponHover:Add("lmn_Minelayer_Launcher_B", onHover, onUnhover)
	self.weaponHover:Add("lmn_Minelayer_Launcher_AB", onHover, onUnhover)
	
	self.weaponArmed:Add("lmn_Minelayer_Launcher", onHover, onUnhover)
	self.weaponArmed:Add("lmn_Minelayer_Launcher_A", onHover, onUnhover)
	self.weaponArmed:Add("lmn_Minelayer_Launcher_B", onHover, onUnhover)
	self.weaponArmed:Add("lmn_Minelayer_Launcher_AB", onHover, onUnhover)
	
	modApi:appendAsset("img/weapons/lmn_minelayer_launcher.png", mod.resourcePath .."img/weapons/launcher.png")
	modApi:appendAsset("img/effects/lmn_minelayer_shot_missile_U.png", mod.resourcePath .."img/effects/shot_missile_U.png")
	modApi:appendAsset("img/effects/lmn_minelayer_shot_missile_R.png", mod.resourcePath .."img/effects/shot_missile_R.png")
	modApi:appendAsset("img/effects/lmn_minelayer_shotup_missile.png", mod.resourcePath .."img/effects/shotup_missile.png")
	
	for i = 1, 4 do
		modApi:appendAsset("img/combat/lmn_minelayer_preview_arrow_".. i ..".png", mod.resourcePath .."img/combat/preview_arrow_".. i ..".png")
		Location["combat/lmn_minelayer_preview_arrow_".. i ..".png"] = Point(-16, 0)
	end
	
	local angle_variance = 80
	local angle_3 = 218 + angle_variance / 2
	
	lmn_Emitter_Minelayer_Launcher_Small = Emitter_Missile:new{
		image = "effects/smoke/art_smoke.png",
		max_alpha = 0.4,
		x = -8,
		y = 15,
		angle = angle_3,
		angle_variance = angle_variance,
		variance = 0,
		variance_x = 10,
		variance_y = 7,
		burst_count = 1,
		lifespan = 1.8,
		speed = 0.4,
		layer = LAYER_BACK
	}
	lmn_Emitter_Minelayer_Launcher_Small_Front = lmn_Emitter_Minelayer_Launcher_Small:new{layer = LAYER_FRONT, max_alpha = 0.2}
	lmn_Emitter_Minelayer_Launcher_Big = lmn_Emitter_Minelayer_Launcher_Small:new{burst_count = 5}
	
	lmn_Emitter_Minelayer_Launcher_Trail = Emitter_Missile:new{
		image = "effects/smoke/art_smoke.png",
		max_alpha = 0.4,
		y = 10,
		variance = 0,
		variance_x = 5,
		variance_y = 8,
		burst_count = 3,
		layer = LAYER_FRONT
	}
end

function this:load(modApiExt)
	self.modApiExt = modApiExt
	
	modApi:addMissionUpdateHook(function()
		local skill, skillType = self.weaponArmed:GetCurrent()
		
		if
			skillType == "lmn_Minelayer_Launcher"	or
			skillType == "lmn_Minelayer_Launcher_A"	or
			skillType == "lmn_Minelayer_Launcher_B"	or
			skillType == "lmn_Minelayer_Launcher_AB"
		then
			if
				not self.weaponHover:GetCurrent() and
				self.hoveredTile
			then
				local pawn = self.weaponArmed:GetPawn()
				if pawn then
					local distance = pawn:GetSpace():Manhattan(self.hoveredTile)
					Values.y_velocity = GetYVelocity(distance)
				end
			end
		end
	end)
end

return this