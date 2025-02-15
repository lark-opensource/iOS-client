/*
 * Copyright (c) 2007 The FFmpeg Project
 *
 * This file is part of FFmpeg.
 *
 * FFmpeg is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * FFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with FFmpeg; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *
 * This file may have been modified by Bytedance Inc. (“Bytedance Modifications”). 
 * All Bytedance Modifications are Copyright 2022 Bytedance Inc.
 */

#ifndef AVFORMAT_NETWORK_H
#define AVFORMAT_NETWORK_H

#include <errno.h>
#include <stdint.h>

#include "config.h"
#include "libavutil/error.h"
#include "libavutil/ttmapp.h"
#include "os_support.h"
#include "avio.h"
#include "url.h"

#if HAVE_UNISTD_H
#include <unistd.h>
#endif

#if HAVE_WINSOCK2_H
#include <winsock2.h>
#include <ws2tcpip.h>

#ifndef EPROTONOSUPPORT
#define EPROTONOSUPPORT WSAEPROTONOSUPPORT
#endif
#ifndef ETIMEDOUT
#define ETIMEDOUT       WSAETIMEDOUT
#endif
#ifndef ECONNREFUSED
#define ECONNREFUSED    WSAECONNREFUSED
#endif
#ifndef EINPROGRESS
#define EINPROGRESS     WSAEINPROGRESS
#endif

#define getsockopt(a, b, c, d, e) getsockopt(a, b, c, (char*) d, e)
#define setsockopt(a, b, c, d, e) setsockopt(a, b, c, (const char*) d, e)

int ff_neterrno(void);
#else
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

#define ff_neterrno() AVERROR(errno)
#endif /* HAVE_WINSOCK2_H */

#if HAVE_ARPA_INET_H
#include <arpa/inet.h>
#endif

#if HAVE_POLL_H
#include <poll.h>
#endif

int ff_socket_nonblock(int socket, int enable);

extern int ff_network_inited_globally;
int ff_network_init(void);
void ff_network_close(void);

int ff_tls_init(void);
void ff_tls_deinit(void);

int ff_network_wait_fd(int fd, int write);

/**
 * This works similarly to ff_network_wait_fd, but waits up to 'timeout' microseconds
 * Uses ff_network_wait_fd in a loop
 *
 * @fd Socket descriptor
 * @write Set 1 to wait for socket able to be read, 0 to be written
 * @timeout Timeout interval, in microseconds. Actual precision is 100000 mcs, due to ff_network_wait_fd usage
 * @param int_cb Interrupt callback, is checked before each ff_network_wait_fd call
 * @return 0 if data can be read/written, AVERROR(ETIMEDOUT) if timeout expired, or negative error code
 */
int ff_network_wait_fd_timeout(int fd, int write, int64_t timeout, AVIOInterruptCB *int_cb);

int ff_inet_aton (const char * str, struct in_addr * add);

#if !HAVE_STRUCT_SOCKADDR_STORAGE
struct sockaddr_storage {
#if HAVE_STRUCT_SOCKADDR_SA_LEN
    uint8_t ss_len;
    uint8_t ss_family;
#else
    uint16_t ss_family;
#endif /* HAVE_STRUCT_SOCKADDR_SA_LEN */
    char ss_pad1[6];
    int64_t ss_align;
    char ss_pad2[112];
};
#endif /* !HAVE_STRUCT_SOCKADDR_STORAGE */

typedef union sockaddr_union {
    struct sockaddr_storage storage;
    struct sockaddr_in in;
#if HAVE_STRUCT_SOCKADDR_IN6
    struct sockaddr_in6 in6;
#endif
} sockaddr_union;

#ifndef MSG_NOSIGNAL
#define MSG_NOSIGNAL 0
#endif

#if !HAVE_STRUCT_ADDRINFO
struct addrinfo {
    int ai_flags;
    int ai_family;
    int ai_socktype;
    int ai_protocol;
    int ai_addrlen;
    struct sockaddr *ai_addr;
    char *ai_canonname;
    struct addrinfo *ai_next;
};
#endif /* !HAVE_STRUCT_ADDRINFO */

