local addonName, Addon = ...;

Addon.DEFAULT_ICON = 134400;

Addon.icons = {
	{
		-- M+: TWW Season 1
		{525134, "Mythic Keystone", "M+"},
		{5899326, "Ara-Kara, City of Echoes", "AK"},
		{5899328, "City of Threads", "CoT"},
		{5899330, "The Dawnbreaker", "TD"},
		{5899333, "The Stonevault", "TS"},
		{3601531, "Mists of Tirna Scithe", "MoTS"},
		{3601560, "The Necrotic Wake", "NW"},
		{2011139, "Siege of Boralus", "SoB"},
		{409596, "Grim Batol", "GB"},
	},
	{
		-- Raid: Nerub-ar Palace
		{5779391, "Nerub-ar Palace"},
		{5779390, "Ulgrax the Devourer"},
		{5779386, "The Bloodbound Horror"},
		{5779389, "Sikran, Captain of the Sureki"},
		{5661707, "Rasha'nan"},
		{5688871, "Broodtwister Ovi'nax"},
		{5779388, "Nexus-Princess Ky'veza"},
		{5779387, "The Silken Court"},
		{5779391, "Queen Ansurek"},
	},
	{
		-- M+: DF Season 4
		{4352494, "Mythic Keystone", "M+"},
		{4578414, "Algeth'ar Academy", "AA"},
		{4578412, "Brackenhide Hollow", "BH"},
		{4578415, "Halls of Infusion", "HOI"},
		{4578417, "Neltharus", "NELT"},
		{4578416, "Ruby Life Pools", "RLP"},
		{4578411, "The Azure Vault", "AV"},
		{4578413, "The Nokhud Offensive", "NO"},
		{4578418, "Uldaman: Legacy of Tyr", "ULD"},
	},
	{
		-- Raid: Vault of the Incarnates
		{4630363, "Vault of the Incarnates"},
		{4630361, "Eranog"},
		{4630366, "Terros"},
		{4630359, "The Primal Council"},
		{4630365, "Sennarth, the Cold Breath"},
		{4630367, "Dathea, Ascended"},
		{4630362, "Kurog Grimtotem"},
		{4630360, "Broodkeeper Diurna"},
		{4630364, "Raszageth the Storm-Eater"},
	},
	{
		-- Raid: Aberrus, the Shadowed Crucible
		{5161748, "Aberrus, the Shadowed Crucible"},
		{5161745, "Kazzara, the Hellforged"},
		{5161743, "The Amalgamation Chamber"},
		{5161744, "The Forgotten Experiments"},
		{5161751, "Assault of the Zaqali"},
		{5161749, "Rashok, the Elder"},
		{5161752, "The Vigilant Steward, Zskarn"},
		{5161746, "Magmorax"},
		{5161747, "Echo of Neltharion"},
		{5161750, "Scalecommander Sarkareth"},
	},
	{
		-- Raid: Amirdrassil, the Dream's Hope
		{5342929, "Amirdrassil, the Dream's Hope"},
		{5342924, "Gnarlroot"},
		{5342926, "Igira the Cruel"},
		{5342928, "Volcoross"},
		{5342919, "Council of Dreams"},
		{5342927, "Larodar, Keeper of the Flame"},
		{5342920, "Nymue, Weaver of the Cycle"},
		{5342930, "Smolderon"},
		{5342923, "Tindral Sageswift, Seer of the Flame"},
		{5342925, "Fyrakk the Blazing"},
	},
};

function Addon:AddIconSelectionData()
	local LargerMacroIconSelectionData = _G["LargerMacroIconSelectionData"];
	local fileData = LargerMacroIconSelectionData:GetFileData();

	-- Add icons if there are not registered in the LargerMacroIconSelectionData.
	local additionalData = {
		-- [0000] = "inv_xxxx",
	};

	local hasAddedIcons = false;
	for key, value in pairs(additionalData) do
		hasAddedIcons = true;
		fileData[key] = value;
	end

	if hasAddedIcons then
		LargerMacroIconSelectionData.GetFileData = function()
			return fileData;
		end
	end
end

local function OnClickedIconSelectButton(button)
	local popup = Addon.frame.EditPopupFrame;
	popup.BorderBox.SelectedIconArea.SelectedIconButton:SetIconTexture(button.icon);

	if popup.SearchBox then
		popup.SearchBox:SetText(tostring(button.icon));
	end
end

function Addon:InitIconSearcher()
	_G["LargerMacroIconSelection"]:Initialize(Addon.frame.EditPopupFrame);
end

function Addon:InitIconSelector()
	local gridOffset = 46;
	local parent = Addon.frame.EditPopupFrame.IconListFrame;
	for groupIndex, group in ipairs(Addon.icons) do
		for iconIndex, iconInfo in ipairs(group) do
			--- @type table
			local IconButton = CreateFrame("Button", nil, parent, "TalentLoadoutExIconButtonTemplate");
			IconButton:SetPoint("TOPLEFT", parent, "TOPLEFT", 22 + gridOffset * (iconIndex - 1), -18 - gridOffset * (groupIndex - 1));
			IconButton.texture:SetTexture(iconInfo[1]);
			IconButton.text:SetText(iconInfo[3] or tostring(iconIndex - 1));
			IconButton.icon = iconInfo[1];
			IconButton.name = iconInfo[2];
			IconButton:SetScript("OnClick", OnClickedIconSelectButton);
		end
	end

	parent:SetHeight(gridOffset * #Addon.icons + parent:GetHeight());
end
