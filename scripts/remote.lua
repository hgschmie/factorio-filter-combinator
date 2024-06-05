------------------------------------------------------------------------
-- Remote API
------------------------------------------------------------------------
require('lib.init')

local const = require('lib.constants')
local table = require('__stdlib__/stdlib/utils/table')

---@param entity_id integer
---@return FilterCombinatorConfig? config
local function get_config(entity_id)
    local fc_entity = This.fico:entity(entity_id)
    if not fc_entity then return nil end

    return fc_entity.config
end

---@param entity_id integer
---@param config FilterCombinatorConfig
local function set_config(entity_id, config)
    local fc_entity = This.fico:entity(entity_id)
    if not fc_entity then return end

    fc_entity.config = table.deepcopy(config)
    This.fico:reconfigure(fc_entity)
end

if Framework.remote_api then
    -- use get_config(entity_id) to retrieve configuration
    Framework.remote_api.get_config = get_config
    -- use set_config(entity_id, config) to set config
    Framework.remote_api.set_config = set_config
end
