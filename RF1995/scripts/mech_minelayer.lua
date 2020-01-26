
local this = {}

lmn_MinelayerMech = Pawn:new{
	Name = "Rocket Artillery",
	Class = "Ranged",
	Health = 2,
	MoveSpeed = 2,
	Image = "lmn_MechMinelayer",
	ImageOffset = 1,
	SkillList = { "lmn_Minelayer_Launcher", "lmn_Minelayer_Mine" },
	SoundLocation = "/support/civilian_artillery/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
}

function this:init(mod)
	lmn_MinelayerMech.ImageOffset = require(mod.scriptPath .."colorMaps").Get(mod.id)
	require(mod.scriptPath .."nonMassiveDeployWarning"):AddPawn("lmn_MinelayerMech")
	
	self.weapon_launcher = require(mod.scriptPath .."weapon_launcher")
	self.weapon_minelayer = require(mod.scriptPath .."weapon_minelayer")
	self.weapon_launcher:init(mod)
	self.weapon_minelayer:init(mod)
	
	modApi:appendAsset("img/units/player/lmn_mech_minelayer.png", mod.resourcePath .."img/units/player/minelayer.png")
	modApi:appendAsset("img/units/player/lmn_mech_minelayer_a.png", mod.resourcePath .."img/units/player/minelayer_a.png")
	modApi:appendAsset("img/units/player/lmn_mech_minelayer_w.png", mod.resourcePath .."img/units/player/minelayer_w.png")
	modApi:appendAsset("img/units/player/lmn_mech_minelayer_broken.png", mod.resourcePath .."img/units/player/minelayer_broken.png")
	modApi:appendAsset("img/units/player/lmn_mech_minelayer_w_broken.png", mod.resourcePath .."img/units/player/minelayer_w_broken.png")
	modApi:appendAsset("img/units/player/lmn_mech_minelayer_ns.png", mod.resourcePath .."img/units/player/minelayer_ns.png")
	modApi:appendAsset("img/units/player/lmn_mech_minelayer_h.png", mod.resourcePath .."img/units/player/minelayer_h.png")
	
	setfenv(1, ANIMS)
	lmn_MechMinelayer =			MechUnit:new{ Image = "units/player/lmn_mech_minelayer.png", PosX = -14, PosY = 7 }
	lmn_MechMinelayera =		lmn_MechMinelayer:new{ Image = "units/player/lmn_mech_minelayer_a.png", NumFrames = 4 }
	lmn_MechMinelayer_broken =	lmn_MechMinelayer:new{ Image = "units/player/lmn_mech_minelayer_broken.png" }
	lmn_MechMinelayerw =		lmn_MechMinelayer:new{ Image = "units/player/lmn_mech_minelayer_w.png", PosY = 14 }
	lmn_MechMinelayerw_broken =	lmn_MechMinelayerw:new{ Image = "units/player/lmn_mech_minelayer_w_broken.png" }
	lmn_MechMinelayer_ns =		MechIcon:new{ Image = "units/player/lmn_mech_minelayer_ns.png" }
end

function this:load(modApiExt)
	local this = self
	self.modApiExt = modApiExt
	
	self.weapon_launcher:load(modApiExt)
	self.weapon_minelayer:load(modApiExt)
end

return this