// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_EVENT_H_
#define CANVAS_EVENT_H_

#include "canvas/event_target.h"
#include "jsbridge/napi/base.h"

namespace lynx {
namespace canvas {

using piper::BridgeBase;
using piper::ImplBase;

class Event : public ImplBase {
 public:
  static Event* Create(const std::string& type, EventTarget* target) {
    return new Event(type, target);
  }

  Event(const std::string& type, EventTarget* target)
      : type_(type), target_(target) {}

  const std::string& GetType() { return type_; }
  EventTarget* GetTarget() { return target_; }
  float GetX() { return x_; }
  float GetY() { return y_; }

 private:
  std::string type_;
  EventTarget* target_ = nullptr;
  float x_ = 0.0;
  float y_ = 0.0;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_EVENT_H_
