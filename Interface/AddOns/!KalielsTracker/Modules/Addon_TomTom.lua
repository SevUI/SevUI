--- Kaliel's Tracker
--- Copyright (c) 2012-2024, Marouan Sabbagh <mar.sabbagh@gmail.com>
--- All Rights Reserved.
---
--- This file is part of addon Kaliel's Tracker.

local addonName, KT = ...
local M = KT:NewModule(addonName.."_AddonTomTom")
KT.AddonTomTom = M

local ACD = LibStub("MSA-AceConfigDialog-3.0")
local _DBG = function(...) if _DBG then _DBG("KT", ...) end end

local db
local mediaPath = "Interface\\AddOns\\"..addonName.."\\Media\\"
local questWaypoint
local superTrackedQuestID = 0

local OTF = KT_ObjectiveTrackerFrame

--------------
-- Internal --
--------------

local function SetupOptions()
	KT.options.args.tomtom = {
		name = "TomTom",
		type = "group",
		args = {
			tomtomDesc1 = {
				name = "TomTom support combined Blizzard's POI and TomTom's Arrow.\n\n"..
						"|cffff7f00Warning:|r Original \"TomTom > Quest Objectives\" options are ignored!\n\n\n"..
						"|TInterface\\WorldMap\\UI-QuestPoi-NumberIcons:32:32:-2:10:256:256:128:160:96:128|t+"..
						"|T"..mediaPath.."KT-TomTomTag:32:32:-8:10|t...   Active POI button of quest with TomTom Waypoint.",
				type = "description",
				order = 1,
			},
			tomtomArrival = {
				name = "Arrival distance",
				type = "range",
				min = 0,
				max = 150,
				step = 5,
				set = function(_, value)
					db.tomtomArrival = value
				end,
				order = 2,
			},
			tomtomAnnounce = {
				name = "Waypoint announcement",
				desc = "Show announcement when add/remove quest waypoint, inside the chat frame. When disable this option, you always see messages \"No data for quest waypoint\".",
				type = "toggle",
				width = 1.1,
				set = function()
					db.tomtomAnnounce = not db.tomtomAnnounce
				end,
				order = 3,
			},
		},
	}

	KT.optionsFrame.tomtom = ACD:AddToBlizOptions(addonName, "Addon - "..KT.options.args.tomtom.name, KT.title, "tomtom")

	-- Reverts the option to display Quest Objectives
	if not GetCVarBool("questPOI") then
		SetCVar("questPOI", 1)
	end
end

local function Announce(msg, force)
	if db.tomtomAnnounce or force then
		ChatFrame1:AddMessage("|cff33ff99"..KT.title..":|r "..msg)
	end
end

local QuestPOIGetIconInfo = QuestPOIGetIconInfo
if not QuestPOIGetIconInfo then
	QuestPOIGetIconInfo = function(questID)
		local x, y
		local completed = C_QuestLog.IsComplete(questID)
		local mapID = GetQuestUiMapID(questID)
		if mapID and mapID > 0 then
			local quests = C_QuestLog.GetQuestsOnMap(mapID)
			if quests then
				for _, info in pairs(quests) do
					if info.questID == questID then
						x = info.x
						y = info.y
						break
					end
				end
			end
		end
		return completed, x, y
	end
end

local function WorldQuestPOIGetIconInfo(mapID, questID)
	local x, y
	local taskInfo = GetQuestsForPlayerByMapIDCached(mapID)
	if taskInfo then
		for _, info  in ipairs(taskInfo) do
			if HaveQuestData(info.questId) then
				if info.questId == questID then
					x = info.x
					y = info.y
					break
				end
			end
		end
	end
	return x, y
end

local function SetWaypointTag(button, show)
	if show then
		if button.KTtomtom then
			button.KTtomtom:Show()
		else
			if button.Display then
				button.KTtomtom = button.Display:CreateTexture(nil, "OVERLAY")
				button.KTtomtom:SetTexture(mediaPath.."KT-TomTomTag")
				button.KTtomtom:SetPoint("CENTER")
			end
		end

		if button.KTtomtom and button.pinScale then
			local scale = button.KTtomtom:GetParent():GetPinScale()
			button.KTtomtom:SetSize(scale * 32, scale * 32)
		end
	else
		if button.KTtomtom then
			button.KTtomtom:Hide()
		end
	end
end

local function AddWaypoint(questID, isSilent)
	if C_QuestLog.IsQuestCalling(questID) then
		return false
	end

	local title, mapID
	local x, y, completed
	if QuestUtils_IsQuestWorldQuest(questID) then
		title = C_TaskQuest.GetQuestInfoByQuestID(questID)
		mapID = C_TaskQuest.GetQuestZoneID(questID)
		if mapID then
			x, y = WorldQuestPOIGetIconInfo(mapID, questID)
		end
	else
		title = C_QuestLog.GetTitleForQuestID(questID)
		mapID = GetQuestUiMapID(questID)
		if mapID and mapID > 0 then
			completed, x, y = QuestPOIGetIconInfo(questID)
		end
	end

	if not title then
		return false
	end

	if completed then
		title = "|TInterface\\GossipFrame\\ActiveQuestIcon:0:0:0:0|t "..title
	else
		title = "|TInterface\\GossipFrame\\AvailableQuestIcon:0:0:0:0|t "..title
	end

	if not mapID or mapID == 0 or not x or not y then
		if not isSilent then
			Announce("|cffff0000No data for quest waypoint|r ..."..title, true)
		end
		return false
	end

	local uid = TomTom:AddWaypoint(mapID, x, y, {
		title = title,
		silent = true,
		world = false,
		minimap = false,
		crazy = true,
		persistent = false,
		arrivaldistance = db.tomtomArrival,
	})
	uid.questID = questID
	questWaypoint = uid

	if not isSilent then
		Announce("Added a quest waypoint ..."..title)
	end

	return true
