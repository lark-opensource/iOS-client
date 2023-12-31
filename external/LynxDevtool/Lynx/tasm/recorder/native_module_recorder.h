// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_RECORDER_NATIVE_MODULE_RECORDER_H_
#define LYNX_TASM_RECORDER_NATIVE_MODULE_RECORDER_H_

#include <string>
#include <vector>

#include "jsbridge/jsi/jsi.h"
#include "tasm/recorder/ark_base_recorder.h"
#include "third_party/rapidjson/document.h"

namespace lynx {

namespace piper {
class Runtime;
class Value;
}  // namespace piper

namespace tasm {
namespace recorder {

class NativeModuleRecorder {
 public:
  static constexpr const char* kParamArgc = "argc";
  static constexpr const char* kParamArgs = "args";
  static constexpr const char* kParamFunction = "function";
  static constexpr const char* kParamJSMethodName = "jsMethodName";
  static constexpr const char* kParamModuleName = "moduleName";
  static constexpr const char* kParamReturnValue = "returnValue";
  static constexpr const char* kParamSelectorName = "selectorName";
  static constexpr const char* kCallBack = "callback";
  static constexpr const char* kFuncSendGlobalEvent = "sendGlobalEvent";

  static constexpr const char* kFuncNativeModuleFunctionCall =
      "nativeModuleFunctionCall";
  static constexpr const char* kFuncNativeModuleCallbackCall =
      "nativeModuleCallbackCall";

  // some key for android touch event
  static constexpr const char* kFuncSendEventAndroid = "sendEventAndroid";
  static constexpr const char* kEventAndroidArgs[] = {"action", "x", "y",
                                                      "metaState"};

  static void RecordFunctionCall(const char* module_name,
                                 const char* js_method_name, uint32_t argc,
                                 const piper::Value* args,
                                 const int64_t* callbacks, uint32_t count,
                                 piper::Value& res, piper::Runtime* rt,
                                 int64_t record_id);

  static void RecordCallback(const char* module_name, const char* method_name,
                             const piper::Value& args, piper::Runtime* rt,
                             int64_t callback_id, int64_t record_id);

  static void RecordCallback(const char* module_name, const char* method_name,
                             const piper::Value* args, uint32_t count,
                             piper::Runtime* rt, int64_t callback_id,
                             int64_t record_id);

  static void RecordGlobalEvent(std::string module_id, std::string method_id,
                                const piper::Value* args, uint64_t count,
                                piper::Runtime* rt);

  static void RecordEventAndroid(const std::vector<std::string>& args,
                                 int64_t record_id, ArkBaseRecorder* instance);

 private:
  static rapidjson::Value ParsePiperValueToJsonValue(const piper::Value& res,
                                                     piper::Runtime* rt);
};

}  // namespace recorder
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_RECORDER_NATIVE_MODULE_RECORDER_H_
