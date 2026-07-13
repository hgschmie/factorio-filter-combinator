--------------------------------------------------------------------------------
-- event setup for the mod
--------------------------------------------------------------------------------
assert(script)

local Event = require('stdlib.event.event')
local Position = require('stdlib.area.position')
local Player = require('stdlib.event.player')
local Ticker = require('framework.ticker')

local Matchers = require('framework.matchers')

local const = require('lib.constants')

--------------------------------------------------------------------------------
-- entity create / delete
--------------------------------------------------------------------------------

---@param event EventData.on_built_entity | EventData.on_robot_built_entity | EventData.on_space_platform_built_entity | EventData.script_raised_revive | EventData.script_raised_built
local function on_entity_created(event)
    local entity = event and event.entity
    if not (entity and entity.valid) then return end

    ---@type Tags?
    local tags = event.tags

    local config = nil

    -- see if a ghost (with tags) from a blueprint is replaced
    local entity_ghost = Framework.Ghost:findGhostForEntity(entity)
    if entity_ghost then
        tags = tags or entity_ghost.tags
    end

    if tags then
        config = This.fico.deserialize_config(tags)
    end

    This.fico:create(entity, config)
end

---@param event EventData.on_player_mined_entity | EventData.on_robot_mined_entity | EventData.on_space_platform_mined_entity | EventData.script_raised_destroy
local function on_entity_deleted(event)
    local entity = event and event.entity
    if not (entity and entity.valid) then return end
    assert(entity.unit_number)

    if This.fico:destroy(entity.unit_number) then
        Framework.gui_manager:destroyGuiByEntityId(entity.unit_number)
    end
end

---@param event EventData.on_post_entity_died
local function on_post_entity_died(event)
    if not (event.unit_number) then return end

    if This.fico:destroy(event.unit_number) then
        Framework.gui_manager:destroyGuiByEntityId(event.unit_number)
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

    if event.source.force ~= event.destination.force then return end

    local src_fc_entity = This.fico:entity(event.source.unit_number)
    local dst_fc_entity = This.fico:entity(event.destination.unit_number)

    if not (src_fc_entity and dst_fc_entity) then return end

    This.fico:reconfigure(dst_fc_entity, src_fc_entity.config)
end

--------------------------------------------------------------------------------
-- Configuration changes (startup)
--------------------------------------------------------------------------------

local function on_configuration_changed()
    This:init()

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

local TICK_INTERVAL = 10

---@param context ff2.ticker.TickerContext
---@param values ff2.ticker.TickerContext
local function ticker_unit_of_work(context, values)
    local fc_index = context.index
    local fc_entity = values.index

    if fc_entity.main and fc_entity.main.valid then
        This.fico:tick(fc_entity)
    elseif This.fico:destroy(fc_index) then
        Framework.gui_manager:destroyGuiByEntityId(fc_index)
    end
end

local function on_tick()
    local ticker_info = Ticker.getTicker(const.filter_combinator_name)

    local fc_storage = This:storage()
    if fc_storage.count == 0 then return end

    local entities_per_tick = math.max(1, math.ceil(fc_storage.count / TICK_INTERVAL)) -- at least one

    local context = ticker_info.context or {}

    local iterator = Ticker.createWorkIterator {
        context = context,
        field_name = 'index',
        iterable = fc_storage.fc,
    }

    while entities_per_tick > 0 do
        iterator.process(ticker_unit_of_work)

        entities_per_tick = entities_per_tick - 1
    end

    ticker_info.context = context
    ticker_info.last_tick = game.tick
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
    -- register post_died to deal with dead entities
    Event.register(defines.events.on_post_entity_died, on_post_entity_died)

    -- manage ghost building (robot building)
    Framework.Ghost:registerForName {
        names = const.filter_combinator_name
    }

    -- Configuration changes (startup)
    Event.on_configuration_changed(on_configuration_changed)

    -- manage blueprinting and copy/paste
    Framework.blueprint:registerCallbackForNames(const.filter_combinator_name, This.fico.serialize_config)

    -- manage tombstones for undo/redo and dead entities
    Framework.Tombstone:registerCallback(const.filter_combinator_name, {
        create_tombstone = This.fico.serialize_config,
        apply_tombstone = Framework.Ghost.mapTombstoneToGhostTags,
    })

    -- Entity cloning
    Event.register(defines.events.on_entity_cloned, on_entity_cloned, match_main_entity)
    Event.register(defines.events.on_entity_cloned, on_internal_entity_cloned, match_internal_entities)

    -- Entity settings pasting
    Event.register(defines.events.on_entity_settings_pasted, on_entity_settings_pasted, match_main_entity)

    -- Event ticker
    Event.on_nth_tick(1, on_tick)
end

--------------------------------------------------------------------------------
-- mod init/load code
--------------------------------------------------------------------------------

local function on_init()
    This:init()

    register_events()
end

local function on_load()
    register_events()
end

-- setup player management
Player.register_events(true)

Event.on_init(on_init)
Event.on_load(on_load)
