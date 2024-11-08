------------------------------------------------------------------------
-- Prototypes for all internal combinators, both regular and debug mode
------------------------------------------------------------------------

local const = require('lib.constants')

local collision_mask_util = require('collision-mask-util')

local combinator_flags = {
    'placeable-off-grid',
    'not-repairable',
    'not-on-map',
    'not-deconstructable',
    'not-blueprintable',
    'hide-alt-info',
    'not-flammable',
    'not-upgradable',
    'not-in-kill-statistics',
    'not-in-made-in',
}

---@param source data.CombinatorPrototype
---@param name string
---@return data.CombinatorPrototype combinator
local function create_combinator(source, name)
    local c = util.copy(source)

    -- PrototypeBase
    c.name = name

    -- CombinatorPrototype
    c.energy_source = { type = 'void' }
    c.active_energy_usage = '0.001W'
    c.sprites = util.empty_sprite()
    c.activity_led_sprites = util.empty_sprite()
    c.activity_led_light_offsets = { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
    c.activity_led_light = nil
    c.draw_circuit_wires = false
    c.draw_copper_wires = false

    -- EntityPrototype
    c.allow_copy_paste = false
    c.collision_box = nil
    c.collision_mask = collision_mask_util.new_mask()
    c.flags = combinator_flags
    c.hidden = true
    c.hidden_in_factoriopedia = true
    c.minable = nil
    c.selection_box = nil
    c.selectable_in_game = false
    return c
end

--------------------------------------------------------------------------------

local dc = create_combinator(data.raw['decider-combinator']['decider-combinator'], const.internal_dc_name) --[[@as data.DeciderCombinatorPrototype ]]
dc.greater_symbol_sprites = util.empty_sprite()
dc.greater_or_equal_symbol_sprites = util.empty_sprite()
dc.less_symbol_sprites = util.empty_sprite()
dc.equal_symbol_sprites = util.empty_sprite()
dc.not_equal_symbol_sprites = util.empty_sprite()
dc.less_or_equal_symbol_sprites = util.empty_sprite()

--------------------------------------------------------------------------------

local ac = create_combinator(data.raw['arithmetic-combinator']['arithmetic-combinator'], const.internal_ac_name) --[[@as data.ArithmeticCombinatorPrototype ]]
ac.plus_symbol_sprites = util.empty_sprite()
ac.minus_symbol_sprites = util.empty_sprite()
ac.multiply_symbol_sprites = util.empty_sprite()
ac.divide_symbol_sprites = util.empty_sprite()
ac.modulo_symbol_sprites = util.empty_sprite()
ac.power_symbol_sprites = util.empty_sprite()
ac.left_shift_symbol_sprites = util.empty_sprite()
ac.right_shift_symbol_sprites = util.empty_sprite()
ac.and_symbol_sprites = util.empty_sprite()
ac.or_symbol_sprites = util.empty_sprite()
ac.xor_symbol_sprites = util.empty_sprite()

--------------------------------------------------------------------------------

local cc = util.copy(data.raw['constant-combinator']['constant-combinator']) --[[@as data.ConstantCombinatorPrototype]]

-- PrototypeBase
cc.name = const.internal_cc_name

-- ConstantCombinatorPrototype
cc.sprites = util.empty_sprite()
cc.activity_led_sprites = util.empty_sprite()
cc.activity_led_light_offsets = { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
cc.activity_led_light = nil
cc.draw_circuit_wires = false
cc.draw_copper_wires = false

-- EntityPrototype
cc.allow_copy_paste = false
cc.collision_box = nil
cc.collision_mask = collision_mask_util.new_mask()
cc.selection_box = nil
cc.flags = combinator_flags
cc.hidden = true
cc.hidden_in_factoriopedia = true
cc.minable = nil
cc.selection_box = nil
cc.selectable_in_game = false

-- PrototypeBase

-- for debugging, add a tint to make them more visible
local debug_ac = util.copy(data.raw['arithmetic-combinator']['arithmetic-combinator']) --[[@as data.ArithmeticCombinatorPrototype]]
debug_ac.name = const.internal_debug_ac_name
debug_ac.hidden_in_factoriopedia = true

local debug_cc = util.copy(data.raw['constant-combinator']['constant-combinator']) --[[@as data.ConstantCombinatorPrototype]]
debug_cc.name = const.internal_debug_cc_name
debug_cc.hidden_in_factoriopedia = true

local debug_dc = util.copy(data.raw['decider-combinator']['decider-combinator']) --[[@as data.DeciderCombinatorPrototype]]
debug_dc.name = const.internal_debug_dc_name
debug_dc.hidden_in_factoriopedia = true

local tint = { r = 0, g = 0.8, b = 0.6, a = 1}
for _, directions in pairs({'north', 'south','east','west'}) do
    debug_ac.sprites[directions].layers[1].tint = tint
    debug_cc.sprites[directions].layers[1].tint = tint
    debug_dc.sprites[directions].layers[1].tint = tint
end

data:extend { ac, cc, dc, debug_ac, debug_cc, debug_dc }
