-- Please use the Localization App on CurseForge to Update this
-- https://legacy.curseforge.com/wow/addons/talenttree-viewer/localization
local name, _ = ...

local debug = false
--[==[@debug@
debug = true
--@end-debug@]==]

local L = LibStub("AceLocale-3.0"):NewLocale(name, "enUS", true, debug)

-- TalentTreeViewer
L["%d (level %d)"] = "%d (level %d)"
L["Click to |cFF3333FFdownload|r TalentLoadoutManager"] = "Click to |cFF3333FFdownload|r TalentLoadoutManager"
L["CTRL-C to copy"] = "CTRL-C to copy"
L["Error while importing IcyVeins URL: Could not find node for index"] = "Error while importing IcyVeins URL: Could not find node for index"
L["Export"] = "Export"
L["Icy-veins calculator links are also supported!"] = "Icy-veins calculator links are also supported!"
L["Ignore Restrictions"] = "Ignore Restrictions"
L["Ignore restrictions when selecting talents"] = "Ignore restrictions when selecting talents"
L["Import string is corrupt, node type mismatch at nodeID %d. First option will be selected."] = "Import string is corrupt, node type mismatch at nodeID %d. First option will be selected."
L["Level"] = "Level"
L["Leveling build"] = "Leveling build"
L["Leveling build %d (%d points spent)"] = "Leveling build %d (%d points spent)"
L["Leveling Build Tools"] = "Leveling Build Tools"
L["Leveling builds can be saved and loaded with TalentLoadoutManager"] = "Leveling builds can be saved and loaded with TalentLoadoutManager"
L["Save leveling build recording, and reset the leveling build."] = "Save leveling build recording, and reset the leveling build."
L["Select a leveling build to apply"] = "Select a leveling build to apply"
L["Select another Specialization"] = "Select another Specialization"
L["Select Recorded Build"] = "Select Recorded Build"
L["Select the level to apply the leveling build to"] = "Select the level to apply the leveling build to"
L["Start/resume recording a leveling build. This will fast-forward you to the highest level in the current build."] = "Start/resume recording a leveling build. This will fast-forward you to the highest level in the current build."
L["Stop recording the leveling build."] = "Stop recording the leveling build."
L["This will lag out your game!"] = "This will lag out your game!"
L["This will reset your current talent choices!"] = "This will reset your current talent choices!"
L["You can also export/import leveling builds, or link them in chat"] = "You can also export/import leveling builds, or link them in chat"

