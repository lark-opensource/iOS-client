/*-
 * Copyright (c) 2009-2011 Michihiro NAKAJIMA
 * Copyright (c) 2003-2008 Tim Kientzle and Miklos Vajna
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR(S) ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR(S) BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "archive_platform.h"

__FBSDID("$FreeBSD$");

#ifdef HAVE_ERRNO_H
#include <errno.h>
#endif
#include <stdio.h>
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif
#ifdef HAVE_STRING_H
#include <string.h>
#endif
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#if HAVE_LZMA_H
#include <lzma.h>
#endif

#include "archive.h"
#include "archive_endian.h"
#include "archive_private.h"
#include "archive_read_private.h"

#if HAVE_LZMA_H && HAVE_LIBLZMA

struct private_data {
	lzma_stream	 stream;
	unsigned char	*out_block;
	size_t		 out_block_size;
	int64_t		 total_out;
	char		 eof; /* True = found end of compressed data. */
	char		 in_stream;

	/* Following variables are used for lzip only. */
	char		 lzip_ver;
	uint32_t	 crc32;
	int64_t		 member_in;
	int64_t		 member_out;
};

#if LZMA_VERSION_MAJOR >= 5
/* Effectively disable the limiter. */
#define LZMA_MEMLIMIT	UINT64_MAX
#else
/* NOTE: This needs to check memory size which running system has. */
#define LZMA_MEMLIMIT	(1U << 30)
#endif

/* Combined lzip/lzma/xz filter */
static ssize_t	xz_filter_read(struct archive_read_filter *, const void **);
static int	xz_filter_close(struct archive_read_filter *);
static int	xz_lzma_bidder_init(struct archive_read_filter *);

#endif

/*
 * Note that we can detect xz and lzma compressed files even if we
 * can't decompress them.  (In fact, we like detecting them because we
 * can give better error messages.)  So the bid framework here gets
 * compiled even if no lzma library is available.
 */
static int	xz_bidder_bid(struct archive_read_filter_bidder *,
		    struct archive_read_filter *);
static int	xz_bidder_init(struct archive_read_filter *);
static int	lzma_bidder_bid(struct archive_read_filter_bidder *,
		    struct archive_read_filter *);
static int	lzma_bidder_init(struct archive_read_filter *);
static int	lzip_has_member(struct archive_read_filter *);
static int	lzip_bidder_bid(struct archive_read_filter_bidder *,
		    struct archive_read_filter *);
static int	lzip_bidder_init(struct archive_read_filter *);

#if ARCHIVE_VERSION_NUMBER < 4000000
/* Deprecated; remove in libarchive 4.0 */
int
archive_read_support_compression_xz(struct archive *a)
{
	return archive_read_support_filter_xz(a);
}
#endif

int
archive_read_support_filter_xz(struct archive *_a)
{
	struct archive_read *a = (struct archive_read *)_a;
	struct archive_read_filter_bidder *bidder;

	archive_check_magic(_a, ARCHIVE_READ_MAGIC,
	    ARCHIVE_STATE_NEW, "archive_read_support_filter_xz");

	if (__archive_read_get_bidder(a, &bidder) != ARCHIVE_OK)
		return (ARCHIVE_FATAL);

	bidder->data = NULL;
	bidder->name = "xz";
	bidder->bid = xz_bidder_bid;
	bidder->init = xz_bidder_init;
	bidder->options = NULL;
	bidder->free = NULL;
#if HAVE_LZMA_H && HAVE_LIBLZMA
	return (ARCHIVE_OK);
#else
	archive_set_error(_a, ARCHIVE_ERRNO_MISC,
	    "Using external xz program for xz decompression");
	return (ARCHIVE_WARN);
#endif
}

#if ARCHIVE_VERSION_NUMBER < 4000000
int
archive_read_support_compression_lzma(struct archive *a)
{
	return archive_read_support_filter_lzma(a);
}
#endif

int
archive_read_support_filter_lzma(struct archive *_a)
{
	struct archive_read *a = (struct archive_read *)_a;
	struct archive_read_filter_bidder *bidder;

	archive_check_magic(_a, ARCHIVE_READ_MAGIC,
	    ARCHIVE_STATE_NEW, "archive_read_support_filter_lzma");

	if (__archive_read_get_bidder(a, &bidder) != ARCHIVE_OK)
		return (ARCHIVE_FATAL);

	bidder->data = NULL;
	bidder->name = "lzma";
	bidder->bid = lzma_bidder_bid;
	bidder->init = lzma_bidder_init;
	bidder->options = NULL;
	bidder->free = NULL;
#if HAVE_LZMA_H && HAVE_LIBLZMA
	return (ARCHIVE_OK);
#else
	archive_set_error(_a, ARCHIVE_ERRNO_MISC,
	    "Using external lzma program for lzma decompression");
	return (ARCHIVE_WARN);
#endif
}


