This, Framework = require('lib.init')()

local const = require('lib.constants')

data:extend({
    {
        -- Debug mode (framework dependency)
        type = 'string-setting',
        name = Framework.PREFIX .. 'debug-mode',
        order = 'az',
        setting_type = 'startup',
        default_value = '0',
        allowed_values = { '0', '1', '2', '3' },
    },
})

--------------------------------------------------------------------------------

---@diagnostic disable-next-line: undefined-field
Framework.post_settings_stage()
