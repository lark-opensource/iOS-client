// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_BASE_LOAD_TIMING_INFO_H_
#define NET_BASE_LOAD_TIMING_INFO_H_

#include <stdint.h>

#include "base/time/time.h"
#include "base/ttnet_implement_buildflags.h"
#include "net/base/net_export.h"

#if BUILDFLAG(TTNET_IMPLEMENT)
#include <map>
#include "net/base/address_list.h"
#include "net/net_buildflags.h"
#include "net/third_party/quiche/src/quic/core/quic_error_codes.h"
#include "net/third_party/quiche/src/quic/core/quic_types.h"
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_PROXY_SUPPORT)
#include "net/tt_net/proxy/tt_proxy_info.h"
#endif
#endif

namespace net {

// Structure containing timing information for a request.
// It addresses the needs of
// http://groups.google.com/group/http-archive-specification/web/har-1-1-spec,
// http://dev.w3.org/2006/webapi/WebTiming/, and
// http://www.w3.org/TR/resource-timing/.
//
// All events that do not apply to a request have null times.  For non-HTTP
// requests, all times other than the request_start times are null.
//
// Requests with connection errors generally only have request start times as
// well, since they never received an established socket.
//
// The general order for events is:
// request_start
// service_worker_start_time
// proxy_start
// proxy_end
// dns_start
// dns_end
// connect_start
// ssl_start
// ssl_end
// connect_end
// send_start
// send_end
// service_worker_ready_time
// service_worker_fetch_start
// service_worker_respond_with_settled
// first_early_hints_time
// receive_headers_start
// receive_headers_end
//
// Times represent when a request starts/stops blocking on an event(*), not the
// time the events actually occurred. In particular, in the case of preconnects
// and socket reuse, no time may be spent blocking on establishing a connection.
// In the case of SPDY, PAC scripts are only run once for each shared session,
// so no time may be spent blocking on them.
//
// (*) Note 1: push_start and push_end are the exception to this, as they
// represent the operation which is asynchronous to normal request flow and
// hence are provided as absolute values and not converted to "blocking" time.
//
// (*) Note 2: Internally to the network stack, times are those of actual event
// occurrence. URLRequest converts them to time which the network stack was
// blocked on each state, as per resource timing specs.
//
// DNS and SSL times are both times for the host, not the proxy, so DNS times
// when using proxies are null, and only requests to HTTPS hosts (Not proxies)
// have SSL times.
struct NET_EXPORT LoadTimingInfo {
#if BUILDFLAG(TTNET_IMPLEMENT)
  // Contains DNS resolve information.
  struct NET_EXPORT_PRIVATE DnsInfo {
    DnsInfo();
    DnsInfo(const DnsInfo& dns_info);
    ~DnsInfo();

    AddressList address_list;
    std::string task_info_json;
    int dns_hijacked_error{0};
    int skip_prefer_ip_error{0};
    int cache_stale_reason{-1};
    bool race_dns_stale_cache{false};
  };

  struct NET_EXPORT_PRIVATE CompressInfo {
    CompressInfo();
    CompressInfo(const CompressInfo& compress_info);
    ~CompressInfo();

    int compress_state{-1};
    int64_t duration{0};
    std::string type;
    size_t before_size{0};
    size_t after_size{0};
  };

  // QUIC race result.
  enum RaceResult {
    QUIC_RACE_INIT = 0,
    QUIC_WON_RACE_NEW_SESSION = 1,
    QUIC_WON_RACE_REUSE_SESSION = 2,
    QUIC_LOST_RACE_CONNECTING = 3,
    QUIC_LOST_RACE_CONNECT_FAILED = 4,
    QUIC_LOST_RACE_BUT_CONNECTED = 5,
    QUIC_LOST_RACE_CREATE_STREAM_FAILED = 6,
    QUIC_LOST_RACE_MARKED_BROKEN = 7,
    QUIC_TCP_BOTH_FAILED = 8,
    QUIC_WON_RACE_TCP_FAILED = 9,
    QUIC_LOST_RACE_MARK_BROKEN_DEFAULT_NETWORK = 10,
    QUIC_LOST_RACE_MARK_BROKEN_ALL_NETWORK = 11,
    QUIC_DISABLED_BAN_ALT_SVC_RETRY = 12,
    QUIC_DISABLED_BAN_ALT_SVC_421 = 13,
    QUIC_DISABLED_MARK_BROKEN_IN_HTTP = 14,
  };

