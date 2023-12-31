// Copyright 2020 The Lynx Authors. All rights reserved.

#include "agent/domain_agent/inspector_ark_replay_agent.h"

#include "agent/devtool_agent_ng.h"
#include "base/file_stream.h"
#include "element/element_helper.h"
#include "tasm/replay/replay_controller.h"

namespace lynxdev {
namespace devtool {

InspectorArkReplayAgent::InspectorArkReplayAgent() {
  functions_map_["Replay.start"] = &InspectorArkReplayAgent::Start;
  functions_map_["Replay.end"] = &InspectorArkReplayAgent::End;
}

InspectorArkReplayAgent::~InspectorArkReplayAgent() = default;

void InspectorArkReplayAgent::CallMethod(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  std::string method = message["method"].asString();
  auto iter = functions_map_.find(method);
  if (iter == functions_map_.end() || devtool_agent == nullptr ||
      !lynx::tasm::replay::ReplayController::Enable()) {
    Json::Value res;
    res["error"]["code"] = kLynxInspectorErrorCode;
    res["error"]["message"] = "Not implemented: " + method;
    res["id"] = message["id"].asInt64();
    devtool_agent->SendResponseAsync(res);
  } else {
    (this->*(iter->second))(
        std::static_pointer_cast<DevToolAgentNG>(devtool_agent), message);
  }
}

void InspectorArkReplayAgent::Start(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  int id = static_cast<int>(message["id"].asInt64());
  LOGI("start replay test");
  lynx::tasm::replay::ReplayController::StartTest();
  Json::Value res;
  res["result"] = Json::Value(Json::ValueType::objectValue);
  res["id"] = id;
  devtool_agent->SendResponseAsync(res);
}

void InspectorArkReplayAgent::End(std::shared_ptr<DevToolAgentNG> devtool_agent,
                                  const Json::Value& message) {
  if (lynx::tasm::replay::ReplayController::Enable()) {
    LOGI("send replay end");
    Json::Value content(Json::ValueType::objectValue);
    content["method"] = "Replay.end";
    std::string file_path = message["params"].asString();
    int stream_handle = FileStream::Open(file_path);
    content["params"]["stream"] = std::to_string(stream_handle);
    devtool_agent->SendResponseAsync(content);
  }
}

}  // namespace devtool
}  // namespace lynxdev
