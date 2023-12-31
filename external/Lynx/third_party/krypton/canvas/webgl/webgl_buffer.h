// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_WEBGL_WEBGL_BUFFER_H_
#define CANVAS_WEBGL_WEBGL_BUFFER_H_

#include "canvas/gpu/command_buffer/puppet.h"
#include "canvas/gpu/gl_constants.h"
#include "canvas/webgl/webgl_context_object.h"

namespace lynx {
namespace canvas {

class WebGLBuffer : public WebGLContextObject {
 public:
  WebGLBuffer(WebGLRenderingContext *context);
  bool HasObject() const override;
  bool HasEverBeenBound() const { return initial_target_; }

 protected:
  void DeleteObjectImpl(CommandRecorder *recorder) override;

 public:
  Puppet<uint32_t> related_id_;
  bool has_gl_object_pending_ = true;
  GLenum initial_target_ = KR_GL_NONE;
  GLsizeiptr size_ = 0;
  GLenum usage_ = KR_GL_NONE;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_WEBGL_WEBGL_BUFFER_H_
