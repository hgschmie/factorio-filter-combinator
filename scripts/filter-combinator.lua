------------------------------------------------------------------------
-- Filter combinator main code
------------------------------------------------------------------------

local Is = require('__stdlib__/stdlib/utils/is')
local table = require('__stdlib__/stdlib/utils/table')
local Util = require('framework.util')

local const = require('lib.constants')

--- @class FilterCombinator
local FiCo = {}

------------------------------------------------------------------------

---@class FilterCombinatorConfig
---@field enabled boolean
---@field status defines.entity_status?
---@field use_wire boolean
---@field filter_wire defines.wire_type
---@field include_mode boolean
---@field signals ConstantCombinatorParameters[]
local default_config = {
    enabled = true,
    use_wire = false,
    filter_wire = defines.wire_type.green,
    include_mode = true,
    signals = {}
}

--- @param parent_config FilterCombinatorConfig?
--- @return FilterCombinatorConfig config
local function create_config(parent_config)
    parent_config = parent_config or default_config

    local config = {}
    -- iterate over all field names given in the default_config
    for field_name, _ in pairs(default_config) do
        config[field_name] = parent_config[field_name] or default_config[field_name]
    end

    return config
end

------------------------------------------------------------------------
-- init setup
------------------------------------------------------------------------

--- Setup the global fico data structure.
function FiCo:init()
    if global.fc_data then return end

    global.fc_data = {
        fc = {},
        count = 0,
        VERSION = const.current_version,
    }
end

------------------------------------------------------------------------
-- attribute getters/setters
------------------------------------------------------------------------

--- Returns the registered total count
--- @return integer count The total count of filter combinators
function FiCo:totalCount()
    return global.fc_data.count
end

--- Returns data for all filter combinators.
--- @return FilterCombinatorData[] entities
function FiCo:entities()
    return global.fc_data.fc
end

--- Returns data for a given filter combinator
--- @param entity_id integer main unit number (== entity id)
--- @return FilterCombinatorData? entity
function FiCo:entity(entity_id)
    return global.fc_data.fc[entity_id]
end

--- Sets or clears a filter combinator entity
--- @param entity_id integer The unit_number of the primary
---@param fc_entity FilterCombinatorData?
function FiCo:setEntity(entity_id, fc_entity)
    assert((fc_entity ~= nil and global.fc_data.fc[entity_id] == nil)
        or (fc_entity == nil and global.fc_data.fc[entity_id] ~= nil))

    if (fc_entity) then
        assert(Is.Valid(fc_entity.main) and fc_entity.main.unit_number == entity_id)
    end

    global.fc_data.fc[entity_id] = fc_entity
    global.fc_data.count = global.fc_data.count + ((fc_entity and 1) or -1)

    if global.fc_data.count < 0 then
        global.fc_data.count = table_size(global.fc_data.fc)
        Framework.logger:logf('Filter Combinator count got negative (bug), size is now: %d', global.fc_data.count)
    end
end

------------------------------------------------------------------------
-- create internal entities
------------------------------------------------------------------------

---@class FcCreateInternalEntityCfg
---@field entity FilterCombinatorData
---@field type string
---@field ignore boolean?
---@field player_index integer?
---@field x integer?
---@field y integer?

---@param cfg FcCreateInternalEntityCfg
local function create_internal_entity(cfg)
    local fc_entity = cfg.entity
    local type = cfg.type

    local ignore = cfg.ignore or false
    local player_index = cfg.player_index

    -- ignored combinators are always invisible
    -- if no player index was passed, combinators are invisible
    local comb_visible = (not ignore) and (player_index and Framework.settings:player(player_index).comb_visible)

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

        create_build_effect_smoke = false,
        spawn_decorations = false,
        move_stuck_players = true,
    }

    assert(sub_entity)

    sub_entity.minable = false
    sub_entity.destructible = false

    if not ignore then
        fc_entity.entities[sub_entity.unit_number] = sub_entity
    end

    return sub_entity
end

------------------------------------------------------------------------
-- "all signals" management
------------------------------------------------------------------------

