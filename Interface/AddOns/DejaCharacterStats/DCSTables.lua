MIN_PLAYER_LEVEL_FOR_ITEM_LEVEL_DISPLAY = 1;

local ADDON_NAME, namespace = ... 	--localization
local L = namespace.L 				--localization
local _,addon = ...
local doll_tooltip_format = PAPERDOLLFRAME_TOOLTIP_FORMAT
	namespace.doll_tooltip_format = doll_tooltip_format
local highlight_code = HIGHLIGHT_FONT_COLOR_CODE
	namespace.highlight_code = highlight_code
local font_color_close = FONT_COLOR_CODE_CLOSE
	namespace.font_color_close = font_color_close
local dcs_format = format
local char_ctats_pane = CharacterStatsPane
local _, DCS_TableData = ...
local _, gdbprivate = ...
local ilvl_two_decimals, ilvl_one_decimals, ilvl_eq_av, ilvl_class_color
local unitclass, classColorString

gdbprivate.gdbdefaults.gdbdefaults.dejacharacterstatsItemLevelChecked = {
	ItemLevelEQ_AV_SetChecked = true,
	ItemLevelDecimalsSetChecked = false,
	ItemLevelTwoDecimalsSetChecked = true,
	ItemLevelClassColorSetChecked = true,
}

-----------------------
-- Item Level Checks --
-----------------------
	local DCS_ILvl_EQ_AV_Check = CreateFrame("CheckButton", "DCS_ILvl_EQ_AV_Check", DejaCharacterStatsPanel, "InterfaceOptionsCheckButtonTemplate")
	DCS_ILvl_EQ_AV_Check:RegisterEvent("PLAYER_LOGIN")
	DCS_ILvl_EQ_AV_Check:ClearAllPoints()
	DCS_ILvl_EQ_AV_Check:SetPoint("TOPLEFT", "dcsILvlPanelCategoryFS", 7, -15)
	DCS_ILvl_EQ_AV_Check:SetScale(1)
	DCS_ILvl_EQ_AV_Check.tooltipText = L["Displays Equipped/Available item levels unless equal."] --Creates a tooltip on mouseover.
	_G[DCS_ILvl_EQ_AV_Check:GetName() .. "Text"]:SetText(L["Equipped/Available"])

	DCS_ILvl_EQ_AV_Check:SetScript("OnEvent", function(self, event)
		if event == "PLAYER_LOGIN" then
			ilvl_eq_av = gdbprivate.gdb.gdbdefaults.dejacharacterstatsItemLevelChecked.ItemLevelEQ_AV_SetChecked
			self:SetChecked(ilvl_eq_av)
		end
	end)

	DCS_ILvl_EQ_AV_Check:SetScript("OnClick", function(self)
		ilvl_eq_av = not ilvl_eq_av
		gdbprivate.gdb.gdbdefaults.dejacharacterstatsItemLevelChecked.ItemLevelEQ_AV_SetChecked = ilvl_eq_av
		PaperDollFrame_UpdateStats()
	end)

local DCS_ItemLevelDecimalPlacesCheck = CreateFrame("CheckButton", "DCS_ItemLevelDecimalPlacesCheck", DejaCharacterStatsPanel, "InterfaceOptionsCheckButtonTemplate")
	DCS_ItemLevelDecimalPlacesCheck:RegisterEvent("PLAYER_LOGIN")
	DCS_ItemLevelDecimalPlacesCheck:ClearAllPoints()
	DCS_ItemLevelDecimalPlacesCheck:SetPoint("TOPLEFT", "dcsILvlPanelCategoryFS", 7, -55)
	DCS_ItemLevelDecimalPlacesCheck:SetScale(1.00)
	DCS_ItemLevelDecimalPlacesCheck.tooltipText = L["Displays average item level to one decimal place."] --Creates a tooltip on mouseover.
	_G[DCS_ItemLevelDecimalPlacesCheck:GetName() .. "Text"]:SetText(L["One Decimal Place"])

	DCS_ItemLevelDecimalPlacesCheck:SetScript("OnEvent", function(self, event)
		if event == "PLAYER_LOGIN" then
			ilvl_one_decimals = gdbprivate.gdb.gdbdefaults.dejacharacterstatsItemLevelChecked.ItemLevelDecimalsSetChecked
			self:SetChecked(ilvl_one_decimals)
		end
	end)

	DCS_ItemLevelDecimalPlacesCheck:SetScript("OnClick", function(self)
		ilvl_one_decimals = self:GetChecked() --can't be improved into ilvl_one_decimals = not ilvl_one_decimals ?
		gdbprivate.gdb.gdbdefaults.dejacharacterstatsItemLevelChecked.ItemLevelDecimalsSetChecked = ilvl_one_decimals
		if ilvl_one_decimals then
			DCS_ItemLevelTwoDecimalsCheck:SetChecked(false)
			gdbprivate.gdb.gdbdefaults.dejacharacterstatsItemLevelChecked.ItemLevelTwoDecimalsSetChecked = false
			ilvl_two_decimals = false
		end
		PaperDollFrame_UpdateStats()
	end)

