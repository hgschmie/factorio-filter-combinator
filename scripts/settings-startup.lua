------------------------------------------------------------------------
-- global startup settings
------------------------------------------------------------------------

---@type table<string, FrameworkSettingDefault>
local StartupSettings = {
  -- Defaults
  empty_slots = { name = Framework.PREFIX .. "empty-slots", default_value = 40 },
}

return StartupSettings
