-----------------------------------------------------------------------------------------------
-- Client Lua Script for PvP_HealthShieldBar
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
require "Window"
require "Apollo"
require "GameLib"
require "Spell"
require "Unit"
require "Item"

local PvP_HealthShieldBar = {}

function PvP_HealthShieldBar:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function PvP_HealthShieldBar:Init()
    Apollo.RegisterAddon(self)
end

local knEvadeResource = 7 -- the resource hooked to dodges (TODO replace with enum)

local eHealthColor =
{
	HealthInRed = 1,
	HealthInOrange = 2,
	HealthInGreen = 3
}

function PvP_HealthShieldBar:OnLoad()
	
	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnEnteredCombat", self)
	Apollo.RegisterEventHandler("RefreshPvP_HealthShieldBar", "OnFrameUpdate", self)
	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", "OnTutorial_RequestUIAnchor", self)
	Apollo.RegisterEventHandler("OptionsUpdated_PvP_HealthShieldBar", "OnOptionsUpdated", self)

	Apollo.RegisterTimerHandler("HealthShieldBarTimer", "OnFrameUpdate", self)
	Apollo.RegisterTimerHandler("CCArmorBrokenDisplayTimer", "OnCCArmorBrokenDisplayTimer", self)
	Apollo.RegisterTimerHandler("PvP_HealthShieldBar_FlashThrottleTimer", "OnFlashThrottleTimer", self)

	Apollo.RegisterSlashCommand("addon_healthwarn", "OnHealthWarnSlashCommand", self)

	Apollo.CreateTimer("HealthShieldBarTimer", 0.5, true)
	--Apollo.CreateTimer("EnduranceDisplayTimer", 30, false) --TODO: Fix(?) This is perma-killing the display when DT dashing is disabled via the toggle
	Apollo.CreateTimer("CCArmorBrokenDisplayTimer", 3, false)

    self.wndMain = Apollo.LoadForm("PvP_HealthShieldBar.xml", "PvP_HealthShieldBarForm", "FixedHudStratum", self)
	--wndParent = self.wndMain:Get
	--local tAddon = wndParent:GetData()
	--Print("Addon" .. tAddon.strName)
	for k,info in pairs(self) do
		Print(info.strName)
	end
	self.wndHealth = self.wndMain:FindChild("HealthBar")
	self.wndMaxAbsorb = self.wndMain:FindChild("MaxAbsorbBar")
	self.wndMaxShield = self.wndMain:FindChild("MaxShieldBar")
	self.wndCurrShield = self.wndMain:FindChild("CurrShieldBar")
	self.wndCurrAbsorb = self.wndMain:FindChild("CurrAbsorbBar")
	self.wndFlashShield = self.wndMain:FindChild("CurrShieldFlash")
	self.wndFlashAbsorb = self.wndMain:FindChild("CurrAbsorbFlash")
	self.wndFlashHealth = self.wndMain:FindChild("HealthBarFlash")

	self.nBarWidth = self.wndHealth:GetWidth()
	self.bInCombat = false
	self.fHealthWarn = 0.4
	self.fHealthWarn2 = 0.6
	self.eHealthState = eHealthColor.HealthInGreen
	self.bBrokenCCArmorFadeTimer = false
	
	-- For flashes
	self.bHealthBarFlashes = g_InterfaceOptions and g_InterfaceOptions.Carbine.bHealthBarFlashes or true
	self.bFlashThrottle = false
	self.nLastHealthCurr = -1
	self.nLastShieldCurr = -1
	self.nLastAbsorbCurr = -1

	-- Mount health
	self.wndMountHealth = Apollo.LoadForm("PvP_HealthShieldBar.xml", "MountHealthFrame", "FixedHudStratum", self)
	self.wndMountHealth:Show(false)

end

function PvP_HealthShieldBar:OnConfigureStart()
end

function PvP_HealthShieldBar:OnOptionsUpdated()
	self.bHealthBarFlashes = g_InterfaceOptions and g_InterfaceOptions.Carbine.bHealthBarFlashes or false	
end

function PvP_HealthShieldBar:OnHealthWarnSlashCommand(strArg1, strArg2)
	local nArg = tonumber(strArg2) -- This slash command will change self.nHealthWarn until reloadui
	if nArg and nArg > 1 and nArg < 100 then
		self.fHealthWarn = nArg / 100
	elseif nArg and nArg < 1 and nArg > 0 then
		self.fHealthWarn = nArg
	end
end

