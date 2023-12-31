// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_WEBGL_WEBGL_RENDERBUFFER_H_
#define CANVAS_WEBGL_WEBGL_RENDERBUFFER_H_

#include "canvas/gpu/command_buffer/puppet.h"
#include "canvas/gpu/gl_constants.h"
#include "webgl_context_object.h"

namespace lynx {
namespace canvas {

class WebGLRenderbuffer : public WebGLContextObject {
 public:
  WebGLRenderbuffer(WebGLRenderingContext *context);
  Puppet<uint32_t> related_id_;
  uint32_t width_ = 0, height_ = 0;
  uint32_t internal_format_ = KR_GL_NONE;
  uint32_t type_ = KR_GL_NONE;
  uint32_t samples_ = 0;
  void SetHasEverBeenBound() { has_ever_been_bound_ = true; }
  bool HasEverBeenBound() const { return has_ever_been_bound_; }
  bool HasObject() const override;

 protected:
  void DeleteObjectImpl(CommandRecorder *recorder) override;

 private:
  bool has_ever_been_bound_ = false;
  bool has_gl_object_pending_ = true;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_WEBGL_WEBGL_RENDERBUFFER_H_
