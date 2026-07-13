This, Framework = require('lib.init')()

-- add state field
for _, fc_entity in pairs(This.fico:entities()) do
    fc_entity.state = fc_entity.state or {
        wires = {},
        filters = {},
    }

    fc_entity.config.filters = fc_entity.config.filters or {}

    This.fico:reconfigure(fc_entity)
end
