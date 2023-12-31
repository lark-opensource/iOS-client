// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_dictionary.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef JSBRIDGE_BINDINGS_CANVAS_NAPI_MEDIA_RECORDER_CONFIG_H_
#define JSBRIDGE_BINDINGS_CANVAS_NAPI_MEDIA_RECORDER_CONFIG_H_

#include "base/log/logging.h"
#include "jsbridge/napi/native_value_traits.h"

namespace lynx {
namespace canvas {

class MediaRecorderConfig {
 public:
  static std::unique_ptr<MediaRecorderConfig> ToImpl(const Napi::Value&);

  Napi::Object ToJsObject(Napi::Env);

  bool hasAudio() { return has_audio_; }
  bool audio() {
    return audio_;
  }

  bool hasAutoPauseAndResume() { return has_autoPauseAndResume_; }
  bool autoPauseAndResume() {
    return autoPauseAndResume_;
  }

  bool hasBps() { return has_bps_; }
  uint32_t bps() {
    return bps_;
  }

  bool hasDeleteFilesOnDestroy() { return has_deleteFilesOnDestroy_; }
  bool deleteFilesOnDestroy() {
    return deleteFilesOnDestroy_;
  }

  bool hasDuration() { return has_duration_; }
  uint32_t duration() {
    return duration_;
  }

  bool hasFps() { return has_fps_; }
  uint32_t fps() {
    return fps_;
  }

  bool hasHeight() { return has_height_; }
  uint32_t height() {
    return height_;
  }

  bool hasWidth() { return has_width_; }
  uint32_t width() {
    return width_;
  }

  // Dictionary name
  static constexpr const char* DictionaryName() {
    return "MediaRecorderConfig";
  }

 private:
  bool has_audio_ = true;
  bool has_autoPauseAndResume_ = true;
  bool has_bps_ = false;
  bool has_deleteFilesOnDestroy_ = true;
  bool has_duration_ = true;
  bool has_fps_ = true;
  bool has_height_ = false;
  bool has_width_ = false;

  bool audio_ = false;
  bool autoPauseAndResume_ = true;
  uint32_t bps_;
  bool deleteFilesOnDestroy_ = true;
  uint32_t duration_ = 0u;
  uint32_t fps_ = 30u;
  uint32_t height_;
  uint32_t width_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // JSBRIDGE_BINDINGS_CANVAS_NAPI_MEDIA_RECORDER_CONFIG_H_
