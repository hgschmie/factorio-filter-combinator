require('lib.init')
local const = require('lib.constants')

------------------------------------------------------------------------
-- if the circuit network was already researched when the mod was
-- installed, then activate the recipe right away.
------------------------------------------------------------------------

if storage.fc_data and storage.fc_data.VERSION >= const.current_version  then return end

storage.fc_data.VERSION = const.current_version

for _, force in pairs(game.forces) do
    if force.technologies['circuit-network'].researched then
        force.recipes[const.filter_combinator_name].enabled = true
    end
end
