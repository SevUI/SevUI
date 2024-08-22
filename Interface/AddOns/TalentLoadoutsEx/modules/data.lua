local addonName, Addon = ...;

TalentLoadoutEx = TalentLoadoutEx or { Option = { IsEnabledPvp = true }};

local localizedClass, englishClass = UnitClass("player");
Addon.className = localizedClass;
Addon.classColor = RAID_CLASS_COLORS[englishClass];

function Addon:GetSpecTable(class, spec)
	class = class or englishClass;
	spec = spec or GetSpecialization();
	TalentLoadoutEx[class] = TalentLoadoutEx[class] or {};
	TalentLoadoutEx[class][spec] = TalentLoadoutEx[class][spec] or {};
	return TalentLoadoutEx[class][spec];
end

function Addon:GetDataByName(name)
	for _, data in ipairs(Addon:GetSpecTable()) do
		if name and #name > 0 and name == data.name then
			return data;
		end
	end

	return nil;
end

function Addon:GetData(index)
	return Addon:GetSpecTable()[index or Addon.selectedIndex];
end

function Addon:IsDataLoaded(data)
	if TalentLoadoutEx.Option.IsEnabledPvp then
		for index, pvpTalentID in ipairs(C_SpecializationInfo.GetAllSelectedPvpTalentIDs()) do
			if pvpTalentID and pvpTalentID ~= tonumber(data["pvp"..index]) then
				return false;
			end
		end
	end

	local text = Addon:GetExportText();
	return text and text == data.text;
end

local function SetPvpTalent(slot, pvpTalentID)
	if pvpTalentID and (GetPvpTalentInfoByID(pvpTalentID)) then
		LearnPvpTalent(tonumber(pvpTalentID), slot); ---@diagnostic disable-line: redundant-parameter
	end
end

function Addon:SetPvpTalent(pvpTalentID1, pvpTalentID2, pvpTalentID3)
	if not TalentLoadoutEx.Option.IsEnabledPvp then
		return;
	end

	local isUIErrorsFrameShown = UIErrorsFrame and UIErrorsFrame:IsShown();
	if isUIErrorsFrameShown then
		UIErrorsFrame:Hide();
		C_Timer.After(
			1,
			function()
				UIErrorsFrame:Clear();
				UIErrorsFrame:Show();
			end
		);
	end

	SetPvpTalent(3, pvpTalentID3 or pvpTalentID1);
	SetPvpTalent(2, pvpTalentID2 or pvpTalentID1);
	SetPvpTalent(1, pvpTalentID1);
end

function Addon:LoadConfig()
	local data = Addon:GetData();
	if data then
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
		if data.isLegacy then
			Addon:Print("Legacy format text is obsolated.");
		else
			Addon:ImportText(data.text);
			Addon:SetPvpTalent(data.pvp1, data.pvp2, data.pvp3);
			Addon:SendUpdateMessage();
		end
	end
end

function Addon:SavePvpTalent(pvpTalentID1, pvpTalentID2, pvpTalentID3)
	if not TalentLoadoutEx.Option.IsEnabledPvp then
		return;
	end

	local data = Addon:GetData();
	if data then
		data.pvp1 = pvpTalentID1;
		data.pvp2 = pvpTalentID2;
		data.pvp3 = pvpTalentID3;
	end
end

function Addon:SaveConfig(text)
	text = text and #text > 0 and text or Addon:GetExportText();
	local data = Addon:GetData();
	if text and data then
		data.text = text;
		data.isLegacy = nil;

		if TalentLoadoutEx.Option.IsEnabledPvp then
			Addon:SavePvpTalent(unpack(C_SpecializationInfo.GetAllSelectedPvpTalentIDs()));
		end
	end
end

-- Swap group1 and group2.
local function SwapGroupOrder(groupIndex1, groupIndex2, groupIndex3)
	local specTable = Addon:GetSpecTable();
	for _ = 1, groupIndex2 - groupIndex1 do
		if groupIndex3 then
			table.insert(specTable, groupIndex3, specTable[groupIndex1]);
		else
			table.insert(specTable, specTable[groupIndex1]);
		end

		table.remove(specTable, groupIndex1);
	end
end

function Addon:MoveUp()
	if Addon.selectedIndex and Addon.selectedIndex > 1 then
		local specTable = Addon:GetSpecTable();
		local target = specTable[Addon.selectedIndex];

		if target.text then
			-- Config
			specTable[Addon.selectedIndex] = specTable[Addon.selectedIndex - 1];
			specTable[Addon.selectedIndex - 1] = target;

			local preGroupIndex = nil;
			for index = 1, Addon.selectedIndex - 2 do
				local data = specTable[index];
				if not data.text then
					preGroupIndex = index;
				end
			end

			if preGroupIndex then
				specTable[preGroupIndex].isExpanded = true;
			end

			Addon.selectedIndex = Addon.selectedIndex - 1;
		else
			-- Group
			local groupIndex1 = nil;
			local groupIndex2 = Addon.selectedIndex;
			local groupIndex3 = nil;

			for index, data in ipairs(specTable) do
				if not data.text then
					if index < Addon.selectedIndex then
						groupIndex1 = index;
					elseif index > Addon.selectedIndex then
						groupIndex3 = index;
						break;
					end
				end
			end

			if groupIndex1 then
				SwapGroupOrder(groupIndex1, groupIndex2, groupIndex3);
				Addon.selectedIndex = groupIndex1;
			end
		end

		Addon:RequestUpdate();
	end
end

