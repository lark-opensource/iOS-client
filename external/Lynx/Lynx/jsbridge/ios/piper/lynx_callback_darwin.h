// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_IOS_PIPER_LYNX_CALLBACK_DARWIN_H_
#define LYNX_JSBRIDGE_IOS_PIPER_LYNX_CALLBACK_DARWIN_H_

#import <Foundation/Foundation.h>
#include "jsbridge/jsi/jsi.h"
#include "jsbridge/module/lynx_module_callback.h"

namespace lynx {
namespace piper {

piper::Value convertNSNumberToJSIBoolean(Runtime &runtime, NSNumber *value);
piper::Value convertNSNumberToJSINumber(Runtime &runtime, NSNumber *value);
piper::String convertNSStringToJSIString(Runtime &runtime, NSString *value);
std::optional<Value> convertObjCObjectToJSIValue(Runtime &runtime, id value);
std::optional<Object> convertNSDictionaryToJSIObject(Runtime &runtime, NSDictionary *value);
std::optional<Array> convertNSArrayToJSIArray(Runtime &runtime, NSArray *value);

class ModuleCallbackDarwin : public ModuleCallback {
 public:
  ModuleCallbackDarwin(int64_t callback_id);
  ~ModuleCallbackDarwin();
  id argument;
  void Invoke(Runtime *runtime, ModuleCallbackFunctionHolder *holder) override;
};
}  // namespace piper
}  // namespace lynx
#endif  // LYNX_JSBRIDGE_IOS_PIPER_LYNX_CALLBACK_DARWIN_H_
