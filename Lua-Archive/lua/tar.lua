-- vi: set foldmethod=marker foldlevel=0:
--
-- tar.lua
-- ---------------------------------------------------------------------------
-- LibArchive - 2007
-- ---------------------------------------------------------------------------
-- Author: Aitor Pérez Iturri - <aitor.iturri@gmail.com>	
-- Created: 28/11/07 21:43:40 CET
-- License: GNU GPL (see www.fsf.org for details)
-- ---------------------------------------------------------------------------
-- Description:
--
-- ---------------------------------------------------------------------------

require "tar.core"

-- Create module {{{1

module("tar", package.seeall)

-- Imports {{{1

require "posix"

-- Local Variables {{{1

local verbose_table = setmetatable({}, {__mode = 'k'})
local callback_table = setmetatable({}, {__mode = 'k'})

-- Exported Variables {{{1

-- Local Functions {{{1

--- Save the original open function, to use here as a local one
local opentar = tar.open

local function is_verbose ( tarhandler )
	if verbose_table[tarhandler] then
		return verbose_table[tarhandler]
	end
	return false
end  ----------  end of function is_verbose  ----------

local function extract_all ( tarhandler, path )
	local i=0
	local cwd = posix.getcwd()
	if not (posix.chdir(path)) then
		return nil, "chdir "..path..": "..posix.errno()
	end
	local entry, err = tarhandler:read()
	if err then
		posix.chdir(cwd)
		return nil, err
	end
	-- extract entry to disk
	while (entry) do
		if is_verbose(tarhandler) then
			print(entry.name)
		end
		_, err = tarhandler:extract()
		if err then
			posix.chdir(cwd)
			return nil, err
		end
		entry, err = tarhandler:read()
		if err then
			posix.chdir(cwd)
			return nil, err
		end
		i = i + 1
	end
	posix.chdir(cwd)
	return i
end  ----------  end of function extractAll  ----------


local function add_path ( tarhandler, path )
	local prefix = path or ""
	local filestable = posix.dir(path or ".")
	if not filestable then
		return 0, "stat ".. path or "." .. ": "..posix.errno()
	end
	local n = 0
	local i = 3
	while filestable[i] do
		tarhandler:write(prefix..filestable[i])
		if is_verbose(tarhandler) then
			print(prefix..filestable[i])
		end
		n = n + 1
		if posix.stat(prefix..filestable[i]).type == "directory" then
			n, err = n + add_path (tarhandler, prefix..filestable[i].."/")
			if err then
				return n, err
			end
		end
		i = i + 1
	end
	return n
end  ----------  end of function add_tree  ----------

local function add_tree ( tarhandler, tree, prefix )
	local cwd = posix.getcwd()
	if not posix.chdir(tree) then
		return nil, posix.errno()
	end
	return add_path (tarhandler)
end  ----------  end of function addTree  ----------

local function set_verbose ( tarhandler )
	verbose_table[tarhandler] = true
	return true
end  ----------  end of function set_verbose  ----------

local function unset_verbose ( tarhandler )
	verbose_table[tarhandler] = false
	return false
end  ----------  end of function unset_verbose  ----------

-- Exported Functions {{{1

function open (file, mode, compression)
	local f, err = opentar(file,mode,compression)
	if not f then 
		return nil, err
	end
	local mt = getmetatable(f)
	local fmode = f:mode()
	mt.setVerbose = set_verbose
	mt.unsetVerbose = unset_verbose
	if fmode == "write" then
		mt.addTree = add_tree
	else 
		if fmode == "read" then
		mt.extractAll = extract_all
		end
	end
	return f
end

-- Types

