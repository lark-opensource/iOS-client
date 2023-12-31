// Copyright 2020 The Lynx Authors. All rights reserved.

#include "agent/domain_agent/inspector_io_agent.h"

#include <fstream>
#include <sstream>

#include "agent/devtool_agent_base.h"
#include "base/file_stream.h"
#include "base/log/logging.h"
#include "third_party/modp_b64/modp_b64.h"

namespace lynxdev {
namespace devtool {

InspectorIOAgent::InspectorIOAgent() {
  functions_map_["IO.read"] = &InspectorIOAgent::Read;
  functions_map_["IO.close"] = &InspectorIOAgent::Close;
  functions_map_["IO.resolveBlob"] = &InspectorIOAgent::ResolveBlob;
}

InspectorIOAgent::~InspectorIOAgent() = default;

void InspectorIOAgent::CallMethod(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  std::string method = message["method"].asString();
  auto iter = functions_map_.find(method);
  if (iter == functions_map_.end() || devtool_agent == nullptr) {
    Json::Value res;
    res["error"] = Json::ValueType::objectValue;
    res["error"]["code"] = kLynxInspectorErrorCode;
    res["error"]["message"] = "Not implemented: " + method;
    res["id"] = message["id"].asInt64();
    devtool_agent->SendResponseAsync(res);
  } else {
    (this->*(iter->second))(devtool_agent, message);
  }
}

void InspectorIOAgent::Read(std::shared_ptr<DevToolAgentBase> devtool_agent,
                            const Json::Value& message) {
  std::string handle_str = message["params"]["handle"].asString();
  if (!std::isdigit(handle_str[0])) {
    DLOGE("Get invalid stream handle:" << handle_str);
    Json::Value res;
    res["error"] = Json::ValueType::objectValue;
    res["error"]["code"] = kLynxInspectorErrorCode;
    res["error"]["message"] = "Get invalid stream handle";
    res["id"] = message["id"].asInt64();
    devtool_agent->SendResponseAsync(res);
    return;
  }

  std::ostringstream oss;
  Json::Value res;
  res["id"] = message["id"].asInt64();
  res["result"]["base64Encoded"] = true;
  int size = static_cast<int>(message["params"]["size"].asInt64());
  if (size > 0) {
    std::unique_ptr<char[]> buff = std::make_unique<char[]>(size);
    int total_read = FileStream::Read(std::stoi(handle_str),
                                      static_cast<char*>(buff.get()), size);
    if (total_read > 0) {
      int encode_length = modp_b64_encode_len(total_read);
      std::unique_ptr<char[]> encode_buff =
          std::make_unique<char[]>(encode_length);
      modp_b64_encode(encode_buff.get(), buff.get(), total_read);
      res["result"]["data"] = encode_buff.get();
    }
    if (total_read == size) {
      res["result"]["eof"] = false;
    } else {
      res["result"]["eof"] = true;
    }
  } else {
    res["result"]["eof"] = true;
  }
  devtool_agent->SendResponseAsync(res);
}

void InspectorIOAgent::Close(std::shared_ptr<DevToolAgentBase> devtool_agent,
                             const Json::Value& message) {
  std::string handle_str = message["params"]["handle"].asString();
  if (!std::isdigit(handle_str[0])) {
    DLOGE("Get invalid stream handle");
    return;
  }
  FileStream::Close(std::stoi(handle_str));

  Json::Value res;
  res["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(res);
}

void InspectorIOAgent::ResolveBlob(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {}

}  // namespace devtool
}  // namespace lynxdev
