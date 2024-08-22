local _AddonName, _EchoRaidTools = ...
local _Notes = _EchoRaidTools:GetModule("Notes")

local LibSharedMedia = LibStub:GetLibrary ("LibSharedMedia-3.0")

EchoRaidTools_NoteFrameMixin = {}
function EchoRaidTools_NoteFrameMixin:OnLoad()
    self.Text = self.ParentFrame.Text
    self.ResizeButton.target = self
    self:SetUpDisplayBorder()

    self.BG:SetVertexColor(_Notes.GetBackgroundRGBA())

    local monoFont = LibSharedMedia:Fetch("font", "Ubuntu")
    self.Text:SetFont(monoFont, 12)
end
function EchoRaidTools_NoteFrameMixin:OnEnter()
    if not _Notes.GetLock() then
        self.ResizeButton:SetAlpha(1)
    end
end
function EchoRaidTools_NoteFrameMixin:OnLeave()
    self.ResizeButton:SetAlpha(0)
end
function EchoRaidTools_NoteFrameMixin:OnMouseDown()
    if not _Notes.GetLock() then
        self:StartMoving()
    end
end
function EchoRaidTools_NoteFrameMixin:OnMouseUp()
    if not _Notes.GetLock() then
        self:StopMovingOrSizing()
        local screenH = GetScreenHeight()
        local bottomToTop = self:GetTop()
        local distanceFromTop = screenH - bottomToTop
        _Notes.SetXY(self:GetLeft(), -distanceFromTop)
    end
end
function EchoRaidTools_NoteFrameMixin:SetUpDisplayBorder()
    local edgeFile = LibSharedMedia:Fetch("border", _Notes.GetBorder())
    local borderSize = _Notes.GetBorderSize()
    local r,g,b,a = _Notes.GetBorderRGBA()

    --self.Border:ClearAllPoints()
    --self.Border:SetPoint("TOPLEFT", -borderSize, borderSize)
    --self.Border:SetPoint("BOTTOMRIGHT", borderSize, -borderSize)
    
    local backDrop = {edgeFile = edgeFile, edgeSize = borderSize, bgFile = nil}
    self.Border:SetBackdrop(backDrop)
    self.Border:SetBackdropBorderColor(r,g,b,a)
    self.Border:SetBackdropColor(0,0,0,0)

    local show =  _Notes.GetUseBorder()
    if show then
        self.Border:Show()
    else
        self.Border:Hide()
    end

end

EchoRaidTools_ResizeButtonMixin = {}
function EchoRaidTools_ResizeButtonMixin:OnEnter()
    if not _Notes.GetLock() then
        self:SetAlpha(1)
        if SetCursor then
            SetCursor("UI_RESIZE_CURSOR");
        end
    end
end
function EchoRaidTools_ResizeButtonMixin:OnLeave()
    self:SetAlpha(0)
    if SetCursor then
		SetCursor(nil);
	end
end
function EchoRaidTools_ResizeButtonMixin:OnMouseDown()
    if not _Notes.GetLock() then
        local target = self.target;
        if not target then
            return;
        end
        self.target:StartSizing("BOTTOMRIGHT", true)
    end
end
function EchoRaidTools_ResizeButtonMixin:OnMouseUp()
    if not _Notes.GetLock() then
        local target = self.target;
        if not target then
            return;
        end
        target:StopMovingOrSizing()
        _Notes.SetSize(target:GetSize())
    end
end


EchoRaidTools_NotesNodeFrameMixin = {}
function EchoRaidTools_NotesNodeFrameMixin:NotesNodeFrameAdditionalLoad()
    self.AddButton:SetFrameLevel(self.Button:GetFrameLevel()+1)
end
function EchoRaidTools_NotesNodeFrameMixin:AdditionalSetup(info)
    self.AddButton:SetScript("OnClick", info.addButtonClick)
    self.AddButton.tooltip = info.addButtonTooltip
    --[[if self.expanded then
        self.AddButton:Show()
    else
        self.AddButton:Hide()
    end]]
    --[[hooksecurefunc(self, "Toggle", function()
        if self.expanded then
            self.AddButton:Show()
        else
            self.AddButton:Hide()
        end
    end)]]
end


