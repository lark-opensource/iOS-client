// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_BASE_INPUT_MOUSE_EVENT_H
#define LYNX_INSPECTOR_BASE_INPUT_MOUSE_EVENT_H

#include <string>

namespace lynxdev {
namespace devtool {
struct MouseEvent {
  std::string type_;
  int x_;
  int y_;
  std::string button_;
  float delta_x_;
  float delta_y_;
  int modifiers_;
  int clickcount_;
};

}  // namespace devtool
}  // namespace lynxdev

#endif  // LYNX_INSPECTOR_BASE_INPUT_MOUSE_EVENT_H
