--------------------------------------------------------------------------------
-- Framework test module
--
-- activate in This.mod.other_mods to show execution of the various phases.
--
--------------------------------------------------------------------------------

local FrameworkSupport = {}

FrameworkSupport.settings = function()
    Framework.logger:log('Settings stage for additional modules called!')
end

FrameworkSupport.data = function()
    Framework.logger:log('Data stage for additional modules called!')
end

FrameworkSupport.data_updates = function()
    Framework.logger:log('Data Updates stage for additional modules called!')
end

FrameworkSupport.data_final_fixes = function()
    Framework.logger:log('Data Final Fixes stage for additional modules called!')
end

FrameworkSupport.runtime = function()
    Framework.logger:log('Runtime stage for additional modules called!')
end

return FrameworkSupport
