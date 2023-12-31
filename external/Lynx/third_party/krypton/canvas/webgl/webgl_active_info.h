// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_WEBGL_WEBGL_ACTIVE_INFO_H_
#define CANVAS_WEBGL_WEBGL_ACTIVE_INFO_H_

#include "jsbridge/napi/base.h"

namespace lynx {
namespace canvas {

using piper::BridgeBase;
using piper::ImplBase;

class WebGLActiveInfo : public ImplBase {
 public:
  WebGLActiveInfo();
  double GetSize();
  double GetType();
  const std::string& GetName();

 public:
  double size_;
  double type_;
  std::string name_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_WEBGL_WEBGL_ACTIVE_INFO_H_
