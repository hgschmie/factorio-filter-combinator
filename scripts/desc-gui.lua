------------------------------------------------------------------------
-- Filter combinator description editor
------------------------------------------------------------------------

assert(script)

local Event = require('stdlib.event.event')
local Player = require('stdlib.event.player')

local const = require('lib.constants')

---@class FilterCombinatorDescGui
local Gui = {
    NAME = 'combinator-description-gui',
}

----------------------------------------------------------------------------------------------------
-- UI definition
----------------------------------------------------------------------------------------------------

--- Provides all the events used by the GUI and their mappings to functions. This must be outside the
--- GUI definition as it can not be serialized into storage.
---@return framework.gui_manager.event_definition
local function get_gui_event_definition()
    return {
        events = {
            onWindowClosed = Gui.onWindowClosed,
            onReturnToMain = Gui.onReturnToMain,
            onConfirmDescription = Gui.onConfirmDescription,
            onDescriptionChanged = Gui.onDescriptionChanged,
        },
        cleanup = function(gui)
            local button = gui.context.button
            if button and button.valid then button.toggled = false end
            return false
        end,
        custominput_events = {
            [defines.events.on_gui_closed] = {
                [const.custom_input_confirm_gui] = Gui.onConfirmDescription,
                [const.custom_input_toggle_menu] = Gui.onReturnToMain,
            },
        },
    }
end

--- Returns the definition of the GUI. All events must be mapped onto constants from the gui_events array.
---@param gui framework.gui
---@return framework.gui.element_definition ui
function Gui.getUi(gui)
    local gui_events = gui.gui_events

    return {
        type = 'frame',
        name = 'gui_root',
        direction = 'vertical',
        handler = { [defines.events.on_gui_closed] = gui_events.onWindowClosed },
        elem_mods = { auto_center = true },
        style_mods = {
            width = 400,
            height = 300,
        },
        children = {
            { -- Title Bar
                type = 'flow',
                style = 'frame_header_flow',
                drag_target = 'gui_root',
                children = {
                    {
                        type = 'label',
                        style = 'frame_title',
                        caption = { '', { 'gui-edit-label.edit-description' }, ' - ', { 'entity-name.' .. const.filter_combinator_name } },
                        drag_target = 'gui_root',
                        ignored_by_interaction = true,
                    },
                    {
                        type = 'empty-widget',
                        style = 'framework_titlebar_drag_handle',
                        ignored_by_interaction = true,
                    },
                    {
                        type = 'sprite-button',
                        style = 'frame_action_button',
                        sprite = 'utility/close',
                        hovered_sprite = 'utility/close_black',
                        clicked_sprite = 'utility/close_black',
                        mouse_button_filter = { 'left' },
                        tooltip = { 'gui.cancel-instruction' },
                        handler = { [defines.events.on_gui_click] = gui_events.onReturnToMain },
                    },
                },
            }, -- Title Bar End
            {  -- Body
                type = 'flow',
                direction = 'vertical',
                style_mods = {
                    vertically_stretchable = true,
                },
                children = {
                    {
                        type = 'text-box',
                        name = 'description',
                        text = gui.context.description,
                        icon_selector = true,
                        style_mods = {
                            horizontally_stretchable = true,
                            horizontally_squashable = true,
                            vertically_stretchable = true,
                            vertically_squashable = true,
                            width = 376,
                            natural_height = 200,
                        },
                        handler = { [defines.events.on_gui_text_changed] = gui_events.onDescriptionChanged },
                    },
                    {
                        type = 'flow',
                        direction = 'horizontal',
                        style_mods = { vertically_stretchable = false },
                        children = {
                            {
                                type = 'empty-widget',
                                style = 'draggable_space',
                                style_mods = {
                                    horizontally_stretchable = true,
                                    vertically_stretchable = true,
                                },
                            },
                            {
                                type = 'button',
                                style = 'confirm_button',
                                caption = { 'gui-edit-label.save-description' },
                                mouse_button_filter = { 'left' },
                                handler = { [defines.events.on_gui_click] = gui_events.onConfirmDescription },
                            },
                        },
                    },
                },
            }, -- Body End
        },
    }
end

----------------------------------------------------------------------------------------------------
-- UI callbacks
----------------------------------------------------------------------------------------------------

---@param event EventData.on_gui_closed
---@param gui framework.gui
function Gui.onWindowClosed(event, gui)
    Framework.gui_manager:destroyGuiByPlayer(event.player_index)
end

---@param event EventData.on_gui_click|framework.gui.custominput_data
---@param gui framework.gui
function Gui.onReturnToMain(event, gui)
    Framework.gui_manager:destroyGui(event.player_index, gui.type)

    local main_gui = Framework.gui_manager:findGui(event.player_index, This.gui.NAME)
    if main_gui and main_gui.root and main_gui.root.valid then
        local player = Player.get(event.player_index)
        if player then player.opened = main_gui.root end
    else
        Framework.gui_manager:destroyGuiByPlayer(event.player_index)
    end
end

---@param event EventData.on_gui_click|framework.gui.custominput_data
---@param gui framework.gui
function Gui.onConfirmDescription(event, gui)
    ---@type filter_combinator.DescGuiContext
    local context = gui.context

    local entity = context.entity
    if entity and entity.valid then
        entity.combinator_description = context.description
    end

    Gui.onReturnToMain(event, gui)
end

---@param event EventData.on_gui_text_changed
---@param gui framework.gui
function Gui.onDescriptionChanged(event, gui)
    gui.context.description = event.text
end

----------------------------------------------------------------------------------------------------
-- Open/close
----------------------------------------------------------------------------------------------------

---@class filter_combinator.DescGuiContext
---@field entity LuaEntity
---@field description string
---@field button LuaGuiElement

---@param player LuaPlayer
---@param entity LuaEntity
---@param button LuaGuiElement
function Gui.openGui(player, entity, button)
    ---@type filter_combinator.DescGuiContext
    local gui_context = {
        entity = entity,
        description = entity.combinator_description,
        button = button,
    }

    local gui = Framework.gui_manager:createGui {
        type = Gui.NAME,
        player_index = player.index,
        parent = player.gui.screen,
        ui_tree_provider = Gui.getUi,
        context = gui_context,
        entity_id = entity.unit_number,
        retain_open_guis = true,
    }

    player.opened = gui.root

    local description = assert(gui:findElement('description'))
    description.focus()
end

---@param player_index integer
function Gui.closeGui(player_index)
    Framework.gui_manager:destroyGui(player_index, Gui.NAME)
end

----------------------------------------------------------------------------------------------------
-- Event registration
----------------------------------------------------------------------------------------------------

local function init_gui()
    Framework.gui_manager:registerGuiType(Gui.NAME, get_gui_event_definition())
end

Event.on_init(init_gui)
Event.on_load(init_gui)

return Gui
