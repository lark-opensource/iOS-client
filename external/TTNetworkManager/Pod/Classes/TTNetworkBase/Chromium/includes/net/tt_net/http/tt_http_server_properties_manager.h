//
//  Created by xiaoyikai on 1/24/21.
//  Copyright © 2021 ttnet. All rights reserved.
//

#ifndef NET_TT_NET_HTTP_HTTP_SERVER_PROPERTIES_MANAGER_H_
#define NET_TT_NET_HTTP_HTTP_SERVER_PROPERTIES_MANAGER_H_

#include "base/macros.h"
#include "base/values.h"
#include "net/tt_net/http/tt_http_server_properties.h"

namespace net {

class NET_EXPORT_PRIVATE TTHttpServerPropertiesManager {
 public:
  TTHttpServerPropertiesManager() = default;
  ~TTHttpServerPropertiesManager() = default;

  static void AddToIetfQuicSessionMap(
      const base::DictionaryValue& server_dict,
      TTHttpServerProperties::IetfQuicSessionMap* ietf_quic_session_map);
  static void SaveIetfQuicSessionMapToServerPrefs(
      const TTHttpServerProperties::IetfQuicSessionMap& ietf_quic_session_map,
      base::DictionaryValue* http_server_properties_dict);
};

}  // namespace net

#endif  // NET_TT_NET_HTTP_HTTP_SERVER_PROPERTIES_MANAGER_H_
