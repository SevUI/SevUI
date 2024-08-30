-- Clicked, a World of Warcraft keybind manager.
-- Copyright (C) 2024  Kevin Krol
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

local AceGUI = LibStub("AceGUI-3.0")

--- @class ClickedInternal
local Addon = select(2, ...)

local Helpers = Addon.BindingConfig.Helpers

Addon.BindingConfig = Addon.BindingConfig or {}

--- @class BindingInputConditionDrawer : BindingConditionDrawer
--- @field private checkbox ClickedCheckBox
--- @field private editbox? ClickedEditBox
--- @field private negated? ClickedCheckBox
local Drawer = {}

--- @protected
function Drawer:Draw()
	local drawer = self.condition.drawer --[[@as InputDrawerConfig]]

	local isAnyEnabled = FindInTableIf(self.bindings, function(binding)
		--- @type SimpleLoadOption
		local load = binding.load[self.fieldName] or self.condition.init()
		return load.selected
	end) ~= nil

	self.checkbox = Helpers:DrawConditionToggle(self.container, self.bindings, self.fieldName, self.condition, self.requestRedraw)

	if not isAnyEnabled then
		return
	end

	-- editbox
	do
		--- @param binding Binding
		--- @return string
		local function ValueSelector(binding)
			--- @type SimpleLoadOption
			local load = binding.load[self.fieldName] or self.condition.init()
			return load.value
		end

		--- @param widget ClickedEditBox
		--- @param value string
		local function OnTextChanged(widget, _, value)
			if drawer.validate ~= nil then
				value = drawer.validate(value, false)
				widget:SetText(value)
			end
		end

		--- @return string[]
		local function GetTooltipText()
			--- @type string[]
			local result = { Addon.L[drawer.label] }
			local tooltip = drawer.tooltip

			if type(tooltip) == "string" then
				table.insert(result, tooltip)
			elseif type(tooltip) == "table" then
				for _, line in ipairs(tooltip) do
					table.insert(result, line)
				end
			end

			return result
		end

		--- @param value string
		local function OnEnterPressed(_, _, value)
			value = string.trim(value)

			if drawer.validate ~= nil then
				value = drawer.validate(value, true)
			end

			for _, binding in ipairs(self.bindings) do
				--- @type SimpleLoadOption
				local load = binding.load[self.fieldName] or self.condition.init()

				if load.selected then
					load.value = value
					binding.load[self.fieldName] = load
					Clicked:ReloadBinding(binding, true)
				end
			end

			self.requestRedraw()
		end

		self.editbox = AceGUI:Create("ClickedEditBox") --[[@as ClickedEditBox]]
		self.editbox:SetCallback("OnTextChanged", OnTextChanged)
		self.editbox:SetCallback("OnEnterPressed", OnEnterPressed)
		self.editbox:SetRelativeWidth(0.5)

		Helpers:HandleWidget(self.editbox, self.bindings, ValueSelector, GetTooltipText)

		self.container:AddChild(self.editbox)
	end

	-- negate
	self.negated = Helpers:DrawNegateToggle(self.container, self.bindings, self.fieldName, self.condition, self.requestRedraw)
end

Addon.BindingConfig.BindingConditionDrawers = Addon.BindingConfig.BindingConditionDrawers or {}
Addon.BindingConfig.BindingConditionDrawers["input"] = Drawer
