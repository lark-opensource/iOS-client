// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef CANVAS_GPU_GL_GLOBAL_DEVICE_ATTRIBUTES_H_
#define CANVAS_GPU_GL_GLOBAL_DEVICE_ATTRIBUTES_H_

#include <mutex>

#include "canvas/gpu/gl_device_attributes.h"

namespace lynx {
namespace canvas {
class GLGlobalDeviceAttributes final {
 public:
  static GLGlobalDeviceAttributes &Instance();

  bool Inited();
  bool Valid();
  bool InitedButFailed();

  GLDeviceAttributes GetDeviceAttributes();
  const GLDeviceAttributes &GetDeviceAttributesRef();

  // make sure called inner valid gl context
  bool InitOnGPU();

 private:
  GLGlobalDeviceAttributes();

  std::mutex attributes_mutex_;
  GLDeviceAttributes device_attributes_;
  bool inited_;
  bool valid_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_GPU_GL_GLOBAL_DEVICE_ATTRIBUTES_H_
