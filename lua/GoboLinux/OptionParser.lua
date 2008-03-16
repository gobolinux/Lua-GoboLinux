-- vi:set foldmethod=marker foldlevel=0:
--
-- (lua library) 
--
-- OptionParser.lua
--
-- ---------------------------
-- A cli parser library in lua
-- ---------------------------
-- Aitor Pérez Iturri
-- 2007. GNU GPL (see http://www.fsf.org for details)
-- --------------------------------------------------
-- This code is based in the great shell scripts used in the GoboLinux
-- distribution ... maybe the best distro arround the world ;).
-- -------------------------------------------------------------------
-- ToDo List:
-- ----------------------------------------------------------------------------
-- ChangeLog:
--	2007-07-01
--		- Added functions:
--			* allBoolean, anyBoolean, allEntry, anyEntry, map_boolean,
--			map_entry. This gives support to check some many options at time.
-- ----------------------------------------------------------------------------

-- Create new module {{{1
module("GoboLinux.OptionParser",package.seeall) 

-- Import modules {{{1
require "GoboLinux.errors"
require "GoboLinux.types"
require "GoboLinux.output"
local output = GoboLinux.output
local types = GoboLinux.types
local errors = GoboLinux.errors

-- Local Variables {{{1
methods = {}

-- Local functions {{{1
-- ----- ---------
-- get_token (str) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- 		str: STRING
-- @output:
-- ---------------------------------------------------------------------------
-- Description: Parses an option string and gives the token value and the token
-- type.
-- Token types are:
-- 	- ShortOption
-- 	- LongOption
-- 	- ListOption
-- 	- UnknowOption
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function get_token (str) 
	local shortoption="^%-(%w[^%s]*)"
	local longoption="^%-%-(%w[^%s]*)"
	local entryoption="^([%w%p][^%s]*)"
	local listoption="^(.+:.*)"
	local token
	token = str:match(shortoption,0,"%1")
	if token then return token, "ShortOption" end
	token = str:match(longoption,0,"%1")
	if token then return token, "LongOption" end
	token = str:match(entryoption,0,"%1")
	if token then return token, "EntryOption" end
	token = str:match(listoption,0,"%1")
	if token then return token, "ListOption" end
	return nil, "UnknowOption"
end

-- get_option_from (str) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description: Iterator to return each option in str.
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function get_option_from_string (str)
	local regexp="^%s*([-|%a][-|%a]%a+)(.*)"
	local rest=str or ""
	local option
	return function ()
		option, rest = rest:match(regexp,0,"%1 %2")
		if not option then return nil end
		return get_token(option)
	end
end

-- get_option (table) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function get_option (table)
	local idx=nil
	local option
	local options=table
	return function ()
		idx, option = next(options,idx)
		if not option or idx <= 0 then return nil end
		return get_token(option)
	end
end

-- get_id () {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description: Iterator which returns an unique id in each call.
-- ---------------------------------------------------------------------------
-- Todo:
-- 	- Implement it with a better solution.
-- 	- Make it local to each parser object.
-- ---------------------------------------------------------------------------
local function get_id ()
	local id = 0
	return function ()
		id = id + 1
		return id
	end
end

-- get_table_for_option (optiontype) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- 		optiontype: STRING
-- @output:
-- ---------------------------------------------------------------------------
-- Description: Gives the table for the token `optiontype`
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function get_table_for_option (optiontype)
	if optiontype == "Boolean" then
		return "OptionsBoolean"
	end
	if optiontype == "Entry" then
		return "OptionsEntry"
	end
	if optiontype == "List" then
		return "OptionsList"
	end
	if optiontype == "ShortOption" then
		return "OptionsShort"
	end
	if optiontype == "LongOption" then
		return "OptionsLong"
	end
	return nil
end

-- set_value (parser, option, value, default) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description: Sets a value option.
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function set_value (parser, option, value, default)
	local id = parser.OptionsShort[option] or parser.OptionsLong[option]
	if not id then return false end
	local optiontype=parser.OptionsType[id]
	if optiontype == "Entry" then
		-- Checks if values are limited
		if parser.ValuesForEntry[id] and 
			not parser.ValuesForEntry[id][value] then
			return false
		end
	end
	local optiontable = get_table_for_option(optiontype)
	if not optiontable then return false end
	if default then
		parser.OptionsDefaults[id] = value
		return true
	end
	parser[optiontable][id] = value
	return true
end

-- set_boolean (parser, option, value, default) {{{2  
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description: Sets a Boolean option.
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function set_boolean (parser, option, value, default)
	if value then
		return set_value(parser,option, true, default)
	else
		return set_value(parser, option, false, default)
	end
end

-- set_entry (parser, option, value, default) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function set_entry (parser, option, value, default)
	return set_value(parser, option, value, default)
end

-- set_values4entry (parser, option, values) {{{2  
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function set_values4entry (parser, option, values)
	local id = parser.OptionsShort[option] or parser.OptionsLong[option]
	if not id then return false end
	local t = {}
	for i,v in ipairs(values) do
		t[v]=true
	end
	parser.ValuesForEntry[id] = t
	return true
end

-- set_list (parser, option, value, default) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function set_list (parser, option, value, default)
	local t = {}
	local str=value..":"
	for entry in str:gmatch("([^:]*):",0,"%1") do
		table.insert(t,entry)
	end
	return set_value(parser, option, t, default)
end

-- set_argument (parser, option) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function set_argument (parser, option)
	table.insert(parser.Arguments, option)
end

-- show_version (parser) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function show_version (parser)
	local str = parser.Program .." "..parser.Version
	io.write(str.."\n\n")
	if parser.Credits then
		io.write(parser.Credits.."\n")
	end
end

-- show_help (parser)  {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function show_help (parser)
	if parser.Usage then
		io.write("Usage: "..parser.Usage.."\n\n")
	else
		io.write("Usage: "..parser.Program.." [options]\n\n")
	end
	if parser.Description then
		io.write("Description: ")
		io.write(parser.Description.."\n\n")
	end
	io.write("Options: \n")
	for id, optiontype in ipairs(parser.OptionsType) do
		local optionsvalues = nil
		local short = parser.OptionsShort[id]
		local long = parser.OptionsLong[id]
		local desc = parser.OptionsDescription[id]
		local defaultvalue = parser.OptionsDefaults[id]
		local str = "    "
		if short then str=str.."-"..short..", " end
		if long then str=str.."--"..long end
		if optiontype == "Entry" then
			optionsvalues = parser.ValuesForEntry[id] or nil
			if optionsvalues then
				str = str .. " <"
				for v in pairs(optionsvalues) do
					str = str..v.."|"
				end
				str = str:match("(.*).$",0,"%1")
				str = str .. ">"
			else
				str = str .. " <entry>"
			end
		else
			if optiontype == "List" then
				str=str.." <entry>[:<entry>...]"
			end
		end
		if defaultvalue then
			str = str .. ", default is "..tostring(defaultvalue)
		end
		io.write(str)
		if desc then
			io.write("\n        "..desc.."\n")
		end
	end
	if parser.Example then
		io.write("\nExample: "..parser.Example.."\n")
	end
end

-- add_option (parser, optiontype, short, long, description) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- 	- To check "optiontype" before to assign it.
-- ---------------------------------------------------------------------------
local function add_option (parser, optiontype, short, long, description)
	if (not short and not long) or not optiontype then return false end
	local id = parser.nextID()
	if short then
		parser.OptionsShort[short] = id
		parser.OptionsShort[id] = short
	end
	if long then
		parser.OptionsLong[long] = id
		parser.OptionsLong[id] = long
	end
	if description then
		parser.OptionsDescription[id] = description
	end
	parser.OptionsType[id] = optiontype
	return true
end


-- map_boolean (self, initialvalue, func, arg) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function map_boolean (self, initialvalue, func, arg)
	local values = {}
	local status = initialvalue
	for i,option in ipairs(arg) do
		local id = self:isBoolean(option)
		if not id then return false end
		values[i] = self.OptionsBoolean[id] or self.OptionsDefaults[id]
		status = func (status, values[i])
	end
	return status, unpack(values)
end


-- map_entry (self, initialvalue, func, arg) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function map_entry (self, initialvalue, func, arg)
	local values = {}
	local status = initialvalue
	for i,option in ipairs(arg) do
		local id = self:isEntry(option)
		if not id then return false end
		values[i] = self.OptionsEntry[id] or self.OptionsDefaults[id]
		status = func (status, values[i])
	end
	return status, unpack(values,1,#arg)
end


-- Exported Functions {{{1
-- -------- ---------
-- usage (self) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function usage (parser)
	show_help(parser)
	os.exit(1)
end


-- addBoolean (self, short, long, description, value) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function addBoolean (self, short, long, description, value)
	if not add_option(self,"Boolean",short,long,description) then
		return false
	end
	if value then
		set_boolean(self, short or long, true, true)
	else
		set_boolean(self, short or long, false, true)
	end
	return true
end


-- addEntry (self, short, long, description, value, values) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function addEntry (self, short, long, description, value, values)
	if not add_option(self,"Entry",short,long,description) then
		return false
	end
	if values then 
		set_values4entry(self, short or long, values)
	end
	if value then
		set_entry(self, short or long, value, true)
	end
	return true
end

-- addList (self, short, long, description, value) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function addList (self, short, long, description, value)
	if not add_option(self, "List", short, long, description) then
		return false
	end
	if value then
		set_list(self, short or long ,value, true)
	end
end


-- isOption (self, option) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function isOption (self, option) 
	if not self.OptionsShort[self] or not self.OptionsLong[self] then
		return false
	end
	return true
end

-- isEntry (self, option) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function isEntry  (self, option)
	local id = self.OptionsShort[option] or self.OptionsLong[option]
	if not id then return false end
	return id
end


-- isList (self, option) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function isList (self, option)
	local id = self.OptionsShort[option] or self.OptionsLong[option]
	if not id then return false end
	if self.OptionsType[id] == "List" then return id end
	return false
end

-- isBoolean (self, option) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function isBoolean (self, option)
	local id = self.OptionsShort[option] or self.OptionsLong[option]
	if not id then return false end
	if self.OptionsType[id] == "Boolean" then return id end
	return false
end

-- arguments (self) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function arguments (self)
	if #self.Arguments == 0 then
		return nil
	end
	return self.Arguments
end

-- boolean (self, option) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function boolean (self, option)
	local id = self:isEntry(option)
	if not id then return false end
	return self.OptionsBoolean[id] or self.OptionsDefaults[id]
end

-- anyBoolean (self, ...) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function anyBoolean (self, ...)
	return map_boolean (self, false, function (a,b) return a or b end, arg)
end

-- allBoolean (self, ...) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function allBoolean (self, ...)
	return map_boolean (self, true, function (a,b) return a and b end, arg)
end

-- entry (self, option) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function entry (self, option)
	local id = self:isEntry(option)
	if not id then return false end
	return self.OptionsEntry[id] or self.OptionsDefaults[id]
end

-- anyEntry (self, ...) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function anyEntry (self, ...)
	local func = function (a,b)
		return a or not not b
	end
	return map_entry (self, false, func, arg)
end

-- allEntry (self, ...) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- 		self: OPTIONPARSER_INSTANCE
-- 		...: STRING
-- @output:
-- ---------------------------------------------------------------------------
-- Description: Returns true if all of the entry values passed as ... are
-- setted.
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function allEntry (self, ...)
	local func = function (a,b)
		return a and not not b
	end
	return map_entry (self, true, func, arg)
end

-- list (self, option) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- 		self: OPTIONPARSER_INSTANCE
-- 		option: 
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function list (self, option)
	local id = self:isList(option)
	if not id then return false end
	return self.OptionsList[id] or self.OptionsDefaults[id]
end

-- parseOptions (self, arguments) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- 		self: PARSER_INSTANCE
-- 		arguments: STRING
-- @output:
-- ---------------------------------------------------------------------------
-- Description: Parses the command line argument looking for arguments and
-- options.
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function parseOptions (self, arguments)
	local expectedtoken=nil
	local lastoption=nil
	local next_option=get_option(arguments)
	local option, token = next_option()
	while option do 
		-- Gets table for token type (short or long option)
		local table = get_table_for_option(token)
		if not table then 
			-- it's not an option
			if token == "EntryOption" or token == "ListOption" then
				set_argument(self, option)
			else
				usage(self)
			end
		else
			-- it's an option
			-- Looks if token is registered
			local id = self[table][option]
			if not id then usage(self) end
			local optiontype = self.OptionsType[id]
			-- Sets boolean value if token is boolean
			if optiontype == "Boolean" then
				set_boolean(self, option, true)
			-- the next token is expected to be ...
			else 
				if optiontype == "Entry" then
					local value, token = next_option()
					if value and token == "EntryOption" then
						set_entry(self, option, value)
					else
						usage(self)
					end
				else 
					if optiontype == "List" then
						local value, token = next_option()
						if value and (token == "ListOption" or token == "EntryOption") then
							set_list(self, option, value)
						else
							usage(self)
						end
					end
				end
			end
		end
		option, token = next_option()
	end
	if self:boolean("help") then
		usage(self)
	end
	if self:boolean("version") then
		show_version(self)
		os.exit(0)
	end
	if self:boolean("warnings") then
		output.Warnings = true
	end
	if self:boolean("no-warnings") then
		output.Warnings = false
	end
	if self:entry("verbose") then
		output.Verbose = tonumber(self:entry("verbose"))
	end
	if self:boolean("silent") then
		output.Silent = true
	end
end

-- Exported Interface {{{2
-- -------- ---------
methods = {
	usage = usage,
	addBoolean = addBoolean,
	addEntry = addEntry,
	addList = addList,
	isOption = isOption,
	isEntry = isEntry,
	isList = isList,
	isBoolean = isBoolean,
	arguments = arguments,
	boolean = boolean,
	anyBoolean = anyBoolean,
	allBoolean = allBoolean,
	entry = entry,
	anyEntry = anyEntry,
	allEntry = allEntry,
	list = list,
	parseOptions = parseOptions,
	isA="OptionParser Instance",
}


-- Constructor {{{1
-- -----------
-- new {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
new = function ()
	local parser = {}
	parser.Program = ""
	parser.Credits = ""
	parser.Version = ""
	parser.nextID = get_id()
	parser.OptionsType = {}
	parser.OptionsShort = {}
	parser.OptionsLong = {}
	parser.OptionsDescription = {}
	parser.OptionsEntry = {}
	parser.ValuesForEntry = {}
	parser.OptionsBoolean = {}
	parser.OptionsList = {}
	parser.OptionsDefaults = {}
	parser.Arguments = {}
	setmetatable(parser, {__index = methods})
	parser:addBoolean("h", "help", "Shows this help.")
	parser:addBoolean(nil, "version", "Shows program version.")
	parser:addBoolean(nil, "warnings", "Shows warning messages.")
	parser:addBoolean(nil, "no-warnings", "Hide all warning messages.")
	parser:addEntry(nil, "verbose", "Shows verbose message for that level.")
	parser:addEntry(nil, "silent", "Enable silent mode, only terse messages will be showed.")
	return parser
end

-- Types {{{1
-- Type OPTIONPARSER {{{2
types.add_type("OPTIONPARSER", function (v)
	return type(v) == "table" and v.isA == "OptionParser Instance"
end)