  enum DelayTcp {
    NO_DELAY_REUSE_SESSION = 0,
    NO_DELAY_WITH_CONFIRM = 1,
    DELAY_1_5_RTT = 2,
    DELAY_SET_RTT = 3,
  };

  // Contains HTTP/2 statistics.
  struct Http2Info {
    Http2Info();
    Http2Info(const Http2Info& http2_info);
    ~Http2Info();

    // HTTP/2 granular error info. See |SpdyProtocolErrorDetails| for details.
    // Init it with |SpdyProtocolErrorDetails::TTNET_ERROR_UNSPECIFIED|.
    int spdy_protocol_error{-1};
    // HTTP/2 error code from RFC 7540 Section 7, 32-bit fields that are used in
    // RST_STREAM and GOAWAY frames to convey the reasons for the stream or
    // connection error. See |SpdyErrorCode| for details.
    int rfc_7540_error{-1};
  };

  // Contains QUIC statistics.
  struct NET_EXPORT_PRIVATE QuicInfo {
    QuicInfo();
    QuicInfo(const QuicInfo& quic_info);
    ~QuicInfo();
    enum QuicConnectStatus {
      QUIC_DISABLED = 0,
      QUIC_ENABLED = 1,
      QUIC_CONNECTED = 2,
    };
    enum ZeroRttHit {
      ZERO_RTT_NONE = 0,
      ZERO_RTT_HIT = 1,
      ZERO_RTT_NOT_HIT = 2,
      ZERO_RTT_NOT_HIT_REJCHLO = 3,
    };

    quic::QuicStreamId stream_id;
    std::string server_connection_id;
    std::string client_connection_id;

    int64_t smoothed_rtt;
    ZeroRttHit zero_rtt_hit;
    int64_t ack_delay_time;
    int64_t send_ack_delay_time;
    int64_t packet_process_time;
    int64_t max_packet_process_time;
    int64_t yield_cpu_time;
    int64_t max_yield_cpu_time;
    int64_t packet_backlog_time;
    int64_t max_packet_backlog_time;
    int64_t pacing_delay_time;
    int64_t pacing_block;
    int64_t cwnd0_block;
    int64_t loss_handshake;
    double reordered_rate;
    double loss_rate;
    double loss_rate_rto;
    double loss_rate_tlp;
    double loss_rate_nack_timeout;
    double loss_rate_nack_ack;
    double loss_rate_lazy_fack_timeout;
    double loss_rate_lazy_fack_ack;
    double loss_rate_tpv_fack_timeout;
    double loss_rate_tpv_fack_ack;
    double loss_rate_1rtt_nack_timeout;
    double loss_rate_1rtt_nack_ack;
    int64_t retrans_handshake;
    double retrans_loss;
    double retrans_tlp;
    double retrans_rto;
    double rto_srtt_ratio;
    int64_t delay_tcp_time;
    DelayTcp delay_tcp_type;
    RaceResult quic_attempt;
    bool is_handshake_negotiated;
    uint64_t latest_ping;
    uint64_t latest_ping_ack;
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_THROTTLE_MONITOR)
    size_t throttle;
#endif
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_QUIC_RECVMMSG)
    uint64_t num_socket_read_called;
    uint64_t socket_read_time;
    bool enable_recvmmsg;
#endif
#if BUILDFLAG(TTNET_IMPLEMENT_ENABLE_FEC_SUPPORT)
    quic::QuicPacketCount packets_revived;
    quic::QuicPacketNumber last_revived_packet_number;
    int64_t fec_encoder_duration_ms;
    int64_t fec_decoder_duration_ms;
#endif
    int64_t probe_rtt_duration_ms;

    QuicConnectStatus quic_connect;
    quic::QuicErrorCode connection_error;
    bool is_first_stream;
  };
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_STREAM_ZSTD)
  struct SourceStreamInfo {
    SourceStreamInfo();
    SourceStreamInfo(const SourceStreamInfo& other);
    ~SourceStreamInfo();

    std::string type;
    int error_code{0};
    std::string error_msg;
    int64_t duration{0};
    std::string request_ttzip_version;
    std::string response_ttzip_version;
    size_t raw_bytes{0};
    size_t compress_bytes{0};
    int concurrent_job_count{0};
  };
