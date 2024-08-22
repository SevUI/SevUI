local _AddonName, _EchoRaidTools = ...
local _Notes = _EchoRaidTools:GetModule("Notes")

local LibSharedMedia = LibStub:GetLibrary ("LibSharedMedia-3.0")
local aceComm = LibStub:GetLibrary ("AceComm-3.0", true)

local GetSpellInfo = GetSpellInfo
if not GetSpellInfo then
    GetSpellInfo = function(spellID)
		if not spellID then
			return nil;
		end

		local spellInfo = C_Spell.GetSpellInfo(spellID);
		if spellInfo then
			return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime, spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID, spellInfo.originalIconID;
		end
	end
end

function _Notes:LoadSettings()
    EchoRaidToolsDB.Notes = EchoRaidToolsDB.Notes or {}
    local data = EchoRaidToolsDB.Notes

    local function checkForOverlapUIDs(uid)
        for _, noteDetails in pairs(data.SavedNotes) do
            if noteDetails.uid == uid then
                uid = uid.."a"
                checkForOverlapUIDs(uid)
            end
        end
        return uid
    end
    local function acquireNoteUID()
        local guid = UnitGUID("player"):sub(8)
        local time = GetServerTime()
        local uid = guid..time
        return checkForOverlapUIDs(uid)
    end
    data.SavedNotes = data.SavedNotes or {}
    data.SavedNotes[1] = data.SavedNotes[1] or {
        name = "Note",
        note = "",
        show = true,
        uid = acquireNoteUID(),
        received = false,
    }
    for _, noteInfo in pairs(data.SavedNotes) do
        if not noteInfo.uid then
            noteInfo.uid = acquireNoteUID()
        end
    end
    data.Note = data.SavedNotes[1].note

    local currentNote = 1

    function _Notes.GetAllSavedNotes()
        return data.SavedNotes
    end
    function _Notes.GetNoteName(index)
        return data.SavedNotes[index].name
    end
    function _Notes.GetCurrentNoteName()
        return _Notes.GetNoteName(_Notes.GetCurrentNoteIndex())
    end
    function _Notes.GetNoteUID(index)
        return data.SavedNotes[index].uid
    end
    function _Notes.GetCurrentNoteUID()
        return _Notes.GetNoteUID(_Notes.GetCurrentNoteIndex())
    end
    function _Notes.RenameNote(text, index)
        data.SavedNotes[index].name = text
        _Notes.ResetNote()
    end
    function _Notes.GetTotalNumNotes()
        return #data.SavedNotes
    end
    function _Notes.GetCurrentNoteIndex()
        return currentNote
    end
    function _Notes.GetNoteTextByIndex(index)
        return data.SavedNotes[index].note
    end
    function _Notes.NoteIsReceivedNote(index)
        return data.SavedNotes[index] and data.SavedNotes[index].received
    end

    function _Notes.MoveNoteIndex(index, delta)
        local newIndex = index + delta
        if newIndex > 0 and newIndex <= #data.SavedNotes then
            local removed = table.remove(data.SavedNotes, index)
            table.insert(data.SavedNotes, newIndex, removed)
            _Notes.FormatAndDisplayNote()
        end
    end

    data.x = data.x or 50
    data.y = data.y or 50
    data.width = data.width or 200
    data.height = data.height or 200
    data.useBorder = data.useBorder == nil and true or data.useBorder
    data.border = data.border or "1 pixel"
    data.borderColor = data.borderColor or {0,0,0,1}
    data.borderSize = data.borderSize or 2
    data.borderOffsetX = data.borderOffsetX or 0
    data.borderOffsetY = data.borderOffsetY or 0
    data.backgroundColor = data.backgroundColor or {0,0,0,0.3}
    data.moduleEnabled = not not data.moduleEnabled
    data.saveNotes = false
    data.lockNote = not not data.lockNote
    --vdt(data)

    local history = {data.Note or ""}
    local historyIndex = 1

    local BorderArray
    _Notes.BuildBorderArray = function()
        if not BorderArray then
            BorderArray = {}
            local borders = LibSharedMedia:HashTable("border")
            for name, borderPath in pairs (borders) do
                table.insert(BorderArray, {value = name, label = name, border = borderPath})
            end
            table.sort(BorderArray, function (t1, t2) return t1.label < t2.label end)
            return BorderArray
        else
            return BorderArray
        end
    end

    function _Notes.EnableModule()
        _Notes.NotesFrame:Show()
    end
    function _Notes.DisableModule()
        _Notes.NotesFrame:Hide()
    end
    function _Notes.GetModuleEnabled()
        return data.moduleEnabled
    end
    function _Notes.ToggleModuleEnabled()
        data.moduleEnabled = not data.moduleEnabled
        if data.moduleEnabled then
            _Notes.EnableModule()
        else
            _Notes.DisableModule()
        end
    end

    function _Notes.GetXY()
        return data.x, data.y
    end
    function _Notes.SetXY(x,y)
        data.x = x
        data.y = y
    end
    function _Notes.GetSize()
        return data.width, data.height
    end
    function _Notes.SetSize(w,h)
        data.width = w
        data.height = h
    end

    function _Notes.ToggleLock()
        data.lockNote = not data.lockNote
        if data.lockNote then
            
        else
            
        end
    end
    function _Notes.GetLock()
        return data.lockNote
    end
    function _Notes.ToggleUseBorder()
        data.useBorder = not data.useBorder
        if data.useBorder then
            _Notes.NotesFrame.Border:Show()
        else
            _Notes.NotesFrame.Border:Hide()
        end
    end
    function _Notes.GetUseBorder()
        return data.useBorder
    end
    function _Notes.SetBorder(value)
        data.border = value
        _Notes.NotesFrame:SetUpDisplayBorder()
    end
    function _Notes.GetBorder()
        return data.border
    end
    function _Notes.GetBorderRGBA()
        local r,g,b,a = unpack(data.borderColor)
        return r,g,b,a
    end
    function _Notes.SetBorderRGBA(r,g,b,a)
        data.borderColor = {r,g,b,a}
        _Notes.NotesFrame:SetUpDisplayBorder()
    end
    function _Notes.GetBorderSize()
        return data.borderSize
    end
    function _Notes.SetBorderSize(value)
        data.borderSize = value
        _Notes.NotesFrame:SetUpDisplayBorder()
    end
    function _Notes.GetBackgroundRGBA()
        local r,g,b,a = unpack(data.backgroundColor)
        return r,g,b,a
    end
    function _Notes.SetBackgroundRGBA(r,g,b,a)
        data.backgroundColor = {r,g,b,a}
        _Notes.NotesFrame.BG:SetVertexColor(r,g,b,a)
    end

    function _Notes.FireScanEvents()
        if WeakAuras and WeakAuras.ScanEvents then
            WeakAuras.ScanEvents("ECHO_NOTE_UDPATE", true)
        end
    end
    function _Notes.UpdateMainEditBox(text)
        if _Notes.MainEditBox then
            _Notes.MainEditBox:SetText(text)
        end
    end
    function _Notes.FormatLinksForDisplay(text)
        text = text:gsub("|H.-|h.-|h", function(link)
            local linkInfo, displayText = LinkUtil.SplitLink(link)
            local linkType, tagType, tag1, tag2, tag3 = strsplit(":", linkInfo)
            if tagType == "spell" and tag1 then
                local name, _, icon = GetSpellInfo(tag1)
                if icon then
                    return LinkUtil.FormatLink("addon", format("|T%d:0|t %s", icon, name), tagType, tag1)
                end
            elseif tagType == "icon" and tag1 then
                local iconString = _Notes.iconLookup[tag1] and _Notes.iconLookup[tag1].markup or tag1
                if iconString then
                    return LinkUtil.FormatLink("addon", iconString, tagType, tag1)
                end
            end
        end)
        return text
    end
    function _Notes.FormatAndDisplayNote()
        if _Notes.NotesFrame then
            local displayText = ""
            for _, noteInfo in ipairs(data.SavedNotes) do
                if noteInfo.show then
                    displayText = format("%s%s|cff555555=== |cffaaaaaa%s|r ===|r\n\n%s", displayText, displayText == "" and "" or "\n\n", noteInfo.name, noteInfo.note)
                end
            end
            displayText = displayText:gsub("||", "|")
            displayText = _Notes.FormatLinksForDisplay(displayText)
            _Notes.NotesFrame.Text:SetText(displayText)
        end
    end
    function _Notes.SetUndoStatus()
        if _Notes.UndoButton and _Notes.RedoButton then
            if historyIndex == #history then
                _Notes.RedoButton:Disable()
            else
                _Notes.RedoButton:Enable()
            end
            if historyIndex <= 1 then
                _Notes.UndoButton:Disable()
            else
                _Notes.UndoButton:Enable()
            end
        end
    end
    function _Notes.MoveThroughHistory(adjust)
        local newHistoryIndex = historyIndex + adjust
        if history[newHistoryIndex] then
            _Notes.PauseNoteChangeHandling = true
            RunNextFrame(function() _Notes.PauseNoteChangeHandling = false end)
            local historyNote = history[newHistoryIndex]
            data.Note = historyNote
            data.SavedNotes[currentNote].note = historyNote
            _Notes.MainEditBox:SetText(historyNote)
            _Notes.FormatAndDisplayNote()
            historyIndex = newHistoryIndex
            _Notes.SetUndoStatus()
        end
    end
    function _Notes.ClearHistory()
        history = {data.Note or ""}
        historyIndex = 1
    end
    function _Notes.UpdateNote(newText, userInput)
        if newText ~= _Notes.GetNote() then
            if historyIndex < #history then
                for i = historyIndex +1, #history do
                    history[i] = nil
                end
            end
            table.insert(history, newText)
            historyIndex = #history
            --vdt(history, #history)
            _Notes.SetUndoStatus()
            data.Note = newText
            data.SavedNotes[currentNote].note = newText
            --_Notes.UpdateMainEditBox(newText)
            _Notes.FormatAndDisplayNote(newText)
            _Notes.FireScanEvents()
        end
    end
    function _Notes.GetNote()
        return data.Note or ""
    end
    function _Notes.ResetNote()
        _Notes.FormatAndDisplayNote()
    end

    function _Notes.SelectNote(index)
        currentNote = index
        data.Note = _Notes.GetNoteTextByIndex(index)
        _Notes.UpdateMainEditBox(data.Note)
        _Notes.ClearHistory()
        _Notes.SetUndoStatus()
        _Notes.ResetNote()
        _Notes.UpdateNavigation(index)
    end
    function _Notes.AddReceivedNote(name, uid, noteString)
        for index, noteDetails in pairs(data.SavedNotes) do
            if noteDetails.uid == uid then
                noteDetails.note = noteString
                _Notes.SelectNote(index)
                return
            end
        end
        local newNote = {name = name, uid = uid, show = true, note = noteString, received = true}
        table.insert(data.SavedNotes, newNote)
        local index = #data.SavedNotes
        _Notes.SelectNote(index)
    end
    function _Notes.AddNewNote()
        local uid = acquireNoteUID()
        local newNote = {note = "", name = "New Note", show = false, uid = uid, received = false}
        table.insert(data.SavedNotes, newNote)
        local index = #data.SavedNotes
        _Notes.SelectNote(index)
    end
    function _Notes.CopyNote(index)
        local newNote = CopyTable(data.SavedNotes[index])
        newNote.name = format("%s Copy", newNote.name)
        newNote.uid = acquireNoteUID()
        newNote.received = false
        table.insert(data.SavedNotes, newNote)
        local newIndex = #data.SavedNotes
        _Notes.SelectNote(newIndex)
    end
    function _Notes.ExecuteDeleteNote(index)
        table.remove(data.SavedNotes, index)
        _Notes.SelectNote(math.max(index - 1, 1))
    end
    function _Notes.DeleteNote(index)
        if #data.SavedNotes > 1 and data.SavedNotes[index] then
            local popup = _Notes.GetDialogPopup()
            popup:ClearAllPoints()
            popup:SetPoint("CENTER")
            popup:Show()
            local name = _Notes.GetNoteName(index)
            popup.Text:SetText("Do you really want to delete the following Note?\n"..name)
            popup.OKButton:SetScript("OnClick", function()
                popup.OKButton:SetScript("OnClick", nil)
                popup:Hide()
                _Notes.ExecuteDeleteNote(index)
            end)
            popup.CancelButton:SetScript("OnClick", function()
                popup.OKButton:SetScript("OnClick", nil)
                popup:Hide()
            end)
        end
    end
    function _Notes.SetGroupLeaveBehaviour(selection)
        if selection == 1 then
            data.saveNotes = false
        elseif selection == 2 then
            data.saveNotes = true
        end
    end
    function _Notes.GetGroupLeaveBehaviour()
        return data.saveNotes and 2 or 1
    end
    function _Notes.PurgeGroupNotes()
        local changed = false
        for i = #data.SavedNotes, 1, -1 do
            if data.SavedNotes[i].received then
                if data.saveNotes then
                    data.SavedNotes[i].received = false
                    data.SavedNotes[i].uid = acquireNoteUID()
                else
                    table.remove(data.SavedNotes, i)
                    changed = true
                end
            end
        end
        if changed then
            _Notes.SelectNote(1)
        end
    end
    function _Notes.ToggleNote(index)
        if data.SavedNotes[index] then
            data.SavedNotes[index].show = not data.SavedNotes[index].show
            _Notes.ResetNote()
            _Notes.UpdateNavigation(index)
        end
    end
    function _Notes.IsNoteActive(index)
        return data.SavedNotes[index] and data.SavedNotes[index].show
    end

    function _Notes.GetCaptureString(startIndex, endIndex, inserting)
        if inserting then
            startIndex = startIndex -1
        end
        local cap = string.format("(%s)(%s)(.*)",string.rep(".", startIndex), string.rep(".", endIndex-startIndex))
        return cap
    end
    function _Notes.GetTextByIndices(startIndex, endIndex)
        local captureString = _Notes.GetCaptureString(startIndex, endIndex)
        local text = _Notes.GetNote()
        local highlightText = select(2, text:match(captureString))
        return highlightText
    end
    local function formatStringByPosition(mainString, startIndex, endIndex, formatString)
        local captureString = _Notes.GetCaptureString(startIndex, endIndex, true)
        local replaceString = format(startIndex > 1 and "%%1%s%%3" or "%s%%3", formatString)
        return mainString:gsub(captureString, replaceString)
    end

    local function insertString(str1, str2, pos)
        return str1:gsub("()", {[pos]=str2})
    end
    function _Notes.AddColorToSelectedText(r,g,b,a)
        if _Notes.isCursorInsideTag() then
            return
        end
        local col = CreateColor(r,g,b,a)
        col = col:GenerateHexColor()
        if col then
            local highlightS, highlightE = _Notes.MainEditBox:GetTextHighlight()
            if highlightS and highlightE and highlightS ~= highlightE then
                local text = _Notes.GetNote()
                --text = insertString(text, "|r", highlightE+1)
                --text = insertString(text, "|c"..col, highlightS+1)
                text = formatStringByPosition(text, highlightS, highlightE, format("|Haddon:color:%s|h|c%s%%2|r|h ", col, col))
                _Notes.UpdateNote(text)
                _Notes.UpdateMainEditBox(text)
            end
        end
    end
    local tagTypes = {
        color = {
            func = function(text, hex)
                return format("|Haddon:color:%s:%s|h|c%s%s|r|h", text, hex, hex, text)
            end,
            text = "Color",
        },
        player = {
            func = function(name, class)
                local hex = select(4, GetClassColor(class))
                if name and hex then
                    return format("|Haddon:player:%s:%s|h|c%s%s|r|h", name, class, hex, name)
                end
            end,
            text = "Player",
        },
        --[[unit = {
            func = function(unit)
                local name = UnitName(unit)
                local class = select(2, UnitClass(unit))
                local hex = select(4, GetClassColor(class))
                if name and hex then
                    return format("|Haddon:unit:%s|h|c%s%s|r|h", unit, hex, name)
                end
            end,
            text = "Unit",
        },]]
        timer = {
            func = function(seconds)
                return format("|Haddon:timer:%d|h|cffcccccc{%s}|r|h", seconds, SecondsToClock(seconds))
            end,
            text = "Timer",
        },
        spell = {
            func = function(spellID)
                spellID = tonumber(spellID)
                if spellID then
                    local name, _, icon = GetSpellInfo(spellID)
                    if name and icon then
                        return format("|Haddon:spell:%d|h|cffffd100[%s]|r|h", spellID, name)
                    end
                end
                _EchoRaidTools:SetStatus("No valid spell found", 5)
            end,
            text = "Spell"
        },
        icon = {
            func = function(iconString)
                if _Notes.iconLookup[iconString] or tonumber(iconString) then
                    return format("|Haddon:icon:%s|h|cffcccccc[icon:%s]|r|h", iconString, iconString)
                end
                _EchoRaidTools:SetStatus("No valid icon found", 5)
            end,
            text = "Icon"
        },
    }
    _Notes.tagTypes = tagTypes
    function _Notes.GetTagString(type, ...)
        if tagTypes[type] then
            local tagString = tagTypes[type].func(...)
            return tagString
        end
    end
    function _Notes.InsertNewTag(type, ...)
        local tagString = _Notes.GetTagString(type, ...)
        if tagString then
            local s,e = _Notes.isCursorInsideTag()
            if s and e then
                local mainString = _Notes.GetNote()
                mainString = formatStringByPosition(mainString, s, e, tagString)
                _Notes.UpdateMainEditBox(mainString)
                _Notes.PauseCursorHandling = true
                --_Notes.MainEditBox:SetCursorPosition(s + #tagString + 1)
                _Notes.MainEditBox:SetFocus()
                RunNextFrame(function()
                    _Notes.PauseCursorHandling = false
                end)
            else
                _Notes.MainEditBox:Insert(format("%s ",tagString))
                _Notes.PauseCursorHandling = true
                _Notes.MainEditBox:SetFocus()
                RunNextFrame(function()
                    _Notes.PauseCursorHandling = false
                end)
            end
        end
        _Notes.lastTagString = tagString
    end
    function _Notes.InsertLastTag()
        _Notes.MainEditBox:Insert(format("%s ",_Notes.lastTagString))
        _Notes.PauseCursorHandling = true
        _Notes.MainEditBox:SetFocus()
        RunNextFrame(function()
            _Notes.PauseCursorHandling = false
        end)
    end
    function _Notes.InsertNewBlankTag(type)
        _Notes.ShowTagSettings(type)
    end
    local function getTagType(s,e)
        local fullTag = _Notes.GetNote():sub(s,e)
        local type, settings = fullTag:match("|Haddon:(%w+):(.-)|h")
        --local printableTag = fullTag:gsub("|", "\124")
        _Notes.lastTagString = fullTag
        return type, fullTag, strsplit(":", settings)
    end
    function _Notes.GetTagSettings(s,e)
        _Notes.ShowTagSettings(getTagType(s,e))
    end

    function _Notes.TrustSender(sender)
        -- is the sender trusted? Depends on leader only setting
        return true
    end
    function _Notes.ValidateReveivedNote(text)
        if text:match("^!ECHO:NOTE:") then
            local name, uid, noteString = text:match("^!ECHO:NOTE:(.-):(.-)!(.+)")
            if name and uid and noteString then
                return name, uid, noteString
            end
        end
    end

    _Notes.ConfigOpen = false
    function _Notes.OnShow()
        _Notes.ConfigOpen = true
        if _Notes.UpdateUnitPickerDropdown then _Notes.UpdateUnitPickerDropdown() end
        if _Notes.UpdateGuildPickerDropdown then _Notes.UpdateGuildPickerDropdown() end
    end
    function _Notes.OnHide()
        _Notes.ConfigOpen = false
    end

    function _Notes.LockEdit()
        if _Notes.MainEditBox then
            _Notes.MainEditBox:Disable()
        end
    end
    function _Notes.UnlockEdit()
        if _Notes.MainEditBox then
            _Notes.MainEditBox:Enable()
        end
    end

    function _Notes.CreateFormatString()
        local note = _Notes.GetNote()
        note = _Notes.FormatLinksForDisplay(note)
        local timers = {}
        note = note:gsub("|H.-|h.-|h", function(link)
            local linkInfo, displayText = LinkUtil.SplitLink(link)
            local linkType, tagType, tag1, tag2, tag3 = strsplit(":", linkInfo)
            if tagType == "timer" and tag1 then
                table.insert(timers, tonumber(tag1))
                return "%s"
            end
        end)
        return note, timers
    end

    local cTimer
    function _Notes.StartOnUpdate(note, timers)
        if cTimer then cTimer:Cancel() end
        local now = GetTime()
        local updateNote = function()
            local elapsed = GetTime() - now
            local replacements = {}
            for i, timer in ipairs(timers) do
                local current = timer - elapsed
                local col = "ffffffff"
                if current <= 0 then
                    col = "FF6B6B6B"
                elseif current <= 5 then
                    col = "FF00FF0D"
                elseif current <= 10 then
                    col = "FFFFFF62"
                end
                local displayTimer = format("|c%s{%s}|r", col, SecondsToClock(current))
                table.insert(replacements, displayTimer)
            end
            local output = format(note, unpack(replacements))
            _Notes.NotesFrame.Text:SetText(output)
        end
        cTimer = C_Timer.NewTicker(1, function() updateNote() end)
        updateNote()
    end
    function _Notes.CancelOnUpdate()
        if cTimer then cTimer:Cancel() end
        _Notes.ResetNote()
    end

    EchoNotes = {}
    function _Notes.StartEncounter()
        _Notes.LockEdit()
        local outputNote, timers = _Notes.CreateFormatString()
        _Notes.StartOnUpdate(outputNote, timers)
    end
    function _Notes.EndEncounter()
        _Notes.UnlockEdit()
        _Notes.CancelOnUpdate()
    end
    EchoNotes.StartEncounter = _Notes.StartEncounter
    EchoNotes.EndEncounter = _Notes.EndEncounter
    function _Notes.GetFullNoteString()
        return _Notes.GetNote()
    end
    function _Notes.GetNoteByLine()
        local note = _Notes.GetNote()
        local out = {strsplit("\n", note)}
        return out
    end
    function _Notes.GetHashTags()
        local lines = _Notes.GetNoteByLine()
        local ret = {}
        for i = 1, #lines do
            local line = lines[i]
            local tag, content = line:match("^#(%w-) (.+)")
            if tag and content then
                local names = {}
                for name in content:gmatch("Haddon:player:(%w+)") do
                    table.insert(names, name)
                end
                ret[tag] = ret[tag] or {}
                table.insert(ret[tag], names)
            end
        end
        return ret
    end
    function _Notes.GetSpecificHashTag(tag)
        local tagTable = _Notes.GetHashTags()
        return tagTable[tag]
    end
    EchoNotes.GetFullNoteString = _Notes.GetFullNoteString
    EchoNotes.GetNoteByLine = _Notes.GetNoteByLine
    EchoNotes.GetHashTags = _Notes.GetHashTags
    EchoNotes.GetSpecificHashTag = _Notes.GetSpecificHashTag

    _Notes.GetDialogPopup = function()
        _EchoRaidTools.PopupDialog = _EchoRaidTools.PopupDialog or CreateFrame("FRAME", nil, UIParent, "EchoRaidTools_PopupDialog")
        return _EchoRaidTools.PopupDialog
    end

    _Notes.HideDialogPopup = function()
        if _EchoRaidTools.PopupDialog and _EchoRaidTools.PopupDialog:IsShown() then
            local popup = _EchoRaidTools.PopupDialog
            popup.OKButton:SetScript("OnClick", nil)
            popup:Hide()
        end
    end
end