function PvP_HealthShieldBar:OnFrameUpdate()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil then return end

	local tStats = unitPlayer:GetBasicStats()
	if tStats == nil then return end

	local bShieldOverload = unitPlayer:IsShieldOverloaded()
	local nHealthMax = tStats.maxHealth
	local nHealthCurr = tStats.health
	local nShieldMax = unitPlayer:GetShieldCapacityMax()
	local nShieldCurr = bShieldOverload and nShieldMax or unitPlayer:GetShieldCapacity()
	local nAbsorbMax = unitPlayer:GetAbsorptionMax()
	local nAbsorbCurr = nAbsorbMax > 0 and unitPlayer:GetAbsorptionValue() or 0
	local nTotalMax = nHealthMax + nShieldMax + nAbsorbMax

	-- Shield, Absorb, and Health Flash (Before Resizing) TODO: FIX THIS OPTION
	if self.bHealthBarFlashes then
		if self.nLastShieldCurr < nShieldCurr and nShieldCurr == nShieldMax then
			self.wndFlashShield:SetSprite("sprResourceBar_ShieldFlash")
		end
			
		if self.nLastShieldCurr > 0 and self.nLastShieldCurr > nShieldCurr and not self.bFlashThrottle then
			self.bFlashThrottle = true
			Apollo.CreateTimer("PvP_HealthShieldBar_FlashThrottleTimer", 3, false)
			self.wndFlashShield:SetSprite("sprResourceBar_ShieldFlash")
		end
		self.nLastShieldCurr = nShieldCurr

		if self.nLastAbsorbCurr > 0 and self.nLastAbsorbCurr > nAbsorbCurr and not self.bFlashThrottle then
			self.bFlashThrottle = true
			Apollo.CreateTimer("PvP_HealthShieldBar_FlashThrottleTimer", 3, false)
			self.wndFlashAbsorb:SetSprite("sprResourceBar_ShieldFlash")
		end
		self.nLastAbsorbCurr = nAbsorbCurr

		if self.nLastHealthCurr > 0 and self.nLastHealthCurr > nHealthCurr and not self.bFlashThrottle then
			self.bFlashThrottle = true
			Apollo.CreateTimer("PvP_HealthShieldBar_FlashThrottleTimer", 1.5, false)
			self.wndFlashHealth:SetSprite("ClientSprites:WhiteFlash")
		end
		self.nLastHealthCurr = nHealthCurr
	end

	-- Text Labels
	local strHealthTooltip = String_GetWeaselString(Apollo.GetString("HealthBar_Health"), nHealthCurr, nHealthMax)
	local strShieldTooltip = String_GetWeaselString(Apollo.GetString("HealthBar_Shields"), nShieldCurr, nShieldMax)
	local strAbsorbTooltip = String_GetWeaselString(Apollo.GetString("HealthBar_Absorb"), nAbsorbCurr, nAbsorbMax)
	local strHealthText = nHealthCurr == nHealthMax and tostring(nHealthMax) or String_GetWeaselString(Apollo.GetString("Achievements_ProgressBarProgress"), nHealthCurr, nHealthMax)
	local strShieldText = ""
	if nShieldCurr ~= 0 and nShieldMax ~= 0 and nShieldCurr ~= nShieldMax then
		strShieldText = String_GetWeaselString(Apollo.GetString("HealthBar_HealthTextPartialShield"), strHealthText, nShieldCurr, nShieldMax)
	elseif nShieldCurr ~= 0 and nShieldMax ~= 0 then
		strShieldText = String_GetWeaselString(Apollo.GetString("HealthBar_HealthTextFullShield"), strHealthText, nShieldMax)
	end
	
	if nShieldCurr ~= 0 then
		self.wndMain:FindChild("HealthText"):SetText(strShieldText)
	else
		self.wndMain:FindChild("HealthText"):SetText(strHealthText)
	end
	self.wndMain:FindChild("HealthBar"):SetTooltip(string.format("<T Font=\"CRB_InterfaceSmall\">%s</T>", String_GetWeaselString(Apollo.GetString("HealthBar_HealthShieldTooltip"), strHealthTooltip, strShieldTooltip, "")))
	self.wndMain:FindChild("MaxShieldBar"):SetTooltip(string.format("<T Font=\"CRB_InterfaceSmall\">%s</T>", String_GetWeaselString(Apollo.GetString("HealthBar_HealthShieldTooltip"), strShieldTooltip, strHealthTooltip, "")))
	self.wndMain:FindChild("MaxAbsorbBar"):SetTooltip(string.format("<T Font=\"CRB_InterfaceSmall\">%s</T>", String_GetWeaselString(Apollo.GetString("HealthBar_HealthShieldTooltip"), strAbsorbTooltip, strShieldTooltip, strHealthTooltip)))

	-- Bars
	self.wndHealth:Show(nHealthCurr > 0)
	self.wndMaxShield:Show(nHealthCurr > 0)
	self.wndCurrShield:Show(nHealthCurr > 0)
	self.wndMaxAbsorb:Show(nHealthCurr > 0 and nAbsorbMax > 0)

	-- Health Bar Color
	if (nHealthCurr / nHealthMax) < self.fHealthWarn then
		if self.eHealthState ~= eHealthColor.HealthInRed then
			self.eHealthState = eHealthColor.HealthInRed
			self.wndHealth:SetSprite("CRB_ActionBarFrameSprites:sprResourceBar_RedProgBar")
			self.wndHealth:FindChild("HealthBarEdgeGlow"):SetSprite("CRB_ActionBarFrameSprites:sprResourceBar_RedEdgeGlow")
		end
	elseif (nHealthCurr / nHealthMax) < self.fHealthWarn2 then
		if self.eHealthState ~= eHealthColor.HealthInOrange then
			self.eHealthState = eHealthColor.HealthInOrange
			self.wndHealth:SetSprite("CRB_ActionBarFrameSprites:sprResourceBar_OrangeProgBar")
			self.wndHealth:FindChild("HealthBarEdgeGlow"):SetSprite("CRB_ActionBarFrameSprites:sprResourceBar_OrangeEdgeGlow")
		end
	else
		if self.eHealthState ~= eHealthColor.HealthInGreen then
			self.eHealthState = eHealthColor.HealthInGreen
			self.wndHealth:SetSprite("CRB_ActionBarFrameSprites:sprResourceBar_GreenProgBar")
			self.wndHealth:FindChild("HealthBarEdgeGlow"):SetSprite("CRB_ActionBarFrameSprites:sprResourceBar_GreenEdgeGlow")
		end
	end

	-- Scaling
	local nPointHealthRight = self.nBarWidth * (nHealthCurr / nTotalMax)
	local nPointShieldMid 	= self.nBarWidth * ((nHealthCurr + nShieldCurr) / nTotalMax)
	local nPointShieldRight = self.nBarWidth * ((nHealthCurr + nShieldMax) / nTotalMax)
	local nPointAbsorbMid 	= self.nBarWidth * ((nHealthCurr + nShieldMax + nAbsorbCurr) / nTotalMax)
	local nPointAbsorbRight = self.nBarWidth * ((nHealthCurr + nShieldMax + nAbsorbMax) / nTotalMax)

	if nShieldMax > 0 and nShieldMax / nTotalMax < 0.1 then
		local nMinShieldSize = 0.1 -- HARDCODE: Minimum shield bar length for formatting
		nPointHealthRight = self.nBarWidth * math.min(1 - nMinShieldSize, nHealthCurr / nTotalMax) -- Health is normal, but caps at nMinShieldSize
		nPointShieldRight = self.nBarWidth * math.min(1, (nHealthCurr / nTotalMax) + nMinShieldSize) -- If not 1, the size is thus healthbar + hard minimum
	end
	
	self.wndCurrShield:FindChild("ShieldBarEdgeGlow"):Show(nShieldCurr < nShieldMax or nAbsorbMax > 0)
	
	self.wndCurrAbsorb:FindChild("AbsorbBarEdgeGlow"):Show(nAbsorbMax > 0 and nAbsorbCurr < nAbsorbMax)
	
	self.wndHealth:SetAnchorOffsets(0, 0, nPointHealthRight, 0)

	self.wndCurrShield:SetAnchorOffsets(nPointHealthRight, 0, nPointShieldMid, 0)
	self.wndFlashShield:SetAnchorOffsets(nPointHealthRight, 0, nPointShieldMid, 0)
	self.wndMaxShield:SetAnchorOffsets(nPointHealthRight, 0, nPointShieldRight, 0)

	self.wndCurrAbsorb:SetAnchorOffsets(nPointShieldRight, 0, nPointAbsorbMid, 0)
	self.wndFlashAbsorb:SetAnchorOffsets(nPointShieldRight, 0, nPointAbsorbMid, 0)
	self.wndMaxAbsorb:SetAnchorOffsets(nPointShieldRight, 0, nPointAbsorbRight, 0)

	-- Mount Health
	local bMounted = unitPlayer:IsMounted()
	self.wndMountHealth:Show(bMounted, not bMounted)
	if bMounted then
		self.wndMountHealth:FindChild("MountHealth"):SetFloor(0)
		self.wndMountHealth:FindChild("MountHealth"):SetMax(unitPlayer:GetMountMaxHealth())
		self.wndMountHealth:FindChild("MountHealth"):SetProgress(unitPlayer:GetMountHealth())
		self.wndMountHealth:FindChild("MountHealthText"):SetText(String_GetWeaselString(Apollo.GetString("HealthBar_MountHealth"),  unitPlayer:GetMountHealth(), unitPlayer:GetMountMaxHealth()))
	end

