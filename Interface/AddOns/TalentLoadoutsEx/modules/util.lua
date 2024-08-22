local addonName, Addon = ...;

function Addon:Print(...)
	print(format("|cff1eff00%s: |r", addonName), ...);
end

Addon.isLocked = false;
function Addon:Lock()
	Addon.isLocked = true;
	Addon:UpdatePanelButton();
end

function Addon:Unlock()
	Addon.isLocked = false;
	Addon:UpdatePanelButton();
end
