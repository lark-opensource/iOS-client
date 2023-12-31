// Copyright 2022 The Lynx Authors. All rights reserved.

#include "canvas/webgl/webgl_rendering_context.h"

namespace lynx {
namespace canvas {

/// In order to support the morph animation requirements of sar,
/// the texImage3d interface is supported in the form of a webgl extension.
/// The interface can only guarantee the normal use of sar for the time being,
/// and cannot pass the webgl test, which will be completed later.
void WebGLRenderingContext::TexImage3D(GLenum target, GLint level,
                                       GLenum internalformat, GLsizei width,
                                       GLsizei height, GLsizei depth,
                                       GLint border, GLenum format, GLenum type,
                                       ArrayBufferView pixels) {
  DCHECK(Recorder());
  struct Runnable {
    void Run(command_buffer::RunnableBuffer *) {
      GL::TexImage3D(target_, level_, internalformat_, width_, height_, depth_,
                     border_, format_, type_, pixels_->Data());
    }
    uint32_t target_, internalformat_, format_, type_;
    int32_t level_, width_, height_, depth_, border_;
    std::unique_ptr<DataHolder> pixels_;
  };
  auto cmd = Recorder()->Alloc<Runnable>();
  cmd->target_ = target;
  cmd->level_ = level;
  cmd->internalformat_ = internalformat;
  cmd->width_ = width;
  cmd->height_ = height;
  cmd->depth_ = depth;
  cmd->border_ = border;
  cmd->format_ = format;
  cmd->type_ = type;
  cmd->pixels_ = DataHolder::MakeWithCopy(pixels.Data(), pixels.ByteLength());
}

}  // namespace canvas
}  // namespace lynx
