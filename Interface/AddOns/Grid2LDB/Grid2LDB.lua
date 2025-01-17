--[[ Simple DataBroker launcher for Grid2. Created by Michael --]]

local DataBroker = LibStub("LibDataBroker-1.1", true)
if not DataBroker then return end

local L = LibStub:GetLibrary("AceLocale-3.0"):GetLocale("Grid2")

local Grid2Layout = Grid2Layout

local MenuLayoutsShow

local GetAddOnInfo = C_AddOns and C_AddOns.GetAddOnInfo or GetAddOnInfo

local Grid2LDB = DataBroker:NewDataObject("Grid2", {
	type  = "launcher",
	label = GetAddOnInfo("Grid2", "Title"),
	icon  = "Interface\\AddOns\\Grid2\\media\\icon",
	OnClick = function(self, button)
		if button=="LeftButton" then
			Grid2:OnChatCommand()
		elseif button=="RightButton" then
			MenuLayoutsShow()
		end
	end,
	OnTooltipShow = function(tooltip)
		tooltip:AddLine(Grid2.versionstring)
		tooltip:AddDoubleLine( L["Profile"], Grid2.db:GetCurrentProfile(), 255,255,255, 255,255,0)
		tooltip:AddDoubleLine( L["Theme"],   select(2,Grid2:GetCurrentTheme()) , 255,255,255, 255,255,0)
		tooltip:AddDoubleLine( L["Layout"], L[Grid2Layout.layoutName or ""], 255,255,255, 255,255,0)
		for _,func in pairs(Grid2.tooltipFunc) do
			func(tooltip)
		end
		tooltip:AddLine("|cFFff4040Left Click|r to open configuration\n|cFFff4040Right Click|r to open layouts menu", 0.2, 1, 0.2)
	end,
})

local icon = LibStub("LibDBIcon-1.0")
if icon then
	icon:Register("Grid2", Grid2LDB, Grid2.db.global.minimapIcon or Grid2Layout.db.shared.minimapIcon)
	Grid2Layout.minimapIcon = icon
end

--
-- Layouts popup menu
--
do
	local menuFrame
	local partyType
	local instType
	local layoutName
	local menuTable = {}
	local function SetLayout(self)
		if not InCombatLockdown() then
			layoutName    = self.value
			local key     = Grid2Layout.instMaxPlayers
			local layouts = Grid2Layout.db.profile.layouts
			if not layouts[key] then
				key = partyType.."@"..instType
				if not layouts[key] then key = partyType end
			end
			layouts[key] = layoutName
			Grid2Layout:ReloadLayout()
		end
	end
	local function SetVisibility(self)
		Grid2Layout:FrameVisibility(self.value)
	end
	local function CreateMenuTable()
		layoutName = Grid2Layout.layoutName
		if partyType~=Grid2Layout.partyType or instType~=Grid2Layout.instType then
			-- layouts
			local L = LibStub:GetLibrary("AceLocale-3.0"):GetLocale("Grid2")
			wipe(menuTable)
			partyType = Grid2Layout.partyType
			instType = Grid2Layout.instType
			menuTable[#menuTable+1] = { text = L["Select Layout"],  notCheckable= true, isTitle = true }
			for name, layout in pairs(Grid2Layout.layoutSettings) do
				if layout.meta[partyType] and name~="None" then
					menuTable[#menuTable+1] = { func= SetLayout, text = L[name], value = name, checked = function() return name == layoutName end }
				end
			end
			sort(menuTable, function(a,b) if a.isTitle then return true elseif b.isTitle then return false else return a.text<b.text end end )
			-- Visibility
			table.insert( menuTable, 1, { func= SetVisibility, text = L["Never"],   value = 'Never',   checked = function() return Grid2Layout.db.profile.FrameDisplay == 'Never' end } )
			table.insert( menuTable, 1, { func= SetVisibility, text = L["Raid"],    value = 'Raid',    checked = function() return Grid2Layout.db.profile.FrameDisplay == 'Raid' end } )
			table.insert( menuTable, 1, { func= SetVisibility, text = L["Grouped"], value = 'Grouped', checked = function() return Grid2Layout.db.profile.FrameDisplay == 'Grouped' end } )
			table.insert( menuTable, 1, { func= SetVisibility, text = L["Always"],  value = 'Always',  checked = function() return Grid2Layout.db.profile.FrameDisplay == 'Always' end } )
			table.insert( menuTable, 1, { text = L["Grid2 Visibility"],  notCheckable= true, isTitle = true } )
			-- Movement
			table.insert( menuTable, 1, { func= function() Grid2Layout:FrameLock() end, text = L["Locked"], value = '',  checked = function() return Grid2Layout.db.profile.FrameLock end, isNotRadio=true, keepShownOnClick=1 } )
			table.insert( menuTable, 1, { text = L["Grid2 Movement"],  notCheckable= true, isTitle = true } )
		end
	end
	local EasyMenu_Initialize = EasyMenu_Initialize or function(frame, level, menuList)
		for index = 1, #menuList do
			local value = menuList[index]
			if value.text then value.index = index; UIDropDownMenu_AddButton(value, level) end
		end
	end
	local EasyMenu = EasyMenu or function(menuList, menuFrame, anchor, x, y, displayMode, autoHideDelay)
		if displayMode=='MENU' then menuFrame.displayMode = displayMode end
		UIDropDownMenu_Initialize(menuFrame, EasyMenu_Initialize, displayMode, nil, menuList)
		ToggleDropDownMenu(1, nil, menuFrame, anchor, x, y, menuList, nil, autoHideDelay)
	end
	MenuLayoutsShow= function()
		menuFrame= menuFrame or CreateFrame("Frame", "Grid2LDBLayoutsMenu", UIParent, "UIDropDownMenuTemplate")
		CreateMenuTable()
		EasyMenu(menuTable, menuFrame, "cursor", 0 , 0, "MENU", 1)
	end
end