#endif
#endif
  // Contains the LoadTimingInfo events related to establishing a connection.
  // These are all set by ConnectJobs.
  struct TTNET_IMPLEMENT_EXPORT NET_EXPORT_PRIVATE ConnectTiming {
    ConnectTiming();
#if BUILDFLAG(TTNET_IMPLEMENT)
    ConnectTiming(const ConnectTiming& other);
#endif
    ~ConnectTiming();

    // The time spent looking up the host's DNS address.  Null for requests that
    // used proxies to look up the DNS address.  Also null for SOCKS4 proxies,
    // since the DNS address is only looked up after the connection is
    // established, which results in unexpected event ordering.
    // TODO(mmenke):  The SOCKS4 event ordering could be refactored to allow
    //                these times to be non-null.
    // Corresponds to |domainLookupStart| and |domainLookupEnd| in
    // ResourceTiming (http://www.w3.org/TR/resource-timing/) for Web-surfacing
    // requests.
    base::TimeTicks dns_start;
    base::TimeTicks dns_end;

    // The time spent establishing the connection. Connect time includes proxy
    // connect times (though not proxy_resolve or DNS lookup times), time spent
    // waiting in certain queues, TCP, and SSL time.
    // TODO(mmenke):  For proxies, this includes time spent blocking on higher
    //                level socket pools.  Fix this.
    // TODO(mmenke):  Retried connections to the same server should apparently
    //                be included in this time.  Consider supporting that.
    //                Since the network stack has multiple notions of a "retry",
    //                handled at different levels, this may not be worth
    //                worrying about - backup jobs, reused socket failure,
    //                multiple round authentication.
    // Corresponds to |connectStart| and |connectEnd| in ResourceTiming
    // (http://www.w3.org/TR/resource-timing/) for Web-surfacing requests.
    base::TimeTicks connect_start;
    base::TimeTicks connect_end;

    // The time when the SSL handshake started / completed. For non-HTTPS
    // requests these are null.  These times are only for the SSL connection to
    // the final destination server, not an SSL/SPDY proxy.
    // |ssl_start| corresponds to |secureConnectionStart| in ResourceTiming
    // (http://www.w3.org/TR/resource-timing/) for Web-surfacing requests.
    base::TimeTicks ssl_start;
    base::TimeTicks ssl_end;

#if BUILDFLAG(TTNET_IMPLEMENT)
    // connect_job_start means the actual start time of connect job.
    // connect_start means the start time of tcp connect within a connect job,
    // as the connect job include dns, tcp and ssl.
    // We mark the connect_job_start to caculating the time gap before connect
    // job actually started.
    base::Time connect_job_start;

    // Restore DNS related information when connecting, currently only
    // ConnectTiming
    // is passed out of HostResolver, so add |dns_info| here.
    // TODO(jason.yc): Move this out of ConnectTiming.
    DnsInfo dns_info;
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_PROXY_SUPPORT)
    TTNetProxyInfo ttnet_proxy_info;
#endif
    int happy_eyeballs_result{0};
    int32_t socket_send_buffer_size{-1};
    int32_t socket_recv_buffer_size{-1};