end

function PvP_HealthShieldBar:HelperDrawProgressAsTicks(nProgress)
	local nTick = 100 / 8
	local nAnimationOffset = 3 -- TODO animation hack, offsets the delayed bits to the diagonal
	for idx = 1, 8 do
		local bIsTrue = nProgress - nAnimationOffset > (nTick * (idx - 1))
		self.wndEndurance:FindChild("EvadeDodgeBit"..idx):Show(bIsTrue, not bIsTrue)
	end
	self.wndEndurance:FindChild("EvadeProgressContainer"):Show(true)
end

function PvP_HealthShieldBar:OnEnteredCombat(unit, bInCombat)
	if unit == GameLib.GetPlayerUnit() then
		self.bInCombat = bInCombat
	end
end

function PvP_HealthShieldBar:OnCCArmorBrokenDisplayTimer()
	self.bBrokenCCArmorFadeTimer = false
end

function PvP_HealthShieldBar:OnFlashThrottleTimer()
	self.bFlashThrottle = false
end

function PvP_HealthShieldBar:OnMouseButtonDown(wnd, wndControl, iButton, nX, nY, bDouble)
	if iButton == 0 then -- Left Click
		GameLib.SetTargetUnit(GameLib.GetPlayerUnit())
	end
	return true -- stop propogation
