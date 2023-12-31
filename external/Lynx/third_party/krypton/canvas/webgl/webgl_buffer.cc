// Copyright 2021 The Lynx Authors. All rights reserved.

#include "webgl_buffer.h"

#include "canvas/gpu/gl/gl_api.h"

namespace lynx {
namespace canvas {

WebGLBuffer::WebGLBuffer(WebGLRenderingContext *context)
    : WebGLContextObject(context) {
  related_id_.Build(GetRecorder());

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) {
      DCHECK(content_);
      uint32_t _id = 0;
      GL::GenBuffers(1, &_id);
      content_->Set(_id);
    }
    PuppetContent<uint32_t> *content_ = nullptr;
  };
  auto cmd = GetRecorder()->Alloc<Runnable>();
  cmd->content_ = related_id_.Get();
}

bool WebGLBuffer::HasObject() const { return has_gl_object_pending_; }

void WebGLBuffer::DeleteObjectImpl(CommandRecorder *recorder) {
  has_gl_object_pending_ = false;

  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) {
      DCHECK(content_);
      GL::DeleteBuffers(1, &(content_->Get()));
    }
    PuppetContent<uint32_t> *content_ = nullptr;
  };
  auto cmd = GetRecorder()->Alloc<Runnable>();
  cmd->content_ = related_id_.Get();
}

}  // namespace canvas
}  // namespace lynx