#endif
  };

  LoadTimingInfo();
  LoadTimingInfo(const LoadTimingInfo& other);
  ~LoadTimingInfo();

  // True if the socket was reused.  When true, DNS, connect, and SSL times
  // will all be null.  When false, those times may be null, too, for non-HTTP
  // requests, or when they don't apply to a request.
  //
  // For requests that are sent again after an AUTH challenge, this will be true
  // if the original socket is reused, and false if a new socket is used.
  // Responding to a proxy AUTH challenge is never considered to be reusing a
  // socket, since a connection to the host wasn't established when the
  // challenge was received.
  bool socket_reused;

  // Unique socket ID, can be used to identify requests served by the same
  // socket.  For connections tunnelled over SPDY proxies, this is the ID of
  // the virtual connection (The SpdyProxyClientSocket), not the ID of the
  // actual socket.  HTTP requests handled by the SPDY proxy itself all use the
  // actual socket's ID.
  //
  // 0 when there is no socket associated with the request, or it's not an HTTP
  // request.
  uint32_t socket_log_id;

  // Start time as a base::Time, so times can be coverted into actual times.
  // Other times are recorded as TimeTicks so they are not affected by clock
  // changes.
  base::Time request_start_time;

  // Corresponds to |fetchStart| in ResourceTiming
  // (http://www.w3.org/TR/resource-timing/) for Web-surfacing requests.
  base::TimeTicks request_start;

  // The time immediately before starting ServiceWorker. If the response is not
  // provided by the ServiceWorker, kept empty.
  // Corresponds to |workerStart| in
  // ResourceTiming (http://www.w3.org/TR/resource-timing/) for Web-surfacing
  base::TimeTicks service_worker_start_time;

  // The time immediately before dispatching fetch event in ServiceWorker.
  // If the response is not provided by the ServiceWorker, kept empty.
  // This value will be used for |fetchStart| (or |redirectStart|) in
  // ResourceTiming (http://www.w3.org/TR/resource-timing/) for Web-surfacing
  // if this is greater than |request_start|.
  base::TimeTicks service_worker_ready_time;

  // The time when serviceworker fetch event was popped off the event queue
  // and fetch event handler started running.
  // If the response is not provided by the ServiceWorker, kept empty.
  base::TimeTicks service_worker_fetch_start;

  // The time when serviceworker's fetch event's respondWith promise was
  // settled. If the response is not provided by the ServiceWorker, kept empty.
  base::TimeTicks service_worker_respond_with_settled;

  // The time spent determining which proxy to use.  Null when there is no PAC.
  base::TimeTicks proxy_resolve_start;
  base::TimeTicks proxy_resolve_end;

  ConnectTiming connect_timing;

  // The time that sending HTTP request started / ended.
  // |send_start| corresponds to |requestStart| in ResourceTiming
  // (http://www.w3.org/TR/resource-timing/) for Web-surfacing requests.
  base::TimeTicks send_start;
  base::TimeTicks send_end;

  // The time at which the first / last byte of the HTTP headers were received.
  // |receive_headers_start| corresponds to |responseStart| in ResourceTiming
  // (http://www.w3.org/TR/resource-timing/) for Web-surfacing requests.
  base::TimeTicks receive_headers_start;
  base::TimeTicks receive_headers_end;

  // The time that the first 103 Early Hints response is received.
  base::TimeTicks first_early_hints_time;

  // In case the resource was proactively pushed by the server, these are
  // the times that push started and ended. Note that push_end will be null
  // if the request is still being transmitted, i.e. the underlying h2 stream
  // is not closed by the server.
  base::TimeTicks push_start;
  base::TimeTicks push_end;

#if BUILDFLAG(TTNET_IMPLEMENT)
  // HTTP/2 Statistics.
  LoadTimingInfo::Http2Info http2_info;
  // QUIC Statistics.
  LoadTimingInfo::QuicInfo quic_info;
  // Compress information Statistics.
  LoadTimingInfo::CompressInfo compress_info;

  // RFC 7540, 6.5.2: value for SETTINGS_HEADER_TABLE_SIZE.
  uint32_t settings_header_table_size{0};

  // Maximum number of concurrent streams client will create.
  size_t max_concurrent_streams{0};

  std::multimap<std::string, int64_t> runloop_timestamp_info_;

  base::Time http_transaction_start_timestamp;
  base::Time create_stream_start_timestamp;
  base::Time create_stream_finish_timestamp;
  base::Time send_start_timestamp;
  base::Time send_end_timestamp;
  base::Time read_headers_start_timestamp;
  base::Time read_headers_end_timestamp;

  base::Time set_cookie_start_timestamp;
  base::Time set_cookie_end_timestamp;
  base::Time request_delay_start_timestamp;
  base::Time request_delay_end_timestamp;

  bool dns_cross_sp_action_hit{false};
#if !BUILDFLAG(TTNET_IMPLEMENT_DISABLE_STREAM_ZSTD)
  // ZSTD Statistics.
  SourceStreamInfo source_stream_info;
#endif
#endif
};

}  // namespace net

#endif  // NET_BASE_LOAD_TIMING_INFO_H_
