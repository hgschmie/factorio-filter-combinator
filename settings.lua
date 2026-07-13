This, Framework = require('lib.init')()

local const = require('lib.constants')

data:extend({
    {
        -- Debug mode (framework dependency)
        setting_type = "startup",
        name = Framework.PREFIX .. 'debug-mode',
        type = "bool-setting",
        default_value = false,
        order = "z"
    },
})

--------------------------------------------------------------------------------

---@diagnostic disable-next-line: undefined-field
Framework.post_settings_stage()
