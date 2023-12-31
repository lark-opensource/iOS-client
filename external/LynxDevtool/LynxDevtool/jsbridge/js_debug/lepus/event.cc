// Copyright 2019 The Lynx Authors. All rights reserved.
#include "event.h"

#include <utility>

namespace lynx {
namespace lepus {

Event::Event(EventType event_type, EventData *data)
    : event_type_(event_type), event_data_(data) {}
Event::Event(EventType event_type, std::shared_ptr<EventData> event_data_sp)
    : event_type_(event_type), event_data_(std::move(event_data_sp)) {}
Event::~Event() = default;

// return if there is a Debugger.disable
bool Event::IsTerminal() {
  if (event_type_ == EventType::resume &&
      event_data_->GetProtocol()->GetProtoType() ==
          debugProtocols::ProtocolType::Debug) {
    return true;
  }
  if (event_type_ == EventType::disable &&
      event_data_->GetProtocol()->GetProtoType() ==
          debugProtocols::ProtocolType::Debug) {
    return true;
  }
  return false;
}

void Event::InitData(const std::string &msg) {
  std::unique_ptr<rapidjson::Document> dom =
      std::make_unique<rapidjson::Document>();
  std::string protocol_method;
  debugProtocols::ProtocolType protocol_type =
      debugProtocols::ProtocolType::Debug;

  dom->Parse(msg.c_str());

  // use protocol message to get protocol type
  if (dom->HasMember("method")) {
    protocol_method = (*dom)["method"].GetString();
    auto dot_index = protocol_method.find('.');
    protocol_type = protocol_method.substr(0, dot_index) == "Runtime"
                        ? debugProtocols::ProtocolType::Runtime
                        : debugProtocols::ProtocolType::Debug;
    protocol_method = protocol_method.substr(dot_index + 1);
  }

  event_type_ = GetEventType(protocol_method);

  // get event data
  if (event_type_ == setBreakpointByUrl ||
      event_type_ == setBreakpointsActive ||
      event_type_ == getPossibleBreakpoints) {
    event_data_ = std::make_unique<BreakpointEventData>((*dom)["id"].GetInt());
  } else {
    event_data_ = std::make_unique<DebugEventData>((*dom)["id"].GetInt());
  }
  // use event data to init specific protocol
  event_data_->InitProtocol(protocol_type, event_type_, std::move(dom));
}

EventType Event::GetEventType(const std::string &method) {
  if (method == "enable") {
    return enable;
  } else if (method == "getScriptSource") {
    return getScriptSource;
  } else if (method == "setBreakpointsActive") {
    return setBreakpointsActive;
  } else if (method == "setBreakpointByUrl") {
    return setBreakpointByUrl;
  } else if (method == "stepOver") {
    return stepOver;
  } else if (method == "stepInto") {
    return stepInto;
  } else if (method == "stepOut") {
    return stepOut;
  } else if (method == "resume") {
    return resume;
  } else if (method == "getProperties") {
    return getProperties;
  } else if (method == "removeBreakpoint") {
    return removeBreakpoint;
  } else if (method == "getPossibleBreakpoints") {
    return getPossibleBreakpoints;
  } else if (method == "disable") {
    return disable;
  } else if (method == "stopAtEntry") {
    return stopAtEntry;
  } else {
    return undefined;
  }
}

void DebugEventData::InitProtocol(debugProtocols::ProtocolType protocolType,
                                  EventType &type,
                                  std::unique_ptr<rapidjson::Document> dom) {
  auto parameter = dom->FindMember("params");
  rapidjson::Value pms;
  if (parameter != dom->MemberEnd()) {
    pms = (*dom)["params"].GetObject();
  } else {
    rapidjson::Document param_null;
    param_null.SetObject();
    pms = param_null.GetObject();
  }
  switch (type) {
    case enable: {
      if (protocolType == debugProtocols::ProtocolType::Debug) {
        protocol_ = std::make_unique<debugProtocols::Enable>(
            HAS_INT_MEMBER(pms, maxScriptsCacheSize));
      } else {
        protocol_ = std::make_unique<debugProtocols::REnable>();
      }
      break;
    }
    case getScriptSource: {
      protocol_ = std::make_unique<debugProtocols::GetScriptSource>(
          pms["scriptId"].GetString());
      break;
    }
    case getProperties: {
      protocol_ = std::make_unique<debugProtocols::GetProperties>(
          pms["objectId"].GetString());
      break;
    }
    case stepInto:
      protocol_ = std::make_unique<debugProtocols::StepInto>();
      break;
    case stepOut:
      protocol_ = std::make_unique<debugProtocols::StepOut>();
      break;
    case stepOver:
      protocol_ = std::make_unique<debugProtocols::StepOver>();
      break;
    case resume:
      protocol_ = std::make_unique<debugProtocols::Resume>();
      break;
    case removeBreakpoint:
      protocol_ = std::make_unique<debugProtocols::RemoveBreakpoint>(
          pms["breakpointId"].GetString());
      break;
    case disable: {
      if (protocolType == debugProtocols::ProtocolType::Debug) {
        protocol_ = std::make_unique<debugProtocols::Disable>();
      } else {
        protocol_ = std::make_unique<debugProtocols::RDisable>();
      }
      break;
    }
    case stopAtEntry:
      break;
    default:
      break;
  }
}

void BreakpointEventData::InitProtocol(
    debugProtocols::ProtocolType protoType, EventType &type,
    std::unique_ptr<rapidjson::Document> dom) {
  auto parameters = dom->FindMember("params");
  rapidjson::Value pms;
  if (parameters != dom->MemberEnd()) {
    pms = (*dom)["params"].GetObject();
  } else {
    rapidjson::Document param_null;
    param_null.SetObject();
    pms = param_null.GetObject();
  }
  switch (type) {
    case setBreakpointsActive: {
      protocol_ = std::make_unique<debugProtocols::SetBreakpointsActive>(
          pms["active"].GetBool());
      break;
    }
    case setBreakpointByUrl: {
      protocol_ = std::make_unique<debugProtocols::SetBreakpointByUrl>(
          HAS_INT_MEMBER(pms, lineNumber), HAS_STR_MEMBER(pms, url),
          HAS_STR_MEMBER(pms, urlRegex), HAS_STR_MEMBER(pms, scriptHash),
          HAS_INT_MEMBER(pms, columnNumber), HAS_STR_MEMBER(pms, condition));
      break;
    }
    case getPossibleBreakpoints: {
      rapidjson::Value start = pms["start"].GetObject();
      rapidjson::Value end =
          pms.HasMember("end") ? pms["end"].GetObject()
                               : rapidjson::Value(rapidjson::Type::kObjectType);
      debugProtocols::Location start_location(
          "0", HAS_INT_MEMBER(start, lineNumber),
          HAS_INT_MEMBER(start, columnNumber));
      debugProtocols::Location end_location("0",
                                            HAS_INT_MEMBER(end, lineNumber),
                                            HAS_INT_MEMBER(end, columnNumber));
      protocol_ = std::make_unique<debugProtocols::GetPossibleBreakpoints>(
          start_location, end_location,
          HAS_BOOL_MEMBER(pms, restrictToFunction));
      break;
    }
    default:
      break;
  }
}

}  // namespace lepus
}  // namespace lynx
