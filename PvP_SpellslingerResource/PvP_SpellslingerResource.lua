-----------------------------------------------------------------------------------------------
-- Client Lua Script for SpellslingerResource
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
-----------boiler plate-----------------------------------
require "Window"

local SpellslingerResource = {}

function SpellslingerResource:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function SpellslingerResource:Init()
    Apollo.RegisterAddon(self)
end

function SpellslingerResource:OnLoad()
----------------------------------------------------------
	Apollo.RegisterEventHandler("CharacterCreated", "OnCharacterCreated", self)
	
	if GameLib.GetPlayerUnit() then
		self:OnCharacterCreated()
	end
end

function SpellslingerResource:OnCharacterCreated()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer:GetClassId() ~= GameLib.CodeEnumClass.Spellslinger then
		return
	end
	
	
	Apollo.RegisterEventHandler("VarChange_FrameCount", "OnFrame", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnEnteredCombat", self)

    self.wndMain = Apollo.LoadForm("PvP_SpellslingerResource.xml", "SpellslingerResourceForm", "FixedHudStratum", self)

	self.wndMain:FindChild("SurgeBacker"):SetTooltip(string.format("<T Font=\"CRB_InterfaceSmall\">%s</T>", Apollo.GetString("CRB_SpellslingerResource")))
	

		
end

function SpellslingerResource:OnFrame()
	local unitPlayer = GameLib.GetPlayerUnit()

	if not self.wndMain:IsValid() then
		return
	end

	-- TODO REMOVE and replace
	local nLeft, nTop, nRight, nBottom = self.wndMain:GetRect()
	Apollo.SetGlobalAnchor("CastingBarBottom", 0.0, nTop - 15, true)

	-- Mana
	local nManaMax = math.floor(unitPlayer:GetMaxMana())
	local nManaCurrent = math.floor(unitPlayer:GetMana())
	self.wndMain:FindChild("ManaProgressBar"):SetMax(nManaMax)
	self.wndMain:FindChild("ManaProgressBar"):SetProgress(nManaCurrent)
	self.wndMain:FindChild("ManaProgressText"):SetText(String_GetWeaselString(Apollo.GetString("CRB_Percent"), math.floor(nManaCurrent / nManaMax * 100)))
	self.wndMain:FindChild("ManaProgressBar"):SetTooltip(String_GetWeaselString(Apollo.GetString("Spellslinger_Focus"), nManaCurrent, nManaMax))

	-- Resource
	local nResourceMax = unitPlayer:GetMaxResource(4)
	local nResourceCurrent = unitPlayer:GetResource(4)
	self.wndMain:FindChild("SurgeProgressBar"):SetMax(nResourceMax)
	self.wndMain:FindChild("SurgeProgressBar"):SetProgress(nResourceCurrent)
	self.wndMain:FindChild("SurgeProgressBar"):SetTooltip(String_GetWeaselString(Apollo.GetString("Spellslinger_SpellSurge"), nResourceCurrent, nResourceMax))

	local bSurgeReady = nResourceCurrent >= 50
	if bSurgeReady ~= self.wndMain:FindChild("SurgeBacker"):GetData() then
		self.wndMain:FindChild("SurgeProgressBar"):SetTextColor("xkcdAmber")
		self.wndMain:FindChild("SurgeBacker"):SetData(bSurgeReady)
		self.wndMain:FindChild("SurgeBacker"):SetSprite(bSurgeReady and "sprSpellslinger_TEMP_BackerAnim" or "sprSpellslinger_TEMP_BackerArt")
	end
	
	
	if nResourceCurrent < 50 then 
		self.wndMain:FindChild("SurgeProgressBar"):SetTextColor("xkcdLightRed")
	end

	-- Glow
	local bSurgeActive = GameLib.IsSpellSurgeActive() or false
	self.wndMain:FindChild("SurgeGlowBG"):Show(bSurgeActive)
	self.wndMain:FindChild("SurgeGlowAnims"):Show(bSurgeActive)
end

function SpellslingerResource:OnEnteredCombat(unitPlayer, bInCombat)
	if self.wndMain and self.wndMain:FindChild("CombatNoticeLeft") and self.wndMain:FindChild("CombatNoticeRight") and unitPlayer == GameLib.GetPlayerUnit() then
		self.wndMain:FindChild("CombatNoticeLeft"):Show(bInCombat)
		self.wndMain:FindChild("CombatNoticeRight"):Show(bInCombat)
	end
end

-----------boiler plate-----------------------------------
local SpellslingerResourceInst = SpellslingerResource:new()
SpellslingerResourceInst:Init()
----------------------------------------------------------