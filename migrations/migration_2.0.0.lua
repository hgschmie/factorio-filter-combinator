This, Framework = require('lib.init')()

local const = require('lib.constants')

------------------------------------------------------------------------
-- if the circuit network was already researched when the mod was
-- installed, then activate the recipe right away.
------------------------------------------------------------------------

for _, force in pairs(game.forces) do
    if force.technologies['circuit-network'].researched then
        force.recipes[const.filter_combinator_name].enabled = true
    end
end
