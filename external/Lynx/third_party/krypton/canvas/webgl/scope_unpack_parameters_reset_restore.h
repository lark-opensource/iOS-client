// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_WEBGL_SCOPE_UNPACK_PARAMETERS_RESET_RESTORE_H_
#define CANVAS_WEBGL_SCOPE_UNPACK_PARAMETERS_RESET_RESTORE_H_

#include "webgl_rendering_context.h"

namespace lynx {
namespace canvas {
class ScopedUnpackParametersResetRestore {
 public:
  explicit ScopedUnpackParametersResetRestore(WebGLRenderingContext* context,
                                              bool enabled = true);

  ~ScopedUnpackParametersResetRestore();

 private:
  WebGLRenderingContext* context_;
  bool enabled_;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_WEBGL_SCOPE_UNPACK_PARAMETERS_RESET_RESTORE_H_
