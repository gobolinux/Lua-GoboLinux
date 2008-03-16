/*
 * =====================================================================================
 *
 *       Filename:  luaarchive.h
 *
 *    Description:  Functions to operate with lua stack. 
 *    				Header file, includes some macros.
 *
 *        Version:  1.0
 *        Created:  20/11/07 09:58:20 CET
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  Aitor Pérez Iturri (api), aitor.iturri@gmail.com
 *        Company:  ia Systems
 *
 * =====================================================================================
 */
#ifndef _LUA_ARCHIVE_H_
#define _LUA_ARCHIVE_H_

#include		<lua.h>

#define LUAARCHIVE_RDMODE					0
#define LUAARCHIVE_WRMODE					1
#define LUAARCHIVE_UNKMODE					2

#define LUAARCHIVE_TAR						1
#define LUAARCHIVE_CPIO						2
#define LUAARCHIVE_ISO9660					3
#define LUAARCHIVE_MTREE					4

#define LUAARCHIVE_NOCOMPRESSION			0
#define LUAARCHIVE_GZIP						1
#define LUAARCHIVE_BZIP2					2
#define LUAARCHIVE_COMPRESS					3
#define LUAARCHIVE_ALLCOMPRESSION			4

#define LUAARCHIVE_ERR_UNKMODE				(-40)
#define LUAARCHIVE_ERR_UNKTYPE				(-41)
#define LUAARCHIVE_ERR_UNKCOMPRRESION		(-42)
#define LUAARCHIVE_ERR_BADCOMPRESSION		(-43)

#define LUAARCHIVE_ERRMSG_UNKMODE			"Invalid openning mode."
#define LUAARCHIVE_ERRMSG_UNKTYPE			"Invalid type."
#define LUAARCHIVE_ERRMSG_UNKCOMPRESSION	"Invalid compression."
#define LUAARCHIVE_ERRMSG_BADCOMPRESSION	"Compression not supported in this mode."

typedef struct archive * archive_p;
typedef struct archive_entry * archive_entry_p;

struct luaArchiveHandler {
	archive_p archive;
	archive_entry_p nextentry;
	int type;
	int mode;
	int compression;
};

typedef struct luaArchiveHandler luaarchive_t;
typedef struct luaArchiveHandler * luaarchive_p;

int luaarchive_pusherror (lua_State *, char *);
int luaarchive_pusharchiveerror (lua_State *, luaarchive_p);
//int luaarchive_pushferror (lua_State *, char *, ...);
luaarchive_p luaarchive_tohandler (lua_State *, int, char *);
int luaarchive_tocompression(lua_State *, int,  char *);
int luaarchive_pushentrytable(lua_State *, archive_entry_p);
int luaarchive_new (lua_State *, char *, char *);
int luaarchive_open (lua_State *, char *);
int luaarchive_close (lua_State *, char *);
int luaarchive_read (lua_State *, char *);
int luaarchive_write (lua_State *, char *);
int luaarchive_type (lua_State *, char *);
int luaarchive_extract (lua_State *, char *);
int luaarchive_entry (lua_State *, char *);
int luaarchive_mode (lua_State *, char *);
#endif
