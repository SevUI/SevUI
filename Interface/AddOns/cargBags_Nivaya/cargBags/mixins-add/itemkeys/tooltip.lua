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

DESCRIPTION:
	Item keys which require tooltip parsing to work
]]
local parent, ns = ...
local cargBags = ns.cargBags

local isDF = select(4,GetBuildInfo()) >= 100000

local tipName = parent.."Tooltip"
local tooltip

local function generateTooltip()
	tooltip = CreateFrame("GameTooltip", tipName, nil)
	tooltip:SetOwner(WorldFrame, "ANCHOR_NONE") 
	tooltip:AddFontStrings( 
		tooltip:CreateFontString("$parentTextLeft1", nil, "GameTooltipText"), 
		tooltip:CreateFontString("$parentTextRight1", nil, "GameTooltipText")
	)
end

local getBindOn

if isDF then

	local bindOnStrings = {
		--ACCOUNT bound
		[ITEM_BIND_TO_ACCOUNT] = "account",
		[ITEM_ACCOUNTBOUND] = "account",
		[ITEM_BIND_TO_BNETACCOUNT] = "account",
		[ITEM_BNETACCOUNTBOUND] = "account",
		
		[ITEM_SOULBOUND] = "soul",
		[ITEM_BIND_ON_PICKUP] = "pickup",

		[ITEM_BIND_QUEST] = "quest",
		
		[ITEM_BIND_ON_EQUIP] = "equip",
		
		[ITEM_BIND_ON_USE] = "use",
	}
	
	getBindOn = function(bagID, slotID)
		local bindOn
		local info = C_TooltipInfo.GetBagItem(bagID, slotID)
		for line=1,#info.lines do
			if line > 5 then break end	--stop after this since the information should be found by now
			local args = info.lines[line].args
			if args then
				for k=1,#args do
					if args[k].field == "leftText" then
						bindOn = bindOnStrings[args[k].stringVal]
						if bindOn then
							return bindOn
						end
					end
				end
			end
		end
	end
	
else

	getBindOn = function(bagID, slotID)
		if(not tooltip) then generateTooltip() end
		tooltip:ClearLines()
		tooltip:SetBagItem(bagID, slotID)
		local bound = _G[tipName.."TextLeft2"] and _G[tipName.."TextLeft2"]:GetText()
		if(not bound) then return end

		local bindOn
		if(bound:match(ITEM_BIND_ON_EQUIP)) then bindOn = "equip"
		elseif(bound:match(ITEM_SOULBOUND)) then bindOn = "soul"
		elseif(bound:match(ITEM_BIND_QUEST)) then bindOn = "quest"
		elseif(bound:match(ITEM_BIND_TO_ACCOUNT)) then bindOn = "account"
		elseif(bound:match(ITEM_BIND_ON_PICKUP)) then bindOn = "pickup"
		elseif(bound:match(ITEM_BIND_ON_USE)) then bindOn = "use" end
		
		return bindOn
	end
	
end

cargBags.itemKeys["bindOn"] = function(i)
	if(not i.link) then return end
	
	local bindOn
	
	if not i.bindOnOld then
		bindOn = getBindOn(i.bagID, i.slotID)
	else
		-- check again because these can change during play
		if i.bindOnOld == "equip" or i.bindOnOld == "use" then
			bindOn = getBindOn(i.bagID, i.slotID)
		else
			bindOn = i.bindOnOld
		end
	end
	
	i.bindOnOld = bindOn
	return bindOn
	
end

