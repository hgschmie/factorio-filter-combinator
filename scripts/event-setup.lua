--------------------------------------------------------------------------------
-- event setup for the mod
--------------------------------------------------------------------------------

local Event = require('__stdlib__/stdlib/event/event')
local Is = require('__stdlib__/stdlib/utils/is')
local Player = require('__stdlib__/stdlib/event/player')
local table = require('__stdlib__/stdlib/utils/table')

local Util = require('framework.util')

local const = require('lib.constants')

--------------------------------------------------------------------------------
-- manage ghost building (robot building)
--------------------------------------------------------------------------------

local function onGhostEntityCreated(event)
    local entity = event and (event.created_entity or event.entity)
    script.register_on_entity_destroyed(entity)

    -- if an entity ghost was placed, register information to configure
    -- an entity if it is placed over the ghost
    ---@type table<integer, ModGhost>
    local ghosts = global.ghosts or {}

    ---@class ModGhost
    ---@field position MapPosition
    ---@field orientation RealOrientation
    ---@field tags Tags?
    ---@field player_index integer
    ghosts[entity.unit_number] = {
        position = entity.position,
        orientation = entity.orientation,
        tags = entity.tags,
        player_index = event.player_index
    }

    global.ghosts = ghosts
end

--------------------------------------------------------------------------------
-- entity create / delete
--------------------------------------------------------------------------------

--- @param event EventData.on_built_entity | EventData.on_robot_built_entity | EventData.script_raised_revive
local function onEntityCreated(event)
    local entity = event and (event.created_entity or event.entity)

    local player_index = event.player_index
    local tags = event.tags

    -- see if this entity replaces a ghost
    if global.ghosts then
        for _, ghost in pairs(global.ghosts) do
            if entity.position.x == ghost.position.x
                and entity.position.y == ghost.position.y
                and entity.orientation == ghost.orientation then
                player_index = player_index or ghost.player_index
                tags = tags or ghost.tags
                break
            end
        end
    end

    -- register entity for destruction
    script.register_on_entity_destroyed(entity)

    This.fico:create(entity, player_index, tags)
end

local function onEntityDeleted(event)
    local entity = event and (event.created_entity or event.entity)

    This.fico:destroy(entity.unit_number)
end

--------------------------------------------------------------------------------
-- Entity destruction
--------------------------------------------------------------------------------

local function onEntityDestroyed(event)
    -- is it a ghost?
    if global.ghosts and global.ghosts[event.unit_number] then
        global.ghosts[event.unit_number] = nil
        return
    end

    -- or a main entity?
    local fc_entity = This.fico:entity(event.unit_number)
    if not fc_entity then return end

    -- main entity destroyed
    This.fico:destroy(event.unit_number)
end

--------------------------------------------------------------------------------
-- Entity cloning
--------------------------------------------------------------------------------

--- @param event EventData.on_entity_cloned
local function onMainEntityCloned(event)
    -- Space Exploration Support
    if not (Is.Valid(event.source) and Is.Valid(event.destination)) then return end

    local src_data = This.fico:entity(event.source.unit_number)
    if not src_data then return end

    local tags = { fc_config = src_data.config } -- clone the config from the src to the destination

    This.fico:create(event.destination, nil, tags)
end

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

local function onEntitySettingsPasted(event)
    local player = Player.get(event.player_index)

    if not (Is.Valid(player) and player.force == event.source.force and player.force == event.destination.force) then return end

    local src_fc_entity = This.fico:entity(event.source.unit_number)
    local dst_fc_entity = This.fico:entity(event.destination.unit_number)

    if not (src_fc_entity and dst_fc_entity) then return end

    dst_fc_entity.config = table.deepcopy(src_fc_entity.config)
    This.fico:reconfigure(dst_fc_entity)
end

--------------------------------------------------------------------------------
-- Blueprint / copy&paste management
--------------------------------------------------------------------------------

