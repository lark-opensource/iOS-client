// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_WEBGL_WEBGL_CONTEXT_OBJECT_H_
#define CANVAS_WEBGL_WEBGL_CONTEXT_OBJECT_H_

#include "canvas/util/js_object_pair.h"
#include "canvas/webgl/canvas_resource_provider_3d.h"
#include "canvas/webgl/webgl_object_ng.h"

namespace lynx {
namespace canvas {
class WebGLContextObject : public WebGLObjectNG {
 public:
  bool Validate(const WebGLRenderingContext*) const final;

 protected:
  explicit WebGLContextObject(WebGLRenderingContext* context);

  CommandRecorder* GetRecorder() const final;

  std::shared_ptr<CanvasResourceProvider3D> resource_provider_;

 private:
  size_t context_id_;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_WEBGL_WEBGL_CONTEXT_OBJECT_H_
