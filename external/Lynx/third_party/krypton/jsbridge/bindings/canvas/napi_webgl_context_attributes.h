// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_dictionary.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef JSBRIDGE_BINDINGS_CANVAS_NAPI_WEBGL_CONTEXT_ATTRIBUTES_H_
#define JSBRIDGE_BINDINGS_CANVAS_NAPI_WEBGL_CONTEXT_ATTRIBUTES_H_

#include "base/log/logging.h"
#include "jsbridge/napi/native_value_traits.h"

namespace lynx {
namespace canvas {

class WebGLContextAttributes {
 public:
  static std::unique_ptr<WebGLContextAttributes> ToImpl(const Napi::Value&);

  Napi::Object ToJsObject(Napi::Env);

  bool hasAlpha() { return has_alpha_; }
  bool alpha() {
    return alpha_;
  }

  bool hasAntialias() { return has_antialias_; }
  bool antialias() {
    return antialias_;
  }

  bool hasDepth() { return has_depth_; }
  bool depth() {
    return depth_;
  }

  bool hasDesynchronized() { return has_desynchronized_; }
  bool desynchronized() {
    return desynchronized_;
  }

  bool hasEnableMSAA() { return has_enableMSAA_; }
  bool enableMSAA() {
    return enableMSAA_;
  }

  bool hasFailIfMajorPerformanceCaveat() { return has_failIfMajorPerformanceCaveat_; }
  bool failIfMajorPerformanceCaveat() {
    return failIfMajorPerformanceCaveat_;
  }

  bool hasPremultipliedAlpha() { return has_premultipliedAlpha_; }
  bool premultipliedAlpha() {
    return premultipliedAlpha_;
  }

  bool hasPreserveDrawingBuffer() { return has_preserveDrawingBuffer_; }
  bool preserveDrawingBuffer() {
    return preserveDrawingBuffer_;
  }

  bool hasStencil() { return has_stencil_; }
  bool stencil() {
    return stencil_;
  }

  // Dictionary name
  static constexpr const char* DictionaryName() {
    return "WebGLContextAttributes";
  }

 private:
  bool has_alpha_ = true;
  bool has_antialias_ = true;
  bool has_depth_ = true;
  bool has_desynchronized_ = true;
  bool has_enableMSAA_ = true;
  bool has_failIfMajorPerformanceCaveat_ = true;
  bool has_premultipliedAlpha_ = true;
  bool has_preserveDrawingBuffer_ = true;
  bool has_stencil_ = true;

  bool alpha_ = true;
  bool antialias_ = false;
  bool depth_ = true;
  bool desynchronized_ = false;
  bool enableMSAA_ = false;
  bool failIfMajorPerformanceCaveat_ = false;
  bool premultipliedAlpha_ = true;
  bool preserveDrawingBuffer_ = false;
  bool stencil_ = false;
};

}  // namespace canvas
}  // namespace lynx

#endif  // JSBRIDGE_BINDINGS_CANVAS_NAPI_WEBGL_CONTEXT_ATTRIBUTES_H_
