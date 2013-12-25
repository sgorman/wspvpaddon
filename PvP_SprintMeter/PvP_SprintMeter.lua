-----------------------------------------------------------------------------------------------
-- Client Lua Script for SprintMeter
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
require "Window"
require "GameLib"
require "Apollo"

local SprintMeter = {}

function SprintMeter:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function SprintMeter:Init()
	Apollo.RegisterAddon(self)
end

function SprintMeter:OnLoad()
	Apollo.RegisterTimerHandler("SprintMeterGracePeriod", "OnSprintMeterGracePeriod", self)
	Apollo.RegisterEventHandler("VarChange_FrameCount", "OnFrame", self)
	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", 	"OnTutorial_RequestUIAnchor", self)	

	self.wndMain = Apollo.LoadForm("PvP_SprintMeter.xml", "SprintMeterFormVert", "InWorldHudStratum", self)
	self.wndMain:Show(false, true)
	--self.wndMain:SetUnit(GameLib.GetPlayerUnit(), 40) -- 1 or 9 are also good

	self.bJustFilled = false
	self.nLastSprintValue = 0
end

function SprintMeter:OnFrame()
	local unitPlayer = GameLib.GetPlayerUnit()
	if not unitPlayer then
		return
	end

	local bWndVisible = self.wndMain:IsVisible()
	local nRunCurr = unitPlayer:GetResource(0)
	local nRunMax = unitPlayer:GetMaxResource(0)
	local bAtMax = nRunCurr == nRunMax or unitPlayer:IsDead()

	self.wndMain:FindChild("ProgBar"):SetMax(nRunMax)
	self.wndMain:FindChild("ProgBar"):SetProgress(nRunCurr, bWndVisible and nRunMax or 0)

	if self.nLastSprintValue ~= nRunCurr then
		self.wndMain:FindChild("SprintIcon"):SetSprite(self.nLastSprintValue < nRunCurr and "sprResourceBar_Sprint_RunIconSilver" or "sprResourceBar_Sprint_RunIconBlue")
		self.nLastSprintValue = nRunCurr
	end

	if bWndVisible and bAtMax and not self.bJustFilled then
		self.bJustFilled = false
		Apollo.StopTimer("SprintMeterGracePeriod")
		Apollo.CreateTimer("SprintMeterGracePeriod", 0.4, false)
		self.wndMain:FindChild("ProgFlash"):SetSprite("sprResourceBar_Sprint_ProgFlash")
	end

	if not bAtMax then
		self.bJustFilled = true
		Apollo.StopTimer("SprintMeterGracePeriod")
	end
	--Makes SprintPercent disappear at 100% capacity
	--self.wndMain:Show(bAtMax or self.bJustFilled, not bAtMax)
	--Makes SprintPercent always visible
	self.wndMain:Show(bAtMax or self.bJustFilled, not bAtMax)
	
	if nRunCurr >= 350 then
	 self.wndMain:FindChild("ProgBar"):SetTextColor("green")
	elseif nRunCurr >= 175 then
	 self.wndMain:FindChild("ProgBar"):SetTextColor("yellow")
	elseif nRunCurr >= 0 then
	 self.wndMain:FindChild("ProgBar"):SetTextColor("red")
	end
end

function SprintMeter:OnSprintMeterGracePeriod()
	Apollo.StopTimer("SprintMeterGracePeriod")
	self.bJustFilled = false
	if self.wndMain and self.wndMain:IsValid() then
		self.wndMain:Show(false)
	end
end

---------------------------------------------------------------------------------------------------
-- Tutorial anchor request
---------------------------------------------------------------------------------------------------
function SprintMeter:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	if eAnchor == GameLib.CodeEnumTutorialAnchor.SprintMeter then

	local tRect = {}
	tRect.l, tRect.t, tRect.r, tRect.b = self.wndMain:GetRect()

	Event_FireGenericEvent("Tutorial_RequestUIAnchorResponse", eAnchor, idTutorial, strPopupText, tRect)
	end
end


local SprintMeterInst = SprintMeter:new()
SprintMeterInst:Init()
