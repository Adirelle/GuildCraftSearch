--[[
GuildCraftSearch - A simple GUI to quickly search through the recipes known by your guildmates..
Copyright 2011-2013 Adirelle (adirelle@gmail.com)
All rights reserved.

This file is part of GuildCraftSearch.

GuildCraftSearch is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

GuildCraftSearch is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GuildCraftSearch.  If not, see <http://www.gnu.org/licenses/>.
--]]

local addonName, addon = ...

local frame = CreateFrame("Frame", addonName, UIParent)
frame:Hide()
frame:SetScript('OnEvent', function(self, event, ...) return self[event](self, event, ...) end)

local filterToSet
local function UpdateTradeSkillFrameSearchBox()
	if filterToSet and TradeSkillFrameSearchBox and TradeSkillFrameSearchBox:IsVisible() and TradeSkillFrameSearchBox:GetText() ~= filterToSet then
		TradeSkillFrameSearchBox:SetText(filterToSet)
		filterToSet = nil
	end
end

local function GuildTradeSkillFix()
	if TradeSkillFrame and IsTradeSkillGuild() and TradeSkillFrame:IsShown() then
		return TradeSkillFrame_Update()
	end
end
frame.GUILD_TRADESKILL_UPDATE = GuildTradeSkillFix
frame:RegisterEvent('GUILD_TRADESKILL_UPDATE')

frame:SetScript('OnShow', function(self)

	local waitRecipes = false
	local buttons = {}

	self:SetSize(212, 80)
	self:SetPoint("CENTER")
	self:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	})
	self:SetBackdropColor(0,0,0,1)

	local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 8, -12)
	title:SetText("Search guild crafts")

	local closeButton = CreateFrame("Button", nil, self, "UIPanelCloseButton")
	closeButton:SetPoint("TOPRIGHT", -2, -3)
	closeButton:SetScript('OnClick', function() return self:Hide() end)

	local editBox = CreateFrame("EditBox", nil, self)
	editBox:SetSize(180, 20)
	editBox:SetPoint("TOPLEFT", 16, -40)
	editBox:SetTextInsets(16, 0, 0, 0)
	editBox:SetFontObject("ChatFontSmall")
	editBox:SetText(SEARCH)
	editBox:SetAutoFocus(false)
	self.EditBox = editBox

	local icon = editBox:CreateTexture("OVERLAY")
	icon:SetSize(14, 14)
	icon:SetPoint("LEFT", -2)
	icon:SetTexture([[Interface\Common\UI-Searchbox-Icon]])
	icon:SetVertexColor(0.7, 0.7, 0.7)

	editBox:SetScript('OnEnterPressed', function(self) self:ClearFocus() end)
	editBox:SetScript('OnEscapePressed', function(self) self:ClearFocus() end)
	editBox:SetScript('OnEditFocusLost', function(self)
		if self:GetText() == "" then
			self:SetText(SEARCH)
			self:SetFontObject("GameFontDisable")
			icon:SetVertexColor(0.6, 0.6, 0.6)
		end
		self:HighlightText(0, 0)
	end)
	editBox:SetScript('OnEditFocusGained', function(self)
		if self:GetText() == SEARCH then
			self:SetText("")
			self:SetFontObject("ChatFontSmall")
			icon:SetVertexColor(1.0, 1.0, 1.0)
		end
		self:HighlightText()
	end)

	local raw_ChatEdit_InsertLink = _G.ChatEdit_InsertLink
	_G.ChatEdit_InsertLink = function(link)
		if raw_ChatEdit_InsertLink(link) then return true end
		if link and link ~= "" and editBox:IsVisible() and editBox:HasFocus() then
			local text = strmatch(link, '|h%[(.+)%]|h')
			if text then
				editBox:SetText(text)
				return true
			end
		end
		return false
	end

	local leftTexture = editBox:CreateTexture("BACKGROUND")
	leftTexture:SetSize(8, 20)
	leftTexture:SetPoint("TOPLEFT", -5, 0)
	leftTexture:SetTexture([[Interface\Common\Common-Input-Border]])
	leftTexture:SetTexCoord(0, 0.0625, 0, 0.625)

	local rightTexture = editBox:CreateTexture("BACKGROUND")
	rightTexture:SetSize(8, 20)
	rightTexture:SetPoint("RIGHT", 0, 0)
	rightTexture:SetTexture([[Interface\Common\Common-Input-Border]])
	rightTexture:SetTexCoord(0.9375, 1.0, 0, 0.625)

	local middleTexture = editBox:CreateTexture("BACKGROUND")
	middleTexture:SetSize(0, 20)
	middleTexture:SetPoint("LEFT", leftTexture, "RIGHT")
	middleTexture:SetPoint("RIGHT", rightTexture, "LEFT")
	middleTexture:SetTexture([[Interface\Common\Common-Input-Border]])
	middleTexture:SetTexCoord(0.0625, 0.9375, 0, 0.625)

	local function Button_OnClick(button)
		local text = editBox:GetText()
		if text == SEARCH then
			filterToSet = ""
		else
			filterToSet = text
		end

		if not TradeSkillFrame_Show then
			TradeSkillFrame_LoadUI()
		end
		ViewGuildRecipes(button.skillID)

		UpdateTradeSkillFrameSearchBox()
	end

	local function Button_OnEnter(button)
		GameTooltip_SetDefaultAnchor(GameTooltip, button)
		GameTooltip:AddLine(button.headerName)
		GameTooltip:AddLine(format("%d crafters in the guild,", button.numPlayers), 1, 1, 1)
		if button.numPlayers > 0 then
			GameTooltip:AddLine(format("out of which %d are online.", button.numOnline), 1, 1, 1)
		end
		GameTooltip:Show()
	end

	local function Button_OnLeave(button)
		if GameTooltip:GetOwner() == button then
			GameTooltip:Hide()
		end
	end

	function self:GUILD_TRADESKILL_UPDATE()
		GuildTradeSkillFix()
		if not frame:IsVisible() then return end

		waitRecipes = false
		local numButtons = 0
		for i = 1, GetNumGuildTradeSkill() do
			local skillID, _, iconTexture, headerName, numOnline, _, numPlayers = GetGuildTradeSkillInfo(i)
			if skillID and CanViewGuildRecipes(skillID) and iconTexture and headerName then
				numButtons = numButtons + 1
				local button = buttons[numButtons]
				if not button then
					local row, col = floor((numButtons-1) / 5), (numButtons-1) % 5
					button = CreateFrame("Button", nil, self)
					button:SetSize(32,32)
					button:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", col * 36 - 4, - 12 - row * 36)

					local icon = button:CreateTexture("BACKGROUND")
					icon:SetAllPoints(button)
					button.Icon = icon

					button:SetNormalTexture([[Interface\Buttons\UI-Quickslot2]])
					button:SetPushedTexture([[Interface\Buttons\UI-Quickslot-Depress]])
					button:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]])
					button:GetHighlightTexture():SetBlendMode("ADD")

					local t = button:GetNormalTexture()
					t:ClearAllPoints()
					t:SetPoint("TOPLEFT", -11, 11)
					t:SetPoint("BOTTOMRIGHT", 11, -11)

					button:RegisterForClicks('LeftButtonUp')
					button:SetScript('OnClick', Button_OnClick)
					button:SetScript('OnEnter', Button_OnEnter)
					button:SetScript('OnLeave', Button_OnLeave)

					buttons[numButtons] = button
				end
				button.skillID = skillID
				button.headerName = headerName
				button.numOnline = numOnline
				button.numPlayers = numPlayers
				button.Icon:SetTexture(iconTexture)
				button.Icon:SetDesaturated(numPlayers == 0)
				button:Show()
				if numPlayers > 0 then
					button:Enable()
				else
					button:Disable()
				end
			end
		end
		for i = numButtons+1, #buttons do
			buttons[i]:Hide()
		end
		self:SetHeight(80 + 36 * ceil((numButtons-1) / 5))
	end

	tinsert(UISpecialFrames, self:GetName())

	function self:OnShow()
		editBox:SetFocus()
		local text = GetTradeSkillItemNameFilter()
		if text and text ~= "" then
			editBox:SetText(text)
		end
		if not waitRecipes then
			waitRecipes = true
			QueryGuildRecipes()
		end
	end
	self:SetScript('OnShow', self.OnShow)

	self:EnableMouse(true)
	self:SetClampedToScreen(true)

	self:SetScript('OnMouseDown', function()
		if self:IsMovable() then
			self:StartMoving()
		end
	end)
	self:SetScript('OnMouseUp', function()
		if self:IsMovable() then
			self:StopMovingOrSizing()
			local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
			GuildCraftSearchDB.anchor = { point, relativeTo and relativeTo:GetName(), relativePoint, xOfs, yOfs }
		end
	end)

	return self:OnShow(self)
