
local mod =  {
	id = "lmn_RF1995",
	name = "RF1995",
	version = "1.3.7",
	modApiVersion = "2.3.0",
	icon = "img/icons/mod_icon.png",
	requirements = {}
}

function mod:init()
	self.modApiExt = require(self.scriptPath .."modApiExt/modApiExt")
	self.modApiExt:init()
	
	lmn_RF_CUtils = require(self.scriptPath .."libs/CUtils")
	
	self.colorMaps = require(self.scriptPath .."colorMaps")
	self.colorMaps.Add(
		self.id,
		{
			lights =         {236, 138,   9},
			main_highlight = {147,  95,  47},
			main_light =     { 90,  55,  27},
			main_mid =       { 41,  23,  15},
			main_dark =      { 20,  10,   6},
			metal_dark =     { 34,  32,  32},
			metal_mid =      { 76,  69,  61},
			metal_light =    {161, 146, 125}
		}
	)
	
	self.armorDetection = require(self.scriptPath .."armorDetection")
	self.weaponMarks = require(self.scriptPath .."weaponMarks")
	self.deployWarning = require(self.scriptPath .."nonMassiveDeployWarning")
	self.weaponHover = require(self.scriptPath .."weaponHover")
	self.weaponArmed = require(self.scriptPath .."weaponArmed")
	self.effectPreview = require(self.scriptPath .."effectPreview")
	self.virtualBoard = require(self.scriptPath .."virtualBoard")
	
	self.weaponMarks:init(self)
	self.deployWarning:init(self)
	self.weaponHover:init(self)
	self.weaponArmed:init(self)
	self.virtualBoard.init(self)
	
	self.jeep = require(self.scriptPath .."mech_jeep")
	self.tank = require(self.scriptPath .."mech_tank")
	self.helicopter = require(self.scriptPath .."mech_helicopter")
	self.minelayer = require(self.scriptPath .."mech_minelayer")
	
	self.jeep:init(self)
	self.tank:init(self)
	self.helicopter:init(self)
	self.minelayer:init(self)
end

function mod:load(options, version)
	self.modApiExt:load(self, options, version)
	
	self.virtualBoard.load(self.modApiExt, self.armorDetection, self.weaponMarks)
	self.weaponMarks:load(self.modApiExt)
	self.deployWarning:load(self.modApiExt)
	self.weaponArmed:load(self.modApiExt)
	require(self.scriptPath .."shop"):load(options)
	
	self.jeep:load(self.modApiExt)
	self.tank:load(self.modApiExt)
	self.helicopter:load(self.modApiExt)
	self.minelayer:load(self.modApiExt)
	
	math.randomseed(os.time()); math.random()
	local rng = math.random(1,4)
	local list = {}
	list[(rng + 0) % 4 + 1] = "lmn_JeepMech"
	list[(rng + 1) % 4 + 1] = "lmn_HelicopterMech"
	list[(rng + 2) % 4 + 1] = "lmn_TankMech"
	list[(rng + 3) % 4 + 1] = "lmn_MinelayerMech"
	
	modApi:addSquad(
		{
			"RF1995",
			list[1],
			list[2],
			list[3]
		},
		"RF1995",
		"How this squad got mixed up in the earth-saving business is unknown. "
		.. "Now where do the Vek hide their flag?"
		.. "\n\n(4th mech available in Custom and Random squads)",
		self.resourcePath .. "img/icons/squad_icon.png"
	)
	
	-- add a 4th member of our squad.
	table.insert(modApi.mod_squads[#modApi.mod_squads], list[4])
end

return mod