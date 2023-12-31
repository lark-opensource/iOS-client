// Copyright 2019 The Lynx Authors. All rights reserved.

#import "lynx_module_darwin.h"
#import <objc/message.h>
#import <objc/runtime.h>
#include <memory>
#import "LynxLog.h"
#include "base/iOS/lynx_env_darwin.h"
#include "base/lynx_env.h"
#include "base/timer/time_utils.h"
#include "base/trace_event/trace_event.h"
#include "config/config.h"
#include "jsbridge/bindings/big_int/constants.h"
#include "jsbridge/module/lynx_module_timing.h"
#include "jsbridge/utils/utils.h"
#include "tasm/config.h"
#include "tasm/lynx_trace_event.h"
#include "tasm/recorder/recorder_controller.h"
#include "third_party/modp_b64/modp_b64.h"

#if __ENABLE_LYNX_NET__
#include "jsbridge/network/request_interceptor_darwin.h"
#endif

namespace lynx {
namespace piper {

namespace {
std::string genExceptionErrorMessage(NSException *exception) {
  auto message = std::string{" throws an uncaught exception: "}
                     .append([exception.name UTF8String])
                     .append(". Reason: ")
                     .append([exception.reason UTF8String]);

  if (exception.userInfo != nil) {
    message.append(". UserInfo:\n");
    for (id key in exception.userInfo) {
      NSString *pair =
          [[NSString alloc] initWithFormat:@"%@, %@", key, [exception.userInfo objectForKey:key]];
      message.append([pair UTF8String]);
      message.append("\n");
    }
  }
  return message;
}
}  // namespace

#pragma mark - LynxModuleDarwin

void LynxModuleDarwin::buildLookupMap(
    NSDictionary<NSString *, NSString *> *lookup,
    std::unordered_map<std::string, std::shared_ptr<MethodMetadata>> &map) {
  for (NSString *methodName in lookup) {
    SEL selector = NSSelectorFromString(lookup[methodName]);
    NSMethodSignature *msig = [[instance_ class] instanceMethodSignatureForSelector:selector];
    if (msig == nil) {
      // TODO (liujilong): Log this.
      continue;
    }
    std::string method = std::string([methodName UTF8String]);
    auto darwinModule = std::make_shared<MethodMetadata>(msig.numberOfArguments - 2, method);
    map[method] = darwinModule;
  }
}

LynxModuleDarwin::LynxModuleDarwin(id<LynxModule> instance,
                                   const std::shared_ptr<ModuleDelegate> &delegate)
    : LynxModule(std::string([[[instance class] name] UTF8String]), delegate), instance_(instance) {
  methodLookup = [[instance class] methodLookup];
  buildLookupMap(methodLookup, methodMap_);
  if ([[instance class] respondsToSelector:@selector(attributeLookup)]) {
    attributeLookup = [[instance class] attributeLookup];
  }
#if ENABLE_ARK_RECORDER
  // Most invokes are accompanied by one callback
  callback_stack_ = [[NSMutableArray alloc] init];
#endif
  methodAuthBlocks_ = [[NSMutableArray alloc] init];
  methodSessionBlocks_ = [NSMutableArray array];
}

void LynxModuleDarwin::Destroy() {
#if !defined(OS_OSX)
  if (instance_ == nil || [instance_ isEqual:[NSNull null]]) {
    LOGI("lynx LynxModule Destroy: " << name_ << ", module is empty.");
    return;
  }
  LOGI("lynx LynxModule Destroy: " << name_);
  if ([instance_ respondsToSelector:@selector(destroy)]) {
    [instance_ destroy];
  }
#endif  // !defined(OS_OSX)
}

std::optional<piper::Value> LynxModuleDarwin::invokeMethod(const MethodMetadata &method,
                                                           Runtime *rt, const piper::Value *args,
                                                           size_t count) {
  uint64_t call_func_start = lynx::base::CurrentSystemTimeMilliseconds();
  piper::Scope scope(*rt);
  auto res = piper::Value::undefined();
  const std::string &js_method_name = method.name;
  std::string first_arg_str;
  if (count > 0 && args && args[0].isString()) {
    first_arg_str = args[0].getString(*rt).utf8(*rt);
  }
  piper::NativeModuleInfoCollectorPtr timing_collector =
      std::make_shared<piper::NativeModuleInfoCollector>(delegate_, name_, js_method_name,
                                                         first_arg_str);
#if __ENABLE_LYNX_NET__
  // We need these information to monitor network request information,
  // the rate of success and the proportion of requests accomplished by
  // Lynx. After fully switch to Lynx Network, we can remove these logics.
  network::SetNetworkCallbackInfo(name_, js_method_name, rt, args, count, timing_collector);
#endif
  TRACE_EVENT(LYNX_TRACE_CATEGORY_JSB, nullptr, [&](lynx::perfetto::EventContext ctx) {
    ctx.event()->set_name("CallJSB:" + name_ + "." + js_method_name);
    auto *debug = ctx.event()->add_debug_annotations();
    debug->set_name("First Argument");
    debug->set_string_value(first_arg_str);
  });
  // issue: #1510
  ErrCode callErrorCode = LYNX_ERROR_CODE_SUCCESS;
  uint64_t start_time = lynx::base::CurrentTimeMilliseconds();
  std::ostringstream invoke_session;
  invoke_session << start_time;
  @try {
    NSString *jsMethodNameNSString = [NSString stringWithUTF8String:js_method_name.c_str()];
    if (methodLookup[jsMethodNameNSString] != nil) {
      SEL selector = NSSelectorFromString(methodLookup[jsMethodNameNSString]);
      auto res_opt = invokeObjCMethod(rt, js_method_name, start_time, selector, args, count,
                                      callErrorCode, timing_collector);
      if (!res_opt) {
        rt->reportJSIException(
            JSINativeException("Exception happen in LynxModuleDarwin invokeMethod: " + name_ + "." +
                               method.name + " , args: " + first_arg_str));
        timing_collector->OnErrorOccurred(NativeModuleStatusCode::FAILURE);
        return std::optional<piper::Value>();
      }
      res = std::move(*res_opt);
      LOGI("LynxModuleDarwin did invokeMethod: " << name_ << "." << method.name
                                                 << " , args: " << first_arg_str);
    } else {
      LOGE("LynxModuleDarwin::invokeMethod module: "
           << name_ << ", method: " << js_method_name << " , args: " << first_arg_str
           << " failed in invokeMethod(), cannot find method in methodLookup: " <<
           [[methodLookup description] UTF8String]);
    }
  } @catch (NSException *exception) {
    LLogError(@"Exception '%@' was thrown while invoking function %s on target %@\n call stack: %@",
              exception, method.name.c_str(), instance_, exception.callStackSymbols);
    // NSInvalidArgumentException is already handle in iOS.3
    callErrorCode = LYNX_ERROR_CODE_MODULE_FUNC_CALL_EXCEPTION;
    // issue: #1510
    delegate_->OnErrorOccurred(LYNX_ERROR_CODE_MODULE_FUNC_CALL_EXCEPTION, name_, js_method_name,
                               genExceptionErrorMessage(exception));
    delegate_->OnMethodInvoked(name_, js_method_name, LYNX_ERROR_CODE_MODULE_FUNC_CALL_EXCEPTION);
    timing_collector->OnErrorOccurred(NativeModuleStatusCode::FAILURE);
  }
  if (base::LynxEnv::GetInstance().IsPiperMonitorEnabled()) {
    std::string first_param_str;
    if (count > 0 && args && args[0].isString()) {
      first_param_str = args[0].getString(*rt).utf8(*rt);
    }
    base::LynxEnvDarwin::onPiperInvoked(name_, js_method_name, first_param_str, schema_,
                                        invoke_session.str());
  }
  timing_collector->EndCallFunc(call_func_start);
  return res;
}

piper::Value LynxModuleDarwin::getAttributeValue(Runtime *rt, std::string propName) {
  if (!attributeLookup) return piper::Value::undefined();
  NSString *attributeName = [NSString stringWithUTF8String:propName.c_str()];
  id value = attributeLookup[attributeName];
  if (value) {
    auto value_opt = convertObjCObjectToJSIValue(*rt, value);
    if (value_opt) {
      return std::move(*value_opt);
    }
  }
  return piper::Value::undefined();
}

NSInvocation *LynxModuleDarwin::getMethodInvocation(
    Runtime &runtime, const id module, const std::string &methodName, SEL selector,
    const piper::Value *args, size_t count, NSMutableArray *retainedObjectsForInvocation,
    enum ErrCode &callErrorCode, uint64_t start_time, NSDictionary *extra,
    const piper::NativeModuleInfoCollectorPtr &timing_collector) {
  piper::Scope scope(runtime);
  NSMethodSignature *methodSignature = [[module class] instanceMethodSignatureForSelector:selector];
  NSInvocation *inv = [NSInvocation invocationWithMethodSignature:methodSignature];
  [inv setSelector:selector];

  NSMutableArray *objcParams = [[NSMutableArray alloc] init];
  static char STRING_KEY;
  objc_setAssociatedObject(inv, &STRING_KEY, objcParams, OBJC_ASSOCIATION_RETAIN);

  // error message generator
  auto methodNameStr = std::string{[NSStringFromSelector(selector) UTF8String]};
  auto expectedButGot = [this, &methodNameStr, &callErrorCode](size_t pos,
                                                               const std::string &expected,
                                                               const std::string &but_got) mutable {
    callErrorCode = LYNX_ERROR_CODE_MODULE_FUNC_WRONG_ARG_TYPE;
    auto message =
        LynxModuleUtils::ExpectedButGotAtIndexError(expected, but_got, static_cast<int>(pos));
    delegate_->OnErrorOccurred(LYNX_ERROR_CODE_MODULE_FUNC_WRONG_ARG_TYPE, name_, methodNameStr,
                               message);
  };
  // arg type
  const auto argTypeStr = [](const piper::Value *arg) {
    return LynxModuleUtils::JSTypeToString(arg);
  };
  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY_JSB, "JSValueToObjCValue");
  // index: i + 2 ==> objc arguments: [this, _cmd, args..., resoledBlock, rejectedBlock]
  uint64_t convert_params_start = base::CurrentSystemTimeMilliseconds();
  for (size_t i = 0; i < count; i++) {
    const piper::Value *arg = &args[i];
    const char *objCArgType = [methodSignature getArgumentTypeAtIndex:i + 2];
    // issue: #1510
    auto reportError = [i, expectedButGot, argTypeStr, arg](const std::string &expected) mutable {
      expectedButGot(i, expected, argTypeStr(arg));
    };
    NSNumber *num = nil;
    if (arg->isBool()) {
      num = [NSNumber numberWithBool:arg->getBool()];
    } else if (arg->isNumber()) {
      num = [NSNumber numberWithDouble:arg->getNumber()];
    }

    if (objCArgType[0] == _C_ID) {
      id obj = nil;
      if (arg->isBool()) {
        obj = [NSNumber numberWithBool:arg->getBool()];
      } else if (arg->isNumber()) {
        obj = [NSNumber numberWithDouble:arg->getNumber()];
      } else if (arg->isNull()) {
        obj = nil;
      } else if (arg->isString()) {
        obj = convertJSIStringToNSString(runtime, arg->getString(runtime));
      } else if (arg->isObject()) {
        std::unique_ptr<std::vector<piper::Object>> pre_object_vector =
            std::make_unique<std::vector<piper::Object>>();

        piper::Object o = arg->getObject(runtime);
        if (o.isArray(runtime)) {
          obj = convertJSIArrayToNSArray(runtime, o.getArray(runtime), *pre_object_vector);
          // If obj is nil, means that there is exception in convertJSIArrayToNSArray, return
          // directly.
          if (obj == nil) {
            return nil;
          }
        } else if (o.isFunction(runtime)) {
          LOGV("LynxModuleDarwin::getMethodInvocation, "
               << " module: " << name_ << " method: " << methodName
               << " |JS FUNCTION| found at argument " << i);
          obj =
              ConvertJSIFunctionToCallback(runtime, o.getFunction(runtime), methodName, &args[0],
                                           ModuleCallbackType::Base, start_time, timing_collector);
        } else if (o.isArrayBuffer(runtime)) {
          obj = convertJSIArrayBufferToNSData(runtime, o.getArrayBuffer(runtime));
        } else {
          obj = convertJSIObjectToNSDictionary(runtime, o, *pre_object_vector);
          // If obj is nil, means that there is exception in convertJSIObjectToNSDictionary, return
          // directly.
          if (obj == nil) {
            return nil;
          }
        }
      }
      if (obj != nil) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
          NSMutableDictionary *temp = [NSMutableDictionary dictionary];
          if ([module isKindOfClass:NSClassFromString(@"BDLynxBridgeModule")]) {
            [temp addEntriesFromDictionary:@{@"extra" : extra ?: @{}}];
          }
          [temp addEntriesFromDictionary:obj];
          [objcParams addObject:temp];
          [inv setArgument:(void *)&temp atIndex:i + 2];
        } else {
          [objcParams addObject:obj];
          [inv setArgument:(void *)&obj atIndex:i + 2];
        }
        continue;
      } else  // obj == nil
      {
        // issue: #1510
        reportError("sub class of NSObject");
      }

    } else {
      // issue: #1510
      if (num == nil) {
        switch (objCArgType[0]) {
          case _C_CHR:
            reportError("short");
            break;
          case _C_UCHR:
            reportError("unsigned char");
            break;
          case _C_SHT:
            reportError("short");
            break;
          case _C_USHT:
            reportError("unsigned short");
            break;
          case _C_INT:
            reportError("int");
            break;
          case _C_UINT:
            reportError("unsigned int");
            break;
          case _C_LNG:
            reportError("long");
            break;
          case _C_ULNG:
            reportError("unsigned long");
            break;
          case _C_LNG_LNG:
            reportError("long long");
            break;
          case _C_ULNG_LNG:
            reportError("unsigned long long");
            break;
          case _C_BOOL:
            reportError("bool");
            break;
          case _C_DBL:
            reportError("double");
            break;
          case _C_FLT:
            reportError("float");
            break;
          default:
            reportError("unknown number type");
            break;
        }
      }

      if (objCArgType[0] == _C_CHR) {
        char c = [num charValue];
        [inv setArgument:(void *)&c atIndex:i + 2];
        continue;
      } else if (objCArgType[0] == _C_UCHR) {
        unsigned char uc = [num unsignedCharValue];
        [inv setArgument:(void *)&uc atIndex:i + 2];
        continue;
      } else if (objCArgType[0] == _C_SHT) {
        short s = [num shortValue];
        [inv setArgument:(void *)&s atIndex:i + 2];
        continue;
      } else if (objCArgType[0] == _C_USHT) {
        unsigned short us = [num unsignedShortValue];
        [inv setArgument:(void *)&us atIndex:i + 2];
        continue;
      } else if (objCArgType[0] == _C_INT) {
        int ii = [num intValue];
        [inv setArgument:(void *)&ii atIndex:i + 2];
        continue;
      } else if (objCArgType[0] == _C_UINT) {
        unsigned int ui = [num unsignedIntValue];
        [inv setArgument:(void *)&ui atIndex:i + 2];
        continue;
      } else if (objCArgType[0] == _C_LNG) {
        long l = [num longValue];
        [inv setArgument:(void *)&l atIndex:i + 2];
        continue;
      } else if (objCArgType[0] == _C_ULNG) {
        unsigned long ul = [num unsignedLongValue];
        [inv setArgument:(void *)&ul atIndex:i + 2];
        continue;
      } else if (objCArgType[0] == _C_LNG_LNG) {
        long long ll = [num longLongValue];
        [inv setArgument:(void *)&ll atIndex:i + 2];
        continue;
      } else if (objCArgType[0] == _C_ULNG_LNG) {
        unsigned long long ull = [num unsignedLongLongValue];
        [inv setArgument:(void *)&ull atIndex:i + 2];
        continue;
      } else if (objCArgType[0] == _C_BOOL) {
        BOOL b = [num boolValue];
        [inv setArgument:(void *)&b atIndex:i + 2];
        continue;
      } else if (objCArgType[0] == _C_FLT) {
        float f = [num floatValue];
        [inv setArgument:(void *)&f atIndex:i + 2];
      } else if (objCArgType[0] == _C_DBL) {
        double d = [num doubleValue];
        [inv setArgument:(void *)&d atIndex:i + 2];
      }
    }
  }
  if (timing_collector != nullptr) {
    timing_collector->EndFuncParamsConvert(convert_params_start);
  }
  TRACE_EVENT_END(LYNX_TRACE_CATEGORY_JSB);
  return inv;
}

