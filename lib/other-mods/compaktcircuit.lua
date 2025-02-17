--------------------------------------------------------------------------------
-- CompactCircuit (https://mods.factorio.com/mod/compaktcircuit) support
--------------------------------------------------------------------------------

local const = require('lib.constants')
local Is = require('stdlib.utils.is')

local CompaktCircuitSupport = {}

--------------------------------------------------------------------------------

---@param entity LuaEntity
local function ccs_get_info(entity)
    if not Is.Valid(entity) then return end

    local fc_entity = This.fico:entity(entity.unit_number)
    if not fc_entity then return end

    return {
        [const.config_tag_name] = fc_entity.config
    }
end

---@class filter_combinator.CompactCircuitInfo
---@field name string
---@field index number
---@field position MapPosition
---@field direction defines.direction
---@field fc_config FilterCombinatorConfig

---@param info filter_combinator.CompactCircuitInfo
---@param surface LuaSurface
---@param position MapPosition
---@param force LuaForce
local function ccs_create_packed_entity(info, surface, position, force)
    local packed_main = surface.create_entity {
        name = const.filter_combinator_name_packed,
        position = position,
        direction = info.direction,
        force = force,
        raise_built = false,
    }

    assert(packed_main)

    local fc_entity = This.fico:create(packed_main, info[const.config_tag_name])
    assert(fc_entity)

    return packed_main
end

---@param info filter_combinator.CompactCircuitInfo
---@param surface LuaSurface
---@param force LuaForce
local function ccs_create_entity(info, surface, force)
    local main = surface.create_entity {
        name = const.filter_combinator_name,
        position = info.position,
        direction = info.direction,
        force = force,
        raise_built = false,
    }

    assert(main)

    local fc_entity = This.fico:create(main, info[const.config_tag_name])
    assert(fc_entity)

    return main
end

--------------------------------------------------------------------------------

local function ccs_init()
    if not Framework.remote_api then return end
    if not remote.interfaces['compaktcircuit'] then return end

    if remote.interfaces['compaktcircuit']['add_combinator'] then
        Framework.remote_api.get_info = ccs_get_info
        Framework.remote_api.create_packed_entity = ccs_create_packed_entity
        Framework.remote_api.create_entity = ccs_create_entity

        remote.call('compaktcircuit', 'add_combinator', {
            name = const.filter_combinator_name,
            packed_names = { const.filter_combinator_name_packed },
            interface_name = const.filter_combinator_name,
        })
    end
end

--------------------------------------------------------------------------------

function CompaktCircuitSupport.data()
    assert(data.raw)

    local data_util = require('framework.prototypes.data-util')

    local fc_entity_packed = data_util.copy_entity_prototype(data.raw['arithmetic-combinator'][const.filter_combinator_name],
        const.filter_combinator_name_packed, true) --[[@as data.ArithmeticCombinatorPrototype ]]

    -- ArithmeticCombinatorPrototype
    for _, field in pairs(const.ac_sprites) do
        fc_entity_packed[field] = util.empty_sprite()
    end

    fc_entity_packed.hidden = true
    fc_entity_packed.hidden_in_factoriopedia = true

    data:extend { fc_entity_packed }
end

--------------------------------------------------------------------------------

function CompaktCircuitSupport.runtime()
    assert(script)

    local Event = require('stdlib.event.event')

    Event.on_init(ccs_init)
    Event.on_load(ccs_init)
end

return CompaktCircuitSupport