--- @param blueprint LuaItemStack
--- @param entities LuaEntity[]
local function save_to_blueprint(entities, blueprint)
    if not entities or #entities < 1 then return end
    if not (blueprint and blueprint.is_blueprint_setup()) then return end

    -- blueprints hold a set of entities without any identifying information besides
    -- the position of the entity. Build a double-index map that allows finding the
    -- index in the blueprint entity list by x/y coordinate.
    local blueprint_index = {}
    for idx, blueprint_entity in pairs(blueprint.get_blueprint_entities()) do
        local x_map = blueprint_index[blueprint_entity.position.x] or {}
        assert(not (x_map[blueprint_entity.position.y]))
        x_map[blueprint_entity.position.y] = idx
        blueprint_index[blueprint_entity.position.x] = x_map
    end

    -- all entities here are filter combinators. Find their index in the blueprint
    -- and assign the config as a tag.
    for _, main in pairs(entities) do
        if Is.Valid(main) then
            local fc_entity = This.fico:entity(main.unit_number)
            if fc_entity then
                local idx = (blueprint_index[main.position.x] or {})[main.position.y]
                if idx then
                    blueprint.set_blueprint_entity_tag(idx, 'fc_config', fc_entity.config)
                end
            end
        end
    end
end

local function has_valid_cursor_stack(player)
    if not Is.Valid(player) then return false end
    if not player.cursor_stack then return false end

    return (player.cursor_stack.valid_for_read and player.cursor_stack.name == 'blueprint')
end


--- @param event EventData.on_player_setup_blueprint
local function onPlayerSetupBlueprint(event)
    if not event.area then return end

    local player, player_data = Player.get(event.player_index)

    local entities = player.surface.find_entities_filtered {
        area = event.area,
        force = player.force,
        name = const.filter_combinator_name,
    }
    -- nothing in there for us
    if #entities < 1 then return end

    if has_valid_cursor_stack(player) then
        save_to_blueprint(entities, player.cursor_stack)
    else
        -- Player is editing the blueprint, no access for us yet.
        -- onPlayerConfiguredBlueprint picks this up and stores it.
        player_data.fc_blueprint_data = entities
    end
end

--- @param event EventData.on_player_configured_blueprint
local function onPlayerConfiguredBlueprint(event)
    local player, player_data = Player.get(event.player_index)

    if player_data.fc_blueprint_data then
        if has_valid_cursor_stack(player) and player_data.fc_blueprint_data then
            save_to_blueprint(player_data.fc_blueprint_data, player.cursor_stack)
        end
        player_data.fc_blueprint_data = nil
    end
end

--------------------------------------------------------------------------------
-- Configuration changes (runtime and startup)
--------------------------------------------------------------------------------

--- @param changed ConfigurationChangedData?
local function onConfigurationChanged(changed)
    if This and This.fico then
        This.fico:clearAllSignals()

        local all_signals = This.fico:getAllSignals()

        for _, fc_entity in pairs(This.fico:entities()) do
            fc_entity.ref.ex.get_or_create_control_behavior().parameters = all_signals
        end
    end
end

--------------------------------------------------------------------------------
-- Event ticker
--------------------------------------------------------------------------------

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

local match_main_entities = Util.create_event_entity_matcher('name', const.main_entity_names)
local match_internal_entities = Util.create_event_entity_matcher('name', const.internal_entity_names)
local match_ghost_entities = Util.create_event_ghost_entity_matcher(const.main_entity_names)

-- mod init code
Event.on_init(function() This.fico:init() end)

-- manage ghost building (robot building)
Util.event_register(const.creation_events, onGhostEntityCreated, match_ghost_entities)

-- entity create / delete
Util.event_register(const.creation_events, onEntityCreated, match_main_entities)
Util.event_register(const.deletion_events, onEntityDeleted, match_main_entities)

-- entity destroy
Event.register(defines.events.on_entity_destroyed, onEntityDestroyed)

-- Entity cloning
Event.register(defines.events.on_entity_cloned, onMainEntityCloned, match_main_entities)
Event.register(defines.events.on_entity_cloned, onInternalEntityCloned, match_internal_entities)

-- Entity settings pasting
Event.register(defines.events.on_entity_settings_pasted, onEntitySettingsPasted, match_main_entities)

-- Blueprint / copy&paste management
Event.register(defines.events.on_player_setup_blueprint, onPlayerSetupBlueprint)
Event.register(defines.events.on_player_configured_blueprint, onPlayerConfiguredBlueprint)

-- Configuration changes (runtime and startup)
Event.on_configuration_changed(onConfigurationChanged)
Event.register(defines.events.on_runtime_mod_setting_changed, onConfigurationChanged)

-- Event ticker
Event.on_nth_tick(301, onNthTick)