EchoRaidTools_NotesButtonFrameMixin = {}
function EchoRaidTools_NotesButtonFrameMixin:NotesButtonFrameAdditionalLoad()
    self.selected = false
    self.loaded = true
    self.groupDisabled = false

    self.SelectedTexture:Hide()

    self.EditBox.parent = self
    self.RenameButton.parent = self
    self.CopyButton.parent = self
    self.DeleteButton.parent = self
    self.CheckButton.parent = self

    local fLevel = self:GetFrameLevel()
    self.EditBox:SetFrameLevel(fLevel+1)
    self.EditBox:SetAllPoints(self.ButtonText)
    self.RenameButton:SetFrameLevel(fLevel+1)
    self.CopyButton:SetFrameLevel(fLevel+1)
    self.DeleteButton:SetFrameLevel(fLevel+1)
    self.CheckButton:SetFrameLevel(fLevel+1)

    self.ButtonText:SetPoint("RIGHT", -40, 0)
end
function EchoRaidTools_NotesButtonFrameMixin:AdditionalSetup(info)
    self:SetScript("OnClick", function()
        PlaySound(62538)
        info.clickFunc()
    end)
    if info.UseCheckButton then
        self.CheckButton:Show()
        self.CheckButton:SetChecked(info.CheckButtonGetter())
        self.CheckButton:SetScript("OnClick", function()
            PlaySound(62538)
            info.CheckButtonSetter()
            self.CheckButton:SetChecked(info.CheckButtonGetter())
        end)
        self.CheckButton.tooltip = info.CheckButtonTooltip
        self.ButtonText:SetPoint("LEFT", self.CheckButton, "RIGHT", 1, 0)
    else
        self.CheckButton:Hide()
        self.CheckButton:SetScript("OnClick", nil)
        self.ButtonText:SetPoint("LEFT", 0, 0)
    end
    self.DeleteButton:SetScript("OnClick", function()
        PlaySound(62538)
        info.DeleteFunc()
    end)
    self.CopyButton:SetScript("OnClick", function()
        PlaySound(62538)
        info.CopyFunc()
    end)
    if info.GetReceived and info.GetReceived() then
        self.ReceivedTexture:Show()
    else
        self.ReceivedTexture:Hide()
    end
    if info.GetSelected and info.GetSelected() then
        self.SelectedTexture:Show()
    else
        self.SelectedTexture:Hide()
    end
    self.GetName = function() return info.NameGetter() end
    self.SetName = function(text) return info.NameSetter(text) end
    self.tooltip = info.GetTooltip and info.GetTooltip()

    self.UpDownFrame.UpButton:Enable()
    self.UpDownFrame.DownButton:Enable()
    if info.index == 1 then
        self.UpDownFrame.UpButton:Disable()
    elseif info.index == _Notes.GetTotalNumNotes() then
        self.UpDownFrame.DownButton:Disable()
    end
    self.UpDownFrame.UpButton:SetScript("OnClick", function()
        _Notes.MoveNoteIndex(info.index, -1)
        _Notes.UpdateNavigation()
    end)
    self.UpDownFrame.DownButton:SetScript("OnClick", function()
        _Notes.MoveNoteIndex(info.index, 1)
        _Notes.UpdateNavigation()
    end)
end

EchoRaidTools_NotesTemplate_RenameButtonMixin = {}
function EchoRaidTools_NotesTemplate_RenameButtonMixin:OnClick()
    self.parent.ButtonText:Hide()
    self.parent.EditBox:Show()
    self.parent.EditBox:SetText(self.parent.GetName())
    self.parent.EditBox:SetFocus()
end

EchoRaidTools_NotesTemplate_EditBoxMixin = {}
function EchoRaidTools_NotesTemplate_EditBoxMixin:OnEscapePressed()
    self:ClearFocus()
    self:Hide()
    self.parent.ButtonText:Show()
end
function EchoRaidTools_NotesTemplate_EditBoxMixin:OnEnterPressed()
    self.parent.SetName(self:GetText())

    self.parent.EditBox:ClearFocus()
    self.parent.EditBox:Hide()
    self.parent.ButtonText:SetText(self.parent.GetName())
    self.parent.ButtonText:Show()