--- Adds all item, fluid and virtual signals to a combinator.
--- @return ConstantCombinatorParameters[] all_signals
local function create_all_signals()
    local prototypes = {
        item = game.item_prototypes,
        fluid = game.fluid_prototypes,
        virtual = game.virtual_signal_prototypes,
    }

    local idx = 1

    ---@type ConstantCombinatorParameters[]
    local signals = {}

    for type, prototype in pairs(prototypes) do
        for sig_name, p in pairs(prototype) do
            if not (type == 'virtual' and p.special) then
                table.insert(signals, { signal = { type = type, name = sig_name }, count = 1, index = idx })
                idx = idx + 1
            end
        end
    end

    return signals
end

---@return ConstantCombinatorParameters[] all_signals
function FiCo:getAllSignals()
    if not self.all_signals then
        if not global.all_signals then
            global.all_signals = create_all_signals()
        end
        self.all_signals = global.all_signals
    end
    return self.all_signals
end

function FiCo:clearAllSignals()
    self.all_signals = nil
    global.all_signals = nil
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

---@param fc_entity FilterCombinatorData
---@param wire_cfg FcWireConfig
---@param wire_type table<string, defines.wire_type>?
local function connect_wire(fc_entity, wire_cfg, wire_type)
    wire_type = wire_type or defines.wire_type
    local wire = wire_type[wire_cfg.wire or 'red']

    assert(fc_entity.ref[wire_cfg.src])
    assert(fc_entity.ref[wire_cfg.dst])

    assert(fc_entity.ref[wire_cfg.src].connect_neighbour {
        target_entity = fc_entity.ref[wire_cfg.dst],
        wire = wire,
        source_circuit_id = wire_cfg.src_circuit and defines.circuit_connector_id['combinator_' .. wire_cfg.src_circuit],
        target_circuit_id = wire_cfg.dst_circuit and defines.circuit_connector_id['combinator_' .. wire_cfg.dst_circuit],
    })
end

---@param fc_entity FilterCombinatorData
---@param wire_cfg FcWireConfig
local function disconnect_wire(fc_entity, wire_cfg)
    local wire = defines.wire_type[wire_cfg.wire or 'red']

    assert(fc_entity.ref[wire_cfg.src])
    if wire_cfg.dst then
        assert(fc_entity.ref[wire_cfg.dst])
    end

    if wire_cfg.dst then
        fc_entity.ref[wire_cfg.src].disconnect_neighbour {
            target_entity = fc_entity.ref[wire_cfg.dst],
            wire = wire,
            source_circuit_id = wire_cfg.src_circuit and defines.circuit_connector_id['combinator_' .. wire_cfg.src_circuit],
            target_circuit_id = wire_cfg.dst_circuit and defines.circuit_connector_id['combinator_' .. wire_cfg.dst_circuit],
        }
    else
        fc_entity.ref[wire_cfg.src].disconnect_neighbour(wire)
    end
end


-- Position grid for sub-entities if they are visible (for debugging)
--
--    -4/-4      -2/-4             0/-4 (out)  2/-4             4/-4
--    -4/-2 (a2) -2/-2 (a4)        0/-2        2/-2  (d2)       4/-2 (d3)
--    -4/ 0      -2/ 0 (input_pos) 0/ 0 (main) 2/ 0 (input_neg) 4/ 0 (d4)
--    -4/ 2      -2/ 2 (filter)    0/ 2        2/ 2 (inv)       4/ 2
--    -4/ 4 (cc) -2/ 4             0/ 4 (inp)  2/ 4             4/ 4 (ex)
--
local sub_entities = {
    { id = 'cc',        type = 'cc', x = -4, y = 4 },
    { id = 'ex',        type = 'cc', x = 4,  y = 4 },

    { id = 'filter',    type = 'dc', x = -2, y = 2 },

    { id = 'inp',       type = 'dc', x = 0,  y = 4 },
    { id = 'out',       type = 'ac', x = 0,  y = -4 },

    { id = 'inv',       type = 'ac', x = 2,  y = 2 },

    { id = 'input_pos', type = 'ac', x = -2, y = 0 },
    { id = 'input_neg', type = 'ac', x = 2,  y = 0 },

    { id = 'a2',        type = 'ac', x = -4, y = -2 },
    { id = 'a4',        type = 'ac', x = -2, y = -2 },

    { id = 'd2',        type = 'dc', x = 2,  y = -2 },
    { id = 'd3',        type = 'dc', x = 4,  y = -2 },
    { id = 'd4',        type = 'dc', x = 4,  y =  0 },

}