end

function PvP_HealthShieldBar:OnDisableDashToggle(wndHandler, wndControl)
	Apollo.SetConsoleVariable("player.doubleTapToDash", not wndControl:IsChecked())
	self.wndEndurance:FindChild("EvadeDisabledBlocker"):Show(not wndControl:IsChecked())
	self.wndDisableDash:FindChild("DisableDashToggleFlash"):Show(not wndControl:IsChecked())
	self:OnFrameUpdate()
end

function PvP_HealthShieldBar:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	if eAnchor == GameLib.CodeEnumTutorialAnchor.DashMeter then
		local tRect = {}
		tRect.l, tRect.t, tRect.r, tRect.b = self.wndMain:GetRect()
		Event_FireGenericEvent("Tutorial_RequestUIAnchorResponse", eAnchor, idTutorial, strPopupText, tRect)
	elseif eAnchor == GameLib.CodeEnumTutorialAnchor.ClassResource then
		local tRect = {}
		tRect.l, tRect.t, tRect.r, tRect.b = self.wndMain:GetRect()
		Event_FireGenericEvent("Tutorial_RequestUIAnchorResponse", eAnchor, idTutorial, strPopupText, tRect)
	elseif eAnchor == GameLib.CodeEnumTutorialAnchor.HealthBar then
		local tRect = {}
		tRect.l, tRect.t, tRect.r, tRect.b = self.wndMain:GetRect()
		Event_FireGenericEvent("Tutorial_RequestUIAnchorResponse", eAnchor, idTutorial, strPopupText, tRect)
	elseif eAnchor == GameLib.CodeEnumTutorialAnchor.ShieldBar then
		local tRect = {}
		tRect.l, tRect.t, tRect.r, tRect.b = self.wndMain:GetRect()
		Event_FireGenericEvent("Tutorial_RequestUIAnchorResponse", eAnchor, idTutorial, strPopupText, tRect)
	end
end

function PvP_HealthShieldBar:OnSave(eLevel)

end

---------------------------------------------------------------------------------------------------
-- PvP_HealthShieldBarForm Functions
---------------------------------------------------------------------------------------------------

function PvP_HealthShieldBar:OnBarContainerMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	Position = 50
	PvP_Settings.Set("HealthShieldBar", "X", Position)
end

local PvP_HealthShieldBarInst = PvP_HealthShieldBar:new()
PvP_HealthShieldBarInst:Init()
