#!/bin/lua

-- vi: set foldmethod=marker foldlevel=0:
--
-- test.lua
-- ---------------------------------------------------------------------------
--  - 2007
-- ---------------------------------------------------------------------------
-- Author: Aitor Pérez Iturri - <aitor.iturri@gmail.com>	
-- Created: 14/11/07 14:29:47 CET
-- License: GNU GPL (see www.fsf.org for details)
-- ---------------------------------------------------------------------------
-- Description:
--
-- ---------------------------------------------------------------------------

package.cpath="../../.libs/?.so;"..package.cpath
package.path="../../lua/?.lua;"..package.path

require "tar"
require "posix"
require "GoboLinux.OptionParser"
require "GoboLinux.output"

local output = GoboLinux.output

local luatar = GoboLinux.OptionParser.new()

luatar.Program = "lTar"
luatar.Version = "1.0"
luatar.Credits = "Aitor Pérez Iturri - GNU GPL"
luatar.Description = "Little implementation of tar command in lua"
luatar.Example = arg[0] .. " -z -x -f foo.tar -C /tmp"
luatar:addBoolean("t","list", "List tar contents")
luatar:addBoolean("x","extract", "Extract tar contents")
luatar:addEntry("f","file", "Use specific tar file")
luatar:addBoolean("c","create", "Create a new specific tar file")
luatar:addBoolean("z","gzip", "Uses gzip to compress or decompress the tar file")
luatar:addBoolean("j","bzip2", "Uses bzip2 to compress or decompress the tar file")
luatar:addEntry("C",nil,"Changes to dir before to do the work")
luatar:addBoolean("s", "silent", "Doesn't show any output, only errors")

local function luatar_list (file, compression)
	local fd, err = tar.open(file,"r", compression)
	if not fd then
		output.log_error("Error luatar_list: "..err)
		return false
	end

	local entry, err = fd:read()
	if not entry then
		output.log_error("Error luatar_list:" ..err)
		fd:close()
		return false
	end

	while entry do
		output.log_terse(entry.name);
		entry, err  = fd:read()
	end

	fd:close()
	return true
end

local function luatar_extract (file, compression, path)
	local fd, error = tar.open(file, "r", compression)
	if not fd then
		output.log_error("Error luatar_extract: "..err)
		return false
	end

	if not luatar:boolean("s") then
		fd:setVerbose()
	end

	local _, err = fd:extractAll(path)
	if err then
		output.log_error("Error luatar_extract: "..err)
		fd:close()
		return false
	end

	fd:close()
	return true
end

local function luatar_create (file, compression, tree)
	local fd, err = tar.open(file, "w", compression)
	if not fd then
		output.log_error("Error luatar_create: "..err)
		return false
	end

	if not luatar:boolean("s") then
		fd:setVerbose()
	end

	local n, err = fd:addTree(tree)
	if err then
		output.log_error("Error luatar_create: "..err)
		fd:close()
		return false
	end

	fd:close()
	return true
end

local function main (argc, argv)
	local success
	if argc == 0 then
		luatar:usage()
	end
	luatar:parseOptions(argv)
	
	-- Gets tar file
	local tarfile = luatar:entry("f")
	if not tarfile then
		luatar:usage()
	end

	-- Gets arguments
	local arguments = luatar:arguments()

	-- Gets compression mode
	local compression
	if luatar:boolean("z") then
		compression="gzip"
	elseif luatar:boolean("j") then
		compression="bzip2"
	else
		compression="none"
	end

	-- Gets operation requested
	if (luatar:boolean("t")) then
		success = luatar_list(tarfile, compression)
	elseif luatar:boolean("c") then
		if not arguments then 
			luatar:usage()
		end
		success = luatar_create(tarfile, compression, arguments[1])
	elseif luatar:boolean("x") then
		local path = luatar:entry("C")
		success = luatar_extract(tarfile, compression, path or ".")
	else
		luatar:usage()
	end
	if not success then
		os.exit(1)
	else
		os.exit(0)
	end
end

-- Call main
main(#arg, arg)
