// Copyright 2021 The Lynx Authors. All rights reserved.

#include "agent/domain_agent/inspector_ark_recorder_agent.h"

#include <fstream>

#include "agent/devtool_agent_base.h"
#include "base/closure.h"
#include "base/file_stream.h"
#include "tasm/recorder/recorder_controller.h"

namespace lynxdev {
namespace devtool {

InspectorArkRecorderAgent::InspectorArkRecorderAgent() {
  functions_map_["Recording.start"] = &InspectorArkRecorderAgent::Start;
  functions_map_["Recording.end"] = &InspectorArkRecorderAgent::End;
}

void InspectorArkRecorderAgent::CallMethod(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  std::string method = message["method"].asString();
  auto iter = functions_map_.find(method);
  if (iter == functions_map_.end() || devtool_agent == nullptr ||
      !lynx::tasm::recorder::RecorderController::Enable()) {
    Json::Value res;
    res["error"]["code"] = kLynxInspectorErrorCode;
    res["error"]["message"] = "Not implemented: " + method;
    res["id"] = message["id"].asInt64();
    devtool_agent->SendResponseAsync(res);
  } else {
    (this->*(iter->second))(devtool_agent, message);
  }
}

void InspectorArkRecorderAgent::Start(
    const std::shared_ptr<DevToolAgentBase>& devtool_agent,
    const Json::Value& message) {
  int id = static_cast<int>(message["id"].asInt64());
  LOGI("start recording");
  std::string url = message["url"].asString();
  lynx::tasm::recorder::RecorderController::StartRecord(url);
  Json::Value res;
  res["result"] = Json::Value(Json::ValueType::objectValue);
  res["id"] = id;
  devtool_agent->RecordEnable(true);
  devtool_agent->SendResponseAsync(res);
}

void InspectorArkRecorderAgent::End(
    const std::shared_ptr<DevToolAgentBase>& devtool_agent,
    const Json::Value& message) {
  int id = static_cast<int>(message["id"].asInt64());
  LOGI("End recording");
  lynx::base::MoveOnlyClosure<void, std::vector<std::string>&,
                              std::vector<int64_t>&>
      send_complete(
          [devtool_agent_bak = devtool_agent](std::vector<std::string>& files,
                                              std::vector<int64_t>& sessions) {
            Json::Value msg;
            msg["method"] = "Recording.recordingComplete";
            Json::Value handlers, filenames, session_ids;
            for (auto i : sessions) {
              session_ids.append(i);
            }
            for (auto item : files) {
              int stream_handle = FileStream::Open(item);
              handlers.append(stream_handle);
              filenames.append(item);
            }
            msg["params"]["stream"] = handlers;
            msg["params"]["filenames"] = filenames;
            msg["params"]["sessionIDs"] = session_ids;
            msg["params"]["recordFormat"] = "json";
            devtool_agent_bak->SendResponseAsync(msg);
          });
  lynx::tasm::recorder::RecorderController::EndRecord(std::move(send_complete));
  devtool_agent->RecordEnable(false);
  devtool_agent->ResponseOK(id);
}

}  // namespace devtool
}  // namespace lynxdev
