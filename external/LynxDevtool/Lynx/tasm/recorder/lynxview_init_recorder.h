// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_RECORDER_LYNXVIEW_INIT_RECORDER_H_
#define LYNX_TASM_RECORDER_LYNXVIEW_INIT_RECORDER_H_

#include "tasm/recorder/ark_base_recorder.h"
#include "third_party/rapidjson/document.h"

namespace lynx {
namespace tasm {
namespace recorder {

class LynxViewInitRecorder {
 public:
  // LynxView Initial Data
  static constexpr const char* kParamThreadStrategy = "threadStrategy";
  static constexpr const char* kParamEnableJSRuntime = "enableJSRuntime";
  static constexpr const char* kParamLayoutHeightMode = "layoutHeightMode";
  static constexpr const char* kParamLayoutWidthMode = "layoutWidthMode";
  static constexpr const char* kParamPreferredLayoutHeight =
      "preferredLayoutHeight";
  static constexpr const char* kParamPreferredLayoutWidth =
      "preferredLayoutWidth";
  static constexpr const char* kParamPreferredMaxLayoutHeight =
      "preferredMaxLayoutHeight";
  static constexpr const char* kParamPreferredMaxLayoutWidth =
      "preferredMaxLayoutWidth";

  static constexpr const char* kFuncInitialLynxView = "initialLynxView";
  static constexpr const char* kFuncUpdateViewPort = "updateViewPort";
  static constexpr const char* kFuncSetThreadStrategy = "setThreadStrategy";

  // Registered Native Module
  static constexpr const char* kParamModuleMethodLookup = "moduleMethodLookup";
  static constexpr const char* kParamModuleName = "moduleName";
  static constexpr const char* kParamModuleParamValue = "moduleParam";

  static constexpr const char* kFuncRegisteredNativeModule =
      "registeredNativeModule";

  static LynxViewInitRecorder& GetInstance() {
    static base::NoDestructor<LynxViewInitRecorder> instance_;
    return *instance_.get();
  }

  // LynxView Initial Data
  static void RecordViewPort(int32_t layout_height_mode,
                             int32_t layout_width_mode,
                             double preferred_layout_height,
                             double preferred_layout_width,
                             double preferred_max_layout_height,
                             double preferred_max_layout_width,
                             int64_t record_id);

  static void RecordThreadStrategy(int32_t threadStrategy, int64_t record_id,
                                   bool enableJSRuntime);

 private:
  friend base::NoDestructor<LynxViewInitRecorder>;
  LynxViewInitRecorder() = default;
  ~LynxViewInitRecorder() = default;
  LynxViewInitRecorder(const LynxViewInitRecorder&) = delete;
  LynxViewInitRecorder& operator=(const LynxViewInitRecorder&) = delete;

  rapidjson::Value method_lookup_value_;
};

}  // namespace recorder
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_RECORDER_LYNXVIEW_INIT_RECORDER_H_
