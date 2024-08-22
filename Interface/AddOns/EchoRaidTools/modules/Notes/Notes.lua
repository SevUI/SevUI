local _AddonName, _EchoRaidTools = ...
local _Notes = _EchoRaidTools:NewModule("Notes")


function _Notes:ADDON_LOADED(addonName)
    if addonName ~= _AddonName then return end
    if _Notes.loaded then return end
    local LibDeflate = LibStub:GetLibrary ("LibDeflate", true)
	local aceComm = LibStub:GetLibrary ("AceComm-3.0", true)

    _Notes:LoadSettings()
    local data = EchoRaidToolsDB.Notes

    local NotesFrame = CreateFrame("FRAME", nil, UIParent, "EchoRaidTools_NoteFrame")
    _Notes.NotesFrame = NotesFrame
    _Notes.FormatAndDisplayNote(_Notes.GetNote())

    NotesFrame:SetPoint("TOPLEFT", _Notes.GetXY())
    NotesFrame:SetSize(_Notes.GetSize())
    NotesFrame:Show()

    _Notes.noteCommPrefix = "EchoRTNote"
    local function handleComms(prefix, text, channel, sender)
        if prefix == _Notes.noteCommPrefix and text then
            if _Notes.TrustSender(sender) then
                local name, uid, noteString = _Notes.ValidateReveivedNote(text)
                if noteString then
                    _Notes.AddReceivedNote(name, uid, noteString)
                end
            end
        end
    end
    function _Notes.RegisterComms()
        aceComm:RegisterComm(_Notes.noteCommPrefix, function(...) handleComms(...) end)
    end
    _Notes.RegisterComms()

    local getNoteSendString = function()
        local noteString = _Notes.GetNote()
        local noteName = _Notes.GetCurrentNoteName()
        local uid = _Notes.GetCurrentNoteUID()
        local header = format("!ECHO:NOTE:%s:%s!", noteName, uid)
        local output = header..noteString
        return output
    end

    function _Notes:SendNote()
        local sendString = getNoteSendString()
        aceComm:SendCommMessage(_Notes.noteCommPrefix, sendString, "RAID", nil, "BULK")
    end

    _Notes:LoadConfig()
    _Notes.loaded = true
    if not _Notes.GetModuleEnabled() then
        _Notes.DisableModule()
    end
end