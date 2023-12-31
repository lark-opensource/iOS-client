// Copyright 2021 The Lynx Authors. All rights reserved.

#include "webgl_active_info.h"

namespace lynx {
namespace canvas {

WebGLActiveInfo::WebGLActiveInfo() {}

double WebGLActiveInfo::GetSize() { return size_; }

double WebGLActiveInfo::GetType() { return type_; }

const std::string& WebGLActiveInfo::GetName() { return name_; }

}  // namespace canvas
}  // namespace lynx
