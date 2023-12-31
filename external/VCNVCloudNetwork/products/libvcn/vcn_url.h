//
//  vcn_url.h
//  network-1
//
//  Created by thq on 17/2/18.
//  Copyright © 2017年 thq. All rights reserved.
//

#ifndef vcn_url_h
#define vcn_url_h


#include "vcn_avio.h"
#include "vcn_format_version.h"

#include "vcn_dict.h"
#include "vcn_log.h"

#define URL_PROTOCOL_FLAG_NESTED_SCHEME 1 /*< The protocol name can be the first part of a nested protocol scheme */
#define URL_PROTOCOL_FLAG_NETWORK       2 /*< The protocol uses network */

extern const AVClass vcn_url_context_class;

typedef struct VCNURLContext {
    const AVClass *av_class;    /**< information for vcn_av_log(). Set by url_open(). */
    const struct URLProtocol *prot;
    void *priv_data;
    char *filename;             /**< specified URL */
    int flags;
    int max_packet_size;        /**< if non zero, the stream is packetized with this max packet size */
    int is_streamed;            /**< true if streamed (no seek possible), default = false */
    int is_connected;
    AVNetIOInterruptCB interrupt_callback;
    int64_t rw_timeout;         /**< maximum time to wait for (network) read/write operation completion, in mcs */
    const char *protocol_whitelist;
    const char *protocol_blacklist;
    int64_t log_handle;         /**log handle**/
} VCNURLContext;

typedef char* (*getTcpHostIP)(VCNURLContext* h);

typedef struct URLProtocol {
    const char *name;
    int     (*url_open)( VCNURLContext *h, const char *url, int flags);
    /**
     * This callback is to be used by protocols which open further nested
     * protocols. options are then to be passed to ffurl_open()/vcn_url_connect()
     * for those nested protocols.
     */
    int     (*url_open2)(VCNURLContext *h, const char *url, int flags, AVDictionary **options);
    int     (*url_accept)(VCNURLContext *s, VCNURLContext **c);
    int     (*url_handshake)(VCNURLContext *c);
    
    /**
     * Read data from the protocol.
     * If data is immediately available (even less than size), EOF is
     * reached or an error occurs (including EINTR), return immediately.
     * Otherwise:
     * In non-blocking mode, return AVERROR(EAGAIN) immediately.
     * In blocking mode, wait for data/EOF/error with a short timeout (0.1s),
     * and return AVERROR(EAGAIN) on timeout.
     * Checking interrupt_callback, looping on EINTR and EAGAIN and until
     * enough data has been read is left to the calling function; see
     * retry_transfer_wrapper in avio.c.
     */
    int     (*url_read)( VCNURLContext *h, unsigned char *buf, int size);
    int     (*url_write)(VCNURLContext *h, const unsigned char *buf, int size);
    int64_t (*url_seek)( VCNURLContext *h, int64_t pos, int whence);
    int     (*url_close)(VCNURLContext *h);
    int (*url_read_pause)(VCNURLContext *h, int pause);
    int64_t (*url_read_seek)(VCNURLContext *h, int stream_index,
                             int64_t timestamp, int flags);
    int (*url_get_file_handle)(VCNURLContext *h);
    int (*url_get_multi_file_handle)(VCNURLContext *h, int **handles,
                                     int *numhandles);
    int (*url_get_short_seek)(VCNURLContext *h);
    int (*url_shutdown)(VCNURLContext *h, int flags);
    int priv_data_size;
    const AVClass *priv_data_class;
    int flags;
    int (*url_check)(VCNURLContext *h, int mask);
    int (*url_open_dir)(VCNURLContext *h);
    int (*url_read_dir)(VCNURLContext *h, AVIODirEntry **next);
    int (*url_close_dir)(VCNURLContext *h);
    int (*url_delete)(VCNURLContext *h);
    int (*url_move)(VCNURLContext *h_src, VCNURLContext *h_dst);
    const char *default_whitelist;
} URLProtocol;

/**
 * Create a VCNURLContext for accessing to the resource indicated by
 * url, but do not initiate the connection yet.
 *
 * @param puc pointer to the location where, in case of success, the
 * function puts the pointer to the created VCNURLContext
 * @param flags flags which control how the resource indicated by url
 * is to be opened
 * @param int_cb interrupt callback to use for the VCNURLContext, may be
 * NULL
 * @return >= 0 in case of success, a negative value corresponding to an
 * AVERROR code in case of failure
 */
int vcn_url_alloc(VCNURLContext **puc, const char *filename, int flags,
                const AVNetIOInterruptCB *int_cb);

/**
 * Connect an VCNURLContext that has been allocated by vcn_url_alloc
 *
 * @param options  A dictionary filled with options for nested protocols,
 * i.e. it will be passed to url_open2() for protocols implementing it.
 * This parameter will be destroyed and replaced with a dict containing options
 * that were not found. May be NULL.
 */
