------------------------------------------------------------------------
-- Filter combinator main code
------------------------------------------------------------------------
assert(script)

local Is = require('stdlib.utils.is')
local table = require('stdlib.utils.table')
local tools = require('framework.tools')

local const = require('lib.constants')

---@class FilterCombinator
local FiCo = {}

------------------------------------------------------------------------

---@class FilterCombinatorConfig
---@field enabled boolean
---@field status defines.entity_status?
---@field use_wire boolean
---@field filter_wire defines.wire_type
---@field include_mode boolean
---@field filters LogisticFilter[]
local default_config = {
    enabled = true,
    use_wire = false,
    filter_wire = defines.wire_type.green,
    include_mode = true,
    filters = {}
}

---@param parent_config FilterCombinatorConfig?
---@return FilterCombinatorConfig config
local function create_config(parent_config)
    parent_config = parent_config or default_config

    local config = {}
    -- iterate over all field names given in the default_config
    for field_name, _ in pairs(default_config) do
        if parent_config[field_name] ~= nil then
            config[field_name] = parent_config[field_name]
        else
            config[field_name] = default_config[field_name]
        end
    end

    return config
end

------------------------------------------------------------------------
-- init setup
------------------------------------------------------------------------

--- Setup the global fico data structure.
function FiCo:init()
    if storage.fc_data then return end

    storage.fc_data = {
        fc = {},
        count = 0,
        VERSION = const.current_version,
    }
end

------------------------------------------------------------------------
-- attribute getters/setters
------------------------------------------------------------------------

--- Returns the registered total count
---@return integer count The total count of filter combinators
function FiCo:totalCount()
    return storage.fc_data.count
end

--- Returns data for all filter combinators.
---@return FilterCombinatorData[] entities
function FiCo:entities()
    return storage.fc_data.fc
end

--- Returns data for a given filter combinator
---@param entity_id integer main unit number (== entity id)
---@return FilterCombinatorData? entity
function FiCo:entity(entity_id)
    return storage.fc_data.fc[entity_id]
end

--- Sets or clears a filter combinator entity
---@param entity_id integer The unit_number of the primary
---@param fc_entity FilterCombinatorData?
function FiCo:setEntity(entity_id, fc_entity)
    assert((fc_entity ~= nil and storage.fc_data.fc[entity_id] == nil)
        or (fc_entity == nil and storage.fc_data.fc[entity_id] ~= nil))

    if (fc_entity) then
        assert(Is.Valid(fc_entity.main) and fc_entity.main.unit_number == entity_id)
    end

    storage.fc_data.fc[entity_id] = fc_entity
    storage.fc_data.count = storage.fc_data.count + ((fc_entity and 1) or -1)

    if storage.fc_data.count < 0 then
        storage.fc_data.count = table_size(storage.fc_data.fc)
        Framework.logger:logf('Filter Combinator count got negative (bug), size is now: %d', storage.fc_data.count)
    end
end

------------------------------------------------------------------------
-- filter management
------------------------------------------------------------------------

---@param control LuaConstantCombinatorControlBehavior
---@param filters LogisticFilter[]
local function assign_filters(control, filters)
    for i = 1, control.sections_count, 1 do
        control.remove_section(i)
    end

    ---@type integer
    local idx = 0

    ---@type table<string, table<string, table<string, number>>>
    local cache = {}

    for i, filter in pairs(filters) do
        local signal = filter.value --[[@as SignalFilter]]
        local type = signal.type or 'item'
        cache[type] = cache[type] or {}
        cache[type][signal.name] = cache[type][signal.name] or {}

        local index = cache[type][signal.name][signal.quality]
        if not index then
            index = idx
            cache[type][signal.name][signal.quality] = index
            idx = idx + 1
            local section = control.sections[math.floor(index / 1000) + 1] or control.add_section()

            local pos = index % 1000 + 1
            section.set_slot(pos, filter)
        else
            local section = control.sections[math.floor(index / 1000) + 1]
            assert(section)

            local pos = index % 1000 + 1
            filter.min = filter.min + section.filters[pos].min
            section.set_slot(pos, filter)
        end
    end
end

------------------------------------------------------------------------
-- internal wiring management
------------------------------------------------------------------------

---@class FcWireConfig
---@field src string
---@field dst string?
---@field src_circuit string?
---@field dst_circuit string?
---@field wire string?

