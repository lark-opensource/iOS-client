// Copyright 2021 The Lynx Authors. All rights reserved.

#include "scope_unpack_parameters_reset_restore.h"

namespace lynx {
namespace canvas {

ScopedUnpackParametersResetRestore::ScopedUnpackParametersResetRestore(
    WebGLRenderingContext *context, bool enabled)
    : context_(context), enabled_(enabled) {
  if (enabled) context_->ResetUnpackParameters();
}

ScopedUnpackParametersResetRestore::~ScopedUnpackParametersResetRestore() {
  if (enabled_) {
    context_->RestoreUnpackParameters();
  }
}

}  // namespace canvas
}  // namespace lynx
