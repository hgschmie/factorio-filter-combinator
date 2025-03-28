------------------------------------------------------------------------
-- Prototype for the actual filter combinator
------------------------------------------------------------------------

local const = require('lib.constants')

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
for _, field in pairs(const.ac_sprites) do
    fc[field] = full_sprite
end

-- EntityPrototype
fc.icon = const:png('filter-combinator-improved')
fc.minable.result = fc.name

data:extend { fc }
