// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_QUIC_QUIC_CONTEXT_H_
#define NET_QUIC_QUIC_CONTEXT_H_

#include <memory>

#include "net/base/host_port_pair.h"
#include "net/third_party/quiche/src/quic/core/quic_connection.h"

namespace net {

// Default QUIC supprted versions used in absence of any external configuration.
inline NET_EXPORT_PRIVATE quic::ParsedQuicVersionVector
DefaultSupportedQuicVersions() {
#if BUILDFLAG(TTNET_IMPLEMENT)
  return quic::ParsedQuicVersionVector{quic::ParsedQuicVersion::Q043(),
                                       quic::ParsedQuicVersion::Draft29()};
#else
  return quic::ParsedQuicVersionVector{quic::ParsedQuicVersion::Q050()};
#endif
}

// When a connection is idle for 30 seconds it will be closed.
constexpr base::TimeDelta kIdleConnectionTimeout =
    base::TimeDelta::FromSeconds(30);

// Sessions can migrate if they have been idle for less than this period.
constexpr base::TimeDelta kDefaultIdleSessionMigrationPeriod =
    base::TimeDelta::FromSeconds(30);

// The default maximum time allowed to have no retransmittable packets on the
// wire (after sending the first retransmittable packet) if
// |migrate_session_early_v2_| is true. PING frames will be sent as needed to
// enforce this.
constexpr base::TimeDelta kDefaultRetransmittableOnWireTimeout =
    base::TimeDelta::FromMilliseconds(200);

// The default maximum time QUIC session could be on non-default network before
// migrate back to default network.
constexpr base::TimeDelta kMaxTimeOnNonDefaultNetwork =
    base::TimeDelta::FromSeconds(128);

// The default maximum number of migrations to non default network on write
// error per network.
const int64_t kMaxMigrationsToNonDefaultNetworkOnWriteError = 5;

// The default maximum number of migrations to non default network on path
// degrading per network.
const int64_t kMaxMigrationsToNonDefaultNetworkOnPathDegrading = 5;

// QUIC's socket receive buffer size.
// We should adaptively set this buffer size, but for now, we'll use a size
// that seems large enough to receive data at line rate for most connections,
// and does not consume "too much" memory.
const int32_t kQuicSocketReceiveBufferSize = 1024 * 1024;  // 1MB

// Structure containing simple configuration options and experiments for QUIC.
struct NET_EXPORT QuicParams {
  QuicParams();
  QuicParams(const QuicParams& other);
  ~QuicParams();

  // QUIC runtime configuration options.

  // Versions of QUIC which may be used.
  quic::ParsedQuicVersionVector supported_versions =
      DefaultSupportedQuicVersions();
  // User agent description to send in the QUIC handshake.
  std::string user_agent_id;
  // Limit on the size of QUIC packets.
  size_t max_packet_length = quic::kDefaultMaxPacketSize;
  // Maximum number of server configs that are to be stored in
  // HttpServerProperties, instead of the disk cache.
  size_t max_server_configs_stored_in_properties = 0u;
  // QUIC will be used for all connections in this set.
  std::set<HostPortPair> origins_to_force_quic_on;
  // Set of QUIC tags to send in the handshake's connection options.
  quic::QuicTagVector connection_options;
  // Set of QUIC tags to send in the handshake's connection options that only
  // affect the client.
  quic::QuicTagVector client_connection_options;
  // Enables experimental optimization for receiving data in UDPSocket.
  bool enable_socket_recv_optimization = false;
  // Initial value of QuicSpdyClientSessionBase::max_allowed_push_id_.
  quic::QuicStreamId max_allowed_push_id = 0;

  // Active QUIC experiments

