require('lib.init')('runtime')
local const = require('lib.constants')

if storage.fc_data and storage.fc_data.VERSION >= const.current_version then return end

for main_unit_number, fc_entity in pairs(This.fico:entities()) do
    if not fc_entity.ref.main.valid then
        This.fico:destroy(main_unit_number)
    else
        for name, sub_entity in pairs(fc_entity.ref) do
            -- destroy all but the main entity
            if name ~= 'main' then
                fc_entity.entities[sub_entity.unit_number] = nil
                fc_entity.ref[name] = nil
                sub_entity.destroy()
            end
        end

        if fc_entity.config.signals then
            -- migrate old config
            local filters = {}
            for _, signal in pairs(fc_entity.config.signals) do
                if signal.signal then
                    -- only add signals that actually exist
                    local type = signal.signal.type == 'virtual' and 'virtual_signal' or signal.type
                    if prototypes[type][signal.name] then
                        ---@type LogisticFilter
                        local filter = {
                            value = { name = signal.signal.name, type = signal.signal.type, quality = 'normal' },
                            min = 1,
                        }
                        table.insert(filters, filter)
                    end
                end
            end
            fc_entity.config.signals = nil
            fc_entity.config.filters = filters
        end

        -- recreate all the sub entities again
        This.fico:create_sub_entities(fc_entity)

        -- reconfigure to current config
        This.fico:reconfigure(fc_entity)
    end
end

storage.all_signals = nil

storage.fc_data.VERSION = const.current_version