local signal_each = { type = 'virtual', name = 'signal-each' }

local initial_behavior = {
    { src = 'filter',    comparator = '!=', copy_count_from_input = false },
    { src = 'inp',       comparator = '<' },
    { src = 'd2',        comparator = '>' },
    { src = 'd3',        comparator = '>' },
    { src = 'd4',        comparator = '<' },
    { src = 'input_neg', operation = '*',   second_constant = 0 - (2 ^ 31 - 1) },
    { src = 'a2',        operation = '*',   second_constant = -1 },
    { src = 'input_pos', operation = '*',   second_constant = 2 ^ 31 - 1 },
    { src = 'a4',        operation = '*',   second_constant = -1 },
    { src = 'out',       operation = '+',   second_constant = 0 },
    { src = 'inv',       operation = '*',   second_constant = -1 },
}

local wiring = {
    -- the base wiring that needs to be done when the fc is created
    initial = {
        -- ex, target_entity = inv, target_circuit_id = output }
        { src = 'ex',        dst = 'inv',            dst_circuit = 'output' },
        -- cc, target_entity = inv, target_circuit_id = input }
        { src = 'cc',        dst = 'inv',            dst_circuit = 'input' },
        -- Exclusive Mode
        -- ccf, target_entity = inv, target_circuit_id = input, source_circuit_id = output, }
        { src = 'filter',    src_circuit = 'output', dst = 'inv',           dst_circuit = 'input' },

        -- Connect Logic
        -- d1, target_entity = d2, target_circuit_id = input, source_circuit_id = input, }
        { src = 'inp',       src_circuit = 'input',  dst = 'd2',            dst_circuit = 'input' },
        -- d1.connect_neighbour { wire = defines.wire_type.green, target_entity = d2, target_circuit_id = input, source_circuit_id = input, }
        { src = 'inp',       src_circuit = 'input',  dst = 'd2',            dst_circuit = 'input',  wire = 'green' },

        -- -- Negative Inputs
        -- a1, target_entity = cc, source_circuit_id = input }
        { src = 'input_neg', src_circuit = 'input',  dst = 'cc' },
        -- a2, target_entity = a1, target_circuit_id = output, source_circuit_id = input,}
        { src = 'a2',        src_circuit = 'input',  dst = 'input_neg',     dst_circuit = 'output' },
        -- d3, target_entity = a2, target_circuit_id = output, source_circuit_id = input,}
        { src = 'd3',        src_circuit = 'input',  dst = 'a2',            dst_circuit = 'output' },
        -- d3, target_entity = d1, target_circuit_id = output, source_circuit_id = input,}
        { src = 'd3',        src_circuit = 'input',  dst = 'inp',           dst_circuit = 'output' },

        -- -- Positive Inputs
        -- a3, target_entity = cc, source_circuit_id = input }
        { src = 'input_pos', src_circuit = 'input',  dst = 'cc' },
        -- a4, target_entity = a3, target_circuit_id = output, source_circuit_id = input,}
        { src = 'a4',        src_circuit = 'input',  dst = 'input_pos',     dst_circuit = 'output' },
        -- d4, target_entity = a4, target_circuit_id = output, source_circuit_id = input,}
        { src = 'd4',        src_circuit = 'input',  dst = 'a4',            dst_circuit = 'output' },
        -- d4, target_entity = d2, target_circuit_id = output, source_circuit_id = input,}
        { src = 'd4',        src_circuit = 'input',  dst = 'd2',            dst_circuit = 'output' },

        -- -- Wire up output (to be able to use any color wire again)
        -- out.connect_neighbour { wire = defines.wire_type.green, target_entity = a1, target_circuit_id = output, source_circuit_id = input, }
        { src = 'out',       src_circuit = 'input',  dst = 'input_neg',     dst_circuit = 'output', wire = 'green' },
        -- out.connect_neighbour { wire = defines.wire_type.green, target_entity = d3, target_circuit_id = output, source_circuit_id = input, }
        { src = 'out',       src_circuit = 'input',  dst = 'd3',            dst_circuit = 'output', 'green' },
        -- out.connect_neighbour { wire = defines.wire_type.green, target_entity = a3, target_circuit_id = output, source_circuit_id = input, }
        { src = 'out',       src_circuit = 'input',  dst = 'input_pos',     dst_circuit = 'output', wire = 'green' },
        -- out.connect_neighbour { wire = defines.wire_type.green, target_entity = d4, target_circuit_id = output, source_circuit_id = input, }
        { src = 'out',       src_circuit = 'input',  dst = 'd4',            dst_circuit = 'output', wire = 'green' },

        -- -- Connect main entity
        -- main, target_entity = out, target_circuit_id = output, source_circuit_id = output, }
        { src = 'main',      src_circuit = 'output', dst = 'out',           dst_circuit = 'output' },
        -- main.connect_neighbour { wire = defines.wire_type.green, target_entity = out, target_circuit_id = output, source_circuit_id = output, }
        { src = 'main',      src_circuit = 'output', dst = 'out',           dst_circuit = 'output', wire = 'green' },
        -- main, target_entity = d1, target_circuit_id = input, source_circuit_id = input, }
        { src = 'main',      src_circuit = 'input',  dst = 'inp',           dst_circuit = 'input' },
        -- main.connect_neighbour { wire = defines.wire_type.green, target_entity = d1, target_circuit_id = input, source_circuit_id = input, }
        { src = 'main',      src_circuit = 'input',  dst = 'inp',           dst_circuit = 'input',  wire = 'green' },
    },
    -- disconnect phase 1. After executing this, the fc is disabled
    disconnect1 = {
        -- Disconnect main, which was potentially rewired for wire input based filtering
        -- data.main.disconnect_neighbour { wire = defines.wire_type.red, target_entity = data.inp, target=input, source=input, }
        { src = 'main', src_circuit = 'input', dst = 'inp',    dst_circuit = 'input' },
        -- data.main.disconnect_neighbour { wire = defines.wire_type.green, target_entity = data.inp, target=input, source=input, }
        { src = 'main', src_circuit = 'input', dst = 'inp',    dst_circuit = 'input', wire = 'green' },
        -- data.main.disconnect_neighbour { wire = defines.wire_type.red, target_entity = data.filter, target=input, source=input, }
        { src = 'main', src_circuit = 'input', dst = 'filter', dst_circuit = 'input' },
        -- data.main.disconnect_neighbour { wire = defines.wire_type.green, target_entity = data.filter, target=input, source=input, }
        { src = 'main', src_circuit = 'input', dst = 'filter', dst_circuit = 'input', wire = 'green' },
    },
    -- disconnect phase 2. After executing this, the fc is ready to be rewired
    disconnect2 = {
        -- Disconnect configured input, which gets rewired for exclusive mode and wire input filtering
        -- data.cc.disconnect_neighbour(defines.wire_type.red)
        { src = 'cc' },

        -- Disconnect inverter, which gets rewired for exclusive mode
        -- data.inv.disconnect_neighbour { wire = defines.wire_type.red, target_entity = data.input_pos, target=input, source=output, }
        { src = 'inv',    src_circuit = 'output', dst = 'input_pos', dst_circuit = 'input' },
        -- data.inv.disconnect_neighbour { wire = defines.wire_type.red, target_entity = data.input_neg, target=input, source=output, }
        { src = 'inv',    src_circuit = 'output', dst = 'input_neg', dst_circuit = 'input' },

        -- Disconnect filter, which gets rewired for wire input based filtering
        -- data.filter.disconnect_neighbour { wire = defines.wire_type.red, target_entity = data.input_pos, target=input, source=output, }
        { src = 'filter', src_circuit = 'output', dst = 'input_pos', dst_circuit = 'input' },
        -- data.filter.disconnect_neighbour { wire = defines.wire_type.red, target_entity = data.input_neg, target=input, source=output, }
        { src = 'filter', src_circuit = 'output', dst = 'input_neg', dst_circuit = 'input' },

    },
    -- connect default configuration (include mode, using constants)
    connect_default = {
        -- Default config
        -- data.cc.connect_neighbour { wire = defines.wire_type.red, target_entity = data.input_pos, target=input, }
        { src = 'cc',   dst = 'input_pos',     dst_circuit = 'input' },
        -- data.cc.connect_neighbour { wire = defines.wire_type.red, target_entity = data.input_neg, target=input, }
        { src = 'cc',   dst = 'input_neg',     dst_circuit = 'input' },

        -- data.main.connect_neighbour { wire = defines.wire_type.red, target_entity = data.inp, target=input, source=input, }
        { src = 'main', src_circuit = 'input', dst = 'inp',          dst_circuit = 'input' },
        -- data.main.connect_neighbour { wire = defines.wire_type.green, target_entity = data.inp, target=input, source=input, }
        { src = 'main', src_circuit = 'input', dst = 'inp',          dst_circuit = 'input', wire = 'green' },
    },
    -- connect exclude configuration (exclude mode, using constants)
    connect_exclude = {
        -- All but the configured signals
        -- data.cc.connect_neighbour { wire = defines.wire_type.red, target_entity = data.inv, target=input }
        { src = 'cc',   dst = 'inv',            dst_circuit = 'input' },

        -- data.inv.connect_neighbour { wire = defines.wire_type.red, target_entity = data.input_pos, target=input, source=output, }
        { src = 'inv',  src_circuit = 'output', dst = 'input_pos',    dst_circuit = 'input' },
        -- data.inv.connect_neighbour { wire = defines.wire_type.red, target_entity = data.input_neg, target=input, source=output, }
        { src = 'inv',  src_circuit = 'output', dst = 'input_neg',    dst_circuit = 'input' },

        -- data.main.connect_neighbour { wire = defines.wire_type.red, target_entity = data.inp, target=input, source=input, }
        { src = 'main', src_circuit = 'input',  dst = 'inp',          dst_circuit = 'input' },
        -- data.main.connect_neighbour { wire = defines.wire_type.green, target_entity = data.inp, target=input, source=input, }
        { src = 'main', src_circuit = 'input',  dst = 'inp',          dst_circuit = 'input', wire = 'green' },
    },
    -- connect wire mode (include mode, using wire to select signals)
    connect_use_wire = {
        -- Wire input is the signals we want
        -- data.main.connect_neighbour { wire = non_filter_wire, target_entity = data.inp, target=input, source=input, }
        { src = 'main',   src_circuit = 'input',  dst = 'inp',       dst_circuit = 'input', wire = 'non_filter' },
        -- data.main.connect_neighbour { wire = filter_wire, target_entity = data.filter, target=input, source=input, }
        { src = 'main',   src_circuit = 'input',  dst = 'filter',    dst_circuit = 'input', wire = 'filter' },

        -- data.filter.connect_neighbour { wire = defines.wire_type.red, target_entity = data.input_pos, target=input, source=output, }
        { src = 'filter', src_circuit = 'output', dst = 'input_pos', dst_circuit = 'input' },
        -- data.filter.connect_neighbour { wire = defines.wire_type.red, target_entity = data.input_neg, target=input, source=output, }
        { src = 'filter', src_circuit = 'output', dst = 'input_neg', dst_circuit = 'input' },

    },
    -- connect wire exclude mode (exclude mode, using wire to select signals)
    connect_use_wire_exclude = {
        -- All but those present on an input wire
        -- data.main.connect_neighbour { wire = non_filter_wire, target_entity = data.inp, target=input, source=input, }
        { src = 'main', src_circuit = 'input',  dst = 'inp',       dst_circuit = 'input', wire = 'non_filter' },
        -- data.main.connect_neighbour { wire = filter_wire, target_entity = data.filter, target=input, source=input, }
        { src = 'main', src_circuit = 'input',  dst = 'filter',    dst_circuit = 'input', wire = 'filter' },

        -- data.inv.connect_neighbour { wire = defines.wire_type.red, target_entity = data.input_pos, target=input, source=output, }
        { src = 'inv',  src_circuit = 'output', dst = 'input_pos', dst_circuit = 'input' },
        -- data.inv.connect_neighbour { wire = defines.wire_type.red, target_entity = data.input_neg, target=input, source=output, }
        { src = 'inv',  src_circuit = 'output', dst = 'input_neg', dst_circuit = 'input' },
    }
}

