/*
 * =====================================================================================
 *
 *       Filename:  luaarchive.c
 *
 *    Description:  Functions to operate with the lua stack.
 *
 *        Version:  1.0
 *        Created:  20/11/07 10:48:40 CET
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  Aitor Pérez Iturri (api), aitor.iturri@gmail.com
 *        Company:  ia Systems
 *
 * =====================================================================================
 */

#include	<lua.h>
#include	<lualib.h>
#include	<lauxlib.h>
#include	<archive.h>
#include	<archive_entry.h>
#include	<errno.h>
#include	<string.h>
#include	<sys/types.h>
#include	<sys/stat.h>
#include	<fcntl.h>

#include	"luaarchive.h"
#include	"aux.h"

	int
luaarchive_pusherror ( lua_State * L, char * str )
{
	lua_pushnil(L);
	lua_pushstring(L, str);
	return 2;

}		/* -----  end of function luaarchive_pusherror  ----- */

	int
luaarchive_pusharchiveerror( lua_State * L, luaarchive_p archivehandler )
{
	lua_pushnil(L);
	lua_pushstring(L, archive_error_string(archivehandler->archive));
	aux_finish(archivehandler);
	return 2;
}		/* -----  end of function luaarchive_pusharchiveerror(  ----- */


	int
luaarchive_pushentrytable ( lua_State * L , archive_entry_p entry)
{
	struct st * filestat;
	lua_createtable(L, 0, 0);
	// Put stat values into te table
    lua_pushinteger(L, (lua_Integer) archive_entry_dev(entry));
	lua_setfield(L, -2, "dev");
  	lua_pushinteger(L, (lua_Integer) archive_entry_gid(entry));
	lua_setfield(L, -2, "gid");
    lua_pushinteger(L, (lua_Integer) archive_entry_uid(entry));
	lua_setfield(L, -2, "uid");
	lua_pushinteger(L, (lua_Integer) archive_entry_ino(entry));
	lua_setfield(L, -2, "ino");
	lua_pushinteger(L, (lua_Integer) archive_entry_atime(entry));
	lua_setfield(L, -2, "atime");
	lua_pushinteger(L, (lua_Integer) archive_entry_ctime(entry));
	lua_setfield(L, -2, "ctime");
	lua_pushinteger(L, (lua_Integer) archive_entry_mtime(entry));
	lua_setfield(L, -2, "mtime");
	lua_pushstring(L, aux_filetype(archive_entry_mode(entry)));
	lua_setfield(L, -2, "type");
	lua_pushinteger(L, (lua_Integer) archive_entry_size(entry));
	lua_setfield(L, -2, "size");
	lua_pushinteger(L, (lua_Integer) archive_entry_mode(entry));
	lua_setfield(L, -2, "mode");
	lua_pushinteger(L, (lua_Integer) archive_entry_nlink(entry));
	lua_setfield(L, -2, "nlink");
	lua_pushstring(L, (char *) archive_entry_pathname(entry));
	lua_setfield(L, -2, "name");
	return -1;
}		/* -----  end of function luaarchive_pushentrytable  ----- */

	luaarchive_p
luaarchive_tohandler ( lua_State *L, int index, char * metatable )
{
	luaarchive_p archivehandler;
	archivehandler = (luaarchive_p) luaL_checkudata(L, index, metatable);
	return archivehandler;

}		/* -----  end of function luaarchive_tohandler  ----- */


	int
luaarchive_tocompression ( lua_State *L, int narg, char * mode )
{
	const char * compression_modes_read [] = {
		"none",
		"gzip",
		"bzip2",
		"compress",
		"all",
		NULL
	};
	const char * compression_modes_write [] = {
		"none",
		"gzip",
		"bzip2",
		NULL
	};
	switch (aux_getmode(mode)) {
		case LUAARCHIVE_RDMODE:
			return luaL_checkoption (L, narg, "all", compression_modes_read);
		case LUAARCHIVE_WRMODE:
			return luaL_checkoption (L, narg, "none", compression_modes_write);
		default:
			return luaarchive_pusherror(L, LUAARCHIVE_ERRMSG_BADCOMPRESSION);
	}
}		/* -----  end of function luaarchive_tocompression  ----- */

	int
luaarchive_new ( lua_State *L, char * mode, char * metatable )
{
	luaarchive_p archivehandler;
	archivehandler = (luaarchive_p) lua_newuserdata(L, sizeof(luaarchive_t));
	archivehandler->nextentry = NULL;
	switch (aux_getmode(mode)) {
		case LUAARCHIVE_RDMODE:
			archivehandler->archive = archive_read_new();
			archivehandler->mode = LUAARCHIVE_RDMODE;
			break;
		case LUAARCHIVE_WRMODE:
			archivehandler->archive = archive_write_new();
			archivehandler->mode = LUAARCHIVE_WRMODE;
			break;
		default:
			lua_pushstring(L, LUAARCHIVE_ERRMSG_UNKMODE);
			return 0;
	}
	// Sets the metatable
	luaL_getmetatable(L, metatable);
	lua_setmetatable(L, -2);
	return 1;
}		/* -----  end of function luaarchive_new  ----- */


	int