std::optional<piper::Value> LynxModuleDarwin::invokeObjCMethod(
    Runtime *runtime, const std::string &methodName, uint64_t invoke_session, SEL selector,
    const piper::Value *args, size_t count, enum ErrCode &callErrorCode,
    const piper::NativeModuleInfoCollectorPtr &timing_collector) {
  piper::Scope scope(*runtime);
  NSMutableArray *retainedObjectsForInvocation = [NSMutableArray arrayWithCapacity:count + 2];
  NSMethodSignature *methodSignature =
      [[instance_ class] instanceMethodSignatureForSelector:selector];
  NSUInteger argumentsCount = methodSignature.numberOfArguments;

  std::string jsb_func_name;
  if (count > 0 && args && args[0].isString() &&
      [instance_ isKindOfClass:NSClassFromString(@"BDLynxBridgeModule")]) {
    jsb_func_name = args[0].getString(*runtime).utf8(*runtime);
  }

#if ENABLE_ARK_RECORDER
  StartRecordFunction();
#endif

  auto &inst = instance_;
  auto moduleNameStr = std::string{[NSStringFromClass([inst class]) UTF8String]};
  auto methodNameStr = std::string{[NSStringFromSelector(selector) UTF8String]};

  // issue: #1510
  // TODO: argumentsCount - 4 == count means this is a promise
  // THUS THIS ARGUMENT CHECK CANNOT DETECT IF __argumentsCount - 4 != count__ !!
  if (argumentsCount - 2 != count && argumentsCount - 4 != count) {
    // issue: #1510
    // if #arg is __MORE__, an exception will be thrown on parsing type of args,
    // thus the function will not be invoked
    callErrorCode = LYNX_ERROR_CODE_MODULE_FUNC_WRONG_ARG_NUM;
    auto invokedErrorMessage = std::string{" invoked with wrong number of arguments, expected "}
                                   .append(std::to_string(argumentsCount - 2))
                                   .append(" but got ")
                                   .append(std::to_string(count))
                                   .append(".");
    delegate_->OnErrorOccurred(LYNX_ERROR_CODE_MODULE_FUNC_WRONG_ARG_NUM, name_, methodNameStr,
                               invokedErrorMessage);
    if (argumentsCount - 2 < count) {
      delegate_->OnMethodInvoked(name_, methodNameStr, LYNX_ERROR_CODE_MODULE_FUNC_WRONG_ARG_NUM);
      if (timing_collector != nullptr) {
        timing_collector->OnErrorOccurred(NativeModuleStatusCode::PARAMETER_ERROR);
      }
      return Value{};
    }
  }

  NSMutableDictionary *extra = [NSMutableDictionary dictionary];
  std::ostringstream time_s;
  time_s << invoke_session;
  @try {
    if (methodSessionBlocks_.count > 0) {
      for (LynxMethodSessionBlock sessionBlock in methodSessionBlocks_) {
        [extra
            addEntriesFromDictionary:sessionBlock(
                                         jsb_func_name.size() > 0
                                             ? [NSString stringWithUTF8String:jsb_func_name.c_str()]
                                             : NSStringFromSelector(selector),
                                         NSStringFromClass([inst class]),
                                         [NSString stringWithUTF8String:time_s.str().c_str()],
                                         namescope_)
                                         ?: @{}];
      }
    }
  } @catch (NSException *exception) {
    LOGE("Exception happened in LynxMethodSessionBlocks! Error message: "
         << genExceptionErrorMessage(exception));
    if (timing_collector != nullptr) {
      timing_collector->OnErrorOccurred(NativeModuleStatusCode::UNAUTHORIZED_BY_SYSTEM);
    }
  }

  NSInvocation *inv = getMethodInvocation(*runtime, instance_, methodName, selector, args, count,
                                          retainedObjectsForInvocation, callErrorCode,
                                          invoke_session, extra, timing_collector);
  @try {
    if (methodAuthBlocks_.count > 0 && base::LynxEnv::GetInstance().IsPiperMonitorEnabled()) {
      std::ostringstream time_s;
      time_s << invoke_session;
      for (LynxMethodBlock authBlock in methodAuthBlocks_) {
        if (!authBlock(jsb_func_name.size() > 0
                           ? [NSString stringWithUTF8String:jsb_func_name.c_str()]
                           : NSStringFromSelector(selector),
                       NSStringFromClass([inst class]),
                       [NSString stringWithUTF8String:time_s.str().c_str()], inv)) {
          auto error_msg = std::string{" has been rejected by LynxMethodAuthBlocks!"};
          LOGE(name_ << "." << methodNameStr << error_msg);
          delegate_->OnErrorOccurred(LYNX_ERROR_CODE_JAVASCRIPT, name_, methodNameStr, error_msg);
          if (timing_collector != nullptr) {
            timing_collector->OnErrorOccurred(NativeModuleStatusCode::UNAUTHORIZED);
          }
          return piper::Value::undefined();
        }
      }
    }
  } @catch (NSException *exception) {
    LOGE("Exception happened in LynxMethodAuthBlocks! Error message: "
         << genExceptionErrorMessage(exception));
    if (timing_collector != nullptr) {
      timing_collector->OnErrorOccurred(NativeModuleStatusCode::UNAUTHORIZED);
    }
  }

  if (inv == nil) {
    runtime->reportJSIException(JSINativeException(
        "Exception happened in getMethodInvocation when convert js value to objc value."));
    if (timing_collector != nullptr) {
      timing_collector->OnErrorOccurred(NativeModuleStatusCode::FAILURE);
    }
    return std::optional<piper::Value>();
  }

  if (argumentsCount - 4 == count) {
    LOGV("LynxModule, invokeObjCMethod, module: " << name_ << " method: " << methodName
                                                  << " is a promise");
    // objc arguments: [this, _cmd, args..., resoledBlock, rejectedBlock]
    return createPromise(*runtime, ^(Runtime &rt, LynxPromiseResolveBlock resolveBlock,
                                     LynxPromiseRejectBlock rejectBlock) {
      @try {
        [inv setArgument:(void *)&resolveBlock atIndex:count + 2];
        [inv setArgument:(void *)&rejectBlock atIndex:count + 3];
        [retainedObjectsForInvocation addObject:resolveBlock];
        [retainedObjectsForInvocation addObject:rejectBlock];
        PerformMethodInvocation(rt, inv, instance_);
        // issue: #1510
        LOGV("LynxModuleDarwin::invokeObjCMethod, module: "
             << name_ << " method: " << methodName << " |PROMISE|, did PerformMethodInvocation");
        delegate_->OnMethodInvoked(name_, methodNameStr, callErrorCode);
      } @catch (NSException *exception) {
        LLogError(
            @"Exception '%@' was thrown while invoking function %s on target %@\n call stack: %@",
            exception, methodNameStr.c_str(), instance_, exception.callStackSymbols);
        // issue: #1510
        delegate_->OnMethodInvoked(name_, methodNameStr,
                                   LYNX_ERROR_CODE_MODULE_FUNC_CALL_EXCEPTION);
        delegate_->OnErrorOccurred(LYNX_ERROR_CODE_MODULE_FUNC_CALL_EXCEPTION, name_, methodNameStr,
                                   genExceptionErrorMessage(exception));
      }
    });
  }
  // issue: #1510
  uint64_t invoke_facade_method_start = base::CurrentSystemTimeMilliseconds();
  auto res = PerformMethodInvocation(*runtime, inv, instance_);
  if (!res) {
    runtime->reportJSIException(
        JSINativeException("PerformMethodInvocation error! There may be error when convert return "
                           "ObjcValue to JSValue."));
    if (timing_collector != nullptr) {
      timing_collector->OnErrorOccurred(NativeModuleStatusCode::RETURN_ERROR);
    }
    return std::optional<piper::Value>();
  }
  if (timing_collector != nullptr) {
    timing_collector->EndPlatformMethodInvoke(invoke_facade_method_start);
  }
  LOGV("LynxModuleDarwin::invokeObjCMethod, module: " << name_ << " method: " << methodName
                                                      << " did PerformMethodInvocation");
  TRACE_EVENT(LYNX_TRACE_CATEGORY_JSB, "OnMethodInvoked");
  delegate_->OnMethodInvoked(name_, methodNameStr, callErrorCode);

#if ENABLE_ARK_RECORDER
  EndRecordFunction(methodName, count, args, runtime, *res);
#endif
  return std::move(*res);
}

