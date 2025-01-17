--[[
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
	A collection of buttons for the bags.

	The buttons are not positioned automatically, use the standard-
	function :LayoutButtons() for this

DEPENDENCIES
	mixins/api-common
	mixins/parseBags (optional)
	base-add/filters.sieve.lua (optional)

CALLBACKS
	BagButton:OnCreate(bagID)
]]

local addon, ns = ...
local cargBags = ns.cargBags
local Implementation = cargBags.classes.Implementation

local isClassic = WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE

local isDF = select(4,GetBuildInfo()) >= 100000
local NumBagContainer = isDF and 5 or 4
local BankContainerStartID = NumBagContainer + 1
local MaxNumContainer = isDF and 12 or 11

local ContainerIDToInventoryID = ContainerIDToInventoryID or C_Container.ContainerIDToInventoryID

local BackdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil

function Implementation:GetBagButtonClass()
	return self:GetClass("BagButton", true, "BagButton")
end

local BagButton = cargBags:NewClass("BagButton", nil, "CheckButton")

-- Default attributes
BagButton.checkedTex = [[Interface\AddOns\cargBags_Nivaya\media\BagHighlight]]
BagButton.bgTex = [[Interface\AddOns\cargBags_Nivaya\media\BagSlot]]
BagButton.itemFadeAlpha = 0.2

local buttonNum = 0
function BagButton:Create(bagID)
    buttonNum = buttonNum+1
    local name = addon.."BagButton"..buttonNum

    local button
	if isClassic then
		button = setmetatable(CreateFrame("CheckButton", name, nil, "ItemButtonTemplate"), self.__index)
	else
		button = setmetatable(CreateFrame("ItemButton", name, nil), self.__index)
	end

    local invID = ContainerIDToInventoryID(bagID)
    button.invID = invID
    button._bagID = bagID
    button.isBag = 1
    if button._bagID <= NumBagContainer then
        -- Inventory
        button:SetID(invID)
        --button.UpdateTooltip = BagSlotButton_OnEnter
    elseif button._bagID >= BankContainerStartID then
        -- Bank
        button:SetID(buttonNum) -- bank IDs don't use the actual invID
        button.GetInventorySlot = ButtonInventorySlot
        --button.UpdateTooltip = BankFrameItemButton_OnEnter
    end

    button:RegisterForDrag("LeftButton", "RightButton")
    button:RegisterForClicks("anyUp")
    local checked = button:CreateTexture(nil, "OVERLAY")
    checked:SetTexture(self.checkedTex)
    checked:SetVertexColor(1, 0.8, 0, 0.8)
    checked:SetBlendMode("ADD")
    checked:SetAllPoints()
    button.checked = checked

    button:SetSize(32, 32)

    button.Icon =       _G[name.."IconTexture"]
    button.Count =      _G[name.."Count"]
    button.Cooldown =   _G[name.."Cooldown"]
    button.Quest =      _G[name.."IconQuestTexture"]
    button.Border =     _G[name.."NormalTexture"]
    
    button.bg = CreateFrame("Frame", nil, button, BackdropTemplate)
    button.bg:SetAllPoints(button)
    button.bg:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = false, tileSize = 16, edgeSize = 1,
    })
    button.bg:SetBackdropColor(1, 1, 1, 0)
    button.bg:SetBackdropBorderColor(0, 0, 0, 1)
    
    button.Icon:SetTexCoord(.08, .92, .08, .92)
    button.Icon:SetVertexColor(0.8, 0.8, 0.8)
    button.Border:SetAlpha(0)

    cargBags.SetScriptHandlers(button, "OnClick", "OnReceiveDrag", "OnEnter", "OnLeave", "OnDragStart")

    if(button.OnCreate) then button:OnCreate(bagID) end

    return button
end

function BagButton:GetBagID()
    return self._bagID
end

function BagButton:Update()
	local icon = GetInventoryItemTexture("player", (self.GetInventorySlot and self:GetInventorySlot()) or self.invID)
	self.Icon:SetTexture(icon or self.bgTex)
	self.Icon:SetDesaturated(IsInventoryItemLocked(self.invID))

	if(self._bagID > NumBagContainer) then	--if(self._bagID > NUM_BAG_SLOTS) then
		if(self._bagID-NumBagContainer <= GetNumBankSlots()) then	--if(self._bagID-NUM_BAG_SLOTS <= GetNumBankSlots()) then
			self.Icon:SetVertexColor(1, 1, 1)
			self.notBought = false
			self.tooltipText = BANK_BAG
		else
			self.notBought = true
			self.Icon:SetVertexColor(1, 0, 0)
			self.tooltipText = BANK_BAG_PURCHASE
		end
	end

	self.checked:SetShown(not self.hidden and not self.notBought)

	if(self.OnUpdate) then self:OnUpdate() end
end