--- Rewires a FC to match its configuration. Must be called after every configuration
--- change.
---@param fc_entity FilterCombinatorData
function FiCo:reconfigure(fc_entity)
    if not fc_entity then return end

    local fc_config = fc_entity.config

    local enabled = fc_config.enabled and Util.STATUS_TABLE[fc_entity.config.status] ~= 'RED'

    -- disconnect wires in case the combinator was turned off
    for _, cfg in pairs(wiring.disconnect1) do
        disconnect_wire(fc_entity, cfg)
    end

    -- turn the constant combinators on or off
    -- fc_entity.ref.main.active = enabled
    fc_entity.ref.ex.get_or_create_control_behavior().enabled = enabled

    local cc_control = fc_entity.ref.cc.get_or_create_control_behavior() --[[@as LuaConstantCombinatorControlBehavior ]]
    cc_control.enabled = enabled

    if not enabled then return end

    -- setup the signals for the cc
    cc_control.parameters = table.deepcopy(fc_config.signals)

    -- disconnect wires for rewiring
    for _, cfg in pairs(wiring.disconnect2) do
        disconnect_wire(fc_entity, cfg)
    end

    -- now rewire
    local rewire_cfg
    if fc_config.include_mode and fc_config.use_wire then
        -- all inputs on a wire
        rewire_cfg = wiring.connect_use_wire
    elseif fc_config.use_wire then
        -- all but inputs on a wire
        rewire_cfg = wiring.connect_use_wire_exclude
    elseif fc_config.include_mode then
        -- default
        rewire_cfg = wiring.connect_default
    else
        -- exclude mode
        rewire_cfg = wiring.connect_exclude
    end

    local wire_type = {
        red = defines.wire_type.red,
        green = defines.wire_type.green,
        filter = fc_config.filter_wire == defines.wire_type.red and defines.wire_type.red or defines.wire_type.green,
        non_filter = fc_config.filter_wire == defines.wire_type.green and defines.wire_type.red or defines.wire_type.green,
    }

    -- reconnect based on the configuration
    for _, cfg in pairs(rewire_cfg) do
        connect_wire(fc_entity, cfg, wire_type)
    end
