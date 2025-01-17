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
]]
local addon, ns = ...
local cargBags = ns.cargBags

local isClassic = WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE
local isCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local isDF = select(4,GetBuildInfo()) >= 100000
local NumBagContainer = isDF and 5 or 4
local BankContainerStartID = NumBagContainer + 1
local MaxNumContainer = isDF and 12 or 11

local GetContainerNumSlots = GetContainerNumSlots or C_Container.GetContainerNumSlots
local GetContainerItemLink = GetContainerItemLink or C_Container.GetContainerItemLink
local GetContainerItemCooldown = GetContainerItemCooldown or C_Container.GetContainerItemCooldown
local GetContainerItemEquipmentSetInfo = isRetail and (GetContainerItemEquipmentSetInfo or C_Container.GetContainerItemEquipmentSetInfo)
local CloseBankFrame = CloseBankFrame or C_Bank.CloseBankFrame	

local animaSpells = {
	[336327] = true,
	[336456] = true,
	[345706] = true,
	[347555] = true,
}
local function IsAnimaItem(itemId)
	local n,spellId = GetItemSpell(itemId or 0)
	return spellId and animaSpells[spellId]
end

local korthianRelictSpells = {
	[356931] = true,	--currently unused
	[356933] = true,
	[356934] = true,
	[356935] = true,	--currently unused
	[356936] = true,
	[356937] = true,	--currently unused
	[356938] = true,
	[356939] = true,
	[356940] = true,
}
local function IsKorthianRelictItem(itemId)
	local n,spellId = GetItemSpell(itemId or 0)
	return spellId and korthianRelictSpells[spellId]
end

--[[!
	@class Implementation
		The Implementation-class serves as the basis for your cargBags-instance, handling
		item-data-fetching and dispatching events for containers and items.
]]
local Implementation = cargBags:NewClass("Implementation", nil, "Button")
Implementation.instances = {}
Implementation.itemKeys = {}

local toBagSlot = cargBags.ToBagSlot
local L

--[[!
	Creates a new instance of the class
	@param name <string>
	@return impl <Implementation>
]]
function Implementation:New(name)
	if(self.instances[name]) then return error(("cargBags: Implementation '%s' already exists!"):format(name)) end
	if(_G[name]) then return error(("cargBags: Global '%s' for Implementation is already used!"):format(name)) end

	local impl = setmetatable(CreateFrame("Button", name, UIParent), self.__index)
	impl.name = name

	impl:SetAllPoints()
	impl:EnableMouse(nil)
	impl:Hide()

	cargBags.SetScriptHandlers(impl, "OnEvent", "OnShow", "OnHide")

	impl.contByID = {} --! @property contByID <table> Holds all child-Containers by index
	impl.contByName = {} --!@ property contByName <table> Holds all child-Containers by name
	impl.buttons = {} -- @property buttons <table> Holds all ItemButtons by bagSlot
	impl.bagSizes = {} -- @property bagSizes <table> Holds the size of all bags
	impl.events = {} -- @property events <table> Holds all event callbacks
	impl.notInited = true -- @property notInited <bool>

	tinsert(UISpecialFrames, name) 

	self.instances[name] = impl

	return impl
end

--[[!
	Script handler, inits and updates the Implementation when shown
	@callback OnOpen
]]
function Implementation:OnShow()
	if(self.notInited) then
		if not(InCombatLockdown()) then -- initialization of bags in combat taints the itembuttons within - Lars Norberg
			self:Init()
		else
			return
		end
	end

	if(self.OnOpen) then self:OnOpen() end
	self:OnEvent("BAG_UPDATE")
end

--[[!
	Script handler, closes the Implementation when hidden
	@callback OnClose
]]
function Implementation:OnHide()
	if(self.notInited) then return end

	if(self.OnClose) then self:OnClose() end
	if(self:AtBank()) then CloseBankFrame() end
end

--[[!
	Toggles the implementation
	@param forceopen <bool> Only open it
]]
function Implementation:Toggle(forceopen)
	if(not forceopen and self:IsShown()) then
		self:Hide()
	else
		self:Show()
	end
end

