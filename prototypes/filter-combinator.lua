------------------------------------------------------------------------
-- Prototype for the actual filter combinator
------------------------------------------------------------------------

local const = require('lib.constants')
local data_util = require('framework.prototypes.data-util')

local ac_sprites = {
    'plus_symbol_sprites',
    'minus_symbol_sprites',
    'multiply_symbol_sprites',
    'divide_symbol_sprites',
    'modulo_symbol_sprites',
    'power_symbol_sprites',
    'left_shift_symbol_sprites',
    'right_shift_symbol_sprites',
    'and_symbol_sprites',
    'or_symbol_sprites',
    'xor_symbol_sprites',
}

local function update_sprite(sprite, filename, x, y)
    sprite.filename = const:png(filename)
    sprite.x = x or 0
    sprite.y = y or 0
end

local fc = util.copy(data.raw['arithmetic-combinator']['arithmetic-combinator']) --[[@as data.ArithmeticCombinatorPrototype ]]

local sprite_h = util.copy(fc.and_symbol_sprites.north)
update_sprite(sprite_h, 'hr-filter-combinator-improved-display')

local sprite_v = util.copy(fc.and_symbol_sprites.east)
update_sprite(sprite_v, 'hr-filter-combinator-improved-display')

local full_sprite = { east = sprite_v, west = sprite_v, north = sprite_h, south = sprite_h }

-- PrototypeBase
fc.name = const.filter_combinator_name

-- ArithmeticCombinatorPrototype
for _, field in pairs(ac_sprites) do
    fc[field] = full_sprite
end

-- EntityPrototype
fc.icon = const:png('filter-combinator-improved')
fc.minable.result = fc.name

data:extend { fc }

-- add packed entity here as well, otherwise some constants that refer to the unpacked and
-- packed entity will cause the mod to crash if compaktcircuits was not loaded

local fc_packed = data_util.copy_prototype(fc, const.filter_combinator_name_packed, true) --[[@as data.ArithmeticCombinatorPrototype ]]

-- ArithmeticCombinatorPrototype
for _, field in pairs(ac_sprites) do
    fc_packed[field] = util.empty_sprite()
end

data:extend { fc_packed }
