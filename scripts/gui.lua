------------------------------------------------------------------------
-- Filter combinator GUI
------------------------------------------------------------------------

local Event = require('stdlib.event.event')
local Player = require('stdlib.event.player')
local table = require('stdlib.utils.table')

local tools = require('framework.tools')

local const = require('lib.constants')

---@class ModGui
local ModGui = {}

-- callback predefines
local onWindowClosed, onSwitchEnabled, onSwitchExclusive, onToggleWireMode, onSwitchRedWire, onSwitchGreenWire
-- forward declarations
local gui_updater, update_gui_state



----------------------------------------------------------------------------------------------------
-- UI definition
----------------------------------------------------------------------------------------------------

---@param fc_entity FilterCombinatorData
---@return FrameworkGuiElemDef ui
local function get_ui(fc_entity)
    return {
        type = 'frame',
        name = 'gui_root',
        direction = 'vertical',
        handler = { [defines.events.on_gui_closed] = onWindowClosed },
        elem_mods = { auto_center = true },
        children = {
            { -- Title Bar
                type = 'flow',
                style = 'frame_header_flow',
                drag_target = 'gui_root',
                children = {
                    {
                        type = 'label',
                        style = 'frame_title',
                        caption = { const.fc_entity_name },
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
                        handler = { [defines.events.on_gui_click] = onWindowClosed },
                    },
                },
            }, -- Title Bar End
            {  -- Body
                type = 'frame',
                style = 'entity_frame',
                children = {
                    {
                        type = 'flow',
                        style = 'two_module_spacing_vertical_flow',
                        direction = 'vertical',
                        children = {
                            {
                                type = 'flow',
                                style = 'framework_indicator_flow',
                                children = {
                                    {
                                        type = 'sprite',
                                        name = 'lamp',
                                        style = 'framework_indicator',
                                    },
                                    {
                                        type = 'label',
                                        style = 'label',
                                        name = 'status',
                                    },
                                    {
                                        type = 'empty-widget',
                                        name = 'spacer',
                                        style_mods = { horizontally_stretchable = true },
                                    },
                                    {
                                        type = 'label',
                                        style = 'label',
                                        caption = 'ID: ' .. fc_entity.main.unit_number,
                                    },
                                },
                            },
                            {
                                type = 'frame',
                                style = 'deep_frame_in_shallow_frame',
                                name = 'preview_frame',
                                children = {
                                    {
                                        type = 'entity-preview',
                                        name = 'preview',
                                        style = 'wide_entity_button',
                                        elem_mods = { entity = fc_entity.main },
                                    },
                                },
                            },
                            {
                                type = 'label',
                                style = 'semibold_label', -- heading_3_label'
                                caption = { 'gui-constant.output' },
                            },
                            {
                                type = 'switch',
                                name = 'on-off',
                                right_label_caption = { 'gui-constant.on' },
                                left_label_caption = { 'gui-constant.off' },
                                handler = { [defines.events.on_gui_switch_state_changed] = onSwitchEnabled },
                            },
                            {
                                type = 'label',
                                style = 'semibold_label', -- heading_3_label'
                                caption = { const:locale('mode-heading') },
                            },
                            {
                                type = 'switch',
                                name = 'incl-excl',
                                right_label_caption = { const:locale('mode-exclude') },
                                right_label_tooltip = { const:locale('mode-exclude-tooltip') },
                                left_label_caption = { const:locale('mode-include') },
                                left_label_tooltip = { const:locale('mode-include-tooltip') },
                                handler = { [defines.events.on_gui_switch_state_changed] = onSwitchExclusive },
                            },
                            {
                                type = 'checkbox',
                                caption = { const:locale('mode-wire') },
                                name = 'mode-wire',
                                handler = { [defines.events.on_gui_checked_state_changed] = onToggleWireMode },
                                state = false,
                            },
                            {
                                type = 'flow',
                                direction = 'horizontal',
                                name = 'wire-select',
                                children = {
                                    {
                                        type = 'radiobutton',
                                        caption = { 'item-name.red-wire' },
                                        name = 'red-wire-indicator',
                                        handler = { [defines.events.on_gui_checked_state_changed] = onSwitchRedWire },
                                        state = false,
                                    },
                                    {
                                        type = 'radiobutton',
                                        caption = { 'item-name.green-wire' },
                                        name = 'green-wire-indicator',
                                        handler = { [defines.events.on_gui_checked_state_changed] = onSwitchGreenWire },
                                        state = false,
                                    },
                                },
                            },
                            {
                                type = 'flow',
                                direction = 'vertical',
                                name = 'item-grid',
                                children = {
                                    {
                                        type = 'line',
                                    },
                                    {
                                        type = 'label',
                                        style = 'semibold_label', -- heading_3_label'
                                        caption = { const:locale('signals-heading') },
                                    },
                                    {
                                        type = 'scroll-pane',
                                        style = 'logistic_sections_scroll_pane', -- constant_combinator_logistics_scroll_pane
                                        children = {
                                            {
                                                type = 'frame',
                                                style = 'deep_frame_in_shallow_frame',
                                                children = {
                                                    {
                                                        type = 'table',
                                                        name = 'signals',
                                                        style = 'slot_table',
                                                        column_count = 10,
                                                    },
                                                },
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
    }
end

----------------------------------------------------------------------------------------------------
-- UI Callbacks
----------------------------------------------------------------------------------------------------

---@param event EventData.on_gui_switch_state_changed|EventData.on_gui_checked_state_changed|EventData.on_gui_elem_changed
---@return FilterCombinatorData? fc_entity
local function locate_config(event)
    local _, player_data = Player.get(event.player_index)
    if not (player_data and player_data.fc_gui) then return nil end

    local fc_entity = This.fico:entity(player_data.fc_gui.fc_id)
    if not fc_entity then return nil end

    return fc_entity
end

----------------------------------------------------------------------------------------------------

--- close the UI (button or shortcut key)
---
---@param event EventData.on_gui_click|EventData.on_gui_opened
onWindowClosed = function(event)
    local player, player_data = Player.get(event.player_index)

    local fc_gui = player_data.fc_gui

    if (fc_gui) then
        if player.opened == player_data.fc_gui.gui.root then
            player.opened = nil
        end

        Event.remove(-1, gui_updater, nil, fc_gui)
        player_data.fc_gui = nil

        if fc_gui.gui then
            Framework.gui_manager:destroy_gui(fc_gui.gui)
        end
    end
end

----------------------------------------------------------------------------------------------------

local on_off_values = {
    left = false,
    right = true,
}

local values_on_off = table.invert(on_off_values)

--- Enable / Disable switch
---
---@param event EventData.on_gui_switch_state_changed
onSwitchEnabled = function(event)
    local fc_entity = locate_config(event)
    if not fc_entity then return end

    fc_entity.config.enabled = on_off_values[event.element.switch_state]
end

----------------------------------------------------------------------------------------------------

local incl_excl_values = {
    left = true,
    right = false,
}

local values_incl_excl = table.invert(incl_excl_values)

--- inclusive/exclusive switch
---
---@param event EventData.on_gui_switch_state_changed
onSwitchExclusive = function(event)
    local fc_entity = locate_config(event)
    if not fc_entity then return end

    fc_entity.config.include_mode = incl_excl_values[event.element.switch_state]
end

----------------------------------------------------------------------------------------------------

--- switch green wire
---@param event EventData.on_gui_checked_state_changed
onSwitchGreenWire = function(event)
    local fc_entity = locate_config(event)
    if not fc_entity then return end

    fc_entity.config.filter_wire = defines.wire_type.green
end

----------------------------------------------------------------------------------------------------

--- switch red wire
---@param event EventData.on_gui_checked_state_changed
onSwitchRedWire = function(event)
    local fc_entity = locate_config(event)
    if not fc_entity then return end

    fc_entity.config.filter_wire = defines.wire_type.red
end

----------------------------------------------------------------------------------------------------

---@param event  EventData.on_gui_checked_state_changed
onToggleWireMode = function(event)
    local fc_entity = locate_config(event)
    if not fc_entity then return end

    fc_entity.config.use_wire = event.element.state
end

----------------------------------------------------------------------------------------------------

---@param event EventData.on_gui_elem_changed
onSelectSignal = function(event)
    local fc_entity = locate_config(event)
    if not fc_entity then return end

    if not event.element.tags then return end

    local signal = event.element.elem_value --[[@as SignalID]]
    local slot = event.element.tags.idx --[[@as number]]

    if signal then
        local quality = signal.quality or 'normal'
        local type = signal.type or 'item'
        for _, filter in pairs(fc_entity.config.filters) do
            if filter.value.name == signal.name and filter.value.type == type and filter.value.quality == quality then
                event.element.elem_value = nil
                local player = Player.get(event.player_index)
                local item_name = prototypes[type == 'virtual' and 'virtual_signal' or type][signal.name].localised_name
                player.create_local_flying_text { text = { const:locale('signal-selected'), item_name }, create_at_cursor = true }
                player.play_sound { path = 'utility/cannot_build', position = player.position, volume = 1 }
                return
            end
        end

        fc_entity.config.filters[slot] = {
            value = { name = signal.name, type = type, quality = quality, comparator = '=', },
            min = 1,
        }
    else
        fc_entity.config.filters[slot] = nil
    end
end

----------------------------------------------------------------------------------------------------
-- create grid buttons for "all signals" constant combinator
----------------------------------------------------------------------------------------------------

---@param fc_entity FilterCombinatorData
---@return FrameworkGuiElemDef[] gui_elements
local function make_grid_buttons(fc_entity)
    local filters = fc_entity.config.filters
    local list = {}

    local base = 0

    repeat
        local has_signals = false
        for j = 1, 10 do
            local idx = base + j
            local entry = {
                type = 'choose-elem-button',
                tags = { idx = idx },
                style = 'slot_button',
                elem_type = 'signal',
                handler = { [defines.events.on_gui_elem_changed] = onSelectSignal },
            }
            if filters[idx] and filters[idx].value then
                entry.signal = { name = filters[idx].value.name, type = filters[idx].value.type, quality = filters[idx].value.quality, }
                has_signals = true
            end
            table.insert(list, entry)
        end

        base = base + 10
        -- exit if there are at least two rows and one is a full row of empty signals
    until base > 0 and not has_signals

    return list
end

----------------------------------------------------------------------------------------------------
-- GUI state updater
----------------------------------------------------------------------------------------------------

---@param gui FrameworkGui
---@param fc_entity FilterCombinatorData
update_gui_state = function(gui, fc_entity)
    local fc_config = fc_entity.config

    local entity_status = (not fc_config.enabled) and defines.entity_status.disabled -- if not enabled, status is disabled
        or fc_config.status                                                          -- if enabled, the registered state takes precedence if present
        or defines.entity_status.working                                             -- otherwise, it is working

    local on_off = gui:find_element('on-off')
    on_off.switch_state = values_on_off[fc_config.enabled]

    local lamp = gui:find_element('lamp')
    lamp.sprite = tools.STATUS_SPRITES[entity_status]

    local status = gui:find_element('status')
    status.caption = { tools.STATUS_NAMES[entity_status] }

    local incl_excl = gui:find_element('incl-excl')
    incl_excl.switch_state = values_incl_excl[fc_config.include_mode]

    local mode_wire = gui:find_element('mode-wire')
    mode_wire.state = fc_config.use_wire

    local wire_select = gui:find_element('wire-select')
    wire_select.visible = fc_config.use_wire

    local item_grid = gui:find_element('item-grid')
    item_grid.visible = not fc_config.use_wire

    local red_wire = gui:find_element('red-wire-indicator')
    red_wire.state = fc_config.filter_wire == defines.wire_type.red

    local green_wire = gui:find_element('green-wire-indicator')
    green_wire.state = fc_config.filter_wire == defines.wire_type.green

    local slot_buttons = make_grid_buttons(fc_entity)
    gui:replace_children('signals', slot_buttons)
end

----------------------------------------------------------------------------------------------------
-- Event ticker
----------------------------------------------------------------------------------------------------

---@param fc_gui FilterCombinatorGui
gui_updater = function(ev, fc_gui)
    local fc_entity = This.fico:entity(fc_gui.fc_id)
    if not fc_entity then
        Event.remove(-1, gui_updater, nil, fc_gui)
        return
    end

    This.fico:tick(fc_entity)

    if not (fc_gui.last_config and table.compare(fc_gui.last_config, fc_entity.config)) then
        This.fico:reconfigure(fc_entity)
        update_gui_state(fc_gui.gui, fc_entity)
        fc_gui.last_config = tools.copy(fc_entity.config)
    end
end

----------------------------------------------------------------------------------------------------
-- open gui handler
----------------------------------------------------------------------------------------------------

---@param event EventData.on_gui_opened
local function onGuiOpened(event)
    local player, player_data = Player.get(event.player_index)
    if player.opened and player_data.fc_gui and player.opened == player_data.fc_gui.gui.root then
        player.opened = nil
    end

    -- close an eventually open gui
    onWindowClosed(event)

    local entity = event and event.entity --[[@as LuaEntity]]
    local fc_id = entity.unit_number --[[@as integer]]
    local fc_entity = This.fico:entity(fc_id)

    if not fc_entity then
        log('Data missing for ' ..
            event.entity.name .. ' on ' .. event.entity.surface.name .. ' at ' .. serpent.line(event.entity.position) .. ' refusing to display UI')
        player.opened = nil
        return
    end

    local gui = Framework.gui_manager:create_gui(player.gui.screen, get_ui(fc_entity))

    ---@class FilterCombinatorGui
    ---@field gui FrameworkGui
    ---@field fc_id integer
    ---@field last_config FilterCombinatorConfig?
    player_data.fc_gui = {
        gui = gui,
        fc_id = fc_id,
        last_config = nil,
    }

    Event.register(-1, gui_updater, nil, player_data.fc_gui)

    player.opened = gui.root
end

----------------------------------------------------------------------------------------------------
-- Event registration
----------------------------------------------------------------------------------------------------

local match_main_entities = tools.create_event_entity_matcher('name', const.main_entity_names)

Event.on_event(defines.events.on_gui_opened, onGuiOpened, match_main_entities)

return ModGui
