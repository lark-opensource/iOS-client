// Copyright 2019 The Lynx Authors. All rights reserved.

#include "agent/domain_agent/inspector_input_agent.h"

#include <sstream>

#include "agent/devtool_agent_base.h"
#include "base/mouse_event.h"

namespace lynxdev {
namespace devtool {

InspectorInputAgent::InspectorInputAgent() {
  functions_map_["Input.emulateTouchFromMouseEvent"] =
      &InspectorInputAgent::EmulateTouchFromMouseEvent;
}

InspectorInputAgent::~InspectorInputAgent() = default;

void InspectorInputAgent::EmulateTouchFromMouseEvent(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  Json::Value params = message["params"];

  std::shared_ptr<MouseEvent> input = std::make_shared<MouseEvent>();
  input->button_ = params["button"].asString();
  input->clickcount_ = params["clickCount"].asInt();
  input->delta_x_ = params["deltaX"].asFloat();
  input->delta_y_ = params["deltaY"].asFloat();
  input->modifiers_ = params["modifiers"].asInt();
  input->type_ = params["type"].asString();
  input->x_ = params["x"].asInt();
  input->y_ = params["y"].asInt();
  devtool_agent->EmulateTouch(input);
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorInputAgent::CallMethod(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  std::string method = message["method"].asString();
  Json::Value params = message["params"];

  auto iter = functions_map_.find(method);
  if (iter == functions_map_.end()) {
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
}  // namespace devtool
}  // namespace lynxdev
