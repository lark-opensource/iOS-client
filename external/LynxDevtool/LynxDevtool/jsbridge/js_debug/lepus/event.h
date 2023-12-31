// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LEPUS_EVENT_H
#define LEPUS_EVENT_H
#include <iostream>
#include <list>
#include <string>
#include <unordered_map>
#include <utility>

#include "jsbridge/js_debug/lepus/debug_protocols.h"

namespace lynx {
namespace lepus {

class Event;
class Breakpoint;
// event type
enum EventType {
  enable = 10000,
  stopAtEntry,
  getScriptSource,
  setBreakpointsActive,
  setBreakpointByUrl,
  getPossibleBreakpoints,
  stepOver,
  stepInto,
  stepOut,
  resume,
  getProperties,
  removeBreakpoint,
  disable,
  undefined
};

// base class for debug event and breakpoint event associated with breakpoints
// initialize with event id
class EventData {
  friend class Event;

 public:
  explicit EventData(int32_t event_id = -1) : event_id_(event_id) {}
  virtual ~EventData() = default;

  // use protocol message to construct specific protocol
  virtual void InitProtocol(debugProtocols::ProtocolType protoType,
                            EventType &type,
                            std::unique_ptr<rapidjson::Document> dom) {}
  // get the protocol
  virtual debugProtocols::BaseProtocol *GetProtocol() = 0;
  // get event id
  virtual int32_t GetEventId() const { return event_id_; }

  EventData(const EventData &) = delete;
  const EventData &operator=(const EventData &) = delete;

 protected:
  int32_t event_id_;
};

// debug event data
class DebugEventData : public EventData {
 public:
  explicit DebugEventData(int32_t event_id) : EventData(event_id) {}
  ~DebugEventData() override = default;

  // use protocol message to construct specific protocol
  void InitProtocol(debugProtocols::ProtocolType protocolType, EventType &type,
                    std::unique_ptr<rapidjson::Document> dom) override;
  int32_t GetEventId() const override { return event_id_; }
  debugProtocols::BaseProtocol *GetProtocol() override {
    return protocol_.get();
  }

 private:
  std::unique_ptr<debugProtocols::BaseProtocol> protocol_;
};

// breakpoint event data
class BreakpointEventData : public EventData {
 public:
  BreakpointEventData(int32_t breakpoint_id) : EventData(breakpoint_id) {}
  ~BreakpointEventData() override = default;

  void InitProtocol(debugProtocols::ProtocolType protoType, EventType &type,
                    std::unique_ptr<rapidjson::Document> dom) override;

  int32_t GetEventId() const override { return event_id_; }

  debugProtocols::BaseProtocol *GetProtocol() override {
    return protocol_.get();
  }

  BreakpointEventData(const BreakpointEventData &) = delete;
  BreakpointEventData &operator=(const BreakpointEventData &) = delete;

 private:
  std::unique_ptr<debugProtocols::BaseProtocol> protocol_;
};

class Event {
  friend class EventData;

 public:
  Event(EventType event_type, EventData *data = nullptr);
  Event(EventType event_type, std::shared_ptr<EventData> event_data_sp);
  ~Event();
  // get event data
  EventData *GetData() { return event_data_.get(); }
  // use protocol message to init a debug event
  void InitData(const std::string &msg);
  // if there is a Debugger.disable to end this debug process
  bool IsTerminal();
  // get event id
  int32_t GetEventId() { return event_data_->GetEventId(); }
  // get event type
  static EventType GetEventType(const std::string &method);
  uint32_t GetEventType() const { return event_type_; }

  Event &operator=(const Event &) = delete;
  Event() = delete;

 private:
  EventType event_type_;                   // The bit describing this event
  std::shared_ptr<EventData> event_data_;  // User specific data for this event
};

}  // namespace lepus
}  // namespace lynx

#endif  // LEPUS_EVENT_H
