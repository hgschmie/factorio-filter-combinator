require('lib.init')

local const = require('lib.constants')

-- explicitly remove group information from control sections
for _, fc_entity in pairs(This.fico:entities()) do
    if fc_entity.ref.signals then
        local control_behavior = fc_entity.ref.signals.get_or_create_control_behavior() --[[ @as LuaConstantCombinatorControlBehavior ]]
        if control_behavior then
            for i = 1, control_behavior.sections_count, 1 do
                control_behavior.sections[i].group = ''
            end
        end
    end
end