end)

local function OpenGUI(anchor)
	frame.anchored = not not anchor
	frame:SetMovable(not frame.anchored)
	frame:Show()
	frame:ClearAllPoints()
	if anchor then
		local scale, x, y = UIParent:GetEffectiveScale(), anchor:GetCenter()
		x, y  = x / scale, y / scale
		local uiscale, sw, sh = UIParent:GetEffectiveScale(), UIParent:GetSize()
		sw, sh = sw / uiscale, sh / uiscale
		local fromH, toH = "", ""
		local fromV, toV = "", ""
		if y < sw * 3 / 5 then
			fromV, toV = "TOP", (y < sh - 24) and "TOP" or "BOTTOM"
		else
			fromV, toV = "BOTTOM", "TOP"
		end
		if x < sw / 3 then
			fromH, toH = "LEFT", "RIGHT"
		elseif x > sw * 2 / 3 then
			fromH, toH = "RIGHT", "LEFT"
		else
			fromH, toH = "", ""
		end
		frame:SetPoint(fromV..fromH, anchor, toV..toH)
	else
		if GuildCraftSearchDB.anchor then
			frame:SetPoint(unpack(GuildCraftSearchDB.anchor))
		else
			frame:SetPoint("CENTER", UIParent, 0, 0)
		end
	end
end

SLASH_GUILDCRAFTSEARCH2 = "/guildcraftsearch"
SLASH_GUILDCRAFTSEARCH1 = "/gcs"
function SlashCmdList.GUILDCRAFTSEARCH(txt)
	OpenGUI(nil)
	if txt and txt ~= "" then
		frame.EditBox:SetText(txt)
	end
end

function frame:ADDON_LOADED(_, name)
	if name ~= addonName then return end

	if not GuildCraftSearchDB then GuildCraftSearchDB = {} end

	local dataobj = LibStub('LibDataBroker-1.1'):NewDataObject(addonName, {
		type = 'launcher',
		label = "Guild crafts",
		icon = [[Interface\ICONS\INV_Misc_Spyglass_03]],
		OnClick = OpenGUI,
	})

	LibStub('LibDBIcon-1.0'):Register(addonName, dataobj, GuildCraftSearchDB)

	self:UnregisterEvent('ADDON_LOADED')
end

frame:RegisterEvent('ADDON_LOADED')
