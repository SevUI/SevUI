local _AddonName, _EchoRaidTools = ...
local _Notes = _EchoRaidTools:GetModule("Notes")

local eventFrame = CreateFrame("FRAME")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
eventFrame:RegisterEvent("ENCOUNTER_START")
eventFrame:RegisterEvent("ENCOUNTER_END")
eventFrame:RegisterEvent("GROUP_LEFT")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "GROUP_ROSTER_UPDATE" then
        if  _Notes.ConfigOpen then
            _Notes.UpdateUnitPickerDropdown()
        end
    elseif event == "GUILD_ROSTER_UPDATE" then
        if  _Notes.ConfigOpen then
            _Notes.UpdateGuildPickerDropdown()
        end
    elseif event == "ENCOUNTER_START" then
        _Notes.StartEncounter()
    elseif event == "ENCOUNTER_END" then
        _Notes.EndEncounter()
    elseif event == "GROUP_LEFT" then
        if not IsInGroup() then
            _Notes.PurgeGroupNotes()
        end
    elseif event == "PLAYER_LOGOUT" then
        if not IsInGroup() then
            _Notes.PurgeGroupNotes()
        end
    end
end)