int vcn_url_connect(VCNURLContext *uc, AVDictionary **options);

/**
 * Create an VCNURLContext for accessing to the resource indicated by
 * url, and open it.
 *
 * @param puc pointer to the location where, in case of success, the
 * function puts the pointer to the created VCNURLContext
 * @param flags flags which control how the resource indicated by url
 * is to be opened
 * @param int_cb interrupt callback to use for the VCNURLContext, may be
 * NULL
 * @param options  A dictionary filled with protocol-private options. On return
 * this parameter will be destroyed and replaced with a dict containing options
 * that were not found. May be NULL.
 * @param parent An enclosing VCNURLContext, whose generic options should
 *               be applied to this VCNURLContext as well.
 * @return >= 0 in case of success, a negative value corresponding to an
 * AVERROR code in case of failure
 */
__attribute__((visibility ("default"))) int vcn_url_open_whitelist(VCNURLContext **puc, const char *filename, int flags,
                         const AVNetIOInterruptCB *int_cb, AVDictionary **options,
                         const char *whitelist, const char* blacklist,
                         VCNURLContext *parent);

int ffurl_open(VCNURLContext **puc, const char *filename, int flags,
               const AVNetIOInterruptCB *int_cb, AVDictionary **options);

/**
 * Accept an VCNURLContext c on an VCNURLContext s
 *
 * @param  s server context
 * @param  c client context, must be unallocated.
 * @return >= 0 on success, ff_neterrno() on failure.
 */
__attribute__((visibility ("default"))) int vcn_url_accept(VCNURLContext *s, VCNURLContext **c);

/**
 * Perform one step of the protocol handshake to accept a new client.
 * See avio_handshake() for details.
 * Implementations should try to return decreasing values.
 * If the protocol uses an underlying protocol, the underlying handshake is
 * usually the first step, and the return value can be:
 * (largest value for this protocol) + (return value from other protocol)
 *
 * @param  c the client context
 * @return >= 0 on success or a negative value corresponding
 *         to an AVERROR code on failure
 */
__attribute__((visibility ("default"))) int vcn_url_handshake(VCNURLContext *c);

/**
 * Read up to size bytes from the resource accessed by h, and store
 * the read bytes in buf.
 *
 * @return The number of bytes actually read, or a negative value
 * corresponding to an AVERROR code in case of error. A value of zero
 * indicates that it is not possible to read more from the accessed
 * resource (except if the value of the size argument is also zero).
 */
__attribute__((visibility ("default"))) int vcn_url_read(VCNURLContext *h, unsigned char *buf, int size);

/**
 * Read as many bytes as possible (up to size), calling the
 * read function multiple times if necessary.
 * This makes special short-read handling in applications
 * unnecessary, if the return value is < size then it is
 * certain there was either an error or the end of file was reached.
 */
int vcn_url_read_complete(VCNURLContext *h, unsigned char *buf, int size);

/**
 * Write size bytes from buf to the resource accessed by h.
 *
 * @return the number of bytes actually written, or a negative value
 * corresponding to an AVERROR code in case of failure
 */
__attribute__((visibility ("default"))) int vcn_url_write(VCNURLContext *h, const unsigned char *buf, int size);

/**
 * Change the position that will be used by the next read/write
 * operation on the resource accessed by h.
 *
 * @param pos specifies the new position to set
 * @param whence specifies how pos should be interpreted, it must be
 * one of SEEK_SET (seek from the beginning), SEEK_CUR (seek from the
 * current position), SEEK_END (seek from the end), or AVSEEK_SIZE
 * (return the filesize of the requested resource, pos is ignored).
 * @return a negative value corresponding to an AVERROR code in case
 * of failure, or the resulting file position, measured in bytes from
 * the beginning of the file. You can use this feature together with
 * SEEK_CUR to read the current file position.
 */
__attribute__((visibility ("default"))) int64_t vcn_url_seek(VCNURLContext *h, int64_t pos, int whence);

/**
 * Close the resource accessed by the VCNURLContext h, and free the
 * memory used by it. Also set the VCNURLContext pointer to NULL.
 *
 * @return a negative value if an error condition occurred, 0
 * otherwise
 */
__attribute__((visibility ("default"))) int vcn_url_closep(VCNURLContext **h);
__attribute__((visibility ("default"))) int vcn_url_close(VCNURLContext *h);

/**
 * Return the filesize of the resource accessed by h, AVERROR(ENOSYS)
 * if the operation is not supported by h, or another negative value
 * corresponding to an AVERROR error code in case of failure.
 */
int64_t ffurl_size(VCNURLContext *h);

/**
 * Return the file descriptor associated with this URL. For RTP, this
 * will return only the RTP file descriptor, not the RTCP file descriptor.
 *
 * @return the file descriptor associated with this URL, or <0 on error.
 */