local function highlight(button, func, bagID)
	func(button, not bagID or button._bagID == bagID)
end

local function CalculateItemTooltipAnchors(self, mainTooltip)
	local x = self:GetRight();
	local anchorFromLeft = x < GetScreenWidth() / 2;
	if ( anchorFromLeft ) then
		mainTooltip:SetAnchorType("ANCHOR_BOTTOMRIGHT", 0, 0);
		mainTooltip:SetPoint("TOPLEFT", self, "BOTTOMRIGHT");
	else
		mainTooltip:SetAnchorType("ANCHOR_BOTTOMLEFT", 0, 0);
		mainTooltip:SetPoint("TOPRIGHT", self, "BOTTOMLEFT");
	end
end

function BagButton:OnEnter()
	local hlFunction = self.bar.highlightFunction

	if(hlFunction) then
		if(self.bar.isGlobal) then
			for i, container in pairs(self.implementation.contByID) do
				container:ApplyToButtons(highlight, hlFunction, self._bagID)
			end
		else
			self.bar.container:ApplyToButtons(highlight, hlFunction, self._bagID)
		end
	end

	if self.UpdateTooltip then 
		self:UpdateTooltip()
	else
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		CalculateItemTooltipAnchors(self, GameTooltip)
		GameTooltip:SetInventoryItem("player", self.invID)
		GameTooltip:Show()
	end
end

function BagButton:OnLeave()
	local hlFunction = self.bar.highlightFunction

	if(hlFunction) then
		if(self.bar.isGlobal) then
			for i, container in pairs(self.implementation.contByID) do
				container:ApplyToButtons(highlight, hlFunction)
			end
		else
			self.bar.container:ApplyToButtons(highlight, hlFunction)
		end
	end

	GameTooltip:Hide()
end

function BagButton:OnClick()
	if(self.notBought) then
		self.checked:Hide()
		BankFrame.nextSlotCost = GetBankSlotCost(GetNumBankSlots())
		return StaticPopup_Show("CONFIRM_BUY_BANK_SLOT")
	end

	if(PutItemInBag((self.GetInventorySlot and self:GetInventorySlot()) or self.invID)) then return end

	-- Somehow we need to disconnect this from the filter-sieve
	local container = self.bar.container
	if(container and container.SetFilter) then
		if(not self.filter) then
			local bagID = self._bagID
			self.filter = function(i) return i.bagID ~= bagID end
		end
		self.hidden = not self.hidden

		if(self.bar.isGlobal) then
			for i, container in pairs(container.implementation.contByID) do
				container:SetFilter(self.filter, self.hidden)
				container.implementation:OnEvent("BAG_UPDATE", self._bagID)
			end
		else
			container:SetFilter(self.filter, self.hidden)
			container.implementation:OnEvent("BAG_UPDATE", self._bagID)
		end
	end
end
BagButton.OnReceiveDrag = BagButton.OnClick

function BagButton:OnDragStart()
	PickupBagFromSlot(self.invID)
end

-- Updating the icons
local function updater(self, event)
	for i, button in pairs(self.buttons) do
		button:Update()
	end
end

local function onLock(self, event, bagID, slotID)
	if(bagID == -1 and slotID > NUM_BANKGENERIC_SLOTS) then
		bagID, slotID = ContainerIDToInventoryID(slotID-NUM_BANKGENERIC_SLOTS+NUM_BAG_SLOTS)
	end
	
	if(slotID) then return end

	for i, button in pairs(self.buttons) do
		if(button.invID == bagID) then
			return button:Update()
		end
	end
end

local disabled = {
	[-2] = true,
	[-1] = true,
	[0] = true,
}
if isClassic then
	if GetClassicExpansionLevel() == 0 then	--is Vanilla WoW
		disabled[11] = true
	end
	disabled[12] = true
end

-- Register the plugin
cargBags:RegisterPlugin("BagBar", function(self, bags)
	if(cargBags.ParseBags) then
		bags = cargBags:ParseBags(bags)
	end

	local bar = CreateFrame("Frame",  nil, self)
	bar.container = self

	bar.layouts = cargBags.classes.Container.layouts
	bar.LayoutButtons = cargBags.classes.Container.LayoutButtons

	local buttonClass = self.implementation:GetBagButtonClass()
	bar.buttons = {}
	for i=1, #bags do
		if(not disabled[bags[i]]) then -- Temporary until I include fake buttons for backpack, bankframe and keyring
			local button = buttonClass:Create(bags[i])
			button:SetParent(bar)
			button.bar = bar
			table.insert(bar.buttons, button)
		end
	end

	self.implementation:RegisterEvent("BAG_UPDATE", bar, updater)
	self.implementation:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED", bar, updater)
	self.implementation:RegisterEvent("ITEM_LOCK_CHANGED", bar, onLock)

	return bar
end)