local DCS_ItemLevelTwoDecimalsCheck = CreateFrame("CheckButton", "DCS_ItemLevelTwoDecimalsCheck", DejaCharacterStatsPanel, "InterfaceOptionsCheckButtonTemplate")
	DCS_ItemLevelTwoDecimalsCheck:RegisterEvent("PLAYER_LOGIN")
	DCS_ItemLevelTwoDecimalsCheck:ClearAllPoints()
	DCS_ItemLevelTwoDecimalsCheck:SetPoint("TOPLEFT", "dcsILvlPanelCategoryFS", 7, -75)
	DCS_ItemLevelTwoDecimalsCheck:SetScale(1.00)
	DCS_ItemLevelTwoDecimalsCheck.tooltipText = L["Displays average item level to two decimal places."] --Creates a tooltip on mouseover.
	_G[DCS_ItemLevelTwoDecimalsCheck:GetName() .. "Text"]:SetText(L["Two Decimal Places"])

	DCS_ItemLevelTwoDecimalsCheck:SetScript("OnEvent", function(self, event)
		if event == "PLAYER_LOGIN" then
			ilvl_two_decimals = gdbprivate.gdb.gdbdefaults.dejacharacterstatsItemLevelChecked.ItemLevelTwoDecimalsSetChecked
			self:SetChecked(ilvl_two_decimals)
		end
	end)

	DCS_ItemLevelTwoDecimalsCheck:SetScript("OnClick", function(self)
		ilvl_two_decimals = self:GetChecked()
		gdbprivate.gdb.gdbdefaults.dejacharacterstatsItemLevelChecked.ItemLevelTwoDecimalsSetChecked = ilvl_two_decimals
		if ilvl_two_decimals then
			DCS_ItemLevelDecimalPlacesCheck:SetChecked(false)
			gdbprivate.gdb.gdbdefaults.dejacharacterstatsItemLevelChecked.ItemLevelDecimalsSetChecked = false
			ilvl_one_decimals = false
		end
		PaperDollFrame_UpdateStats()
	end)

local DCS_ILvl_Class_Color_Check = CreateFrame("CheckButton", "DCS_ILvl_Class_Color_Check", DejaCharacterStatsPanel, "InterfaceOptionsCheckButtonTemplate")
	DCS_ILvl_Class_Color_Check:RegisterEvent("PLAYER_LOGIN")
	DCS_ILvl_Class_Color_Check:ClearAllPoints()
	DCS_ILvl_Class_Color_Check:SetPoint("TOPLEFT", "dcsILvlPanelCategoryFS", 7, -35)
	DCS_ILvl_Class_Color_Check:SetScale(1)
	DCS_ILvl_Class_Color_Check.tooltipText = L["Displays average item level with class colors."] --Creates a tooltip on mouseover.
	_G[DCS_ILvl_Class_Color_Check:GetName() .. "Text"]:SetText(L["Class Colors"]) --wording for both texts is really bad

	DCS_ILvl_Class_Color_Check:SetScript("OnEvent", function(self, event)
		if event == "PLAYER_LOGIN" then
			_, unitclass = UnitClass("player");
			classColorString = "|c"..RAID_CLASS_COLORS[unitclass].colorStr;
			ilvl_class_color = gdbprivate.gdb.gdbdefaults.dejacharacterstatsItemLevelChecked.ItemLevelClassColorSetChecked
			self:SetChecked(ilvl_class_color)
		end
	end)

	DCS_ILvl_Class_Color_Check:SetScript("OnClick", function(self)
		ilvl_class_color = not ilvl_class_color
		gdbprivate.gdb.gdbdefaults.dejacharacterstatsItemLevelChecked.ItemLevelClassColorSetChecked = ilvl_class_color
		PaperDollFrame_UpdateStats()
	end)

----------------------------
-- DCS Functions & Arrays --
----------------------------
function DCS_TableData:CopyTable(tab)
	local copy = {}
	for k, v in pairs(tab) do
		if k == "RUNE_REGEN" or k == "ATTACK_ATTACKSPEED" or k == "POWER" or k == "ALTERNATEMANA" then
			tab [k] = nil
		else
			copy[k] = (type(v) == "table") and DCS_TableData:CopyTable(v) or v
		end
	end
	return copy
end

function DCS_TableData:MergeTable(tab)
    local exists
	for i, v in ipairs(tab) do
        if (not self.StatData[v.statKey]) then
            table.remove(tab, i)
        end
    end
    for k in pairs(self.StatData) do
        exists = false
        for _, v in ipairs(tab) do
            if (k == v.statKey) then exists = true end
        end
        if (not exists) then
            table.insert(tab, { statKey = k })
        end
    end
    return tab
end

function DCS_TableData:SwapStat(tab, statKey, dst)
    local src
    for i, v in ipairs(tab) do
        if (v.statKey == statKey) then
            src = v
            table.remove(tab, i)
        end
    end
    for i, v in ipairs(tab) do
        if (v.statKey == dst.statKey) then
            table.insert(tab, i, src or {statKey = statKey})
            break
        end
    end
    return tab
end

DCS_TableData.StatData = DCS_TableData:CopyTable(PAPERDOLL_STATINFO)