std::optional<piper::Value> LynxModuleDarwin::createPromise(Runtime &runtime,
                                                            PromiseInvocationBlock invoke) {
  if (!invoke) {
    return piper::Value::undefined();
  }

  auto Promise = runtime.global().getPropertyAsFunction(runtime, "Promise");
  if (!Promise) {
    return std::optional<piper::Value>();
  }

  PromiseInvocationBlock invokeCopy = [invoke copy];
  piper::Function fn = piper::Function::createFromHostFunction(
      runtime, piper::PropNameID::forAscii(runtime, "fn"), 2,
      [invokeCopy, delegate = delegate_](piper::Runtime &rt, const piper::Value &thisVal,
                                         const piper::Value *args,
                                         size_t count) -> std::optional<piper::Value> {
        piper::Scope scope(rt);
        if (count != 2) {
          rt.reportJSIException(
              JSINativeException("Promise must pass constructor function two args. Passed " +
                                 std::to_string(count) + " args."));
          return std::optional<piper::Value>();
        }
        if (!invokeCopy) {
          return piper::Value::undefined();
        }
        int64_t resolveCallbackId =
            delegate->RegisterJSCallbackFunction(args[0].getObject(rt).getFunction(rt));
        int64_t rejectCallbackId =
            delegate->RegisterJSCallbackFunction(args[1].getObject(rt).getFunction(rt));
        if (resolveCallbackId == ModuleCallback::kInvalidCallbackId ||
            rejectCallbackId == ModuleCallback::kInvalidCallbackId) {
          LOGW("LynxModuleDarwin::create promise failed, LynxRuntime has destroyed");
          return piper::Value::undefined();
        }

        LOGV("LynxModuleDarwin::createPromise, resolve block id: "
             << resolveCallbackId << ", reject block id: " << rejectCallbackId);
        __block BOOL resolveWasCalled = NO;
        __block BOOL rejectWasCalled = NO;

        LynxPromiseResolveBlock resolveBlock = ^(id result) {
          if (rejectWasCalled) {
            LOGE("Tried to resolve a promise after it's already been rejected.");
            return;
          }
          if (resolveWasCalled) {
            LOGE("Tried to resolve a promise more than once.");
            return;
          }
          auto resolveCallback = std::make_shared<piper::ModuleCallbackDarwin>(resolveCallbackId);
          resolveCallback->argument = result;
          LOGV("LynxModule, LynxResolveBlock, put to JSThread id: " << resolveCallbackId);
          delegate->CallJSCallback(resolveCallback, rejectCallbackId);
        };
        LynxPromiseRejectBlock rejectBlock = ^(NSString *code, NSString *message) {
          if (resolveWasCalled) {
            LOGE("Tried to reject a promise after it's already been resolved.");
            return;
          }
          if (rejectWasCalled) {
            LOGE("Tried to reject a promise more than once.");
            return;
          }
          auto strongRejectWrapper =
              std::make_shared<piper::ModuleCallbackDarwin>(rejectCallbackId);
          NSDictionary *jsError = @{@"errorCode" : code, @"message" : message};
          strongRejectWrapper->argument = jsError;
          rejectWasCalled = YES;
          LOGV("LynxModule, LynxRejectBlock, put to JSThread id: " << rejectCallbackId);
          delegate->CallJSCallback(strongRejectWrapper, resolveCallbackId);
        };

        invokeCopy(rt, resolveBlock, rejectBlock);
        return piper::Value::undefined();
      });

  return Promise->callAsConstructor(runtime, fn);
}

