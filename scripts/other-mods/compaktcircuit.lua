--------------------------------------------------------------------------------
-- CompactCircuit (https://mods.factorio.com/mod/compaktcircuit) support
--------------------------------------------------------------------------------

local const = require('lib.constants')
local Is = require('stdlib.utils.is')
local tools = require('framework.tools')

local CompaktCircuitSupport = {}

--------------------------------------------------------------------------------

---@param entity LuaEntity
local function ccs_get_info(entity)
    if not Is.Valid(entity) then return end

    local fc_entity = This.fico:entity(entity.unit_number)
    if not fc_entity then return end

    return {
        fc_config = fc_entity.config
    }
end

---@param surface LuaSurface
---@param position MapPosition
---@param force LuaForce
local function ccs_create_packed_entity(info, surface, position, force)
    local packed_main = surface.create_entity {
        name = const.filter_combinator_name_packed,
        position = position,
        force = force,
        direction = info.direction,
        raise_built = false,
    }

    assert(packed_main)
    script.register_on_object_destroyed(packed_main)

    local fc_entity = This.fico:create(packed_main, nil, info)
    assert(fc_entity)

    return packed_main
end

---@param surface LuaSurface
---@param force LuaForce
local function ccs_create_entity(info, surface, force)
    local main = surface.create_entity {
        name = const.filter_combinator_name,
        position = info.position,
        force = force,
        direction = info.direction,
        raise_built = false
    }

    assert(main)
    script.register_on_object_destroyed(main)

    local fc_entity = This.fico:create(main, nil, info)
    assert(fc_entity)

    return main
end

--------------------------------------------------------------------------------

local function ccs_init()
    if not Framework.remote_api then return end
    if not (remote.interfaces['compaktcircuit'] and remote.interfaces['compaktcircuit']['add_combinator']) then return end

    Framework.remote_api.get_info = ccs_get_info
    Framework.remote_api.create_packed_entity = ccs_create_packed_entity
    Framework.remote_api.create_entity = ccs_create_entity

    remote.call('compaktcircuit', 'add_combinator', {
        name = const.filter_combinator_name,
        packed_names = { const.filter_combinator_name_packed },
        interface_name = const.filter_combinator_name,
    })
end

--------------------------------------------------------------------------------

function CompaktCircuitSupport.data()
    local collision_mask_util = require('collision-mask-util')

    local packed = tools.copy(data.raw['arithmetic-combinator'][const.filter_combinator_name])

    -- PrototypeBase
    packed.name = const.filter_combinator_name_packed

    -- ArithmeticCombinatorPrototype
    packed.plus_symbol_sprites = util.empty_sprite()
    packed.minus_symbol_sprites = util.empty_sprite()
    packed.multiply_symbol_sprites = util.empty_sprite()
    packed.divide_symbol_sprites = util.empty_sprite()
    packed.modulo_symbol_sprites = util.empty_sprite()
    packed.power_symbol_sprites = util.empty_sprite()
    packed.left_shift_symbol_sprites = util.empty_sprite()
    packed.right_shift_symbol_sprites = util.empty_sprite()
    packed.and_symbol_sprites = util.empty_sprite()
    packed.or_symbol_sprites = util.empty_sprite()
    packed.xor_symbol_sprites = util.empty_sprite()

    -- CombinatorPrototype
    packed.sprites = util.empty_sprite()
    packed.activity_led_light_offsets = { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    packed.activity_led_sprites = util.empty_sprite()
    packed.draw_circuit_wires = false

    -- turn off the flashing icons
    packed.energy_source.render_no_network_icon = false
    packed.energy_source.render_no_power_icon = false

    -- EntityPrototype
    packed.collision_box = nil
    packed.collision_mask = collision_mask_util.new_mask()
    packed.selection_box = nil
    packed.flags = {
        'placeable-off-grid',
        'not-repairable',
        'not-on-map',
        'not-deconstructable',
        'not-blueprintable',
        'hide-alt-info',
        'not-flammable',
        'not-upgradable',
        'not-in-kill-statistics',
        'not-in-made-in'
    }

    packed.allow_copy_paste = false
    packed.hidden = true
    packed.hidden_in_factoriopedia = true
    packed.minable = nil
    packed.selection_box = nil
    packed.selectable_in_game = false

    data:extend { packed }
end


function CompaktCircuitSupport.runtime()
    local Event = require('stdlib.event.event')

    Event.on_init(ccs_init)
    Event.on_load(ccs_init)
end

return CompaktCircuitSupport
