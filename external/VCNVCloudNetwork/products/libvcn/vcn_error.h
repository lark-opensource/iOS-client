//
//  vcn_error.h
//  network-1
//
//  Created by thq on 17/2/17.
//  Copyright © 2017年 thq. All rights reserved.
//

#ifndef vcn_error_h
#define vcn_error_h


#include <errno.h>
#include <stddef.h>

/**
 * @addtogroup lavu_error
 *
 * @{
 */


/* error handling */
#if EDOM > 0
#define AVERROR(e) (-(e))   ///< Returns a negative error code from a POSIX error code, to return from library functions.
#define AVUNERROR(e) (-(e)) ///< Returns a POSIX error code from a library function error return value.
#else
/* Some platforms have E* and errno already negated. */
#define AVERROR(e) (e)
#define AVUNERROR(e) (e)
#endif

#define FFERRTAG(a, b, c, d) (-(int)MKTAG(a, b, c, d))

#define AVERROR_BSF_NOT_FOUND      FFERRTAG(0xF8,'B','S','F') ///< Bitstream filter not found
#define AVERROR_BUG                FFERRTAG( 'B','U','G','!') ///< Internal bug, also see AVERROR_BUG2
#define AVERROR_BUFFER_TOO_SMALL   FFERRTAG( 'B','U','F','S') ///< Buffer too small
#define AVERROR_DECODER_NOT_FOUND  FFERRTAG(0xF8,'D','E','C') ///< Decoder not found
#define AVERROR_DEMUXER_NOT_FOUND  FFERRTAG(0xF8,'D','E','M') ///< Demuxer not found
#define AVERROR_ENCODER_NOT_FOUND  FFERRTAG(0xF8,'E','N','C') ///< Encoder not found
#define AVERROR_EOF                FFERRTAG( 'E','O','F',' ') ///< End of file
#define AVERROR_EXIT               FFERRTAG( 'E','X','I','T') ///< Immediate exit was requested; the called function should not be restarted
#define AVERROR_EXTERNAL           FFERRTAG( 'E','X','T',' ') ///< Generic error in an external library
#define AVERROR_FILTER_NOT_FOUND   FFERRTAG(0xF8,'F','I','L') ///< Filter not found
#define AVERROR_INVALIDDATA        FFERRTAG( 'I','N','D','A') ///< Invalid data found when processing input
#define AVERROR_MUXER_NOT_FOUND    FFERRTAG(0xF8,'M','U','X') ///< Muxer not found
#define AVERROR_OPTION_NOT_FOUND   FFERRTAG(0xF8,'O','P','T') ///< Option not found
#define AVERROR_PATCHWELCOME       FFERRTAG( 'P','A','W','E') ///< Not yet implemented in FFmpeg, patches welcome
#define AVERROR_PROTOCOL_NOT_FOUND FFERRTAG(0xF8,'P','R','O') ///< Protocol not found

#define AVERROR_STREAM_NOT_FOUND   FFERRTAG(0xF8,'S','T','R') ///< Stream not found
/**
 * This is semantically identical to AVERROR_BUG
 * it has been introduced in Libav after our AVERROR_BUG and with a modified value.
 */
#define AVERROR_BUG2               FFERRTAG( 'B','U','G',' ')
#define AVERROR_UNKNOWN            FFERRTAG( 'U','N','K','N') ///< Unknown error, typically from an external library
#define AVERROR_EXPERIMENTAL       (-0x2bb2afa8) ///< Requested feature is flagged experimental. Set strict_std_compliance if you really want to use it.
#define AVERROR_INPUT_CHANGED      (-0x636e6701) ///< Input changed between calls. Reconfiguration is required. (can be OR-ed with AVERROR_OUTPUT_CHANGED)
#define AVERROR_OUTPUT_CHANGED     (-0x636e6702) ///< Output changed between calls. Reconfiguration is required. (can be OR-ed with AVERROR_INPUT_CHANGED)
/* HTTP & RTSP errors */
#define AVERROR_HTTP_REDIRECT      FFERRTAG(0xF8,'3','x','x')
#define AVERROR_HTTP_BAD_REQUEST   FFERRTAG(0xF8,'4','0','0')
#define AVERROR_HTTP_UNAUTHORIZED  FFERRTAG(0xF8,'4','0','1')
#define AVERROR_HTTP_FORBIDDEN     FFERRTAG(0xF8,'4','0','3')
#define AVERROR_HTTP_NOT_FOUND     FFERRTAG(0xF8,'4','0','4')
#define AVERROR_HTTP_TIMEOUT       FFERRTAG(0xF8,'4','0','8')
#define AVERROR_HTTP_OTHER_4XX     FFERRTAG(0xF8,'4','X','X')
#define AVERROR_HTTP_SERVER_ERROR  FFERRTAG(0xF8,'5','X','X')

