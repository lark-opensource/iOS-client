#ifndef DEBUGROUTER_PROCESSOR_H_
#define DEBUGROUTER_PROCESSOR_H_

#include "message_handler.h"
#include "protocol/protocol.h"
#include "protocol/protocol_message.h"
#include <string>

namespace debugrouter {
namespace processor {

constexpr const char *kDebugRouterErrorMessage = "DebugRouterError";
constexpr int kDebugRouterErrorCode = -3;

class Processor {
public:
  Processor(std::unique_ptr<MessageHandler> message_handler);
  void Process(protocol::ProtocolMessage &message);
  void Process(const std::string &message);
  std::string WrapCustomizedMessage(const std::string &type, int session_id,
                                    const std::string &message, int mark,
                                    bool isObject = false);
  void FlushSessionList();
  void SetIsReconnect(bool is_reconnect);

private:
  void registerDevice();
  void joinRoom();
  void sessionList();
  void changeRoomServer(const std::string &url, const std::string &room);
  void openCard(const std::string &url);
  void processMessage(const std::string &type, int session_id,
                      const std::string &message);
  void
  HandleAppAction(std::shared_ptr<protocol::RemoteDebugProtocolBodyData4Custom>
                      custom_data);
  std::string wrapStopAtEntryMessage(const std::string &type,
                                     const std::string &message) const;

  debugrouter::protocol::RemoteDebugPrococolClientId client_id_;
  std::unique_ptr<MessageHandler> message_handler_;
  bool is_reconnect_;

  void process(const Json::Value &root);
};

} // namespace processor
} // namespace debugrouter

#endif /* DEBUGROUTER_PROCESSOR_H_ */
