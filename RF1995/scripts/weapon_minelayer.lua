
local this = {}

lmn_Minelayer_Mine = Skill:new{
	Name = "Proximity Mines",
	Class = "Ranged",
	Icon = "weapons/lmn_minelayer_mine.png",
	Description = "Passive Effect\n\nLeave a mine after moving.",
	Damage = 3,
	PowerCost = 0,
	Upgrades = 1,
	MineImmunity = false,
	UpgradeCost = {1},
	UpgradeList = {"Minesweeper"},
	GetTargetArea = function () return PointList() end,
	CustomTipImage = "lmn_Minelayer_Mine_Tip",
	TipImage = {
		CustomPawn = "lmn_MinelayerMech",
		Unit = Point(2,3),
		Target = Point(2,1),
	}
}

function lmn_Minelayer_Mine:SuppressDialog(duration)
	this.suppressDialog:AddEvent("Mech_ShieldDown")
	this.suppressDialog:AddEvent("PilotDeath")
	
	if duration and duration >= 0 then
		modApi:scheduleHook(duration, function()
			self:UnsuppressDialog()
		end)
	end
end

function lmn_Minelayer_Mine:UnsuppressDialog()
	this.suppressDialog:RemEvent("Mech_ShieldDown")
	this.suppressDialog:RemEvent("PilotDeath")
end

function lmn_Minelayer_Mine:SaveOrigin(pawn)
	this.pawnState:Save(pawn)
	this.tileState_Layer:Save(pawn:GetSpace())
end

function lmn_Minelayer_Mine:SaveDestination(tile)
	this.tileState_Sweeper:Save(tile)
end

lmn_Minelayer_Mine_A = lmn_Minelayer_Mine:new{
	UpgradeDescription = "All allies gain immunity to mines.",
	MineImmunity = true,
	CustomTipImage = "lmn_Minelayer_Mine_Tip_A",
}

local function IsMinelayer(pawn)
	return
		this.armorDetection.HasPoweredWeapon(pawn, "lmn_Minelayer_Mine")   or
		this.armorDetection.HasPoweredWeapon(pawn, "lmn_Minelayer_Mine_A")
end

local function HasMinesweeper(pawn)
	if	pawn:IsEnemy()		or
		not pawn:IsMech()
	then
		return false
	end
	
	for _, id in ipairs(extract_table(Board:GetPawns(TEAM_MECH))) do
		if this.armorDetection.HasPoweredWeapon(Board:GetPawn(id), "lmn_Minelayer_Mine_A") then
			return true
		end
	end
	
	return false
end

-----------------------
-- move skill override
-----------------------
local oldMoveGetSkillEffect = Move.GetSkillEffect
function Move:GetSkillEffect(p1, p2, ...)
	local ret = SkillEffect()
	
	if IsMinelayer(Pawn) then
		local damage = SpaceDamage(p1)
		damage.sItem = "lmn_Minelayer_Item_Mine"
		damage.sImageMark = "combat/lmn_minelayer_mark_mine_small.png"
		damage.sSound = "/impact/generic/grapple"
		ret:AddDamage(damage)
		
		ret:AddScript("lmn_Minelayer_Mine:SaveOrigin(Board:GetPawn(".. Pawn:GetId() .."))")
	end
	
	origMove = extract_table(oldMoveGetSkillEffect(self, p1, p2, ...).effect)
	for _, v in ipairs(origMove) do
		ret.effect:push_back(v)
	end
	
	if HasMinesweeper(Pawn) and Board:IsDangerousItem(p2) then
		local damage = SpaceDamage(p2)
		damage.sImageMark = "combat/icons/lmn_minelayer_icon_strikeout.png"
		ret:AddDamage(damage)
	end
	
	if Board:IsDangerousItem(p2) then
		ret:AddScript("lmn_Minelayer_Mine:SaveDestination(".. p2:GetString() ..")")
		--this.tileState_Sweeper:Save(p2)
	end
    
    return ret
end

------------
-- TipImage
------------
lmn_Minelayer_Mine_Tip = lmn_Minelayer_Mine:new{}
lmn_Minelayer_Mine_Tip_A = lmn_Minelayer_Mine_A:new{}

function lmn_Minelayer_Mine_Tip:GetTargetArea(point)
	return Board:GetReachable(point, Pawn:GetMoveSpeed(), Pawn:GetPathProf())
end

function lmn_Minelayer_Mine_Tip:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	
	local damage = SpaceDamage(p1)
	damage.sItem = "lmn_Minelayer_Item_Mine_Tip"
	damage.sImageMark = "combat/lmn_minelayer_mark_mine_small.png"
	ret:AddDamage(damage)
	
	if self.MineImmunity then
		damage = SpaceDamage(p2)
		damage.sItem = "lmn_Minelayer_Item_Mine_Tip_Explode"
		damage.sImageMark = "combat/lmn_minelayer_mine_small.png"
		Board:DamageSpace(damage)
		
		damage = SpaceDamage(p2)
		damage.sImageMark = "combat/icons/lmn_minelayer_minesweeper.png"
		ret:AddDamage(damage)
	end
	ret:AddMove(Board:GetPath(p1, p2, Pawn:GetPathProf()), FULL_DELAY)
	
	return ret