--[[!
	Fetches an implementation by name
	@param name <string>
	@return impl <Implementation>
]]
function Implementation:Get(name)
	return self.instances[name]
end

--[[!
	Fetches a child-Container by name
	@param name <string>
	@return container <Container>
]]
function Implementation:GetContainer(name)
	return self.contByName[name]
end

--[[!
	Fetches a implementation-owned class by relative name

	The relative class names are prefixed by the name of the implementation
	e.g. :GetClass("Button") -> ImplementationButton
	It is just to prevent people from overwriting each others classes

	@param name <string> The relative class name
	@param create <bool> Creates it, if it doesn't exist
	@param ... Arguments to pass to cargBags:NewClass(name, ...) when creating
	@return class <table> The class prototype
]]
function Implementation:GetClass(name, create, ...)
	if(not name) then return end

	name = self.name..name
	local class = cargBags.classes[name]
	if(class or not create) then return class end

	class = cargBags:NewClass(name, ...)
	class.implementation = self
	return class
end

--[[!
	Wrapper for :GetClass() using a Container
	@note Container-classes have the full name "ImplementationNameContainer"
	@param name <string> The relative container class name
	@return class <table> The class prototype
]]
function Implementation:GetContainerClass(name)
	return self:GetClass((name or "").."Container", true, "Container")
end

--[[!
	Wrapper for :GetClass() using an ItemButton
	@note ItemButton-Classes have the full name "ImplementationNameItemButton"
	@param name <string> The relative itembutton class name
	@return class <table> The class prototype
]]
function Implementation:GetItemButtonClass(name)
	return self:GetClass((name or "").."ItemButton", true, "ItemButton")
end

--[[!
	Sets the ItemButton class to use for spawning new buttons
	@param name <string> The relative itembutton class name
	@return class <table> The newly set class
]]
function Implementation:SetDefaultItemButtonClass(name)
	self.buttonClass = self:GetItemButtonClass(name)
	return self.buttonClass
end

--[[!
	Registers the implementation to overwrite Blizzards Bag-Toggle-Functions
	@note This function only works before PLAYER_LOGIN and can be overwritten by other Implementations
]]
function Implementation:RegisterBlizzard()
	cargBags:RegisterBlizzard(self)
end

local _registerEvent = UIParent.RegisterEvent
local _isEventRegistered = UIParent.IsEventRegistered

--[[!
	Registers an event callback - these are only called if the Implementation is currently shown
	The events do not have to be 'blizz events' - they can also be internal messages
	@param event <string> The event to register for
	@param key Something passed to the callback as arg #1, also serves as identification
	@param func <function> The function to call on the event
]]
function Implementation:RegisterEvent(event, key, func)
	local events = self.events
	
	if(not events[event]) then
		events[event] = {}
	end

	events[event][key] = func
	if(event:upper() == event and not _isEventRegistered(self, event)) then
		_registerEvent(self, event)
	end
end

--[[!
	Returns whether the Implementation has the specified event callback
	@param event <string> The event of the callback
	@param key The identification of the callback [optional]
]]
function Implementation:IsEventRegistered(event, key)
	return self.events[event] and (not key or self.events[event][key])
end

--[[!
	Script handler, dispatches the events
]]
function Implementation:OnEvent(event, ...)
	if(not (self.events[event] and self:IsShown())) then return end

	for key, func in pairs(self.events[event]) do
		func(key, event, ...)
	end
end

