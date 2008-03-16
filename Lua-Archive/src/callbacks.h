/*
 * =====================================================================================
 *
 *       Filename:  callbacks.h
 *
 *    Description:  
 *
 *        Version:  1.0
 *        Created:  22/11/07 01:25:23 CET
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  Aitor Pérez Iturri (api), aitor.iturri@gmail.com
 *        Company:  ia Systems
 *
 * =====================================================================================
 */

struct clientdata {
	char * name;
	int fd;
};

int callback_open (archive_p, void *);
int callback_close (archive_p, void *);
ssize_t callback_read (archive_p, void *, void **);
ssize_t callback_write (archive_p, void *, void *, size_t);
int callback_skip (archive_p, void *, size_t);

