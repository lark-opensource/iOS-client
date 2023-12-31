// Copyright 2021 The Lynx Authors. All rights reserved.

#include "es_state.h"

#include "canvas/base/log.h"

namespace lynx {
namespace canvas {
void Estate::Save() {
  enabled_.Save();
  buffer_.Save();
  misc_.Save();
  pixel_store_.Save();
  stencil_.Save();
  texture_.Save();
  tfo_.Save();
  uniform_binding_point_.Save();
  // TODO query releated
  DCHECK(glGetError() == GL_NO_ERROR);
}

void Estate::SetCurrent() {
  enabled_.SetCurrent();
  buffer_.SetCurrent();
  misc_.SetCurrent();
  pixel_store_.SetCurrent();
  stencil_.SetCurrent();
  texture_.SetCurrent();
  tfo_.SetCurrent();
  uniform_binding_point_.SetCurrent();
  DCHECK(glGetError() == GL_NO_ERROR);
}

std::unique_ptr<Estate> Estate::Clone() const {
  auto context = std::make_unique<Estate>();

  context->enabled_ = enabled_;
  context->buffer_ = buffer_;
  context->misc_ = misc_;
  context->pixel_store_ = pixel_store_;
  context->stencil_ = stencil_;
  context->texture_ = texture_;
  context->tfo_ = tfo_;
  context->uniform_binding_point_ = uniform_binding_point_;
  return context;
}
}  // namespace canvas
}  // namespace lynx
