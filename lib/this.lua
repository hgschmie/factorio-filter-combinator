----------------------------------------------------------------------------------------------------
--- Initialize this mod's globals
----------------------------------------------------------------------------------------------------

---@class FilterCombinatorMod
---@field other_mods table<string, string>
---@field fico FilterCombinator
---@field gui FilterCombinatorGui?
This = {
    other_mods = {
        compaktcircuit = 'compaktcircuit',
        PickerDollies = 'PickerDollies',
        ['even-pickier-dollies'] = 'PickerDollies',
    },
}

if script then
    This.fico = require('scripts.filter-combinator')
    This.gui = require('scripts.gui') --[[@as FilterCombinatorGui ]]

    -- setup remote interface
    require('scripts.remote')
end

return This
