// Copyright 2019 The Lynx Authors. All rights reserved.

#include "jsbridge/ios/piper/lynx_callback_darwin.h"
#include "base/timer/time_utils.h"
#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "jsbridge/bindings/big_int/constants.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/recorder/recorder_controller.h"

#if __ENABLE_LYNX_NET__
#include "jsbridge/network/network_module.h"
#endif

namespace lynx {
namespace piper {

piper::Value convertNSNumberToJSIBoolean(Runtime &runtime, NSNumber *value) {
  Scope scope(runtime);
  return piper::Value((bool)[value boolValue]);
}

piper::Value convertNSNumberToJSINumber(Runtime &runtime, NSNumber *value) {
  Scope scope(runtime);
  return piper::Value([value doubleValue]);
}

piper::String convertNSStringToJSIString(Runtime &runtime, NSString *value) {
  Scope scope(runtime);
  return piper::String::createFromUtf8(runtime, [value UTF8String] ?: "");
}

std::optional<Object> convertNSDictionaryToJSIObject(Runtime &runtime, NSDictionary *value) {
  Scope scope(runtime);
  piper::Object result = piper::Object(runtime);
  NSDictionary *valueCopy = [value mutableCopy];
  for (NSString *k in valueCopy) {
    auto element = convertObjCObjectToJSIValue(runtime, valueCopy[k]);
    if (!element) {
      return std::optional<Object>();
    }
    if (!result.setProperty(runtime, [k UTF8String], std::move(*element))) {
      return std::optional<Object>();
    }
  }
  return result;
}

std::optional<Array> convertNSArrayToJSIArray(Runtime &runtime, NSArray *value) {
  Scope scope(runtime);
  NSArray *valueCopy = [value mutableCopy];
  auto result = piper::Array::createWithLength(runtime, valueCopy.count);
  if (!result) {
    return std::optional<Array>();
  }
  for (size_t i = 0; i < value.count; i++) {
    auto value_opt = convertObjCObjectToJSIValue(runtime, valueCopy[i]);
    if (!value_opt) {
      return std::optional<Array>();
    }
    if (!(*result).setValueAtIndex(runtime, i, std::move(*value_opt))) {
      return std::optional<Array>();
    }
  }
  return result;
}

piper::ArrayBuffer convertNSDataToJSIArrayBuffer(Runtime &runtime, NSData *value) {
  Scope scope(runtime);

  size_t length = [value length];
  const void *bytes = [value bytes];
  piper::ArrayBuffer result =
      piper::ArrayBuffer(runtime, static_cast<const uint8_t *>(bytes), length);
  return result;
}

std::optional<Value> convertObjCObjectToJSIValue(Runtime &runtime, id value) {
  Scope scope(runtime);
  if ([value isKindOfClass:[NSString class]]) {
    return std::optional<Value>(Value(convertNSStringToJSIString(runtime, (NSString *)value)));
  } else if ([value isKindOfClass:[NSNumber class]]) {
    if ([value isKindOfClass:[@YES class]]) {
      return convertNSNumberToJSIBoolean(runtime, (NSNumber *)value);
    } else if ([value compare:[NSNumber numberWithLongLong:piper::kMinJavaScriptNumber]] ==
                   NSOrderedAscending ||
               [value compare:[NSNumber numberWithLongLong:piper::kMaxJavaScriptNumber]] ==
                   NSOrderedDescending) {
      // In JavaScript, the max safe integer is 9007199254740991 and the min
      // safe integer is -9007199254740991, so when integer beyond limit, use
      // BigInt(in Lynx, BigInt is a particular JavaScript Object) to define it. More information
      // from
      // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number
      auto big_int =
          BigInt::createWithString(runtime, std::string([[value stringValue] UTF8String]));
      if (!big_int) {
        return std::optional<piper::Value>();
      } else {
        return piper::Value(std::move(*big_int));
      }
    }
    return convertNSNumberToJSINumber(runtime, (NSNumber *)value);
  } else if ([value isKindOfClass:[NSDictionary class]]) {
    auto obj = convertNSDictionaryToJSIObject(runtime, (NSDictionary *)value);
    return obj ? std::optional<Value>(Value(std::move(*obj))) : std::optional<Value>();
  } else if ([value isKindOfClass:[NSArray class]]) {
    auto array = convertNSArrayToJSIArray(runtime, (NSArray *)value);
    return array ? std::optional<Value>(Value(std::move(*array))) : std::optional<Value>();
  } else if ([value isKindOfClass:[NSData class]]) {
    return std::optional<Value>(Value(convertNSDataToJSIArrayBuffer(runtime, (NSData *)value)));
  } else if (value == (id)kCFNull) {
    return piper::Value::null();
  }
  return piper::Value::undefined();
}

ModuleCallbackDarwin::ModuleCallbackDarwin(int64_t callback_id) : ModuleCallback(callback_id) {}

ModuleCallbackDarwin::~ModuleCallbackDarwin() {}

void ModuleCallbackDarwin::Invoke(Runtime *runtime, ModuleCallbackFunctionHolder *holder) {
  if (runtime == nullptr) {
    LOGE("lynx ModuleCallbackDarwin has null runtime or null function");
    return;
  }
  TRACE_EVENT(LYNX_TRACE_CATEGORY_JSB, nullptr, [&](lynx::perfetto::EventContext ctx) {
    ctx.event()->set_name("InvokeCallbackFor:" + module_name_ + "." + method_name_);
    ctx.event()->add_terminating_flow_ids(CallbackFlowId());
    auto *debug = ctx.event()->add_debug_annotations();
    debug->set_name("First Argument");
    debug->set_string_value(first_arg_);
  });
  piper::Runtime *rt = runtime;
  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY_JSB, "ObjCValueToJSValue");
  uint64_t convert_params_start = base::CurrentSystemTimeMilliseconds();
  auto arg = convertObjCObjectToJSIValue(*rt, argument);
  uint64_t convert_params_end = base::CurrentSystemTimeMilliseconds();
  TRACE_EVENT_END(LYNX_TRACE_CATEGORY_JSB);
  if (!arg) {
    rt->reportJSIException(JSINativeException(
        "invoke JSB callback fail! Reason: Transfer Objc value to js value fail."));
    return;
  }
#if ENABLE_ARK_RECORDER
  tasm::recorder::NativeModuleRecorder::RecordCallback(module_name_.c_str(), method_name_.c_str(),
                                                       *arg, rt, callback_id(), record_id_);
#endif

  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY_JSB, "InvokeCallback");
  uint64_t invoke_js_callback_start = base::CurrentSystemTimeMilliseconds();
  holder->function_.call(*rt, *arg);
  if (timing_collector_ != nullptr) {
    timing_collector_->EndCallbackInvoke((convert_params_end - convert_params_start),
                                         invoke_js_callback_start);
#if __ENABLE_LYNX_NET__
    if (piper::network::IsNetworkResponse(this)) {
      piper::network::ReportRequestSuccess(
          timing_collector_, piper::network::TryGetHttpCode(runtime, &*arg, 1), false);
    }
#endif
  }
  TRACE_EVENT_END(LYNX_TRACE_CATEGORY_JSB);
}
}  // namespace piper
}  // namespace lynx
