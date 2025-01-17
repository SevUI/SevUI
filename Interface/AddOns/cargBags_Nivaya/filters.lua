local addon, ns = ...
local cargBags = ns.cargBags

local isClassic = WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE
local isCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local IsAddOnLoaded = IsAddOnLoaded or C_AddOns.IsAddOnLoaded

local isDF = select(4,GetBuildInfo()) >= 100000
local NumBagContainer = isDF and 5 or 4
local BankContainerStartID = NumBagContainer + 1
local MaxNumContainer = isDF and 12 or 11

local cbNivaya = cargBags:NewImplementation("Nivaya")
cbNivaya:RegisterBlizzard()
function cbNivaya:UpdateBags() for i = -3, MaxNumContainer do cbNivaya:UpdateBag(i) end end

local L = cBnivL
cB_Filters = {}
cB_KnownItems = cB_KnownItems or {}
cBniv_CatInfo = {}
cB_ItemClass = {}

cB_existsBankBag = { Armor = true, Gem = true, Quest = true, TradeGoods = true, Consumables = true, ArtifactPower = true, BattlePet = true }
cB_filterEnabled = { Armor = true, Gem = true, Quest = true, TradeGoods = true, Consumables = true, Keyring = true, Junk = true, Stuff = true, ItemSets = true, ArtifactPower = true, BattlePet = true }

--------------------
--Basic filters
--------------------
cB_Filters.fBags = function(item) return item.bagID >= 0 and item.bagID <= NumBagContainer end
cB_Filters.fBank = function(item) return item.bagID == -1 or item.bagID >= BankContainerStartID and item.bagID <= MaxNumContainer end
if isRetail then
	cB_Filters.fBankReagent = function(item) return item.bagID == -3 end
end
cB_Filters.fBankFilter = function() return cBnivCfg.FilterBank end
cB_Filters.fHideEmpty = function(item) if cBnivCfg.CompressEmpty then return item.link ~= nil else return true end end

