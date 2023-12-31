//
//  Created by xiaoyikai on 1/24/21.
//  Copyright © 2021 ttnet. All rights reserved.
//

#ifndef NET_TT_NET_QUIC_QUIC_CLIENT_SESSION_CACHE_H_
#define NET_TT_NET_QUIC_QUIC_CLIENT_SESSION_CACHE_H_

#include "net/http/http_server_properties.h"
#include "net/third_party/quiche/src/quic/core/crypto/transport_parameters.h"
#include "net/third_party/quiche/src/quic/core/quic_types.h"
#include "third_party/boringssl/src/include/openssl/base.h"

namespace net {

class NET_EXPORT_PRIVATE TTQuicClientSessionCache {
 public:
  TTQuicClientSessionCache(HttpServerProperties* http_server_properties);
  ~TTQuicClientSessionCache();

 private:
  friend class QuicClientSessionCache;
  bool LoadFromIetfQuicSessionMap(const quic::QuicServerId& server_id,
      const SSL_CTX* ctx, SSL_SESSION** const tls_session,
      quic::TransportParameters** const params,
      std::string* application_state);
  void SaveToIetfQuicSessionMap(const quic::QuicServerId& server_id,
                                const SSL_SESSION* tls_session,
                                const quic::TransportParameters* params,
                                const quic::ApplicationState* application_state);

  HttpServerProperties* const http_server_properties_;
};

}  // namespace net

#endif  // NET_TT_NET_QUIC_QUIC_CLIENT_SESSION_CACHE_H_
