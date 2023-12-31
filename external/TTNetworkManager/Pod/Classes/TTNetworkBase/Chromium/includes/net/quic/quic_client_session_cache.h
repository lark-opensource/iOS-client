// Copyright (c) 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef NET_QUIC_QUIC_CLIENT_SESSION_CACHE_H_
#define NET_QUIC_QUIC_CLIENT_SESSION_CACHE_H_

#include <stddef.h>
#include <time.h>

#include <memory>
#include <string>

#include "base/bind.h"
#include "base/containers/mru_cache.h"
#include "base/memory/memory_pressure_monitor.h"
#include "base/time/time.h"
#include "net/third_party/quiche/src/quic/core/crypto/quic_crypto_client_config.h"
#include "third_party/boringssl/src/include/openssl/base.h"
#if BUILDFLAG(TTNET_IMPLEMENT)
#include "net/http/http_server_properties.h"
#include "net/tt_net/quic/tt_quic_client_session_cache.h"
#endif

namespace base {
class Clock;
}

namespace net {

class NET_EXPORT_PRIVATE QuicClientSessionCache : public quic::SessionCache {
 public:
  QuicClientSessionCache();
#if BUILDFLAG(TTNET_IMPLEMENT)
  QuicClientSessionCache(HttpServerProperties* http_server_properties,
                         size_t max_entries);
#else
  explicit QuicClientSessionCache(size_t max_entries);
#endif
  ~QuicClientSessionCache() override;

  void Insert(const quic::QuicServerId& server_id,
              bssl::UniquePtr<SSL_SESSION> session,
              const quic::TransportParameters& params,
              const quic::ApplicationState* application_state) override;

  std::unique_ptr<quic::QuicResumptionState> Lookup(
      const quic::QuicServerId& server_id,
      const SSL_CTX* ctx) override;

  void ClearEarlyData(const quic::QuicServerId& server_id) override;

  void SetClockForTesting(base::Clock* clock) { clock_ = clock; }

  size_t size() const { return cache_.size(); }

  void Flush();

  void OnMemoryPressure(
      base::MemoryPressureListener::MemoryPressureLevel memory_pressure_level);

 private:
  struct Entry {
    Entry();
    Entry(Entry&&);
    ~Entry();

    // Adds a new |session| onto sessions, dropping the oldest one if two are
    // already stored.
    void PushSession(bssl::UniquePtr<SSL_SESSION> session);

    // Retrieves the latest session from the entry, meanwhile removing it.
    bssl::UniquePtr<SSL_SESSION> PopSession();

#if BUILDFLAG(TTNET_IMPLEMENT)
    SSL_SESSION* PeekSession() const;
#else
    SSL_SESSION* PeekSession();
#endif

    bssl::UniquePtr<SSL_SESSION> sessions[2];
    std::unique_ptr<quic::TransportParameters> params;
    std::unique_ptr<quic::ApplicationState> application_state;
  };
  void FlushInvalidEntries();

  // Creates a new entry and insert into |cache_|.
  void CreateAndInsertEntry(const quic::QuicServerId& server_id,
                            bssl::UniquePtr<SSL_SESSION> session,
                            const quic::TransportParameters& params,
                            const quic::ApplicationState* application_state);

  base::Clock* clock_;
  base::MRUCache<quic::QuicServerId, Entry> cache_;
  std::unique_ptr<base::MemoryPressureListener> memory_pressure_listener_;
#if BUILDFLAG(TTNET_IMPLEMENT)
  TTQuicClientSessionCache tt_quic_client_session_cache_;
#endif
};

}  // namespace net

#endif  // NET_QUIC_QUIC_CLIENT_SESSION_CACHE_H_
