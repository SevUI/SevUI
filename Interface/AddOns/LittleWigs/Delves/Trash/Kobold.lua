--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Kobold Delve Trash", {2681, 2683}) -- Kriegval's Rest, The Waterworks
if not mod then return end
mod:RegisterEnableMob(
	213447, -- Kuvkel (Kriegval's Rest gossip NPC)
	213775, -- Dagran Thaurissan II (Kriegval's Rest gossip NPC)
	214143, -- Foreman Bruknar (The Waterworks gossip NPC)
	214290, -- Pagsly (The Waterworks gossip NPC)
	204127, -- Kobold Taskfinder
	225568, -- Kobold Guardian
	213577, -- Spitfire Charger
	211777 -- Spitfire Fusetender
)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:GetLocale()
if L then
	L.kobold_trash = "Kobold Trash"

	L.kobold_taskfinder = "Kobold Taskfinder"
	L.spitfire_charger = "Spitfire Charger"
	L.spitfire_fusetender = "Spitfire Fusetender"
end

--------------------------------------------------------------------------------
-- Initialization
--

function mod:OnRegister()
	self.displayName = L.kobold_trash
end

local autotalk = mod:AddAutoTalkOption(true)
function mod:GetOptions()
	return {
		autotalk,
		-- Kobold Taskfinder / Kobold Guardian
		449071, -- Blazing Wick
		448399, -- Battle Cry
		-- Spitfire Charger
		445210, -- Fire Charge
		-- Spitfire Fusetender
		448528, -- Throw Dynamite
	}, {
		[449071] = L.kobold_taskfinder,
		[445210] = L.spitfire_charger,
		[448528] = L.spitfire_fusetender,
	}
end

function mod:OnBossEnable()
	-- Autotalk
	self:RegisterEvent("GOSSIP_SHOW")

	-- Kobold Taskfinder / Kobold Guardian
	self:Log("SPELL_CAST_START", "BlazingWick", 449071)
	self:Log("SPELL_CAST_START", "BattleCry", 448399)

	-- Spitfire Charger
	self:Log("SPELL_CAST_START", "FireCharge", 445210)

	-- Spitfire Fusetender
	self:Log("SPELL_CAST_SUCCESS", "ThrowDynamite", 448528)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

-- Autotalk

function mod:GOSSIP_SHOW()
	local info = self:GetWidgetInfo("delve", 6183)
	local level = info and tonumber(info.tierText)
	if (not level or level > 3) and self:GetOption(autotalk) then
		if self:GetGossipID(119802) then -- Kriegval's Rest, start Delve (Kuvkel)
			-- 119802:I'll get your valuables back from the kobolds.
			self:SelectGossipID(119802)
		elseif self:GetGossipID(119930) then -- Kriegval's Rest, start Delve (Dagran Thaurissan II)
			-- 119930:|cFF0000FF(Delve)|r <Interrupt Dagran> Let's get going Dagran. We'll collect some wax.
			self:SelectGossipID(119930)
		elseif self:GetGossipID(120018) then -- The Waterworks, start Delve (Foreman Bruknar)
			-- 120018:|cFF0000FF(Delve)|r I'll rescue the rest of your workers from the kobolds.
			self:SelectGossipID(120018)
		elseif self:GetGossipID(120096) then
			-- 120096:|cFF0000FF(Delve)|r I'll take the stomping shoes and use them to get your stolen goods back.
			self:SelectGossipID(120096)
		elseif self:GetGossipID(120081) then -- The Waterworks, start Delve (Pagsly)
			-- 120081:|cFF0000FF(Delve)|r I'll help you recover the earthen treasures.
			self:SelectGossipID(120081)
		elseif self:GetGossipID(120082) then -- The Waterworks, continue Delve (Pagsly)
			-- 120082:|cFF0000FF(Delve)|r I'll fend off any kobolds while you get the treasures.
			self:SelectGossipID(120082)
		end
	end
end

-- Kobold Taskfinder

function mod:BlazingWick(args)
	self:Message(args.spellId, "orange")
	self:PlaySound(args.spellId, "alarm")
end

function mod:BattleCry(args)
	self:Message(args.spellId, "red", CL.casting:format(args.spellName))
	self:PlaySound(args.spellId, "alert")
end

-- Spitfire Charger

function mod:FireCharge(args)
	self:Message(args.spellId, "red")
	self:PlaySound(args.spellId, "alarm")
end

-- Spitfire Fusetender

function mod:ThrowDynamite(args)
	self:Message(args.spellId, "orange")
	self:PlaySound(args.spellId, "alarm")
end
