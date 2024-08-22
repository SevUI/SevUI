local addonName, Addon = ...;

function Addon:ShowEditPopup(addDataType)
	local popup = Addon.frame.EditPopupFrame;
	popup.BorderBox.IconSelectorEditBox:SetMaxLetters(0);

	if addDataType then
		popup.addDataType = addDataType;
		popup.data = nil;
	else
		popup.addDataType = nil;
		popup.data = Addon:GetData();
	end

	-- Move Popup
	popup:ClearAllPoints();
	if addDataType == Addon.addDataType.AddConfig or popup.data and popup.data.text then
		popup.TalentTextFrame:Show();
		popup:SetPoint("TOPRIGHT", "$parent", "TOPLEFT", 0, -65);
	else
		popup.TalentTextFrame:Hide();
		popup:SetPoint("TOPRIGHT", "$parent", "TOPLEFT", 0, -20);
	end

	popup:Show();
end

function Addon:HideEditPopup()
	Addon.frame.EditPopupFrame:Hide();
end

TalentLoadoutExEditPopupMixin = {};
function TalentLoadoutExEditPopupMixin:OnShow()
	Addon:Lock();

	IconSelectorPopupFrameTemplateMixin.OnShow(self);
	self.BorderBox.IconSelectorEditBox:SetFocus();

	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN);
	self.iconDataProvider = CreateAndInitFromMixin(IconDataProviderMixin, IconDataProviderExtraType.Spell);
	self.BorderBox.IconSelectorEditBox:OnTextChanged();

	local function OnIconSelected(selectionIndex, icon)
		self.BorderBox.SelectedIconArea.SelectedIconButton:SetIconTexture(icon);
		self.BorderBox.SelectedIconArea.SelectedIconText.SelectedIconDescription:SetText(ICON_SELECTION_CLICK);
		self.BorderBox.SelectedIconArea.SelectedIconText.SelectedIconDescription:SetFontObject(GameFontHighlightSmall);
	end

	self.IconSelector:SetSelectedCallback(OnIconSelected);
	self:Update();
end

function TalentLoadoutExEditPopupMixin:OnHide()
	IconSelectorPopupFrameTemplateMixin.OnHide(self);
	if self.iconDataProvider then
		self.iconDataProvider:Release();
		self.iconDataProvider = nil;
	end
	Addon:Unlock();
end

function TalentLoadoutExEditPopupMixin:Update()
	self.TalentTextFrame.Main.EditBox:SetText(self.data and self.data.text or "");
	self.TalentTextFrame.Main.EditBox:SetCursorPosition(0);

	self.BorderBox.IconSelectorEditBox:SetText(self.data and self.data.name or "");
	self.BorderBox.IconSelectorEditBox:HighlightText();

	local icon = self.data and self.data.icon or Addon.DEFAULT_ICON;
	self.IconSelector:SetSelectedIndex(self:GetIndexOfIcon(icon) or 1);
	self.BorderBox.SelectedIconArea.SelectedIconButton:SetIconTexture(icon);

	local getSelection = GenerateClosure(self.GetIconByIndex, self);
	local getNumSelections = GenerateClosure(self.GetNumIcons, self);
	self.IconSelector:SetSelectionsDataProvider(getSelection, getNumSelections);
	self.IconSelector:ScrollToSelectedIndex();

	self:SetSelectedIconText();
end

function TalentLoadoutExEditPopupMixin:OkayButton_OnClick()
	local newText = self.TalentTextFrame.Main.EditBox:GetText();
	local newIcon = self.BorderBox.SelectedIconArea.SelectedIconButton:GetIconTexture();
	local newName = self.BorderBox.IconSelectorEditBox:GetText();

	if not self.data or self.data.name ~= newName then
		if Addon:GetDataByName(newName) then
			return;
		end
	end

	if self.data then
		-- Edit
		self.data.name = newName;
		self.data.icon = newIcon;
		if newText and #newText > 0 then
			self.data.text = newText;
		end
	else
		-- Add
		local data = {};
		data.name = newName;
		data.icon = newIcon;
		data.text = newText and #newText > 0 and newText or nil;

		local specTable = Addon:GetSpecTable();
		if self.addDataType == Addon.addDataType.AddConfig then
			-- Add Config
			local targetIndex = Addon.selectedIndex and (Addon.selectedIndex + 1) or (#specTable + 1);
			table.insert(specTable, targetIndex, data);
			Addon.selectedIndex = targetIndex;
			Addon:SaveConfig(data.text);
		else
			-- Add Group
			local targetIndex = Addon.selectedIndex and Addon.selectedIndex or 1;
			Addon.selectedIndex = targetIndex;
			table.insert(specTable, targetIndex, data);
			data.isExpanded = true;
		end
	end

	IconSelectorPopupFrameTemplateMixin.OkayButton_OnClick(self);
	Addon:RequestUpdate();
end