__attribute__((visibility ("default"))) int vcn_url_get_file_handle(VCNURLContext *h);

/**
 * Return the file descriptors associated with this URL.
 *
 * @return 0 on success or <0 on error.
 */
int ffurl_get_multi_file_handle(VCNURLContext *h, int **handles, int *numhandles);

/**
 * Signal the VCNURLContext that we are done reading or writing the stream.
 *
 * @param h pointer to the resource
 * @param flags flags which control how the resource indicated by url
 * is to be shutdown
 *
 * @return a negative value if an error condition occurred, 0
 * otherwise
 */
int vcn_url_shutdown(VCNURLContext *h, int flags);

/**
 * Check if the user has requested to interrupt a blocking function
 * associated with cb.
 */
int vcn_ff_check_interrupt(AVNetIOInterruptCB *cb);

/**
 * Return the current short seek threshold value for this URL.
 *
 * @return threshold (>0) on success or <=0 on error.
 */
__attribute__((visibility ("default"))) int vcn_url_get_short_seek(VCNURLContext *h);

/* udp.c */
int ff_udp_set_remote_url(VCNURLContext *h, const char *uri);
int ff_udp_get_local_port(VCNURLContext *h);
__attribute__((visibility ("default"))) int vcn_network_init(void);
/**
 * Assemble a URL string from components. This is the reverse operation
 * of av_url_split.
 *
 * Note, this requires networking to be initialized, so the caller must
 * ensure vcn_network_init has been called.
 *
 * @see av_url_split
 *
 * @param str the buffer to fill with the url
 * @param size the size of the str buffer
 * @param proto the protocol identifier, if null, the separator
 *              after the identifier is left out, too
 * @param authorization an optional authorization string, may be null.
 *                      An empty string is treated the same as a null string.
 * @param hostname the host name string
 * @param port the port number, left out from the string if negative
 * @param fmt a generic format string for everything to add after the
 *            host/port, may be null
 * @return the number of characters written to the destination buffer
 */
__attribute__((visibility ("default"))) int vcn_url_join(char *str, int size, const char *proto,
                const char *authorization, const char *hostname,
                int port, const char *fmt, ...) av_printf_format(7, 8);

/**
 * Convert a relative url into an absolute url, given a base url.
 *
 * @param buf the buffer where output absolute url is written
 * @param size the size of buf
 * @param base the base url, may be equal to buf.
 * @param rel the new url, which is interpreted relative to base
 */
__attribute__((visibility ("default"))) void vcn_ff_make_absolute_url(char *buf, int size, const char *base,
                          const char *rel);

/**
 * Allocate directory entry with default values.
 *
 * @return entry or NULL on error
 */
AVIODirEntry *ff_alloc_dir_entry(void);

const AVClass *vcn_VCNURLContext_child_class_next(const AVClass *prev);

/**
 * Construct a list of protocols matching a given whitelist and/or blacklist.
 *
 * @param whitelist a comma-separated list of allowed protocol names or NULL. If
 *                  this is a non-empty string, only protocols in this list will
 *                  be included.
 * @param blacklist a comma-separated list of forbidden protocol names or NULL.
 *                  If this is a non-empty string, all protocols in this list
 *                  will be excluded.
 *
 * @return a NULL-terminated array of matching protocols. The array must be
 * freed by the caller.
 */
const URLProtocol **vcn_url_get_protocols(const char *whitelist,
                                        const char *blacklist);
__attribute__((visibility ("default"))) const char *vcn_tcp_get_ip_addr(VCNURLContext *h);
__attribute__((visibility ("default"))) const char *vcn_tls_get_ip_addr(VCNURLContext *h);
__attribute__((visibility ("default"))) void vcn_tls_reset_interrupt_callback(VCNURLContext *h);

/*from hlsc.c*/
/*start file structure*/
typedef struct FileNode
{
    
    int64_t in_mdfile_position;
    int64_t in_vcn_file_position;
    int64_t fill_size;
    int64_t node_size;
    int64_t reserved1;
    int64_t reserved2;
    struct FileNode *next;
    struct FileNode *prev;
} FileNode;
#define FILE_NODE_SIZE (sizeof(int64_t)*6)
typedef struct VCNMFBOX{
    int32_t length;
    int32_t head;
    int32_t crc;
    int32_t num;
    uint32_t file_size[2];
    int32_t rv1;
    int32_t rv2;
}VCNMFBox;
/*end file structure*/
/*save box into file end*/
void save_filebox(int write_fd,uint64_t filesize,FileNode *nodes,char *cache_file_key);
int read_filebox(int r_handle,char* file_path,FileNode **nodes,char *cache_file_key,int is_need_truncate);
void set_vcn_custom_verify_callback(int (*callback)(void*, void*, const char*, int));
int is_has_vcn_custom_verify_callback();
#endif /* vcn_url_h */
