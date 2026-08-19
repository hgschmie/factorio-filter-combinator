----------------------------------------------------------------------------------------------------
--- Global definitions included in all phases
----------------------------------------------------------------------------------------------------

-- mod code
local this = require('lib.this')

-- Framework core
local framework = require('framework.init')
framework:init(this.framework_init)

if script then
    this.boot()
end

return function()
    return this, framework
end
