------------------------------------------------------------------------
-- mod constant definitions.
--
-- can be loaded into scripts and data
------------------------------------------------------------------------

local Constants = {}

--------------------------------------------------------------------------------
-- main constants
--------------------------------------------------------------------------------

-- the current version that is the result of the latest migration
Constants.current_version = 8

Constants.prefix = 'hps:fc-'
Constants.name = 'filter-combinator'
Constants.root = '__filter-combinator-improved__'
Constants.gfx_location = Constants.root .. '/graphics/'

--------------------------------------------------------------------------------
-- Framework intializer
--------------------------------------------------------------------------------

---@return FrameworkConfig config
function Constants.framework_init()
    return {
        -- prefix is the internal mod prefix
        prefix = Constants.prefix,
        -- name is a human readable name
        name = Constants.name,
        -- The filesystem root.
        root = Constants.root,
        -- Remote interface name
        remote_name = Constants.filter_combinator_name,
    }
end

--------------------------------------------------------------------------------
-- Path and name helpers
--------------------------------------------------------------------------------

---@param value string
---@return string result
function Constants:with_prefix(value)
    return self.prefix .. value
end

---@param path string
---@return string result
function Constants:png(path)
    return self.gfx_location .. path .. '.png'
end

---@param id string
---@return string result
function Constants:locale(id)
    return Constants:with_prefix('gui.') .. id
end

--------------------------------------------------------------------------------
-- entity names and maps
--------------------------------------------------------------------------------

-- Base name
Constants.filter_combinator_name = Constants:with_prefix(Constants.name)

-- Compactcircuits support
Constants.filter_combinator_name_packed = Constants:with_prefix('filter-combinator-packed')

Constants.main_entity_names = {
    Constants.filter_combinator_name, Constants.filter_combinator_name_packed,
}

-- Internal entities in normal and debug mode
Constants.internal_ac_name = Constants:with_prefix('filter-combinator-ac')
Constants.internal_cc_name = Constants:with_prefix('filter-combinator-cc')
Constants.internal_dc_name = Constants:with_prefix('filter-combinator-dc')
Constants.internal_debug_ac_name = Constants:with_prefix('filter-combinator-debug-ac')
Constants.internal_debug_cc_name = Constants:with_prefix('filter-combinator-debug-cc')
Constants.internal_debug_dc_name = Constants:with_prefix('filter-combinator-debug-dc')

Constants.entity_maps = {
    standard = { ac = Constants.internal_ac_name, cc = Constants.internal_cc_name, dc = Constants.internal_dc_name, },
    debug = { ac = Constants.internal_debug_ac_name, dc = Constants.internal_debug_dc_name, cc = Constants.internal_debug_cc_name, }
}

-- all internal entities
Constants.internal_entity_names = {
    Constants.internal_ac_name, Constants.internal_cc_name, Constants.internal_dc_name,
    Constants.internal_debug_ac_name, Constants.internal_debug_cc_name, Constants.internal_debug_dc_name,
}

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

Constants.creation_events = {
    defines.events.on_built_entity,
    defines.events.on_robot_built_entity,
    defines.events.script_raised_built,
    defines.events.script_raised_revive,
}

Constants.deletion_events = {
    defines.events.on_player_mined_entity,
    defines.events.on_robot_mined_entity,
    defines.events.on_entity_died,
    defines.events.script_raised_destroy,
}

--------------------------------------------------------------------------------
-- localization
--------------------------------------------------------------------------------

Constants.fc_entity_name = 'entity-name.' .. Constants.filter_combinator_name

--------------------------------------------------------------------------------
return Constants