end

lmn_Minelayer_Mine_Tip_A.GetTargetArea = lmn_Minelayer_Mine_Tip.GetTargetArea
lmn_Minelayer_Mine_Tip_A.GetSkillEffect = lmn_Minelayer_Mine_Tip.GetSkillEffect

---------
-- items
---------
local damage = SpaceDamage(3)
damage.sSound = "/impact/generic/explosion"
damage.sAnimation = "ExploAir1"

lmn_Minelayer_Item_Mine = { Image = "combat/lmn_minelayer_mine_small.png", Damage = damage, Tooltip = "old_earth_mine", Icon = "combat/icons/icon_mine_glow.png"}

lmn_Minelayer_Item_Mine_Tip = shallow_copy(lmn_Minelayer_Item_Mine)
lmn_Minelayer_Item_Mine_Tip.Damage = SpaceDamage(0)

local damage = SpaceDamage(0)
damage.sAnimation = "ExploAir1"

lmn_Minelayer_Item_Mine_Tip_Explode = shallow_copy(lmn_Minelayer_Item_Mine)
lmn_Minelayer_Item_Mine_Tip_Explode.Damage = damage

--------
-- init
--------
function this:init(mod)
	self.id = mod.id .."_minelayer"
	
	require(mod.scriptPath .."shop"):addWeapon({
		id = "lmn_Minelayer_Mine",
		desc = "Adds Proximity Mines to the store."
	})
	
	self.armorDetection = require(mod.scriptPath .."armorDetection")
	self.suppressDialog = require(mod.scriptPath .."suppressDialog")
	self.mineDetection = require(mod.scriptPath .."mineDetection")
	self.pawnState = require(mod.scriptPath .."pawnState")(self.id)
	
	local tileState = require(mod.scriptPath .."tileState")
	self.tileState_Layer = tileState(self.id .."_layer")
	self.tileState_Sweeper = tileState(self.id .."_sweeper")
	
	self.mineDetection:init(mod)
	
	local function SweepMine(pawn)
		if HasMinesweeper(pawn) then
			lmn_Minelayer_Mine:SuppressDialog(1200)
			self.pawnState:Restore(pawn, true)
		--	self.mineDetection:RestoreTile(pawn:GetSpace())
		end
	end
	
	self.mineDetection:AddMineExplodedHook(SweepMine)
	self.mineDetection:AddFreezeMineExplodedHook(SweepMine)
	self.mineDetection:AddMineTileStateChangedHook(function(tile, currentState, savedState)
		if
			currentState.terrain == TERRAIN_WATER or
			currentState.terrain == TERRAIN_HOLE
		then
			Board:DamageSpace(SpaceDamage(tile, 1))
		end
	end)
	
	modApi:appendAsset("img/weapons/lmn_minelayer_mine.png", mod.resourcePath .."img/weapons/mine.png")
	modApi:appendAsset("img/combat/lmn_minelayer_mine_small.png", mod.resourcePath .."img/combat/mine_small.png")
	modApi:appendAsset("img/combat/lmn_minelayer_mark_mine_small.png", mod.resourcePath .."img/combat/mark_mine_small.png")
	modApi:appendAsset("img/combat/icons/lmn_minelayer_minesweeper.png", mod.resourcePath .."img/combat/icons/icon_minesweeper_glow.png")
	modApi:appendAsset("img/combat/icons/lmn_minelayer_icon_strikeout.png", mod.resourcePath .."img/combat/icons/icon_strikeout.png")
	
	Location["combat/lmn_minelayer_mine_small.png"] = Point(-8,3)
	Location["combat/lmn_minelayer_mark_mine_small.png"] = Point(-8,3)
	Location["combat/icons/lmn_minelayer_minesweeper.png"] = Location["combat/icons/icon_mine_glow.png"]
	Location["combat/icons/lmn_minelayer_icon_strikeout.png"] = Point(-13,10)
end

function this:load(modApiExt)
	self.mineDetection:load(modApiExt)
	
	modApiExt:addPawnUndoMoveHook(function(_, pawn, oldTile)
		if IsMinelayer(pawn) then
			lmn_Minelayer_Mine:SuppressDialog(1200)
			self.pawnState:Restore(pawn)
			self.pawnState:Clear(pawn)
			
			local tile = pawn:GetSpace()
			self.tileState_Layer:Restore(tile)
			self.tileState_Layer:Clear(tile)
		end
		
		self.tileState_Sweeper:Restore(oldTile)
		self.tileState_Sweeper:Clear(oldTile)
	end)
end

return this