--[[!
	Inits the implementation by registering events
	@callback OnInit
]]
function Implementation:Init()
	if(not self.notInited) then return end
	
	 -- initialization of bags in combat taints the itembuttons within - Lars Norberg
	if (InCombatLockdown()) then
		local L = LibStub("gLocale-1.0"):GetLocale(addon, true)
		if (L) then
			UIErrorsFrame:AddMessage(L["Can't initialize bags while engaged in combat."], 1.0, 0.82, 0.0, 1.0)
			UIErrorsFrame:AddMessage(L["Please exit combat then re-open the bags!"], 1.0, 0.82, 0.0, 1.0)
		end

		return
	end
	
	self.notInited = nil

	if(self.OnInit) then self:OnInit() end

	if(not self.buttonClass) then
		self:SetDefaultItemButtonClass()
	end

	self:RegisterEvent("BAG_UPDATE", self, self.BAG_UPDATE)
	self:RegisterEvent("BAG_UPDATE_COOLDOWN", self, self.BAG_UPDATE_COOLDOWN)
	self:RegisterEvent("ITEM_LOCK_CHANGED", self, self.ITEM_LOCK_CHANGED)
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED", self, self.PLAYERBANKSLOTS_CHANGED)
	if isRetail then
		self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED", self, self.PLAYERREAGENTBANKSLOTS_CHANGED)
	end
	self:RegisterEvent("BANKFRAME_OPENED", self, self.BANKFRAME_OPENED)
	self:RegisterEvent("UNIT_QUEST_LOG_CHANGED", self, self.UNIT_QUEST_LOG_CHANGED)
	self:RegisterEvent("BAG_CLOSED", self, self.BAG_CLOSED)
end

--[[!
	Returns whether the user is currently at the bank
	@return atBank <bool>
]]
function Implementation:AtBank()
	return cargBags.atBank
end

--[[
	Fetches a button by bagID-slotID-pair
	@param bagID <number>
	@param slotID <number>
	@return button <ItemButton>
]]
function Implementation:GetButton(bagID, slotID)
	return self.buttons[toBagSlot(bagID, slotID)]
end

--[[!
	Stores a button by bagID-slotID-pair
	@param bagID <number>
	@param slotID <number>
	@param button <ItemButton> [optional]
]]
function Implementation:SetButton(bagID, slotID, button)
	self.buttons[toBagSlot(bagID, slotID)] = button
end

local defaultItem = cargBags:NewItemTable()

--[[!
	Fetches the itemInfo of the item in bagID/slotID into the table
	@param bagID <number>
	@param slotID <number>
	@param i <table> [optional]
	@return i <table>
]]
local ilvlTypes = {
	[GetItemClassInfo(4)] = true,	--Armor
	[GetItemClassInfo(2)] = true,	--Weapon
}
local ilvlSubTypes = {
--	[GetItemSubClassInfo(3,11)] = true	--Artifact Relic
}
--[[
local cB_TT_Name = "cargBagsContainerItemTooltip"
local cB_TT= CreateFrame("GameTooltip", cB_TT_Name, nil, "GameTooltipTemplate")
local itemLevelString = _G["ITEM_LEVEL"]:gsub("%%d", "")
local itemDB = {}
local function GetContainerItemLevel(link, bagID, slotID)
	if itemDB[link] then return itemDB[link] end
	cB_TT:SetOwner(UIParent, "ANCHOR_NONE")
	cB_TT:SetBagItem(bagID, slotID)
 	for i = 2, 5 do
		local text = _G[cB_TT_Name.."TextLeft"..i]:GetText() or ""
		local hasLevel = string.find(text, itemLevelString)
		if hasLevel then
			local level = string.match(text, "(%d+)%)?$")
			itemDB[link] = tonumber(level)
			break
		end
	end
	return itemDB[link]
end]]


