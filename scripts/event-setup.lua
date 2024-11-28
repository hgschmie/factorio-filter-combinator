--------------------------------------------------------------------------------
-- event setup for the mod
--------------------------------------------------------------------------------

local Event = require('stdlib.event.event')
local Is = require('stdlib.utils.is')
local Player = require('stdlib.event.player')

local tools = require('framework.tools')

local const = require('lib.constants')

--------------------------------------------------------------------------------
-- entity create / delete
--------------------------------------------------------------------------------

---@param event EventData.on_built_entity | EventData.on_robot_built_entity | EventData.script_raised_revive | EventData.script_raised_built
local function onEntityCreated(event)
    local entity = event and event.entity

    local player_index = event.player_index
    local tags = event.tags

    local entity_ghost = Framework.ghost_manager:findMatchingGhost(entity)
    if entity_ghost then
        player_index = player_index or entity_ghost.player_index
        tags = tags or entity_ghost.tags
    end

    -- register entity for destruction
    script.register_on_object_destroyed(entity)

    This.fico:create(entity, player_index, tags)
end

---@param event EventData.on_player_mined_entity | EventData.on_robot_mined_entity | EventData.on_entity_died | EventData.script_raised_destroy
local function onEntityDeleted(event)
    local entity = event and event.entity

    This.fico:destroy(entity.unit_number)
end

--------------------------------------------------------------------------------
-- Entity destruction
--------------------------------------------------------------------------------

---@param event EventData.on_object_destroyed
local function onObjectDestroyed(event)
    -- is it a ghost?
    if storage.ghosts and storage.ghosts[event.useful_id] then
        storage.ghosts[event.useful_id] = nil
        return
    end

    -- or a main entity?
    local fc_entity = This.fico:entity(event.useful_id)
    if not fc_entity then return end

    -- main entity destroyed
    This.fico:destroy(event.useful_id)
end

--------------------------------------------------------------------------------
-- Entity cloning
--------------------------------------------------------------------------------

---@param event EventData.on_entity_cloned
local function onMainEntityCloned(event)
    -- Space Exploration Support
    if not (Is.Valid(event.source) and Is.Valid(event.destination)) then return end

    local src_data = This.fico:entity(event.source.unit_number)
    if not src_data then return end

    local tags = { fc_config = src_data.config } -- clone the config from the src to the destination

    This.fico:create(event.destination, nil, tags)
end

---@param event EventData.on_entity_cloned
local function onInternalEntityCloned(event)
    -- Space Exploration Support
    if not (Is.Valid(event.source) and Is.Valid(event.destination)) then return end

    -- delete the destination entity, it is not needed as the internal structure of the
    -- filter combinator is recreated when the main entity is cloned
    event.destination.destroy()
end

--------------------------------------------------------------------------------
-- Entity settings pasting
--------------------------------------------------------------------------------

---@param event EventData.on_entity_settings_pasted
local function onEntitySettingsPasted(event)
    local player = Player.get(event.player_index)

    if not (Is.Valid(player) and player.force == event.source.force and player.force == event.destination.force) then return end

    local src_fc_entity = This.fico:entity(event.source.unit_number)
    local dst_fc_entity = This.fico:entity(event.destination.unit_number)

    if not (src_fc_entity and dst_fc_entity) then return end

    dst_fc_entity.config = tools.copy(src_fc_entity.config)
    This.fico:reconfigure(dst_fc_entity)
end

--------------------------------------------------------------------------------
-- Event ticker
--------------------------------------------------------------------------------

---@param event NthTickEventData
local function onNthTick(event)
    if This.fico:totalCount() <= 0 then return end

    for main_unit_number, fc_entity in pairs(This.fico:entities()) do
        if not Is.Valid(fc_entity.main) then
            -- most likely cc has removed the main entity
            This.fico:destroy(main_unit_number)
        else
            This.fico:tick(fc_entity)
        end
    end
end

--------------------------------------------------------------------------------
-- event registration
--------------------------------------------------------------------------------

local match_main_entities = tools.create_event_entity_matcher('name', const.main_entity_names)
local match_internal_entities = tools.create_event_entity_matcher('name', const.internal_entity_names)
local match_ghost_entities = tools.create_event_ghost_entity_name_matcher(const.main_entity_names)

-- mod init code
Event.on_init(function() This.fico:init() end)

-- manage ghost building (robot building)
Framework.ghost_manager:register_for_ghost_names(const.main_entity_names)

-- entity create / delete
tools.event_register(tools.CREATION_EVENTS, onEntityCreated, match_main_entities)
tools.event_register(tools.DELETION_EVENTS, onEntityDeleted, match_main_entities)

-- entity destroy
Event.register(defines.events.on_object_destroyed, onObjectDestroyed)

-- Entity cloning
Event.register(defines.events.on_entity_cloned, onMainEntityCloned, match_main_entities)
Event.register(defines.events.on_entity_cloned, onInternalEntityCloned, match_internal_entities)

-- Entity settings pasting
Event.register(defines.events.on_entity_settings_pasted, onEntitySettingsPasted, match_main_entities)

-- Manage blueprint configuration setting
Framework.blueprint:register_callback(const.filter_combinator_name, This.fico.blueprint_callback)

-- Event ticker
Event.on_nth_tick(301, onNthTick)