DCS_TableData.StatData.ItemLevelFrame = {
    category   = true,
    frame      = char_ctats_pane.ItemLevelFrame,
    updateFunc = function(statFrame)
		local numSlots = 16
		local upgradeItemLevel = 0

		if GetInventorySlotInfo("SECONDARYHANDSLOT") then
			numSlots = 17
		end

		local avgItemLevel, avgItemLevelEquipped, avgItemLevelPvP = GetAverageItemLevel();
		local minItemLevel = C_PaperDollInfo.GetMinItemLevel();

		--[[@ Dragonflight launch:
			avgItemLevel is always the same as avgItemLevelPvp unless we have an item upgrade in bags.
			Then Blizzard is adding the whole number difference to indicate an available upgrade; not the average that is added.
			Example: avgItemLevel = 200 which is also the avgItemLevelPvP.
			We get a ilvl 240 bracer that is an upgrade over our current ilvl 230 bracer, a difference of 10.
			Blizzard erroneously calculates avgItemLevel = 200 + 10 = 210; showing an item in bags that will upgrade our average ilvl to 210.
			The 10 ilvls of the bracer has to be averaged over the 16 or 17 item slots to get the correct average ilvl.
			Solution: avgItemLevel = (200) + (10 / 16) = 200.625; showing the correct average ilvl of 200.625.
		]]

		avgItemLevelEquipped = math.max(minItemLevel or 0, avgItemLevelEquipped);

		-- print("\n", "Avg Ilvl: "..avgItemLevel.."\n", "Equipped Ilvl: "..avgItemLevelEquipped.."\n", "PVP Ilvl: "..avgItemLevelPvP.."\n", "Is PVP Flagged: "..tostring(UnitIsPVP("player")).."\n", "Min Ilvl: "..(minItemLevel or 0).."\n", "Upgrade Ilvl: "..upgradeItemLevel.."\n")

		statFrame.tooltip2 = STAT_AVERAGE_ITEM_LEVEL_TOOLTIP;
		-- avgItemLevel has both the gear available in bags/bank as well as PVP ilvl boost. So we subtract PVP ilvl boost from it, divide by the number of slots and add it to avgItemLevelEquipped for the available upgrade value.
		if ( avgItemLevel > avgItemLevelPvP ) then
			avgItemLevel = avgItemLevelEquipped + ( (avgItemLevel - avgItemLevelPvP) / numSlots )
		else
			statFrame.tooltip2 = statFrame.tooltip2.."\n\n"..STAT_AVERAGE_PVP_ITEM_LEVEL:format(avgItemLevelPvP);
		end

		local DCS_DecimalPlaces
		local multiplier

		if ilvl_two_decimals then
			DCS_DecimalPlaces = ("%.2f")
			multiplier = 100
		elseif ilvl_one_decimals then
			DCS_DecimalPlaces = ("%.1f")
			multiplier = 10
		else
			DCS_DecimalPlaces = ("%.0f")
			multiplier = 1
		end

		avgItemLevel = floor(multiplier*avgItemLevel)/multiplier;
		avgItemLevelEquipped = floor(multiplier*avgItemLevelEquipped)/multiplier;
		upgradeItemLevel = floor(multiplier*upgradeItemLevel)/multiplier;

		statFrame.tooltip = highlight_code..dcs_format(doll_tooltip_format, STAT_AVERAGE_ITEM_LEVEL).." "..dcs_format(DCS_DecimalPlaces, avgItemLevel);

		if ilvl_eq_av and (avgItemLevel > avgItemLevelEquipped) then
			if ilvl_class_color then
				-- Function Argument Format: PaperDollFrame_SetLabelAndText(statFrame, label, text, isPercentage, numericValue)
				PaperDollFrame_SetLabelAndText(statFrame, STAT_AVERAGE_ITEM_LEVEL, classColorString .. dcs_format(DCS_DecimalPlaces .. ("/") .. DCS_DecimalPlaces,avgItemLevelEquipped, avgItemLevel), false, avgItemLevel)
			else
				PaperDollFrame_SetLabelAndText(statFrame, STAT_AVERAGE_ITEM_LEVEL, dcs_format(DCS_DecimalPlaces .. ("/") .. DCS_DecimalPlaces,avgItemLevelEquipped, avgItemLevel), false, avgItemLevel)
			end
			local temp = DCS_DecimalPlaces .. ")"
			local format_for_avg_equipped = gsub(STAT_AVERAGE_ITEM_LEVEL_EQUIPPED, "d%)", temp,  1)
			statFrame.tooltip = statFrame.tooltip .. "  " .. dcs_format(format_for_avg_equipped, avgItemLevelEquipped);
		else
			if ilvl_class_color then
				PaperDollFrame_SetLabelAndText(statFrame, STAT_AVERAGE_ITEM_LEVEL, classColorString .. dcs_format(DCS_DecimalPlaces,avgItemLevelEquipped), false, avgItemLevelEquipped)
			else
				PaperDollFrame_SetLabelAndText(statFrame, STAT_AVERAGE_ITEM_LEVEL, dcs_format(DCS_DecimalPlaces, avgItemLevelEquipped), false, avgItemLevelEquipped)
			end
		end
		statFrame.tooltip = statFrame.tooltip .. font_color_close;

		statFrame:Show()
    end
}

DCS_TableData.StatData.GeneralCategory = {
    category   = true,
    frame      = char_ctats_pane.GeneralCategory,
    updateFunc = function()	end
}