------------------------------------
-- General Classification (cached)
------------------------------------
cB_Filters.fItemClass = function(item, container)
	if not item.id or not item.name then	return false	end	-- incomplete data (itemID or itemName missing), return (item that aren't loaded yet will get classified on the next successful call)
	if cB_ItemClass[item.id] == "Keyring" and not KeyRingButtonIDToInvSlotID then
		cB_ItemClass[item.id] = nil
	end
	if not cB_ItemClass[item.id] or (KeyRingButtonIDToInvSlotID and item.bagID == -2) then
		cbNivaya:ClassifyItem(item)
	end
	
	local t, bag = cB_ItemClass[item.id]

	local isBankBag = item.bagID == -1 or (item.bagID >= BankContainerStartID and item.bagID <= MaxNumContainer)
	if isBankBag then
		bag = (cB_existsBankBag[t] and cBnivCfg.FilterBank and cB_filterEnabled[t]) and "Bank"..t or "Bank"
	else
		bag = (t ~= "NoClass" and cB_filterEnabled[t]) and t or "Bag"
	end

	return bag == container
end


function cbNivaya:ClassifyItem(item)
	-- keyring
	if item.bagID == -2 and KeyRingButtonIDToInvSlotID then
		cB_ItemClass[item.id] = "Keyring";
		return true
	end

	-- user assigned containers
	local tC = cBniv_CatInfo[item.id]
	if tC then cB_ItemClass[item.id] = tC; return true end

	-- junk
	if (item.rarity == 0) then cB_ItemClass[item.id] = "Junk"; return true end

	-- type based filters
	if item.type then
		if		(item.type == L.Armor) or (item.type == L.Weapon)	then cB_ItemClass[item.id] = "Armor"; return true
		elseif	(item.type == L.Gem)								then cB_ItemClass[item.id] = "Gem"; return true
		elseif	(item.type == L.Quest)								then cB_ItemClass[item.id] = "Quest"; return true
		elseif	(item.type == L.Trades)								then cB_ItemClass[item.id] = "TradeGoods"; return true
		elseif	(item.type == L.Consumables)						then cB_ItemClass[item.id] = "Consumables"; return true
		elseif	(item.type == POWER_TYPE_ANIMA)						then cB_ItemClass[item.id] = "ArtifactPower"; return true
		elseif	(item.type == L.BattlePet)							then cB_ItemClass[item.id] = "BattlePet"; return true
		end
	end
	
	cB_ItemClass[item.id] = "NoClass"
end

------------------------------------------
-- New Items filter and related functions
------------------------------------------
cB_Filters.fNewItems = function(item)
	if not cBnivCfg.NewItems then return false end
	if not ((item.bagID >= 0) and (item.bagID <= NumBagContainer)) then return false end
	if not item.link then return false end
	if not cB_KnownItems[item.id] then return true end
	local t = GetItemCount(item.id)	--cbNivaya:getItemCount(item.id)
	return (t > cB_KnownItems[item.id]) and true or false
end

-----------------------------------------
-- Item Set filter and related functions
-----------------------------------------
local item2setIR = {} -- ItemRack
local item2setOF = {} -- Outfitter
local IR = IsAddOnLoaded('ItemRack')
local OF = IsAddOnLoaded('Outfitter')
local OFisInitialized = false

cB_Filters.fItemSets = function(item)
	--print("fItemSets", item, item.isInSet)
	if not cB_filterEnabled["ItemSets"] then return false end
	if not item.link then return false end
	local tC = cBniv_CatInfo[item.name]
	if tC then return (tC == "ItemSets") and true or false end
	-- Check ItemRack sets:
	if IR then
		if item2setIR[ItemRack.GetIRString(item.link)] then return true end
	end
	-- Check Outfitter sets:
	if OF then
		--local _,_,itemStr = string.find(item.link, "^|c%x+|H(.+)|h%[.*%]")
		--if item2setOF[itemStr] then return true end
		--if item2setOF[item.link] then return true end
		if OFisInitialized then
			if Outfitter:GetOutfitsUsingItem(Outfitter_GetItemInfoFromLink(item.link)) then return true end
		end
	end
	-- Check Equipment Manager sets:
	if isRetail then
		if cargBags.itemKeys["setID"](item) then return true end
	end
   return false
end

-- ItemRack related
local function cacheSetsIR()
	for k in pairs(item2setIR) do item2setIR[k] = nil end
	local IRsets = ItemRackUser.Sets
	for i in next, IRsets do
		if not string.find(i, "^~") then 
			for _,item in pairs(IRsets[i].equip) do
				if item then item2setIR[item] = true end
			end
		end
	end
	cbNivaya:UpdateBags()
end

if IR then
	local hooked = false
	
	cacheSetsIR()
	
	local function ItemRackOpt_CreateHooks()
		if hooked then return end
		
		--local IRsaveSet = ItemRackOpt.SaveSet
		--function ItemRackOpt.SaveSet(...) IRsaveSet(...); cacheSetsIR() end
		--local IRdeleteSet = ItemRackOpt.DeleteSet
		--function ItemRackOpt.DeleteSet(...) IRdeleteSet(...); cacheSetsIR() end
		
		hooksecurefunc(ItemRackOpt, "SaveSet", cacheSetsIR)
		hooksecurefunc(ItemRackOpt, "DeleteSet", cacheSetsIR)
		
		hooked = true
	end
	
	--local IRtoggleOpts = ItemRack.ToggleOptions
	--function ItemRack.ToggleOptions(...) IRtoggleOpts(...) ItemRackOpt_CreateHooks() end
	hooksecurefunc(ItemRack, "ToggleOptions", ItemRackOpt_CreateHooks)
end

-- Outfitter related
local pLevel = UnitLevel("player")
local function createItemString(i) return string.format("item:%d:%d:%d:%d:%d:%d:%d:%d:%d", i.Code, i.EnchantCode or 0, i.JewelCode1 or 0, i.JewelCode2 or 0, i.JewelCode3 or 0, i.JewelCode4 or 0, i.SubCode or 0, i.UniqueID or 0, pLevel) end

local function cacheSetsOF()
	--[[
	for k in pairs(item2setOF) do item2setOF[k] = nil end
	for _,id in ipairs(Outfitter_GetCategoryOrder()) do
		local OFsets = Outfitter_GetOutfitsByCategoryID(id)
		for _,vSet in pairs(OFsets) do
			for _,item in pairs(vSet.Items) do
				if item then
					--item2setOF[createItemString(item)] = true
					if item.Link then
						item2setOF[item.Link] = true
					end
				end
			end
		end
	end
	]]
	cbNivaya:UpdateBags()
end

local function checkOFinit()
	OFisInitialized = Outfitter:IsInitialized()
end

if OF then
	Outfitter_RegisterOutfitEvent("ADD_OUTFIT", cacheSetsOF)
	Outfitter_RegisterOutfitEvent("DELETE_OUTFIT", cacheSetsOF)
	Outfitter_RegisterOutfitEvent("EDIT_OUTFIT", cacheSetsOF)
	if Outfitter:IsInitialized() then
		checkOFinit()
		cacheSetsOF()
	else
		Outfitter_RegisterOutfitEvent('OUTFITTER_INIT', function() checkOFinit() cacheSetsOF() end)
	end
end
