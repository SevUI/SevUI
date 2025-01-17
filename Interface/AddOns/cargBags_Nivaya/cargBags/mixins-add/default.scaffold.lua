--[[
LICENSE
	cargBags: An inventory framework addon for World of Warcraft

	Copyright (C) 2010  Constantin "Cargor" Schomburg <xconstruct@gmail.com>

	cargBags is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	cargBags is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with cargBags; if not, write to the Free Software
	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

DESCRIPTION
	Provides a Scaffold that generates a default Blizz' ContainerButton

DEPENDENCIES
	mixins/api-common.lua
]]
local addon, ns = ...
local cargBags = ns.cargBags

local tonumber = tonumber
local select = select
local unpack = unpack
local math = math
local string = string

local GetContainerItemDurability = GetContainerItemDurability or C_Container.GetContainerItemDurability

local BackdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil

local showOverlayTextures = true
local onlyShowCraftingQualityOverlay = true

--[[
local S_UPGRADE_LEVEL = "^" .. gsub(ITEM_UPGRADE_TOOLTIP_FORMAT, "%%d", "(%%d+)")	-- Search pattern
local scantip = CreateFrame("GameTooltip", "ItemUpgradeScanTooltip", nil, "GameTooltipTemplate")
scantip:SetOwner(UIParent, "ANCHOR_NONE")

local function GetItemUpgradeLevel(itemLink)
	scantip:SetOwner(UIParent, "ANCHOR_NONE")
	scantip:SetHyperlink(itemLink)
	for i = 2, scantip:NumLines() do -- Line 1 = name so skip
		local text = _G["ItemUpgradeScanTooltipTextLeft"..i]:GetText()
		if text and text ~= "" then
			local currentUpgradeLevel, maxUpgradeLevel = strmatch(text, S_UPGRADE_LEVEL)
			if currentUpgradeLevel then
				return currentUpgradeLevel, maxUpgradeLevel
			end
		end
	end
	scantip:Hide()
end
]]
local function Round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

local function ItemColorGradient(perc, ...)
	if perc >= 1 then
		return select(select('#', ...) - 2, ...)
	elseif perc <= 0 then
		return ...
	end

	local num = select('#', ...) / 3
	local segment, relperc = math.modf(perc*(num-1))
	local r1, g1, b1, r2, g2, b2 = select((segment*3)+1, ...)

	return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
end

local function CreateInfoString(button, position)
	local str = button:CreateFontString(nil, "OVERLAY")
	if position == "TOP" then
		str:SetJustifyH("LEFT")
		str:SetPoint("TOPLEFT", button, "TOPLEFT", 1.5, -1.5)
	else
		str:SetJustifyH("RIGHT")
		str:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1.5, 1.5)
	end
	str:SetFont(unpack(ns.options.fonts.itemCount))

	return str
end

local function GetScreenModes()
	local curResIndex = GetCurrentResolution()
	local curRes = curResIndex > 0 and select(curResIndex, GetScreenResolutions()) or nil
	local windowedMode = Display_DisplayModeDropDown:windowedmode()
	
	local resolution = curRes or (windowedMode and GetCVar("gxWindowedResolution")) or GetCVar("gxFullscreenResolution")
	
	return resolution
end

local borderSize
local function GetBorderSizeFromScreenSize()
	if borderSize then return borderSize end
	local width, height = GetPhysicalScreenSize()
	local uiScale = UIParent:GetScale()	--GetCVar("uiScale")
	
	borderSize = 768/height/(uiScale*cBnivCfg.scale)
	return borderSize
end

local function ItemButton_Scaffold(self)
	self:SetSize(37, 37)
--[[
	local monitorIndex = (tonumber(GetCVar('gxMonitor')) or 0) + 1
	local resolution = select(GetCurrentResolution(monitorIndex), GetScreenResolutions(monitorIndex))
	local bordersize = 768/string.match(resolution, "%d+x(%d+)")/(GetCVar("uiScale")*cBnivCfg.scale)
]]
	local bordersize = GetBorderSizeFromScreenSize()	--768/string.match(GetScreenModes(), "%d+x(%d+)")/(GetCVar("uiScale")*cBnivCfg.scale)
	local name = self:GetName()
	self.Icon = _G[name.."IconTexture"]
	self.Count = _G[name.."Count"]
	self.Cooldown = _G[name.."Cooldown"]
	self.Quest = _G[name.."IconQuestTexture"]
	self.Border = CreateFrame("Frame", nil, self, BackdropTemplate)
	self.Border:SetPoint("TOPLEFT", self.Icon, 0, 0)
	self.Border:SetPoint("BOTTOMRIGHT", self.Icon, 0, 0)
	self.Border:SetBackdrop({
		edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = bordersize,
	})
	self.Border:SetBackdropBorderColor(0, 0, 0, 0)

	self.TopString = CreateInfoString(self, "TOP")
	self.BottomString = CreateInfoString(self, "BOTTOM")
end

