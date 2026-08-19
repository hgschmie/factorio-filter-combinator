------------------------------------------------------------------------
-- mod constant definitions.
--
-- can be loaded into scripts and data
------------------------------------------------------------------------

local Constants = {
    prefix = 'hps__fc-',
    log_prefix = 'FiCo',
    name = 'filter-combinator',
    root = '__filter-combinator-improved__',
    order = 'c[combinators]-cf[filter-combinator-improved]',
    config_tag_name = 'fc_config'
}

Constants.name_packed = Constants.name .. '-packed' -- for compakt circuits
Constants.gfx_location = Constants.root .. '/graphics/'

--------------------------------------------------------------------------------
-- main constants
--------------------------------------------------------------------------------


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
-- data helper
--------------------------------------------------------------------------------

Constants.ac_sprites = {
    'plus_symbol_sprites',
    'minus_symbol_sprites',
    'multiply_symbol_sprites',
    'divide_symbol_sprites',
    'modulo_symbol_sprites',
    'power_symbol_sprites',
    'left_shift_symbol_sprites',
    'right_shift_symbol_sprites',
    'and_symbol_sprites',
    'or_symbol_sprites',
    'xor_symbol_sprites',
}

--------------------------------------------------------------------------------
-- entity names and maps
--------------------------------------------------------------------------------

-- Base name
Constants.filter_combinator_name = Constants:with_prefix(Constants.name)

-- Compactcircuits support
Constants.filter_combinator_name_packed = Constants:with_prefix(Constants.name_packed)

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
-- GUI input handling
--------------------------------------------------------------------------------

Constants.custom_input_toggle_menu = Constants:with_prefix('toggle-menu')
Constants.custom_input_confirm_gui = Constants:with_prefix('confirm-gui')
Constants.custom_input_ignore_close = Constants:with_prefix('ignore-close')

--------------------------------------------------------------------------------
return Constants
