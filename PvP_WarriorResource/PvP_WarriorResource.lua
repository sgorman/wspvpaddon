-----------------------------------------------------------------------------------------------
-- Client Lua Script for WarriorResource
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "GameLib"
require "Unit"

local WarriorResource = {}

function WarriorResource:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function WarriorResource:Init()
	Apollo.RegisterAddon(self)
end

function WarriorResource:OnLoad()
	Apollo.RegisterEventHandler("CharacterCreated", "OnCharacterCreate", self)
	
	if GameLib:GetPlayerUnit() then
		self:OnCharacterCreate()
	end
end

function WarriorResource:OnCharacterCreate()
	local unitPlayer = GameLib:GetPlayerUnit()
	if unitPlayer:GetClassId() == GameLib.CodeEnumClass.Warrior then
		Apollo.RegisterTimerHandler("WarriorResource_ChargeBarOverdriveTick", "OnWarriorResource_ChargeBarOverdriveTick", self)
		Apollo.RegisterTimerHandler("WarriorResource_ChargeBarOverdriveDone", "OnWarriorResource_ChargeBarOverdriveDone", self)
		Apollo.RegisterEventHandler("VarChange_FrameCount", "OnFrame", self)

		self.wndResourceBar = Apollo.LoadForm("PvP_WarriorResource.xml", "WarriorResourceForm", "FixedHudStratum", self)
		self.wndResourceBar:FindChild("ChargeBarOverdriven"):SetMax(100)
		self.wndResourceBar:ToFront()

		self.nOverdriveTick = 0
		
		self.wndResourceBar:FindChild("ResourceCount"):SetTooltip(string.format("<T Font=\"CRB_InterfaceSmall\">%s</T>", Apollo.GetString("CRB_WarriorResource")))
		self.wndResourceBar:FindChild("ResourceCount1"):SetTooltip(string.format("<T Font=\"CRB_InterfaceSmall\">%s</T>", Apollo.GetString("CRB_WarriorResource")))
		
	end
end

function WarriorResource:OnFrame(strName, nCnt)
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil then
		return
	elseif unitPlayer:GetClassId() ~= GameLib.CodeEnumClass.Warrior then
		if self.wndResourceBar then
			self.wndResourceBar:Show(false)
			self.wndResourceBar:Destroy()
		end
		return
	end

	if not self.wndResourceBar:IsValid() then
		return
	end

	local nLeft0, nTop0, nRight0, nBottom0 = self.wndResourceBar:GetRect()
	Apollo.SetGlobalAnchor("CastingBarBottom", 0.0, nTop0 - 15, true)

	local bOverdrive = GameLib.IsOverdriveActive()
	local nResourceCurr = unitPlayer:GetResource(1)
	local nResourceMax = unitPlayer:GetMaxResource(1)

	self.wndResourceBar:FindChild("ChargeBar"):SetMax(nResourceMax)
	self.wndResourceBar:FindChild("ChargeBar"):SetProgress(nResourceCurr)

	if bOverdrive and not self.bOverDriveActive then
		self.bOverDriveActive = true
		self.wndResourceBar:FindChild("ChargeBarOverdriven"):SetProgress(100)
		Apollo.CreateTimer("WarriorResource_ChargeBarOverdriveTick", 0.01, false)
		Apollo.CreateTimer("WarriorResource_ChargeBarOverdriveDone", 10, false)
	end

	self.wndResourceBar:FindChild("Overdrive_Glow"):Show(bOverdrive)
	self.wndResourceBar:FindChild("ChargeBarOverdriven"):Show(bOverdrive)
	self.wndResourceBar:FindChild("Overdrive_FrameInset"):Show(bOverdrive)

	self.wndResourceBar:FindChild("ChargeBar"):Show(not bOverdrive)
	self.wndResourceBar:FindChild("InsetFrameDivider1"):Show(not bOverdrive)
	self.wndResourceBar:FindChild("InsetFrameDivider2"):Show(not bOverdrive)
	self.wndResourceBar:FindChild("InsetFrameDivider3"):Show(not bOverdrive)

	if bOverdrive then
		self.wndResourceBar:FindChild("ResourceCount"):SetText(Apollo.GetString("WarriorResource_OverdriveCaps"))
		self.wndResourceBar:FindChild("ResourceCount"):SetTextColor(ApolloColor.new("xkcdAmber"))
		self.wndResourceBar:FindChild("ResourceCount1"):SetText(Apollo.GetString("WarriorResource_OverdriveCaps"))
		self.wndResourceBar:FindChild("ResourceCount1"):SetTextColor(ApolloColor.new("xkcdAmber"))

	else
		self.wndResourceBar:FindChild("ResourceCount"):SetText(nResourceCurr == 0 and "" or nResourceCurr)
		self.wndResourceBar:FindChild("ResourceCount"):SetTextColor(ApolloColor.new("white"))
		self.wndResourceBar:FindChild("ResourceCount1"):SetText(nResourceCurr == 0 and "" or nResourceCurr)
		self.wndResourceBar:FindChild("ResourceCount1"):SetTextColor(ApolloColor.new("white"))
	end
	
	if nResourceCurr == 0 then
		self.wndResourceBar:FindChild("ResourceCount1"):SetText("0")
	end
	
	if nResourceCurr >= 750 then
		self.wndResourceBar:FindChild("ResourceCount1"):SetTextColor("green")
	elseif nResourceCurr >= 250 then
		self.wndResourceBar:FindChild("ResourceCount1"):SetTextColor("yellow")
	elseif nResourceCurr >= 0 then
		self.wndResourceBar:FindChild("ResourceCount1"):SetTextColor("red")
	end
end

function WarriorResource:OnWarriorResource_ChargeBarOverdriveTick()
	Apollo.StopTimer("WarriorResource_ChargeBarOverdriveTick")
	self.wndResourceBar:FindChild("ChargeBarOverdriven"):SetProgress(0, 10)
end

function WarriorResource:OnWarriorResource_ChargeBarOverdriveDone()
	Apollo.StopTimer("WarriorResource_ChargeBarOverdriveDone")
	self.bOverDriveActive = false
end

local WarriorResourceInst = WarriorResource:new()
WarriorResourceInst:Init()
