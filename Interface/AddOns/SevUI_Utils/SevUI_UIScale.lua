local f = CreateFrame("Frame", nil, UIParent)
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(self, event)
    UIParent:SetScale(0.5333)
    f:UnregisterAllEvents()
    
    -- Adjust SUF frames post-UIScale to ensure they're positioned in the right place
    -- local sufPet = SUFUnitpet
    -- sufPet:ClearAllPoints()
    -- sufPet:SetPoint("TOPLEFT", UIParent, "CENTER", -206, 648)

    local sufPlayer = SUFUnitplayer
    sufPlayer:ClearAllPoints()
    sufPlayer:SetPoint("CENTER", UIParent, "CENTER", -500, 0)

    local sufTarget = SUFUnittarget
    sufTarget:ClearAllPoints()
    sufTarget:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 74)

    -- local sufTargetTarget = SUFUnittargettarget
    -- sufTargetTarget:ClearAllPoints()
    -- sufTargetTarget:SetPoint("CENTER", UIParent, "CENTER", 320, -194)
end)
