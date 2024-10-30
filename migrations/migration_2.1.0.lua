require('lib.init')('runtime')
local const = require('lib.constants')

------------------------------------------------------------------------
-- if the circuit network was already researched when the mod was
-- installed, then activate the recipe right away.
--
-- fixes installs that ran the 2.0.0 migration but skipped it because
-- of a wrong check.
------------------------------------------------------------------------

for _, force in pairs(game.forces) do
    if force.technologies['circuit-network'].researched then
        force.recipes[const.filter_combinator_name].enabled = true
    end
end
