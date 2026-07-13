---@meta
----------------------------------------------------------------------------------------------------
-- class definitions
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- this.lua
----------------------------------------------------------------------------------------------------

---@class fico.Storage
---@field fc FilterCombinatorData[]
---@field count integer

---@class fico.State
---@field wires string[]
---@field dc string?
---@field filters LogisticFilter[]

----------------------------------------------------------------------------------------------------
-- filter-combinator.lua
----------------------------------------------------------------------------------------------------

---@class FilterCombinatorData
---@field main LuaEntity
---@field config FilterCombinatorConfig
---@field state fico.State
---@field comb_visible boolean
---@field entities LuaEntity[]
---@field ref table<string, LuaEntity>