end

local function RemoveWaypoint(questID)
	if questID == superTrackedQuestID then
		TomTom:RemoveWaypoint(questWaypoint)
		questWaypoint = nil
		superTrackedQuestID = 0
	end
end

local function SetSuperTrackedQuestWaypoint(questID, force)
	if questID ~= superTrackedQuestID or force then
		RemoveWaypoint(superTrackedQuestID)
		if not QuestUtils_IsQuestBonusObjective(questID) then
			if AddWaypoint(questID, force) then
				superTrackedQuestID = questID
			end
		end
	end
end

local function SetHooks()
	-- TomTom
	if TomTom.EnableDisablePOIIntegration then
		local bck_TomTom_EnableDisablePOIIntegration = TomTom.EnableDisablePOIIntegration
		function TomTom:EnableDisablePOIIntegration()
			TomTom.profile.poi.enable = false
			TomTom.profile.poi.modifier = "A"
			TomTom.profile.poi.setClosest = false
			TomTom.profile.poi.arrival = 0
			bck_TomTom_EnableDisablePOIIntegration(self)
		end
	end

	hooksecurefunc(TomTom, "ClearWaypoint", function(self, uid)
		if uid.questID == superTrackedQuestID then
			questWaypoint = nil
			superTrackedQuestID = 0
			OTF:Update()
			if QuestMapFrame:IsShown() then
				QuestMapFrame:Refresh()
			end
		end
	end)

	hooksecurefunc(TomTom, "SetCrazyArrow", function(self, uid, dist, title)
		if superTrackedQuestID > 0 then
			RemoveWaypoint(superTrackedQuestID)
		end
	end)

	-- Blizzard
	hooksecurefunc(C_SuperTrack, "SetSuperTrackedQuestID", function(questID)
		SetSuperTrackedQuestWaypoint(questID)
	end)

	hooksecurefunc(C_SuperTrack, "ClearAllSuperTracked", function()
		if superTrackedQuestID > 0 then
			RemoveWaypoint(superTrackedQuestID)
		end
	end)

	hooksecurefunc(C_QuestLog, "AbandonQuest", function()
		local questID = QuestMapFrame.DetailsFrame.questID or QuestLogPopupDetailFrame.questID
		RemoveWaypoint(questID)
	end)

	-- Only for World Quests
	hooksecurefunc(KT_WorldQuestObjectiveTracker, "OnQuestTurnedIn", function(self, questID)
		RemoveWaypoint(questID)
	end)

	hooksecurefunc(POIButtonMixin, "UpdateButtonStyle", function(self)
		if self.questID then
			SetWaypointTag(self, superTrackedQuestID == self.questID)
		end
	end)

	hooksecurefunc(POIButtonMixin, "OnClick", function(self)
		KT_CampaignQuestObjectiveTracker:MarkDirty()
		-- Quest and World Quest modules are automatically marked as dirty
	end)
end

local function SetEvents()
	-- Update waypoint after reload with supertracking
	KT:RegEvent("QUEST_LOG_UPDATE", function(eventID)
		local questID = C_SuperTrack.GetSuperTrackedQuestID()
		if questID then
			SetSuperTrackedQuestWaypoint(questID)
		end
		KT:UnregEvent(eventID)
	end)

	-- Update waypoint after quest objectives changed
	KT:RegEvent("QUEST_WATCH_UPDATE", function(_, questID)
		if questID == C_SuperTrack.GetSuperTrackedQuestID() then
			C_Timer.After(0, function()
				SetSuperTrackedQuestWaypoint(questID, true)
			end)
		end
	end)

	-- Update waypoint after accept quest
	KT:RegEvent("QUEST_POI_UPDATE", function()
		local questID = C_SuperTrack.GetSuperTrackedQuestID()
		if questID then
			SetSuperTrackedQuestWaypoint(questID)
			OTF:Update()
		end
	end)
end

--------------
-- External --
--------------

function M:OnInitialize()
	_DBG("|cffffff00Init|r - "..self:GetName(), true)
	db = KT.db.profile
	self.isLoaded = (KT:CheckAddOn("TomTom", "v4.0.1-release") and db.addonTomTom)

	if self.isLoaded then
		KT:Alert_IncompatibleAddon("TomTom", "v4.0.1-release")
	end

	local defaults = KT:MergeTables({
		profile = {
			tomtomArrival = 20,
			tomtomAnnounce = true,
		}
	}, KT.db.defaults)
	KT.db:RegisterDefaults(defaults)
end

function M:OnEnable()
	_DBG("|cff00ff00Enable|r - "..self:GetName(), true)
	SetupOptions()
	SetEvents()
	SetHooks()
end