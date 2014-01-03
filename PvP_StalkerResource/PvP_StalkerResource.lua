-----------------------------------------------------------------------------------------------
-- Client Lua Script for StalkerResource
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "GameLib"
require "Unit"

local StalkerResource = {}

local karResource6ToSprite =
{
	"", -- No Suit
	"Icon_SkillMind_UI_espr_rsrgnc",
	"Icon_SkillShadow_UI_SM_crrptngprsnc",
	"Icon_SkillShadow_UI_SM_ghstshft",
	"Icon_ShieldBlock"
}

local karStanceToColor =
{
	"ffffffff",
	"2x:ff99ffff",
	"ff999999",
}

function StalkerResource:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function StalkerResource:Init()
	Apollo.RegisterAddon(self)
end

function StalkerResource:OnLoad()
	Apollo.RegisterEventHandler("CharacterCreated", "OnCharacterCreated", self)

	if GameLib.GetPlayerUnit() then
		self:OnCharacterCreated()
	end
end

function StalkerResource:OnCharacterCreated()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer:GetClassId() ~= GameLib.CodeEnumClass.Stalker then
		return
	end

	Apollo.RegisterEventHandler("VarChange_FrameCount", "OnFrame", self)

	self.wndResourceBar = Apollo.LoadForm("PvP_StalkerResource.xml", "StalkerResourceForm", "FixedHudStratum", self)
	self.wndResourceBar:ToFront()
end

function StalkerResource:OnFrame(varName, cnt)
	if not self.wndResourceBar:IsValid() then
		return
	end

	local unitPlayer = GameLib.GetPlayerUnit()

	local nLeft, nTop, nRight, nBottom = self.wndResourceBar:GetRect()
	Apollo.SetGlobalAnchor("CastingBarBottom", 0.0, nTop - 10, true)


	for idx, wndActuator in pairs({self.wndResourceBar:FindChild("ActuatorLeft"), self.wndResourceBar:FindChild("ActuatorRight")}) do
		local nResource = unitPlayer:GetResource(idx) -- Left = Resource1, Right = Resource2
		local nResourceMax = unitPlayer:GetMaxResource(idx)
		local nOneFourth = nResourceMax / 4

		wndActuator:FindChild("ActuatorCover"):Show(nResource >= nResourceMax)
		wndActuator:FindChild("ActuatorFill1"):SetMax(nOneFourth)
		wndActuator:FindChild("ActuatorFill2"):SetMax(nOneFourth)
		wndActuator:FindChild("ActuatorFill3"):SetMax(nOneFourth)
		wndActuator:FindChild("ActuatorFill4"):SetMax(nOneFourth)

		if nResource == nResourceMax then
			wndActuator:FindChild("ActuatorFill1"):SetProgress(0)
			wndActuator:FindChild("ActuatorFill2"):SetProgress(0)
			wndActuator:FindChild("ActuatorFill3"):SetProgress(0)
			wndActuator:FindChild("ActuatorFill4"):SetProgress(0)
		else
			--[[ Progressive Fill
			wndActuator:FindChild("ActuatorFill1"):SetProgress(nResource)
			wndActuator:FindChild("ActuatorFill2"):SetProgress(nResource - nOneFourth)
			wndActuator:FindChild("ActuatorFill3"):SetProgress(nResource - (nOneFourth * 2))
			wndActuator:FindChild("ActuatorFill4"):SetProgress(nResource - (nOneFourth * 3))
			]]--

			-- Chunk Fill
			wndActuator:FindChild("ActuatorFill1"):SetProgress(nOneFourth)
			wndActuator:FindChild("ActuatorFill2"):SetProgress(nOneFourth)
			wndActuator:FindChild("ActuatorFill3"):SetProgress(nOneFourth)
			wndActuator:FindChild("ActuatorFill4"):SetProgress(nOneFourth)
			wndActuator:FindChild("ActuatorFill1"):Show(nResource > nOneFourth)
			wndActuator:FindChild("ActuatorFill2"):Show(nResource > (nOneFourth * 2))
			wndActuator:FindChild("ActuatorFill3"):Show(nResource > (nOneFourth * 3))
			wndActuator:FindChild("ActuatorFill4"):Show(nResource >= nResourceMax)
		end

		--Flash if the last value was < Max
		local nLastValue = wndActuator:FindChild("ActuatorFlash"):GetData()
		if nLastValue and nLastValue < nResourceMax and nResource == nResourceMax then
			wndActuator:FindChild("ActuatorCover"):SetSprite("CRB_StalkerSprites:spr_Stalker_ActuatorFill")
			wndActuator:FindChild("ActuatorFlash"):SetSprite("CRB_StalkerSprites:spr_Stalker_ActuatorFlash")
		end
		wndActuator:FindChild("ActuatorFlash"):SetData(nResource)
	end
	
	EnergyResource = GameLib.GetPlayerUnit():GetResource(3)
	
	if EnergyResource >= 70 then
		self.wndResourceBar:FindChild("EnergyMeter"):SetTextColor("green")
	elseif EnergyResource >= 35 then
		self.wndResourceBar:FindChild("EnergyMeter"):SetTextColor("yellow")
	elseif EnergyResource >= 0 then
		self.wndResourceBar:FindChild("EnergyMeter"):SetTextColor("red")
	end
	
	----------Resource 3
	local nResource3 = unitPlayer:GetResource(3)
	local nResource3Max = unitPlayer:GetMaxResource(3)

	self.wndResourceBar:FindChild("CenterMeter"):SetMax(nResource3Max)
	self.wndResourceBar:FindChild("CenterMeter"):SetProgress(nResource3)
	self.wndResourceBar:FindChild("CenterMeterText"):SetText(String_GetWeaselString(Apollo.GetString("CRB_Percent"), nResource3))
	self.wndResourceBar:FindChild("EnergyMeter"):SetText(String_GetWeaselString(Apollo.GetString("CRB_Percent"), nResource3))
	local nStanceIdx = GameLib.GetCurrentClassInnateAbilityIndex() or 1
	self.wndResourceBar:FindChild("CenterMeter"):SetBarColor(karStanceToColor[nStanceIdx])
	self.wndResourceBar:FindChild("NewStalkerResourceIconFrame"):Show(self:DrawGlowForBuff(unitPlayer))
	
	self.wndResourceBar:FindChild("CenterMeter"):SetMax(nResource3Max)
	self.wndResourceBar:FindChild("CenterMeter"):SetProgress(nResource3)
	self.wndResourceBar:FindChild("CenterMeterText"):SetText(String_GetWeaselString(Apollo.GetString("CRB_Percent"), nResource3))

	local nStanceIdx = GameLib.GetCurrentClassInnateAbilityIndex() or 1
	self.wndResourceBar:FindChild("CenterMeter"):SetBarColor(karStanceToColor[nStanceIdx])

	self.wndResourceBar:FindChild("NewStalkerResourceIconFrame"):Show(self:DrawGlowForBuff(unitPlayer))
end

function StalkerResource:DrawGlowForBuff(unitPlayer)
	local nResource6 = unitPlayer:GetResource(6)
	if nResource6 >= 2 and nResource6 <= 5 then
		self.wndResourceBar:FindChild("NewStalkerResourceIcon"):SetSprite(karResource6ToSprite[nResource6])
	end
	return nResource6 >= 2 and nResource6 <= 5
end

local StalkerResourceInst = StalkerResource:new()
StalkerResourceInst:Init()
