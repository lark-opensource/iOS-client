// Copyright 2021 The Lynx Authors. All rights reserved.

#include "agent/domain_agent/inspector_template_agent.h"

#include "agent/devtool_agent_base.h"
#include "lepus/json_parser.h"

namespace lynxdev {
namespace devtool {
InspectorTemplateAgent::InspectorTemplateAgent() {
  functions_map_["Template.templateData"] =
      &InspectorTemplateAgent::GetTemplateData;
  functions_map_["Template.templateConfigInfo"] =
      &InspectorTemplateAgent::GetTemplateConfigInfo;
  functions_map_["Template.templateApi"] =
      &InspectorTemplateAgent::GetTemplateApiInfo;
}

InspectorTemplateAgent::~InspectorTemplateAgent() = default;

void InspectorTemplateAgent::GetTemplateData(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value result(Json::ValueType::objectValue);

  lynx::lepus::Value* value = devtool_agent->GetLepusValueFromTemplateData();
  if (value != nullptr) {
    std::string template_data_str = lynx::lepus::lepusValueToString(*value);
    result["content"] = template_data_str;
  }

  response["result"] = result;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorTemplateAgent::GetTemplateConfigInfo(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value result(Json::ValueType::objectValue);

  std::string config_str = devtool_agent->GetTemplateConfigInfo();
  response["result"] = config_str;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorTemplateAgent::GetTemplateApiInfo(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value result(Json::ValueType::objectValue);
  lynx::lepus::Value* default_processor_value =
      devtool_agent->GetTemplateApiDefaultProcessor();
  result["useDefault"] = (default_processor_value != nullptr &&
                          default_processor_value->IsClosure());

  std::unordered_map<std::string, lynx::lepus::Value>* processor_map =
      devtool_agent->GetTemplateApiProcessorMap();
  if (processor_map != nullptr && !processor_map->empty()) {
    Json::Value keys(Json::ValueType::arrayValue);
    for (auto& element : *processor_map) {
      keys.append(element.first);
    }
    result["processMapKeys"] = keys;
  }

  response["result"] = result;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorTemplateAgent::CallMethod(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& content) {
  std::string method = content["method"].asString();
  auto iter = functions_map_.find(method);
  if (iter != functions_map_.end()) {
    (this->*(iter->second))(devtool_agent, content);
  } else {
    Json::Value res;
    res["error"] = Json::ValueType::objectValue;
    res["error"]["code"] = kLynxInspectorErrorCode;
    res["error"]["message"] = "Not implemented: " + method;
    res["id"] = content["id"].asInt64();
    devtool_agent->SendResponseAsync(res);
  }
}

}  // namespace devtool
}  // namespace lynxdev
