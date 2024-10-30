------------------------------------------------------------------------
-- per-player runtime settings
------------------------------------------------------------------------

---@type table<string, FrameworkSettingDefault>
local PlayerSettings = {
    -- Defaults
    comb_visible = { name = Framework.PREFIX .. 'comb-visible', default_value = false },
}

return PlayerSettings