--[[!
	Update the button with new item-information
	@param item <table> The itemTable holding information, see Implementation:GetCustomItemInfo()
	@callback OnUpdate(item)
]]
local L = cargBags:GetLocalizedTypes()
local ilvlTypes = {
	[L.ItemClass["Armor"]] = true,
	[L.ItemClass["Weapon"]] = true,
}
local ilvlSubTypes = {
--	[GetItemSubClassInfo(3,11)] = true	--Artifact Relic
}
local function ItemButton_Update(self, item)
	if item.texture then
		local tex = item.texture or (cBnivCfg.CompressEmpty and self.bgTex)
		if tex then
			self.Icon:SetTexture(tex)
			self.Icon:SetTexCoord(.08, .92, .08, .92)
		else
			self.Icon:SetColorTexture(1,1,1,0.1)
		end
	else
		if cBnivCfg.CompressEmpty then
			self.Icon:SetTexture(self.bgTex)
			self.Icon:SetTexCoord(.08, .92, .08, .92)
		else
			self.Icon:SetColorTexture(1,1,1,0.1)
		end
	end
	if(item.count and item.count > 1) then
		self.Count:SetText(item.count >= 1000 and "*" or item.count)
		self.Count:Show()
	else
		self.Count:Hide()
	end
	self.count = item.count -- Thank you Blizz for not using local variables >.> (BankFrame.lua @ 234 )
	
	if showOverlayTextures and SetItemButtonOverlay then
		if onlyShowCraftingQualityOverlay then
			ClearItemButtonOverlay(self)
			SetItemCraftingQualityOverlay(self, item.link)	--creates the CraftingQuality overlay only
		else
			SetItemButtonOverlay(self, item.link, item.quality)	--creates overlays for AzeriteEmpowered, Corrupted, Cosmetic, Conduit and CraftingQuality items
		end
		--update ProfessionQualityOverlay position
		local ovl = self.ProfessionQualityOverlay
		if ovl then
			ovl:ClearAllPoints()
			ovl:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 2)	--default: ("TOPLEFT", self, "TOPLEFT", -3, 2)
		end
	end

	-- Durability
	local dCur, dMax = GetContainerItemDurability(item.bagID, item.slotID)
	if dMax and (dMax > 0) and (dCur < dMax) then
		local dPer = (dCur / dMax * 100)
		local r, g, b = ItemColorGradient((dCur/dMax), 1, 0, 0, 1, 1, 0, 0, 1, 0)
		self.TopString:SetText(Round(dPer).."%")
		self.TopString:SetTextColor(r, g, b)
	else
		self.TopString:SetText("")
	end

	-- Item Level
	if item.link then
		if (item.type and (ilvlTypes[item.type] or item.subType and ilvlSubTypes[item.subType])) and item.level > 0 then
			self.BottomString:SetText(item.level)
			local r,g,b = GetItemQualityColor(item.rarity)
			self.BottomString:SetTextColor(r,g,b)
		else
			self.BottomString:SetText("")
		end
	else
		self.BottomString:SetText("")
	end

	self:UpdateCooldown(item)
	self:UpdateLock(item)
	self:UpdateQuest(item)

	--check for frame:GetRight() as of Patch 10 (Dragonflight) to ensure ContainerFrameItemButton_CalculateItemTooltipAnchors is not throwing errors
	--DISABLED due to lag on opening bags
	--not sure this is required any longer anyways
	--if (self.OnUpdate) and self:GetRight() then self:OnUpdate(item) end
end

--[[!
	Updates the buttons cooldown with new item-information
	@param item <table> The itemTable holding information, see Implementation:GetCustomItemInfo()
	@callback OnUpdateCooldown(item)
]]
local function ItemButton_UpdateCooldown(self, item)
	if(item.cdEnable == 1 and item.cdStart and item.cdStart > 0) then
		self.Cooldown:SetCooldown(item.cdStart, item.cdFinish)
		self.Cooldown:Show()
	else
		self.Cooldown:Hide()
	end

	if(self.OnUpdateCooldown) then self:OnUpdateCooldown(item) end
end

--[[!
	Updates the buttons lock with new item-information
	@param item <table> The itemTable holding information, see Implementation:GetCustomItemInfo()
	@callback OnUpdateLock(item)
]]
local function ItemButton_UpdateLock(self, item)
	self.Icon:SetDesaturated(item.locked)

	if(self.OnUpdateLock) then self:OnUpdateLock(item) end
end

--[[!
	Updates the buttons quest texture with new item information
	@param item <table> The itemTable holding information, see Implementation:GetCustomItemInfo()
	@callback OnUpdateQuest(item)
]]
local function ItemButton_UpdateQuest(self, item)
	if item.questID or item.isQuestItem then
		self.Border:SetBackdropBorderColor(1, 1, 0, 1)
	elseif item.rarity and item.rarity > 1 then
		local r, g, b = GetItemQualityColor(item.rarity)
		self.Border:SetBackdropBorderColor(r, g, b, 1)
	else
		self.Border:SetBackdropBorderColor(0, 0, 0, 1)
	end
	if(self.OnUpdateQuest) then self:OnUpdateQuest(item) end
end

cargBags:RegisterScaffold("Default", function(self)
	self.glowTex = "Interface\\Buttons\\UI-ActionButton-Border" --! @property glowTex <string> The textures used for the glow
	self.glowAlpha = 0.8 --! @property glowAlpha <number> The alpha of the glow texture
	self.glowBlend = "ADD" --! @property glowBlend <string> The blendMode of the glow texture
	self.glowCoords = { 14/64, 50/64, 14/64, 50/64 } --! @property glowCoords <table> Indexed table of texCoords for the glow texture
	self.bgTex = nil --! @property bgTex <string> Texture used as a background if no item is in the slot

	self.CreateFrame = ItemButton_CreateFrame
	self.Scaffold = ItemButton_Scaffold

	self.Update = ItemButton_Update
	self.UpdateCooldown = ItemButton_UpdateCooldown
	self.UpdateLock = ItemButton_UpdateLock
	self.UpdateQuest = ItemButton_UpdateQuest

	self.OnEnter = ItemButton_OnEnter
	self.OnLeave = ItemButton_OnLeave
end)
