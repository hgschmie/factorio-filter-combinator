----------------------------------------------------------------------------------------------------
--- Initialize this mod's globals
----------------------------------------------------------------------------------------------------

---@class FilterCombinatorMod
---@field other_mods table<string, string>
---@field fico FilterCombinator
---@field gui ModGui?
local This = {
    other_mods = {
        framework = 'framework',
        compaktcircuit = 'compaktcircuit',
        PickerDollies = 'PickerDollies',
        ['even-pickier-dollies'] = 'PickerDollies',
    },
}

if script then
    This.fico = require('scripts.filter-combinator')
    This.gui = require('scripts.gui') --[[@as ModGui ]]
end

return This
