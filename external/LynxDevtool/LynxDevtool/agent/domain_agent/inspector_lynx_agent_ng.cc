// Copyright 2021 The Lynx Authors. All rights reserved.

#include "inspector_lynx_agent_ng.h"

#include "agent/devtool_agent_ng.h"
#include "element/element_helper.h"

namespace lynxdev {
namespace devtool {

InspectorLynxAgentNG::InspectorLynxAgentNG() {
  functions_map_["Lynx.getProperties"] = &InspectorLynxAgentNG::GetProperties;
  functions_map_["Lynx.getData"] = &InspectorLynxAgentNG::GetData;
  functions_map_["Lynx.getComponentId"] = &InspectorLynxAgentNG::GetComponentId;
  functions_map_["Lynx.getRectToWindow"] =
      &InspectorLynxAgentNG::GetLynxViewRectToWindow;
  functions_map_["Lynx.getVersion"] = &InspectorLynxAgentNG::GetLynxVersion;
  functions_map_["Lynx.transferData"] = &InspectorLynxAgentNG::TransferData;
  functions_map_["Lynx.setTraceMode"] = &InspectorLynxAgentNG::SetTraceMode;
  functions_map_["Lynx.getScreenshot"] = &InspectorLynxAgentNG::GetScreenshot;
}

InspectorLynxAgentNG::~InspectorLynxAgentNG() = default;

void InspectorLynxAgentNG::CallMethod(
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
    (this->*(iter->second))(
        std::static_pointer_cast<DevToolAgentNG>(devtool_agent), message);
  }
}

// return physical pixel rect of lynx view
void InspectorLynxAgentNG::GetLynxViewRectToWindow(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value rect(Json::ValueType::objectValue);
  auto dict = ElementInspector::GetRectToWindow(devtool_agent->GetRoot());
  rect["left"] = dict[0];
  rect["top"] = dict[1];
  rect["width"] = dict[2];
  rect["height"] = dict[3];
  response["result"] = rect;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorLynxAgentNG::GetProperties(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  content["properties"] = "";
  Json::Value params = message["params"];
  size_t index = static_cast<size_t>(params["nodeId"].asInt64());
  auto* ptr = devtool_agent->GetElementById(devtool_agent->GetRoot(), index);
  if (ptr) {
    if (ElementInspector::Type(ptr) == InspectorElementType::COMPONENT) {
      content["properties"] = ElementHelper::GetProperties(ptr);
    } else if (ElementInspector::Type(ptr) ==
               InspectorElementType::SHADOWROOT) {
      content["properties"] = ElementHelper::GetProperties(ptr->parent());
    }
  }
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorLynxAgentNG::GetData(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  content["data"] = "";
  Json::Value params = message["params"];
  size_t index = static_cast<size_t>(params["nodeId"].asInt64());
  auto* ptr = devtool_agent->GetElementById(devtool_agent->GetRoot(), index);
  if (ptr) {
    if (ElementInspector::Type(ptr) == InspectorElementType::COMPONENT) {
      content["data"] = ElementHelper::GetData(ptr);
    } else if (ElementInspector::Type(ptr) ==
               InspectorElementType::SHADOWROOT) {
      content["data"] = ElementHelper::GetData(ptr->parent());
    }
  }
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorLynxAgentNG::GetComponentId(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  content["componentId"] = -1;
  Json::Value params = message["params"];
  size_t index = static_cast<size_t>(params["nodeId"].asInt64());
  auto* ptr = devtool_agent->GetElementById(devtool_agent->GetRoot(), index);
  if (ptr) {
    if (ElementInspector::Type(ptr) == InspectorElementType::COMPONENT) {
      content["componentId"] = ElementHelper::GetComponentId(ptr);
    } else if (ElementInspector::Type(ptr) ==
               InspectorElementType::SHADOWROOT) {
      content["componentId"] = ElementHelper::GetComponentId(ptr->parent());
    }
  }
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorLynxAgentNG::GetLynxVersion(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  response["result"] = devtool_agent->GetLynxVersion();
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorLynxAgentNG::TransferData(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value params = message["params"];
  if (params.empty()) {
    return;
  }

  Json::Value data_type = params["dataType"];
  if (!data_type.empty() && !data_type.asString().compare("template")) {
    Json::Value data = params["data"];
    Json::Value eof = params["eof"];
    if (data.isString() && eof.isBool()) {
      devtool_agent->OnReceiveTemplateFragment(data.asString(), eof.asBool());
    }
  }
}

void InspectorLynxAgentNG::SetTraceMode(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content = Json::Value(Json::ValueType::objectValue);

  Json::Value params = message["params"];
  if (!params.empty()) {
    Json::Value enable_trace_mode = params["enableTraceMode"];
    if (!enable_trace_mode.empty() && enable_trace_mode.isBool()) {
      bool value = enable_trace_mode.asBool();
      devtool_agent->EnableTraceMode(value);
    }
  }
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorLynxAgentNG::GetScreenshot(
    std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& message) {
  devtool_agent->SendOneshotScreenshot();
  // send empty response
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content = Json::Value(Json::ValueType::objectValue);
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

}  // namespace devtool
}  // namespace lynxdev
