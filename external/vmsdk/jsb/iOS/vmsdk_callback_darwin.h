// Copyright 2019 The Vmsdk Authors. All rights reserved.

#pragma once

#import <Foundation/Foundation.h>

#include "jsb/module/module_delegate.h"
#include "jsb/module/vmsdk_module_callback.h"

namespace vmsdk {
namespace piper {

Napi::Value convertNSNumberToJSIBoolean(Napi::Env env, NSNumber *value);
Napi::Value convertNSNumberToJSINumber(Napi::Env env, NSNumber *value);
Napi::String convertNSStringToJSIString(Napi::Env env, NSString *value);
Napi::Value convertObjCObjectToJSIValue(Napi::Env env, id value);
Napi::Object convertNSDictionaryToJSIObject(Napi::Env env, NSDictionary *value);
Napi::Array convertNSArrayToJSIArray(Napi::Env env, NSArray *value);

class ModuleCallbackDarwin : public ModuleCallback {
 public:
  ModuleCallbackDarwin(int64_t callback_id, const std::string &module_name,
                       const std::shared_ptr<ModuleDelegate> delegate);
  ~ModuleCallbackDarwin();
  id argument;
  void Invoke(Napi::Env env, ModuleCallbackFunctionHolder *holder) override;

 private:
  std::string module_;
  const std::shared_ptr<ModuleDelegate> delegate_;
};
}  // namespace jsbridge
}  // namespace vmsdk
