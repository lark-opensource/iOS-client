// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REPLAY_LYNX_MODULE_TESTBENCH_H_
#define LYNX_TASM_REPLAY_LYNX_MODULE_TESTBENCH_H_
#include <list>
#include <memory>
#include <string>

#include "base/string/string_utils.h"
#include "jsbridge/jsi/jsi.h"
#include "jsbridge/module/lynx_module.h"
#include "jsbridge/module/module_delegate.h"
#include "third_party/fml/thread.h"
#include "third_party/rapidjson/document.h"

namespace lynx {
namespace piper {

class ModuleTestBench : public LynxModule {
 public:
  ModuleTestBench(const std::string& name,
                  const std::shared_ptr<ModuleDelegate>& delegate)
      : LynxModule(name, delegate), testbench_thread_("test_bench_thread") {}
  ~ModuleTestBench() override = default;
  void initModuleData(const rapidjson::Value& value,
                      rapidjson::Value* value_ptr,
                      rapidjson::Value* jsb_settings_ptr,
                      rapidjson::Document::AllocatorType& allocator);
  virtual void Destroy() override;

 protected:
  std::optional<piper::Value> invokeMethod(const MethodMetadata& method,
                                           Runtime* rt,
                                           const piper::Value* args,
                                           size_t count) override;

  piper::Value getAttributeValue(Runtime* rt, std::string propName) override;

 private:
  /**
   [
      {
      methodName:xxx,
      params:xxx,
      returnValue:xxx,
      },
      ......
   ]
   */
  rapidjson::Value moduleData;

  using ValueKind = Value::ValueKind;

  bool IsStrictMode();

  bool IsJsbIgnoredParams(const std::string& param);

  rapidjson::Value* jsb_ignored_info_;

  rapidjson::Value* jsb_settings_;

  bool IsSameURL(const std::string& first, const std::string& second);

  bool isSameMethod(const MethodMetadata& method, Runtime* rt,
                    const piper::Value* args, size_t count,
                    rapidjson::Value& value);
  bool isSameArgs(Runtime* rt, const piper::Value* args, size_t count,
                  rapidjson::Value& value);
  bool sameKernel(Runtime* rt, const piper::Value* args,
                  rapidjson::Value& value);
  // build methodMap for class LynxModule
  void buildLookupMap();

  static std::string kUndefined;
  static std::string kContainerID;
  static std::string kTimeStamp;
  static std::string kCardVersion;
  static std::string kHeader;
  static std::string kRequestTime;
  static std::string kFunction;
  static std::string kNaN;

  // record callbackFunction for every jsb call, it will be clear at end of this
  // call
  std::list<piper::Function> callbackFunctions;
  std::shared_ptr<rapidjson::Document::AllocatorType> allocator;

  piper::Value convertRapidJsonObjectToJSIValue(Runtime& runtime,
                                                rapidjson::Value& value);
  piper::Value convertRapidJsonStringToJSIValue(Runtime& runtime,
                                                rapidjson::Value& value);
  piper::Value convertRapidJsonNumberToJSIValue(Runtime& runtime,
                                                rapidjson::Value& value);

  void ActionsForJsbMatchFailed(Runtime* rt, const piper::Value* args,
                                size_t count);

  void InvokeJsbCallback(piper::Function callback_function, piper::Value value,
                         int64_t delay = -1);

  fml::Thread testbench_thread_;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_TASM_REPLAY_LYNX_MODULE_TESTBENCH_H_
