------------------------------------------------------------------------
-- Manage GUIs and GUI state -- loosely inspired by flib
------------------------------------------------------------------------
assert(script)

local Event = require('stdlib.event.event')
local table = require('stdlib.utils.table')

require('stdlib.utils.string')

local FrameworkGui = require('framework.gui')

local GUI_UPDATE_TICK_INTERVAL = 11

------------------------------------------------------------------------
-- types
------------------------------------------------------------------------

--- A handler function to invoke when receiving GUI events for this element.
---@alias framework.gui.element_handler fun(e: framework.gui.event_data, gui: framework.gui)
---@alias framework.gui.update_callback fun(gui: framework.gui): boolean
---@alias framework.gui.context table<string, any?>
---@alias framework.gui_events table<string, string>

--- Aggregate type of all possible GUI events.
---@alias framework.gui.event_data EventData.on_gui_checked_state_changed|EventData.on_gui_click|EventData.on_gui_closed|EventData.on_gui_confirmed|EventData.on_gui_elem_changed|EventData.on_gui_location_changed|EventData.on_gui_opened|EventData.on_gui_selected_tab_changed|EventData.on_gui_selection_state_changed|EventData.on_gui_switch_state_changed|EventData.on_gui_text_changed|EventData.on_gui_value_changed

---@class framework.gui_manager.create_gui
---@field player_index integer      Player Index
---@field type string GUI type
---@field parent LuaGuiElement      Parent to associate with
---@field ui_tree_provider fun(context: framework.gui): framework.gui.element_definitions
---@field existing_elements table<string, LuaGuiElement>? Optional set of existing GUI elements.
---@field context framework.gui.context? Context element
---@field entity_id integer? The entity for which a gui is created

---@class framework.gui_manager.event_definition
---@field events table<string, framework.gui.element_handler>
---@field callback framework.gui.update_callback?

---@alias framework.guis table<string, framework.gui> gui Type to actual gui element

---@class framework.gui_manager.state
---@field guis table<number, framework.guis> All registered and known guis for this manager.


---@class framework.gui_manager
---@field GUI_PREFIX string The prefix for all registered handlers and other global information.
---@field known_gui_types table<string, framework.gui_manager.event_definition>
local FrameworkGuiManager = {
    GUI_PREFIX = Framework.PREFIX .. 'gui-',
    known_gui_types = {},
}

------------------------------------------------------------------------
--
------------------------------------------------------------------------

---@type framework.gui_manager.state
local EMPTY_STATE = {
    guis = {},
}

---@return framework.gui_manager.state state Manages GUI state
function FrameworkGuiManager:state()
    local state = Framework.runtime:storage()

    ---@type framework.gui_manager.state
    state.gui_manager = state.gui_manager or EMPTY_STATE

    return state.gui_manager
end

------------------------------------------------------------------------

---@param event framework.gui.event_data
---@param gui framework.gui
local function do_dispatch(event, gui)
    ---@type LuaGuiElement
    local elem = event.element
    if not (elem and elem.valid) then return false end

    -- find the event mapping for the GUI
    local gui_type = FrameworkGuiManager.known_gui_types[gui.type]
    assert(gui_type)

    local event_handler_map = gui.event_handlers[event.name]
    assert(event_handler_map)

    local handler_id = event_handler_map[elem.name]
    if handler_id then
        -- per-element registered handler
        local event_handler = gui_type.events[handler_id]
        if not event_handler then return false end
        event_handler(event, gui)
        return true
    elseif type(elem.tags.handler) == 'table' then
        -- tag defined handler table.
        -- use per-element registered handler
        -- workaround for https://forums.factorio.com/viewtopic.php?t=130401
        handler_id = elem.tags.handler[event.name] or elem.tags.handler[tostring(event.name)]
        local event_handler = gui_type.events[handler_id]
        if not event_handler then return false end
        event_handler(event, gui)
        return true
    end
    return false
end


--- Dispatch an event to a registered gui.
---@param event framework.gui.event_data
---@return boolean handled True if an event handler was called, False otherwise.
function FrameworkGuiManager:dispatch(event)
    if not event then return false end

    -- find the GUI for the player
    local player_index = event.player_index
    local guis = self:findGuis(player_index)
    if #guis == 0 then return false end

    local called = false
    for _, gui in pairs(guis) do
        called = do_dispatch(event, gui) or called
    end

    return called
end

------------------------------------------------------------------------

--- Finds a gui based on player index and gui_type
---@param player_index integer
---@param gui_type string?
---@return framework.gui[] framework_guis
function FrameworkGuiManager:findGuis(player_index, gui_type)
    assert(player_index)

    local state = self:state()
    local guis = state.guis[player_index]
    local result = {}
    if not guis then return result end

    for _, gui in pairs(guis) do
        if not gui_type or gui.type == gui_type then
            table.insert(result, gui)
end
    end

    return result
end

