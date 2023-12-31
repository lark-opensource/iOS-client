// Copyright 2021 The Lynx Authors. All rights reserved.

#include "webgl_context_object.h"

#include "canvas/webgl/webgl_rendering_context.h"

namespace lynx {
namespace canvas {

WebGLContextObject::WebGLContextObject(WebGLRenderingContext* context)
    : resource_provider_(context->ResourceProvider()),
      context_id_(context->UniqueID()) {
  DCHECK(resource_provider_);
}

CommandRecorder* WebGLContextObject::GetRecorder() const {
  return resource_provider_->GetRecorder();
}

bool WebGLContextObject::Validate(const WebGLRenderingContext* context) const {
  return context->UniqueID() == context_id_;
}
}  // namespace canvas
}  // namespace lynx
