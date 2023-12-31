/// Copyright 2019 The Vmsdk Authors. All rights reserved.

#import "jsb/iOS/vmsdk_module_darwin.h"
#import <objc/message.h>
#import <objc/runtime.h>
#include <memory>
#import "basic/log/iOS/VLog.h"
//#include "basic/vmsdk_env.h"
#include "basic/trace_event/trace_event.h"
//#include "jsb/bindings/big_int/constants.h"
#include "basic/modp_b64/modp_b64.h"

namespace vmsdk {
namespace piper {

// namespace {
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

#pragma mark - Function Previous Declaration

static Napi::Value performMethodInvocation(Napi::Env env, NSInvocation *inv, const id module,
                                           NSMutableArray *retainedObjectsForInvocation);

#pragma mark - VmsdkModuleDarwin

VmsdkModuleDarwin::VmsdkModuleDarwin(id<JSModule> instance,
                                     const std::shared_ptr<ModuleDelegate> &delegate)
    : VmsdkModule(std::string([[[instance class] name] UTF8String]), delegate),
      instance_(instance) {
  methodLookup = [[instance class] methodLookup];
  buildLookupMap(methodLookup, methodMap_);
  if ([[instance class] respondsToSelector:@selector(attributeLookup)]) {
    attributeLookup = [[instance class] attributeLookup];
  }
}

void VmsdkModuleDarwin::Destroy() {}

Napi::Value VmsdkModuleDarwin::invokeMethod(const Napi::CallbackInfo &info) {
  auto res = info.Env().Undefined();
  MethodMetadata *method = reinterpret_cast<MethodMetadata *>(info.Data());
  int count = info.Length();
  if (method == nullptr) {
    VLOGE("VmsdkModule, module: %s failed in invokeMethod(), method is a nullptr", name_.c_str());
    return res;
  }

  const std::string &js_method_name = method->name;
  //  TRACE_EVENT(VMSDK_TRACE_CATEGORY_JSB, nullptr, [&](TraceEvent *event) {
  //   event->set_name("CallJSB:" + name_ + "." + jsMethodName);
  //   std::string first_str;
  //   if (count > 0 && info[0].IsString()) {
  //     // get the first arg
  //     first_str = info[0].As<Napi::String>().Utf8Value();
  //   }
  //    //   auto *debug = event->add_debug_annotations();
  //    //   debug->set_name("First Argument");
  //    //   debug->set_string_value(first_str);
  //  });
  // issue: #1510
  ErrCode callErrorCode = VMSDK_ERROR_CODE_SUCCESS;

  @try {
    NSString *jsMethodNameNSString = [NSString stringWithUTF8String:js_method_name.c_str()];
    if (methodLookup[jsMethodNameNSString] != nil) {
      std::string func_name = "";
      if (count >= 1 && info[0].IsString()) {
        func_name = info[0].As<Napi::String>().Utf8Value();
      }
      LOGV("VmsdkModuleDarwin  invokeMethod: " << method->name << " , args: " << func_name);
      SEL selector = NSSelectorFromString(methodLookup[jsMethodNameNSString]);
      res = invokeObjCMethod(info.Env(), js_method_name, selector, info, count, callErrorCode);
    } else {
      // clang-format off
     LOGE( "VmsdkModuleDarwin::invokeMethod module: " << name_
                << ", method: " << js_method_name
                << " failed in invokeMethod(), cannot find method in methodLookup: "
                << [[methodLookup description] UTF8String]);
      // clang-format on
    }
  } @catch (NSException *exception) {
    VLogError(@"Exception '%@' was thrown while invoking function %s on target "
              @"%@\ncallstack: %@",
              exception, method->name.c_str(), instance_, exception.callStackSymbols);
    // NSInvalidArgumentException is already handle in iOS.3
    callErrorCode = VMSDK_ERROR_CODE_MODULE_FUNC_CALL_EXCEPTION;
    // issue: #1510
    delegate_->OnErrorOccurred(VMSDK_ERROR_CODE_MODULE_FUNC_CALL_EXCEPTION, name_, js_method_name,
                               genExceptionErrorMessage(exception));
    delegate_->OnMethodInvoked(name_, js_method_name, VMSDK_ERROR_CODE_MODULE_FUNC_CALL_EXCEPTION);
  }
  return res;
}

NSInvocation *VmsdkModuleDarwin::getMethodInvocation(Napi::Env env, const id module,
                                                     const std::string &methodName, SEL selector,
                                                     const Napi::CallbackInfo &info, size_t count,
                                                     NSMutableArray *retainedObjectsForInvocation,
                                                     enum ErrCode &callErrorCode) {
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
    callErrorCode = VMSDK_ERROR_CODE_MODULE_FUNC_WRONG_ARG_TYPE;
    auto message =
        VmsdkModuleUtils::ExpectedButGotAtIndexError(expected, but_got, static_cast<int>(pos));
    delegate_->OnErrorOccurred(VMSDK_ERROR_CODE_MODULE_FUNC_WRONG_ARG_TYPE, name_, methodNameStr,
                               message);
  };
  // arg type
  const auto argTypeStr = [](const Napi::Value arg) {
    return VmsdkModuleUtils::JSTypeToString(arg);
  };
  TRACE_EVENT_BEGIN(VMSDK_TRACE_CATEGORY_JSB, "JSValueToObjCValue");
  // index: i + 2 ==> objc arguments: [this, _cmd, args..., resoledBlock,
  // rejectedBlock]
  for (size_t i = 0; i < count; i++) {
    const Napi::Value arg = info[i];
    const char *objCArgType = [methodSignature getArgumentTypeAtIndex:i + 2];

    // issue: #1510
    auto reportError = [i, expectedButGot, argTypeStr, arg](const std::string &expected) mutable {
      expectedButGot(i, expected, argTypeStr(arg));
    };
    NSNumber *num = nil;
    if (arg.IsBoolean()) {
      num = [NSNumber numberWithBool:arg.ToBoolean().Value()];
    } else if (arg.IsNumber()) {
      num = [NSNumber numberWithDouble:arg.ToNumber()];
    }

    if (objCArgType[0] == _C_ID) {
      id obj = nil;
      if (arg.IsBoolean()) {
        obj = [NSNumber numberWithBool:arg.ToBoolean().Value()];
      } else if (arg.IsNumber()) {
        obj = [NSNumber numberWithDouble:arg.ToNumber()];
      } else if (arg.IsNull()) {
        obj = nil;
      } else if (arg.IsString()) {
        obj = convertJSIStringToNSString(info.Env(), arg.As<Napi::String>());
      } else if (arg.IsObject()) {
        if (arg.IsArray()) {
          obj = convertJSIArrayToNSArray(info.Env(), arg.As<Napi::Array>());
        } else if (arg.IsFunction()) {
          LOGV("VmsdkModuleDarwin::getMethodInvocation, "
               << " module: " << name_ << " method: " << methodName
               << " |JS FUNCTION| found at argument " << i);
          obj = convertJSIFunctionToCallback(info.Env(), arg.As<Napi::Function>());
        } else if (arg.IsArrayBuffer()) {
          obj = convertJSIArrayBufferToNSData(info.Env(), arg.As<Napi::ArrayBuffer>());
        } else {
          obj = convertJSIObjectToNSDictionary(info.Env(), arg.As<Napi::Object>());
        }
      }
      if (obj != nil) {
        [objcParams addObject:obj];
        [inv setArgument:(void *)&obj atIndex:i + 2];
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
  TRACE_EVENT_END(VMSDK_TRACE_CATEGORY_JSB);
  return inv;
}

Napi::Value VmsdkModuleDarwin::invokeObjCMethod(Napi::Env env, const std::string &methodName,
                                                SEL selector, const Napi::CallbackInfo &info,
                                                size_t count, enum ErrCode &callErrorCode) {
  NSMutableArray *retainedObjectsForInvocation = [NSMutableArray arrayWithCapacity:count + 2];

  NSMethodSignature *methodSignature =
      [[instance_ class] instanceMethodSignatureForSelector:selector];
  NSUInteger argumentsCount = methodSignature.numberOfArguments;

  auto &inst = instance_;
  auto moduleNameStr = std::string{[NSStringFromClass([inst class]) UTF8String]};
  auto methodNameStr = std::string{[NSStringFromSelector(selector) UTF8String]};

  // issue: #1510
  // TODO: argumentsCount - 4 == count means this is a promise
  // THUS THIS ARGUMENT CHECK CANNOT DETECT IF __argumentsCount - 4 != count__
  // !!
  if (argumentsCount - 2 != count && argumentsCount - 4 != count) {
    // issue: #1510
    // if #arg is __MORE__, an exception will be thrown on parsing type of args,
    // thus the function will not be invoked
    callErrorCode = VMSDK_ERROR_CODE_MODULE_FUNC_WRONG_ARG_NUM;
    auto invokedErrorMessage = std::string{" invoked with wrong number of arguments, expected "}
                                   .append(std::to_string(argumentsCount - 2))
                                   .append(" but got ")
                                   .append(std::to_string(count))
                                   .append(".");
    delegate_->OnErrorOccurred(VMSDK_ERROR_CODE_MODULE_FUNC_WRONG_ARG_NUM, name_, methodNameStr,
                               invokedErrorMessage);
    if (argumentsCount - 2 < count) {
      delegate_->OnMethodInvoked(name_, methodNameStr, VMSDK_ERROR_CODE_MODULE_FUNC_WRONG_ARG_NUM);
      return env.Undefined();
    }
  }
  NSInvocation *inv = getMethodInvocation(info.Env(), instance_, methodName, selector, info, count,
                                          retainedObjectsForInvocation, callErrorCode);

  // TODO(gongkai): support promise
  if (argumentsCount - 4 == count) {
    LOGV("VmsdkModule, invokeObjCMethod, module: " << name_ << " method: " << methodName
                                                   << " is a promise");
    //    // objc arguments: [this, _cmd, args..., resoledBlock, rejectedBlock]
    //    return createPromise(*runtime, ^(Runtime &rt, VmsdkPromiseResolveBlock
    //    resolveBlock,
    //                                     VmsdkPromiseRejectBlock rejectBlock) {
    //      @try {
    //        [inv setArgument:(void *)&resolveBlock atIndex:count + 2];
    //        [inv setArgument:(void *)&rejectBlock atIndex:count + 3];
    //        [retainedObjectsForInvocation addObject:resolveBlock];
    //        [retainedObjectsForInvocation addObject:rejectBlock];
    //        performMethodInvocation(rt, inv, instance_,
    //        retainedObjectsForInvocation);
    //        // issue: #1510
    //        LOGV("VmsdkModuleDarwin::invokeObjCMethod, module: "
    //             << name_ << " method: " << methodName << " |PROMISE|, did
    //             performMethodInvocation");
    //        delegate_->OnMethodInvoked(name_, methodNameStr, callErrorCode);
    //      } @catch (NSException *exception) {
    //        LLogError(
    //            @"Exception '%@' was thrown while invoking function %s on
    //            target %@\ncallstack: %@", exception, methodNameStr.c_str(),
    //            instance_, exception.callStackSymbols);
    //        // issue: #1510
    //        delegate_->OnMethodInvoked(name_, methodNameStr,
    //                                   VMSDK_ERROR_CODE_MODULE_FUNC_CALL_EXCEPTION);
    //        delegate_->OnErrorOccurred(VMSDK_ERROR_CODE_MODULE_FUNC_CALL_EXCEPTION,
    //        name_, methodNameStr,
    //                                   genExceptionErrorMessage(exception));
    //      }
    //    });
  }
  // issue: #1510
  auto res = performMethodInvocation(info.Env(), inv, instance_, retainedObjectsForInvocation);
  LOGV("VmsdkModuleDarwin::invokeObjCMethod, module: " << name_ << " method: " << methodName
                                                       << " did performMethodInvocation");
  TRACE_EVENT(VMSDK_TRACE_CATEGORY_JSB, "OnMethodInvoked");
  delegate_->OnMethodInvoked(name_, methodNameStr, callErrorCode);
  return res;
}

Napi::Value VmsdkModuleDarwin::createPromise(Napi::Env env, PromiseInvocationBlock invoke) {
  return Napi::Value();
  //  if (!invoke) {
  //    return piper::Value::undefined();
  //  }
  //
  //  piper::Function Promise = runtime.global().getPropertyAsFunction(runtime,
  //  "Promise");
  //
  //  PromiseInvocationBlock invokeCopy = [invoke copy];
  //  piper::Function fn = piper::Function::createFromHostFunction(
  //      runtime, piper::PropNameID::forAscii(runtime, "fn"), 2,
  //      [invokeCopy, delegate = delegate_](piper::Runtime &rt, const
  //      piper::Value &thisVal,
  //                                         const piper::Value *args, size_t
  //                                         count) {
  //        if (count != 2) {
  //          throw std::invalid_argument("Promise must pass constructor
  //          function two args. Passed " +
  //                                      std::to_string(count) + " args.");
  //        }
  //        if (!invokeCopy) {
  //          return piper::Value::undefined();
  //        }
  //        int64_t resolveCallbackId =
  //            delegate->RegisterJSCallbackFunction(args[0].getObject(rt).getFunction(rt));
  //        int64_t rejectCallbackId =
  //            delegate->RegisterJSCallbackFunction(args[1].getObject(rt).getFunction(rt));
  //        if (resolveCallbackId == ModuleCallback::kInvalidCallbackId ||
  //            rejectCallbackId == ModuleCallback::kInvalidCallbackId) {
  //          LOGW("VmsdkModuleDarwin::create promise failed, VmsdkRuntime has
  //          destoyed"); return piper::Value::undefined();
  //        }
  //
  //        LOGV("VmsdkModuleDarwin::createPromise, resolve block id: "
  //             << resolveCallbackId << ", reject block id: " <<
  //             rejectCallbackId);
  //        __block BOOL resolveWasCalled = NO;
  //        __block BOOL rejectWasCalled = NO;
  //
  //        VmsdkPromiseResolveBlock resolveBlock = ^(id result) {
  //          if (rejectWasCalled) {
  //            throw std::runtime_error(
  //                "Tried to resolve a promise after it's already been
  //                rejected.");
  //          }
  //          if (resolveWasCalled) {
  //            throw std::runtime_error("Tried to resolve a promise more than
  //            once.");
  //          }
  //          auto resolveCallback =
  //          std::make_shared<piper::ModuleCallbackDarwin>(resolveCallbackId);
  //          resolveCallback->argument = result;
  //          LOGV("VmsdkModule, VmsdkResolveBlock, put to JSThread id: " <<
  //          resolveCallbackId); delegate->CallJSCallback(resolveCallback,
  //          rejectCallbackId);
  //        };
  //        VmsdkPromiseRejectBlock rejectBlock = ^(NSString *code, NSString
  //        *message) {
  //          if (resolveWasCalled) {
  //            throw std::runtime_error("Tried to reject a promise after it's
  //            already been resolved.");
  //          }
  //          if (rejectWasCalled) {
  //            throw std::runtime_error("Tried to reject a promise more than
  //            once.");
  //          }
  //          auto strongRejectWrapper =
  //              std::make_shared<piper::ModuleCallbackDarwin>(rejectCallbackId);
  //          NSDictionary *jsError = @{@"errorCode" : code, @"message" :
  //          message}; strongRejectWrapper->argument = jsError; rejectWasCalled
  //          = YES; LOGV("VmsdkModule, VmsdkRejectBlock, put to JSThread id: " <<
  //          rejectCallbackId); delegate->CallJSCallback(strongRejectWrapper,
  //          resolveCallbackId);
  //        };
  //
  //        invokeCopy(rt, resolveBlock, rejectBlock);
  //        return piper::Value::undefined();
  //      });
  //
  //  return Promise.callAsConstructor(runtime, fn);
}

void VmsdkModuleDarwin::buildLookupMap(
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
    auto darwinModule = std::make_shared<MethodMetadata>(msig.numberOfArguments - 2, method, this);
    map[method] = darwinModule;
  }
}

#pragma mark - Functions Implementations.

NSString *convertJSIStringToNSString(Napi::Env env, const Napi::String &value) {
  return [NSString stringWithUTF8String:value.Utf8Value().c_str()];
}

NSArray *convertJSIArrayToNSArray(Napi::Env env, const Napi::Array &value) {
  size_t size = value.Length();
  NSMutableArray *result = [NSMutableArray new];
  for (size_t i = 0; i < size; i++) {
    // Insert kCFNull when it's `undefined` value to preserve the indices.
    [result addObject:convertJSIValueToObjCObject(env, value.Get(i)) ?: (id)kCFNull];
  }
  return [result copy];
}

NSDictionary *convertJSIObjectToNSDictionary(Napi::Env env, const Napi::Object &value) {
  Napi::Array propertyNames = value.GetPropertyNames();
  size_t size = propertyNames.Length();
  NSMutableDictionary *result = [NSMutableDictionary new];
  for (size_t i = 0; i < size; i++) {
    Napi::String name = propertyNames.Get(i).As<Napi::String>();
    NSString *k = convertJSIStringToNSString(env, name);
    id v = convertJSIValueToObjCObject(env, value.Get(name));
    if (v) {
      result[k] = v;
    }
  }
  return [result copy];
}

NSData *convertJSIArrayBufferToNSData(Napi::Env env, const Napi::ArrayBuffer &value) {
  Napi::ArrayBuffer buff = value.As<Napi::ArrayBuffer>();
  size_t size = buff.ByteLength();
  if (@available(iOS 10.0, *)) {
    uint8_t *buffer = (uint8_t *)buff.Data();
    return [NSData dataWithBytes:buffer length:size];  // copy mode
  } else {
    size_t len = modp_b64_decode_len(modp_b64_encode_len(size));
    if (len < 0) {
      len = 0;
    }
    uint8_t *buffer = (uint8_t *)malloc(len);
    memcpy(buffer, buff.Data(), len);
    if (len == 0) {
      free(buffer);
      return [NSData data];
    }
    return [NSData dataWithBytesNoCopy:buffer length:len];  // no copy mode
  }
  return NULL;
}

static Napi::Value performMethodInvocation(Napi::Env env, NSInvocation *inv, const id module,
                                           NSMutableArray *retainedObjectsForInvocation) {
  TRACE_EVENT_BEGIN(VMSDK_TRACE_CATEGORY_JSB, "Fire");
  const char *returnType = [[inv methodSignature] methodReturnType];
  void (^block)() = ^{
    [inv invokeWithTarget:module];
    if (returnType[0] == _C_VOID) {
      return;
    }
  };
  block();
  TRACE_EVENT_END(VMSDK_TRACE_CATEGORY_JSB);

#ifndef GET_RETURN_VAULE_WITH
#define GET_RETURN_VAULE_WITH(type)     \
  type value_for_type;                  \
  [inv getReturnValue:&value_for_type]; \
  return Napi::Number::New(env, (double)value_for_type)
#endif

  TRACE_EVENT(VMSDK_TRACE_CATEGORY_JSB, "ObjCValueToJSIValue");
  switch (returnType[0]) {
    case _C_VOID:
      return env.Undefined();
    case _C_ID: {
      void *rawResult;
      [inv getReturnValue:&rawResult];
      id result = (__bridge id)rawResult;
      return convertObjCObjectToJSIValue(env, result);
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
  VLogError(@"VmsdkModule, performMethodInvocation, returnType[0]: %c is an "
            @"unknown type, return "
            @"undefined instead",
            returnType[0]);
  return env.Undefined();
}

id convertJSIValueToObjCObject(Napi::Env env, const Napi::Value &value) {
  if (value.IsUndefined() || value.IsNull()) {
    return nil;
  }
  if (value.IsBoolean()) {
    return @(value.ToBoolean().Value());
  }
  if (value.IsNumber()) {
    return @(value.ToNumber().DoubleValue());
  }
  if (value.IsString()) {
    return convertJSIStringToNSString(env, value.As<Napi::String>());
  }
  if (value.IsObject()) {
    //    if (value.has(runtime, BIG_INT_VAL)) {
    //      // such as {"id":8913891381287328398} will exsist on js
    //      // {"id":{"__vmsdk_val__":8913891381287328398}}, so we should convert
    //      its data structure.
    //
    //      // In order to keep consistance of origin data structure as much as
    //      possible, when object
    //      // contains key named "__vmsdk_val__", it means that it is a BigInt
    //      Object, then we should
    //      // convert its value to "String".
    //      return convertJSIStringToNSString(runtime,
    //                                        value.getProperty(runtime,
    //                                        BIG_INT_VAL).asString(runtime));
    //    } else
    if (value.IsArray()) {
      return convertJSIArrayToNSArray(env, value.As<Napi::Array>());
    } else if (value.IsArrayBuffer()) {
      return convertJSIArrayBufferToNSData(env, value.As<Napi::ArrayBuffer>());
    }
    return convertJSIObjectToNSDictionary(env, value.As<Napi::Object>());
  }

  throw std::runtime_error("Unsupported piper::piper::Value kind");
}

JSModuleCallbackBlock piper::VmsdkModuleDarwin::convertJSIFunctionToCallback(
    Napi::Env env, const Napi::Function &function) {
  int64_t callback_id = delegate_->RegisterJSCallbackFunction(std::move(function));
  BOOL __block wrapperWasCalled = NO;

  // avoid ios block default capture this cause dangling pointer
  std::shared_ptr<ModuleDelegate> delegate(delegate_);
  std::string name = name_;

  return ^(id response) {
    if (wrapperWasCalled) {
      LOGE("VmsdkModuleDarwin, callback id: " << callback_id << " is called more than once.");
      return;
    }

    if (!delegate->IsRunning()) {
      LOGE("VmsdkModuleDarwin, IsRunning: false, callback id: " << callback_id);
      return;
    }

    auto wrapper = std::make_shared<ModuleCallbackDarwin>(callback_id, name, delegate);

    wrapperWasCalled = YES;
    wrapper->argument = response;
    LOGV("VmsdkModuleDarwin, VmsdkCallbackBlock, put function to JSThread, "
         << "callback id: " << callback_id << "piper::ModuleCallbackDarwin: " << wrapper);

    delegate->CallJSCallback(wrapper);
  };
}

}
}
