// Copyright 2020 The Lynx Authors. All rights reserved.
#ifndef DEBUGROUTER_PROTOCOL_MESSAGE_H_
#define DEBUGROUTER_PROTOCOL_MESSAGE_H_

#include "json/value.h"
#include <memory>
#include <string>

#ifndef DEVTOOL_DLL_EXPORT
  #if defined(OS_WIN)
    #ifdef BUILD_DLL
      #define DEVTOOL_DLL_EXPORT __declspec(dllexport)
    #else
      #define DEVTOOL_DLL_EXPORT __declspec(dllimport)
    #endif
  #else
    #define DEVTOOL_DLL_EXPORT
  #endif
#endif

namespace debugrouter {
namespace protocol {
class ProtocolMessage {

public:
  DEVTOOL_DLL_EXPORT static bool is_use_protocol_message_;

  DEVTOOL_DLL_EXPORT const std::string &GetStringValue();

  const Json::Value &GetJsonValue();

  bool IsNull();

  DEVTOOL_DLL_EXPORT explicit ProtocolMessage(Json::Value &&json);

  explicit ProtocolMessage(std::string &&str);

  explicit ProtocolMessage(const ProtocolMessage &message);

  ProtocolMessage &operator=(const ProtocolMessage &message) = delete;
  ProtocolMessage &operator=(ProtocolMessage &&message) = delete;

  explicit ProtocolMessage(ProtocolMessage &&message);

  virtual ~ProtocolMessage();

protected:
  std::unique_ptr<std::string> content_ptr_;
  std::unique_ptr<Json::Value> root_ptr_;
};
} // namespace protocol
} // namespace debugrouter

#endif // DEBUGROUTER_PROTOCOL_MESSAGE_H_
