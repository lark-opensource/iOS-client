//
//  tt_websocket_manager.h
//  sources
//
//  Created by gaohaidong on 2018/8/23.
//

#ifndef NET_TT_NET_WEBSOCKET_TT_WEBSOCKET_MANAGER_H_
#define NET_TT_NET_WEBSOCKET_TT_WEBSOCKET_MANAGER_H_

#include "base/memory/singleton.h"
#include "net/tt_net/websocket/tt_websocket_client.h"

namespace net {

class TTNET_IMPLEMENT_EXPORT WSManager {
 public:
  static WSManager* GetInstance();
  ~WSManager();

  // Every app should only has one shared connection.
  WSClient* SharedConnection(WSClient::ConnectionMode mode);

  // In rare case, app may start a new connecton.
  // NOT recommend to start many new connections.
  std::unique_ptr<WSClient> NewConnection(WSClient::ConnectionMode mode);

 private:
  friend struct base::DefaultSingletonTraits<WSManager>;
  WSManager();

  std::unique_ptr<WSClient> ws_client_;

  DISALLOW_COPY_AND_ASSIGN(WSManager);
};

}  // namespace net

#endif /* NET_TT_NET_WEBSOCKET_TT_WEBSOCKET_MANAGER_H_ */
