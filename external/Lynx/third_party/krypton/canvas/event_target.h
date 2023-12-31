// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_EVENT_TARGET_H_
#define CANVAS_EVENT_TARGET_H_

#include "jsbridge/napi/base.h"

namespace lynx {
namespace canvas {

using piper::BridgeBase;
using piper::ImplBase;

class Event;

class EventTarget : public ImplBase {
 public:
  static std::unique_ptr<EventTarget> Create() {
    return std::unique_ptr<EventTarget>(new EventTarget());
  }
  EventTarget() {}
  void OnWrapped() override {}
  virtual void AddEventListener(const std::string& type, Napi::Object listener,
                                bool capture = false);
  virtual void RemoveEventListener(const std::string& type,
                                   Napi::Object listener, bool capture = false);
  virtual bool DispatchEvent(Event* event);
  virtual void TriggerEventListeners(const std::string& type,
                                     const Napi::Value& payload);
  // custom function, used to record if has event listeners in js side
  virtual void ResetEventListenerStatus(const std::string& type,
                                        bool hasListeners);
  virtual bool GetEventListenerStatus(const std::string& type);

 private:
  std::vector<std::string> listen_events_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_EVENT_TARGET_H_
