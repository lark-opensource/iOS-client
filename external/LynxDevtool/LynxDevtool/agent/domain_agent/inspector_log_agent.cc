// Copyright 2019 The Lynx Authors. All rights reserved.

#include "agent/domain_agent/inspector_log_agent.h"

#include "agent/devtool_agent_base.h"
#include "jsbridge/lynx_console_helper.h"

#define MAX_CACHE_LOG 500

namespace {

const std::string LOG_VERBOSE = "verbose";
const std::string LOG_INFO = "info";
const std::string LOG_WARNING = "warning";
const std::string LOG_ERROR = "error";

// There are some differences between the definition of level in logging.h and
// lynx_console.cc, need to use the same definition as lynx_console.cc here.
// （eg: 5 defined as LOG_FATAL in logging.h but CONSOLE_LOG_ALOG in
// lynx_console.cc)
static std::string MessageLogLevel(int level) {
  switch (level) {
    case lynx::piper::CONSOLE_LOG_VERBOSE:
      return LOG_VERBOSE;
    case lynx::piper::CONSOLE_LOG_WARNING:
      return LOG_WARNING;
    case lynx::piper::CONSOLE_LOG_ERROR:
      return LOG_ERROR;
    default:
      return LOG_INFO;
      break;
  }
}

}  // namespace

namespace lynxdev {
namespace devtool {

InspectorLogAgent::InspectorLogAgent() {
  functions_map_["Log.enable"] = &InspectorLogAgent::Enable;
  functions_map_["Log.entryAdded"] = &InspectorLogAgent::Enable;
  functions_map_["Log.disable"] = &InspectorLogAgent::Disable;
}

InspectorLogAgent::~InspectorLogAgent() = default;

void InspectorLogAgent::Enable(std::shared_ptr<DevToolAgentBase> devtool_agent,
                               const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  ready_ = true;
  FireCacheLogs(devtool_agent);
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorLogAgent::Disable(std::shared_ptr<DevToolAgentBase> devtool_agent,
                                const Json::Value& message) {
  Json::Value response(Json::ValueType::objectValue);
  Json::Value content(Json::ValueType::objectValue);
  ready_ = false;
  FireCacheLogs(devtool_agent);
  response["result"] = content;
  response["id"] = message["id"].asInt64();
  devtool_agent->SendResponseAsync(response);
}

void InspectorLogAgent::StartViolationsReport(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& params) {
  Json::Value content = Json::Value(Json::ValueType::objectValue);
}

void InspectorLogAgent::CallMethod(
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

void InspectorLogAgent::FireCacheLogs(
    std::shared_ptr<DevToolAgentBase> devtool_agent) {
  for (const auto& log : logMessageQueue_) {
    PostLog(devtool_agent, log);
  }
  logMessageQueue_.clear();
}

void InspectorLogAgent::SendLog(std::shared_ptr<DevToolAgentBase> devtool_agent,
                                const lynx::piper::ConsoleMessage& message) {
  if (ready_) {
    PostLog(devtool_agent, message);
  } else {
    if (logMessageQueue_.size() >= MAX_CACHE_LOG) {
      logMessageQueue_.erase(logMessageQueue_.begin());
    }
    logMessageQueue_.push_back(message);
  }
}

void InspectorLogAgent::PostLog(std::shared_ptr<DevToolAgentBase> devtool_agent,
                                const lynx::piper::ConsoleMessage& message) {
  Json::Value content;
  Json::Value params;
  Json::Value msg;
  msg["source"] = "javascript";
  msg["level"] = MessageLogLevel(message.level_);
  msg["text"] = message.text_;
  msg["timestamp"] = message.timestamp_;
  params["entry"] = msg;
  content["method"] = "Log.entryAdded";
  content["params"] = params;
  devtool_agent->SendResponseAsync(content);
}

}  // namespace devtool
}  // namespace lynxdev