local invert_table = table.invert(defines.wire_type)

local function get_wire_name(circuit, wire)
    circuit = circuit and 'combinator_' .. circuit or 'circuit'

    local wire_name = circuit .. '_' .. wire
    return defines.wire_connector_id[wire_name]
end

---@param fc_entity FilterCombinatorData
---@param wire_cfg FcWireConfig
---@param wire_type table<string, defines.wire_type>?
local function connect_wire(fc_entity, wire_cfg, wire_type)
    wire_type = wire_type or defines.wire_type
    local wire = wire_type[wire_cfg.wire or 'red']
    local wire_name = invert_table[wire]

    local wire_origin = defines.wire_origin[fc_entity.comb_visible and 'player' or 'script']

    assert(fc_entity.ref[wire_cfg.src])
    assert(fc_entity.ref[wire_cfg.dst])

    local src_connector = fc_entity.ref[wire_cfg.src].get_wire_connector(get_wire_name(wire_cfg.src_circuit, wire_name), false)
    local dst_connector = fc_entity.ref[wire_cfg.dst].get_wire_connector(get_wire_name(wire_cfg.dst_circuit, wire_name), false)

    if src_connector and dst_connector then
        assert(src_connector.connect_to(dst_connector, false, wire_origin))
    end
end

---@param fc_entity FilterCombinatorData
---@param wire_cfg FcWireConfig
local function disconnect_wire(fc_entity, wire_cfg)
    local wire = defines.wire_type[wire_cfg.wire or 'red']
    local wire_name = invert_table[wire]

    local wire_origin = defines.wire_origin[fc_entity.comb_visible and 'player' or 'script']

    assert(fc_entity.ref[wire_cfg.src])

    if wire_cfg.dst then
        assert(fc_entity.ref[wire_cfg.dst])
    end

    local src_connector = wire_cfg.src and fc_entity.ref[wire_cfg.src].get_wire_connector(get_wire_name(wire_cfg.src_circuit, wire_name), false)
    assert(src_connector)

    local dst_connector = wire_cfg.dst and fc_entity.ref[wire_cfg.dst].get_wire_connector(get_wire_name(wire_cfg.dst_circuit, wire_name), false)

    if dst_connector then
        src_connector.disconnect_from(dst_connector, wire_origin)
    else
        src_connector.disconnect_all(wire_origin)
    end
end


-- Position grid for sub-entities if they are visible (for debugging)
--
--    -2/-4 (sig_shift) 0/-4        2/-4 (pos_proc)   4/-4 (neg_proc)
--    -2/-2 (sig_norm)  0/-2        2/-2 (pos_filter) 4/-2 (neg_filter)
--    -2/ 0 (signals)   0/ 0 (main) 2/ 0 (pos_split)  4/ 0 (neg_split)
--
local sub_entities = {
    { id = 'signals',    type = 'cc', x = 0,  y = 2, desc = 'GUI Settings' },

    { id = 'pos_split',  type = 'dc', x = 2,  y = 2, desc = 'Split out all positive data signals.' },
    { id = 'neg_split',  type = 'dc', x = 4,  y = 2, desc = 'Split out all negative data signals.' },

    { id = 'pos_filter', type = 'dc', x = 2,  y = 0, desc = 'Positive signal filter. Removes unwanted signals.' },
    { id = 'neg_filter', type = 'dc', x = 4,  y = 0, desc = 'Negative signal filter. Removes unwanted signals.' },

    { id = 'sig_norm',   type = 'dc', x = -2, y = 2, desc = 'Normalizes all signals to 0/1' },
    { id = 'sig_shift',  type = 'ac', x = -2, y = 0, desc = 'Shifts values to 0/2^31' },
}

local signal_each = { type = 'virtual', name = 'signal-each', quality = 'normal' }

---@class DcConfig
---@field src string
---@field first_signal string?
---@field comparator string
---@field second_constant number
---@field output_signal string?
---@field copy_count_from_input boolean?
---@field red_network boolean?
---@field green_network boolean?

