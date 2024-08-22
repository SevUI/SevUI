local prefix = "SevUI"
local playerName = UnitName("player")

C_ChatInfo.RegisterAddonMessagePrefix(prefix)

local function OnEvent(self, event, ...)
	if event == "CHAT_MSG_ADDON" then
        local pref, message = ...
        if pref == prefix then
            SlashCmdList.BIGWIGSLOCALBAR(message)
            -- print("inc", message);
        end
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_ADDON")
f:SetScript("OnEvent", OnEvent)



--C_ChatInfo.SendAddonMessage("SevUI", "10 asd", "WHISPER", UnitName("player"))