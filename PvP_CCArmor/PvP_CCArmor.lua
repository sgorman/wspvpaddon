-----------------------------------------------------------------------------------------------
-- Client Lua Script for PvP_CCArmor
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
require "Window"
require "Apollo"
require "GameLib"
require "Spell"
require "Unit"
require "Item"

local PvP_CCArmor = {}

function PvP_CCArmor:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function PvP_CCArmor:Init()
    Apollo.RegisterAddon(self)
end

local knEvadeResource = 7 -- the resource hooked to dodges (TODO replace with enum)

local eHealthColor =
{
	HealthInRed = 1,
	HealthInOrange = 2,
	HealthInGreen = 3
}

function PvP_CCArmor:OnLoad()
	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnEnteredCombat", self)
	Apollo.RegisterEventHandler("RefreshPvP_CCArmor", "OnFrameUpdate", self)
	Apollo.RegisterEventHandler("OptionsUpdated_PvP_CCArmor", "OnOptionsUpdated", self)

	Apollo.RegisterTimerHandler("CCArmorBrokenDisplayTimer", "OnCCArmorBrokenDisplayTimer", self)

	Apollo.CreateTimer("CCArmorBrokenDisplayTimer", 3, false)

    self.wndMain = Apollo.LoadForm("PvP_CCArmor.xml", "PvP_CCArmorForm", "FixedHudStratum", self)

	self.wndCCArmor = self.wndMain:FindChild("CCArmorContainer")

	self.bInCombat = false
	self.bBrokenCCArmorFadeTimer = false
	self.nLastCCArmorValue = 0

end

function PvP_CCArmor:OnConfigureStart()
end

function PvP_CCArmor:OnOptionsUpdated()
end

function PvP_CCArmor:OnFrameUpdate()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil then return end

	local tStats = unitPlayer:GetBasicStats()
	if tStats == nil then return end

	--Interrupt Armor
	self:UpdateCCArmor(unitPlayer:GetInterruptArmorValue(), unitPlayer:GetInterruptArmorMax())
end


function PvP_CCArmor:UpdateCCArmor(nCurr, nMax)
	if nMax == 0 and self.nLastCCArmorValue == 0 and not self.bBrokenCCArmorFadeTimer then
		self.wndCCArmor:Show(false)
		return
	else
		self.wndCCArmor:Show(true, true)
	end

	-- States
	if nMax == -1 then -- impervious
		self.wndCCArmor:SetSprite("sprResourceBar_InterruptFullShield")
		self.wndCCArmor:FindChild("CCRing"):SetSprite("")
		self.wndCCArmor:FindChild("CCText"):SetText("")
	elseif nCurr == 0 and nMax > 0 then -- just broke
		self.wndCCArmor:SetSprite("sprResourceBar_InterruptBroken")
		self.wndCCArmor:FindChild("CCRing"):SetSprite("sprResourceBar_InterruptCircleRed")
		self.wndCCArmor:FindChild("CCText"):SetText("")
		self.wndCCArmor:FindChild("CCArmorFlash"):SetSprite("sprResourceBar_InterruptCircleFlash")
		self.bBrokenCCArmorFadeTimer = true

		Apollo.StopTimer("CCArmorBrokenDisplayTimer")
		Apollo.StartTimer("CCArmorBrokenDisplayTimer")
	elseif nMax > 0 then -- have armor
		self.wndCCArmor:SetSprite("sprResourceBar_InterruptBG")
		self.wndCCArmor:FindChild("CCRing"):SetSprite("sprResourceBar_InterruptCircleBlue")
		self.wndCCArmor:FindChild("CCText"):SetText(nCurr)
		self.bBrokenCCArmorFadeTimer = false
	end

	if nCurr < self.nLastCCArmorValue and nCurr ~= 0 and nCurr ~= -1 then
		self.wndCCArmor:FindChild("CCArmorFlash"):SetSprite("sprResourceBar_InterruptCircleFlash")
	end

	self.nLastCCArmorValue = nCurr
end

function PvP_CCArmor:OnEnteredCombat(unit, bInCombat)
	if unit == GameLib.GetPlayerUnit() then
		self.bInCombat = bInCombat
	end
end

function PvP_CCArmor:OnCCArmorBrokenDisplayTimer()
	self.bBrokenCCArmorFadeTimer = false
end

local PvP_CCArmorInst = PvP_CCArmor:new()
PvP_CCArmorInst:Init()