/* getaddrinfo constants */
#ifndef EAI_AGAIN
#define EAI_AGAIN 2
#endif
#ifndef EAI_BADFLAGS
#define EAI_BADFLAGS 3
#endif
#ifndef EAI_FAIL
#define EAI_FAIL 4
#endif
#ifndef EAI_FAMILY
#define EAI_FAMILY 5
#endif
#ifndef EAI_MEMORY
#define EAI_MEMORY 6
#endif
#ifndef EAI_NODATA
#define EAI_NODATA 7
#endif
#ifndef EAI_NONAME
#define EAI_NONAME 8
#endif
#ifndef EAI_SERVICE
#define EAI_SERVICE 9
#endif
#ifndef EAI_SOCKTYPE
#define EAI_SOCKTYPE 10
#endif

#ifndef AI_PASSIVE
#define AI_PASSIVE 1
#endif

#ifndef AI_CANONNAME
#define AI_CANONNAME 2
#endif

#ifndef AI_NUMERICHOST
#define AI_NUMERICHOST 4
#endif

#ifndef NI_NOFQDN
#define NI_NOFQDN 1
#endif

#ifndef NI_NUMERICHOST
#define NI_NUMERICHOST 2
#endif

#ifndef NI_NAMERQD
#define NI_NAMERQD 4
#endif

#ifndef NI_NUMERICSERV
#define NI_NUMERICSERV 8
#endif

#ifndef NI_DGRAM
#define NI_DGRAM 16
#endif

#if !HAVE_GETADDRINFO
int ff_getaddrinfo(const char *node, const char *service,
                   const struct addrinfo *hints, struct addrinfo **res);
void ff_freeaddrinfo(struct addrinfo *res);
int ff_getnameinfo(const struct sockaddr *sa, int salen,
                   char *host, int hostlen,
                   char *serv, int servlen, int flags);
#define getaddrinfo ff_getaddrinfo
#define freeaddrinfo ff_freeaddrinfo
#define getnameinfo ff_getnameinfo
#endif /* !HAVE_GETADDRINFO */

#if !HAVE_GETADDRINFO || HAVE_WINSOCK2_H
const char *ff_gai_strerror(int ecode);
#undef gai_strerror
#define gai_strerror ff_gai_strerror
#endif /* !HAVE_GETADDRINFO || HAVE_WINSOCK2_H */

#ifndef INADDR_LOOPBACK
#define INADDR_LOOPBACK 0x7f000001
#endif

#ifndef INET_ADDRSTRLEN
#define INET_ADDRSTRLEN 16
#endif

#ifndef INET6_ADDRSTRLEN
#define INET6_ADDRSTRLEN INET_ADDRSTRLEN
#endif

#ifndef IN_MULTICAST
#define IN_MULTICAST(a) ((((uint32_t)(a)) & 0xf0000000) == 0xe0000000)
#endif
#ifndef IN6_IS_ADDR_MULTICAST
#define IN6_IS_ADDR_MULTICAST(a) (((uint8_t *) (a))[0] == 0xff)
#endif

typedef struct getaddrinfo_a_CTX{
    tt_dns_start     start;
    tt_dns_result    result;
    tt_dns_free      free;
    tt_save_ip          save_ip;
    tt_log_callback    log_callback;
    tt_read_callback    io_callback;
    tt_info_callback   info_callback;
}getaddrinfo_a_ctx;

int ff_support_getaddrinfo_a(void);

int ff_isupport_getaddrinfo_a(uint64_t cb_ctx);

void ff_getaddrinfo_a_init(tt_dns_start getinfo, tt_dns_result result,tt_dns_free end,
                           tt_save_ip save_ip, tt_log_callback log_callback, tt_read_callback io_callback, tt_info_callback info_callback);

void ff_register_dns_parser(tt_dns_start getinfo, tt_dns_result result, tt_dns_free end);

void* ff_igetaddrinfo_a_start(uint64_t cb_ctx, uint64_t handle,const char* hostname, int user_flag);

int ff_igetaddrinfo_a_result(uint64_t cb_ctx, void* ctx,char* ipaddress,int size);

void ff_igetaddrinfo_a_free(uint64_t cb_ctx, void* ctx);

void ff_isave_host_addr(uint64_t cb_ctx, aptr_t handle, const char* ip, int user_flag);

