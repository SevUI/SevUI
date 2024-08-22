-- Please use the Localization App on CurseForge to Update this
-- https://legacy.curseforge.com/wow/addons/talenttree-viewer/localization
local name, _ = ...

local L = LibStub("AceLocale-3.0"):NewLocale(name, "zhCN")
if not L then return end

-- TalentTreeViewer_Loader
L["|cffeda55fClick|r to view the talents for any spec."] = "|cffeda55f点击|r查看任意专精的天赋树。"
L["|cffeda55fShift-Click|r to hide this button. (|cffeda55f/tv reset|r to restore)"] = [=[|cffeda55fShift-点击|r隐藏此按钮。（(|cffeda55f/tv reset|r重新显示按钮）

]=]
L["Would you like to open the build in Talent Viewer instead?"] = "要改用 Talent Viewer 开启这个方案吗？"

