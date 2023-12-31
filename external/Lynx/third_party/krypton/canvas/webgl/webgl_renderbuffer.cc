// Copyright 2021 The Lynx Authors. All rights reserved.

#include "webgl_renderbuffer.h"

#include "canvas/gpu/gl/gl_api.h"

namespace lynx {
namespace canvas {

WebGLRenderbuffer::WebGLRenderbuffer(WebGLRenderingContext *context)
    : WebGLContextObject(context) {
  related_id_.Build(GetRecorder());
  // runnable
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) {
      DCHECK(content_);
      uint32_t v = 0;
      GL::GenRenderbuffers(1, &v);
      content_->Set(v);
    }
    PuppetContent<uint32_t> *content_ = nullptr;
  };
  auto cmd = GetRecorder()->Alloc<Runnable>();
  cmd->content_ = related_id_.Get();
}

bool WebGLRenderbuffer::HasObject() const { return has_gl_object_pending_; }

void WebGLRenderbuffer::DeleteObjectImpl(CommandRecorder *recorder) {
  has_gl_object_pending_ = false;

  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) {
      DCHECK(content_);
      GL::DeleteRenderbuffers(1, &(content_->Get()));
    }
    PuppetContent<uint32_t> *content_ = nullptr;
  };
  auto cmd = GetRecorder()->Alloc<Runnable>();
  cmd->content_ = related_id_.Get();
}

}  // namespace canvas
}  // namespace lynx