#if ARCHIVE_VERSION_NUMBER < 4000000
int
archive_read_support_compression_lzip(struct archive *a)
{
	return archive_read_support_filter_lzip(a);
}
#endif

int
archive_read_support_filter_lzip(struct archive *_a)
{
	struct archive_read *a = (struct archive_read *)_a;
	struct archive_read_filter_bidder *bidder;

	archive_check_magic(_a, ARCHIVE_READ_MAGIC,
	    ARCHIVE_STATE_NEW, "archive_read_support_filter_lzip");

	if (__archive_read_get_bidder(a, &bidder) != ARCHIVE_OK)
		return (ARCHIVE_FATAL);

	bidder->data = NULL;
	bidder->name = "lzip";
	bidder->bid = lzip_bidder_bid;
	bidder->init = lzip_bidder_init;
	bidder->options = NULL;
	bidder->free = NULL;
#if HAVE_LZMA_H && HAVE_LIBLZMA
	return (ARCHIVE_OK);
#else
	archive_set_error(_a, ARCHIVE_ERRNO_MISC,
	    "Using external lzip program for lzip decompression");
	return (ARCHIVE_WARN);
#endif
}

/*
 * Test whether we can handle this data.
 */
static int
xz_bidder_bid(struct archive_read_filter_bidder *self,
    struct archive_read_filter *filter)
{
	const unsigned char *buffer;
	ssize_t avail;

	(void)self; /* UNUSED */

	buffer = __archive_read_filter_ahead(filter, 6, &avail);
	if (buffer == NULL)
		return (0);

	/*
	 * Verify Header Magic Bytes : FD 37 7A 58 5A 00
	 */
	if (memcmp(buffer, "\xFD\x37\x7A\x58\x5A\x00", 6) != 0)
		return (0);

	return (48);
}

/*
 * Test whether we can handle this data.
 *
 * <sigh> LZMA has a rather poor file signature.  Zeros do not
 * make good signature bytes as a rule, and the only non-zero byte
 * here is an ASCII character.  For example, an uncompressed tar
 * archive whose first file is ']' would satisfy this check.  It may
 * be necessary to exclude LZMA from compression_all() because of
 * this.  Clients of libarchive would then have to explicitly enable
 * LZMA checking instead of (or in addition to) compression_all() when
 * they have other evidence (file name, command-line option) to go on.
 */
static int
lzma_bidder_bid(struct archive_read_filter_bidder *self,
    struct archive_read_filter *filter)
{
	const unsigned char *buffer;
	ssize_t avail;
	uint32_t dicsize;
	uint64_t uncompressed_size;
	int bits_checked;

	(void)self; /* UNUSED */

	buffer = __archive_read_filter_ahead(filter, 14, &avail);
	if (buffer == NULL)
		return (0);

	/* First byte of raw LZMA stream is commonly 0x5d.
	 * The first byte is a special number, which consists of
	 * three parameters of LZMA compression, a number of literal
	 * context bits(which is from 0 to 8, default is 3), a number
	 * of literal pos bits(which is from 0 to 4, default is 0),
	 * a number of pos bits(which is from 0 to 4, default is 2).
	 * The first byte is made by
	 * (pos bits * 5 + literal pos bit) * 9 + * literal contest bit,
	 * and so the default value in this field is
	 * (2 * 5 + 0) * 9 + 3 = 0x5d.
	 * lzma of LZMA SDK has options to change those parameters.
	 * It means a range of this field is from 0 to 224. And lzma of
	 * XZ Utils with option -e records 0x5e in this field. */
	/* NOTE: If this checking of the first byte increases false
	 * recognition, we should allow only 0x5d and 0x5e for the first
	 * byte of LZMA stream. */
	bits_checked = 0;
	if (buffer[0] > (4 * 5 + 4) * 9 + 8)
		return (0);
	/* Most likely value in the first byte of LZMA stream. */
	if (buffer[0] == 0x5d || buffer[0] == 0x5e)
		bits_checked += 8;

	/* Sixth through fourteenth bytes are uncompressed size,
	 * stored in little-endian order. `-1' means uncompressed
	 * size is unknown and lzma of XZ Utils always records `-1'
	 * in this field. */
	uncompressed_size = archive_le64dec(buffer+5);
	if (uncompressed_size == (uint64_t)ARCHIVE_LITERAL_LL(-1))
		bits_checked += 64;