#pragma mark - Functions Implementations.

NSString *convertJSIStringToNSString(Runtime &runtime, const piper::String &value) {
  return [NSString stringWithUTF8String:value.utf8(runtime).c_str()];
}

NSArray *convertJSIArrayToNSArray(Runtime &runtime, const piper::Array &value,
                                  std::vector<piper::Object> &pre_object_vector) {
  auto size = value.size(runtime);
  if (!size) {
    return nil;
  }

  Object obj_temp = piper::Value(runtime, value).getObject(runtime);
  if (CheckIsCircularJSObjectIfNecessaryAndReportError(runtime, obj_temp, pre_object_vector,
                                                       "convertJSIArrayToNSArray!")) {
    return nil;
  }
  // As Object is Movable, not copyable, do not push the Object you will use later to vector! You
  // need clone a new one.
  ScopedJSObjectPushPopHelper scoped_push_pop_helper(pre_object_vector, std::move(obj_temp));

  NSMutableArray *result = [NSMutableArray new];
  for (size_t i = 0; i < *size; i++) {
    // Insert kCFNull when it's `undefined` value to preserve the indices.
    auto item = value.getValueAtIndex(runtime, i);
    if (!item) {
      return nil;
    }
    [result
        addObject:convertJSIValueToObjCObject(runtime, *item, pre_object_vector) ?: (id)kCFNull];
  }
  return [result copy];
}

