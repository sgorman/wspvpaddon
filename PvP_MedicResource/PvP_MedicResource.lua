-----------------------------------------------------------------------------------------------
-- Client Lua Script for Medic
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "GameLib"
require "Unit"
require "Spell"

local Medic = {}

function Medic:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Medic:Init()
    Apollo.RegisterAddon(self)
end

function Medic:OnLoad()
	Apollo.RegisterEventHandler("CharacterCreated", "OnCharacterCreated", self)
	
	if GameLib.GetPlayerUnit() then
		self:OnCharacterCreated()
	end
end

function Medic:OnCharacterCreated()
	local unitPlayer = GameLib.GetPlayerUnit()
	
	if not unitPlayer then
		return
	elseif unitPlayer:GetClassId() ~= GameLib.CodeEnumClass.Medic then
		if self.wndMain then
			self.wndMain:Destroy()
		end
		return
	end
	
	Apollo.RegisterEventHandler("VarChange_FrameCount", "OnFrame", self)

    self.wndMain = Apollo.LoadForm("PvP_MedicResource.xml", "MedicResourceForm", "FixedHudStratum", self)
    self.wndMain:Show(false)

	local strResource = string.format("<T Font=\"CRB_InterfaceSmall\">%s</T>", Apollo.GetString("CRB_MedicResource"))
	self.wndMain:FindChild("ResourceContainer"):SetTooltip(strResource)
	self.wndMain:FindChild("ResourceContainer1"):SetTooltip(strResource)
	self.wndMain:FindChild("ResourceContainer2"):SetTooltip(strResource)
	self.wndMain:FindChild("ResourceContainer3"):SetTooltip(strResource)
	self.wndMain:FindChild("ResourceContainer4"):SetTooltip(strResource)
	
	self.tCores = {} -- windows

	for idx = 1,4 do
		self.tCores[idx] = 
		{
			wndCore = Apollo.LoadForm("PvP_MedicResource.xml", "CoreForm",  self.wndMain:FindChild("ResourceContainer" .. idx), self),
			bFull = false
		}
	end
end

function Medic:OnFrame()
	local unitPlayer = GameLib.GetPlayerUnit()
	if not unitPlayer then
		return
	elseif unitPlayer:GetClassId() ~= GameLib.CodeEnumClass.Medic then
		if self.wndMain then
			self.wndMain:Destroy()
		end
		return
	end

	if not self.wndMain:IsValid() then
		return
	end

	if not self.wndMain:IsVisible() then
		self.wndMain:Show(true)
	end

	local nLeft, nTop, nRight, nBottom = self.wndMain:GetRect() -- legacy code
	Apollo.SetGlobalAnchor("CastingBarBottom", 0.0, nTop - 15, true)

	self:DrawCores(unitPlayer) -- right id, draw core info

	-- Resource 2 (Mana)
	local nManaMax = unitPlayer:GetMaxMana()
	local nManaCurrent = unitPlayer:GetMana()
	self.wndMain:FindChild("ManaProgressBar"):SetMax(nManaMax)
	self.wndMain:FindChild("ManaProgressBar"):SetProgress(nManaCurrent)
	if nManaCurrent == nManaMax then
		self.wndMain:FindChild("ManaProgressText"):SetText(nManaMax)
		self.wndMain:FindChild("ManaProgressText1"):SetText(String_GetWeaselString("$1c%", math.floor(nManaCurrent / nManaMax * 100)))
	else
		--self.wndMain:FindChild("ManaProgressText"):SetText(string.format("%.02f/%s", nManaCurrent, nManaMax))
		self.wndMain:FindChild("ManaProgressText"):SetText(String_GetWeaselString(Apollo.GetString("Achievements_ProgressBarProgress"), math.floor(nManaCurrent), nManaMax))
	end

	local strMana = String_GetWeaselString(Apollo.GetString("Medic_FocusTooltip"), nManaCurrent, nManaMax)
	self.wndMain:FindChild("ManaProgressBar"):SetTooltip(string.format("<T Font=\"CRB_InterfaceSmall\">%s</T>", strMana))

end

function Medic:DrawCores(unitPlayer)

	local nResourceCurr = unitPlayer:GetResource(1)
	local nResourceMax = unitPlayer:GetMaxResource(1)

	for idx = 1, #self.tCores do
		--self.tCores[idx].wndCore:Show(nResourceCurr ~= nil and nResourceMax ~= nil and nResourceMax ~= 0)
		local bFull = idx <= nResourceCurr
		self.tCores[idx].wndCore:FindChild("CoreFill"):Show(idx <= nResourceCurr)

		if bFull ~= self.tCores[idx].bFull then
			if bFull == false then -- burned a core
				self.tCores[idx].wndCore:FindChild("CoreFlash"):SetSprite("CRB_WarriorSprites:sprWar_FuelRedFlashQuick")
			else -- generated a core
				self.tCores[idx].wndCore:FindChild("CoreFlash"):SetSprite("CRB_WarriorSprites:sprWar_FuelRedFlash")
			end
		end
		
		self.tCores[idx].bFull = bFull
		
	end	
	
	if nResourceCurr == 4 then
		self.wndMain:FindChild("ResourceContainer"):SetTextColor("green")
		self.wndMain:FindChild("ResourceContainer"):SetText("4")
	elseif nResourceCurr == 3 then
		self.wndMain:FindChild("ResourceContainer"):SetTextColor("ff9acd32")--greenish yellow
		self.wndMain:FindChild("ResourceContainer"):SetText("3")
	elseif nResourceCurr == 2 then
		self.wndMain:FindChild("ResourceContainer"):SetTextColor("yellow")
		self.wndMain:FindChild("ResourceContainer"):SetText("2")
	elseif nResourceCurr == 1 then
		self.wndMain:FindChild("ResourceContainer"):SetTextColor("ffff6501")
		self.wndMain:FindChild("ResourceContainer"):SetText("1")
	elseif nResourceCurr == 0 then
		self.wndMain:FindChild("ResourceContainer"):SetTextColor("red")
		self.wndMain:FindChild("ResourceContainer"):SetText("0")
	end
end

-----------------------------------------------------------------------------------------------
-- Medic Instance
-----------------------------------------------------------------------------------------------
local MedicInst = Medic:new()
MedicInst:Init()
