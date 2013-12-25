-----------------------------------------------------------------------------------------------
-- Client Lua Script for DashMeter
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
require "Window"
require "Apollo"
require "GameLib"
require "Spell"
require "Unit"
require "Item"

local DashMeter = {}

function DashMeter:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function DashMeter:Init()
    Apollo.RegisterAddon(self)
end

local knEvadeResource = 7 -- the resource hooked to dodges (TODO replace with enum)

local eEnduranceFlash =
{
	EnduranceFlashZero = 1,
	EnduranceFlashOne = 2,
	EnudranceFlashTwo = 3
}

function DashMeter:OnLoad()
	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnEnteredCombat", self)
	Apollo.RegisterEventHandler("RefreshDashMeter", "OnFrameUpdate", self)
	Apollo.RegisterEventHandler("OptionsUpdated_DashMeter", "OnOptionsUpdated", self)

	Apollo.RegisterTimerHandler("DashMeterTimer", "OnFrameUpdate", self)
	Apollo.RegisterTimerHandler("EnduranceDisplayTimer", "OnEnduranceDisplayTimer", self)

	Apollo.CreateTimer("DashMeterTimer", 0.5, true)
	--Apollo.CreateTimer("EnduranceDisplayTimer", 30, false) --TODO: Fix(?) This is perma-killing the display when DT dashing is disabled via the toggle

    self.wndMain = Apollo.LoadForm("PvP_DashMeter.xml", "DashMeterForm", "FixedHudStratum", self)
	self.wndEndurance = self.wndMain:FindChild("EnduranceContainer")
	self.wndDisableDash = self.wndEndurance:FindChild("DisableDashToggleContainer")
	
	self.bInCombat = false
	self.eEnduranceState = eEnduranceFlash.EnduranceFlashZero
	self.bEnduranceFadeTimer = false

	-- For flashes
	self.bHealthBarFlashes = g_InterfaceOptions and g_InterfaceOptions.Carbine.bHealthBarFlashes or true
	self.bFlashThrottle = false
	self.nLastHealthCurr = -1
	self.nLastShieldCurr = -1
	self.nLastAbsorbCurr = -1

	-- todo: make this selective
	self.wndEndurance:Show(false, true)
end

function DashMeter:OnOptionsUpdated()
end


function DashMeter:OnFrameUpdate()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil then return end

	local tStats = unitPlayer:GetBasicStats()
	if tStats == nil then return end

	-- Evades
	local nEvadeCurr = unitPlayer:GetResource(knEvadeResource)
	local nEvadeMax = unitPlayer:GetMaxResource(knEvadeResource)
	

	-- Evade Blocker
	-- TODO: Store this and only update when needed
	local bShowDoubleTapToDash = Apollo.GetConsoleVariable("player.showDoubleTapToDash")
	local bSettingDoubleTapToDash = Apollo.GetConsoleVariable("player.doubleTapToDash")

	self.wndDisableDash:Show(bShowDoubleTapToDash)
		
	self.wndDisableDash:FindChild("DisableDashToggleFlash"):Show(bShowDoubleTapToDash and not bSettingDoubleTapToDash)
	self.wndDisableDash:FindChild("DisableDashToggle"):SetCheck(bShowDoubleTapToDash and not bSettingDoubleTapToDash)
	self.wndDisableDash:SetTooltip(bSettingDoubleTapToDash and Apollo.GetString("HealthBar_DisableDoubleTapEvades") or Apollo.GetString("HealthBar_EnableDoubletapTooltip"))

	-- Show/Hide EnduranceEvade UI
	if self.bInCombat or nRunCurr ~= nRunMax or nEvadeCurr ~= nEvadeMax or bSettingDoubleTapToDash then
		Apollo.StopTimer("EnduranceDisplayTimer")
		self.bEnduranceFadeTimer = false
		self.wndEndurance:Show(true, true)
	elseif not self.bEnduranceFadeTimer then
		Apollo.StopTimer("EnduranceDisplayTimer")
		Apollo.StartTimer("EnduranceDisplayTimer")
		self.bEnduranceFadeTimer = true
	end
	
    self.wndEndurance:FindChild("RollsLeft"):SetText(nEvadeCurr / 100)
	if (nEvadeCurr / 100) >= 2 then
		self.wndEndurance:FindChild("RollsLeft"):SetTextColor("Green")
	elseif (nEvadeCurr / 100) >= 1 then
		self.wndEndurance:FindChild("RollsLeft"):SetTextColor("Yellow")
	elseif (nEvadeCurr / 100) >= 0 then
		self.wndEndurance:FindChild("RollsLeft"):SetTextColor("Red")
	end
	
end


function DashMeter:OnDisableDashToggle(wndHandler, wndControl)
	Apollo.SetConsoleVariable("player.doubleTapToDash", not wndControl:IsChecked())
	self.wndEndurance:FindChild("EvadeDisabledBlocker"):Show(not wndControl:IsChecked())
	self.wndDisableDash:FindChild("DisableDashToggleFlash"):Show(not wndControl:IsChecked())
	self:OnFrameUpdate()
end


local DashMeterInst = DashMeter:new()
DashMeterInst:Init()