function Addon:MoveDown()
	local specTable = Addon:GetSpecTable();
	if Addon.selectedIndex and Addon.selectedIndex < #specTable then
		local target = specTable[Addon.selectedIndex];

		if target.text then
			-- Config
			specTable[Addon.selectedIndex] = specTable[Addon.selectedIndex + 1];
			specTable[Addon.selectedIndex + 1] = target;

			if not specTable[Addon.selectedIndex].text then
				specTable[Addon.selectedIndex].isExpanded = true;
			end

			Addon.selectedIndex = Addon.selectedIndex + 1;
		else
			-- Group
			local groupIndex1 = Addon.selectedIndex;
			local groupIndex2 = nil;
			local groupIndex3 = nil;

			for index, data in ipairs(specTable) do
				if not data.text then
					if index > Addon.selectedIndex then
						if not groupIndex2 then
							groupIndex2 = index;
						else
							groupIndex3 = index;
							break;
						end
					end
				end
			end

			if groupIndex2 then
				SwapGroupOrder(groupIndex1, groupIndex2, groupIndex3);
				Addon.selectedIndex = groupIndex1 + (groupIndex3 or #specTable + 1) - groupIndex2;
			end
		end

		Addon:RequestUpdate();
	end
end

function Addon:DeleteData()
	local specTable = Addon:GetSpecTable();
	local data = Addon.selectedIndex and specTable[Addon.selectedIndex];
	if data then
		table.remove(specTable, Addon.selectedIndex);
		table.wipe(data);
	end

	if not specTable[Addon.selectedIndex] then
		Addon.selectedIndex = nil;
	end
end

local function GetNewName(name, isGroup)
	local nameDictionary = {};
	local specTable = Addon:GetSpecTable();
	for _, data in ipairs(specTable) do
		nameDictionary[data.name] = true;
	end

	local prefix = name and #name > 0 and name or (isGroup and "New Group" or "New Config");
	if not nameDictionary[prefix] then
		return prefix;
	end

	local number = 1
	while true do
		number = number + 1;
		local newName = string.format("%s %02d", prefix, number);
		if not nameDictionary[newName] then
			return newName;
		end
	end
end

function Addon:ImportDataText(lines)
	local tempData = {};
	local tempDataList = {};
	for line in lines:gmatch("([^\r\n]*)[\r\n]?") do
		if line:match("^# ?") then
			if not tempData.name then
				tempData.name = line:gsub("^# ?", "");
			else
				for text in line:gmatch("([0-9]+)") do
					if not tempData.icon then
						tempData.icon = tonumber(text);
					elseif not tempData.pvp1 then
						tempData.pvp1 = tonumber(text);
					elseif not tempData.pvp2 then
						tempData.pvp2 = tonumber(text);
					else
						tempData.pvp3 = tonumber(text);
					end
				end
			end
		else
			if #line > 0 then
				-- Config
				tempData.text = line;
				table.insert(tempDataList, tempData);
			elseif tempData.name then
				table.insert(tempDataList, tempData);
			else
				-- Blank line
			end

			tempData = {};
		end
	end

	if tempData.name then
		table.insert(tempDataList, tempData);
	end

	local specTable = Addon:GetSpecTable();
	if #specTable > 0 and tempDataList[1] and tempDataList[1].text then
		table.insert(tempDataList, 1, {});
	end

	for _, data in ipairs(tempDataList) do
		if data.text then
			-- Config
			table.insert(
				specTable,
				{
					name = GetNewName(data.name),
					icon = data.icon or Addon.DEFAULT_ICON,
					pvp1 = data.pvp1,
					pvp2 = data.pvp2,
					pvp3 = data.pvp3,
					text = data.text,
				}
			);
		else
			-- Group
			table.insert(
				specTable,
				{
					name = GetNewName(data.name, true),
					icon = data.icon or Addon.DEFAULT_ICON,
					isExpanded = true;
				}
			);
		end
	end
end

function Addon:GetSpecDataText()
	local text = "";
	local specTable = Addon:GetSpecTable();
	for _, data in ipairs(specTable) do
		if not data.text then
			-- Group
			text = string.format("%s# %s\n# %s\n\n", text, data.name, data.icon);
		elseif not data.isLegacy then
			-- Config
			-- Legacy data cannot cxport.
			text = string.format("%s# %s\n# %s", text, data.name, data.icon);

			if TalentLoadoutEx.Option.IsEnabledPvp then
				text = data.pvp1 and string.format("%s/%s", text, data.pvp1) or text;
				text = data.pvp2 and string.format("%s/%s", text, data.pvp2) or text;
				text = data.pvp3 and string.format("%s/%s", text, data.pvp3) or text;
			end

			text = string.format("%s\n%s\n\n", text, data.text);
		end
	end

	return text;
end

function Addon:UpdateData()
	-- Add Option
	TalentLoadoutEx.Option = TalentLoadoutEx.Option or {};
	if TalentLoadoutEx.Option.IsEnabledPvp == nil then
		TalentLoadoutEx.Option.IsEnabledPvp = true;
	end

	-- Remove nil data
	-- Fix PvP Talent ID
	for className, classTable in pairs(TalentLoadoutEx) do
		if className ~= "Option" then
			for specIndex, specTable in ipairs(classTable) do
				local fixedTable = {};

				-- Don't use ipairs because of a bug that can cause nil data to be mixed in.
				for _, data in pairs(specTable) do
					if data then
						data.pvp1 = tonumber(data.pvp1);
						data.pvp2 = tonumber(data.pvp2);
						data.pvp3 = tonumber(data.pvp3);
						table.insert(fixedTable, data);
					end
				end

				classTable[specIndex] = fixedTable;
			end
		end
	end
end

Addon:RegisterAddonLoad(addonName, true, "UpdateData");
