-- Please use the Localization App on CurseForge to Update this
-- https://legacy.curseforge.com/wow/addons/talenttree-viewer/localization
local name, _ = ...

local L = LibStub("AceLocale-3.0"):NewLocale(name, "zhTW")
if not L then return end

-- TalentTreeViewer_Loader
L["|cffeda55fClick|r to view the talents for any spec."] = "|cffeda55f點擊|r查看任意專精的天賦。"
L["|cffeda55fShift-Click|r to hide this button. (|cffeda55f/tv reset|r to restore)"] = "|cffeda55fShift-點擊|r隱藏此按鈕。(|cffeda55f/tv reset|r 重新顯示按鈕)"
L["Would you like to open the build in Talent Viewer instead?"] = "你要在 Talent Viewer 裡預覽這個方案嗎？"