luaarchive_close ( lua_State *L, char * metatable )
{
	luaarchive_p handler;
	handler = luaarchive_tohandler(L, 1, metatable);
	if (!handler)
		return luaL_argerror(L, 1, "expected archive handler");
	if (!aux_close(handler)) {
		lua_pushstring(L, archive_error_string(handler->archive));
		return 0;
	}
	lua_pushnil(L);
	return 1;
}		/* -----  end of function luaarchive_close  ----- */


	int
luaarchive_read ( lua_State *L, char * metatable )
{
	luaarchive_p handler;
	archive_entry_p entry;
	int status;
	handler = luaarchive_tohandler(L, 1, metatable);

	if (!handler) 
		return luaarchive_pusherror(L, "expected archive handler.");
	// Skip data if is not the first read
	if (handler->nextentry) {
//		archive_entry_free(handler->nextentry);
		handler->nextentry = NULL;
	}

	if (archive_read_header_position(handler->archive) != 0) 
		if (archive_read_data_skip(handler->archive) != ARCHIVE_OK)
			return luaarchive_pusherror(L, 
					(char *)archive_error_string(handler->archive));
	status = archive_read_next_header(handler->archive, &entry);
	if ( status	!= ARCHIVE_OK)
		if (status == ARCHIVE_EOF) {
			lua_pushnil(L);
			return 1;
		}
		else
			return luaarchive_pusherror(L, 
					(char *)archive_error_string(handler->archive));
	luaarchive_pushentrytable(L, entry);
//	lua_pushstring(L, (char *) archive_entry_pathname(entry));
	handler->nextentry = entry;
	return 1;

}		/* -----  end of function luaarchive_read  ----- */


	int
luaarchive_extract ( lua_State * L, char * metatable )
{
	luaarchive_p handler;
	int options=0;
	handler = luaarchive_tohandler (L, 1, metatable);

	if (!handler) 
		return luaarchive_pusherror(L, "expected archive handler.");

	if (!handler->nextentry) {
		lua_pushnil(L);
		return 1;
	}

	// Get options

	if (archive_read_extract(handler->archive, handler->nextentry, options))
		return luaarchive_pusherror(L, 
				(char *) archive_error_string(handler->archive));
	else
		lua_pushstring(L, archive_entry_pathname(handler->nextentry));
	return 1;
}		/* -----  end of function luarchive_extract  ----- */

	int
luaarchive_write ( lua_State * L, char * metatable )
{
	luaarchive_p handler;
	archive_entry_p entry;
	char * file;
	struct stat filestat;
	int fd, len, totallen=0;
	char buff [255];
	handler = luaarchive_tohandler(L, 1, metatable);

	if (!handler)
		return luaarchive_pusherror(L, "expected archive handler.");

	file = (char *) luaL_checkstring(L, 2);

	if (lstat(file, &filestat)) 
		return luaarchive_pusherror(L, strerror(errno));
	entry = archive_entry_new();
	archive_entry_copy_stat(entry, &filestat);
	archive_entry_set_pathname(entry, file);

	// Needed to cast filestat.st_size, because in linux it's
	// size_t type.
	archive_entry_set_size(entry, (int64_t) filestat.st_size);
	
	if (archive_write_header(handler->archive, entry)) {
		printf("%s\n",archive_error_string(handler->archive));
	}
	fd = open(file, O_RDONLY);
	if (fd < 0) {
		archive_entry_free(entry);
		return luaarchive_pusherror(L, strerror(errno));
	}
 	len = read(fd, buff, sizeof(buff));
	while ( len > 0 ) {
		totallen += len;
	   	archive_write_data(handler->archive, buff, len);
	   	len = read(fd, buff, sizeof(buff));
	}
	archive_entry_free(entry);
	//archive_write_finish_entry(handler->archive);
	lua_pushnumber(L, totallen);
	return 1;
}		/* -----  end of function luaarchive_write  ----- */

	int
luaarchive_type ( lua_State * L, char * metatable )
{
	luaarchive_p handler;
	char * type;
	char * compression;
	handler = luaarchive_tohandler(L, 1, metatable);
	if (!handler)
		return luaarchive_pusherror(L, "expected archive handler.");
	type = (char *)archive_format_name(handler->archive);
	compression = (char *)archive_compression_name(handler->archive);
	lua_pushstring(L, aux_gettypename(handler->type));
	lua_pushstring(L, compression);
	return 2;

}		/* -----  end of function luaarchive_type  ----- */


	int
luaarchive_entry ( lua_State * L , char * metatable )
{
	luaarchive_p handler;
	handler = luaarchive_tohandler(L, 1, metatable);

	if (handler->nextentry == NULL) {
		lua_pushnil(L);
		return 1;
	}

	luaarchive_pushentrytable(L, handler->nextentry);
	return 1;
}		/* -----  end of function luaarchive_entry  ----- */


	int
luaarchive_mode ( lua_State *L, char * metatable )
{
	luaarchive_p handler;
	handler = luaarchive_tohandler(L, 1, metatable);
	
	lua_pushstring(L, aux_mode(handler));
	return 1;
}		/* -----  end of function luaarchive_mode  ----- */
