
local this = {}

lmn_JeepMech = Pawn:new{
	Name = "Jeep",
	Class = "Science",
	Health = 1,
	MoveSpeed = 5,
	Image = "lmn_MechJeep",
	ImageOffset = 1,
	SkillList = { "lmn_Jeep_Grenade" },
	SoundLocation = "/support/civilian_truck/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
}

lmn_Jeep_Grenade = Skill:new{
	Name = "Hand Grenades",
	Class = "Science",
	Icon = "weapons/lmn_jeep_grenade.png",
	Description = "Lobs a grenade at one of the 8 surrounding tiles.",
	UpShot = "effects/lmn_shotup_jeep_grenade.png",
	Range = 1,
	Damage = 2,
	Push = 0,
	PowerCost = 1,
	Y_Velocity = 14,
	Upgrades = 2,
	UpgradeCost = {1, 3},
	UpgradeList = {"Push", "+2 Damage"},
	LaunchSound = "/weapons/raining_volley_tile",
	ImpactSound = "/impact/generic/explosion",
	TipImage = {
		CustomPawn = "lmn_JeepMech",
		Unit = Point(2,3),
		Enemy = Point(2,2),
		Enemy2 = Point(3,2),
		Target = Point(3,2),
		Second_Origin = Point(2,3),
		Second_Target = Point(2,2),
	}
}

function lmn_Jeep_Grenade:GetTargetArea(point)
	local ret = PointList()
	local targets = {
		Point(-1,-1), Point(-1, 0), Point(-1, 1),
		Point( 0,-1), Point( 0, 1),
		Point( 1,-1), Point( 1, 0), Point( 1, 1)
	}
	
	for k = 1, #targets do
		if Board:IsValid(point + targets[k]) then
			ret:push_back(point + targets[k])
		end
	end
	
	return ret
end

function lmn_Jeep_Grenade:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	
	local damage = SpaceDamage(p2, self.Damage)
	damage.sAnimation = "explo_fire1"
	ret:AddArtillery(damage, self.UpShot)
	ret:AddBounce(p2, 3)
	
	if self.Push == 1 then
		for i = DIR_START, DIR_END do
			local curr = DIR_VECTORS[i] + p2
			damage = SpaceDamage(curr, 0)
			damage.iPush = i
			damage.sAnimation = "exploout0_".. i
			ret:AddDamage(damage)
		end
	end
	
	return ret
end

lmn_Jeep_Grenade_A = lmn_Jeep_Grenade:new{
	UpgradeDescription = "Push adjacent tiles.",
	Push = 1,
}

lmn_Jeep_Grenade_B = lmn_Jeep_Grenade:new{
	UpgradeDescription = "Increases damage by 2.",
	ImpactSound = "/impact/generic/explosion_large",
	Damage = 4,
}

lmn_Jeep_Grenade_AB = lmn_Jeep_Grenade:new{
	ImpactSound = "/impact/generic/explosion_large",
	Damage = 4,
	Push = 1,
}

function this:init(mod)
	local this = self
	
	require(mod.scriptPath .."shop"):addWeapon({
		id = "lmn_Jeep_Grenade",
		desc = "Adds Hand Grenades to the store."
	})
	
	lmn_JeepMech.ImageOffset = require(mod.scriptPath .."colorMaps").Get(mod.id)
	require(mod.scriptPath .."nonMassiveDeployWarning"):AddPawn("lmn_JeepMech")
	
	self.worldConstants = require(mod.scriptPath .."worldConstants")
	self.weaponHover = require(mod.scriptPath .."weaponHover")
	self.weaponArmed = require(mod.scriptPath .."weaponArmed")
	
	local function onHover(self, type)
		Values.y_velocity = self.Y_Velocity
	end
	
	local function onUnhover(self, type)
		if
			not this.weaponHover:IsCurrent(type) and
			not this.weaponArmed:IsCurrent(type)
		then
			Values.y_velocity = this.worldConstants.GetDefaultHeight()
		end
	end
	
	self.weaponHover:Add("lmn_Jeep_Grenade", onHover, onUnhover)
	self.weaponHover:Add("lmn_Jeep_Grenade_A", onHover, onUnhover)
	self.weaponHover:Add("lmn_Jeep_Grenade_B", onHover, onUnhover)
	self.weaponHover:Add("lmn_Jeep_Grenade_AB", onHover, onUnhover)
	
	self.weaponArmed:Add("lmn_Jeep_Grenade", onHover, onUnhover)
	self.weaponArmed:Add("lmn_Jeep_Grenade_A", onHover, onUnhover)
	self.weaponArmed:Add("lmn_Jeep_Grenade_B", onHover, onUnhover)
	self.weaponArmed:Add("lmn_Jeep_Grenade_AB", onHover, onUnhover)
	
	modApi:appendAsset("img/units/player/lmn_mech_jeep.png", mod.resourcePath .."img/units/player/jeep.png")
	modApi:appendAsset("img/units/player/lmn_mech_jeep_a.png", mod.resourcePath .."img/units/player/jeep_a.png")
	modApi:appendAsset("img/units/player/lmn_mech_jeep_w.png", mod.resourcePath .."img/units/player/jeep_w.png")
	modApi:appendAsset("img/units/player/lmn_mech_jeep_broken.png", mod.resourcePath .."img/units/player/jeep_broken.png")
	modApi:appendAsset("img/units/player/lmn_mech_jeep_w_broken.png", mod.resourcePath .."img/units/player/jeep_w_broken.png")
	modApi:appendAsset("img/units/player/lmn_mech_jeep_ns.png", mod.resourcePath .."img/units/player/jeep_ns.png")
	modApi:appendAsset("img/units/player/lmn_mech_jeep_h.png", mod.resourcePath .."img/units/player/jeep_h.png")
	
	modApi:appendAsset("img/effects/lmn_shotup_jeep_grenade.png", mod.resourcePath .."img/effects/shotup_grenade.png")
	modApi:appendAsset("img/weapons/lmn_jeep_grenade.png", mod.resourcePath .."img/weapons/grenade.png")
	
	setfenv(1, ANIMS)
	lmn_MechJeep =			MechUnit:new{ Image = "units/player/lmn_mech_jeep.png", PosX = -11, PosY = 6 }
	lmn_MechJeepa =			lmn_MechJeep:new{ Image = "units/player/lmn_mech_jeep_a.png", PosY = 5, NumFrames = 2 }
	lmn_MechJeep_broken =	lmn_MechJeep:new{ Image = "units/player/lmn_mech_jeep_broken.png" }
	lmn_MechJeepw =			lmn_MechJeep:new{ Image = "units/player/lmn_mech_jeep_w.png", PosY = 13 }
	lmn_MechJeepw_broken =	lmn_MechJeepw:new{ Image = "units/player/lmn_mech_jeep_w_broken.png" }
	lmn_MechJeep_ns =		MechIcon:new{ Image = "units/player/lmn_mech_jeep_ns.png" }
end

function this:load(modApiExt)
	
end

return this