DCS_TableData.StatData.AttributesCategory = {
    category   = true,
    frame      = char_ctats_pane.AttributesCategory,
    updateFunc = function() end
}

DCS_TableData.StatData.EnhancementsCategory = {
    category   = true,
    frame      = char_ctats_pane.EnhancementsCategory,
    updateFunc = function() end
}

DCS_TableData.StatData.OffenseCategory = {
    category   = true,
    frame      = char_ctats_pane.OffenseCategory,
    updateFunc = function()	end
}

DCS_TableData.StatData.DefenseCategory = {
    category   = true,
    frame      = char_ctats_pane.DefenseCategory,
    updateFunc = function()	end
}

DCS_TableData.StatData.RatingCategory = {
    category   = true,
    frame      = char_ctats_pane.RatingCategory,
    updateFunc = function()	end
}


DCS_TableData.StatData.HonorCategory = {
    category   = true,
    frame      = char_ctats_pane.HonorCategory,
    updateFunc = function()	end
}

function MovementSpeed_OnUpdate(statFrame, elapsedTime) --Added this so Vehicles update as well. Shouldn't be too bad if other addons access this function, but still not as clean as I would like.
	local unit = statFrame.unit;
	local currentSpeed, runSpeed, flightSpeed, swimSpeed = GetUnitSpeed(unit);
	runSpeed = runSpeed/BASE_MOVEMENT_SPEED*100;
	flightSpeed = flightSpeed/BASE_MOVEMENT_SPEED*100;
	swimSpeed = swimSpeed/BASE_MOVEMENT_SPEED*100;
	currentSpeed = currentSpeed/BASE_MOVEMENT_SPEED*100;

	-- Pets seem to always actually use run speed
	if (unit == "pet") then
		swimSpeed = runSpeed;
	end

	-- Determine whether to display running, flying, or swimming speed
	local speed = runSpeed;
	local swimming = IsSwimming(unit);
	if (UnitInVehicle(unit)) then
		local vehicleSpeed = GetUnitSpeed("Vehicle")/BASE_MOVEMENT_SPEED*100;
		speed = vehicleSpeed
	elseif (swimming) then
		speed = swimSpeed;
	elseif (UnitOnTaxi("player") ) then
		speed = currentSpeed;
	elseif (IsFlying(unit)) then
		speed = flightSpeed;
	end

	-- Hack so that your speed doesn't appear to change when jumping out of the water
	if (IsFalling(unit)) then
		if (statFrame.wasSwimming) then
			speed = swimSpeed;
		end
	else
		statFrame.wasSwimming = swimming;
	end

	local valueText = format("%d%%", speed+0.5);
	PaperDollFrame_SetLabelAndText(statFrame, STAT_MOVEMENT_SPEED, valueText, false, speed);
	statFrame.speed = speed;
	statFrame.runSpeed = runSpeed;
	statFrame.flightSpeed = flightSpeed;
	statFrame.swimSpeed = swimSpeed;
end

local move_speed  --Needs a colon like all other stats have. Concatenated so we don't have to redo every localization to include a colon.
if namespace.locale == "zhTW" then
	move_speed = L["Movement Speed"] .. "：" --Chinese colon
else
	move_speed = L["Movement Speed"] .. ":"
end
hooksecurefunc("MovementSpeed_OnUpdate", function(statFrame)
	statFrame.Label:SetText(move_speed)
end)


local SPELL_POWER_MANA = Enum.PowerType.Mana
DCS_TableData.StatData.DCS_POWER = {
	updateFunc = function(statFrame, unit)
		local powerType = SPELL_POWER_MANA --changing here as well for similarity
		local power = UnitPowerMax(unit,powerType);
		local powerText = BreakUpLargeNumbers(power);
		if power > 0 then
			PaperDollFrame_SetLabelAndText(statFrame, MANA, powerText, false, power);
			statFrame.tooltip = highlight_code..dcs_format(doll_tooltip_format, MANA).." "..powerText..font_color_close;
			statFrame.tooltip2 = _G["STAT_MANA_TOOLTIP"];
			statFrame:Show();
		else
			statFrame:Hide();
		end
	end
}

DCS_TableData.StatData.DCS_ALTERNATEMANA = {
	updateFunc = function(statFrame, unit)
		local powerType, powerToken = UnitPowerType(unit);
		if (powerToken == "MANA") then
			statFrame:Hide();
			return;
		end
		local power = UnitPowerMax(unit,powerType);
		local powerText = BreakUpLargeNumbers(power);

		if (powerToken and _G[powerToken]) then
			PaperDollFrame_SetLabelAndText(statFrame, _G[powerToken], powerText, false, power);
			statFrame.tooltip = highlight_code..dcs_format(doll_tooltip_format, _G[powerToken]).." "..powerText..font_color_close;
			statFrame.tooltip2 = _G["STAT_"..powerToken.."_TOOLTIP"];
			statFrame:Show();
		else
			statFrame:Hide();
		end
	end
}