#define AVERROR_EV_RETRY_IMMEDIATELY FFERRTAG('E','R','I','Y')
#define AVERROR_EV_CHANGE_FOR_BACKOFF FFERRTAG('E','C','F','F')
#define AVERROR_EV_CHANGE_FOR_RTO FFERRTAG('E','C','F','R')
#define AVERROR_EV_CHANGE_FOR_ER FFERRTAG('E','C','F','E')
#define AVERROR_EV_CHANGE_FOR_AR FFERRTAG('E','C','F','A')
#define AVERROR_EV_CHANGE_FOR_TR FFERRTAG('E','C','F','T')
#define AVERROR_RESPONE_TIMEOUT  FFERRTAG('R','T','M','O')

#define AVERROR_EARLY_DATA_REJECTED             FFERRTAG( 'E','D','R','J')
#define AVERROR_RESET_EARLY_DATA            FFERRTAG( 'R','S','E','R')

#define AVERROR_HTTP_USERINTERRUPT  FFERRTAG(0xF8,'R','U','P')

#define AVERROR_SOCKET_SEND_TIMEOUT AVERROR(ETIMEDOUT)*50000
#define AVERROR_SOCKET_SEND_AGAIN AVERROR(EAGAIN)*50000

enum AVErrorCodeExt {
    AVERROR_HTTP_ACCPETED = 200,
    AVERROR_TCP_MISSING_IN_URI = -60000,
    AVERROR_PROT_MISSING_IN_URI,
    AVERROR_FAILED_TO_RESOLVE_HOSTNAME,
    AVERROR_FAILED_TO_RESOLVE_HOSTNAME_TIMEOUT,
    AVERROR_FF_SOCKET_FAILED,
    AVERROR_FF_LISTEN_FAILED,
    AVERROR_FF_LISTEN_BIND_FAILED,
    AVERROR_FF_LISTEN_CONNECTION_EXIT,
    AVERROR_FF_LISTEN_CONNECTION_FAILED,
    
    AVERROR_FF_ACCPET_FAILED,
    AVERROR_FF_SOCKET_CONNECT_FAILED,
    AVERROR_READ_NETWORK_WAIT_TIMEOUT,
    AVERROR_WRITE_NETWORK_WAIT_TIMEOUT,
    AVERROR_RECEIV_DATA_FAILED,
    AVERROR_SEND_DATA_FAILED,
    AVERROR_CONTEXT_TYPE_IS_INVALID,
    AVERROR_HTTP_DEFAULT_ERROR,
    AVERROR_HTTP_REDIRECT_COUNT_OUT,
    AVERROR_PROTO_IS_NOT_TCP,
    AVERROR_INVALID_PORT,
    AVERROR_GET_ADDR_INFO_FAILED,
    AVERROR_GET_ADDR_INFO_START_FAILED,
};

#define AV_ERROR_MAX_STRING_SIZE 64

/**
 * Put a description of the AVERROR code errnum in errbuf.
 * In case of failure the global variable errno is set to indicate the
 * error. Even in case of failure vcn_av_strerror() will print a generic
 * error message indicating the errnum provided to errbuf.
 *
 * @param errnum      error code to describe
 * @param errbuf      buffer to which description is written
 * @param errbuf_size the size in bytes of errbuf
 * @return 0 on success, a negative value if a description for errnum
 * cannot be found
 */
__attribute__((visibility ("default"))) int vcn_av_strerror(int errnum, char *errbuf, size_t errbuf_size);

/**
 * Fill the provided buffer with a string containing an error string
 * corresponding to the AVERROR code errnum.
 *
 * @param errbuf         a buffer
 * @param errbuf_size    size in bytes of errbuf
 * @param errnum         error code to describe
 * @return the buffer in input, filled with the error description
 * @see vcn_av_strerror()
 */
static inline char *av_make_error_string(char *errbuf, size_t errbuf_size, int errnum)
{
    vcn_av_strerror(errnum, errbuf, errbuf_size);
    return errbuf;
}

/**
 * Convenience macro, the return value should be used only directly in
 * function arguments but never stand-alone.
 */
#define av_err2str(errnum) \
av_make_error_string((char[AV_ERROR_MAX_STRING_SIZE]){0}, AV_ERROR_MAX_STRING_SIZE, errnum)

/**
 * @}
 */



#endif /* vcn_error_h */
