--------------------------------------------------------------------------------
-- event setup for the mod
--------------------------------------------------------------------------------
assert(script)

local Event = require('stdlib.event.event')
local Position = require('stdlib.area.position')
local Player = require('stdlib.event.player')

local Matchers = require('framework.matchers')

local const = require('lib.constants')

local TICK_INTERVAL = 10

--------------------------------------------------------------------------------
-- entity create / delete
--------------------------------------------------------------------------------

---@param event EventData.on_built_entity | EventData.on_robot_built_entity | EventData.on_space_platform_built_entity | EventData.script_raised_revive | EventData.script_raised_built
local function on_entity_created(event)
    local entity = event and event.entity
    if not (entity and entity.valid) then return end

    local tags = event.tags

    local entity_ghost = Framework.ghost_manager:findGhostForEntity(entity)
    if entity_ghost then
        tags = tags or entity_ghost.tags
    end

    local config = tags and tags[const.config_tag_name] --[[@as FilterCombinatorConfig ]]

    This.fico:create(entity, config)
end

---@param event EventData.on_player_mined_entity | EventData.on_robot_mined_entity | EventData.on_space_platform_mined_entity | EventData.script_raised_destroy
local function on_entity_deleted(event)
    local entity = event and event.entity
    if not (entity and entity.valid) then return end
    assert(entity.unit_number)

    if This.fico:destroy(entity.unit_number) then
        Framework.gui_manager:destroy_gui_by_entity_id(entity.unit_number)
        storage.last_tick_entity = nil
    end
end

--------------------------------------------------------------------------------
-- Entity destruction
--------------------------------------------------------------------------------

---@param event EventData.on_object_destroyed
local function on_object_destroyed(event)
    -- main entity destroyed
    if This.fico:destroy(event.useful_id) then
        storage.last_tick_entity = nil
        Framework.gui_manager:destroy_gui_by_entity_id(event.useful_id)
    end
end

--------------------------------------------------------------------------------
-- Entity cloning
--------------------------------------------------------------------------------

---@param event EventData.on_entity_cloned
local function on_entity_cloned(event)
    if not (event and event.source and event.source.valid and event.destination and event.destination.valid) then return end

    local src_data = This.fico:entity(event.source.unit_number)
    if not src_data then return end

    for _, cloned_entity in pairs(event.destination.surface.find_entities_filtered {
        area = Position(event.destination.position):expand_to_area(0.5),
        name = const.internal_entity_names,
    }) do
        cloned_entity.destroy()
    end

    This.fico:create(event.destination, src_data.config)
end

---@param event EventData.on_entity_cloned
local function on_internal_entity_cloned(event)
    if not (event.source and event.source.valid and event.destination and event.destination.valid) then return end

    -- delete the destination entity, it is not needed as the internal structure of the
    -- filter combinator is recreated when the main entity is cloned
    event.destination.destroy()
end

--------------------------------------------------------------------------------
-- Entity settings pasting
--------------------------------------------------------------------------------

---@param event EventData.on_entity_settings_pasted
local function on_entity_settings_pasted(event)
    if not (event and event.source and event.source.valid and event.destination and event.destination.valid) then return end

    local player = Player.get(event.player_index)
    if not (player and player.valid and player.force == event.source.force and player.force == event.destination.force) then return end

    local src_fc_entity = This.fico:entity(event.source.unit_number)
    local dst_fc_entity = This.fico:entity(event.destination.unit_number)

    if not (src_fc_entity and dst_fc_entity) then return end

    This.fico:reconfigure(dst_fc_entity, src_fc_entity.config)
end

--------------------------------------------------------------------------------
-- Configuration changes (startup)
--------------------------------------------------------------------------------

local function on_configuration_changed()
    This.fico:init()

    -- enable filter combinator if circuit network is researched.
    for _, force in pairs(game.forces) do
        if force.recipes[const.filter_combinator_name] and force.technologies['circuit-network'] then
            force.recipes[const.filter_combinator_name].enabled = force.technologies['circuit-network'].researched
        end
    end
end

--------------------------------------------------------------------------------
-- Event ticker
--------------------------------------------------------------------------------

local function onNthTick()
    local interval = TICK_INTERVAL -- fraction of the ficos to update
    local entities = This.fico:entities()
    local process_count = math.ceil(table_size(entities) / interval)
    local index = storage.last_tick_entity

    if process_count > 0 then
        local fc_entity
        repeat
            index, fc_entity = next(entities, index)
            if fc_entity then
                if fc_entity.main and fc_entity.main.valid then
                    This.fico:tick(fc_entity)
                    process_count = process_count - 1
                else
                    This.fico:destroy(index)
                end
            end
        until process_count == 0 or not index
    else
        index = nil
    end

    storage.last_tick_entity = index
end

--------------------------------------------------------------------------------
-- event registration and management
--------------------------------------------------------------------------------

local function register_events()
    local match_all_main_entities = Matchers:matchEventEntityName {
        const.filter_combinator_name,
        const.filter_combinator_name_packed,
    }

    local match_main_entity = Matchers:matchEventEntityName(const.filter_combinator_name)
    local match_internal_entities = Matchers:matchEventEntityName(const.internal_entity_names)

    -- entity create / delete
    Event.register(Matchers.CREATION_EVENTS, on_entity_created, match_all_main_entities)
    Event.register(Matchers.DELETION_EVENTS, on_entity_deleted, match_all_main_entities)

    -- manage ghost building (robot building)
    Framework.ghost_manager:registerForName(const.filter_combinator_name)

    -- entity destroy (can't filter on that)
    Event.register(defines.events.on_object_destroyed, on_object_destroyed)

    -- Configuration changes (startup)
    Event.on_configuration_changed(on_configuration_changed)

    -- manage blueprinting and copy/paste
    Framework.blueprint:registerCallback(const.filter_combinator_name, This.fico.serialize_config)

    -- manage tombstones for undo/redo and dead entities
    Framework.tombstone:registerCallback(const.filter_combinator_name, {
        create_tombstone = This.fico.serialize_config,
        apply_tombstone = Framework.ghost_manager.mapTombstoneToGhostTags,
    })

    -- Entity cloning
    Event.register(defines.events.on_entity_cloned, on_entity_cloned, match_main_entity)
    Event.register(defines.events.on_entity_cloned, on_internal_entity_cloned, match_internal_entities)

    -- Entity settings pasting
    Event.register(defines.events.on_entity_settings_pasted, on_entity_settings_pasted, match_main_entity)

    -- Event ticker
    Event.on_nth_tick(31, onNthTick)
end

--------------------------------------------------------------------------------
-- mod init/load code
--------------------------------------------------------------------------------

local function on_init()
    This.fico:init()
    register_events()
end

local function on_load()
    register_events()
end

-- setup player management
Player.register_events(true)

Event.on_init(on_init)
Event.on_load(on_load)
