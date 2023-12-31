// Copyright 2019 The Vmsdk Authors. All rights reserved.

#include "jsb/iOS/vmsdk_callback_darwin.h"
#include "basic/log/logging.h"
#include "basic/vmsdk_exception_common.h"
#include "jsb/runtime/js_runtime.h"

namespace vmsdk {
namespace piper {

Napi::Value convertNSNumberToJSIBoolean(Napi::Env env, NSNumber *value) {
  return Napi::Boolean::New(env, (bool)[value boolValue]);
}

Napi::Value convertNSNumberToJSINumber(Napi::Env env, NSNumber *value) {
  return Napi::Number::New(env, [value doubleValue]);
}

Napi::String convertNSStringToJSIString(Napi::Env env, NSString *value) {
  return Napi::String::New(env, [value UTF8String] ?: "");
}

Napi::Object convertNSDictionaryToJSIObject(Napi::Env env, NSDictionary *value) {
  Napi::Object result = Napi::Object::New(env);
  value = [value copy];
  for (NSString *k in value) {
    result.Set([k UTF8String], convertObjCObjectToJSIValue(env, value[k]));
  }
  return result;
}

Napi::Array convertNSArrayToJSIArray(Napi::Env env, NSArray *value) {
  Napi::Array result = Napi::Array::New(env, value.count);
  for (size_t i = 0; i < value.count; i++) {
    result.Set(i, convertObjCObjectToJSIValue(env, value[i]));
  }
  return result;
}

Napi::ArrayBuffer convertNSDataToJSIArrayBuffer(Napi::Env env, NSData *value) {
  size_t length = [value length];
  const void *bytes = [value bytes];
  //   piper::ArrayBuffer result =
  //       piper::ArrayBuffer(runtime, static_cast<const uint8_t *>(bytes),
  //       length);
  //   return result;
  return Napi::ArrayBuffer::New(env, (void *)bytes, length);
}

Napi::Value convertObjCObjectToJSIValue(Napi::Env env, id value) {
  if ([value isKindOfClass:[NSString class]]) {
    return convertNSStringToJSIString(env, (NSString *)value);
  } else if ([value isKindOfClass:[NSNumber class]]) {
    if ([value isKindOfClass:[@YES class]]) {
      return convertNSNumberToJSIBoolean(env, (NSNumber *)value);
    }
    return convertNSNumberToJSINumber(env, (NSNumber *)value);
  } else if ([value isKindOfClass:[NSDictionary class]]) {
    return convertNSDictionaryToJSIObject(env, (NSDictionary *)value);
  } else if ([value isKindOfClass:[NSArray class]]) {
    return convertNSArrayToJSIArray(env, (NSArray *)value);
  } else if ([value isKindOfClass:[NSData class]]) {
    return convertNSDataToJSIArrayBuffer(env, (NSData *)value);
  } else if (value == (id)kCFNull) {
    return env.Null();
  }
  return env.Undefined();
}

ModuleCallbackDarwin::ModuleCallbackDarwin(int64_t callback_id, const std::string &module_name,
                                           const std::shared_ptr<ModuleDelegate> delegate)
    : ModuleCallback(callback_id), module_(module_name), delegate_(delegate) {}

ModuleCallbackDarwin::~ModuleCallbackDarwin() {}

void ModuleCallbackDarwin::Invoke(Napi::Env env, ModuleCallbackFunctionHolder *holder) {
  if (env == nullptr) {
    VLOGE("vmsdk ModuleCallbackDarwin has null runtime or null function");
    return;
  }

  Napi::HandleScope scope(napi_env);
  Napi::ContextScope contextScope(napi_env);

  if ([argument isKindOfClass:[NSArray class]]) {
    //多个参数
    Napi::Array arr = convertNSArrayToJSIArray(env, (NSArray *)argument);
    size_t size = arr.Length();
    std::vector<napi_value> values;
    for (size_t index = 0; index < size; index++) {
      values.push_back(arr.Get(index));
    }
    holder->function_.Value().Call(values);
  } else {
    //只有一个参数
    Napi::Value arg = convertObjCObjectToJSIValue(env, argument);
    holder->function_.Value().Call({arg});
  }
  std::string exception;
  if (runtime::JSRuntimeUtils::CheckAndGetExceptionMsg(env, exception)) {
    // handle this exception
    Napi::Value func_name = holder->function_.Value().Get("name");
    std::string js_name = func_name.As<Napi::String>().Utf8Value();
    delegate_->OnErrorOccurred(VMSDK_ERROR_CODE_MODULE_FUNC_CALL_EXCEPTION, module_, js_name,
                               exception);
    NSLog(@"Js Exception occured.");
  }
}
}
}
