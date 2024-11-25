----------------------------------------------------------------------------------------------------
--- Initialize this mod's globals
----------------------------------------------------------------------------------------------------

---@class FicoModThis
---@field other_mods table<string, string>
---@field fico FilterCombinator
---@field gui ModGui?
local This = {
    other_mods = {
        framework = 'framework',
        nullius = 'nullius',
        compaktcircuit = 'compaktcircuit',
        PickerDollies = 'PickerDollies',
        ['even-pickier-dollies'] = 'PickerDollies',
    },
    fico = require('scripts.filter-combinator'),
    gui = nil,
}

function This:this_runtime()
    if script then
        This.gui = This.gui or require('scripts.gui') --[[@as ModGui ]]
    end
end

----------------------------------------------------------------------------------------------------

return function(stage)
    if This['this_' .. stage] then
        This['this_' .. stage](This)
    end

    return This
end
