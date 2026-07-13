This, Framework = require('lib.init')()

-- add state field
for entity_id, fc_entity in pairs(This.fico:entities()) do
    if fc_entity.main and fc_entity.main.valid then
        fc_entity.state = fc_entity.state or {
            wires = {},
            filters = {},
        }

        fc_entity.config.filters = fc_entity.config.filters or {}

        This.fico:reconfigure(fc_entity)
    else
        This.fico:destroy(entity_id)
    end
end
