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

local _G = _G

--[[!
	@class ItemButton
		This class serves as the basis for all itemSlots in a container
]]
local ItemButton = cargBags:NewClass("ItemButton", nil, "Button")

--[[!
	Gets a template name for the bagID
	@param bagID <number> [optional]
	@return tpl <string>
]]
function ItemButton:GetTemplate(bagID)
	bagID = bagID or self._bagID or self:GetParent():GetID()
	return (bagID == -3 and "ReagentBankItemButtonGenericTemplate") or (bagID == -1 and "BankItemButtonGenericTemplate") or (bagID and "ContainerFrameItemButtonTemplate") or (isClassic and "ItemButtonTemplate" or ""),
      (bagID == -3 and ReagentBankFrame) or (bagID == -1 and BankFrame) or (bagID and _G["ContainerFrame"..bagID + (isClassic and 2 or 1)]);
end 

local mt_gen_key = {__index = function(self,k) self[k] = {}; return self[k]; end}

--[[!
	Fetches a new instance of the ItemButton, creating one if necessary
	@param bagID <number>
	@param slotID <number>
	@return button <ItemButton>
]]
function ItemButton:New(bagID, slotID)
	self.recycled = self.recycled or setmetatable({}, mt_gen_key)

	local tpl, parent = self:GetTemplate(bagID)
	local button = table.remove(self.recycled[tpl]) or self:Create(tpl, parent)
	button._bagID = bagID
	button._slotID = slotID
	button:SetID(slotID)
	
	if not button.GetSlotAndBagID then
		button.GetSlotAndBagID = function(f)
			return f._slotID, f._bagID
		end
	end
	
	button:Show()
	
	return button
end

--[[!
	Creates a new ItemButton
	@param tpl <string> The template to use [optional]
	@return button <ItemButton>
	@callback button:OnCreate(tpl)
]]
local bFS
function ItemButton:Create(tpl, parent)
	local impl = self.implementation
	impl.numSlots = (impl.numSlots or 0) + 1
	local name = ("%sSlot%d"):format(impl.name, impl.numSlots)

	local button
	if isClassic then
		button = setmetatable(CreateFrame("Button", name, parent, tpl), self.__index)
	else
		button = setmetatable(CreateFrame("ItemButton", name, parent, tpl), self.__index)
	end

	if(button.Scaffold) then button:Scaffold(tpl) end
	if(button.OnCreate) then button:OnCreate(tpl) end
	local btnNT = _G[button:GetName().."NormalTexture"]
	local btnNIT = button.NewItemTexture
	local btnBIT = button.BattlepayItemTexture
	if btnNT then btnNT:SetTexture("") end
	if btnNIT then btnNIT:SetTexture("") end
	if btnBIT then btnBIT:SetTexture("") end
	
	button:SetSize(ns.options.itemSlotSize, ns.options.itemSlotSize)
	bFS = _G[button:GetName().."Count"]
	bFS:ClearAllPoints()
	bFS:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1.5, 1.5);
	bFS:SetFont(unpack(ns.options.fonts.itemCount))

	return button
end

--[[!
	Frees an ItemButton, storing it for later use
]]
function ItemButton:Free()
	self:Hide()
	table.insert(self.recycled[self:GetTemplate()], self)
end

--[[!
	Fetches the item-info of the button, just a small wrapper for comfort
	@param item <table> [optional]
	@return item <table>
]]
function ItemButton:GetCustomItemInfo(item)
	return self.implementation:GetCustomItemInfo(self._bagID, self._slotID, item)
end

