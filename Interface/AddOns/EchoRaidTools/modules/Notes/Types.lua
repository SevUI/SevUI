local _AddonName, _EchoRaidTools = ...
local _Notes = _EchoRaidTools:GetModule("Notes")

--[[_Notes.iconTypes = {
    star			= "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1.blp:0|t",
    circle			= "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2.blp:0|t",
    diamond			= "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3.blp:0|t",
    triangle		= "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4.blp:0|t",
    moon			= "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5.blp:0|t",
    square			= "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6.blp:0|t",
    cross			= "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7.blp:0|t",
    skull			= "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8.blp:0|t",
    deathknight     = CreateAtlasMarkup("classicon-deathknight"),
    demonhunter     = CreateAtlasMarkup("classicon-demonhunter"),
    druid           = CreateAtlasMarkup("classicon-druid"),
    hunter          = CreateAtlasMarkup("classicon-hunter"),
    mage            = CreateAtlasMarkup("classicon-mage"),
    monk            = CreateAtlasMarkup("classicon-monk"),
    paladin         = CreateAtlasMarkup("classicon-paladin"),
    priest          = CreateAtlasMarkup("classicon-priest"),
    rogue           = CreateAtlasMarkup("classicon-rogue"),
    shaman          = CreateAtlasMarkup("classicon-shaman"),
    warlock         = CreateAtlasMarkup("classicon-warlock"),
    warrior         = CreateAtlasMarkup("classicon-warrior"),
    evoker          = CreateAtlasMarkup("classicon-evoker"),
}]]
_Notes.IconReference = {
    {ref = "star", text = "Star", type = "texture", path = [[Interface\TargetingFrame\UI-RaidTargetingIcon_1]], markup = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1.blp:0|t"},
    {ref = "circle", text = "Circle", type = "texture", path = [[Interface\TargetingFrame\UI-RaidTargetingIcon_2]], markup = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2.blp:0|t"},
    {ref = "diamond", text = "Diamond", type = "texture", path = [[Interface\TargetingFrame\UI-RaidTargetingIcon_3]], markup = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3.blp:0|t"},
    {ref = "triangle", text = "Triangle", type = "texture", path = [[Interface\TargetingFrame\UI-RaidTargetingIcon_4]], markup = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4.blp:0|t"},
    {ref = "moon", text = "Moon", type = "texture", path = [[Interface\TargetingFrame\UI-RaidTargetingIcon_5]], markup = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5.blp:0|t"},
    {ref = "square", text = "Square", type = "texture", path = [[Interface\TargetingFrame\UI-RaidTargetingIcon_6]], markup = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6.blp:0|t"},
    {ref = "cross", text = "Cross", type = "texture", path = [[Interface\TargetingFrame\UI-RaidTargetingIcon_7]], markup = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7.blp:0|t"},
    {ref = "skull", text = "Skull", type = "texture", path = [[Interface\TargetingFrame\UI-RaidTargetingIcon_8]], markup = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8.blp:0|t"},
}
for i = 1, GetNumClasses() do
    local name, file = GetClassInfo(i)
    local path = "classicon-"..file:lower()
    local t = {ref = file:lower(), text = name, type = "atlas", path = path, markup = CreateAtlasMarkup(path)}
    table.insert(_Notes.IconReference, t)
end
_Notes.iconLookup = {}
for i, info in ipairs(_Notes.IconReference) do
    _Notes.iconLookup[info.ref] = info
end