	/* Second through fifth bytes are dictionary size, stored in
	 * little-endian order. The minimum dictionary size is
	 * 1 << 12(4KiB) which the lzma of LZMA SDK uses with option
	 * -d12 and the maximum dictionary size is 1 << 27(128MiB)
	 * which the one uses with option -d27.
	 * NOTE: A comment of LZMA SDK source code says this dictionary
	 * range is from 1 << 12 to 1 << 30. */
	dicsize = archive_le32dec(buffer+1);
	switch (dicsize) {
	case 0x00001000:/* lzma of LZMA SDK option -d12. */
	case 0x00002000:/* lzma of LZMA SDK option -d13. */
	case 0x00004000:/* lzma of LZMA SDK option -d14. */
	case 0x00008000:/* lzma of LZMA SDK option -d15. */
	case 0x00010000:/* lzma of XZ Utils option -0 and -1.
			 * lzma of LZMA SDK option -d16. */
	case 0x00020000:/* lzma of LZMA SDK option -d17. */
	case 0x00040000:/* lzma of LZMA SDK option -d18. */
	case 0x00080000:/* lzma of XZ Utils option -2.
			 * lzma of LZMA SDK option -d19. */
	case 0x00100000:/* lzma of XZ Utils option -3.
			 * lzma of LZMA SDK option -d20. */
	case 0x00200000:/* lzma of XZ Utils option -4.
			 * lzma of LZMA SDK option -d21. */
	case 0x00400000:/* lzma of XZ Utils option -5.
			 * lzma of LZMA SDK option -d22. */
	case 0x00800000:/* lzma of XZ Utils option -6.
			 * lzma of LZMA SDK option -d23. */
	case 0x01000000:/* lzma of XZ Utils option -7.
			 * lzma of LZMA SDK option -d24. */
	case 0x02000000:/* lzma of XZ Utils option -8.
			 * lzma of LZMA SDK option -d25. */
	case 0x04000000:/* lzma of XZ Utils option -9.
			 * lzma of LZMA SDK option -d26. */
	case 0x08000000:/* lzma of LZMA SDK option -d27. */
		bits_checked += 32;
		break;
	default:
		/* If a memory usage for encoding was not enough on
		 * the platform where LZMA stream was made, lzma of
		 * XZ Utils automatically decreased the dictionary
		 * size to enough memory for encoding by 1Mi bytes
		 * (1 << 20).*/
		if (dicsize <= 0x03F00000 && dicsize >= 0x00300000 &&
		    (dicsize & ((1 << 20)-1)) == 0 &&
		    bits_checked == 8 + 64) {
			bits_checked += 32;
			break;
		}
		/* Otherwise dictionary size is unlikely. But it is
		 * possible that someone makes lzma stream with
		 * liblzma/LZMA SDK in one's dictionary size. */
		return (0);
	}

	/* TODO: The above test is still very weak.  It would be
	 * good to do better. */

	return (bits_checked);
}

static int
lzip_has_member(struct archive_read_filter *filter)
{
	const unsigned char *buffer;
	ssize_t avail;
	int bits_checked;
	int log2dic;

	buffer = __archive_read_filter_ahead(filter, 6, &avail);
	if (buffer == NULL)
		return (0);

	/*
	 * Verify Header Magic Bytes : 4C 5A 49 50 (`LZIP')
	 */
	bits_checked = 0;
	if (memcmp(buffer, "LZIP", 4) != 0)
		return (0);
	bits_checked += 32;

	/* A version number must be 0 or 1 */
	if (buffer[4] != 0 && buffer[4] != 1)
		return (0);
	bits_checked += 8;

	/* Dictionary size. */
	log2dic = buffer[5] & 0x1f;
	if (log2dic < 12 || log2dic > 27)
		return (0);
	bits_checked += 8;

	return (bits_checked);
}

static int
lzip_bidder_bid(struct archive_read_filter_bidder *self,
    struct archive_read_filter *filter)
{

	(void)self; /* UNUSED */
	return (lzip_has_member(filter));
}

#if HAVE_LZMA_H && HAVE_LIBLZMA

/*
 * liblzma 4.999.7 and later support both lzma and xz streams.
 */


#else

/*
 *
 * If we have no suitable library on this system, we can't actually do
 * the decompression.  We can, however, still detect compressed
 * archives and emit a useful message.
 *
 */
static int
lzma_bidder_init(struct archive_read_filter *self)
{
	int r;

	r = __archive_read_program(self, "lzma -d -qq");
	/* Note: We set the format here even if __archive_read_program()
	 * above fails.  We do, after all, know what the format is
	 * even if we weren't able to read it. */
	self->code = ARCHIVE_FILTER_LZMA;
	self->name = "lzma";
	return (r);
}

static int
xz_bidder_init(struct archive_read_filter *self)
{
	int r;

	r = __archive_read_program(self, "xz -d -qq");
	/* Note: We set the format here even if __archive_read_program()
	 * above fails.  We do, after all, know what the format is
	 * even if we weren't able to read it. */
	self->code = ARCHIVE_FILTER_XZ;
	self->name = "xz";
	return (r);
}

static int
lzip_bidder_init(struct archive_read_filter *self)
{
	int r;

	r = __archive_read_program(self, "lzip -d -q");
	/* Note: We set the format here even if __archive_read_program()
	 * above fails.  We do, after all, know what the format is
	 * even if we weren't able to read it. */
	self->code = ARCHIVE_FILTER_LZIP;
	self->name = "lzip";
	return (r);
}

#endif /* HAVE_LZMA_H */
