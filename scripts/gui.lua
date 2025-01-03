---@meta
------------------------------------------------------------------------
-- Filter combinator GUI
------------------------------------------------------------------------

local Event = require('stdlib.event.event')
local Player = require('stdlib.event.player')
local table = require('stdlib.utils.table')

local tools = require('framework.tools')

local const = require('lib.constants')

---@class FilterCombinatorGui
local Gui = {}

----------------------------------------------------------------------------------------------------
-- UI definition
----------------------------------------------------------------------------------------------------

---@param fc_entity FilterCombinatorData
---@return FrameworkGuiElemDef ui
function Gui.get_ui(fc_entity)
    return {
        type = 'frame',
        name = 'gui_root',
        direction = 'vertical',
        handler = { [defines.events.on_gui_closed] = Gui.onWindowClosed },
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
                        caption = { 'entity-name.' .. const.filter_combinator_name },
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
                        handler = { [defines.events.on_gui_click] = Gui.onWindowClosed },
                    },
                },
            }, -- Title Bar End
            {  -- Body
                type = 'frame',
                style = 'inside_shallow_frame',
                direction = 'vertical',
                children = {
                    {
                        type = 'frame',
                        direction = 'horizontal',
                        children = {
                            {
                                type = 'label',
                                style = 'semibold_label',
                                caption = { const:locale('input') },
                            },
                            {
                                type = 'label',
                                style = 'subheader_label',
                                name = 'connections_input',
                            },
                            {
                                type = 'label',
                                style = 'label',
                                name = 'combinator_input_red',
                                visible = false,
                            },
                            {
                                type = 'label',
                                style = 'label',
                                name = 'combinator_input_green',
                                visible = false,
                            },
                            {
                                type = 'empty-widget',
                                style_mods = { horizontally_stretchable = true },
                            },
                            {
                                type = 'label',
                                style = 'semibold_label',
                                caption = { const:locale('output') },
                            },
                            {
                                type = 'label',
                                style = 'subheader_label',
                                name = 'connections_output',
                            },
                            {
                                type = 'label',
                                style = 'label',
                                name = 'combinator_output_red',
                                visible = false,
                            },
                            {
                                type = 'label',
                                style = 'label',
                                name = 'combinator_output_green',
                                visible = false,
                            },
                        },
                    },
                    {
                        type = 'frame',
                        style = 'entity_frame',
                        style_mods = {
                            minimal_width = 400,
                            horizontally_stretchable = true,
                        },
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
                                                style_mods = { horizontally_stretchable = true },
                                            },
                                            {
                                                type = 'label',
                                                style = 'label',
                                                caption = { const:locale('id'), fc_entity.main.unit_number },
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
                                        style = 'semibold_label',
                                        caption = { 'gui-constant.output' },
                                    },
                                    {
                                        type = 'switch',
                                        name = 'on-off',
                                        right_label_caption = { 'gui-constant.on' },
                                        left_label_caption = { 'gui-constant.off' },
                                        handler = { [defines.events.on_gui_switch_state_changed] = Gui.onSwitchEnabled },
                                    },
                                    {
                                        type = 'label',
                                        style = 'semibold_label',
                                        caption = { const:locale('mode-heading') },
                                    },
                                    {
                                        type = 'switch',
                                        name = 'incl-excl',
                                        right_label_caption = { const:locale('mode-exclude') },
                                        right_label_tooltip = { const:locale('mode-exclude-tooltip') },
                                        left_label_caption = { const:locale('mode-include') },
                                        left_label_tooltip = { const:locale('mode-include-tooltip') },
                                        handler = { [defines.events.on_gui_switch_state_changed] = Gui.onSwitchExclusive },
                                    },
                                    {
                                        type = 'checkbox',
                                        caption = { const:locale('mode-wire') },
                                        name = 'mode-wire',
                                        handler = { [defines.events.on_gui_checked_state_changed] = Gui.onToggleWireMode },
                                        state = false,
                                    },
                                    {
                                        type = 'line',
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
                                                handler = { [defines.events.on_gui_checked_state_changed] = Gui.onSwitchRedWire },
                                                state = false,
                                            },
                                            {
                                                type = 'radiobutton',
                                                caption = { 'item-name.green-wire' },
                                                name = 'green-wire-indicator',
                                                handler = { [defines.events.on_gui_checked_state_changed] = Gui.onSwitchGreenWire },
                                                state = false,
                                            },
                                        },
                                    },
                                    {
                                        type = 'label',
                                        name = 'item-grid-label',
                                        style = 'semibold_label',
                                        caption = { const:locale('signals-heading') },
                                    },
                                },
                            },
                        },
                    },
                    {
                        type = 'scroll-pane',
                        name = 'item-grid',
                        style = 'logistic_sections_scroll_pane',
                        direction = 'vertical',
                        vertical_scroll_policy = 'auto-and-reserve-space',
                        horizontal_scroll_policy = 'never',
                        style_mods = {
                            horizontally_stretchable = true,
                        },
                        children = {
                            type = 'table',
                            style = 'slot_table',
                            name = 'signals',
                            column_count = 10,
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
-- close the UI (button or shortcut key)
----------------------------------------------------------------------------------------------------

---@param player_index integer?
function Gui.closeByPlayer(player_index)
    if not player_index then return end

    local player, player_data = Player.get(player_index)
    if not player then return end

    local gui = player_data.fc_gui

    if (not gui) then return end

    Event.remove(-1, Gui.gui_updater, nil, gui)
    player_data.fc_gui = nil
    Framework.gui_manager:destroy_gui(gui.gui)
end

---@param unit_number integer?
function Gui.closeByEntity(unit_number)
    if not unit_number then return end

    for _, player in pairs(game.players) do
        if player.opened then
            local player_data = Player.pdata(player.index)
            if player_data and player_data.fc_gui and player_data.fc_gui.fc_id == unit_number then
                Gui.closeByPlayer(player.index)
            end
        end
    end
end

---
---@param event EventData.on_gui_click|EventData.on_gui_opened
function Gui.onWindowClosed(event)
    Gui.closeByPlayer(event.player_index)
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
function Gui.onSwitchEnabled(event)
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
function Gui.onSwitchExclusive(event)
    local fc_entity = locate_config(event)
    if not fc_entity then return end

    fc_entity.config.include_mode = incl_excl_values[event.element.switch_state]
end

----------------------------------------------------------------------------------------------------

--- switch green wire
---@param event EventData.on_gui_checked_state_changed
function Gui.onSwitchGreenWire(event)
    local fc_entity = locate_config(event)
    if not fc_entity then return end

    fc_entity.config.filter_wire = defines.wire_type.green
end

----------------------------------------------------------------------------------------------------

--- switch red wire
---@param event EventData.on_gui_checked_state_changed
function Gui.onSwitchRedWire(event)
    local fc_entity = locate_config(event)
    if not fc_entity then return end

    fc_entity.config.filter_wire = defines.wire_type.red
end

----------------------------------------------------------------------------------------------------

---@param event  EventData.on_gui_checked_state_changed
function Gui.onToggleWireMode(event)
    local fc_entity = locate_config(event)
    if not fc_entity then return end

    fc_entity.config.use_wire = event.element.state
end

----------------------------------------------------------------------------------------------------

---@param event EventData.on_gui_elem_changed
function Gui.onSelectSignal(event)
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
                handler = { [defines.events.on_gui_elem_changed] = Gui.onSelectSignal },
            }
            if filters[idx] and filters[idx].value then
                entry.signal = { name = filters[idx].value.name, type = filters[idx].value.type, quality = filters[idx].value.quality, }
                has_signals = true
            end
            table.insert(list, entry)
        end

        base = base + 10
        -- exit if there are at least two rows and one is a full row of empty signals
    until base > 10 and not has_signals

    return list
end

----------------------------------------------------------------------------------------------------
-- GUI state updater
----------------------------------------------------------------------------------------------------

---@param gui FrameworkGui
---@param fc_entity FilterCombinatorData
function Gui.update_config_gui_state(gui, fc_entity)
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
    local item_grid_label = gui:find_element('item-grid-label')
    item_grid_label.visible = not fc_config.use_wire

    local red_wire = gui:find_element('red-wire-indicator')
    red_wire.state = fc_config.filter_wire == defines.wire_type.red

    local green_wire = gui:find_element('green-wire-indicator')
    green_wire.state = fc_config.filter_wire == defines.wire_type.green

    local slot_buttons = make_grid_buttons(fc_entity)
    gui:replace_children('signals', slot_buttons)
end

---@param gui FrameworkGui
---@param fc_entity FilterCombinatorData
local function update_gui_state(gui, fc_entity)
    for _, pin in pairs { 'input', 'output' } do
        local connections = gui:find_element('connections_' .. pin)
        connections.caption = { 'gui-control-behavior.not-connected' }
        for _, color in pairs { 'red', 'green' } do
            local pin_name = ('combinator_%s_%s'):format(pin, color)

            local wire_connector = fc_entity.main.get_wire_connector(defines.wire_connector_id[pin_name], false)
            local connect = false

            local wire_connection = gui:find_element(pin_name)
            if wire_connector then
                for _, connection in pairs(wire_connector.connections) do
                    connect = connect or (connection.origin == defines.wire_origin.player)
                    if connect then break end
                end
            end
            if connect then
                connections.caption = { 'gui-control-behavior.connected-to-network' }
                wire_connection.visible = true
                wire_connection.caption = { ('gui-control-behavior.%s-network-id'):format(color), wire_connector.network_id }
            else
                wire_connection.visible = false
                wire_connection.caption = nil
            end
        end
    end
end

----------------------------------------------------------------------------------------------------
-- Event ticker
----------------------------------------------------------------------------------------------------

---@param fc_gui FilterCombinatorGui
function Gui.gui_updater(ev, fc_gui)
    local fc_entity = This.fico:entity(fc_gui.fc_id) --[[@as FilterCombinatorData ]]
    if not fc_entity then
        Event.remove(-1, Gui.gui_updater, nil, fc_gui)
        return
    end

    This.fico:tick(fc_entity)

    if not (fc_gui.last_config and table.compare(fc_gui.last_config, fc_entity.config)) then
        This.fico:reconfigure(fc_entity)
        Gui.update_config_gui_state(fc_gui.gui, fc_entity)
        fc_gui.last_config = tools.copy(fc_entity.config)
    end

    -- always update wire state
    update_gui_state(fc_gui.gui, fc_entity)
end

----------------------------------------------------------------------------------------------------
-- open gui handler
----------------------------------------------------------------------------------------------------

---@param event EventData.on_gui_opened
function Gui.onGuiOpened(event)
    local player, player_data = Player.get(event.player_index)
    if not (player and player_data) then return end

    -- close an eventually open gui
    Gui.closeByPlayer(event.player_index)

    local entity = event and event.entity --[[@as LuaEntity]]
    local fc_id = entity.unit_number --[[@as integer]]
    local fc_entity = This.fico:entity(fc_id) --[[@as FilterCombinatorData ]]

    if not fc_entity then
        log('Data missing for ' ..
            event.entity.name .. ' on ' .. event.entity.surface.name .. ' at ' .. serpent.line(event.entity.position) .. ' refusing to display UI')
        player.opened = nil
        return
    end

    local gui = Framework.gui_manager:create_gui(player.gui.screen, Gui.get_ui(fc_entity))

    ---@class FilterCombinatorGui
    ---@field gui FrameworkGui
    ---@field fc_id integer
    ---@field last_config FilterCombinatorConfig?
    player_data.fc_gui = {
        gui = gui,
        fc_id = fc_id,
        last_config = nil,
    }

    Event.register(-1, Gui.gui_updater, nil, player_data.fc_gui)

    player.opened = gui.root
end

function Gui.onGhostGuiOpened(event)
    local player, player_data = Player.get(event.player_index)
    if not (player and player_data) then return end

    player.opened = nil
end

----------------------------------------------------------------------------------------------------
-- Event registration
----------------------------------------------------------------------------------------------------

local match_main_entities = tools.create_event_entity_matcher('name', const.main_entity_names)
local match_ghost_main_entities = tools.create_event_ghost_entity_matcher('ghost_name', const.main_entity_names)

Event.on_event(defines.events.on_gui_opened, Gui.onGuiOpened, match_main_entities)
Event.on_event(defines.events.on_gui_opened, Gui.onGhostGuiOpened, match_ghost_main_entities)

return Gui
