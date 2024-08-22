local addonName, Addon = ...;

local function ConvertToImportLoadoutEntryInfo(specID, configID, treeID, loadoutContent)
	local loadoutEntryInfo = Addon.TalentsFrame:ConvertToImportLoadoutEntryInfo(configID, treeID, loadoutContent);
	local nodeOrder = Addon:GetNodeOrder(specID, configID, treeID);
	table.sort(
		loadoutEntryInfo,
		function(a, b)
			return nodeOrder[a.nodeID] < nodeOrder[b.nodeID];
		end
	);

	return loadoutEntryInfo;
end

local function CommitTalent(configID)
	if configID and Addon.ApplyButton.isShown and Addon.ApplyButton.isEnabled then
		-- When applying Talent from an addon, a taint error may occur.
		-- If there are too many reports of this occurring, I will discontinue this feature.
		-- Addon.TalentsFrame:CommitConfig();

		-- It looks a little worse than it is, but this one does not cause taint error.
		C_Traits.CommitConfig(configID);
	end
end

local starterBuildDeactiveFrame = CreateFrame("Frame");
function Addon:ImportText(importText)
	local talentsFrame = Addon.TalentsFrame;
	if not talentsFrame then
		Addon:Print("Error: TalentsFrame is not exists.");
		return;
	end

	local configID = C_ClassTalents.GetActiveConfigID();
	if not configID then
		Addon:Print("Error: C_ClassTalents.GetActiveConfigID() = nil");
		return;
	end

	if importText == Addon:GetExportText() then
		CommitTalent(configID);
		return;
	end

	local treeInfo = talentsFrame:GetTreeInfo();
	local treeID = treeInfo and treeInfo.ID;
	local importStream = ExportUtil.MakeImportDataStream(importText);

	local error = Addon:GetValidationError(treeID, importStream);
	if error then
		Addon:Print(error);
		return;
	end

	if C_ClassTalents.GetStarterBuildActive() then
		local eventName = "TRAIT_CONFIG_UPDATED";
		starterBuildDeactiveFrame:RegisterEvent(eventName);
		starterBuildDeactiveFrame:SetScript(
			"OnEvent",
			function(_, event, ...)
				if event == eventName and (...) == configID then
					starterBuildDeactiveFrame:UnregisterAllEvents();
					Addon:ImportText(importText);
				end
			end
		);

		C_ClassTalents.SetStarterBuildActive(false);
		return;
	end

	C_Timer.After(
		0,
		function()
			Addon.isLocked = true;
			C_Traits.ResetTree(configID, treeID);
			local specID = PlayerUtil.GetCurrentSpecID();
			local loadoutContent = talentsFrame:ReadLoadoutContent(importStream, treeID);
			local loadoutEntryInfo = ConvertToImportLoadoutEntryInfo(specID, configID, treeID, loadoutContent);

			for _, entry in ipairs(loadoutEntryInfo) do
				local result = true;
				local errorRank = nil;
				local nodeInfo = C_Traits.GetNodeInfo(configID, entry.nodeID);
				if nodeInfo.type == Enum.TraitNodeType.Single or nodeInfo.type == Enum.TraitNodeType.Tiered then
					for rank = 1, entry.ranksPurchased do
						result = C_Traits.PurchaseRank(configID, entry.nodeID);
						if not result then
							errorRank = rank;
							break;
						end
					end
				else
					-- Enum.TraitNodeType.Selection or Enum.TraitNodeType.SubTreeSelection
					result = C_Traits.SetSelection(configID, entry.nodeID, entry.selectionEntryID);
				end

				if not result then
					local entryInfo = entry.selectionEntryID and C_Traits.GetEntryInfo(configID, entry.selectionEntryID);
					local definitionInfo = entryInfo and entryInfo.definitionID and C_Traits.GetDefinitionInfo(entryInfo.definitionID);

					if definitionInfo then
						local name = definitionInfo.overrideName;
						if not name then
							local spellInfo = definitionInfo.spellID and C_Spell.GetSpellInfo(definitionInfo.spellID);
							name = spellInfo and spellInfo.name;
						end

						if not name then
							Addon:Print("Error: Loadout entry cannot use.");
							DevTools_Dump(entry);
							break;
						elseif errorRank and entry.ranksPurchased > 1 then
							Addon:Print(string.format("Cannot Learn: %s (%d)", name, errorRank));
						else
							Addon:Print(string.format("Cannot Learn: %s", name));
						end
					end
				end
			end

			Addon.isLocked = false;
		end
	);
end