NSDictionary *convertJSIObjectToNSDictionary(Runtime &runtime, const piper::Object &value,
                                             std::vector<piper::Object> &pre_object_vector) {
  auto propertyNames = value.getPropertyNames(runtime);
  if (!propertyNames) {
    runtime.reportJSIException(JSINativeException(
        "There is error in convertJSIObjectToNSDictionary: getPropertyNames fail!"));
    // TODO(wujintian): return optional here.
    return nil;
  }
  auto size = (*propertyNames).size(runtime);
  if (!size) {
    return nil;
  }

  if (CheckIsCircularJSObjectIfNecessaryAndReportError(runtime, value, pre_object_vector,
                                                       "convertJSIObjectToNSDictionary!")) {
    return nil;
  }
  // As Object is Movable, not copyable, do not push the Object you will use
  // later to vector! You need clone a new one.
  ScopedJSObjectPushPopHelper scoped_push_pop_helper(pre_object_vector,
                                                     Value(runtime, value).getObject(runtime));

  NSMutableDictionary *result = [NSMutableDictionary new];
  for (size_t i = 0; i < *size; i++) {
    auto item = (*propertyNames).getValueAtIndex(runtime, i);
    if (!item) {
      return nil;
    }
    piper::String name = item->getString(runtime);
    NSString *k = convertJSIStringToNSString(runtime, name);
    auto js_obj = value.getProperty(runtime, name);
    if (!js_obj) {
      return nil;
    }
    id v = convertJSIValueToObjCObject(runtime, *js_obj, pre_object_vector);
    if (v) {
      result[k] = v;
    }
  }
  return [result copy];
}

