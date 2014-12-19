--[[
	Incremental search module for Textadept.
	Written by: Simon Lundmark

	This module simply allows you to call the module.start_incremental_search
	function that instantly searches for the word that you're typing
	as you type. You can step to the next instance of the word using F3 or by 
	pressing enter.
	
	USAGE:
	
	Install the init.lua-file into your textadept/modules/incremental_search-folder.
	
	in your textadept/init.lua or similar file:
	incremental_search = require("incremental_search")
	keys['ci'] = incremental_search.start_incremental_search
	
	Copyright (c) 2014 Simon Lundmark, Pixeldiet Entertainment AB.

	This software is provided 'as-is', without any express or implied
	warranty. In no event will the authors be held liable for any damages
	arising from the use of this software.

	Permission is granted to anyone to use this software for any purpose,
	including commercial applications, and to alter it and redistribute it
	freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you must not
		claim that you wrote the original software. If you use this software
		in a product, an acknowledgement in the product documentation would be
		appreciated but is not required.
	2. Altered source versions must be plainly marked as such, and must not be
		misrepresented as being the original software.
	3. This notice may not be removed or altered from any source distribution. 
]]--

local M = {}

local WORD_INDICATOR = _SCINTILLA.next_indic_number()
buffer.indic_style[WORD_INDICATOR] = buffer.INDIC_BOX
buffer.indic_fore[WORD_INDICATOR] = "0xAAAAAA"

local last_selected_text
local incremental_search_running

local function step_to_next(current_pos)
	local buffer_text = buffer:get_text()

	local found_start, found_end = string.find(buffer_text, last_selected_text, current_pos-1, true)
	if not found_start then
		found_start, found_end = string.find(buffer_text, last_selected_text, 0, true)
	end
	if found_start then 
		buffer:set_selection(found_end+1, found_start-1)
	else
		buffer:clear_selections()
	end
end

local function update_marker_selection()
	if not incremental_search_running then		
		return
	end
	
	local selected_text = ui.command_entry.entry_text
		
	if selected_text ~= last_selected_text then
		last_selected_text = selected_text
			
		if selected_text and selected_text ~= "" and string.len(selected_text) >= 1 then
			local current_pos = buffer.selection_start and buffer.selection_start-1 or buffer.current_pos
			step_to_next(current_pos)
		end
	end
end

local function start_incremental_search()
	incremental_search_running = true
	ui.command_entry.enter_mode('incremental_search', '')
end

local function incremental_end() 
	incremental_search_running = false
end

keys.incremental_search = {
	['\n'] = function()
		step_to_next(buffer.current_pos)
	end,
	['esc'] = { ui.command_entry.finish_mode, incremental_end },
	['f3'] = function()
		step_to_next(buffer.current_pos)
	end,
}

-- Events:
-- Unfortunately we need to do like this since keypress is fired BEFORE the key is added to the buffert.
-- That means that we get one update when the user presses the key, which moves or updates the selection
-- Which updates the UI, which triggers the update_ui event that in turn updates the function again
-- and this time WITH the full text added.
events.connect(events.UPDATE_UI, update_marker_selection)
events.connect(events.KEYPRESS, function()
	update_marker_selection()
end)

-- External API:
local M = {}
M.start_incremental_search = start_incremental_search
M.stop_incremental_search = incremental_end
return M
