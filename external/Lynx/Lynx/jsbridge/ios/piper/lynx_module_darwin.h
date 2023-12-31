// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_IOS_PIPER_LYNX_MODULE_DARWIN_H_
#define LYNX_JSBRIDGE_IOS_PIPER_LYNX_MODULE_DARWIN_H_

#import <Foundation/Foundation.h>
#import "LynxModule.h"

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "base/debug/lynx_assert.h"
#include "config/config.h"
#include "jsbridge/ios/piper/lynx_callback_darwin.h"
#include "jsbridge/module/lynx_module.h"
#include "jsbridge/module/lynx_module_timing.h"

namespace lynx {
namespace piper {

NSString *convertJSIStringToNSString(Runtime &runtime, const piper::String &value);
NSArray *convertJSIArrayToNSArray(Runtime &runtime, const piper::Array &value,
                                  std::vector<piper::Object> &pre_object_vector);
NSDictionary *convertJSIObjectToNSDictionary(Runtime &runtime, const piper::Object &value,
                                             std::vector<piper::Object> &pre_object_vector);
NSData *convertJSIArrayBufferToNSData(Runtime &runtime, const piper::ArrayBuffer &value);
id convertJSIValueToObjCObject(Runtime &runtime, const piper::Value &value,
                               std::vector<piper::Object> &pre_object_vector);
std::optional<Value> PerformMethodInvocation(Runtime &runtime, NSInvocation *inv, const id module);

class LynxModuleDarwin : public LynxModule {
 public:
  LynxModuleDarwin(id<LynxModule> module, const std::shared_ptr<ModuleDelegate> &delegate);
  void Destroy() override;
#if ENABLE_ARK_RECORDER
  void SetRecordID(int64_t record_id) override;
  void EndRecordFunction(const std::string &method_name, size_t count, const piper::Value *js_args,
                         Runtime *rt, piper::Value &res) override;
  void StartRecordFunction(const std::string &method_name = "") override;
#endif
  std::optional<piper::Value> invokeObjCMethod(
      Runtime *runtime, const std::string &methodName, uint64_t invoke_session, SEL selector,
      const piper::Value *args, size_t count, enum ErrCode &callErrorCode,
      const NativeModuleInfoCollectorPtr &timing_collector);
  void SetSchema(const std::string schema) { schema_ = schema; }
  void SetMethodAuth(NSMutableArray<LynxMethodBlock> *methodAuthBlocks) {
    methodAuthBlocks_ = methodAuthBlocks;
  };
  void SetMethodSession(NSMutableArray<LynxMethodSessionBlock> *methodSessionBlocks) {
    methodSessionBlocks_ = methodSessionBlocks;
  };
  void SetMethodScope(NSString *namescope) { namescope_ = namescope; }
  id instance_;

  NSDictionary<NSString *, NSString *> *methodLookup;
  LynxCallbackBlock ConvertJSIFunctionToCallback(
      Runtime &runtime, piper::Function function, const std::string &method_name,
      const piper::Value *first_arg, ModuleCallbackType type, uint64_t start_time,
      const NativeModuleInfoCollectorPtr &timing_collector);

 protected:
  std::optional<piper::Value> invokeMethod(const MethodMetadata &method, Runtime *rt,
                                           const piper::Value *args, size_t count) override;
  piper::Value getAttributeValue(Runtime *rt, std::string propName) override;

 private:
  NSString *namescope_;
  NSMutableArray<LynxMethodBlock> *methodAuthBlocks_;
  NSMutableArray<LynxMethodSessionBlock> *methodSessionBlocks_;
  NSDictionary *attributeLookup;
  std::string schema_;

  ALLOW_UNUSED_TYPE int64_t record_id_ = 0;
  ALLOW_UNUSED_TYPE NSMutableArray *callback_stack_;

  using PromiseInvocationBlock = void (^)(Runtime &rt, LynxPromiseResolveBlock resolveWrapper,
                                          LynxPromiseRejectBlock rejectWrapper);

  std::optional<piper::Value> createPromise(Runtime &runtime, PromiseInvocationBlock invoke);

  NSInvocation *getMethodInvocation(Runtime &runtime, const id module,
                                    const std::string &methodName, SEL selector,
                                    const piper::Value *args, size_t count,
                                    NSMutableArray *retainedObjectsForInvocation,
                                    enum ErrCode &callErrorCode, uint64_t start_time,
                                    NSDictionary *extra,
                                    const NativeModuleInfoCollectorPtr &timing_collector);

  LynxCallbackBlock convertJSIFunctionToCallback(Runtime &runtime, piper::Function function,
                                                 const std::string &method_name,
                                                 const piper::Value *first_arg,
                                                 const std::string invoke_session);
  void buildLookupMap(NSDictionary<NSString *, NSString *> *,
                      std::unordered_map<std::string, std::shared_ptr<MethodMetadata>> &);
};
}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_IOS_PIPER_LYNX_MODULE_DARWIN_H_