---@type table<string, DcConfig[]>
local dc_config = {
    init = {
        { src = 'pos_split', comparator = '>',  second_constant = 0 },
        { src = 'neg_split', comparator = '<',  second_constant = 0 },
        { src = 'sig_norm',  comparator = '!=', second_constant = 0, copy_count_from_input = false, }
    },

    exclude = {
        { src = 'pos_filter', comparator = '>', second_constant = 0, green_network = false, },
        { src = 'neg_filter', comparator = '<', second_constant = 0, green_network = false, },
    },

    include = {
        { src = 'pos_filter', comparator = '<', second_constant = 0, green_network = false, },
        { src = 'neg_filter', comparator = '>', second_constant = 0, green_network = false, },
    },
}
---@class AcConfig
---@field src string
---@field first_signal string?
---@field operation string
---@field second_constant number
---@field output_signal string?

---@type table<string, AcConfig[]>

local ac_config = {
    init = {
        { src = 'sig_shift', operation = '<<', second_constant = 31, }
    }
}

---@type table<string, FcWireConfig[]>
local wiring = {
    -- the base wiring that needs to be done when the fc is created
    init = {
        -- all data path connections use red wires
        -- positive signal path
        { src = 'pos_split', dst = 'pos_filter', src_circuit = 'output', dst_circuit = 'input', wire = 'red' },
        -- negative signal path
        { src = 'neg_split', dst = 'neg_filter', src_circuit = 'output', dst_circuit = 'input', wire = 'red' },

        -- all signal path connection use green wires
        { src = 'sig_norm',  dst = 'sig_shift',  src_circuit = 'output', dst_circuit = 'input', wire = 'green', },
        { src = 'sig_shift', dst = 'pos_filter', src_circuit = 'output', dst_circuit = 'input', wire = 'green', },
        { src = 'sig_shift', dst = 'neg_filter', src_circuit = 'output', dst_circuit = 'input', wire = 'green', },
    },

    -- enable the FC - wire the processors to the main entity output pins
    enable = {
        { src = 'pos_filter', src_circuit = 'output', dst = 'main', dst_circuit = 'output', wire = 'red', },
        { src = 'pos_filter', src_circuit = 'output', dst = 'main', dst_circuit = 'output', wire = 'green', },
        { src = 'neg_filter', src_circuit = 'output', dst = 'main', dst_circuit = 'output', wire = 'red', },
        { src = 'neg_filter', src_circuit = 'output', dst = 'main', dst_circuit = 'output', wire = 'green', },
    },

    -- do not use a wire for signal selection. Wire the signal buffer to the signal controller and both data wires to the data buffer
    no_wire = {
        { src = 'signals', dst = 'sig_norm',      dst_circuit = 'input', wire = 'green', },
        { src = 'main',    src_circuit = 'input', dst = 'pos_split',     dst_circuit = 'input', wire = 'red', },
        { src = 'main',    src_circuit = 'input', dst = 'pos_split',     dst_circuit = 'input', wire = 'green', },
        { src = 'main',    src_circuit = 'input', dst = 'neg_split',     dst_circuit = 'input', wire = 'red', },
        { src = 'main',    src_circuit = 'input', dst = 'neg_split',     dst_circuit = 'input', wire = 'green', },
    },

    -- use red wire for signal selection. Wire it to the signal buffer, wire only the green wire to the data buffer
    red_wire = {
        { src = 'main', src_circuit = 'input', dst = 'sig_norm',  dst_circuit = 'input', wire = 'red', },
        { src = 'main', src_circuit = 'input', dst = 'pos_split', dst_circuit = 'input', wire = 'green', },
        { src = 'main', src_circuit = 'input', dst = 'neg_split', dst_circuit = 'input', wire = 'green', },
    },

    -- use green wire for signal selection. Wire it to the signal buffer, wire only the red wire to the data buffer
    green_wire = {
        { src = 'main', src_circuit = 'input', dst = 'sig_norm',  dst_circuit = 'input', wire = 'green', },
        { src = 'main', src_circuit = 'input', dst = 'pos_split', dst_circuit = 'input', wire = 'red', },
        { src = 'main', src_circuit = 'input', dst = 'neg_split', dst_circuit = 'input', wire = 'red', },
    },
}

------------------------------------------------------------------------
-- create internal entities
------------------------------------------------------------------------

---@class FcCreateInternalEntityCfg
---@field entity FilterCombinatorData
---@field type string
---@field ignore boolean?
---@field comb_visible boolean
---@field desc string?
---@field x integer?
---@field y integer?

