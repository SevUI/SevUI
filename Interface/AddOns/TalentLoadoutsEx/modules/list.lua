local addonName, Addon = ...;

Addon.addDataType = {
	AddConfig = "Add Config",
	AddGroup = "Add Group",
};

local function OnClickToggleButton(toggleButton)
	local parent = toggleButton:GetParent();
	parent.data.isExpanded = not parent.data.isExpanded;
	Addon.selectedIndex = parent.index;
	Addon:RequestUpdate();
end

local function OnClickListButton(self, button, down)
	if Addon.isLocked then
		return;
	end

	if not self.addDataType then
		Addon.selectedIndex = self.index;
	end

	Addon.frame.ScrollBox:ForEachFrame(
		function(linkButton)
			if Addon.selectedIndex and Addon.selectedIndex == linkButton.index then
				linkButton.SelectedBar:Show();
			else
				linkButton.SelectedBar:Hide();
			end
		end
	);

	Addon:UpdatePanelButton();

	if self.addDataType then
		Addon:ShowEditPopup(self.addDataType);
	elseif IsShiftKeyDown() then
		if button == "LeftButton" then
			Addon:PostLink();
		else
			Addon:CopyLink();
		end
	end
end

local function OnDoubleClickListButton(button, ...)
	if Addon.isLocked then
		return;
	end

	Addon.selectedIndex = button.index;
	if button.addDataType then
		return;
	elseif button.data.text then
		Addon:LoadConfig();
	else
		OnClickToggleButton(button.ToggleButton);
	end
end

local function InitListButton(button, elementData)
	button.index = elementData.index;
	button.data = elementData.data;
	button.addDataType = elementData.addDataType;

	-- Reset
	button.Stripe:Hide();
	button.Check:Hide();
	button.WarningFrame:Hide();
	button.ToggleButton:Hide();
	button.SelectedBar:Hide();

	local talentsFrame = Addon.TalentsFrame;
	local treeInfo = talentsFrame:GetTreeInfo();
	local treeID = treeInfo and treeInfo.ID;
	if not treeID then
		return; -- Skip
	end

	local color = NORMAL_FONT_COLOR;
	if button.addDataType then
		-- Add Button
		button.icon:SetTexture("Interface\\PaperDollInfoFrame\\Character-Plus");
		button.icon:SetSize(30, 30);
		button.icon:SetPoint("LEFT", 7, 0);
		color = GREEN_FONT_COLOR;
	else
		-- Config or Group
		button.icon:SetTexture(button.data.icon);
		button.icon:SetSize(36, 36);
		button.icon:SetPoint("LEFT", 4, 0);

		if not button.data.text then
			-- Group
			button.Stripe:Show();
			button.ToggleButton:SetScript("OnClick", OnClickToggleButton);
			button.ToggleButton.isExpanded = button.data.isExpanded;
			button.ToggleButton:Show();
			color = BLUE_FONT_COLOR;
		elseif button.data.isLegacy then
			-- Config (Legacy)
			button.WarningMessage = Addon.LegacyWarningMessage;
			button.WarningFrame:Show();
		else
			-- Config
			local importStream = ExportUtil.MakeImportDataStream(button.data.text);
			local error = Addon:GetValidationError(treeID, importStream);
			if error then
				button.WarningMessage = error;
				button.WarningFrame:Show();
			elseif Addon:IsDataLoaded(button.data) then
				button.Check:Show();
			end
		end
	end

	button.text:SetText(button.addDataType or button.data.name);
	button.text:SetTextColor(color.r, color.g, color.b);

	button:SetScript("OnClick", OnClickListButton);
	button:SetScript("OnDoubleClick", OnDoubleClickListButton);
	if Addon.selectedIndex and Addon.selectedIndex == button.index then
		button.SelectedBar:Show();
	end
end

function Addon:InitScrollBox()
	local view = CreateScrollBoxListLinearView();
	view:SetElementInitializer("TalentLoadoutExListButtonTemplate", InitListButton)
	view:SetPadding(0,0,3,0,2);
	ScrollUtil.InitScrollBoxListWithScrollBar(Addon.frame.ScrollBox, Addon.frame.ScrollBar, view);
end

function Addon:UpdateScrollBox()
	local dataProvider = CreateDataProvider();

	local isVisible = true;
	for index, data in ipairs(Addon:GetSpecTable()) do
		if data.text then
			if isVisible then
				dataProvider:Insert({index = index, data = data});
			elseif Addon.selectedIndex and Addon.selectedIndex == index then
				Addon.selectedIndex = nil;
			end
		else
			dataProvider:Insert({index = index, data = data});
			isVisible = data.isExpanded;
		end
	end

	dataProvider:Insert({addDataType = Addon.addDataType.AddConfig});
	dataProvider:Insert({addDataType = Addon.addDataType.AddGroup});

	Addon.frame.ScrollBox:SetDataProvider(dataProvider);

	Addon:UpdatePanelButton();
	Addon:SendUpdateMessage();
end

local updateDelay = 0.1;
local lastRequestTime = nil;
function Addon:RequestUpdate()
	local now = GetTime();
	if lastRequestTime and now - lastRequestTime < updateDelay then
		return; -- Skip
	end

	lastRequestTime = now;
	C_Timer.After(
		updateDelay,
		function()
			Addon:UpdateScrollBox();
		end
	);
end

function Addon:RegisterUpdateEvent()
	Addon.frame:RegisterEvent("PLAYER_REGEN_ENABLED");
	Addon.frame:RegisterEvent("PLAYER_REGEN_DISABLED");
	Addon.frame:RegisterEvent("TRAIT_NODE_CHANGED");
	Addon.frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");
	Addon.frame:SetScript(
		"OnEvent",
		function(_, event)
			if event == "PLAYER_REGEN_ENABLED" then
				Addon:Unlock();
			elseif event == "PLAYER_REGEN_DISABLED" then
				Addon:Lock();
				Addon:HideAllPopup();
				Addon:HideEditPopup();
			else
				Addon:RequestUpdate();
			end
		end
	);
end