end
function EchoRaidTools_NotesTemplate_EditBoxMixin:OnEditFocusLost()
    self:ClearFocus()
    self:Hide()
    self.parent.ButtonText:Show()
end

local EditBox

local function isValidTag(potentialTag)
    --check if the string is one of our tags
    return true
end

local function fixLinkSpacing(editbox)
    local text = editbox:GetText()
    local newText, changes = text:gsub("|h|H", "|h |H")
    if changes > 0 then
        editbox:SetText(newText)
    end
end
local function fixEscapes(editbox)
    local text = editbox:GetText()
    local newText, changes = text:gsub("||", "|")
    if changes > 0 then
        editbox:SetText(newText)
    end
end
local function handleNoteChanges(self, userInput)
    if not _Notes.PauseNoteChangeHandling then
        fixLinkSpacing(self)
        fixEscapes(self)
        local newText = self:GetText()
        _Notes.UpdateNote(newText, userInput)
    end
end

local function isPositionInsideTag(pos)
    local noteString = _Notes.GetNote()
    local init = 1
    while init and init < #noteString do
        local s, e = string.find(noteString, "|H.-|h.-|h", init)
        if s and e and s < pos and e > pos then
            return s,e
        end
        init = e and e + 1 or false
    end
end
local function isCursorInsideTag()
    local cursorPos = EditBox:GetCursorPosition()
    return isPositionInsideTag(cursorPos)
end
_Notes.isCursorInsideTag = isCursorInsideTag
local function handleCursorChange(self)
    if not _Notes.PauseCursorHandling then
        local s,e = isCursorInsideTag()
        if s and e then
            EditBox:HighlightText(s,e)
            _Notes.GetTagSettings(s,e)
        else
            _Notes.HideTagSettings()
        end
    end
end

local function handleCopyEnd(editbox, cursorPos, highlightStart, highlightEnd)
    editbox:SetText(editbox:GetText():gsub("||", "|"))
    editbox:SetCursorPosition(cursorPos)
    editbox:HighlightText(highlightStart, highlightEnd)
end
local function handleCopy(editbox, key)
    if key == "C" and IsControlKeyDown() then
        _Notes.PauseCursorHandling = true
        local highlightStart, highlightEnd = editbox:GetTextHighlight()
        local tagS = isPositionInsideTag(highlightStart)
        if tagS and tagS < highlightStart then
            highlightStart = tagS-1
        end
        local _,tagE = isPositionInsideTag(highlightEnd)
        if tagE and tagE > highlightEnd then
            highlightEnd = tagE
        end

        local cursorPos = editbox:GetCursorPosition()
        local note = editbox:GetText()

        local _, preHighlight = note:sub(1,highlightStart):gsub("|", "%1")
        local _, midHighlight = note:sub(1,highlightEnd):gsub("|", "%1")

        editbox:SetText(editbox:GetText():gsub("|", "||"))
        editbox:HighlightText(highlightStart+preHighlight, highlightEnd + midHighlight)

        RunNextFrame(function()
            handleCopyEnd(editbox, cursorPos, highlightStart, highlightEnd)
            _Notes.PauseCursorHandling = false
        end)

    elseif key == "D" and IsControlKeyDown() then
        editbox:Insert("")
    end
end

EchoRaidToolsConfig_NotesEditBoxMixin = {}
function EchoRaidToolsConfig_NotesEditBoxMixin:PostLoad()
    if not EditBox then
        EditBox = self.ScrollingEditBox.ScrollBox.EditBox
    end
    EditBox:SetText(_Notes.GetNote())
    EditBox:SetScript("OnTextChanged", handleNoteChanges)
    EditBox:SetScript("OnCursorChanged", handleCursorChange)

    EditBox:SetScript("OnKeyDown", handleCopy)
end

function _Notes.GetTextHighlight(avoidHandlingCursorChanges)
    if avoidHandlingCursorChanges then
        _Notes.PauseCursorHandling = true
        RunNextFrame(function()
            _Notes.PauseCursorHandling = false
        end)
    end
    local highlightStart, highlightEnd = _Notes.MainEditBox:GetTextHighlight()
    if highlightEnd and highlightEnd ~= highlightStart then
        local highlightText = _Notes.GetTextByIndices(highlightStart, highlightEnd)
        return highlightText
    end
end