require('lib.init')('settings')

data:extend({
      {
         name = Framework.PREFIX .. 'empty-slots',
         type = 'int-setting',
         setting_type = 'startup',
         order = 'a',
         default_value = 20,
         minimum_value = 10,
         maximum_value = 600
      },
      {
         -- Debug mode (framework dependency)
         setting_type = "runtime-global",
         name = Framework.PREFIX .. 'debug-mode',
         type = "bool-setting",
         default_value = false,
         order = "z"
      },
      {
         -- make internal units visible
         setting_type = "runtime-per-user",
         name = Framework.PREFIX .. 'comb-visible',
         type = "bool-setting",
         default_value = false,
         order = "b"
      },
})

--------------------------------------------------------------------------------

require('framework.other-mods').settings()
