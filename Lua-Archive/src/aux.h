/*
 * =====================================================================================
 *
 *       Filename:  archive.h
 *
 *    Description:  High level functions to manage archive files.
 *
 *        Version:  1.0
 *        Created:  20/11/07 11:04:35 CET
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  Aitor Pérez Iturri (api), aitor.iturri@gmail.com
 *        Company:  ia Systems
 *
 * =====================================================================================
 */
#ifndef _AUX_H_
#define _AUX_H_

int aux_getmode (char *);
int aux_getcompression (archive_p, int);
char * aux_gettypename (int);
int aux_open (luaarchive_p, char *);
int aux_close (luaarchive_p);
int aux_finish (luaarchive_p);
int aux_support_format (luaarchive_p);
int aux_support_format_write (luaarchive_p);
int aux_support_format_read (luaarchive_p);
int aux_support_compression (luaarchive_p);
int aux_support_compression_write (luaarchive_p);
int aux_support_compression_read (luaarchive_p);
char * aux_filetype (mode_t m);
char * aux_mode (luaarchive_p);
#endif