---@param cfg FcCreateInternalEntityCfg
local function create_internal_entity(cfg)
    local fc_entity = cfg.entity
    local type = cfg.type
    local comb_visible = cfg.comb_visible or false
    local desc = cfg.desc or ''


    -- invisible combinators share position with the main unit
    local x = (comb_visible and cfg.x or 0) or 0
    local y = (comb_visible and cfg.y or 0) or 0

    local entity_map = const.entity_maps[comb_visible and 'debug' or 'standard']

    local main = fc_entity.main

    ---@type LuaEntity?
    local sub_entity = main.surface.create_entity {
        name = entity_map[type],
        position = { x = main.position.x + x, y = main.position.y + y },
        direction = main.direction,
        force = main.force,
        quality = main.quality,

        create_build_effect_smoke = false,
        spawn_decorations = false,
        move_stuck_players = true,
    }

    assert(sub_entity)

    sub_entity.combinator_description = desc
    sub_entity.minable = false
    sub_entity.destructible = false
    sub_entity.operable = comb_visible -- for debugging

    fc_entity.entities[sub_entity.unit_number] = sub_entity

    return sub_entity
end

---@param fc_entity FilterCombinatorData
---@param dc_config DcConfig
local function configure_dc(fc_entity, dc_config)
    local condition = {
        first_signal = dc_config.first_signal or signal_each,
        comparator = dc_config.comparator,
        constant = dc_config.second_constant
    }

    local output = {
        signal = dc_config.output_signal or signal_each,
        copy_count_from_input = dc_config.copy_count_from_input,
        networks = { red = dc_config.red_network == nil and true or dc_config.red_network, green = dc_config.green_network == nil and true or dc_config.green_network, }
    }

    local dc_control_behavior = fc_entity.ref[dc_config.src].get_or_create_control_behavior() --[[@as LuaDeciderCombinatorControlBehavior]]
    assert(dc_control_behavior)
    dc_control_behavior.set_condition(1, condition)
    dc_control_behavior.set_output(1, output)
end

--- Rewires a FC to match its configuration. Must be called after every configuration
--- change.
---@param fc_entity FilterCombinatorData
---@param fc_config FilterCombinatorConfig?
function FiCo:reconfigure(fc_entity, fc_config)
    if not fc_entity then return end

    fc_config = fc_config and util.copy(fc_config) or fc_entity.config

    local enabled = fc_config.enabled and tools.STATUS_TABLE[fc_entity.config.status] ~= 'RED'

    -- disconnect all wires
    for _, name in pairs { 'enable', 'no_wire', 'red_wire', 'green_wire', } do
        for _, cfg in pairs(wiring[name]) do
            disconnect_wire(fc_entity, cfg)
        end
    end

    local signals_control_behavior = fc_entity.ref.signals.get_or_create_control_behavior() --[[@as LuaConstantCombinatorControlBehavior ]]
    assert(signals_control_behavior)
    signals_control_behavior.enabled = enabled

    if not enabled then return end

    -- setup the signals in the signal_control cc
    assign_filters(signals_control_behavior, fc_config.filters)

    -- enabled. Connect the wires for enabling
    for _, cfg in pairs(wiring.enable) do
        connect_wire(fc_entity, cfg)
    end

    -- rewiring for internal settings / green wire / red wire
    local rewire_cfg = 'no_wire'
    if fc_config.use_wire then
        rewire_cfg = fc_config.filter_wire == defines.wire_type.red and 'red_wire' or 'green_wire'
    end

    for _, cfg in pairs(wiring[rewire_cfg]) do
        connect_wire(fc_entity, cfg)
    end

    -- control include/exclude
    local dc_cfg = fc_config.include_mode and 'include' or 'exclude'
    for _, behavior in pairs(dc_config[dc_cfg]) do
        configure_dc(fc_entity, behavior)
    end
end

------------------------------------------------------------------------
-- create/destroy
------------------------------------------------------------------------

