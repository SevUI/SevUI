local _AddonName, _EchoRaidTools = ...
local _Notes = _EchoRaidTools:GetModule("Notes")

function _Notes:LoadConfig()

    function _Notes:GetConfig()
        if _EchoRaidTools.panels.NotesModule then
            return _EchoRaidTools.panels.NotesModule
        end

        --main panel creation
        local window = CreateFrame("FRAME", nil, _EchoRaidTools.panels.main, "EchoRaidToolsMainConfigWindow")
        window:SetScript("OnShow", function() _Notes.OnShow() end)
        window:SetScript("OnHide", function() _Notes.OnHide() end)
        window.Header.EnableModule:SetChecked(_Notes.GetModuleEnabled())
        window.Header.EnableModule:SetScript("OnClick", function(self)
            _Notes.ToggleModuleEnabled()
            self:SetChecked(_Notes.GetModuleEnabled())
        end)
        window.Header.HeaderText:SetText("Notes")

        local panel = CreateFrame("FRAME", nil, window, "EchoRaidToolsMainConfigPanel_NoScroll")
        panel:SetPoint("TOPLEFT", window.Header, "BOTTOMLEFT")
        panel:SetPoint("BOTTOMRIGHT")
        local mainContainer = panel
        _Notes.controlParent = mainContainer
        _Notes.mainWindow = window
        _Notes.mainPanel = panel
        _Notes.mainWindow.currentPanel = panel

        _EchoRaidTools.panels.NotesModule = window

        local tabControl = CreateFrame("Frame", nil, panel, "EchoRaidTools_TabMainPanel")
        tabControl:ClearAllPoints()
        tabControl:SetPoint("TOPLEFT", 5, -2)
        tabControl:SetPoint("TOPRIGHT", -5, -2)
        tabControl:SetHeight(510)
        local tabs = {"Notes", "Settings"}
        local panels = tabControl:SetTabs(tabs)
        local NotesPanel = panels[1]
        local SettingsPanel = panels[2]
        _Notes.TabControl = tabControl

        local tagSettingsControls = {}
        tagSettingsControls.noTag = {}
        tagSettingsControls.noTag.controls = {}
        local currentSettings

        function BuildNotesPanelContents()
            local mainEditBoxFrame = CreateFrame("Frame", nil, NotesPanel, "EchoRaidToolsConfig_NotesEditBox")
            mainEditBoxFrame:SetPoint("TOPLEFT", 2, -50)
            mainEditBoxFrame:SetPoint("BOTTOMRIGHT", -200, 32)
            local mainEditBox = mainEditBoxFrame.ScrollingEditBox.ScrollBox.EditBox
            mainEditBox:SetText(_Notes.GetNote())
            _Notes.MainEditBox = mainEditBox
            --vdt(mainEditBox)

            local SendButton = CreateFrame("FRAME", nil, NotesPanel, "EchoRaidToolsConfig_Button")
            SendButton:SetPoint("TOPLEFT", mainEditBoxFrame, "BOTTOMLEFT", 5, -2)
            SendButton:SetSize(100, 25)
            SendButton.Button:SetText("PUSH")
            SendButton.Button:SetScript("OnClick", _Notes.SendNote)

            local UndoButton = CreateFrame("BUTTON", nil, NotesPanel, "EchoRaidTools_BackButton")
            UndoButton.tooltip = "Undo"
            UndoButton:SetPoint("LEFT", SendButton, "RIGHT", 10, 0)
            UndoButton:SetScript("OnClick", function() _Notes.MoveThroughHistory(-1) end)
            _Notes.UndoButton = UndoButton
            local RedoButton = CreateFrame("BUTTON", nil, NotesPanel, "EchoRaidTools_ForwardButton")
            RedoButton.tooltip = "Redo"
            RedoButton:SetPoint("LEFT", SendButton, "RIGHT", 32, 0)
            RedoButton:SetScript("OnClick", function() _Notes.MoveThroughHistory(1) end)
            _Notes.RedoButton = RedoButton
            _Notes.SetUndoStatus()

            --[[local tagBox = CreateFrame("FRAME", nil, NotesPanel, "EchoRaidToolsConfig_EditBox")
            tagBox:SetPoint("LEFT", RedoButton, "RIGHT", 5, 0)
            tagBox:SetPoint("TOPRIGHT", mainEditBoxFrame, "BOTTOMRIGHT", -2)
            _Notes.TagBox = tagBox]]

            local x = 330
            for i, info in pairs(_Notes.IconReference) do
                local iconButton = CreateFrame("BUTTON", nil, NotesPanel, "EchoRaidTools_NotesIconButton")
                if info.type == "texture" then
                    iconButton:SetNormalTexture(info.path)
                elseif info.type == "atlas" then
                    iconButton:SetNormalAtlas(info.path)
                end
                iconButton:SetPoint("TOPLEFT", x, -25)
                iconButton.tooltip = info.text
                x = x + 18
                iconButton:SetScript("OnClick", function()
                    _Notes.InsertNewTag("icon", info.ref)
                end)
            end

            local unitPicker = CreateFrame("FRAME", nil, NotesPanel, "EchoRaidToolsConfig_Dropdown")
            unitPicker.tooltip = "Insert a player from the current group"
            unitPicker.TopText:SetText("Add Raider")
            unitPicker.TopText:Show()
            unitPicker:SetWidth(150)
            unitPicker:SetPoint("TOPLEFT", 10, -15)
            function _Notes.UpdateUnitPickerDropdown()
                local items = {}
                for unit in _EchoRaidTools.IterateGroup() do
                    local name = UnitName(unit)
                    local class = select(2, UnitClass(unit))
                    local label = GetClassColoredTextForUnit(unit, name)
                    local item = {
                        label = label,
                        value = name,
                        onclick = function()
                            _Notes.InsertNewTag("player", name, class)
                            unitPicker:UpdateSelection("")
                        end,
                        desc = "Insert "..label,
                    }
                    table.insert(items, item)
                end
                unitPicker:SetupSelections(items, 0)
            end
            _Notes.UpdateUnitPickerDropdown()

            local guildPicker = CreateFrame("FRAME", nil, NotesPanel, "EchoRaidToolsConfig_Dropdown")
            guildPicker.tooltip = "Insert a player from the guild"
            guildPicker.TopText:SetText("Add Guild Member")
            guildPicker.TopText:Show()
            guildPicker:SetWidth(150)
            guildPicker:SetPoint("TOPLEFT", 170, -15)
            function _Notes.UpdateGuildPickerDropdown()
                local items = {}
                for i = 1, GetNumGuildMembers() do
                    local name, _, _, level, _, _, _, _, isOnline, _, class = GetGuildRosterInfo(i)
                    name = Ambiguate(name, "guild")
                    if isOnline then
                        local label = GetClassColorObj(class):WrapTextInColorCode(name)
                        local item = {
                            label = label,
                            value = name,
                            onclick = function()
                                _Notes.InsertNewTag("player", name, class)
                                guildPicker:UpdateSelection("")
                            end,
                            desc = "Insert "..label,
                        }
                        table.insert(items, item)
                    end
                end
                guildPicker:SetupSelections(items, 0)
            end
            _Notes.UpdateGuildPickerDropdown()

            do -- New Tag Dropdown
                local InsertPreviousTagButton = CreateFrame("BUTTON", nil, NotesPanel, "EchoRaidTools_ButtonTemplate")
                InsertPreviousTagButton:SetText("Insert Previous Tag")
                InsertPreviousTagButton:SetWidth(150)
                InsertPreviousTagButton:SetPoint("TOPLEFT", mainEditBoxFrame, "TOPRIGHT", 5, -5)
                InsertPreviousTagButton:Disable()
                --table.insert(tagSettingsControls.noTag.controls, InsertPreviousTagButton)
                _Notes.InsertPreviousTagButton = InsertPreviousTagButton
                InsertPreviousTagButton:Hide()
                function InsertPreviousTagButton:Reset()
                    InsertPreviousTagButton:SetScript("OnClick", nil)
                    InsertPreviousTagButton:Disable()
                    InsertPreviousTagButton.tooltip = ""
                end

                local tagPicker = CreateFrame("FRAME", nil, NotesPanel, "EchoRaidToolsConfig_Dropdown")
                tagPicker.tooltip = "Add a tag to the Note"
                tagPicker.TopText:SetText("Add Tag")
                tagPicker.TopText:Show()
                tagPicker:SetWidth(150)
                local items = {}
                for type, info in pairs(_Notes.tagTypes) do
                    local item = {
                        label = info.text,
                        value = type,
                        onclick = function()
                            _Notes.InsertNewBlankTag(type)
                        end,
                        desc = "Insert "..info.text.." type",
                    }
                    table.insert(items, item)
                end
                tagPicker:SetupSelections(items, 0)
                tagPicker:SetPoint("TOPLEFT", mainEditBoxFrame, "TOPRIGHT", 5, -45)
                table.insert(tagSettingsControls.noTag.controls, tagPicker)
                tagPicker:Hide()
                function tagPicker:Reset()
                    self:UpdateSelection()
                end
            end
            do -- Player Tag settings
                tagSettingsControls.player = {}
                tagSettingsControls.player.controls = {}

                local PlayerNameEditBox = CreateFrame("FRAME", nil, NotesPanel, "EchoRaidToolsConfig_EditBox")
                PlayerNameEditBox.tooltip = "Enter Player Name"
                PlayerNameEditBox.TopText:SetText("Name")
                PlayerNameEditBox.TopText:Show()
                PlayerNameEditBox:SetWidth(150)
                PlayerNameEditBox:SetPoint("TOPLEFT", mainEditBoxFrame, "TOPRIGHT", 5, -5)
                table.insert(tagSettingsControls.player.controls, PlayerNameEditBox)
                PlayerNameEditBox:Hide()
                function PlayerNameEditBox:Reset()
                    self.Editbox:SetText("")
                    self.Editbox:SetScript("OnEnterPressed", nil)
                end

                local PlayerNameClassPicker = CreateFrame("FRAME", nil, NotesPanel, "EchoRaidToolsConfig_Dropdown")
                PlayerNameClassPicker.tooltip = "Select Class"
                PlayerNameClassPicker.TopText:SetText("Class")
                PlayerNameClassPicker.TopText:Show()
                PlayerNameClassPicker:SetWidth(150)
                local items = {}
                for i = 1, 13 do
                    local className, classFile = GetClassInfo(i)
                    local color = GetClassColorObj(classFile)
                    local item = {
                        label = color:WrapTextInColorCode(className),
                        value = classFile,
                        onclick = function()
                            PlayerNameClassPicker.selectedClass = classFile
                        end,
                        desc = "set Class to "..className,
                    }
                    table.insert(items, item)
                end
                PlayerNameClassPicker:SetupSelections(items, 0)
                PlayerNameClassPicker:SetPoint("TOPLEFT", mainEditBoxFrame, "TOPRIGHT", 5, -45)
                table.insert(tagSettingsControls.player.controls, PlayerNameClassPicker)
                PlayerNameClassPicker:Hide()
                function PlayerNameClassPicker:Reset()
                    self:UpdateSelection()
                end

                local PlayerNameAcceptButton = CreateFrame("BUTTON", nil, NotesPanel, "EchoRaidTools_ButtonTemplate")
                PlayerNameAcceptButton:SetText("Accept")
                PlayerNameAcceptButton:SetWidth(150)
                PlayerNameAcceptButton:SetPoint("TOPLEFT", mainEditBoxFrame, "TOPRIGHT", 5, -85)
                table.insert(tagSettingsControls.player.controls, PlayerNameAcceptButton)
                PlayerNameAcceptButton:Hide()
                function PlayerNameAcceptButton:Reset()
                    self:SetScript("OnClick", nil)
                end

                tagSettingsControls.player.Setup = function(setterFunc, name, class)
                    PlayerNameEditBox.Editbox:SetText(name or "")
                    PlayerNameClassPicker.selectedClass = class
                    PlayerNameClassPicker:UpdateSelection(class)
                    PlayerNameAcceptButton:SetScript("OnClick",
                        function() setterFunc(PlayerNameEditBox.Editbox:GetText(), PlayerNameClassPicker.selectedClass) end
                    )
                    PlayerNameEditBox.Editbox:SetScript("OnEnterPressed",
                        function() setterFunc(PlayerNameEditBox.Editbox:GetText(), PlayerNameClassPicker.selectedClass) end
                    )
                end
            end
            do --Color tag settings
                tagSettingsControls.color = {}
                tagSettingsControls.color.controls = {}

                local ColorTextEditBox = CreateFrame("FRAME", nil, NotesPanel, "EchoRaidToolsConfig_EditBox")
                ColorTextEditBox.tooltip = "Enter Player Name"
                ColorTextEditBox.TopText:SetText("Name")
                ColorTextEditBox.TopText:Show()
                ColorTextEditBox:SetWidth(150)
                ColorTextEditBox:SetPoint("TOPLEFT", mainEditBoxFrame, "TOPRIGHT", 5, -5)
                table.insert(tagSettingsControls.color.controls, ColorTextEditBox)
                ColorTextEditBox:Hide()
                function ColorTextEditBox:Reset()
                    self.Editbox:SetText("")
                    self.Editbox:SetScript("OnEnterPressed", nil)
                end

                local ColorTextColorPicker = CreateFrame("BUTTON", nil, NotesPanel, "EchoRaidToolsConfig_NewColorPicker")
                ColorTextColorPicker:SetPoint("TOPLEFT", mainEditBoxFrame, "TOPRIGHT", 5, -45)
                local useOpacity = false
                local opacityFunc = nil
                local r,g,b,a = 1,1,1,1
                local func = function() end
                local cancelFunc = nil
                ColorTextColorPicker:SetupInteraction(func, r,g,b,a, opacityFunc, cancelFunc, useOpacity)
                table.insert(tagSettingsControls.color.controls, ColorTextColorPicker)
                ColorTextColorPicker:Hide()

                local ColorTextAcceptButton = CreateFrame("BUTTON", nil, NotesPanel, "EchoRaidTools_ButtonTemplate")
                ColorTextAcceptButton:SetText("Accept")
                ColorTextAcceptButton:SetWidth(150)
                ColorTextAcceptButton:SetPoint("TOPLEFT", mainEditBoxFrame, "TOPRIGHT", 5, -85)
                table.insert(tagSettingsControls.color.controls, ColorTextAcceptButton)
                ColorTextAcceptButton:Hide()
                function ColorTextAcceptButton:Reset()
                    self:SetScript("OnClick", nil)
                end

                tagSettingsControls.color.Setup = function(setterFunc, name, r,g,b)
                    ColorTextEditBox.Editbox:SetText(name or "")
                    if not r then
                        r,g,b = 1,1,1
                    end
                    ColorTextColorPicker:SetRGBA(r,g,b,1)
                    ColorTextAcceptButton:SetScript("OnClick", function()
                        setterFunc(ColorTextEditBox.Editbox:GetText(), ColorPickerFrame:GetColorRGB())
                    end)
                    ColorTextEditBox.Editbox:SetScript("OnEnterPressed", function()
                        setterFunc(ColorTextEditBox.Editbox:GetText(), ColorPickerFrame:GetColorRGB())
                    end)
                end
            end
            do --timer settings
                tagSettingsControls.timer = {}
                tagSettingsControls.timer.controls = {}

                local TimerTextEditBox = CreateFrame("FRAME", nil, NotesPanel, "EchoRaidToolsConfig_EditBox")
                TimerTextEditBox.tooltip = "Enter a timer, in number of seconds"
                TimerTextEditBox.TopText:SetText("Time")
                TimerTextEditBox.TopText:Show()
                TimerTextEditBox:SetWidth(150)
                TimerTextEditBox:SetPoint("TOPLEFT", mainEditBoxFrame, "TOPRIGHT", 5, -5)
                table.insert(tagSettingsControls.timer.controls, TimerTextEditBox)
                TimerTextEditBox:Hide()
                function TimerTextEditBox:Reset()
                    self.Editbox:SetText("")
                    self.Editbox:SetScript("OnEnterPressed", nil)
                end

                local TimerTextAcceptButton = CreateFrame("BUTTON", nil, NotesPanel, "EchoRaidTools_ButtonTemplate")
                TimerTextAcceptButton:SetText("Accept")
                TimerTextAcceptButton:SetWidth(150)
                TimerTextAcceptButton:SetPoint("TOPLEFT", mainEditBoxFrame, "TOPRIGHT", 5, -45)
                table.insert(tagSettingsControls.timer.controls, TimerTextAcceptButton)
                TimerTextAcceptButton:Hide()
                function TimerTextAcceptButton:Reset()
                    self:SetScript("OnClick", nil)
                end

                tagSettingsControls.timer.Setup = function(setterFunc, timeSecs)
                    TimerTextEditBox.Editbox:SetText(timeSecs or "")
                    TimerTextAcceptButton:SetScript("OnClick", function() setterFunc(TimerTextEditBox.Editbox:GetText()) end )
                    TimerTextEditBox.Editbox:SetScript("OnEnterPressed", function() setterFunc(TimerTextEditBox.Editbox:GetText()) end )
                end
            end
            do --spell settings
                tagSettingsControls.spell = {}
                tagSettingsControls.spell.controls = {}

                local SpellTextEditBox = CreateFrame("FRAME", nil, NotesPanel, "EchoRaidToolsConfig_EditBox")
                SpellTextEditBox.tooltip = "Enter a spellID"
                SpellTextEditBox.TopText:SetText("Spell")
                SpellTextEditBox.TopText:Show()
                SpellTextEditBox:SetWidth(150)
                SpellTextEditBox:SetPoint("TOPLEFT", mainEditBoxFrame, "TOPRIGHT", 5, -5)
                table.insert(tagSettingsControls.spell.controls, SpellTextEditBox)
                SpellTextEditBox:Hide()
                function SpellTextEditBox:Reset()
                    self.Editbox:SetText("")
                    self.Editbox:SetScript("OnEnterPressed", nil)
                end

                local SpellTextAcceptButton = CreateFrame("BUTTON", nil, NotesPanel, "EchoRaidTools_ButtonTemplate")
                SpellTextAcceptButton:SetText("Accept")
                SpellTextAcceptButton:SetWidth(150)
                SpellTextAcceptButton:SetPoint("TOPLEFT", mainEditBoxFrame, "TOPRIGHT", 5, -45)
                table.insert(tagSettingsControls.spell.controls, SpellTextAcceptButton)
                SpellTextAcceptButton:Hide()
                function SpellTextAcceptButton:Reset()
                    self:SetScript("OnClick", nil)
                end

                tagSettingsControls.spell.Setup = function(setterFunc, timeSecs)
                    SpellTextEditBox.Editbox:SetText(timeSecs or "")
                    SpellTextAcceptButton:SetScript("OnClick", function() setterFunc(SpellTextEditBox.Editbox:GetText()) end )
                    SpellTextEditBox.Editbox:SetScript("OnEnterPressed", function() setterFunc(SpellTextEditBox.Editbox:GetText()) end)
                end
            end
            do --icon settings
                tagSettingsControls.icon = {}
                tagSettingsControls.icon.controls = {}

                local IconTextEditBox = CreateFrame("FRAME", nil, NotesPanel, "EchoRaidToolsConfig_EditBox")
                IconTextEditBox.tooltip = "Enter an IconID"
                IconTextEditBox.TopText:SetText("Icon")
                IconTextEditBox.TopText:Show()
                IconTextEditBox:SetWidth(150)
                IconTextEditBox:SetPoint("TOPLEFT", mainEditBoxFrame, "TOPRIGHT", 5, -5)
                table.insert(tagSettingsControls.icon.controls, IconTextEditBox)
                IconTextEditBox:Hide()
                function IconTextEditBox:Reset()
                    self.Editbox:SetText("")
                    self.Editbox:SetScript("OnEnterPressed", nil)
                end

                local IconTextAcceptButton = CreateFrame("BUTTON", nil, NotesPanel, "EchoRaidTools_ButtonTemplate")
                IconTextAcceptButton:SetText("Accept")
                IconTextAcceptButton:SetWidth(150)
                IconTextAcceptButton:SetPoint("TOPLEFT", mainEditBoxFrame, "TOPRIGHT", 5, -45)
                table.insert(tagSettingsControls.icon.controls, IconTextAcceptButton)
                IconTextAcceptButton:Hide()
                function IconTextAcceptButton:Reset()
                    self:SetScript("OnClick", nil)
                end

                tagSettingsControls.icon.Setup = function(setterFunc, timeSecs)
                    IconTextEditBox.Editbox:SetText(timeSecs or "")
                    IconTextAcceptButton:SetScript("OnClick", function() setterFunc(IconTextEditBox.Editbox:GetText()) end )
                    IconTextEditBox.Editbox:SetScript("OnEnterPressed", function() setterFunc(IconTextEditBox.Editbox:GetText()) end)
                end
            end

        end
        function _Notes.ShowTagSettings(type, fullTag, ...)
            --[[if fullTag then
                _Notes.TagBox:SetText(fullTag)
            end]]
            if currentSettings then
                for _, control in pairs(tagSettingsControls[currentSettings].controls) do
                    if control.Reset then
                        control:Reset()
                    end
                    control:Hide()
                end
            end
            if type == "player" then
                local name, class = ...
                if not name then
                    name = _Notes.GetTextHighlight(true) or ""
                end
                local setterFunc = function(name, class)
                    if (not name) or (not class) or (name == "") then return end
                    _Notes.InsertNewTag("player", name, class)
                    _Notes.HideTagSettings()
                end
                tagSettingsControls.player.Setup(setterFunc, name, class)

            elseif type == "color" then
                local name, hexColor = ...
                if not name then
                    name = _Notes.GetTextHighlight(true) or ""
                end
                local r,g,b
                if not hexColor then
                    r,g,b = 1,1,1
                else
                    local col = CreateColorFromHexString(hexColor)
                    r,g,b = col:GetRGB()
                end
                local setterFunc = function(name, r, g, b)
                    if (not name) or (not r) or (name == "") then return end
                    local col = CreateColor(r,g,b,1)
                    _Notes.InsertNewTag("color", name, col:GenerateHexColor())
                    _Notes.HideTagSettings()
                end
                tagSettingsControls.color.Setup(setterFunc, name, r,g,b)

            elseif type == "timer" then
                local timeSecs = ...
                local setterFunc = function(timeString)
                    local timeNum = tonumber(timeString)
                    if timeNum then
                        _Notes.InsertNewTag("timer", timeNum)
                        _Notes.HideTagSettings()
                    end
                end
                tagSettingsControls.timer.Setup(setterFunc, timeSecs)

            elseif type == "spell" then
                local spellID = ...
                local setterFunc = function(spellString)
                    local spellNum = tonumber(spellString)
                    if spellNum then
                        _Notes.InsertNewTag("spell", spellNum)
                        _Notes.HideTagSettings()
                    end
                end
                tagSettingsControls.spell.Setup(setterFunc, spellID)

            elseif type == "icon" then
                local iconID = ...
                local setterFunc = function(iconString)
                    _Notes.InsertNewTag("icon", iconString)
                    _Notes.HideTagSettings()
                end
                tagSettingsControls.icon.Setup(setterFunc, iconID)

            end

            for _, control in pairs(tagSettingsControls[type].controls) do
                control:Show()
            end
            currentSettings = type
        end
        function _Notes.HideTagSettings()
            --_Notes.TagBox:SetText("")
            if currentSettings ~= "noTag" then
                if currentSettings and tagSettingsControls[currentSettings] then
                    for _, control in pairs(tagSettingsControls[currentSettings].controls) do
                        if control.Reset then
                            control:Reset()
                        end
                        control:Hide()
                    end
                end
                for _, control in pairs(tagSettingsControls.noTag.controls) do
                    control:Show()
                end
                if _Notes.lastTagString then
                    _Notes.InsertPreviousTagButton:Enable()
                    _Notes.InsertPreviousTagButton:SetScript("OnClick", function() _Notes.InsertLastTag() end)
                    _Notes.InsertPreviousTagButton.tooltip = "Tag: ".._Notes.lastTagString
                end
                currentSettings = "noTag"
            end
        end
        BuildNotesPanelContents()
        _Notes.HideTagSettings()

        function BuildNotesSettingPanel()
            local behaviourHeader = CreateFrame("FRAME", nil, SettingsPanel, "EchoRaidToolsConfig_LineTitle")
            behaviourHeader.Text:SetText("Notes Behaviour")
            behaviourHeader:Show()
            behaviourHeader:SetSize(250, 30)
            behaviourHeader:SetPoint("TOPLEFT", 20, -10)

            local GroupLeaveDropdown = CreateFrame("FRAME", nil, SettingsPanel, "EchoRaidToolsConfig_Dropdown")
            GroupLeaveDropdown.tooltip = "Choose what happens to received notes when you leave the group"
            GroupLeaveDropdown.TopText:SetText("Group Leave/Logout")
            GroupLeaveDropdown.TopText:Show()
            GroupLeaveDropdown:SetWidth(250)
            local GroupLeaveDropdownItems = {
                {
                    label = "Delete Received Notes",
                    value = 1,
                    onclick = function()
                        _Notes.SetGroupLeaveBehaviour(1)
                    end,
                    desc = "Received Notes are deleted when you leave the group or log out"
                },
                {
                    label = "Claim Received Notes",
                    value = 2,
                    onclick = function()
                        _Notes.SetGroupLeaveBehaviour(2)
                    end,
                    desc = "Received Notes are saved when you leave the group or log out"
                }
            }
            GroupLeaveDropdown:SetupSelections(GroupLeaveDropdownItems, _Notes.GetGroupLeaveBehaviour())
            GroupLeaveDropdown:SetPoint("TOPLEFT", 40, -54)

            -- next line header
            
            local displayHeader = CreateFrame("FRAME", nil, SettingsPanel, "EchoRaidToolsConfig_LineTitle")
            displayHeader.Text:SetText("Notes Display settings")
            displayHeader:Show()
            displayHeader:SetSize(250, 30)
            displayHeader:SetPoint("TOPLEFT", 20, -100)

            --next line
            local lockEnable = CreateFrame("FRAME", nil, SettingsPanel, "EchoRaidToolsConfig_CheckButton")
            lockEnable.CheckButton.tooltip = "Lock Note frame"
            lockEnable.TopText:SetText("Lock Note")
            lockEnable.TopText:Show()
            lockEnable:SetWidth(100)
            lockEnable:SetHeight(28)
            lockEnable.CheckButton:SetScript("OnClick", _Notes.ToggleLock)
            lockEnable.CheckButton:SetChecked(_Notes.GetLock())
            lockEnable:Show()
            lockEnable:SetPoint("TOPLEFT", 40, -145)

            -- next line
            local backgroundColor = CreateFrame("BUTTON", nil, SettingsPanel, "EchoRaidToolsConfig_NewColorPicker")
            backgroundColor:SetPoint("TOPLEFT", 40, -185)
            backgroundColor.TopText:Show()
            backgroundColor.TopText:SetText("Background Color")
            local useOpacity = true
            local opacityFunc = nil
            local r,g,b,a = _Notes.GetBackgroundRGBA()
            local func = _Notes.SetBackgroundRGBA
            local cancelFunc = nil
            backgroundColor:SetupInteraction(func, r,g,b,a, opacityFunc, cancelFunc, useOpacity)

            --next line
            local borderEnable = CreateFrame("FRAME", nil, SettingsPanel, "EchoRaidToolsConfig_CheckButton")
            borderEnable.CheckButton.tooltip = "Show a border around the Note"
            borderEnable.TopText:SetText("Enable Border")
            borderEnable.TopText:Show()
            borderEnable:SetWidth(100)
            borderEnable:SetHeight(28)
            borderEnable.CheckButton:SetScript("OnClick", _Notes.ToggleUseBorder)
            borderEnable.CheckButton:SetChecked(_Notes.GetUseBorder())
            borderEnable:Show()
            borderEnable:SetPoint("TOPLEFT", 40, -225)

            local BorderPicker = CreateFrame("FRAME", nil, SettingsPanel, "EchoRaidToolsConfig_Dropdown")
            BorderPicker.tooltip = "Set the Note frame's border"
            BorderPicker.TopText:SetText("Border Texture")
            BorderPicker.TopText:Show()
            BorderPicker:SetWidth(200)
            BorderPicker:Show()
            local BuildDropDownBorderList = function()
                local borders = _Notes.BuildBorderArray()
                local mylist = tDClone(borders)
                for i, array in pairs(mylist) do
                    array.onclick = function(_, _, value) _Notes.SetBorder(value) end
                end
                return mylist
            end
            local items = BuildDropDownBorderList()
            local selected = _Notes.GetBorder()
            BorderPicker:SetupSelections(items, selected)
            BorderPicker:SetPoint("TOPLEFT", 140, -221)

            local borderColor = CreateFrame("BUTTON", nil, SettingsPanel, "EchoRaidToolsConfig_NewColorPicker")
            borderColor:SetPoint("TOPLEFT", 370, -225)
            borderColor.TopText:Show()
            borderColor.TopText:SetText("Border Color")
            local useOpacity = true
            local opacityFunc = nil
            local r,g,b,a = _Notes.GetBorderRGBA()
            local func = _Notes.SetBorderRGBA
            local cancelFunc = nil
            borderColor:SetupInteraction(func, r,g,b,a, opacityFunc, cancelFunc, useOpacity)
            
            local borderSize = CreateFrame("FRAME", nil, SettingsPanel, "EchoRaidTools_BetterSlider")
            borderSize:SetPoint("TOPLEFT", 470, -225)
            borderSize.Slider.tooltip = "Set the Border's Size"
            borderSize.ValueEditbox.tooltip = "Set the Border's Size"
            borderSize.TopText:SetText("Border Size")
            borderSize.TopText:Show()
            borderSize:Setup(1, 10, 1, _Notes.GetBorderSize, _Notes.SetBorderSize, 1, 100)

            --overall alpha

        end

        BuildNotesSettingPanel()

        tabControl:Show()
        panel.tabControl = tabControl

        return window
    end

    function _Notes.BuildNavigationItemTable()
        local items = {
            {
                type = "button",
                title = "Add Note",
                clickFunc = function()
                    _Notes.AddNewNote()
                end,
                icon = "Garr_Building-AddFollowerPlus",
                id = "AddNote",
                template = "EchoRaidTools_NotesNavigationAddButtonFrame",
                tooltip = "Add a new Note"
            }
        }
        --[[items[1] = {
            type = "node",
            title = "Notes",
            id = "notesNode",
            template = "EchoRaidTools_NotesNodeFrame",
            addButtonClick = function()
                _Notes.AddNewNote()
            end,
            addButtonTooltip = "Add new Note",
            children = {},
            defaultOpen = true,
        }]]

        for i, noteDetails in ipairs(_Notes.GetAllSavedNotes()) do
            local noteButton = {
                type = "button",
                title = noteDetails.name,
                id = i.."note",--noteDetails.name.."node",
                template = "EchoRaidTools_NotesButtonFrame",
                NameGetter = function() return _Notes.GetNoteName(i) end,
                NameSetter = function(text) _Notes.RenameNote(text, i) end,
                DeleteFunc = function()
                    _Notes.DeleteNote(i)
                    _Notes.UpdateNavigation()
                end,
                CopyFunc = function()
                    _Notes.CopyNote(i)
                end,
                GetSelected = function()
                    return _Notes.GetCurrentNoteIndex() == i
                end,
                GetReceived = function()
                    return _Notes.NoteIsReceivedNote(i)
                end,
                GetTooltip = function()
                    local ret = _Notes.GetNoteName(i)
                    if _Notes.NoteIsReceivedNote(i) then
                        ret = ret .. " (pushed)" or ""
                    end
                    return ret
                end,
                clickFunc = function() _Notes.TabControl:SelectTab(1) _Notes.SelectNote(i) end,
                CheckButtonSetter = function() _Notes.ToggleNote(i) end,
                CheckButtonGetter = function() return _Notes.IsNoteActive(i) end,
                CheckButtonTooltip = "Toggle Note's visibility",
                UseCheckButton = true,
                index = i,
            }
            table.insert(items, noteButton)
        end
        return items
    end
    function _Notes.UpdateNavigation(newIndex)
        local buttonFrame = _Notes.NavigationButtons
        if not buttonFrame then return end
        buttonFrame:ProcessItemTable(_Notes.BuildNavigationItemTable(newIndex))
    end

    function _Notes.CreateNavigationButtons()
        if _Notes.NavigationButtons then
            return _Notes.NavigationButtons
        end
        local itemTable = _Notes.BuildNavigationItemTable()
        local tree = _EchoRaidTools:CreateTreeView(_EchoRaidTools.panels.main.MainMenu, itemTable, 0)
        tree:ProcessItemTable(_Notes.BuildNavigationItemTable(), true)
        _Notes.NavigationButtons = tree
        return _Notes.NavigationButtons
    end
    function _Notes:GetNavigationButtons()
       if _Notes.NavigationButtons then
        return _Notes.NavigationButtons
       else
        return _Notes.CreateNavigationButtons()
       end
    end

    function _Notes:GetButtonInfo()
        return "Notes",
        nil,
        function()
            return _Notes:GetConfig()
        end,
        _Notes:GetNavigationButtons(),
        2
    end
end
