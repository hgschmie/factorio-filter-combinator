----------------------------------------------------------------------------------------------------
--- Global definitions included in all phases
----------------------------------------------------------------------------------------------------

-- mod code
local this = require('lib.this')

-- Framework core
local framework = require('framework.init')
framework:init(this.framework_init)

-- mod code
local this = require('lib.this')

return function()
    return this, framework
end
