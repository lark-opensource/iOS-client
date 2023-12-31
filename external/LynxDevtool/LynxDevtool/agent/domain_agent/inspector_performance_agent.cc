// Copyright 2021 The Lynx Authors. All rights reserved.

#include "agent/domain_agent/inspector_performance_agent.h"

#include "agent/devtool_agent_base.h"
#include "base/log/logging.h"
#include "base/perf_collector.h"

namespace lynxdev {
namespace devtool {

using lynx::base::PerfCollector;

InspectorPerformanceAgent::InspectorPerformanceAgent() {
  functions_map_["Performance.enable"] = &InspectorPerformanceAgent::Enable;
  functions_map_["Performance.disable"] = &InspectorPerformanceAgent::Disable;
  functions_map_["Performance.getMetrics"] =
      &InspectorPerformanceAgent::getMetrics;
  functions_map_["Performance.getAllTimingInfo"] =
      &InspectorPerformanceAgent::getAllTimingInfo;
}

InspectorPerformanceAgent::~InspectorPerformanceAgent() = default;

void InspectorPerformanceAgent::Enable(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
  ready_ = true;
}

void InspectorPerformanceAgent::Disable(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  ready_ = false;
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorPerformanceAgent::getMetrics(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  // get data from perf_collector.h
  if (ready_) {
    // get first perf container from lynx base
    PerfCollector::PerfMap* perfMapPtr = devtool_agent->GetFirstPerfContainer();

    // find max key in perfMap, let it be the current page trace_id
    int trace_id = -1;
    for (auto& item : *perfMapPtr) {
      trace_id = (trace_id > item.first ? trace_id : item.first);
    }
    if ((*perfMapPtr).find(trace_id) != (*perfMapPtr).end()) {
      std::unordered_map<int, double> currentPageTrace =
          (*perfMapPtr).at(trace_id);
      // construct Performance.metrics [name:string, value:number]
      Json::Value content(Json::ValueType::arrayValue);
      for (auto& perfCase : currentPageTrace) {
        Json::Value metric(Json::ValueType::objectValue);
        metric["name"] = PerfCollector::ToString(
            static_cast<PerfCollector::Perf>(perfCase.first));
        metric["value"] = perfCase.second;
        content.append(metric);
      }
      Json::Value response(Json::ValueType::objectValue);
      response["result"] = content;
      response["id"] = message["id"].asInt64();
      devtool_agent->SendResponseAsync(response);
      return;
    }
  }
  Json::Value res;
  res["error"] = Json::ValueType::objectValue;
  res["error"]["code"] = kLynxInspectorErrorCode;
  res["error"]["message"] = "performance not enabled";
  res["id"] = message["id"].asInt64();
}

void InspectorPerformanceAgent::getAllTimingInfo(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  response["result"] = devtool_agent->GetAllTimingInfo();
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponse(response.toStyledString());
  return;
}

void InspectorPerformanceAgent::CallMethod(
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
