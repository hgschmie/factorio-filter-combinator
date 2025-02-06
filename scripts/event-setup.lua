--------------------------------------------------------------------------------
-- event setup for the mod
--------------------------------------------------------------------------------
assert(script)

local Event = require('stdlib.event.event')
local Is = require('stdlib.utils.is')
local Player = require('stdlib.event.player')

local Matchers = require('framework.matchers')
local tools = require('framework.tools')

local const = require('lib.constants')

--------------------------------------------------------------------------------
-- entity create / delete
--------------------------------------------------------------------------------

---@param event EventData.on_built_entity | EventData.on_robot_built_entity | EventData.script_raised_revive | EventData.script_raised_built
local function onEntityCreated(event)
    local entity = event and event.entity

    local tags = event.tags

    local entity_ghost = Framework.ghost_manager:findGhostForEntity(entity)
    if entity_ghost then
        Framework.ghost_manager:deleteGhost(entity.unit_number)
        tags = tags or entity_ghost.tags
    end

    local config = tags and tags[const.config_tag_name]

    -- register entity for destruction
    script.register_on_object_destroyed(entity)

    This.fico:create(entity, config)
end

---@param event EventData.on_player_mined_entity | EventData.on_robot_mined_entity | EventData.on_entity_died | EventData.script_raised_destroy
local function onEntityDeleted(event)
    local entity = event.entity
    if not (entity and entity.valid) then return end
    assert(entity.unit_number)

    This.fico:destroy(entity.unit_number)
    Framework.gui_manager:destroy_gui_by_entity_id(entity.unit_number)
end

--------------------------------------------------------------------------------
-- Entity destruction
--------------------------------------------------------------------------------

---@param event EventData.on_object_destroyed
local function onObjectDestroyed(event)
    -- main entity destroyed
    This.fico:destroy(event.useful_id)
    Framework.gui_manager:destroy_gui_by_entity_id(event.useful_id)
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

    This.fico:create(event.destination, src_data.config)
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
-- Configuration changes (runtime and startup)
--------------------------------------------------------------------------------

---@param changed ConfigurationChangedData?
local function onConfigurationChanged(changed)
    This.fico:init()

    -- enable filter combinator if circuit network is researched.
    for _, force in pairs(game.forces) do
        if force.recipes[const.filter_combinator_name] and force.technologies['circuit-network'] then
            force.recipes[const.filter_combinator_name].enabled = force.technologies['circuit-network'].researched
        end
    end

    for _, fc_entity in pairs(This.fico:entities()) do
        if fc_entity.ref.signals then
            local control_behavior = fc_entity.ref.signals.get_or_create_control_behavior() --[[ @as LuaConstantCombinatorControlBehavior ]]
            if control_behavior then
                for i = 1, control_behavior.sections_count, 1 do
                    control_behavior.sections[i].group = ''
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Event ticker
--------------------------------------------------------------------------------

local function onNthTick()
    if This.fico:totalCount() <= 0 then return end

    for main_unit_number, fc_entity in pairs(This.fico:entities()) do
        if not (fc_entity.main and fc_entity.main.valid) then
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

local function register_events()
    local match_all_main_entities = Matchers:matchEventEntityName {
        const.filter_combinator_name,
        const.filter_combinator_name_packed,
    }

    local match_main_entity = Matchers:matchEventEntityName(const.filter_combinator_name)
    local match_internal_entities = Matchers:matchEventEntityName(const.internal_entity_names)

    -- manage ghost building (robot building)
    Framework.ghost_manager:registerForName(const.filter_combinator_name)

    -- entity create / delete
    Event.register(Matchers.CREATION_EVENTS, onEntityCreated, match_all_main_entities)
    Event.register(Matchers.DELETION_EVENTS, onEntityDeleted, match_all_main_entities)

    -- entity destroy
    Event.register(defines.events.on_object_destroyed, onObjectDestroyed)

    -- Entity cloning
    Event.register(defines.events.on_entity_cloned, onMainEntityCloned, match_main_entity)
    Event.register(defines.events.on_entity_cloned, onInternalEntityCloned, match_internal_entities)

    -- Entity settings pasting
    Event.register(defines.events.on_entity_settings_pasted, onEntitySettingsPasted, match_main_entity)

    -- Manage blueprint configuration setting
    Framework.blueprint:registerCallback(const.filter_combinator_name, This.fico.serialize_config)

    -- Manage tombstones
    Framework.tombstone:registerCallback(const.filter_combinator_name, {
        create_tombstone = This.fico.serialize_config,
        apply_tombstone = Framework.ghost_manager.mapTombstoneToGhostTags,
    })

    -- config change events
    -- Configuration changes (runtime and startup)
    Event.on_configuration_changed(onConfigurationChanged)
    Event.register(defines.events.on_runtime_mod_setting_changed, onConfigurationChanged)

    -- Event ticker
    Event.on_nth_tick(301, onNthTick)
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

-- mod init code
Event.on_init(on_init)
Event.on_load(on_load)
