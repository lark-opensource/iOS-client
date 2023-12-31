//
//  Created by xiaoyikai on 1/24/21.
//  Copyright © 2021 ttnet. All rights reserved.
//

#ifndef NET_TT_NET_HTTP_HTTP_SERVER_PROPERTIES_H_
#define NET_TT_NET_HTTP_HTTP_SERVER_PROPERTIES_H_

#include "base/macros.h"
#include "base/containers/mru_cache.h"
#include "net/third_party/quiche/src/quic/core/quic_server_id.h"

namespace net {

class HttpServerProperties;
class HttpServerPropertiesManager;

class NET_EXPORT TTHttpServerProperties {
 public:
  typedef base::MRUCache<quic::QuicServerId, std::string> IetfQuicSessionMap;

  TTHttpServerProperties(size_t max_server_configs_stored_in_properties,
                         HttpServerProperties* delegate);

  ~TTHttpServerProperties();

  void SetIetfQuicSession(const quic::QuicServerId& server_id,
                          const std::string& server_info);

  const std::string* GetIetfQuicSession(
      const quic::QuicServerId& server_id);

  const IetfQuicSessionMap& ietf_quic_session_map() const;

  void SetMaxServerConfigsStoredInProperties(
      size_t max_server_configs_stored_in_properties);

 private:
  friend class HttpServerProperties;

  void OnIetfQuicSessionMapLoaded(
      std::unique_ptr<IetfQuicSessionMap> ietf_quic_session_map);

  IetfQuicSessionMap ietf_quic_session_map_;
  HttpServerProperties* const delegate_;

  DISALLOW_COPY_AND_ASSIGN(TTHttpServerProperties);
};

}  // namespace net

#endif  // NET_TT_NET_HTTP_HTTP_SERVER_PROPERTIES_H_
