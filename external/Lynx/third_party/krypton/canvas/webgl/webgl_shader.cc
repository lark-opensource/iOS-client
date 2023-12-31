// Copyright 2021 The Lynx Authors. All rights reserved.

#include "webgl_shader.h"

#include "canvas/gpu/command_buffer/puppet.h"
#include "canvas/gpu/gl/gl_api.h"

namespace lynx {
namespace canvas {

WebGLShader::WebGLShader(WebGLRenderingContext *context, GLenum type)
    : WebGLContextObject(context), has_gl_object_pending_(true) {
  related_id().Build(GetRecorder());
  SetType(type);

  // commit command
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) {
      DCHECK(content_);
      content_->Set(GL::CreateShader(type_));
    }
    PuppetContent<uint32_t> *content_ = nullptr;
    uint32_t type_;
  };
  auto cmd = GetRecorder()->Alloc<Runnable>();
  cmd->content_ = related_id().Get();
  cmd->type_ = type;
}

void WebGLShader::DeleteObjectImpl(CommandRecorder *recorder) {
  has_gl_object_pending_ = false;

  struct Runnable {
    void Run(command_buffer::RunnableBuffer *buffer) {
      GL::DeleteShader(content_->Get());
    }
    PuppetContent<uint32_t> *content_ = nullptr;
  };
  auto cmd = recorder->Alloc<Runnable>();
  cmd->content_ = related_id_.Get();
}

bool WebGLShader::HasObject() const { return has_gl_object_pending_; }

}  // namespace canvas
}  // namespace lynx
