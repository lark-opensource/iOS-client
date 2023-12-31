/*
 * Copyright 2022 Bytedance Inc.
 * SPDX license identifier: LGPL-2.1-or-later
 *
 *
 * Export private or deprecated symbols
 */

#include <stdint.h>
#include "libavformat/url.h"
#include "libavformat/avformat.h"
#include "libavutil/ttexport.h"

int tt_register_protocol(URLProtocol *prot, int protocol_size);

/**
 * Only support register one protocol
 * If call this more than once, only the last once registered.
 * @param prot pointer to URLProtocol.
 * @param protocol_size additional abi check, must be same as sizeof(URLProtocol)
 * @return int Return 0 for success, others failed.
 */
int tt_register_3rd_protocol(URLProtocol *prot, int protocol_size);


int tt_register_input_format(AVInputFormat *format, int format_size);


void tt_register_dnsparser(tt_dns_start getinfo, tt_dns_result result, tt_dns_free end);

void tt_register_io_callback(tt_save_ip       save_ip, 
                             tt_log_callback  log_callback, 
                             tt_read_callback read_callback, 
                             tt_info_callback info_callback);

/**
 * Set the time base and wrapping info for a given stream. This will be used
 * to interpret the stream's timestamps. If the new time base is invalid
 * (numerator or denominator are non-positive), it leaves the stream
 * unchanged.
 *
 * @param s stream
 * @param pts_wrap_bits number of bits effectively used by the pts
 *        (used for wrap control)
 * @param pts_num time base numerator
 * @param pts_den time base denominator
 */
void tt_set_pts_info(AVStream *s, int pts_wrap_bits,
                         unsigned int pts_num, unsigned int pts_den);


/** Flush the frame reader. */
void tt_read_frame_flush(AVFormatContext *s);

/**
 * Read size bytes from AVIOContext into buf.
 * This reads at most 1 packet. If that is not enough fewer bytes will be
 * returned.
 * @return number of bytes read or AVERROR
 */
int tt_io_read_partial(AVIOContext *s, unsigned char *buf, int size);

void tt_set_verify_callback(int (*callback)(void*, void*, const char*, int));


/**
 * Copy encoding parameters from source to destination stream
 *
 * @param dst pointer to destination AVStream
 * @param src pointer to source AVStream
 * @return >=0 on success, AVERROR code on error
 */
int tt_stream_encode_params_copy(AVStream *dst, const AVStream *src);

/**
 * Copies the whilelists from one context to the other
 */
int tt_copy_whiteblacklists(AVFormatContext *dst, const AVFormatContext *src);

/**
 * Initialize an AVIOContext for buffered I/O.
 * avio_alloc_context is a better choice.
 *
 * @param buffer Memory block for input/output operations via AVIOContext.
 *        The buffer must be allocated with av_malloc() and friends.
 *        It may be freed and replaced with a new buffer by libavformat.
 *        AVIOContext.buffer holds the buffer currently in use,
 *        which must be later freed with av_free().
 * @param buffer_size The buffer size is very important for performance.
 *        For protocols with fixed blocksize it should be set to this blocksize.
 *        For others a typical size is a cache page, e.g. 4kb.
 * @param write_flag Set to 1 if the buffer should be writable, 0 otherwise.
 * @param opaque An opaque pointer to user-specific data.
 * @param read_packet  A function for refilling the buffer, may be NULL.
 *                     For stream protocols, must never return 0 but rather
 *                     a proper AVERROR code.
 * @param write_packet A function for writing the buffer contents, may be NULL.
 *        The function may not change the input buffers content.
 * @param seek A function for seeking to specified byte position, may be NULL.
 *
 * @return 0
 */
int tt_io_init_context(AVIOContext *s,
                  unsigned char *buffer,
                  int buffer_size,
                  int write_flag,
                  void *opaque,
                  int (*read_packet)(void *opaque, uint8_t *buf, int buf_size),
                  int (*write_packet)(void *opaque, uint8_t *buf, int buf_size),
                  int64_t (*seek)(void *opaque, int64_t offset, int whence));

void tt_save_host_addr(aptr_t handle, const char* ip, int user_flag);

void tt_network_log_callback(aptr_t handle, int type, int user_flag);

void tt_network_io_read_callback(aptr_t handle, int type, int size);

void tt_network_info_callback(aptr_t handle, int key, int64_t value, const char* strValue);