  // Retry requests which fail with QUIC_PROTOCOL_ERROR, and mark QUIC
  // broken if the retry succeeds.
  bool retry_without_alt_svc_on_quic_errors = true;
  // If true, all QUIC sessions are closed when any local IP address changes.
#if BUILDFLAG(TTNET_IMPLEMENT) && !BUILDFLAG(TTNET_IMPLEMENT_UNITTEST)
  bool close_sessions_on_ip_change = true;
#else
  bool close_sessions_on_ip_change = false;
#endif
  // If true, all QUIC sessions are marked as goaway when any local IP address
  // changes.
  bool goaway_sessions_on_ip_change = false;
  // Specifies QUIC idle connection state lifetime.
  base::TimeDelta idle_connection_timeout = kIdleConnectionTimeout;
  // Specifies the reduced ping timeout subsequent connections should use when
  // a connection was timed out with open streams.
  base::TimeDelta reduced_ping_timeout =
      base::TimeDelta::FromSeconds(quic::kPingTimeoutSecs);
  // Maximum time that a session can have no retransmittable packets on the
  // wire. Set to zero if not specified and no retransmittable PING will be
  // sent to peer when the wire has no retransmittable packets.
  base::TimeDelta retransmittable_on_wire_timeout;
  // Maximum time the session can be alive before crypto handshake is
  // finished.
  base::TimeDelta max_time_before_crypto_handshake =
      base::TimeDelta::FromSeconds(quic::kMaxTimeForCryptoHandshakeSecs);
  // Maximum idle time before the crypto handshake has completed.
  base::TimeDelta max_idle_time_before_crypto_handshake =
      base::TimeDelta::FromSeconds(quic::kInitialIdleTimeoutSecs);
  // If true, connection migration v2 will be used to migrate existing
  // sessions to network when the platform indicates that the default network
  // is changing.
  bool migrate_sessions_on_network_change_v2 = false;
  // If true, connection migration v2 may be used to migrate active QUIC
  // sessions to alternative network if current network connectivity is poor.
  bool migrate_sessions_early_v2 = false;
  // If true, a new connection may be kicked off on an alternate network when
  // a connection fails on the default network before handshake is confirmed.
  bool retry_on_alternate_network_before_handshake = false;
  // If true, an idle session will be migrated within the idle migration
  // period.
  bool migrate_idle_sessions = false;
  // If true, sessions with open streams will attempt to migrate to a different
  // port when the current path is poor.
  bool allow_port_migration = false;
  // A session can be migrated if its idle time is within this period.
  base::TimeDelta idle_session_migration_period =
      kDefaultIdleSessionMigrationPeriod;
  // Maximum time the session could be on the non-default network before
  // migrates back to default network. Defaults to
  // kMaxTimeOnNonDefaultNetwork.
  base::TimeDelta max_time_on_non_default_network = kMaxTimeOnNonDefaultNetwork;
  // Maximum number of migrations to the non-default network on write error
  // per network for each session.
  int max_migrations_to_non_default_network_on_write_error =
      kMaxMigrationsToNonDefaultNetworkOnWriteError;
  // Maximum number of migrations to the non-default network on path
  // degrading per network for each session.
  int max_migrations_to_non_default_network_on_path_degrading =
      kMaxMigrationsToNonDefaultNetworkOnPathDegrading;
  // If true, allows migration of QUIC connections to a server-specified
  // alternate server address.
  bool allow_server_migration = false;
  // If true, allows QUIC to use alternative services with a different
  // hostname from the origin.
  bool allow_remote_alt_svc = true;
  // If true, the quic stream factory may race connection from stale dns
  // result with the original dns resolution
  bool race_stale_dns_on_connection = false;
  // If true, the quic session may mark itself as GOAWAY on path degrading.
  bool go_away_on_path_degrading = false;
  // If true, bidirectional streams over QUIC will be disabled.
  bool disable_bidirectional_streams = false;
  // If true, estimate the initial RTT for QUIC connections based on network.
  bool estimate_initial_rtt = false;
  // If true, client headers will include HTTP/2 stream dependency info
  // derived from the request priority.
  bool headers_include_h2_stream_dependency = false;
  // The initial rtt that will be used in crypto handshake if no cached
  // smoothed rtt is present.
  base::TimeDelta initial_rtt_for_handshake;
  // If true, QUIC with TLS will not try 0-RTT connection.
  bool disable_tls_zero_rtt = false;
  // If true, gQUIC requests will always require confirmation.
  bool disable_gquic_zero_rtt = false;
};

// QuicContext contains QUIC-related variables that are shared across all of the
// QUIC connections, both HTTP and non-HTTP ones.
class NET_EXPORT_PRIVATE QuicContext {
 public:
  QuicContext();
  QuicContext(std::unique_ptr<quic::QuicConnectionHelperInterface> helper);
  ~QuicContext();

  quic::QuicConnectionHelperInterface* helper() { return helper_.get(); }
  const quic::QuicClock* clock() { return helper_->GetClock(); }
  quic::QuicRandom* random_generator() { return helper_->GetRandomGenerator(); }

  QuicParams* params() { return &params_; }
  quic::ParsedQuicVersion GetDefaultVersion() {
    return params_.supported_versions[0];
  }
  const quic::ParsedQuicVersionVector& supported_versions() {
    return params_.supported_versions;
  }

  void SetHelperForTesting(
      std::unique_ptr<quic::QuicConnectionHelperInterface> helper) {
    helper_ = std::move(helper);
  }

 private:
  std::unique_ptr<quic::QuicConnectionHelperInterface> helper_;

  QuicParams params_;
};

// Initializes QuicConfig based on the specified parameters.
quic::QuicConfig InitializeQuicConfig(const QuicParams& params);

}  // namespace net

#endif  // NET_QUIC_QUIC_CONTEXT_H_
