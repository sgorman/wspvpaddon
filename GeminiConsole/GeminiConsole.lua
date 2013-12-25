-----------------------------------------------------------------------------------------------
-- Client Lua Script for GeminiConsole
-- Copyright (c) NCsoft. All rights reserved
-- Author:  draftomatic
-- Creates a Lua console window on /lua slash command
-- The console will attempt to parse and evaluate the input, and follows the conventions of
-- the standard lua command line utility, i.e.:
-- If a line starts with "=" the rest of the line is evaluated as an expression and the result is printed.
-- There are two types of errors that can happen: parse and execute.
-----------------------------------------------------------------------------------------------
require "Window"

local GeminiConsole = {}

local GeminiPackages = _G["GeminiPackages"]
local inspect
local LuaUtils
local Queue

-- Constants
local kstrColorDefault = "FFFFFFFF"
local kstrColorError = "FFD12424"
local kstrColorInspect = "FF5AAFFA"

-- Initialization
function GeminiConsole:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

	-- For keeping track of command history
	self.cmdHistory = {}
	self.cmdHistoryIndex = 1
	self.nonMarkupText = ""
	self.bShowOnReload = false
	self.sLineBuffer = ""
	self.nTabHitCounter = 0

    return o
end
function GeminiConsole:Init()
    Apollo.RegisterAddon(self)
end

-- GeminiConsole OnLoad
function GeminiConsole:OnLoad()
	--Print("GeminiConsole OnLoad")
	GeminiPackages:Require("drafto_inspect-1.0", "drafto_LuaUtils-1.0", "drafto_Queue-1.0", function(i, LU, Q)
		--Print("GeminiConsole Require")
		inspect, LuaUtils, Queue = i, LU, Q

		-- Load Window
		self.wndMain = Apollo.LoadForm("GeminiConsole.xml", "GeminiConsoleWindow", nil, self)

		-- Find Window components
		self.consoleContainer = self.wndMain:FindChild("ConsoleContainer")
		self.console = self.wndMain:FindChild("Console")	-- Console window for evaluation output
		self.input = self.wndMain:FindChild("Input")		-- Text input at the bottom
		self.clipboardWorkaround = self.wndMain:FindChild("ClipboardWorkaround")
		self.showOnReloadInput = self.wndMain:FindChild("ShowOnReload")
		self.wndFPS = self.wndMain:FindChild("FPS")

		-- Register Event Handlers
		Apollo.RegisterSlashCommand("lua", "OnLuaSlashCommand", self)
		--Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)

		-- Line buffer
		self.lineQueue = Queue.new()
		Apollo.CreateTimer("LineQueueTimer", 0.001, true)
		Apollo.RegisterTimerHandler("LineQueueTimer", "OnLineQueueTimer", self)
	
		-- FPS update timer
		Apollo.CreateTimer("FPSTimer", 1.5, true)
		Apollo.RegisterTimerHandler("FPSTimer", "OnFPSTimer", self)
		
		-- Append initial help text
		self:AppendHelpText()

		-- Register library
		GeminiPackages:NewPackage(self, "GeminiConsole-1.1", 7)
	end)
end

-- on SlashCommand "/lua"
function GeminiConsole:OnLuaSlashCommand()
	self.wndMain:Show(true) -- show the window
	self.input:SetFocus()	-- Focus on the text input to start
end

-- Persistence
function GeminiConsole:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.General then return nil end
	return {
		tAnchorPoints = LuaUtils:Pack(self.wndMain:GetAnchorPoints()),
		tAnchorOffsets = LuaUtils:Pack(self.wndMain:GetAnchorOffsets()),
		bShowOnReload = self.bShowOnReload--,
		--sConsoleText = self.nonMarkupText			-- Hack to get console text out of WildStar. Clipboard stuff doesn't work anymore...
	}