function Implementation:GetCustomItemInfo(bagID, slotID, i)
	i = i or defaultItem
	for k in pairs(i) do i[k] = nil end

	i.bagID = bagID
	i.slotID = slotID

	local clink = GetContainerItemLink(bagID, slotID)
	
	if(clink) then
		local _
		if GetContainerItemInfo then
			i.texture, i.count, i.locked, i.quality, i.readable, _, _, _, _, i.id, i.isBound = GetContainerItemInfo(bagID, slotID)
		--	i.cdStart, i.cdFinish, i.cdEnable = GetContainerItemCooldown(bagID, slotID)
		else
			local cInfo = C_Container.GetContainerItemInfo(bagID, slotID)
			i.texture = cInfo.iconFileID
			i.count = cInfo.stackCount
			i.locked = cInfo.isLocked
			i.quality = cInfo.quality
			i.readable = cInfo.isReadable
			i.id = cInfo.itemID
			i.isBound = cInfo.isBound
		end
		if isClassic then
			i.cdStart, i.cdFinish, i.cdEnable = GetContainerItemCooldown(bagID, slotID)
			i.isQuestItem, i.questID, i.questActive = nil, nil, nil
			i.isInSet, i.setName = nil, nil
		else
			if GetContainerItemQuestInfo then
				i.isQuestItem, i.questID, i.questActive = GetContainerItemQuestInfo(bagID, slotID)
			else
				local qInfo = C_Container.GetContainerItemQuestInfo(bagID, slotID)
				i.isQuestItem = qInfo.isQuestItem
				i.questID = qInfo.questID
				i.questActive = qInfo.isActive
			end
			i.isInSet, i.setName = GetContainerItemEquipmentSetInfo(bagID, slotID)
		end

		-- *edits by Lars "Goldpaw" Norberg for WoW 5.0.4 (MoP)
		-- last return value here, "texture", doesn't show for battle pets
		local texture
		i.name, i.link, i.rarity, i.level, i.minLevel, i.type, i.subType, i.stackCount, i.equipLoc, texture, i.sellPrice, i.classID, i.subClassID  = GetItemInfo(clink)
		if isClassic then
			if i.type == cBnivL.Quest then
				i.isQuestItem = true
			end
		end
		-- get the first link return because otherwise ilvl for artifacts will bug
		i.link = clink
		-- get the actual item level for items we want it to be shown
		if (i.type and (ilvlTypes[i.type] or i.subType and ilvlSubTypes[i.subType])) and i.level > 0 then
			if i.rarity == LE_ITEM_QUALITY_ARTIFACT then
				-- for artifact weapons, GetItemInfo returns the actual ilvl
			else
				i.level = GetDetailedItemLevelInfo(clink) or i.level	--GetContainerItemLevel(clink, bagID, slotID) or i.level
			end
		end
		-- get the item spell to determine if the item is an Artifact Power boosting item
		if isRetail and ns.options.filterArtifactPower and IsAnimaItem(i.id) then	--IsArtifactPowerItem(i.id) then
			i.type = POWER_TYPE_ANIMA
		end
		-- texture
		i.texture = i.texture or texture
		-- battle pet info must be extracted from the itemlink
		if isRetail then
			if (clink:find("battlepet")) then
				if not(L) then
					L = cargBags:GetLocalizedTypes()
				end
				local data, name = strmatch(clink, "|H(.-)|h(.-)|h")
				local  _, _, level, rarity, _, _, _, id = strmatch(data, "(%w+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)")
				i.type = L.ItemClass["Battle Pets"]
				i.rarity = tonumber(rarity) or 0
				i.id = tonumber(id) or 0
				i.name = name
				i.minLevel = level
			elseif (clink:find("Hkeystone")) then
				local data, name = strsplit("[", clink)
				i.name = strsplit("]", name)
				if not i.id then
					i.id = 180653	--138019
				end
				_, _, i.rarity, i.level, i.minLevel, i.type, i.subType, i.stackCount, i.equipLoc, texture, i.sellPrice  = GetItemInfo(i.id)
			end
		end
		--print("GetItemInfo:", i.isInSet, i.setName, i.name)
	end
	return i
end

--[[!
	Updates the defined slot, creating/removing buttons as necessary
	@param bagID <number>
	@param slotID <number>
]]
local function nope() end
function Implementation:UpdateSlot(bagID, slotID)
	local item = self:GetCustomItemInfo(bagID, slotID)
	local button = self:GetButton(bagID, slotID)
	local container = self:GetContainerForItem(item, button)

	if(container) then
		if(button) then
			if(container ~= button.container) then
				button.container:RemoveButton(button)
				container:AddButton(button)
			end
		else
			button = self.buttonClass:New(bagID, slotID)
			self:SetButton(bagID, slotID, button)
			container:AddButton(button)
		end

		button:Update(item)
	elseif(button) then
		button.container:RemoveButton(button)
		self:SetButton(bagID, slotID, nil)
		button:Free()

	end
end

local closed
local bagIDstart = ((isClassic and not Cata) and -2) or -1
local bagIDtoIgnore = {}
if not KeyRingButtonIDToInvSlotID then
	bagIDtoIgnore[-2] = true
end

