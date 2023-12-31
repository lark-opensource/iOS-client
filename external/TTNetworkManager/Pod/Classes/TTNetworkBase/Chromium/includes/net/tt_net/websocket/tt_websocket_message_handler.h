#ifndef NET_TT_NET_WEBSOCKET_TT_WEBSOCKET_MESSAGE_HANDLER_H_
#define NET_TT_NET_WEBSOCKET_TT_WEBSOCKET_MESSAGE_HANDLER_H_

#include <string>

namespace net {

class TTWebsocketMessageHandler {
 public:
  virtual ~TTWebsocketMessageHandler();

  static std::unique_ptr<TTWebsocketMessageHandler> Create();

  virtual bool HandleMessage(const std::string& message) = 0;
};

}  // namespace net

#endif  // NET_TT_NET_WEBSOCKET_TT_WEBSOCKET_MESSAGE_HANDLER_H_
