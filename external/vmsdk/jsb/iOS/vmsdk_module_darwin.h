// Copyright 2019 The Vmsdk Authors. All rights reserved.

#pragma once

#import <Foundation/Foundation.h>
#import "jsb/iOS/framework/JSModule.h"

#include "basic/vmsdk_exception_common.h"
#include "jsb/iOS/vmsdk_callback_darwin.h"
#include "jsb/module/vmsdk_module.h"
#include "napi.h"

namespace vmsdk {
namespace piper {

NSString *convertJSIStringToNSString(Napi::Env env, const Napi::String &value);
NSArray *convertJSIArrayToNSArray(Napi::Env env, const Napi::Array &value);
NSDictionary *convertJSIObjectToNSDictionary(Napi::Env env, const Napi::Object &value);
NSData *convertJSIArrayBufferToNSData(Napi::Env env, const Napi::ArrayBuffer &value);
id convertJSIValueToObjCObject(Napi::Env env, const Napi::Value &value);

class VmsdkModuleDarwin : public VmsdkModule {
 public:
  VmsdkModuleDarwin(id<JSModule> module, const std::shared_ptr<ModuleDelegate> &delegate);
  virtual ~VmsdkModuleDarwin() {}
  void Destroy() override;

 protected:
  Napi::Value invokeMethod(const Napi::CallbackInfo &info) override;
  //  Napi::Value getAttributeValue(Napi::Env env, std::string propName)
  //  override;

 private:
  id instance_;
  NSDictionary<NSString *, NSString *> *methodLookup;
  NSDictionary *attributeLookup;
  using PromiseInvocationBlock = void (^)(Napi::Env env, JSModulePromiseResolveBlock resolveWrapper,
                                          JSModulePromiseRejectBlock rejectWrapper);

  Napi::Value createPromise(Napi::Env env, PromiseInvocationBlock invoke);

  Napi::Value invokeObjCMethod(Napi::Env env, const std::string &methodName, SEL selector,
                               const Napi::CallbackInfo &info, size_t count,
                               enum ErrCode &callErrorCode);

  NSInvocation *getMethodInvocation(Napi::Env env, const id module, const std::string &methodName,
                                    SEL selector, const Napi::CallbackInfo &info, size_t count,
                                    NSMutableArray *retainedObjectsForInvocation,
                                    enum ErrCode &callErrorCode);

  JSModuleCallbackBlock convertJSIFunctionToCallback(Napi::Env env, const Napi::Function &function);
  void buildLookupMap(NSDictionary<NSString *, NSString *> *,
                      std::unordered_map<std::string, std::shared_ptr<MethodMetadata>> &);
};
}
}