--- Creates and wires up all the sub entities.
---@param fc_entity FilterCombinatorData
function FiCo:create_sub_entities(fc_entity)
    -- create sub-entities
    for _, cfg in pairs(sub_entities) do
        fc_entity.ref[cfg.id] = create_internal_entity {
            entity = fc_entity,
            type = cfg.type,
            x = cfg.x,
            y = cfg.y,
            desc = cfg.desc,
            comb_visible = fc_entity.comb_visible
        }
    end

    local signals_control_behavior = fc_entity.ref.signals.get_or_create_control_behavior() --[[@as LuaConstantCombinatorControlBehavior]]
    assert(signals_control_behavior)
    for i = 1, signals_control_behavior.sections_count, 1 do
        signals_control_behavior.remove_section(i)
    end

    -- setup all the sub-entities
    for _, behavior in pairs(ac_config.init) do
        local parameters = {
            first_signal = behavior.first_signal or signal_each,
            output_signal = behavior.output_signal or signal_each,
            operation = behavior.operation,
            copy_count_from_input = behavior.copy_count_from_input,
            second_constant = behavior.second_constant
        }
        local ac_control_behavior = fc_entity.ref[behavior.src].get_or_create_control_behavior() --[[@as LuaArithmeticCombinatorControlBehavior]]
        ac_control_behavior.parameters = parameters
    end

    for _, behavior in pairs(dc_config.init) do
        configure_dc(fc_entity, behavior)
    end

    -- setup the initial wiring
    for _, connect in pairs(wiring.init) do
        connect_wire(fc_entity, connect)
    end
end

--- Creates a new entity from the main entity, registers with the mod
--- and configures it.
---@param main LuaEntity
---@param config FilterCombinatorConfig?
function FiCo:create(main, config)
    if not Is.Valid(main) then return end

    local entity_id = main.unit_number --[[@as integer]]

    assert(self:entity(entity_id) == nil)

    -- if true, draw all combinators and wires. For debugging
    local comb_visible = Framework.settings:runtime_setting('debug_mode')

    -- if config was passed in, use that
    config = create_config(config)
    config.status = main.status

    ---@type FilterCombinatorData
    local fc_entity = {
        main = main,
        config = tools.copy(config), -- config may refer to the signal object in parent or default config.
        comb_visible = comb_visible,
        entities = {},
        ref = { main = main },
    }

    self:create_sub_entities(fc_entity)

    self:setEntity(entity_id, fc_entity)

    self:reconfigure(fc_entity)

    return fc_entity
end

--- Destroys a FC and all its sub-entities
---@param entity_id integer main unit number (== entity id)
---@return boolean true if an entity was actually destroyed
function FiCo:destroy(entity_id)
    assert(Is.Number(entity_id))

    local fc_entity = self:entity(entity_id)
    if not fc_entity then return false end

    for _, sub_entity in pairs(fc_entity.entities) do
        sub_entity.destroy()
    end

    self:setEntity(entity_id, nil)
    return true
end

--------------------------------------------------------------------------------
-- Config serialization for blueprint and tombstone
--------------------------------------------------------------------------------

---@param entity LuaEntity
---@return table<string, any>?
function FiCo.serialize_config(entity)
    if not Is.Valid(entity) then return end

    local fico_entity = This.fico:entity(entity.unit_number)
    if not fico_entity then return end

    return {
        [const.config_tag_name] = fico_entity.config,
    }
end

------------------------------------------------------------------------
-- ticker code, updates the status
------------------------------------------------------------------------

--- Can be called from a ticker to update e.g. power status. Useful in
--- the GUI.
---@param fc_entity FilterCombinatorData
function FiCo:tick(fc_entity)
    if not fc_entity then return end

    -- update status based on the main entity
    if not Is.Valid(fc_entity.main) then
        fc_entity.config.enabled = false
        fc_entity.config.status = defines.entity_status.marked_for_deconstruction
    else
        local old_status = fc_entity.config.status
        fc_entity.config.status = fc_entity.main.status

        if old_status ~= fc_entity.config.status then
            self:reconfigure(fc_entity)
        end
    end
end

------------------------------------------------------------------------
-- picker dollies (move)
------------------------------------------------------------------------

function FiCo:move(start_pos, entity)
    local fc_entity = self:entity(entity.unit_number)
    if not fc_entity then return end

    local x = entity.position.x - start_pos.x
    local y = entity.position.y - start_pos.y

    for _, e in pairs(fc_entity.entities) do
        if e.valid then
            e.teleport { x = e.position.x + x, y = e.position.y + y }
        end
    end
end

------------------------------------------------------------------------

return FiCo