end
function GeminiConsole:OnRestore(eLevel, tData)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.General then return nil end
	if tData.bShowOnReload == true then
		self.bShowOnReload = true
		self.showOnReloadInput:SetCheck(true)
		self.wndMain:Show(true)
	else
		self.showOnReloadInput:SetCheck(false)
		self.wndMain:Show(false)
	end
	if tData.tAnchorPoints then
		self.wndMain:SetAnchorPoints(unpack(tData.tAnchorPoints))
	end
	if tData.tAnchorOffsets then
		self.wndMain:SetAnchorOffsets(unpack(tData.tAnchorOffsets))
	end
end

-- Appends text to the console with given color (or default color) and newline
function GeminiConsole:Append(text, color, bSupressNewline)
	local newText = tostring(text)

	local newLine = "\n"
	if bSupressNewline == true then newLine = "" end

	self.nonMarkupText = self.nonMarkupText .. newText .. newLine

	-- Prepare text for printing
	newText = LuaUtils:EscapeHTML(newText .. newLine)

	-- Clip text to account for bug that crashes the game if string is too big
	--local maxText = 30000
	--if #newText > maxText then
		--newText = string.sub(newText, #newText - maxText, #newText)
	--end

	-- Split multiline text so that we can wrap each line in markup separately
	if string.find(newText, "\n") then
		local tempText = ""
		for s in string.gmatch(newText, "[^\n]+") do
			if #s > 0 then
				if color then
					s = LuaUtils:markupTextColor(s, color)
				end
				tempText = tempText .. s .. "&#13;&#10;"
			end
		end
		newText = tempText
	else
		if color then
			newText = LuaUtils:markupTextColor(newText, color)
		end
	end

	-- Append line buffer
	self.sLineBuffer = self.sLineBuffer .. newText

	-- Append console if newline
	if not bSupressNewline then
		self:QueueLine(self.sLineBuffer)
		self.sLineBuffer = ""
	end

end

function GeminiConsole:OnLineQueueTimer()
	if Queue.Size(self.lineQueue) > 0 then
		self:AddLine(Queue.PopRight(self.lineQueue))
	end
end

function GeminiConsole:QueueLine(sLine)
	Queue.PushLeft(self.lineQueue, sLine)
end

function GeminiConsole:AddLine(sLine)
	local bLockScroll = self.console:GetVScrollPos() == self.console:GetVScrollRange()

	--Print(sLine)
	local lineItem = Apollo.LoadForm("GeminiConsole.xml", "LineItem", self.console, self)
	local xml = XmlDoc.new()
	xml:AddLine(sLine, ApolloColor.new("white"), "Fixed", "Left")
	lineItem:SetDoc(xml)
	lineItem:SetHeightToContentHeight()
	
	local nQueueSize = Queue.Size(self.lineQueue)
	if nQueueSize % 10 == 0 then
		self.console:ArrangeChildrenVert()
	end

	-- Set the scrollbar to the bottom
	if bLockScroll then
		self.console:SetVScrollPos(self.console:GetVScrollRange())
	end
end

--- Prints help text to console
function GeminiConsole:AppendHelpText()
	local color1 = "FF63EB7E"
	local color2 = "FF7FB5EB"
	local stars = "*******************************************"
	self:Append(stars, color2)
	self:Append("* ", color2, true)
	self:Append("GeminiConsole v1.1.8", color1)
	self:Append(stars, color2)
	self:Append("Start typing Lua code in the box below to begin.")
	self:Append("")
	self:Append("Special commands:")
	local specialCmdFormat1 = "%-16s"
	local specialCmdFormat2 = "%-30s"
	self:Append(string.format(specialCmdFormat1, "help"), color1, true)
	self:Append(string.format(specialCmdFormat2, "Shows this help text."), nil)
	self:Append(string.format(specialCmdFormat1, "= <expr>"), color1, true)
	self:Append(string.format(specialCmdFormat2, "Evaluates <expr> and prints the result."), nil)
	self:Append(string.format(specialCmdFormat1, "inspect <expr>"), color1, true)
	self:Append(string.format(specialCmdFormat2, "Evaluates <expr> and recursively prints the result."), nil)
	self:Append(string.format(specialCmdFormat1, "reload"), color1, true)
	self:Append(string.format(specialCmdFormat2, "Reloads all addons (Reload UI)"), nil)
	self:Append(string.format(specialCmdFormat1, "cls | clear"), color1, true)
	self:Append(string.format(specialCmdFormat2, "Clears the console text."), nil)
	self:Append(string.format(specialCmdFormat1, "quit | exit"), color1, true)
	self:Append(string.format(specialCmdFormat2, "Exits WildStar."), nil)
	--self:Append("")
	self:Append(stars, color2)
	self:Append("")
end

-- Not working
function GeminiConsole:OnKeyDown(wndHandler, wndControl, strKeyName, nCode, eModifier)
	self:Append("OnKeyDown fired")
end

-- Not working
function GeminiConsole:InputKeyDown(wndHandler, wndControl, strKeyName, nScanCode, nMetakeys)
	self:Append(strKeyName)
end

-- Not working
function GeminiConsole:InputChanged(wndHandler, wndControl, strText)
	if LuaUtils:EndsWith(strText, "\n") then
		if not Apollo.IsShiftKeyDown() then
			self:SubmitInput(wndHandler, wndControl, nil)
		end
	end
end

-- Return key; delegates to SubmitInput
function GeminiConsole:OnInputEnter(wndHandler, wndControl)
	self:SubmitInput(wndHandler, wndControl, nil)
end

-- Tab key; cycle through command history
function GeminiConsole:OnWindowKeyTab(wndHandler, wndControl)
	if #self.cmdHistory < 1 then return end -- aka no history
	local entry = #self.cmdHistory+self.nTabHitCounter
	if entry < 1 then -- don't index out of the table, lets start from the newest again
		self.nTabHitCounter = 0
		entry = #self.cmdHistory+self.nTabHitCounter
	end
	self.input:SetText(self.cmdHistory[entry])
	self.nTabHitCounter = self.nTabHitCounter - 1 -- cycle "backwards" from newest to oldest
end

-- Evaluates the input and updates the console with the input+result
function GeminiConsole:SubmitInput(wndHandler, wndControl, eMouseButton)

	-- Get text input
	local sInput = self.input:GetText()
	sInput = LuaUtils:Trim(sInput)	-- Trim whitespace
	self.input:SetText("")

	-- Reset the tab hit counter
	self.nTabHitCounter = 0

	-- Empty input causes problems
	if sInput == "" then
		self.input:SetFocus();
		return
	end

	-- Command will be executed, so add to history
	table.insert(self.cmdHistory, sInput)
	self.cmdHistoryIndex = #self.cmdHistory + 1		-- Reset history index

	-- Append command to console.
	self:Append("> " .. string.gsub(sInput, "\n", "\n> "))

	-- Check for special commands

	-- Flag for beginning with "="
	local isEcho = false

	-- Help command
	if sInput == "help" then
		self:AppendHelpText()
		return

	-- Clear console special command
	elseif sInput == "clear" or sInput == "cls" then
		self.console:DestroyChildren()
		self.nonMarkupText = ""
		self.input:SetFocus()
		return

	-- Exit game special command
	elseif sInput == "quit" or sInput == "exit" then	
		ExitGame()		-- Starts 30sec countdown
		ExitNow()		-- Overrides 30sec countdown
		return

	-- "reload" special commadn to reload the UI
	elseif sInput == "reload" then
		RequestReloadUI()		-- Apollo call
		return

	-- "inspect" special command
	elseif LuaUtils:StartsWith(sInput, "inspect ") then
		sInput = string.gsub(sInput, "inspect ", "return ")		-- trick to evalutate expressions. lua.c does the same thing.

		--local inspectVar = _G[sInput]		-- Kind of a hack. Looks for global variables

		-- Parse
		local inspectLoadResult, inspectLoadError = loadstring(sInput)

		-- Execute
		if inspectLoadResult == nil or inspectLoadError then		-- Parse error
			self:Append("Error parsing expression:", kstrColorError)
			self:Append(string.gsub(sInput, "return ", ""), kstrColorError)
		else

			-- Run code in protected mode to catch runtime errors
			local status, inspectCallResult = pcall(inspectLoadResult)

			if status == false then					-- Execute error
				self:Append("Error evaluating expression:", kstrColorError)
				self:Append(inspectCallResult)
			else
				-- Use metatable for userdata
				if type(inspectCallResult) == "userdata" then
					inspectCallResult = getmetatable(inspectCallResult)
				end
				self:Append(inspect(inspectCallResult), kstrColorInspect)		-- Inspect and print
			end
		end


		self.input:SetFocus()
		return

	-- Slash Commands
	elseif LuaUtils:StartsWith(sInput, "/") then
		ChatSystemLib.Command(sInput)		-- Pass to chat system
		self.input:SetFocus()
		return

	-- Expression evaluation. Input starting with "=" will be evaluated and the result printed as a string.
	elseif LuaUtils:StartsWith(sInput, "=") then
		sInput = string.gsub(sInput, "=", "return ")			-- trick to evalutate expressions. lua.c does the same thing.
		isEcho = true
	end

	-- Parse
	local result, loadError = loadstring(sInput)

	-- Execute
	if result == nil or loadError then		-- Parse error
		self:Append("Error parsing statement:", kstrColorError)
		self:Append(loadError, kstrColorError)
	else

		-- Run code in protected mode to catch runtime errors
		local status, callResult = pcall(result)

		if status == false then			-- Execute error
			self:Append("Error executing statement:", kstrColorError)
			self:Append(callResult, kstrColorError)
		elseif isEcho then
			self:Append(callResult)		-- Print result if "="
		end
	end

	-- Refocus the input
	self.input:SetFocus()
end

-- Sets the text input to history+1
function GeminiConsole:HistoryForward(wndHandler, wndControl, eMouseButton)
	if self.cmdHistoryIndex + 1 <= #self.cmdHistory then
		self.cmdHistoryIndex = self.cmdHistoryIndex + 1
		local newText = self.cmdHistory[self.cmdHistoryIndex]
		self.input:SetText(newText)
	end
end

-- Sets the input text to history-1
function GeminiConsole:HistoryBackward(wndHandler, wndControl, eMouseButton)
	if self.cmdHistoryIndex - 1 > 0 then
		self.cmdHistoryIndex = self.cmdHistoryIndex - 1
		local newText = self.cmdHistory[self.cmdHistoryIndex]
		self.input:SetText(newText)
	end
end

-- when the close button is clicked
function GeminiConsole:OnCancel()
	self.wndMain:Show(false) -- hide the window
end

-- when the reload button is clicked
function GeminiConsole:OnReloadUI()
	RequestReloadUI()
end

-- Not working
function GeminiConsole:ConsoleChanging( wndHandler, wndControl, strNewText, strOldText, bAllowed )
	self:Append("ConsoleChanging fired.")
	self.console:SetText(strOldText)
end

-- Saves the console text to the clipboard
-- Uses a 2nd hidden EditBox since the main one uses class="MLWindow" which doesn't have the clipboard feature
function GeminiConsole:SaveToClipboard(wndHandler, wndControl, eMouseButton)
	self.clipboardWorkaround:SetText(self.nonMarkupText)
	self.clipboardWorkaround:CopyTextToClipboard()
	self.clipboardWorkaround:SetText("")
	--self:Append("Console text copied to clipboard.", kstrColorInspect)
end

function GeminiConsole:HistoryBackwardHidden( wndHandler, wndControl, eMouseButton )
	self:Append("HistoryBackwardHidden fired.")
end

function GeminiConsole:ReloadCheck( wndHandler, wndControl, eMouseButton )
	self.bShowOnReload = true
end

function GeminiConsole:ReloadUncheck( wndHandler, wndControl, eMouseButton )
	self.bShowOnReload = false
end

function GeminiConsole:OnFPSTimer()
	self.wndFPS:SetText(GameLib.GetFrameRate())
end


-----------------------------------------------------------------------------------------------
-- GeminiConsole Instance
-----------------------------------------------------------------------------------------------
local GeminiConsoleInst = GeminiConsole:new()
GeminiConsoleInst:Init()


