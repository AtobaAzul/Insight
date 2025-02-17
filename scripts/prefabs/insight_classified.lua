--[[
Copyright (C) 2020, 2021 penguin0616

This file is part of Insight.

The source code of this program is shared under the RECEX
SHARED SOURCE LICENSE (version 1.0).
The source code is shared for referrence and academic purposes
with the hope that people can read and learn from it. This is not
Free and Open Source software, and code is not redistributable
without permission of the author. Read the RECEX SHARED
SOURCE LICENSE for details
The source codes does not come with any warranty including
the implied warranty of merchandise.
You should have received a copy of the RECEX SHARED SOURCE
LICENSE in the form of a LICENSE file in the root of the source
directory. If not, please refer to
<https://raw.githubusercontent.com/Recex/Licenses/master/SharedSourceLicense/LICENSE.txt>
]]

-- Init
setfenv(1, _G.Insight.env)
--local CLASSIFIED_NAME = "insight_classified" or debug.getinfo(1, "S"):match("([%w_]+)%.lua$")

--------------------------------------------------------------------------
--[[ Stuff ]]
--------------------------------------------------------------------------
local function OnWorldDataDirty(inst)
	local str = inst.net_world_data:value()
	if str == "" then return end 
	local data = json.decode(str)

	inst._parent.replica.insight.world_data = data
end

local function OnNaughtinessDirty(inst)
	local str = inst.net_naughtiness:value()
	--dprintf("%s:insight_classified -> OnNaughtinessDirty", str)

	if str == "" then return end
	local actions, threshold = str:match("(%d+)|(%d+)")

	if not actions or not threshold then
		mprint(actions, threshold)
		return error("Actions or threshold is missing?")
	end

	actions, threshold = tonumber(actions), tonumber(threshold)

	inst._parent.replica.insight:OnNaughtinessDirty({ actions = actions, threshold = threshold })
end

local function OnInvalidateDirty(inst)
	local ent = inst.net_invalidate:value()
	if ent then
		inst._parent.replica.insight:OnInvalidateCachedEntity(ent)
	end
end

local function OnHuntTargetDirty(inst)
	local target = inst.net_hunt_target:value()
	inst._parent.replica.insight:OnHuntTargetDirty(target)
end

local function OnHungerRateDirty(inst)
	local rate = inst.net_hunger_rate:value()
	inst._parent.replica.insight:OnHungerRateDirty(rate)
end

local function OnSanityRateDirty(inst)
	local rate = inst.net_sanity_rate:value()
	inst._parent.replica.insight:OnSanityRateDirty(rate)
end

local function OnMoistureRateDirty(inst)
	local rate = inst.net_moisture_rate:value()
	inst._parent.replica.insight:OnMoistureRateDirty(rate)
end

local function OnMoonCycleDirty(inst)
	local moon_cycle = inst.net_moon_cycle:value()
	TheWorld:PushEvent("moon_cycle_dirty", { moon_cycle = moon_cycle }) -- This is an event that gets listened to by Combined Status
end

--------------------------------------------------------------------------
--[[ Attachment related functions ]]
--------------------------------------------------------------------------
local function OnRemoveEntity(inst)
	if inst._parent ~= nil then
		inst._parent.insight_classified = nil
	end
end

local function OnEntityReplicated(inst)
	inst._parent = inst.entity:GetParent()

	if inst._parent == nil then
		mprint("Unable to initialize classified data for insight_classified, no parent")

	elseif inst._parent.replica.insight == nil then
		mprint("Unable to initialize classified data for insight_classified, no Insight")

	else
		inst._parent.insight_classified = inst
		inst._parent.replica.insight:AttachClassified(inst)
		inst.OnRemoveEntity = OnRemoveEntity
	end
end

local function RegisterNetListeners(inst)
	-- string
	inst:ListenForEvent("insight_world_data_dirty", OnWorldDataDirty) OnWorldDataDirty(inst)
	inst:ListenForEvent("insight_naughtiness_dirty", OnNaughtinessDirty) OnNaughtinessDirty(inst)

	-- entity
	inst:ListenForEvent("insight_invalidate_dirty", OnInvalidateDirty) OnInvalidateDirty(inst)
	inst:ListenForEvent("insight_hunt_target_dirty", OnHuntTargetDirty) OnHuntTargetDirty(inst)

	-- bool

	-- float
	inst:ListenForEvent("insight_hunger_rate_dirty", OnHungerRateDirty) OnHungerRateDirty(inst)
	inst:ListenForEvent("insight_sanity_rate_dirty", OnSanityRateDirty) OnSanityRateDirty(inst)
	inst:ListenForEvent("insight_moisture_rate_dirty", OnMoistureRateDirty) OnMoistureRateDirty(inst)
	
	-- smallbyte
	inst:ListenForEvent("insight_moon_cycle_dirty", OnMoonCycleDirty) OnMoonCycleDirty(inst)
end

--------------------------------------------------------------------------
--[[ Prefab ]]
--------------------------------------------------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform() -- follow parent sleep state?
	inst.entity:AddNetwork()
	inst.entity:Hide()
	inst:AddTag("CLASSIFIED")

	--[==========[ Netvars ]==========]
	-- net_string
	inst.net_world_data = net_string(inst.GUID, "insight_world_data", "insight_world_data_dirty")
	inst.net_naughtiness = net_string(inst.GUID, "insight_naughtiness", "insight_naughtiness_dirty")

	-- net_entity
	inst.net_invalidate = net_entity(inst.GUID, "insight_invalidate", "insight_invalidate_dirty")
	inst.net_hunt_target = net_entity(inst.GUID, "insight_hunt_target", "insight_hunt_target_dirty")

	-- net_bool

	-- net_float
	inst.net_hunger_rate = net_float(inst.GUID, "insight_hunger_rate", "insight_hunger_rate_dirty")
	inst.net_sanity_rate = net_float(inst.GUID, "insight_sanity_rate", "insight_sanity_rate_dirty")
	inst.net_moisture_rate = net_float(inst.GUID, "insight_moisture_rate", "insight_moisture_rate_dirty")
	
	-- net_smallbyte
	inst.net_moon_cycle = net_smallbyte(inst.GUID, "insight_moon_cycle", "insight_moon_cycle_dirty") -- "insight_net_moon_cycle" 3674213233

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		inst.OnEntityReplicated = OnEntityReplicated
		inst:DoTaskInTime(0, RegisterNetListeners)

		return inst
	end

	inst.persists = false

	return inst
end

return Prefab("insight_classified", fn)
