local addonName, Addon = ...;

function Addon:ShowTextFrame(title)
	Addon.isLocked = true;
	Addon:UpdatePanelButton();
	Addon.frame.TextPopupFrame.Header:Setup(title);
	Addon.frame.TextPopupFrame:Show();
end

function Addon:ShowDataImportFrame()
	Addon.frame.TextPopupFrame.Main.ScrollFrame.ScrollText:SetText("");
	Addon.frame.TextPopupFrame.Main.ImportButton:Show();
	Addon.frame.TextPopupFrame.Main.CancelButton:Show();
	Addon.frame.TextPopupFrame.Main.CloseButton:Hide();
	Addon:ShowTextFrame("Import");
end

function Addon:ShowDataExportFrame()
	Addon.frame.TextPopupFrame.Main.ImportButton:Hide();
	Addon.frame.TextPopupFrame.Main.CancelButton:Hide();
	Addon.frame.TextPopupFrame.Main.CloseButton:Show();

	local text = Addon:GetSpecDataText();
	Addon.frame.TextPopupFrame.Main.ScrollFrame.ScrollText:SetText(text);
	Addon.frame.TextPopupFrame.Main.ScrollFrame.ScrollText:HighlightText();
	Addon:ShowTextFrame("Export");
end

function Addon:InitPanelButtons()
	Addon.frame.ImportButton:SetScript("OnClick", function() Addon:ShowDataImportFrame(); end);
	Addon.frame.ExportButton:SetScript("OnClick", function() Addon:ShowDataExportFrame(); end);
	Addon.frame.LoadButton:SetScript("OnClick", function() Addon:LoadConfig(); end);
	Addon.frame.SaveButton:SetScript("OnClick", function() Addon:ShowConfirmSavePopup(); end);
	Addon.frame.EditButton:SetScript("OnClick", function() Addon:ShowEditPopup(); end);
	Addon.frame.DeleteButton:SetScript("OnClick", function() Addon:ShowConfirmDeletePopup(); end);
	Addon.frame.UpButton:SetScript("OnClick", function() Addon:MoveUp(); end);
	Addon.frame.DownButton:SetScript("OnClick", function() Addon:MoveDown(); end);
end

function Addon:InitTextPopupFrame()
	Addon.frame.TextPopupFrame:SetScript(
		"OnHide",
		function()
			Addon.isLocked = false;
			Addon:UpdatePanelButton();
		end
	);

	Addon.frame.TextPopupFrame.Main.ImportButton:SetScript(
		"OnClick",
		function()
			local text = Addon.frame.TextPopupFrame.Main.ScrollFrame.ScrollText:GetText();
			Addon:ImportDataText(text);
			Addon:UpdateScrollBox();
			Addon.frame.TextPopupFrame:Hide();
		end
	);

	Addon.frame.TextPopupFrame.Main.ImportButton:SetEnabled(true);
	Addon.frame.TextPopupFrame.Main.CancelButton:SetEnabled(true);
	Addon.frame.TextPopupFrame.Main.CloseButton:SetEnabled(true);
end

function Addon:UpdatePanelButton()
	Addon.frame.ImportButton:SetEnabled(false);
	Addon.frame.ExportButton:SetEnabled(false);
	Addon.frame.LoadButton:SetEnabled(false);
	Addon.frame.SaveButton:SetEnabled(false);
	Addon.frame.EditButton:SetEnabled(false);
	Addon.frame.DeleteButton:SetEnabled(false);
	Addon.frame.UpButton:SetEnabled(false);
	Addon.frame.DownButton:SetEnabled(false);

	if Addon.isLocked then
		return;
	end

	Addon.frame.ImportButton:SetEnabled(true);
	Addon.frame.ExportButton:SetEnabled(true);

	local data = Addon:GetData();
	if data then
		Addon.frame.EditButton:SetEnabled(true);
		Addon.frame.DeleteButton:SetEnabled(true);
		Addon.frame.UpButton:SetEnabled(true);
		Addon.frame.DownButton:SetEnabled(true);

		if data.text then
			Addon.frame.LoadButton:SetEnabled(true);
			Addon.frame.SaveButton:SetEnabled(true);
		end
	end
end

local defaultOffsetX = 0;
local defaultOffsetY = -41;
local function SetMoveParentFrame()
	local parent = Addon.frame:GetParent();
	hooksecurefunc(
		parent,
		"StopMovingOrSizing", 
		function()
			Addon.isParentMoved = true;
		end
	);
	hooksecurefunc(
		parent,
		"Show",
		function(self)
			if not Addon.isParentMoved then
				local point, _, relativePoint, offsetX, offsetY = self:GetPoint();
				if point == "TOP" and relativePoint == "TOP" and offsetX == defaultOffsetX and offsetY == defaultOffsetY then
					self:AdjustPointsOffset(Addon.frame:GetWidth() / -2, 0);
				end
			end
		end
	);
end

local function InitPvpFrame()
	local checkButton = Addon.frame.PvpFrame.CheckButton;
	checkButton:SetChecked(TalentLoadoutEx.Option.IsEnabledPvp);
	checkButton:SetScript(
		"OnClick",
		function(self)
			TalentLoadoutEx.Option.IsEnabledPvp = self:GetChecked();
			Addon:UpdateScrollBox();
		end
	);
end

local function SetShown()
	local talentsFrame = Addon.TalentsFrame;
	local isShown = talentsFrame:IsShown() and talentsFrame.ApplyButton:IsShown();
	Addon.ApplyButton.isShown = isShown;

	if isShown then
		Addon:UpdateScrollBox();
	end

	Addon.frame:SetShown(isShown);
end

Addon.ApplyButton = {};
Addon.ApplyButton.isShown = false;
Addon.ApplyButton.isEnabled = false;
function Addon:InitFrame()
	Addon.ParentFrame = PlayerSpellsFrame;
	Addon.frame = CreateFrame("Frame", "TalentLoadoutExMainFrame", Addon.ParentFrame, "TalentLoadoutExMainFrameTemplate");
	SetMoveParentFrame();
	InitPvpFrame();

	Addon.TalentsFrame = Addon.ParentFrame.TalentsTab or Addon.ParentFrame.TalentsFrame;
	hooksecurefunc(Addon.TalentsFrame, "SetShown", SetShown);
	hooksecurefunc(Addon.TalentsFrame.ApplyButton, "SetShown", SetShown);

	hooksecurefunc(
		Addon.TalentsFrame.ApplyButton,
		"SetEnabled",
		function(_, enabled)
			Addon.ApplyButton.isEnabled = enabled;
		end
	);

	Addon:InitPanelButtons();
	Addon:InitTextPopupFrame();
	Addon:InitScrollBox();

	Addon:RequestUpdate();
	Addon:RegisterUpdateEvent();

	Addon:InitIconSelector();
	Addon:RegisterAddonLoad("LargerMacroIconSelection", false, "InitIconSearcher");
	Addon:RegisterAddonLoad("LargerMacroIconSelectionData", false, "AddIconSelectionData");
end