end

------------------------------------------------------------------------
-- create/destroy
------------------------------------------------------------------------

--- Creates a new entity from the main entity, registers with the mod
--- and configures it.
--- @param main LuaEntity
--- @param player_index integer?
--- @param tags Tags?
function FiCo:create(main, player_index, tags)
    if not Is.Valid(main) then return end

    local entity_id = main.unit_number --[[@as integer]]

    assert(self:entity(entity_id) == nil)

    -- if tags were passed in and they contain a fc config, use that.
    local config = create_config(tags and tags['fc_config'] --[[@as FilterCombinatorConfig]])
    config.status = main.status

    local fc_entity = {
        main = main,
        config = table.deepcopy(config), -- config may refer to the signal object in parent or default config.
        entities = {},
        ref = { main = main },
    }
    -- create sub-entities
    for _, cfg in pairs(sub_entities) do
        fc_entity.ref[cfg.id] = create_internal_entity {
            entity = fc_entity,
            type = cfg.type,
            x = cfg.x,
            y = cfg.y,
            player_index = player_index
        }
    end

    fc_entity.ref.ex.get_or_create_control_behavior().parameters = self:getAllSignals()

    -- setup all the sub-entities
    for _, behavior in pairs(initial_behavior) do
        local parameters = {
            first_signal = behavior.first_signal or signal_each,
            output_signal = behavior.output_signal or signal_each,
            comparator = behavior.comparator,
            operation = behavior.operation,
            copy_count_from_input = behavior.copy_count_from_input,
            second_constant = behavior.second_constant
        }
        fc_entity.ref[behavior.src].get_or_create_control_behavior().parameters = parameters
    end

    -- setup the initial wiring
    for _, connect in pairs(wiring.initial) do
        connect_wire(fc_entity, connect)
    end

    self:setEntity(entity_id, fc_entity)

    return fc_entity
end

--- Destroys a FC and all its sub-entities
--- @param entity_id integer main unit number (== entity id)
function FiCo:destroy(entity_id)
    assert(Is.Number(entity_id))

    local fc_entity = self:entity(entity_id)
    if not fc_entity then return end

    for _, sub_entity in pairs(fc_entity.entities) do
        sub_entity.destroy()
    end

    self:setEntity(entity_id, nil)
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

--- @class FilterCombinatorData
--- @field main LuaEntity
--- @field config FilterCombinatorConfig
--- @field entities LuaEntity[]
--- @field ref table<string, LuaEntity>