--[[!
	Updates a bag and its containing slots
	@param bagID <number>
]]
function Implementation:UpdateBag(bagID)
	if bagIDtoIgnore[bagID] then return end
	local numSlots
	if(closed) then
		numSlots, closed = 0
	else
		numSlots = GetContainerNumSlots(bagID)
	end
	local lastSlots = self.bagSizes[bagID] or 0
	self.bagSizes[bagID] = numSlots

	for slotID=1, numSlots do
		self:UpdateSlot(bagID, slotID)
	end
	for slotID=numSlots+1, lastSlots do
		local button = self:GetButton(bagID, slotID)
		if(button) then
			button.container:RemoveButton(button)
			self:SetButton(bagID, slotID, nil)
			button:Free()
		end
	end
end

--[[!
	Updates a set of items
	@param bagID <number> [optional]
	@param slotID <number> [optional]
	@callback Container:OnBagUpdate(bagID, slotID)
]]
function Implementation:BAG_UPDATE(event, bagID, slotID)
	if bagIDtoIgnore[bagID] then return end
	if(bagID and slotID) then
		self:UpdateSlot(bagID, slotID)
	elseif(bagID) then
		self:UpdateBag(bagID)
	else
		for bagID = bagIDstart, MaxNumContainer do
			self:UpdateBag(bagID)
		end
	end
end

--[[!
	Updates a bag of the implementation (fired when it is removed)
	@param bagID <number>
]]
function Implementation:BAG_CLOSED(event, bagID)
	if bagIDtoIgnore[bagID] then return end
	closed = bagID
	self:BAG_UPDATE(event, bagID)
end

--[[!
	Fired when the item cooldowns need to be updated
	@param bagID <number> [optional]
]]
function Implementation:BAG_UPDATE_COOLDOWN(event, bagID)
	if bagIDtoIgnore[bagID] then return end
	if(bagID) then
		for slotID=1, GetContainerNumSlots(bagID) do
			local button = self:GetButton(bagID, slotID)
			if(button) then
				local item = self:GetCustomItemInfo(bagID, slotID)
				button:UpdateCooldown(item)
			end
		end
	else
		for id, container in pairs(self.contByID) do
			for i, button in pairs(container.buttons) do
				local slotID, bagID = button:GetSlotAndBagID()
				local item = self:GetCustomItemInfo(bagID, slotID)
				button:UpdateCooldown(item)
			end
		end
	end
end

--[[!
	Fired when the item is picked up or released
	@param bagID <number>
	@param slotID <number> [optional]
]]
function Implementation:ITEM_LOCK_CHANGED(event, bagID, slotID)
	if(not slotID) then return end
	if bagIDtoIgnore[bagID] then return end

	local button = self:GetButton(bagID, slotID)
	if(button) then
		local item = self:GetCustomItemInfo(bagID, slotID)
		button:UpdateLock(item)
	end
end

--[[!
	Fired when bank bags or slots need to be updated
	@param bagID <number>
	@param slotID <number> [optional]
]]
function Implementation:PLAYERBANKSLOTS_CHANGED(event, bagID, slotID)
	if(bagID <= NUM_BANKGENERIC_SLOTS) then
		slotID = bagID
		bagID = -1
	else
		bagID = bagID - NUM_BANKGENERIC_SLOTS
	end

	self:BAG_UPDATE(event, bagID, slotID)
end

--[[!
	Fired when reagent bank slots need to be updated
	@param bagID <number>
	@param slotID <number> [optional]
]]
if isRetail then
	function Implementation:PLAYERREAGENTBANKSLOTS_CHANGED(event, slotID)
		local bagID = -3

		self:BAG_UPDATE(event, bagID, slotID)
	end
end

function Implementation:BANKFRAME_OPENED(event)
	if isRetail then
		local bagID = -3

		self:BAG_UPDATE(event, bagID)
	end
end


--[[
	Fired when the quest log of a unit changes
]]
function Implementation:UNIT_QUEST_LOG_CHANGED(event)
	for id, container in pairs(self.contByID) do
		for i, button in pairs(container.buttons) do
			local slotID, bagID = button:GetSlotAndBagID()
			local item = self:GetCustomItemInfo(bagID, slotID)
			button:UpdateQuest(item)
		end
	end
end
