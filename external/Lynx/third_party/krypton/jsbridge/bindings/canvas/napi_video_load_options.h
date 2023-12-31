// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_dictionary.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef JSBRIDGE_BINDINGS_CANVAS_NAPI_VIDEO_LOAD_OPTIONS_H_
#define JSBRIDGE_BINDINGS_CANVAS_NAPI_VIDEO_LOAD_OPTIONS_H_

#include "base/log/logging.h"
#include "jsbridge/napi/native_value_traits.h"

namespace lynx {
namespace canvas {

class VideoLoadOptions {
 public:
  static std::unique_ptr<VideoLoadOptions> ToImpl(const Napi::Value&);

  Napi::Object ToJsObject(Napi::Env);

  bool hasUseCustomPlayer() { return has_useCustomPlayer_; }
  bool useCustomPlayer() {
    return useCustomPlayer_;
  }

  // Dictionary name
  static constexpr const char* DictionaryName() {
    return "VideoLoadOptions";
  }

 private:
  bool has_useCustomPlayer_ = true;

  bool useCustomPlayer_ = false;
};

}  // namespace canvas
}  // namespace lynx

#endif  // JSBRIDGE_BINDINGS_CANVAS_NAPI_VIDEO_LOAD_OPTIONS_H_
