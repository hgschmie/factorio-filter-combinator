----------------------------------------------------------------------------------------------------
--- Initialize this mod's globals
----------------------------------------------------------------------------------------------------

---@class FilterCombinatorMod
---@field other_mods table<string, string>
---@field remote_apis table<string, string>
---@field fico FilterCombinator
---@field gui FilterCombinatorGui?
local This = {
    other_mods = {
        compaktcircuit = 'compaktcircuit',
    },
    remote_apis = {
        compaktcircuit = 'compaktcircuit',
        PickerDollies = 'picker-dollies',
    },
}

if script then
    This.fico = require('scripts.filter-combinator')
    This.gui = require('scripts.gui') --[[@as FilterCombinatorGui ]]

    if Framework.ExportedApis then
        -- use get_config(entity_id) to retrieve configuration
        Framework.ExportedApis.get_config = This.fico.getConfig
        -- use set_config(entity_id, config) to set config
        Framework.ExportedApis.set_config = This.fico.setConfig
    end
end

function This:init()
    storage.fc_data = storage.fc_data or {
        fc = {},
        count = 0,
    }
end

---@return fico.Storage
function This.storage()
    return assert(storage.fc_data)
end

return This
