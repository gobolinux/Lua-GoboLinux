/*
 * =====================================================================================
 *
 *       Filename:  ltar.h
 *
 *    Description:  Lua-Tar binding header file.
 *
 *        Version:  1.0
 *        Created:  20/11/07 09:21:39 CET
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  Aitor Pérez Iturri (api), aitor.iturri@gmail.com
 *        Company:  ia Systems
 *
 * =====================================================================================
 */

#ifndef _L_TAR_H_
#define _L_TAR_H_

#define LUARCHIVE_TAR_VERSION			"1.0"

#define LUAARCHIVE_TAR_MODULE			"tar"
#define LUAARCHIVE_TAR_HANDLER			"ARCHIVE.TAR"

static int l_open (lua_State *);
static int l_close (lua_State *);
static int l_read (lua_State *);
static int l_write (lua_State *);
static int l_extract (lua_State *);
static int l_entry (lua_State *);
static int l_mode (lua_State *);
static int luaopen_tar_open (lua_State *);
//
#endif
