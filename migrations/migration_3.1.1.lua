require('lib.init')('runtime')
local const = require('lib.constants')

if storage.fc_data and storage.fc_data.VERSION >= const.current_version then return end

for main_unit_number, fc_entity in pairs(This.fico:entities()) do
    for name, sub_entity in pairs(fc_entity.ref) do
        -- destroy all but the main entity
        if name ~= 'main' then
            fc_entity.entities[sub_entity.unit_number] = nil
            fc_entity.ref[name] = nil
            sub_entity.destroy()
        end
    end
    -- recreate all the sub entities again
    This.fico:create_sub_entities(fc_entity)

    -- reconfigure to current config
    This.fico:reconfigure(fc_entity)
end

storage.all_signals = nil

storage.fc_data.VERSION = const.current_version