void ff_inetwork_log_callback(uint64_t cb_ctx, aptr_t handle, int type, int user_flag);

void ff_inetwork_io_read_callback(uint64_t cb_ctx, aptr_t handle, int type, int size);

void ff_inetwork_info_callback(uint64_t cb_ctx, aptr_t handle, int key, int64_t value, const char* strValue);

int ff_is_multicast_address(struct sockaddr *addr);

void ff_set_custom_verify_callback(int (*callback)(void*, void*, const char*, int));
int ff_do_custom_verify_callback(void* context, void* ssl, const char* host, int port);

typedef void* (*resource_loader_open)(aptr_t handle, const char *arg, int flags, void *cb);
typedef int (*resource_loader_read)(void* loader, unsigned char *buf, int size, void *cb);
typedef int64_t (*resource_loader_seek)(void* loader, int64_t pos, int whence);
typedef int (*resource_loader_close)(void* loader);

typedef struct resourceLoader_ctx {
    resource_loader_open     open;
    resource_loader_read     read;
    resource_loader_seek     seek;
    resource_loader_close    close;
}resourceLoader_ctx;

int ff_support_resourceloader(void);

void ff_resourceloader_init(resource_loader_open open, resource_loader_read read, resource_loader_seek seek, resource_loader_close close);

void* ff_resource_loader_open(aptr_t handle, const char *arg, int flags, void *cb);

int ff_resource_loader_read(void* loader, unsigned char *buf, int size, void *cb);

int64_t ff_resource_loader_seek(void* loader, int64_t pos, int whence);

int ff_resource_loader_close(void* loader);

#define POLLING_TIME 100 /// Time in milliseconds between interrupt check

/**
 * Bind to a file descriptor and poll for a connection.
 *
 * @param fd      First argument of bind().
 * @param addr    Second argument of bind().
 * @param addrlen Third argument of bind().
 * @param timeout Polling timeout in milliseconds.
 * @param h       URLContext providing interrupt check
 *                callback and logging context.
 * @return        A non-blocking file descriptor on success
 *                or an AVERROR on failure.
 */
int ff_listen_bind(int fd, const struct sockaddr *addr,
                   socklen_t addrlen, int timeout,
                   URLContext *h);

/**
 * Bind to a file descriptor to an address without accepting connections.
 * @param fd      First argument of bind().
 * @param addr    Second argument of bind().
 * @param addrlen Third argument of bind().
 * @return        0 on success or an AVERROR on failure.
 */
int ff_listen(int fd, const struct sockaddr *addr, socklen_t addrlen);

/**
 * Poll for a single connection on the passed file descriptor.
 * @param fd      The listening socket file descriptor.
 * @param timeout Polling timeout in milliseconds.
 * @param h       URLContext providing interrupt check
 *                callback and logging context.
 * @return        A non-blocking file descriptor on success
 *                or an AVERROR on failure.
 */
int ff_accept(int fd, int timeout, URLContext *h);

/**
 * Connect to a file descriptor and poll for result.
 *
 * @param fd       First argument of connect(),
 *                 will be set as non-blocking.
 * @param addr     Second argument of connect().
 * @param addrlen  Third argument of connect().
 * @param timeout  Polling timeout in milliseconds.
 * @param h        URLContext providing interrupt check
 *                 callback and logging context.
 * @param will_try_next Whether the caller will try to connect to another
 *                 address for the same host name, affecting the form of
 *                 logged errors.
 * @return         0 on success, AVERROR on failure.
 */
int ff_listen_connect(int fd, const struct sockaddr *addr,
                      socklen_t addrlen, int timeout,
                      URLContext *h, int will_try_next);

/**
 * ONLY for Android TFO
 */
int ff_sendto(int fd, const char *msg, int msg_len, int flag,
                const struct sockaddr *addr,
                socklen_t addrlen, int timeout, URLContext *h,
                int will_try_next);

int ff_listen_connect2(int fd, const struct sockaddr *addr,
                       socklen_t addrlen, int timeout,
                       URLContext *h, int will_try_next,
                       int fast_open);
int ff_http_match_no_proxy(const char *no_proxy, const char *hostname);

int ff_socket(int domain, int type, int protocol);

#endif /* AVFORMAT_NETWORK_H */
