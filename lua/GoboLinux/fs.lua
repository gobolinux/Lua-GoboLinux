-- vim: set foldmethod=marker foldlevel=0:
--
-- fs.lua
-- ---------------------------------------------------------------------------
-- GoboLinux Lua Library - 2007
-- ---------------------------------------------------------------------------
-- Author: Aitor Pérez Iturri - <aitor.iturri@gmail.com>	
-- Created: 20/09/07 10:12:16 CEST
-- License: GNU GPL (see www.fsf.org for details)
-- ---------------------------------------------------------------------------
-- Description:
--  Module which implements high level filesystem functions.
-- ---------------------------------------------------------------------------

require "GoboLinux.fs.core"

-- Create a new module {{{1
module("GoboLinux.fs", package.seeall)

-- Import Modules {{{1
require "posix"
require "switch"
require "rex_pcre"
require "GoboLinux"
require "GoboLinux.types"
require "GoboLinux.errors"

local errors = GoboLinux.errors
local types = GoboLinux.types

-- Local variables {{{1
local Local = {} -- Table to store local functions.

 -- Local functions {{{1
-- map_file (stat, map_func) {{{2
-- ---------------------------------------------------------------------------
-- @input:
--		stat: Stat Table
-- @output:
--		map_func: function (stat) end
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function map_file (file, ...)
	local stat = Local.get_stat(file)
	if not stat then
		return nil
	end
	local result=true
	for _, func in ipairs(arg) do
		result = result and func(stat)
		if result == false then break end
	end
	return result
end
Local["map_file"] = map_file


-- get_stat (file) {{{2
-- ---------------------------------------------------------------------------
-- @input:
--		file: "String" | "Stat Table"
-- @output:
--		"Stat Table"
-- ---------------------------------------------------------------------------
-- Description:
--	Function that returns a table with stat file info, it can get as arguments
--  a string representing a file or a stat table.
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
local function get_stat (file)
	return switch(type(file)):caseof{
		["string"] = function ()
			return posix.stat(file)
		end,
		["table"] = function ()
			if file.type then
				return file
			else
				return nil
			end
		end
	}
end
Local["get_stat"] = get_stat

-- paths (path) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
 function paths ( path )
	local passed=""
	local iterator=rex_pcre.gmatch(path,"(/?[^ \t\n\r\f\v\/]+/?)")
	local last=iterator()
	return function ()
		-- end the closure
		if not last then return nil end
		passed=passed..last
		local path = last
		last=iterator()
		return passed, path
	end
end  ----------  end of function paths  ----------

-- tree_iter (path) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function tree_iter ( path )
	local nexts = {}
	local paths = {}
	local i = 1
	nexts[i] = files(path)
	paths[i] = path
	return function ()
		local entry = nexts[i]()
		if not entry then
			while (i > 1) and not entry do
				i = i - 1
				entry = nexts[i]()
			end
			if i == 0 then return nil end
		end
		if is_directory(entry) then 
			i = i + 1
			paths[i] = paths[i-1].."/"..entry.name
			nexts[i] = files(paths[i])
			return entry, i-2
		else
			return entry, i-1
		end
	end

end  ----------  end of function tree_iter  ----------
-- Exported Functions {{{1
-- is_regular (file) {{{2
-- ---------------------------------------------------------------------------
-- @input:
--		file: Path String | Stat Table
-- @output:
--		Boolean
-- ---------------------------------------------------------------------------
-- Description: Returns true if 'file' is a regular file, false otherwise.
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function is_regular (file)
	return map_file(file, function (stat) 
		return stat.type == "regular"
		end)
end  ----------  end of function isFile  ----------

-- is_file (file) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- 		file: Path String | Stat Table
-- @output:
-- 		Boolean
-- ---------------------------------------------------------------------------
-- Description: Returns true if 'file' is a file (a regular one or a symlink).
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function is_file (file)
	return is_regular(file) or is_symlink(file)
end  ----------  end of function is_file  ----------


function is_path ( path )
	return is_file(path) or is_directory(path)
end  ----------  end of function is_path  ----------

-- is_directory (dir) {{{2
-- ---------------------------------------------------------------------------
-- @input:
--		dir: Path String | Stat Table
-- @output:
--		Boolean
-- ---------------------------------------------------------------------------
-- Description: Returns true if 'dir' is a directory, false otherwise.
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function is_directory (dir)
	return map_file(dir, function (stat)
		return stat.type == "directory"
	end)
end  ----------  end of function isDirectory  ----------


-- is_symlink (link) {{{2
-- ---------------------------------------------------------------------------
-- @input:
--		link: Path String | Stat Table
-- @output:
--		Boolean
-- ---------------------------------------------------------------------------
-- Description: Returns true if 'link' is a symlink, false otherwise.
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function is_symlink (link)
	return map_file(link, function (stat)
		return stat.type == "link"
	end)
end  ----------  end of function isLink  ----------


-- is_executable (file) {{{2
-- ---------------------------------------------------------------------------
-- @input:
--		file: Path String | Stat Table
-- @output:
--		Boolean
-- ---------------------------------------------------------------------------
-- Description: Returns true if 'file' is executable by user, false otherwise.
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function is_executable (file)
	return map_file(file, function (stat)
		local passwd=posix.getpasswd()
		local is_executable = string.match(stat.mode,"........x") or
			string.match(stat.mode,".....x...") and passwd.gid == stat.gid or
			string.match(stat.mode,"..x......") and passwd.uid == stat.uid
		if not is_executable then return false end
		return true
	end)
end  ----------  end of function is_executable  ----------


-- is_writable (file) {{{2
-- ---------------------------------------------------------------------------
-- @input:
--		file: Path String | Stat Table
-- @output:
--		Boolean
-- ---------------------------------------------------------------------------
-- Description: Returns true if 'file' is writable by user, false otherwise.
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function is_writable (file)
	return map_file(file, function (stat)
		local passwd = posix.getpasswd()
		local is_writable = string.match(stat.mode,".......w.") or
		string.match(stat.mode,"....w....") and passwd.gid == stat.gid or
		string.match(stat.mode,".w.......") and passwd.uid == stat.uid
		if not is_writable then return false end
		return true
	end)
end  ----------  end of function isWritable  ----------


-- is_readable (file) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- 		file: Path String | Stat Table
-- @output:
-- 		Boolean
-- ---------------------------------------------------------------------------
-- Description: Returns true if `file` is readable by user, false otherwise.
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function is_readable (file)
	return map_file(file, function (stat)
		local passwd = posix.getpasswd()
		local is_readable = string.match(stat.mode,"......r..") or
		string.match(stat.mode,"...r.....") and passwd.gid == stat.gid or
		string.match(stat.mode,"r........") and passwd.uid == stat.uid
		if not is_readable then return false end
		return true
	end)
end  ----------  end of function is_readable  ----------

-- pwd ()  {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function pwd (  )
	return posix.getcwd()
end  ----------  end of function pwd  ----------


-- dirname (path) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function dirname ( path )
	local dir
	dir = string.gsub(path.."/","/+$","/"):match("(.*)/.*/")
	if not dir or dir == "" then
		dir = "/"
	end
	return dir
end  ----------  end of function dirname  ----------


-- basename (path) {{{2  
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function basename ( path  )
	local base
	base = path:gsub("/+$",""):match("/.*/(.*)")
	if not base then 
		base = path:gsub("/+$",""):match("/(.*)")
	end
	return base
end  ----------  end of function basename (path)  ----------
-- files (path) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function files ( path )
	if not types.check_arg("fs.files()", 1, path, "PATH_STRING") then
		errors.new_error("Unable to found "..path)
		return function () return nil end
	end
	local entries
	if is_directory(path) then
		entries=posix.dir(path)
	else if is_symlink(path) then
		entries=posix.dir(dereference(readlink(path),dirname(path)))
	else
		-- path is not a directory so store at index 3 the path to return it
		entries = {}
		entries[3]=""
	end end
	local i = 3
	return function () 
		if not entries[i] then return nil end -- end of closure
		local entry = entries[i]
		i = i + 1
		local stat = posix.stat(path.."/"..entry)
		if not stat then return nil end
		-- Add name to stat table
		stat.name=entry
		stat.path=path.."/"..entry
		return stat
	end
end  ----------  end of function files  ----------


-- tree (path) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function tree ( path, ... )
--	if not types.check_arg("fs.files()", 1, path, "PATH_STRING") then
--		errors.new_error("Unable to found "..(path or "nil"))
--		return function () return nil end
--	end
	if #arg == 0 then
		-- Only one path to iterate over
		return tree_iter(path)
	else
		local paths, i, entry, level
		i = 0
		paths = {}
		if is_path(path) then
			paths[1] = path
			i = 1
		end
		for j,v in ipairs(arg) do
			if is_path(v) then
--			if not types.check_type(path, "PATH_STRING") then
--				errors.new_error("Unable to found "..path, func_name)
--				return function () return nil end
--			end
				paths[j+i] = v
			end
		end
		if #paths == 0 then
			return function () return nil end
		end
		i = 1
		iter = tree_iter(paths[i])
		return function ()
			entry, level = iter ()
			if not entry then
				i = i + 1
				if paths[i] then
					iter = tree_iter(paths[i])
					entry, level = iter()
				end
			end
			return entry, level
		end
	end
end  ----------  end of function tree  ----------

-- cd (path) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function cd ( path )
	local func_name="fs.cd()"
	if not types.check_arg(func_name,1,path,"STRING") then
		return false
	end
	if not is_readable(path) and not is_executable(path) then
		errors.new_error(func_name..":Could not access directory "..path..
			" from "..pwd())
		return false
	end
	posix.chdir(path)
	return true
end  ----------  end of function cd  ----------

-- mkdir (dir) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function mkdir ( path )
	local func_name = "fs.mkdir()"
	for p in paths(path) do
		if not is_path(p) and not posix.mkdir(p) then
			errors.new_error(posix.errno(), func_name..":"..pwd()..p)
			return false
		end
	end
	return true
end  ----------  end of function mkdir  ----------

-- mkdir_butlast (path, nlast) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function mkdir_butlast ( path, nlast )
	local i = 1
	local npath = path
	-- remove last n members in path
	while i <= (nlast or 1) do
		npath = string.match(npath,"(.*)/[^/]")
		if not npath or npath == "" then
			return true
		end
		i = i + 1
	end
	-- create dirs
	for p in paths(npath) do
		if not mkdir(p) then
			errors.new_error(errors.error(),func_name)
			return false
		end
	end
	return true
end  ----------  end of function mkdir_butlast  ----------


-- symlink (orig, dest) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function symlink ( orig, dest )
	local func_name = "fs.symlink()"
	if not types.check_arg(func_name, 1, orig, "STRING") then
		return false
	end
	if not types.check_arg(func_name, 2, dest, "STRING") then
		return false
	end
	if not posix.symlink(orig, dest) then
		local error_str = pwd().."/"..orig .." -> "..pwd().."/"..dest
		errors.new_error(posix.errno(), func_name..":"..error_str)
		return false
	end
	return true
end  ----------  end of function symlink  ----------

-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------

-- rm (path) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function rm ( path )
	local func_name="fs.rm()"
	if not types.check_arg(func_name, 1, path, "PATH_STRING") then
		errors.new_error(func_name..":"..errors.error())
		return nil
	end
	if not posix.unlink(path) then
		errors.new_error(posix.errno(), func_name)
		return nil
	end
	return true
end  ----------  end of function rm  ---------- 

-- rmdir (dir) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function rmdir ( dir )
	local func_name="fs.rmdir()"
	if not types.check_arg(func_name, 1, dir, "PATH_STRING") then
		errors.new_error(errors.error(), func_name)
		return nil
	end
	local skip_level=0
	for file, level in tree(dir) do
		if is_directory(file.path) then
			if not rmdir(file.path) then
				errors.new_error(errors.error(), func_name)
				return nil
			end
			skip_level = level + 1
		elseif level <= skip_level then
			if not rm(file.path) then
				errors.new_error(errors.error(), func_name)
				return nil
			end
		end
	end
	if not posix.rmdir(dir) then
		errors.new_error(posix.errno(), func_name)
		return nil
	end
	return true
end  ----------  end of function rmdir  ----------

-- mv (from, to) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
--[[function mv ( from, to )
	local func_name="fs.mv()"
	if not types.check_arg(func_name, 1, from, "PATH_STRING") then
		errors.new_error(errors.error(), func_name)
		return nil
	end
	if not types.check_arg(func_name, 2, to, "STRING") then
		errors.new_error(errors.error(), func_name)
		return nil
	end
end  ----------  end of function mv  ------------]]

-- cp (orig, dest) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function cp ( orig, dest )
	local func_name = "fs.cp()"
	local fd_orig, fd_dest, err, orig_stat
	local bufffer = 2048
	fd_orig, err = io.open(orig,"rb")
	if not fd_orig then
		errors.new_error(err, func_name)
		return nil
	end
	if not dest then 
		errors.new_error("Destination is nil",func_name)
		return nil
	end
	fd_dest, err = io.open(dest, "wb")
	if not fd_dest then
		errors.new_error(err, func_name)
		return nil
	end
	orig_stat = posix.stat(orig)
	local data = fd_orig:read(255)
	while data do
		fd_dest:write(data)
		data = fd_orig:read(255)
	end
	fd_orig:close()
	fd_dest:close()
	posix.chmod(dest, orig_stat.mode)
	return true
end  ----------  end of function cp  ----------

-- cpdir (orig, dest) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function cpdir ( orig, dest )
	local func_name = "fs.cpdir()"
	if not types.check_arg(func_name, 1, orig, "DIRECTORY_STRING") then
		return nil
	end
	if not is_directory(dest) then
		if not mkdir(dest) then
			errors.new_error(errors.error(), func_name)
			return nil
		end
	end
	local cwd, last_level, orig_path, status
	cwd = pwd()
	if is_absolute_path(orig) then
		orig_path = orig
	else
		orig_path = pwd().."/"..orig
	end
	if not cd(dest) then
		errors.new_error(errors.error(), func_name)
		cd(cwd)
		return nil
	end
	status = true
	for file in files(orig_path) do
		if is_directory(file) then
			status = cpdir(orig_path.."/"..file.name, pwd().."/"..file.name)
		elseif is_symlink(file) then
			if not symlink(readlink(orig_path.."/"..file.name), 
				pwd().."/"..file.name) then
				errors.new_error(errors.error(), func_name)
				return false
			end
		else
			if not cp(file.path, pwd().."/"..file.name) then
				errors.new_error(errors.error(), func_name)
				return false
			end
		end
	end
	cd(cwd)
	return status
end  ----------  end of function cpdir  ----------
-- symlink_relative (orig, dest) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function symlink_relative (orig, dest, relative_to)
	local func_name = "fs.symlink_relative()"
	local paths_iter, first, next, cwd
	if relative_to and is_directory(relative_to) then
		cwd = pwd()
		if not cd(relative_to) then
			cwd = nil
		end
	end
	if not types.check_arg(func_name, 1, orig, "STRING") then
		if cwd then cd(cwd) end
		return false
	end
	if not types.check_arg(func_name, 2, dest, "STRING") then
		if cwd then cd(cwd) end
		return false
	end
	-- iterate over the paths to get
	for _ in paths(dirname(dest)) do
		orig="../"..orig
	end
	if not posix.symlink(orig:gsub("/+","/"), dest:gsub("/+","/")) then
		local error_str = pwd().."/"..dest.. " -> " .. orig
		errors.new_error(posix.errno(),func_name..":"..error_str)
		if cwd then cd(cwd) end
		return false
	end
	if cwd then cd(cwd) end
	return true
end  ----------  end of function symlink_relative (orig, dest)  ----------


-- readlink (path) {{{2
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function readlink ( path )
	local func_name = "fs.readlink()"
	local value
	if not types.check_arg(func_name, 1, path, "PATH_STRING") then
		return nil
	end
	local 
	value = posix.readlink(path)
	if not value then
		errors.new_error(posix.errno(), func_name)
		return nil
	end
	return value:gsub("/+","/")
end  ----------  end of function readlink  ----------

-- dereference (path, refered_to) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function dereference ( path, refered_to )
	local dest_paths = {}
	local orig_paths = {}
	if is_absolute_path(path) then
		return path
	end
	local new_path = refered_to:gsub("/+","/")
	for _,path in paths(path) do
		if not path then break end
		if path:gsub("/+$","") == ".." then
			new_path = new_path:match("(.*)/+[^/]")
		else if path == "." then
			new_path = new_path
		else
			new_path = new_path.."/"..path:gsub("/+$","")
		end end
	end
	return new_path
end  ----------  end of function dereference  ----------


-- is_absolute_path(path) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------
function is_absolute_path (path) 
	return path:match("^/+.*")
end  ----------  end of function is_absolute_path (path)  ----------


-- stat (path) {{{2 
-- ---------------------------------------------------------------------------
-- @input:
-- @output:
-- ---------------------------------------------------------------------------
-- Description:
-- ---------------------------------------------------------------------------
-- Todo:
-- ---------------------------------------------------------------------------

function stat ( path )
	local func_name="fs.stat()"
	local stat_table = {}
	stat_table = posix.stat(path)
	if not stat_table then
		errors.new_error(posix.errno(), func_name)
		return nil
	end
	if is_absolute_path then
		stat_table.path = path
	else
		stat_table.path = (pwd().."/"..path):gsub("/+","/")
	end
	stat_table.name = basename(path)
	return stat_table
end  ----------  end of function stat  ----------
-- Types {{{1
-- Type PATH_STRING {{{2
GoboLinux.types.add_type("PATH_STRING", function (v)
		return type(v) == "string" and get_stat(v) ~= nil
	end
	)
-- Type REGULAR_STRING {{{2
GoboLinux.types.add_type("REGULAR_STRING", function (v)
		return type(v) == "string" and is_regular(v) 
	end
	)
-- Type DIRECTORY_STRING {{{2
GoboLinux.types.add_type("DIRECTORY_STRING", function (v)
		if type(v) ~= "string" or not is_directory(v) then
			errors.new_error("'"..tostring(v).."' is not DIRECTORY_STRING")
			return false
		end
		return true
	end)
-- Type SYMLINK_STRING {{{2
GoboLinux.types.add_type("SYMLINK_STRING", function (v)
		return type(v) == "string" and is_symlink(v)
	end)

