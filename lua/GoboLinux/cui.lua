-- vi: set foldmethod=marker foldlevel=0:
--
-- cui.lua
-- ---------------------------------------------------------------------------
--  - 2008
-- ---------------------------------------------------------------------------
-- Author: Aitor Pérez Iturri - <aitor.iturri@gmail.com>	
-- Created: 20/01/08 00:20:48 CET
-- License: GNU GPL (see www.fsf.org for details)
-- ---------------------------------------------------------------------------
-- Description:
--
-- ---------------------------------------------------------------------------

-- Create module {{{1
module("GoboLinux.cui", package.seeall)

-- Imports
require "GoboLinux.switch"

-- Local Variables {{{1

-- Screen values {{{2
local screen_columns = tonumber(os.getenv("COLUMNS"))
local screen_lines = tonumber(os.getenv("LINES"))
local current_x
local current_y


-- ANSI escape sequences {{{2
local esc = "\27["
local ANSIclear_screen = esc.."2J"
local ANSIclear_line = esc.."K"
local ANSIrestore_cursor = esc.."u"
local ANSIsave_cursor = esc.."s"
local ANSIset_cursor = esc.."%s;%sf" -- to use with string.format-- colors
local ANSIcursor_up = esc .. "%sA"
local ANSIcursor_down = esc .. "%sB"
local ANSIcursor_right = esc .. "%sC"
local ANSIcursor_left = esc .. "%sD"
local ANSIblack = esc.."30m"
local ANSIred = esc .. "31m"
local ANSIgreen = esc .. "32m"
local ANSIyellow = esc .. "33m"
local ANSIblue = esc .. "34m"
local ANSImagenta = esc .. "35m"
local ANSIcyan = esc .. "36m"
local ANSIwhite = esc .. "37m"
local ANSIboldblack = esc .. "1;30m"
local ANSIboldred = esc .. "1;31m"
local ANSIboldgreen = esc .. "1;32m"
local ANSIboldyellow = esc .. "1;33m"
local ANSIboldblue = esc .. "1;34m"
local ANSIboldmagenta = esc .. "1;35m"
local ANSIboldcyan = esc .. "1;36m"
local ANSIboldwhite = esc .. "1;37m"

-- List of avaible colors {{{2
local colors = {
	Black = true,
	Red = true,
	Green = true,
	Yellow = true,
	Blue = true,
	Magenta = true,
	Cyan = true,
	White = true,
	BoldBlack = true,
	BoldRed = true,
	BoldGreen = true,
	BoldYellow = true,
	BoldBlue = true,
	BoldMagenta = true,
	BoldCyan = true,
	BoldWhite = true
}

 -- List of avaible aligns {{{2
local aligns = {
	Center = true,
	Left = true,
	Right = true,
--	Level = "1"
}

local idents = {
	True = true,
	False = true,
}

-- List of avaible levels {{{2
local levels = {}
levels["1"] = true
levels["2"] = true
levels["3"] = true


-- Text Modifiers info {{{2
local text_modifiers_default = {
	Align = "Left",
	Ident = "True",
	Align ="Left",
	AlingStyle = "Paragraph",
	Color = "BoldWhite",
	IdentStyle = "First",
	Level = "1",
	LevelPosition = "Left",
	Position = "Left"
}

local text_modifiers = {
	Position = aligns,
	Ident = idents,
	Align = aligns,
	Color = colors,
	Level = levels,
	LevelPosition = aligns,
	AlignStyle = {
		Paragraph = true,
		Line = true,
	},
	IdentStyle = {
		First = true,
	}
}

-- Title Modifiers info {{{2
local title_modifiers_default = {
	Align = "Center",
	Ident = "True",
	Align = "Center",
	Color = "BoldRed",
	Level = "1",
	LevelPosition = "Left",
	Position = "Center",
}

local levels_len = { 100, 70, 40 }

local title_modifiers = {
	Position = aligns,
	Ident = idents,
	Color = colors,
	Level = levels,
	LevelPosition = aligns,
}

-- Ask Modifiers info {{{2
local ask_modifiers = {
	Position=aligns,
	LevelPosition=aligns,
	Align = aligns,
	ItemAlign = aligns,
	QuestionAign = aligns,
	Ident = idents,
	Color = colors,
	ItemColor = colors,
	Level = levels,
	AlignStyle = {
		"Paragraph",
		"Line"
	}
}

local ask_modifiers_default = {
	Align = "Center",
	ItemAlign = "Center",
	QuestionAlign = "Left",
	Ident = "True",
	Color = "Yellow",
	AlignStyle = "Paragraph",
	Level = "2",
	LevelPosition="Left",
	Position="Left",
	ItemColor = "BoldGreen",
}

local percent_bar_modifiers = {
	Position = alings,
	LevelPosition = aligns,
	Align = aligns,
	Color = colors,
	Level = levels,
}

local percent_bar_modifiers_default = {
	Position = "Center",
	LevelPosition="Center",
	Align = "Left",
	Color = "Yellow",
	Level = "2"
}

-- Exported Variables {{{1
BorderStyle = "="
Colors = {
	Black = ANSIblack,
	Red = ANSIred,
	Green = ANSIgreen,
	Yellow = ANSIyellow,
	Blue = ANSIblue,
	Magenta = ANSImagenta,
	Cyan = ANSIcyan,
	White = ANSIwhite,
	BoldBlack = ANSIboldblack,
	BoldRed = ANSIboldred,
	BoldGreen = ANSIboldgreen,
	BoldYellow = ANSIboldyellow,
	BoldBlue = ANSIboldblue,
	BoldMagenta = ANSIboldmagenta,
	BoldCyan = ANSIboldcyan,
	BoldWhite = ANSIboldwhite,
	Default = ANSIboldwhite,
}

-- Local Functions {{{1

-- level (level) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function level ( level )
	if level == "0" then return screen_columns end
	return math.floor((screen_columns * levels_len[tonumber(level)]) / 100)
end  ----------  end of function title_level  ----------

-- colorize (str, color) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function colorize ( str, color )
	return Colors[color]..str..Colors.Default
end  ----------  end of function colorize  ----------

-- align_line (line, n, align) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function align_line ( line, n, align )
	local linelen = line:len()
	local l 
	if align == "Left" then
		return line .. string.rep(" ",n - linelen)
	elseif align == "Right" then
		return string.rep(" ",n-linelen) .. line
	else
		return line
	end
end  ----------  end of function align_line  ----------

-- align_buffer (buffer, n, align) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function align_buffer ( buffer, n, align )
	local buff = {}
	for i, line in ipairs(buffer) do
--		local linelen = line:len()
--		if align == "Left" then
--			buff[i] = line .. string.rep(" ",n - linelen)
--		elseif align == "Right" then
--			buff[i] = string.rep(" ",n-linelen) .. line
--		else
--			buff[i] = line
--		end
		buff[i] = align_line(line, n, align)
	end
	return buff
end  ----------  end of function align_buffer  ----------

-- set_modifiers (args, mods, mods_default) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function set_modifiers ( args, mods, mods_default )
	local modifiers = {}
	setmetatable(modifiers, {__index = mods_default})
	for _, mod in ipairs(args) do
		local _,_,opt, value = mod:find("(%w+)%s*=%s*(%w+)",0)
		if opt and mods[opt] and mods[opt][value] then
			modifiers[opt] = value
		end
	end
	return modifiers
end  ----------  end of function set_modifiers  ----------

-- split_line (line, long) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function split_line ( line, long)
	-- Get the next black character just backward
	-- black = 32
	-- tab = 9
	local i = long
	local byte = line:byte(n)
	while (byte ~= 32 and byte ~= 9) or i == 0 do
		i = i - 1
		byte = line:byte(i)
	end
	return line:sub(1,i-1), line:sub(i+1,line:len())
end  ----------  end of function split_line  ----------

-- position (str, n, align, indent) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function position ( str, n, align, indent )
	local str_len = str:len()
	if str_len == n then
		return str
	end
	return switch(align):caseof {
		Center = function ()
			local nl = (n - str_len) / 2
			local nr = n - (nl + str_len)-2
			return string.rep(" ",nl)
					.. str .. string.rep(" ",nr)
		end,
		Left = function ()
	--		if ident then
	--			str = "  "..str 
	--			str_len = str_len + 2
	--		end
			-- add 2 spaces before
			return str .. string.rep(" ", n - (str_len))
		end,
		Right = function ()
	--		if ident then
	--			str = str.."  "
	--			str_len = str_len +2
	--		end
			-- add 2 spaces after
			return string.rep(" ", n - (str_len))..str
		end,
	}
end  ----------  end of position  ----------

-- position_line (text, pos, l, pos2) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function position_line (text, l1, l2,pos1, pos2)
	return position(position(text, level(l1), pos2),level(l2), pos1)
end  ----------  end of function position_line  ----------

-- position_buffer (buffer, l, pos) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function position_buffer ( buffer, l1, l2, pos1, pos2)
	local buff = {}
	for i, line in ipairs(buffer) do
--		buff[i] = position(line, l, pos)
		buff[i] = position_line(line, l1,l2, pos1, pos2)

	end
	return buff
end  ----------  end of function position_buffer  ----------

-- format_text (text, modifiers) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function format_text ( text, modifiers )
	local buffer = {}
	local n = level(modifiers.Level)
	local remain = ""
	local linelen
	local maxlen = 0
	for l in text:gsub("\n"," \n"):gmatch("[^\n]+",0) do
		remain = l
		--local line
		while remain:len() > n do
			maxlen = n
			line, remain = split_line(remain:gsub("\t","    "),n)
			linelen = line:len()
			buffer[#buffer+1] = line
		end
		linelen = remain:len()
		if linelen > maxlen then
			maxlen = linelen
		end
		buffer[#buffer+1] = remain

	end
	return position_buffer(align_buffer(buffer, maxlen, 
											modifiers.Align),
								modifiers.Level,
								"0", -- level 0
								modifiers.LevelPosition,
								modifiers.Position)

end  ----------  end of function format_text  ----------

-- format_title (buffer, l, pos) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function format_title ( title, modifiers )
	local buffer = format_text(title, modifiers)
	buffer[0] = colorize(position_line(string.rep(BorderStyle, 
								level(modifiers.Level)),
							modifiers.Level,
							"0", 
							modifiers.LevelPosition,
							modifiers.Position), modifiers.Color)
	buffer[#buffer+1] = buffer[0]
	return buffer
end  ----------  end of function format_title  ----------


-- show_buffer (buffer, modifiers) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function show_buffer ( buffer, modifiers )
	for _, line in ipairs(buffer) do
		print(colorize(line, modifiers.Color))
	end
end  ----------  end of function show_buffer  ----------


-- gen_percent_bar (n1, n2) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function gen_percent_bar ( n1, n2, modifiers )
--	local barsize = 70
	local barsize = level(modifiers.Level) - 7
	local str = "["
--	local slices = math.floor(barsize/n1)*100
--	local filled = math.floor(slices*n2
	local filled = math.floor((n2/n1 * 100)*(barsize/100))
	local notfilled = barsize-filled
	local percent = string.format("%.0f%%",(n2*100)/n1)
	if 4 - percent:len() ~= 0 then
		percent = percent..string.rep(" ",4-percent:len())
	end
	if percent == "100%" then
		str = str .. string.rep("%",barsize).."]"
	else
		str = str .. string.rep("%",filled) .. string.rep(" ",notfilled) .. "]"
	end
	return str.." "..percent
end  ----------  end of function gen_percent_bar  ----------

-- Exported Functions {{{1

-- TODO: Support for partial screens
function clear_screen ()
	print(ANSIclear_screen)
	return true
end

function clear_line (  )
	print(ANSIclear_line)
end  ----------  end of function clear_line  ----------

function columns (  )
	return screen_columns
end  ----------  end of function columns  ----------

function lines (  )
	return screen_lines
end  ----------  end of function lines  ----------

function cursor_down ( n )
	print(string.format(ANSIcursor_down, tostring(n)))
end  ----------  end of function cursor_down  ----------

function cursor_left ( n )
	print(string.format(ANSIcursor_left, tostring(n)))
end  ----------  end of function cursor_left  ----------

function cursor_right ( n )
	print(string.format(ANSIcursor_right, tostring(n)))
end  ----------  end of function cursor_right  ----------

function cursor_up ( n )
	print(string.format(ANSIcursor_up, tostring(n)))
end  ----------  end of function cursor_up  ----------

function set_cursor (x, y)
	current_x, current_y = x or 0, y or 0
	print(string.format(ANSIset_cursor, tostring(current_x),
										tostring(current_y)))
	return true
end -----------  end of function set_cursor

function save_cursor (  )
	print(ANSIsave_cursor)
end  ----------  end of function save_cursor  ----------

function restore_cursor (  )
	print(ANSIrestore_cursor)
end  ----------  end of function restore_cursor  ----------

function get_cursor ()
	return current_x, current_y
end  ----------  end of function function get_cursor ()  ----------

function title ( title, ... )
	if not type then return nil end
	local buffer ={}
	local modifiers = set_modifiers(arg, title_modifiers, title_modifiers_default)
	local title_len = title:len()
	buffer = format_title(title, modifiers)
	for i=0, #buffer do
		print(buffer[i])
	end
end  ----------  end of function print_titile  ---------

function text ( text, ... )
	local modifiers = set_modifiers(arg, text_modifiers, text_modifiers_default)
	local buffer = format_text(text, modifiers)
	show_buffer(buffer, modifiers)
end  ----------  end of function text  ----------

-- ask {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function ask (str, ... )
	if not str then return nil end
	local modifiers = set_modifiers(arg, ask_modifiers, ask_modifiers_default)
	local answer
	local buffer = format_text(str, modifiers)
	show_buffer(buffer, modifiers)
	answer = io.read("*l")
	return answer
end  ----------  end of function ask  ----------
-- ask_yn ( str) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function ask_yn ( str, ... )
	if not str then return nil end
	local modifiers = set_modifiers(arg, ask_modifiers, ask_modifiers_default)
	local answer
	local buffer = format_text(str .. "(y/n)", modifiers)
	show_buffer(buffer, modifiers)
	answer = io.read("*l")
	answer = answer:sub(1,1)
	while answer ~= 'y' and answer ~= 'n' do
	--	clear_line()
	--	restore_cursor()
		answer = io.read("*l")
		answer = answer:sub(1,1)
	end
	os.execute("stty echo")
	if answer == 'y' then return true
	else return false 
	end
end  ----------  end of function ask_yn  ----------

-- ask_list (str, choices, extra_list, ...) {{{2 
-- STRING -> STRING, LIST, [LIST], [STRING]*
-- ---------------------------------------------------------------------------
-- @input:
-- 	str :: String to show
-- 	choices_list :: List of choices to show and accept
-- 	extra_list :: List of choices not showed but accepted
-- 	...	:: Modifiers passed to the ask item
-- @output:
-- 	choice :: returns the choice selected
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- 	Manage Level Modifier
-- 	Manage AlignStyle Modifier
-- 	Manage ItemColor Modifier
-- 	Manage CheckColor Modifier
-- ---------------------------------------------------------------------------
function ask_list ( str, choices_list, extra_list, ... )
	if not str then return nil end
	if not choices_list or not type(choices_list) == "table" then
		return nil
	end
	local modifiers = set_modifiers(arg, ask_modifiers, ask_modifiers_default)
	local extra_list = extra_list or {}
	local answer
	local choices = {}
	local choices_text = {}
	local choicestext=""
	-- add choices
	for i, l in ipairs(choices_list) do
		local text, desc, choice = l[1], l[2], l[3]
		if not text or not choice then return nil end
		local choice_text = "["..tostring(i).."] "..text
		if desc then
			choice_text=choice_text.."\n\t\t"..desc
		end
		choicestext=choicestext.."\n"..choice_text
		--choices_text[i] = choice_text,
		choices[tostring(i)] = choice
	end
	-- add extra_list 
	for i, l in ipairs(extra_list) do
		local text, choice = l[1], l[3]
		if not text or not choice then return nil end
		choices[text] = choice
	end
	local buff = format_text(choicestext, modifiers)
	show_buffer(buff, modifiers)
	--output.log_terse("")
	--output.log_terse(str)
	--print(colorize(align_line("\n"..str,modifiers.Align),modifiers.Color))
	show_buffer(format_text("\n"..str,modifiers),modifiers)
	--(format_text(str, modifiers))
	while true do 
		answer = io.read("*l")
		if choices[answer]then 
			return choices[answer]
		end
	end
end  ----------  end of function ask_list  ----------


-- percent_bar (items, co, ...) {{{2
-- ---------------------------------------------------------------------------
-- @input:
--	Integer) items: Number of items to iterate in the percent bar
--	(Coroutine) co: Coroutine to execute inside the percent bar
--	(String) ...: Modifiers to alterate the percent bar appareance
-- @output:
--	(Boolean) [true| false, error_message]
-- ---------------------------------------------------------------------------
-- Description:
--	This widget creates a percent bar, the percent bar will be created for 
--	'items' number of elements. The 'co' coroutine will be executed inside it.
--	Se documentation for details on how it works.
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function percent_bar ( items, co, ... )
--	local modifiers = set_modifiers(arg, ask_modifiers, ask_modifiers_default)
	local modifiers = set_modifiers(arg, percent_bar_modifiers, 
			percent_bar_modifiers_default)
	local percent_bar
	local buffer
	local i = 0
	local s
	percent_bar = gen_percent_bar(items,i, modifiers)
	local s,next_item, desc, f = coroutine.resume(co)
	local err
	while coroutine.status(co) ~= "dead" do
		if not s then
			-- internal error when executing coroutine
			err = "Iternal error: "..next_item
			break
		end
	--	buffer = nil
		buffer = format_text(desc.."\n"..percent_bar, modifiers)
		show_buffer(buffer, modifiers)
		cursor_up(#buffer+1)
		_, err = f()
		if err then
			break
		end
		if next_item then
			i = i + 1
			percent_bar = gen_percent_bar(items,i, modifiers)
		end
		s,next_item, desc, f =	coroutine.resume(co)
	end
	if not s then
		-- internal error when executing coroutine
		err = "Iternal error "..next_item
	end
	-- At the end
	--	next_item => Exit code [true|false]
	--	desc => Item description
	--	f => Error description, only if next_item == false
--	if not next_item then
		err = f
--	else
--		percent_bar = gen_percent_bar(items,items,modifiers)
--	end
	buffer = nil
	buffer = format_text(desc.."\n"..percent_bar,modifiers)
	show_buffer(buffer, modifiers)
	if err then  
		return nil, err
	else
		return true
	end
end  ----------  end of function percent_bar  ----------