NSData *convertJSIArrayBufferToNSData(Runtime &runtime, const piper::ArrayBuffer &value) {
  size_t size = value.size(runtime);
  if (@available(iOS 10.0, *)) {
    uint8_t *buffer = value.data(runtime);
    return [NSData dataWithBytes:buffer length:size];  // copy mode
  } else {
    size_t len = modp_b64_decode_len(modp_b64_encode_len(size));
    if (len < 0) {
      len = 0;
    }
    uint8_t *buffer = (uint8_t *)malloc(len);
    size_t result_len = value.copyData(runtime, buffer, len);
    if (result_len == 0) {
      free(buffer);
      return [NSData data];
    }
    return [NSData dataWithBytesNoCopy:buffer length:result_len];  // no copy mode
  }
}

std::optional<Value> PerformMethodInvocation(Runtime &runtime, NSInvocation *inv, const id module) {
  piper::Scope scope(runtime);
  TRACE_EVENT_BEGIN(LYNX_TRACE_CATEGORY_JSB, "Fire");
  const char *returnType = [[inv methodSignature] methodReturnType];
  void (^block)() = ^{
    [inv invokeWithTarget:module];
    if (returnType[0] == _C_VOID) {
      return;
    }
  };
  block();
  TRACE_EVENT_END(LYNX_TRACE_CATEGORY_JSB);

#ifndef GET_RETURN_VAULE_WITH
#define GET_RETURN_VAULE_WITH(type)     \
  type value_for_type;                  \
  [inv getReturnValue:&value_for_type]; \
  return piper::Value((double)value_for_type)
#endif

  TRACE_EVENT(LYNX_TRACE_CATEGORY_JSB, "ObjCValueToJSIValue");
  switch (returnType[0]) {
    case _C_VOID:
      return piper::Value::undefined();
    case _C_ID: {
      void *rawResult;
      [inv getReturnValue:&rawResult];
      id result = (__bridge id)rawResult;
      return convertObjCObjectToJSIValue(runtime, result);
    }
    case _C_SHT: {
      GET_RETURN_VAULE_WITH(short);
    }
    case _C_CHR: {
      GET_RETURN_VAULE_WITH(char);
    }
    case _C_UCHR: {
      GET_RETURN_VAULE_WITH(unsigned char);
    }
    case _C_USHT: {
      GET_RETURN_VAULE_WITH(unsigned short);
    }
    case _C_INT: {
      GET_RETURN_VAULE_WITH(int);
    }
    case _C_UINT: {
      GET_RETURN_VAULE_WITH(unsigned int);
    }
    case _C_LNG: {
      GET_RETURN_VAULE_WITH(long);
    }
    case _C_ULNG: {
      GET_RETURN_VAULE_WITH(unsigned long);
    }
    case _C_LNG_LNG: {
      GET_RETURN_VAULE_WITH(long long);
    }
    case _C_ULNG_LNG: {
      GET_RETURN_VAULE_WITH(unsigned long long);
    }
    case _C_BOOL: {
      GET_RETURN_VAULE_WITH(bool);
    }
    case _C_FLT: {
      GET_RETURN_VAULE_WITH(float);
    }
    case _C_DBL: {
      GET_RETURN_VAULE_WITH(double);
    }
  }
  LLogError(@"LynxModule, PerformMethodInvocation, returnType[0]: %c is an unknown type, return "
            @"undefined instead",
            returnType[0]);
  return piper::Value::undefined();
}

