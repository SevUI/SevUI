-- Please use the Localization App on CurseForge to Update this
-- https://legacy.curseforge.com/wow/addons/talenttree-viewer/localization
local name, _ = ...

local debug = false
--[==[@debug@
debug = true
--@end-debug@]==]

local L = LibStub("AceLocale-3.0"):NewLocale(name, "enUS", true, debug)

-- TalentTreeViewer_Loader
L["|cffeda55fClick|r to view the talents for any spec."] = "|cffeda55fClick|r to view the talents for any spec."
L["|cffeda55fShift-Click|r to hide this button. (|cffeda55f/tv reset|r to restore)"] = "|cffeda55fShift-Click|r to hide this button. (|cffeda55f/tv reset|r to restore)"
L["Would you like to open the build in Talent Viewer instead?"] = "Would you like to open the build in Talent Viewer instead?"