DCS_TableData.StatData.ATTACK_AP = {
	updateFunc = function(statFrame, unit)
		local base, posBuff, negBuff;

		local rangedWeapon = IsRangedWeapon();

		local tag, tooltip;
		if ( rangedWeapon ) then
			base, posBuff, negBuff = UnitRangedAttackPower(unit);
			tag, tooltip = RANGED_ATTACK_POWER, RANGED_ATTACK_POWER_TOOLTIP;
		else
			base, posBuff, negBuff = UnitAttackPower(unit);
			tag, tooltip = MELEE_ATTACK_POWER, MELEE_ATTACK_POWER_TOOLTIP;
		end

		local damageBonus =  BreakUpLargeNumbers(max((base+posBuff+negBuff), 0)/ATTACK_POWER_MAGIC_NUMBER);
		local spellPower = 0;
		local value, valueText, tooltipText;

		if (GetOverrideAPBySpellPower() ~= 0) then --{ As pointed out by toshimoto90, GetOverrideAPBySpellPower() apparently zeros out now instead of returning nil.
			local holySchool = 2;
			-- Start at 2 to skip physical damage
			spellPower = GetSpellBonusDamage(holySchool);
			for i=(holySchool+1), MAX_SPELL_SCHOOLS do
				spellPower = min(spellPower, GetSpellBonusDamage(i));
			end
			spellPower = min(spellPower, GetSpellBonusHealing()) * GetOverrideAPBySpellPower();

			value = spellPower;
			valueText, tooltipText = PaperDollFormatStat(tag, spellPower, 0, 0);
			damageBonus = BreakUpLargeNumbers(spellPower / ATTACK_POWER_MAGIC_NUMBER);
		else
			value = base;
			valueText, tooltipText = PaperDollFormatStat(tag, base, posBuff, negBuff);
		end
		PaperDollFrame_SetLabelAndText(statFrame, STAT_ATTACK_POWER, valueText, false, value);
		statFrame.tooltip = tooltipText;

		local effectiveAP = max(0,base + posBuff + negBuff);
		if (GetOverrideSpellPowerByAP() ~= 0) then --{ As pointed out by toshimoto90, GetOverrideSpellPowerByAP() apparently zeros out now instead of returning nil. Checking both anticipating this is unintended or may otherwise change in the future.
			statFrame.tooltip2 = format(MELEE_ATTACK_POWER_SPELL_POWER_TOOLTIP, damageBonus, BreakUpLargeNumbers(effectiveAP * GetOverrideSpellPowerByAP() + 0.5));
		else
			statFrame.tooltip2 = format(tooltip, damageBonus);
		end
		statFrame:Show();
	end
}

DCS_TableData.StatData.DCS_ATTACK_ATTACKSPEED = {
	updateFunc = function(statFrame, unit)
		local meleeHaste = GetMeleeHaste();
		local speed, offhandSpeed = UnitAttackSpeed(unit);

		local displaySpeed = dcs_format("%.2f", speed);
		if ( offhandSpeed ) then
			offhandSpeed = dcs_format("%.2f", offhandSpeed);
		end
		if ( offhandSpeed ) then
			displaySpeed =  BreakUpLargeNumbers(displaySpeed).." / ".. offhandSpeed;
		else
			displaySpeed =  BreakUpLargeNumbers(displaySpeed);
		end
		PaperDollFrame_SetLabelAndText(statFrame, WEAPON_SPEED, displaySpeed, false, speed);

		statFrame.tooltip = highlight_code..dcs_format(doll_tooltip_format, ATTACK_SPEED).." "..displaySpeed..font_color_close;
		statFrame.tooltip2 = dcs_format(STAT_ATTACK_SPEED_BASE_TOOLTIP, BreakUpLargeNumbers(meleeHaste));

		statFrame:Show();
	end
}

DCS_TableData.StatData.DCS_RUNEREGEN = {
	updateFunc = function(statFrame, unit)
		if ( unit ~= "player" ) then
			statFrame:Hide();
			return;
		end

		local _, class = UnitClass(unit);
		if (class ~= "DEATHKNIGHT") then
			statFrame:Hide();
			return;
		end

		local _, regenRate = GetRuneCooldown(1); -- Assuming they are all the same for now
		if regenRate == nil then
			regenRate = 0
		end
		regenRate = tonumber(regenRate)

		local regenRateText = (dcs_format(STAT_RUNE_REGEN_FORMAT, regenRate));
		PaperDollFrame_SetLabelAndText(statFrame, STAT_RUNE_REGEN, regenRateText, false, regenRate);
		statFrame.tooltip = highlight_code..dcs_format(doll_tooltip_format, STAT_RUNE_REGEN).." "..regenRateText..font_color_close;
		statFrame.tooltip2 = STAT_RUNE_REGEN_TOOLTIP;
		statFrame:Show();
	end
}

local offhand_string = "/"..L["Off Hand"]
local white_damage_string = " "..L["weapon auto attack (white) DPS."]
DCS_TableData.StatData.WEAPON_DPS = {
    updateFunc = function(statFrame, unit)
		local function JustGetDamage(unit)
			if IsRangedWeapon() then
				local attackTime, minDamage, maxDamage = UnitRangedDamage(unit);
				return minDamage, maxDamage, nil, nil;
			else
				return UnitDamage(unit);
			end
		end
		local speed, offhandSpeed = UnitAttackSpeed(unit);
		local minDamage, maxDamage, minOffHandDamage, maxOffHandDamage = JustGetDamage(unit);
		local fullDamage = (minDamage + maxDamage)/2;
		local white_dps = fullDamage/speed
		local main_oh_dps = dcs_format("%.2f", white_dps)
		local tooltip2 = (L["Main Hand"])
		-- If there's an offhand speed then add the offhand info to the tooltip
		if ( offhandSpeed and minOffHandDamage and maxOffHandDamage ) then
			local offhandFullDamage = (minOffHandDamage + maxOffHandDamage)/2;
			local oh_dps = offhandFullDamage/offhandSpeed
			main_oh_dps = main_oh_dps .. "/" .. dcs_format("%.2f",oh_dps)
			white_dps = (white_dps + oh_dps)*(1-DUAL_WIELD_HIT_PENALTY/100)
			tooltip2 = tooltip2 .. offhand_string
		end
		tooltip2 = tooltip2 .. white_damage_string
		local misses_etc = (1+BASE_MISS_CHANCE_PHYSICAL[3]/100)*(1+BASE_ENEMY_DODGE_CHANCE[3]/100)*(1+BASE_ENEMY_PARRY_CHANCE[3]/100) -- hopefully the right formula
		white_dps = white_dps*(1 + GetCritChance()/100)/misses_etc --assumes crits do twice as damage
		white_dps = dcs_format("%.2f", white_dps)
		PaperDollFrame_SetLabelAndText(statFrame, L["Weapon DPS"], white_dps, false, white_dps)
		statFrame.tooltip = highlight_code..dcs_format(doll_tooltip_format, dcs_format(L["Weapon DPS"], main_oh_dps)).." "..dcs_format("%s", main_oh_dps)..font_color_close;
		statFrame.tooltip2 = (tooltip2);
	end
}

local function casterGCD()
	local haste = GetHaste()
	local gcd = max(0.75, 1.5 * 100 / (100+haste))
	return gcd
end

DCS_TableData.StatData.GCD = {
    updateFunc = function(statFrame)
		local spec = GetSpecialization();
		local primaryStat = select(6, GetSpecializationInfo(spec, nil, nil, nil, UnitSex("player")));
		local gcd
		local _, classfilename = UnitClass("player")

		if (classfilename == "DRUID") then
			local id = GetShapeshiftFormID()
			if (id == 1) then --cat form
				gcd = 1
			else
				gcd = casterGCD()
			end
		else
			if (primaryStat == LE_UNIT_STAT_INTELLECT) or (classfilename == "HUNTER") or (classfilename == "SHAMAN") or (primaryStat == LE_UNIT_STAT_STRENGTH) or (classfilename == "DEMONHUNTER")then
				gcd = casterGCD()
			else
				gcd = 1
			end
		end
		PaperDollFrame_SetLabelAndText(statFrame, L["Global Cooldown"], dcs_format("%.2fs",gcd), false, gcd)
		statFrame.tooltip = highlight_code..dcs_format(doll_tooltip_format, dcs_format(L["Global Cooldown"], gcd)).." "..dcs_format("%.2fs", gcd)..font_color_close;
		statFrame.tooltip2 = (L["General global cooldown refresh time."]);
	end
}

DCS_TableData.StatData.REPAIR_COST = {
    updateFunc = function(statFrame, unit)
        if (not statFrame.scanTooltip) then
            statFrame.scanTooltip = CreateFrame("GameTooltip", "StatRepairCostTooltip", statFrame, "GameTooltipTemplate")
            statFrame.scanTooltip:SetOwner(statFrame, "ANCHOR_NONE")
            statFrame.MoneyFrame = CreateFrame("Frame", "StatRepairCostMoneyFrame", statFrame, "TooltipMoneyFrameTemplate")
            MoneyFrame_SetType(statFrame.MoneyFrame, "TOOLTIP")
            statFrame.MoneyFrame:SetPoint("RIGHT", 3, -1)
            local font, size, flag = statFrame.Label:GetFont()
            statFrame.Label:SetFont(font, size, flag)
        end

        local totalCost = 0
        local _, repairCost
        for _, index in ipairs({1,3,5,6,7,8,9,10,16,17}) do
			local repairCost = C_TooltipInfo.GetInventoryItem(unit, index)
			if (repairCost) then
				-- TooltipUtil.SurfaceArgs(repairCost)
				repairCost = repairCost.repairCost
				if (repairCost and repairCost > 0) then
					totalCost = totalCost + repairCost
				end
			end
		end

		MoneyFrame_Update(statFrame.MoneyFrame, totalCost)
		statFrame.MoneyFrame:Hide()

		local totalRepairCost = GetCoinTextureString(totalCost)
		local gold = floor(totalCost / 10000)
		local silver = floor(mod(totalCost / 100, 100))
		local copper = mod(totalCost, 100)
		local displayRepairTotal = dcs_format("%dg %ds %dc", gold, silver, copper);

		--STAT_FORMAT
		-- PaperDollFrame_SetLabelAndText(statFrame, label, text, isPercentage, numericValue) -- Formatting
		PaperDollFrame_SetLabelAndText(statFrame, (L["Repair Total"]), totalRepairCost, false, displayRepairTotal);
		statFrame.tooltip = highlight_code..dcs_format(doll_tooltip_format, dcs_format(L["Repair Total"], totalRepairCost)).." "..dcs_format("%s", totalRepairCost)..font_color_close;
		statFrame.tooltip2 = (L["Total equipped item repair cost before discounts."]);
    end
}

local dura_format = L["Durability"] .." %s"
DCS_TableData.StatData.DURABILITY_STAT = {
    updateFunc = function(statFrame, unit)
		if ( unit ~= "player" ) then
			statFrame:Hide();
			return;
		end

		DCS_Mean_DurabilityCalc()

		local displayDura = dcs_format("%.2f%%", addon.duraMean);

		PaperDollFrame_SetLabelAndText(statFrame, (L["Durability"]), displayDura, false, addon.duraMean);
		statFrame.tooltip = highlight_code..dcs_format(doll_tooltip_format, dcs_format(dura_format, displayDura));
		statFrame.tooltip2 = (L["Average equipped item durability percentage."]);

		statFrame:Show();
	end
}

local rating_and_percentage = L["%s of %s increases %s by %.2f%%"]

local statnames = {
	[CR_HASTE_MELEE] = {name1 = L["Haste Rating"], name2 = STAT_HASTE},
	[CR_LIFESTEAL] = {name1 = L["Leech Rating"], name2 = STAT_LIFESTEAL},
	[CR_AVOIDANCE] = {name1 = L["Avoidance Rating"], name2 = STAT_AVOIDANCE},
	[CR_DODGE] = {name1 = L["Dodge Rating"], name2 = STAT_DODGE},
	[CR_PARRY] = {name1 = L["Parry Rating"], name2 = STAT_PARRY},
	[CR_SPEED] = {name1 = L["Speed Rating"], name2 = L["Movement Speed"]},
}

local function statframeratings(statFrame, unit, stat)
	if ( unit ~= "player" ) then
		statFrame:Hide();
		return;
	end
	local rating = GetCombatRating(stat)
	local percentage = GetCombatRatingBonus(stat)
	local ratingname = statnames [stat].name1
	local name = statnames [stat].name2
	PaperDollFrame_SetLabelAndText(statFrame, ratingname, rating, false, rating);
	statFrame.tooltip = highlight_code..ratingname.." "..rating..font_color_close;
	statFrame.tooltip2 = dcs_format(rating_and_percentage, ratingname, BreakUpLargeNumbers(rating), name, percentage);
	statFrame:Show();
end

DCS_TableData.StatData.CRITCHANCE_RATING = { -- maybe add 3 different stats - melee, ranged and spell crit ratings?
	updateFunc = function(statFrame, unit)
		if ( unit ~= "player" ) then
			statFrame:Hide();
			return;
		end
		local stat;
		local ratingname = L["Critical Strike Rating"]
		local spellCrit, rangedCrit, meleeCrit;
		-- Start at 2 to skip physical damage
		local holySchool = 2;
		local minCrit = GetSpellCritChance(holySchool);
		statFrame.spellCrit = {};
		statFrame.spellCrit[holySchool] = minCrit;
		--local spellCrit;
		for i=(holySchool+1), MAX_SPELL_SCHOOLS do
			spellCrit = GetSpellCritChance(i);
			minCrit = min(minCrit, spellCrit);
			statFrame.spellCrit[i] = spellCrit;
		end
		spellCrit = minCrit
		rangedCrit = GetRangedCritChance();
		meleeCrit = GetCritChance();

		if (spellCrit >= rangedCrit and spellCrit >= meleeCrit) then
			stat = CR_CRIT_SPELL;
		elseif (rangedCrit >= meleeCrit) then
			stat = CR_CRIT_RANGED;
		else
			stat = CR_CRIT_MELEE;
		end
		local rating = GetCombatRating(stat);
		local percentage = dcs_format("%.2f",GetCombatRatingBonus(stat));
		PaperDollFrame_SetLabelAndText(statFrame, ratingname, rating, false, rating);
		statFrame.tooltip = highlight_code..ratingname.." "..rating..font_color_close;
		statFrame.tooltip2 = dcs_format(rating_and_percentage, ratingname, BreakUpLargeNumbers(rating), STAT_CRITICAL_STRIKE, percentage);
		statFrame:Show();
	end
}

DCS_TableData.StatData.VERSATILITY_RATING = {
	updateFunc = function(statFrame, unit)
		if ( unit ~= "player" ) then
			statFrame:Hide();
			return;
		end
		local ratingname = L["Versatility Rating"]
		local versatility = GetCombatRating(CR_VERSATILITY_DAMAGE_DONE);
		local versatilityDamageBonus = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE);
		PaperDollFrame_SetLabelAndText(statFrame, ratingname, versatility, false, versatility);
		statFrame.tooltip = highlight_code..ratingname.." "..versatility..font_color_close;
		statFrame.tooltip2 = dcs_format(rating_and_percentage,ratingname, BreakUpLargeNumbers(versatility), STAT_VERSATILITY, versatilityDamageBonus);
		statFrame:Show();
	end
}

DCS_TableData.StatData.MASTERY_RATING = {
	--localisation of font colors (highlight_code and font_color_close)
	updateFunc = function(statFrame, unit)
		if ( unit ~= "player" ) then
			statFrame:Hide();
			return;
		end
		local color_rating1 = L["Mastery Rating"]
		local color_rating2
		if namespace.locale == "zhTW" then
			color_rating2 = color_rating1 .. "：" --Chinese colon
		else
			color_rating2 = color_rating1 .. ":"
		end
		local color_format = "%d"
		local add_text = ""
		local _, bonuscoeff = GetMasteryEffect();
		local stat = CR_MASTERY
		local rating = GetCombatRating(stat)
		local percentage = dcs_format("%.2f",GetCombatRatingBonus(stat)*bonuscoeff)

		PaperDollFrame_SetLabelAndText(statFrame, "", dcs_format(color_format,rating), false, rating);
		statFrame.Label:SetText(color_rating2)
		statFrame.tooltip = highlight_code..color_rating1.." "..dcs_format(color_format,rating)..add_text..font_color_close;
		statFrame.tooltip2 = dcs_format(rating_and_percentage, L["Mastery Rating"], BreakUpLargeNumbers(rating), STAT_MASTERY, percentage);
		statFrame:Show();
	end
}

DCS_TableData.StatData.HASTE_RATING = {
	updateFunc = function(statFrame, unit)
		statframeratings(statFrame, unit, CR_HASTE_MELEE)
	end
}

DCS_TableData.StatData.LIFESTEAL_RATING = {
	updateFunc = function(statFrame, unit)
		statframeratings(statFrame, unit, CR_LIFESTEAL)
	end
}

DCS_TableData.StatData.AVOIDANCE_RATING = {
	updateFunc = function(statFrame, unit)
		statframeratings(statFrame, unit, CR_AVOIDANCE)
	end
}

DCS_TableData.StatData.DODGE_RATING = {
	updateFunc = function(statFrame, unit)
		statframeratings(statFrame, unit, CR_DODGE)
	end
}

DCS_TableData.StatData.PARRY_RATING = {
	updateFunc = function(statFrame, unit)
		statframeratings(statFrame, unit, CR_PARRY)
	end
}
DCS_TableData.StatData.SPEED_RATING = {
	updateFunc = function(statFrame, unit)
		statframeratings(statFrame, unit, CR_SPEED)
	end
}

local function UpdateRatingFrame(statFrame, unit, bracketIndex, bracketString, bracketCodeName)
	return function(statFrame, unit)
		RequestRatedInfo();
		local rating = select(1, GetPersonalRatedInfo(bracketIndex));
		local ratingStr = tostring(rating);

		PaperDollFrame_SetLabelAndText(statFrame, bracketString, ratingStr, false, rating);
		statFrame.tooltip = highlight_code..dcs_format(doll_tooltip_format, bracketString).." "..ratingStr..font_color_close;
		statFrame.tooltip2 = _G["STAT_"..bracketCodeName.."_TOOLTIP"];
		statFrame:Show();
	end
end

local function RoundNumber(value, decimalPlaces)
	local roundedValue;
	local scale = 10 ^ decimalPlaces;

	roundedValue = (floor(value * scale + 0.5))/scale;

	return roundedValue;
end

local function BuildProgressAndPercentString(current, maximum)
	local str;

	if (maximum and not (maximum == 0)) then
		local percent = 100 * (current / maximum);
		local rounded = RoundNumber(percent, 2);
		str = current .. "/" .. maximum .. " (" .. rounded .. "%)";
	else
		str = "-"
	end

	return str;
end

DCS_TableData.StatData.HONOR_PROGRESS = {
	updateFunc = function(statFrame, unit)
		local currentValue = UnitHonor("player");
		local maxValue = UnitHonorMax("player");
		local honorProgressStr = BuildProgressAndPercentString(currentValue, maxValue);

		PaperDollFrame_SetLabelAndText(statFrame, "Honor", honorProgressStr, false, currentValue);
		statFrame.tooltip = highlight_code..dcs_format(doll_tooltip_format, L["Honor"]).." "..honorProgressStr..font_color_close;
		statFrame.tooltip2 = _G["STAT_HONOR_PROGRESS_TOOLTIP"];
		statFrame:Show();
	end
}

DCS_TableData.StatData.HONOR_LEVEL = {
	updateFunc = function(statFrame, unit)
		local honorLevel = UnitHonorLevel("player");
		local honorLevelStr = tostring(honorLevel);

		PaperDollFrame_SetLabelAndText(statFrame, "Honor Level", honorLevelStr, false, honorLevel);
		statFrame.tooltip = highlight_code..dcs_format(doll_tooltip_format, L["Honor Level"]).." "..honorLevelStr..font_color_close;
		statFrame.tooltip2 = _G["STAT_HONOR_LEVEL_TOOLTIP"];
		statFrame:Show();
	end
}

DCS_TableData.StatData.UserCat1 = {
    category   = true,
    frame      = char_ctats_pane.UserCat1,
    updateFunc = function()	end
}

DCS_TableData.StatData.UserCat2 = {
	category   = true,
	frame      = char_ctats_pane.UserCat2,
	updateFunc = function()	end
}

DCS_TableData.StatData.UserCat3 = {
	category   = true,
	frame      = char_ctats_pane.UserCat3,
	updateFunc = function()	end
}

DCS_TableData.StatData.UserCat4 = {
	category   = true,
	frame      = char_ctats_pane.UserCat4,
	updateFunc = function()	end
}

DCS_TableData.StatData.UserCat5 = {
	category   = true,
	frame      = char_ctats_pane.UserCat5,
	updateFunc = function()	end
}