id convertJSIValueToObjCObject(Runtime &runtime, const piper::Value &value,
                               std::vector<piper::Object> &pre_object_vector) {
  piper::Scope scope(runtime);

  if (value.isUndefined() || value.isNull()) {
    return nil;
  }
  if (value.isBool()) {
    return @(value.getBool());
  }
  if (value.isNumber()) {
    return @(value.getNumber());
  }
  if (value.isString()) {
    return convertJSIStringToNSString(runtime, value.getString(runtime));
  }
  if (value.isObject()) {
    piper::Object o = value.getObject(runtime);
    if (o.hasProperty(runtime, BIG_INT_VAL)) {
      // such as {"id":8913891381287328398} will exsist on js
      // {"id":{"__lynx_val__":8913891381287328398}}, so we should convert its data structure.

      // In order to keep consistance of origin data structure as much as possible, when object
      // contains key named "__lynx_val__", it means that it is a BigInt Object, then we should
      // convert its value to "String".
      auto big_int_opt = o.getProperty(runtime, BIG_INT_VAL);
      if (!big_int_opt) {
        return nil;
      }
      auto big_int = big_int_opt->asString(runtime);
      if (big_int) {
        return convertJSIStringToNSString(runtime, *big_int);
      } else {
        runtime.reportJSIException(JSINativeException("try to get bigint from js value fail!"));
      }
    } else if (o.isArray(runtime)) {
      return convertJSIArrayToNSArray(runtime, o.getArray(runtime), pre_object_vector);
    } else if (o.isArrayBuffer(runtime)) {
      return convertJSIArrayBufferToNSData(runtime, o.getArrayBuffer(runtime));
    }
    return convertJSIObjectToNSDictionary(runtime, o, pre_object_vector);
  }
  LOGE("Must not reach here! Unsupported piper::piper::Value kind");
  return nil;
}

