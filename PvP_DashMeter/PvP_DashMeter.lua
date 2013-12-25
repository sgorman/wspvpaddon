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
	self:UpdateEvades(nEvadeCurr, nEvadeMax)

	-- Evade Blocker
	-- TODO: Store this and only update when needed
	local bShowDoubleTapToDash = Apollo.GetConsoleVariable("player.showDoubleTapToDash")
	local bSettingDoubleTapToDash = Apollo.GetConsoleVariable("player.doubleTapToDash")

	self.wndDisableDash:Show(bShowDoubleTapToDash)
	self.wndEndurance:FindChild("EvadeFlashSprite"):Show(bShowDoubleTapToDash and bSettingDoubleTapToDash)
	self.wndEndurance:FindChild("EvadeDisabledBlocker"):Show(bShowDoubleTapToDash and not bSettingDoubleTapToDash)
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
end

function DashMeter:UpdateEvades(nEvadeValue, nEvadeMax)
	if nEvadeValue >= nEvadeMax then -- all full
		self.wndEndurance:FindChild("EvadeProgressContainer"):Show(false)
		self.wndEndurance:FindChild("EvadeFullSprite"):SetSprite("sprResourceBar_DodgeFull")

		if self.nEnduranceState ~= eEnduranceFlash.EnuduranceFlashTwo then
			self.nEnduranceState = eEnduranceFlash.EnduranceFlashTwo
			self.wndEndurance:FindChild("EvadeFlashSprite"):SetSprite("sprResourceBar_DodgeFlashFull")
		end
	elseif nEvadeValue >= nEvadeMax / 2 then -- one ready, one filling
		self:HelperDrawProgressAsTicks(nEvadeValue - nEvadeMax/2)
		self.wndEndurance:FindChild("EvadeFullSprite"):SetSprite("sprResourceBar_DodgeHalf")

		if self.nEnduranceState == eEnduranceFlash.EnduranceFlashZero then
			self.nEnduranceState = eEnduranceFlash.EnduranceFlashOne
			self.wndEndurance:FindChild("EvadeFlashSprite"):SetSprite("sprResourceBar_DodgeFlashHalf")
		elseif self.nEnduranceState == eEnduranceFlash.EnduranceFlashTwo then
			self.nEnduranceState = eEnduranceFlash.EnduranceFlashOne
			self.wndEndurance:FindChild("EvadeFlashSprite"):SetSprite("sprResourceBar_DodgeFlashFull")
		end
	else -- under one
		self:HelperDrawProgressAsTicks(nEvadeValue)
		self.wndEndurance:FindChild("EvadeFullSprite"):SetSprite("")

		if self.nEnduranceState == eEnduranceFlash.EnduranceFlashOne then
			self.nEnduranceState = eEnduranceFlash.EnduranceFlashZero
			self.wndEndurance:FindChild("EvadeFlashSprite"):SetSprite("sprResourceBar_DodgeFlashHalf")
		elseif self.nEnduranceState == eEnduranceFlash.EnduranceFlashTwo then
			self.nEnduranceState = eEnduranceFlash.EnduranceFlashZero
			self.wndEndurance:FindChild("EvadeFlashSprite"):SetSprite("sprResourceBar_DodgeFlashFull")
		end
	end

	local strEvadeTooltop = Apollo.GetString(Apollo.GetConsoleVariable("player.doubleTapToDash") and "HealthBar_EvadeDoubleTapTooltip" or "HealthBar_EvadeKeyTooltip")
	local strDisplayTooltip = String_GetWeaselString(strEvadeTooltop, math.floor(nEvadeValue / 100), math.floor(nEvadeMax / 100))
	self.wndEndurance:FindChild("EvadeProgressContainer"):SetTooltip(strDisplayTooltip)
	self.wndEndurance:FindChild("EvadeFullSprite"):SetTooltip(strDisplayTooltip)
end

function DashMeter:HelperDrawProgressAsTicks(nProgress)
	local nTick = 100 / 8
	local nAnimationOffset = 3 -- TODO animation hack, offsets the delayed bits to the diagonal
	for idx = 1, 8 do
		local bIsTrue = nProgress - nAnimationOffset > (nTick * (idx - 1))
		self.wndEndurance:FindChild("EvadeDodgeBit"..idx):Show(bIsTrue, not bIsTrue)
	end
	self.wndEndurance:FindChild("EvadeProgressContainer"):Show(true)
end

function DashMeter:OnEnteredCombat(unit, bInCombat)
	if unit == GameLib.GetPlayerUnit() then
		self.bInCombat = bInCombat
	end
end

function DashMeter:OnFlashThrottleTimer()
	self.bFlashThrottle = false
end

function DashMeter:OnEnduranceDisplayTimer()
	self.bEnduranceFadeTimer = false
	self.wndEndurance:Show(false)
end

function DashMeter:OnDisableDashToggle(wndHandler, wndControl)
	Apollo.SetConsoleVariable("player.doubleTapToDash", not wndControl:IsChecked())
	self.wndEndurance:FindChild("EvadeDisabledBlocker"):Show(not wndControl:IsChecked())
	self.wndDisableDash:FindChild("DisableDashToggleFlash"):Show(not wndControl:IsChecked())
	self:OnFrameUpdate()
end


local DashMeterInst = DashMeter:new()
DashMeterInst:Init()
