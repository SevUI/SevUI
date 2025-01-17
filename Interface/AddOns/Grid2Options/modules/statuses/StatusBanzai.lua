local L = Grid2Options.L

local GetSpellInfo = Grid2.API.GetSpellInfo

local function MakeOptions(self, status, options, optionParams)
	self:MakeStatusColorOptions(status, options, optionParams)
	options.update = {
		type = "range",
		order = 20,
		name = L["Update rate"],
		desc = L["Rate at which the status gets updated"],
		min = 0.1,
		max = 5,
		step = 0.05,
		bigStep = 0.1,
		get = function () return status.dbx.updateRate or 0.2 end,
		set = function (_, v) status:SetUpdateRate(v) end,
	}
	if Grid2.isClassic then -- only banzai-threat exist in classic
		options.notAlwaysActive = {
			type = "toggle",
			name = L["Enabled only in combat"],
			desc = L["Track banzai threat only when the player is in combat."],
			width = "full",
			order = 30,
			get = function () return not status.dbx.alwaysActive end,
			set = function (_, v)
				status.dbx.alwaysActive = (not v) or nil
				status:Refresh()
			end,
		}
	end
	if status.dbx.type=='banzai' then
		options.spellsHeader = { type = "header", order = 49, name = L["Spells"] }
		options.useWhiteList = {
			type = "toggle",
			name = L["Whitelist"],
			desc = L["Display only the spells specified in a user defined list."],
			order = 50,
			get = function () return status.dbx.spells~=nil and not status.dbx.useBlackList end,
			set = function (_, v)
				status.dbx.useBlackList = nil
				if v then
					status.dbx.spells = status.dbx.spells or status.dbx.spellsBack or {}
					status.dbx.spellsBack = nil
				else
					status.dbx.spellsBack = status.dbx.spells
					status.dbx.spells = nil
				end
				status:Refresh()
			end,
		}
		options.useBlackList = {
			type = "toggle",
			name = L["Blacklist"],
			desc = L["Ignore spells specified in a user defined list."],
			order = 60,
			get = function () return status.dbx.spells~=nil and status.dbx.useBlackList end,
			set = function (_, v)
				if v then
					status.dbx.spells = status.dbx.spells or status.dbx.spellsBack or {}
					status.dbx.spellsBack = nil
					status.dbx.useBlackList = true
				else
					status.dbx.spellsBack = status.dbx.spells
					status.dbx.spells = nil
					status.dbx.useBlackList = nil
				end
				status:Refresh()
			end,
		}
		options.spellsList = {
			type = "input", dialogControl = "Grid2ExpandedEditBox",
			order = 100,
			width = "full",
			name = "",
			multiline = 16,
			get = function()
				local auras = {}
				for _,aura in pairs(status.dbx.spells) do
					auras[#auras+1]= (type(aura)=="number") and GetSpellInfo(aura) or aura
				end
				return table.concat( auras, "\n" )
			end,
			set = function(_, v)
				wipe(status.dbx.spells)
				local auras = { strsplit("\n,", strtrim(v)) }
				for _,name in pairs(auras) do
					local aura = strtrim(name)
					if #aura>0 then
						table.insert(status.dbx.spells, tonumber(aura) or aura )
					end
				end
				status:Refresh()
			end,
			hidden = function() return status.dbx.spells==nil end
		}
	end
end

Grid2Options:RegisterStatusOptions("banzai", "combat", MakeOptions, {
	title = L["hostile casts against raid members"],
	titleIcon = "Interface\\Icons\\Spell_shadow_deathscream"
})

Grid2Options:RegisterStatusOptions("banzai-threat", "combat", MakeOptions, {
	title = L["advanced threat detection"],
	titleIcon = "Interface\\Icons\\Spell_shadow_deathscream"
})
