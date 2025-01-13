require('lib.init')

local const = require('lib.constants')

data:extend({
    {
        -- Debug mode (framework dependency)
        setting_type = "runtime-global",
        name = Framework.PREFIX .. 'debug-mode',
        type = "bool-setting",
        default_value = false,
        order = "z"
    },
})

--------------------------------------------------------------------------------

Framework.post_settings_stage()
