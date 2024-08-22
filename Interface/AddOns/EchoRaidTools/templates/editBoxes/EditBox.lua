local _AddonName, _EchoRaidTools = ...

EchoRaidToolsConfig_EditboxTemplateMixin = {}
function EchoRaidToolsConfig_EditboxTemplateMixin:OnEnter()
    if self.tooltip then
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetFrameLevel(self:GetFrameLevel() + 2)
        GameTooltip:SetText(self.tooltip)
    end
end
function EchoRaidToolsConfig_EditboxTemplateMixin:OnLeave()
    if self.tooltip then
        GameTooltip:Hide()
    end
end
function EchoRaidToolsConfig_EditboxTemplateMixin:OnLoad()
    self.Disabled = false
end

EchoRaidToolsConfig_EditBoxMixin = {}
function EchoRaidToolsConfig_EditBoxMixin:OnLoad()
    self.Enabled = true
end
function EchoRaidToolsConfig_EditBoxMixin:OnEnter()
    if self.Enabled and self.tooltip then
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetFrameLevel(self:GetFrameLevel() + 2)
        GameTooltip:SetText(self.tooltip)
    end
end
function EchoRaidToolsConfig_EditBoxMixin:OnLeave()
    if self.tooltip then
        GameTooltip:Hide()
    end
end
function EchoRaidToolsConfig_EditBoxMixin:Enable()
    self.TopText:SetTextColor(1, 0.82, 0, 0.7)
    self:SetAlpha(1)
    --self.Button:Enable()
    self.Enabled = true
end
function EchoRaidToolsConfig_EditBoxMixin:Disable()
    self.TopText:SetTextColor(1, 0.82, 0, 0.3)
    self:SetAlpha(0.5)
    --self.Button:Disable()
    self.Enabled = false
end
function EchoRaidToolsConfig_EditBoxMixin:IsEnabled()
    return self.Enabled
end
function EchoRaidToolsConfig_EditBoxMixin:SetText(text)
    self.Editbox:SetText(text)
end

EchoRaidToolsConfig_ExportBoxMixin = {}
function EchoRaidToolsConfig_ExportBoxMixin:OnLoad()
end
function EchoRaidToolsConfig_ExportBoxMixin:OnHide()
    self:SetText("")
end
function EchoRaidToolsConfig_ExportBoxMixin:OnEscapePressed()
    self:ClearFocus()
end
function EchoRaidToolsConfig_ExportBoxMixin:OnTextChanged()
    if self.string then
        self:SetText(self.string)
        self:Select()
    end
end
function EchoRaidToolsConfig_ExportBoxMixin:OnTextSet()
    self.string = self:GetText()
end
function EchoRaidToolsConfig_ExportBoxMixin:OnEditFocusGained()
    --self:HighlightText()
end
function EchoRaidToolsConfig_ExportBoxMixin:OnEditFocusLost()
    self:ClearHighlightText()
end
function EchoRaidToolsConfig_ExportBoxMixin:OnMouseUp()
    self:Select()
end
function EchoRaidToolsConfig_ExportBoxMixin:Select()
    self:SetFocus()
    self:SetCursorPosition(0)
    self:HighlightText(0, -1)
end

EchoRaidToolsConfig_ImportBoxMixin = {}
function EchoRaidToolsConfig_ImportBoxMixin:OnLoad()
    self.Button:SetScript("OnClick", function()
        if self.onClick then
            local text = self.Editbox:GetText()
            self.onClick(text)
            self.Editbox:SetText("")
        end
    end)
    self.ClearTextButton:SetScript("OnClick", function() self.Editbox:SetText("") end)
end
EchoRaidToolsConfig_ExportBoxEditboxTemplateMixin = {}
function EchoRaidToolsConfig_ExportBoxEditboxTemplateMixin:OnEscapePressed()
end
function EchoRaidToolsConfig_ExportBoxEditboxTemplateMixin:OnTextChanged()
    self:SetCursorPosition(0)
end
function EchoRaidToolsConfig_ExportBoxEditboxTemplateMixin:OnEditFocusGained()
end
function EchoRaidToolsConfig_ExportBoxEditboxTemplateMixin:OnEditFocusLost()
end
function EchoRaidToolsConfig_ExportBoxEditboxTemplateMixin:OnMouseUp()
end

EchoRaidToolsConfig_MultilineEditboxTemplateMixin = {}
function EchoRaidToolsConfig_MultilineEditboxTemplateMixin:OnLoad()
end
function EchoRaidToolsConfig_MultilineEditboxTemplateMixin:OnEscapePressed()
    self:ClearFocus()
end
function EchoRaidToolsConfig_MultilineEditboxTemplateMixin:OnTextChanged()
end
function EchoRaidToolsConfig_MultilineEditboxTemplateMixin:OnEditFocusGained()
end
function EchoRaidToolsConfig_MultilineEditboxTemplateMixin:OnEditFocusLost()
end
function EchoRaidToolsConfig_MultilineEditboxTemplateMixin:OnMouseUp()
end

EchoRaidToolsConfig_ScrollingEditBoxTemplateMixin = {}
function EchoRaidToolsConfig_ScrollingEditBoxTemplateMixin:OnLoad()
    local scrollBox = self.ScrollingEditBox:GetScrollBox();
	ScrollUtil.RegisterScrollBoxWithScrollBar(scrollBox, self.ScrollBar);
    local editBox = self.ScrollingEditBox:GetEditBox()
    editBox:SetTextInsets(7,7,7,7)
    local textColor = CreateColor(0.85, 0.85, 0.85, 1)
    self.ScrollingEditBox:SetTextColor(textColor)

    function editBox:GetTextHighlight()
        local Text, Cursor = self:GetText(), self:GetCursorPosition()

        self:Insert("") -- Delete selected text
        local TextNew, CursorNew = self:GetText(), self:GetCursorPosition()
        -- Restore previous text
        self:SetText(Text)
        self:SetCursorPosition(Cursor)
        local Start, End = CursorNew, #Text - (#TextNew - CursorNew)
        self:HighlightText(Start, End)
        return Start, End
    end
    local ClearHighlightText = editBox.ClearHighlightText
    function oClearHighlightText(self, reallyDoIT)
        if reallyDoIT then
            ClearHighlightText(self)
        end
    end
    editBox.ClearHighlightText = oClearHighlightText

    hooksecurefunc(editBox, "Disable", function() editBox:SetAlpha(0.5) end)
    hooksecurefunc(editBox, "Enable", function() editBox:SetAlpha(1) end)

    --[[editBox:HookScript("OnKeyDown", function(self, key)
        if key == "c" and IsControlKeyDown() then
            
        end
    end)]]
end