---@param player_index integer
---@param gui_type string
---@return framework.gui?
function FrameworkGuiManager:findGui(player_index, gui_type)
    assert(gui_type)
    local guis = Framework.gui_manager:findGuis(player_index, gui_type)
    return #guis > 0 and guis[1] or nil
end

---@param player_index integer
---@param gui_type string
---@parameter gui framework.gui
function FrameworkGuiManager:addGui(player_index, gui_type, gui)
    assert(player_index)
    assert(gui_type)
    assert(gui)
    local state = self:state()
    state.guis[player_index] = state.guis[player_index] or {}
    assert(not state.guis[player_index][gui_type])

    state.guis[player_index][gui_type] = gui
end

---@param player_index integer
---@param gui_type string?
---@return (framework.gui)[]
function FrameworkGuiManager:clearGuis(player_index, gui_type)
    local state = self:state()
    local guis = state.guis[player_index]

    local result = {}
    if not guis then return result end

    for g_type, gui in pairs(guis) do
        if not gui_type or gui_type == g_type then
            table.insert(result, gui)
            guis[g_type] = nil
end
    end

    return result
end

---@return table<number, framework.guis>
function FrameworkGuiManager:allGuis()
    local state = self:state()
    return state.guis
end

------------------------------------------------------------------------

--- Registers a GUI type with the event table and callback with the GUI manager.
---@param gui_type string
---@param event_definition framework.gui_manager.event_definition
function FrameworkGuiManager:registerGuiType(gui_type, event_definition)
    assert(gui_type)
    assert(event_definition.events, 'events is unset!')
    assert(not self.known_gui_types[gui_type])

    self.known_gui_types[gui_type] = event_definition
end

--- Creates a new GUI instance.
---@param map framework.gui_manager.create_gui
---@return framework.gui A framework gui instance
function FrameworkGuiManager:createGui(map)
    assert(map)

    assert(map.type)
    assert(map.player_index)
    local player_index = map.player_index

    local gui_type = self.known_gui_types[map.type]

    assert(gui_type, 'No Gui definition for "' .. map.type .. '" registered!')

    -- must be set
    assert(map.parent)

    local gui = FrameworkGui.create {
        type = map.type,
        prefix = self.GUI_PREFIX,
        gui_events = table.array_to_dictionary(table.keys(gui_type.events)),
        entity_id = map.entity_id,
        player_index = map.player_index,
        context = map.context or {},
    }

    local ui_tree = map.ui_tree_provider(gui)
    -- do not change to table_size, '#' returning 0 is the whole point of the check...
    assert(type(ui_tree) == 'table' and #ui_tree == 0, 'The UI tree must have a single root!')


    self:destroyGuis(player_index, map.type)
    local root = gui:add_child_elements(map.parent, ui_tree, map.existing_elements)
    gui.root = root

    self:addGui(player_index, map.type, gui)

    self.guiUpdateTick()

    return gui
end

------------------------------------------------------------------------

---@param gui framework.gui?
local function destroy_gui(gui)
    if not gui then return end

    if gui.root then gui.root.destroy() end
    FrameworkGuiManager:clearGuis(gui.player_index, gui.type)
end

---@param entity_id integer?
function FrameworkGuiManager:destroyGuiByEntityId(entity_id)
    if not entity_id then return end

    for _, player in pairs(game.players) do
        local guis = self:findGuis(player.index)
        for _, gui in pairs(guis) do
            if gui.entity_id and gui.entity_id == entity_id then
                destroy_gui(gui)
        end
    end
    end
end

------------------------------------------------------------------------

--- Destroys a GUI instance.
---@param player_index integer
---@param gui_type string?
function FrameworkGuiManager:destroyGuis(player_index, gui_type)
    local guis = self:findGuis(player_index, gui_type)
    for _, gui in pairs(guis) do
        destroy_gui(gui)
end
end

------------------------------------------------------------------------
-- Update ticker
------------------------------------------------------------------------

function FrameworkGuiManager.guiUpdateTick()
    local guis = FrameworkGuiManager:allGuis()
    if table_size(guis) == 0 then return end

    for _, player_guis in pairs(guis) do
        for idx, gui in pairs(player_guis) do
        local gui_type = FrameworkGuiManager.known_gui_types[gui.type]
        assert(gui_type)
        if gui_type.callback then
            if not gui_type.callback(gui) then
                    player_guis[idx] = nil
                    destroy_gui(gui)
            end
        end
    end
    end
end

--------------------------------------------------------------------------------
-- event registration
--------------------------------------------------------------------------------

local function register_events()
    -- register all gui events with the framework
    for name, id in pairs(defines.events) do
        if name:starts_with('on_gui_') then
            Event.on_event(id, function(ev)
                Framework.gui_manager:dispatch(ev --[[@as framework.gui.event_data]])
            end)
        end
    end

    Event.on_nth_tick(GUI_UPDATE_TICK_INTERVAL, FrameworkGuiManager.guiUpdateTick)
end

local function on_load()
    register_events()
end

local function on_init()
    register_events()
end

Event.on_init(on_init)
Event.on_load(on_load)

return FrameworkGuiManager
