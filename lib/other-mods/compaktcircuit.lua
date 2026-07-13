--------------------------------------------------------------------------------
-- CompactCircuit (https://mods.factorio.com/mod/compaktcircuit) support
--------------------------------------------------------------------------------

local util = require('util')

local const = require('lib.constants')

--------------------------------------------------------------------------------

---@param entity LuaEntity
local function ccs_get_info(entity)
    return This.fico.serialize_config(entity)
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
    local packed_main = assert(surface.create_entity {
        name = const.filter_combinator_name_packed,
        position = position,
        direction = info.direction,
        force = force,
        raise_built = false,
    })

    local config = This.fico.deserialize_config(info)

    assert(This.fico:create(packed_main, config))
    return packed_main
end

---@param info filter_combinator.CompactCircuitInfo
---@param surface LuaSurface
---@param force LuaForce
local function ccs_create_entity(info, surface, force)
    local main = assert(surface.create_entity {
        name = const.filter_combinator_name,
        position = info.position,
        direction = info.direction,
        force = force,
        raise_built = false,
    })

    local config = This.fico.deserialize_config(info)

    assert(This.fico:create(main, config))
    return main
end

--------------------------------------------------------------------------------

local function ccs_init()
    Framework.ExportedApis.get_info = ccs_get_info
    Framework.ExportedApis.create_packed_entity = ccs_create_packed_entity
    Framework.ExportedApis.create_entity = ccs_create_entity
end

--------------------------------------------------------------------------------

return {
    data_updates = function()
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
    end,

    --------------------------------------------------------------------------------

    runtime = function()
        assert(script)

        local Event = require('stdlib.event.event')

        Event.on_init(ccs_init)
        Event.on_load(ccs_init)
    end,
}
