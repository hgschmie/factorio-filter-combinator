----------------------------------------------------------------------------------------------------
--- Initialize this mod's globals
----------------------------------------------------------------------------------------------------

---@class ModThis
---@field other_mods string[]
---@field fico FilterCombinator
---@field gui ModGui?
local This = {
    other_mods = { 'nullius', 'framework', 'compaktcircuit', 'PickerDollies' },
    fico = require('scripts.filter-combinator'),
    gui = nil,
}

Framework.settings:add_startup(require('scripts.settings-startup'))
Framework.settings:add_player(require('scripts.settings-player'))

if (script) then
    This.gui = require('scripts.gui') --[[@as ModGui ]]
end

----------------------------------------------------------------------------------------------------

return This
