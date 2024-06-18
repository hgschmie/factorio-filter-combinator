------------------------------------------------------------------------
-- Prototype for the actual filter combinator
------------------------------------------------------------------------

local const = require('lib.constants')

local function update_sprite(sprite, filename, x, y)
    sprite.filename = const:png(filename)
    sprite.x = x or 0
    sprite.y = y or 0
end

local fc = table.deepcopy(data.raw['arithmetic-combinator']['arithmetic-combinator']) --[[@as data.ArithmeticCombinatorPrototype ]]

local sprite_h = table.deepcopy(fc.and_symbol_sprites.north)
update_sprite(sprite_h, 'filter-combinator-improved-display')
update_sprite(sprite_h.hr_version, 'hr-filter-combinator-improved-display')

local sprite_v = table.deepcopy(fc.and_symbol_sprites.east)
update_sprite(sprite_v, 'filter-combinator-improved-display')
update_sprite(sprite_v.hr_version, 'hr-filter-combinator-improved-display')

local full_sprite = { east = sprite_v, west = sprite_v, north = sprite_h, south = sprite_h }

-- PrototypeBase
fc.name = const.filter_combinator_name

-- ArithmeticCombinatorPrototype
fc.plus_symbol_sprites = full_sprite
fc.minus_symbol_sprites = full_sprite
fc.multiply_symbol_sprites = full_sprite
fc.divide_symbol_sprites = full_sprite
fc.modulo_symbol_sprites = full_sprite
fc.power_symbol_sprites = full_sprite
fc.left_shift_symbol_sprites = full_sprite
fc.right_shift_symbol_sprites = full_sprite
fc.and_symbol_sprites = full_sprite
fc.or_symbol_sprites = full_sprite
fc.xor_symbol_sprites = full_sprite

-- EntityPrototype
fc.icon = const:png('filter-combinator-improved')
fc.minable.result = fc.name

data:extend { fc }
