/*-
 * Copyright 2003-2005 Colin Percival
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted providing that the following conditions 
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import "IESGeckoBSPatch.h"

#include "bzlib.h"

#include <sys/types.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <err.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>

static int bspatch(const char* error, const char* oldfile, const char* newfile, const char* patchfile);

BOOL IESGurdBSPatch(NSString *oldFile, NSString *newFile, NSString *patchFile, NSString **errorMessage)
{
    char errorMsg[1024];
    memset(errorMsg, 0, sizeof(errorMsg));
    
    int result = bspatch(errorMsg,
                         [oldFile cStringUsingEncoding:NSUTF8StringEncoding],
                         [newFile cStringUsingEncoding:NSUTF8StringEncoding],
                         [patchFile cStringUsingEncoding:NSUTF8StringEncoding]);
    if (result == 0) {
        return YES;
    }
    *errorMessage = [NSString stringWithCString:errorMsg encoding:NSUTF8StringEncoding];
    return NO;
}

static off_t offtin(u_char *buf)
{
	off_t y;

	y=buf[7]&0x7F;
	y=y*256;y+=buf[6];
	y=y*256;y+=buf[5];
	y=y*256;y+=buf[4];
	y=y*256;y+=buf[3];
	y=y*256;y+=buf[2];
	y=y*256;y+=buf[1];
	y=y*256;y+=buf[0];

	if(buf[7]&0x80) y=-y;

	return y;
}

static int bspatch(const char* error, const char* oldfile, const char* newfile, const char* patchfile)
{
	FILE *file, *cpFile, *dpFile, *epFile;
	BZFILE *bz2_cpFile, *bz2_dpFile, *bz2_epFile;
	int cbz2err, dbz2err, ebz2err;
	int fd;
	ssize_t oldsize,newsize;
	ssize_t bzctrllen,bzdatalen;
	u_char header[32],buf[8];
	u_char *old, *new;
	off_t ctrl[3];
	off_t lenread;
	off_t i;

	/* Open patch file */
	if ((file = fopen(patchfile, "r")) == NULL) {
		sprintf((char*)error, "\"%s\" %s", patchfile, strerror(errno));
		return -1;
	}

	/*
	File format:
		0	8	"BSDIFF40"
		8	8	X
		16	8	Y
		24	8	sizeof(newfile)
		32	X	bzip2(control block)
		32+X	Y	bzip2(diff block)
		32+X+Y	???	bzip2(extra block)
	with control block a set of triples (x,y,z) meaning :
    add x bytes from oldfile to x bytes from the diff block;
    copy y bytes from the extra block;
    seek forwards in oldfile by z bytes.
	*/

	/* Read header */
	if (fread(header, 1, 32, file) < 32) {
		if (feof(file)) {
			sprintf((char*)error, "\"%s\"Corrupt patch", patchfile);
			return -1;
		}
	}

	/* Check for appropriate magic */
	if (memcmp(header, "BSDIFF40", 8) != 0) {
		sprintf((char*)error, "\"%s\"Corrupt patch", patchfile);
		return -1;
	}		

	/* Read lengths from header */
	bzctrllen = (ssize_t)offtin(header+8);
	bzdatalen = (ssize_t)offtin(header+16);
	newsize = (ssize_t)offtin(header+24);
	if ((bzctrllen < 0) || (bzdatalen < 0) || (newsize < 0)) {
		sprintf((char*)error, "\"%s\"Corrupt patch", patchfile);
		return -1;
	}		

	/* Close patch file and re-open it via libbzip2 at the right places */
	if (fclose(file)) {
		sprintf((char*)error, "\"%s\" %s", patchfile, strerror(errno));
		return -1;
	}
    
	if ((cpFile = fopen(patchfile, "r")) == NULL) {
		sprintf((char*)error, "\"%s\" %s", patchfile, strerror(errno));
		return -1;
	}	
	if (fseeko(cpFile, 32, SEEK_SET)) {
		sprintf((char*)error, "\"%s\" %s", patchfile, strerror(errno));
		return -1;
	}		
	if ((bz2_cpFile = BZ2_bzReadOpen(&cbz2err, cpFile, 0, 0, NULL, 0)) == NULL) {
		sprintf((char*)error, "BZ2_bzReadOpen, bz2err = %d", cbz2err);
		return -1;
	}
    
	if ((dpFile = fopen(patchfile, "r")) == NULL) {
		sprintf((char*)error, "\"%s\" %s", patchfile, strerror(errno));
		return -1;
	}	
	if (fseeko(dpFile, 32 + bzctrllen, SEEK_SET)) {
		sprintf((char*)error, "\"%s\" %s", patchfile, strerror(errno));
		return -1;
	}	
	if ((bz2_dpFile = BZ2_bzReadOpen(&dbz2err, dpFile, 0, 0, NULL, 0)) == NULL) {
		sprintf((char*)error, "BZ2_bzReadOpen, bz2err = %d", cbz2err);
		return -1;
	}
    
	if ((epFile = fopen(patchfile, "r")) == NULL) {
		sprintf((char*)error, "\"%s\" %s", patchfile, strerror(errno));
		return -1;
	}		
	if (fseeko(epFile, 32 + bzctrllen + bzdatalen, SEEK_SET)) {
		sprintf((char*)error, "\"%s\" %s", patchfile, strerror(errno));
		return -1;
	}	
	if ((bz2_epFile = BZ2_bzReadOpen(&ebz2err, epFile, 0, 0, NULL, 0)) == NULL) {
		sprintf((char*)error, "BZ2_bzReadOpen, bz2err = %d", ebz2err);
		return -1;
	}

	if (((fd=open(oldfile,O_RDONLY,0)) < 0) ||
		((oldsize=(ssize_t)lseek(fd,0,SEEK_END)) == -1) ||
		((old=malloc(oldsize+1)) == NULL) ||
		(lseek(fd,0,SEEK_SET) != 0) ||
		(read(fd,old,oldsize) != oldsize) ||
		(close(fd) == -1)) {
		sprintf((char*)error, "\"%s\" %s", oldfile, strerror(errno));
		return -1;
	}
	if ((new=malloc(newsize+1)) == NULL) {
		sprintf((char*)error, "%s", strerror(errno));
		return -1;
	} 

	off_t oldpos = 0, newpos = 0;
	while (newpos < newsize) {
		/* Read control data */
		for (i = 0; i <= 2; i++) {
			lenread = BZ2_bzRead(&cbz2err, bz2_cpFile, buf, 8);
			if ((lenread < 8) ||
                ((cbz2err != BZ_OK) && (cbz2err != BZ_STREAM_END))) {
				sprintf((char*)error, "\"%s\"Corrupt patch", patchfile);
				return -1;
			}			
			ctrl[i] = offtin(buf);
		};

		/* Sanity-check */
		if (newpos+ctrl[0] > newsize) {
			sprintf((char*)error, "\"%s\"Corrupt patch", patchfile);
			return -1;
		}			

		/* Read diff string */
		lenread = BZ2_bzRead(&dbz2err, bz2_dpFile, new + newpos, (int)(ctrl[0]));
		if ((lenread < ctrl[0]) ||
		    ((dbz2err != BZ_OK) && (dbz2err != BZ_STREAM_END))) {
			sprintf((char*)error, "\"%s\"Corrupt patch", patchfile);
			return -1;
		}			

		/* Add old data to diff string */
        for (i = 0; i < ctrl[0]; i++) {
            if ((oldpos + i >= 0) && (oldpos + i < oldsize)) {
				new[newpos+i] += old[oldpos+i];
            }
        }
		/* Adjust pointers */
		newpos += ctrl[0];
		oldpos += ctrl[0];

		/* Sanity-check */
		if (newpos + ctrl[1] > newsize) {
			sprintf((char*)error, "\"%s\"Corrupt patch", patchfile);
			return -1;
		}		

		/* Read extra string */
		lenread = BZ2_bzRead(&ebz2err, bz2_epFile, new + newpos, (int)(ctrl[1]));
		if ((lenread < ctrl[1]) ||
		    ((ebz2err != BZ_OK) && (ebz2err != BZ_STREAM_END))) {
			sprintf((char*)error, "\"%s\"Corrupt patch", patchfile);
			return -1;
		}		

		/* Adjust pointers */
		newpos += ctrl[1];
		oldpos += ctrl[2];
	};

	/* Clean up the bzip2 reads */
	BZ2_bzReadClose(&cbz2err, bz2_cpFile);
	BZ2_bzReadClose(&dbz2err, bz2_dpFile);
	BZ2_bzReadClose(&ebz2err, bz2_epFile);
	if (fclose(cpFile) || fclose(dpFile) || fclose(epFile)) {
		sprintf((char*)error, "\"%s\" %s", patchfile, strerror(errno));
		return -1;
	}

    /* Write the new file */
    if(((fd=open(newfile,O_CREAT|O_TRUNC|O_WRONLY,0666)) < 0) ||
       (write(fd,new,newsize) != newsize) ||
       (close(fd) == -1)) {
        sprintf((char*)error, "\"%s\" %s", newfile, strerror(errno));
        return -1;
    }

	free(new);
	free(old);

	return 0;
}