LynxCallbackBlock LynxModuleDarwin::ConvertJSIFunctionToCallback(
    Runtime &runtime, piper::Function function, const std::string &method_name,
    const piper::Value *first_arg, ModuleCallbackType type, uint64_t start_time,
    const piper::NativeModuleInfoCollectorPtr &timing_collector) {
  piper::Scope scope(runtime);
  int64_t callback_id = delegate_->RegisterJSCallbackFunction(std::move(function));

  LOGV("LynxModuleDarwin::ConvertJSIFunctionToCallback, |JS FUNCTION| id: "
       << callback_id << " " << name_ << "." << method_name);

  BOOL __block wrapperWasCalled = NO;
  // avoid ios block default capture this cause dangling pointer
  std::shared_ptr<ModuleDelegate> delegate(delegate_);

#if ENABLE_ARK_RECORDER
  if ([callback_stack_ count] != 0) {
    [[callback_stack_ lastObject] addObject:[[NSNumber alloc] initWithLongLong:callback_id]];
  }
  int64_t record_id = this->record_id_;
#endif
  // Some JSB implement such as XBridge will use first arg as JSB function name, so we need first
  // arg for tracing.
  __block std::string jsb_func_name;
  if (first_arg && first_arg->isString() &&
      [instance_ isKindOfClass:NSClassFromString(@"BDLynxBridgeModule")]) {
    jsb_func_name = first_arg->getString(runtime).utf8(runtime);
  }

  __block uint64_t start_time_copy = start_time;
  __block std::string module_name_copy = name_;
  __block std::string schema_copy = schema_;
  __block std::string method_name_copy = method_name;
  piper::NativeModuleInfoCollectorPtr timing_collector_copy = timing_collector;
  uint64_t callback_flow_id = lynx::base::tracing::GetFlowId();
  __block uint64_t callback_flow_id_copy = callback_flow_id;
  TRACE_EVENT_INSTANT(LYNX_TRACE_CATEGORY_JSB, "CreateJSB Callback",
                      [=](lynx::perfetto::EventContext ctx) {
                        ctx.event()->add_flow_ids(callback_flow_id);
                        auto *debug = ctx.event()->add_debug_annotations();
                        debug->set_name("startTimestamp");
                        debug->set_string_value(std::to_string(start_time));
                      });
  return ^(id response) {
    if (wrapperWasCalled) {
      LOGR("LynxModule, callback id: " << callback_id << " is called more than once.");
      if (timing_collector_copy != nullptr) {
        timing_collector_copy->OnErrorOccurred(NativeModuleStatusCode::FAILURE);
      }
      return;
    }

    std::shared_ptr<ModuleCallbackDarwin> wrapper;
    switch (type) {
      case ModuleCallbackType::Base:
        wrapper = std::make_shared<ModuleCallbackDarwin>(callback_id);
        break;
      case ModuleCallbackType::Request:
      case ModuleCallbackType::Fetch:
#if __ENABLE_LYNX_NET__
        wrapper = std::make_shared<network::ModuleCallbackRequest>(callback_id, type);
#endif
        break;
    }
    wrapper->SetModuleName(module_name_copy);
    wrapper->SetMethodName(method_name_copy);
    wrapper->SetFirstArg(jsb_func_name);
    wrapper->SetStartTimeMS(start_time_copy);
    wrapper->SetCallbackFlowId(callback_flow_id_copy);
    wrapperWasCalled = YES;
    wrapper->argument = response;
    wrapper->timing_collector_ = timing_collector_copy;
    if (base::LynxEnv::GetInstance().IsPiperMonitorEnabled() &&
        [response isKindOfClass:[NSDictionary class]] && ((NSDictionary *)response).count > 0) {
      std::ostringstream time_s;
      time_s << start_time_copy;
      base::LynxEnvDarwin::onPiperResponsed(
          module_name_copy, jsb_func_name.size() == 0 ? method_name_copy : jsb_func_name,
          schema_copy, response, time_s.str());
    }
    LOGV("LynxModule, LynxCallbackBlock, put function to JSThread, "
         << "callback id: " << callback_id << "piper::ModuleCallbackDarwin: " << wrapper);

#if ENABLE_ARK_RECORDER
    wrapper->SetRecordID(record_id);
#endif
    if (timing_collector_copy != nullptr) {
      timing_collector_copy->CallbackThreadSwitchStart();
    }
    delegate->CallJSCallback(wrapper);
  };
}

#if ENABLE_ARK_RECORDER
void LynxModuleDarwin::SetRecordID(int64_t record_id) { record_id_ = record_id; }

void LynxModuleDarwin::StartRecordFunction(const std::string &method_name) {
  [callback_stack_ addObject:[[NSMutableArray alloc] initWithCapacity:1]];
}

void LynxModuleDarwin::EndRecordFunction(const std::string &method_name, size_t count,
                                         const piper::Value *js_args, Runtime *rt,
                                         piper::Value &res) {
  if ([callback_stack_ count] != 0) {
    NSMutableArray *callbacks_current = [callback_stack_ lastObject];
    int callbacks_count = static_cast<uint32_t>(callbacks_current.count);
    std::unique_ptr<int64_t[]> callbacks;
    if (callbacks_count != 0) {
      callbacks = std::make_unique<int64_t[]>(callbacks_count);
      for (int32_t index = 0; index < callbacks_count; ++index) {
        callbacks.get()[index] = [[callbacks_current objectAtIndex:index] longLongValue];
      }
    }
    std::string moduleName = name_;
    // bridge Module will be redirect to the module LynxNetModule, So when recording, need to change
    // the name back
    if (moduleName == "__LynxNetwork") {
      moduleName = "bridge";
    }
    tasm::recorder::NativeModuleRecorder::RecordFunctionCall(
        moduleName.c_str(), method_name.c_str(), static_cast<uint32_t>(count), js_args,
        callbacks.get(), callbacks_count, res, rt, record_id_);
    [callback_stack_ removeLastObject];
  }
}
#endif
}  // namespace piper
}  // namespace lynx
