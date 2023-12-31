// Copyright 2021 The Lynx Authors. All rights reserved.

#include "lynx_lepus_module_darwin.h"

#import <objc/message.h>
#import <objc/runtime.h>
#import "LynxContext+Internal.h"
#import "LynxContextModule.h"
#import "LynxLog.h"
#import "LynxTemplateData+Converter.h"
#import "TemplateRenderCallbackProtocol.h"

#include "base/debug/lynx_assert.h"
#include "jsbridge/ios/piper/lynx_module_manager_darwin.h"
#include "ssr/dom_reconstruct_utils.h"
#include "tasm/react/ios/lepus_value_converter.h"
#include "tasm/template_assembler.h"
#include "tasm/value_utils.h"

#define kLepusObjcArrayKey @"objcArray"
#define kLepusObjcModuleKey @"module"
#define kLepusObjcJSBMethodKey @"method"
#define kLepusObjcLepusMethodKey @"lepusMethod"
#define kLepusObjcMethodArgusKey @"methodArgus"
#define kLepusObjcCallMethod @"call"

namespace lynx {
namespace piper {

id<LynxModule> GetLynxModuleInstance(id<TemplateRenderCallbackProtocol> render, Class aClass,
                                     id param) {
  __strong id<TemplateRenderCallbackProtocol> _render = render;
  id<LynxModule> instance = [(Class)aClass alloc];
  if ([instance conformsToProtocol:@protocol(LynxContextModule)]) {
    if (param != nil && [instance respondsToSelector:@selector(initWithLynxContext:WithParam:)]) {
      instance = [(id<LynxContextModule>)instance initWithLynxContext:[_render getLynxContext]
                                                            WithParam:param];
    } else {
      instance = [(id<LynxContextModule>)instance initWithLynxContext:[_render getLynxContext]];
    }
  } else if (param != nil && [instance respondsToSelector:@selector(initWithParam:)]) {
    instance = [instance initWithParam:param];
  } else {
    instance = [instance init];
  }
  return instance;
}

void ReportInvArgusError(char type, id<TemplateRenderCallbackProtocol> render) {
  switch (type) {
    case _C_CHR:
      [render onErrorOccurred:LYNX_ERROR_CODE_LEPUS_MODULE_ARGUS_ERROR message:@"short"];
      break;
    case _C_UCHR:
      [render onErrorOccurred:LYNX_ERROR_CODE_LEPUS_MODULE_ARGUS_ERROR message:@"unsigned char"];
      break;
    case _C_SHT:
      [render onErrorOccurred:LYNX_ERROR_CODE_LEPUS_MODULE_ARGUS_ERROR message:@"short"];
      break;
    case _C_USHT:
      [render onErrorOccurred:LYNX_ERROR_CODE_LEPUS_MODULE_ARGUS_ERROR message:@"unsigned short"];
      break;
    case _C_INT:
      [render onErrorOccurred:LYNX_ERROR_CODE_LEPUS_MODULE_ARGUS_ERROR message:@"int"];
      break;
    case _C_UINT:
      [render onErrorOccurred:LYNX_ERROR_CODE_LEPUS_MODULE_ARGUS_ERROR message:@"unsigned int"];
      break;
    case _C_LNG:
      [render onErrorOccurred:LYNX_ERROR_CODE_LEPUS_MODULE_ARGUS_ERROR message:@"long"];
      break;
    case _C_ULNG:
      [render onErrorOccurred:LYNX_ERROR_CODE_LEPUS_MODULE_ARGUS_ERROR message:@"unsigned long"];
      break;
    case _C_LNG_LNG:
      [render onErrorOccurred:LYNX_ERROR_CODE_LEPUS_MODULE_ARGUS_ERROR message:@"long long"];
      break;
    case _C_ULNG_LNG:
      [render onErrorOccurred:LYNX_ERROR_CODE_LEPUS_MODULE_ARGUS_ERROR
                      message:@"unsigned long long"];
      break;
    case _C_BOOL:
      [render onErrorOccurred:LYNX_ERROR_CODE_LEPUS_MODULE_ARGUS_ERROR message:@"bool"];
      break;
    case _C_DBL:
      [render onErrorOccurred:LYNX_ERROR_CODE_LEPUS_MODULE_ARGUS_ERROR message:@"double"];
      break;
    case _C_FLT:

      [render onErrorOccurred:LYNX_ERROR_CODE_LEPUS_MODULE_ARGUS_ERROR message:@"float"];
      break;
    default:
      [render onErrorOccurred:LYNX_ERROR_CODE_LEPUS_MODULE_ARGUS_ERROR
                      message:@"unknown number type"];
      break;
  }
}

NSInvocation* SetArgusToMethodInvocation(int i, id arg, char type, NSInvocation* inv) {
  __strong NSInvocation* _inv = inv;
  switch (type) {
    case _C_CHR: {
      char c = [arg charValue];
      [_inv setArgument:(void*)&c atIndex:i];
    } break;
    case _C_UCHR: {
      unsigned char uc = [arg unsignedCharValue];
      [_inv setArgument:(void*)&uc atIndex:i];
    } break;
    case _C_SHT: {
      short s = [arg shortValue];
      [_inv setArgument:(void*)&s atIndex:i];
    } break;
    case _C_USHT: {
      unsigned short us = [arg unsignedShortValue];
      [_inv setArgument:(void*)&us atIndex:i];
    } break;
    case _C_INT: {
      int ii = [arg intValue];
      [_inv setArgument:(void*)&ii atIndex:i];
    } break;
    case _C_UINT: {
      unsigned int ui = [arg unsignedIntValue];
      [_inv setArgument:(void*)&ui atIndex:i];
    } break;
    case _C_LNG: {
      long l = [arg longValue];
      [_inv setArgument:(void*)&l atIndex:i];
    } break;
    case _C_ULNG: {
      unsigned long ul = [arg unsignedLongValue];
      [_inv setArgument:(void*)&ul atIndex:i];
    } break;
    case _C_LNG_LNG: {
      long long ll = [arg longLongValue];
      [_inv setArgument:(void*)&ll atIndex:i];
    } break;
    case _C_ULNG_LNG: {
      unsigned long long ull = [arg unsignedLongLongValue];
      [_inv setArgument:(void*)&ull atIndex:i];
    } break;
    case _C_BOOL: {
      BOOL b = [arg boolValue];
      [_inv setArgument:(void*)&b atIndex:i];
    } break;
    case _C_FLT: {
      float f = [arg floatValue];
      [_inv setArgument:(void*)&f atIndex:i];
    } break;
    case _C_DBL: {
      double d = [arg doubleValue];
      [_inv setArgument:(void*)&d atIndex:i];
    } break;
  }
  return _inv;
}

lepus::Value GetObjcReturnValue(char type, NSInvocation* inv) {
#ifndef GET_RETURN_VAULE_WITH
#define GET_RETURN_VAULE_WITH(type)     \
  type value_for_type;                  \
  [inv getReturnValue:&value_for_type]; \
  return lepus::Value((double)value_for_type)
#endif
  switch (type) {
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
  return lepus::Value();
}

NSDictionary* GetMethodDetailParams(const std::string& js_method_name, const lepus::Value& args,
                                    const std::vector<lepus::String>& sortedParamsKey) {
  NSMutableDictionary* resolvedDict = [NSMutableDictionary dictionary];
  [resolvedDict setValue:[NSString stringWithUTF8String:js_method_name.c_str()]
                  forKey:kLepusObjcLepusMethodKey];
  NSMutableArray* objcArray = [[NSMutableArray alloc] init];
  if (args.GetLength() > 0) {
    // index: i + 2 ==> objc arguments: [this, _cmd, args..., callback]
    auto resolvedFunc = [&objcArray, &resolvedDict](const lepus::Value& key,
                                                    const lepus::Value& arg) {
      id obj = tasm::convertLepusValueToNSObject(arg);
      if (obj != nil) {
        [objcArray addObject:obj];
        if ([obj isKindOfClass:[NSDictionary class]] &&
            [((NSDictionary*)obj) objectForKey:kLepusObjcModuleKey]) {
          [resolvedDict setValue:obj ?: @"" forKey:kLepusObjcMethodArgusKey];
          [resolvedDict setValue:[((NSDictionary*)obj) objectForKey:kLepusObjcModuleKey] ?: @""
                          forKey:kLepusObjcModuleKey];
          [resolvedDict setValue:[((NSDictionary*)obj) objectForKey:kLepusObjcJSBMethodKey] ?: @""
                          forKey:kLepusObjcJSBMethodKey];
        }
      }
    };
    if (!sortedParamsKey.empty()) {
      for (auto iter = sortedParamsKey.begin(); iter != sortedParamsKey.end(); ++iter) {
        if (!args.GetProperty(*iter).IsNil()) {
          resolvedFunc(lepus::Value(*iter->c_str()), args.GetProperty(*iter));
        }
      }
    } else {
      tasm::ForEachLepusValue(args, std::move(resolvedFunc));
    }

    [resolvedDict setValue:objcArray ?: @[] forKey:kLepusObjcArrayKey];
  }
  return [resolvedDict copy];
}

NSDictionary* GetMethodDetailParamsForAir(const std::string& js_method_name,
                                          const lepus::Value& args) {
  constexpr const static char* kEventDetail = "methodDetail";
  constexpr const static char* kEventCallbackId = "callbackId";
  constexpr const static char* kEventComponentId = "componentId";
  constexpr const static char* kEventEntryName = "tasmEntryName";
  static const std::vector<lepus::String> sortedParamsKey = {
      lepus::String(kEventEntryName), lepus::String(kEventCallbackId),
      lepus::String(kEventComponentId), lepus::String(kEventDetail)};

  NSMutableDictionary* resolvedDict = [NSMutableDictionary dictionary];
  [resolvedDict setValue:[NSString stringWithUTF8String:js_method_name.c_str()]
                  forKey:kLepusObjcLepusMethodKey];
  return GetMethodDetailParams(js_method_name, args, sortedParamsKey);
}

NSInvocation* PrepareMethodInv(id<LynxModule> instance, Class aClass,
                               id<TemplateRenderCallbackProtocol> render, NSDictionary* invDict,
                               bool isAsync) {
  SEL selector = NSSelectorFromString([aClass methodLookup][invDict[kLepusObjcLepusMethodKey]]);
  NSMutableArray* objcParamsArray = [NSMutableArray arrayWithArray:invDict[kLepusObjcArrayKey]];
  NSMethodSignature* methodSignature =
      [[instance class] instanceMethodSignatureForSelector:selector];
  NSInvocation* inv = [NSInvocation invocationWithMethodSignature:methodSignature];
  [inv setSelector:selector];

  static char string_key;
  objc_setAssociatedObject(inv, &string_key, invDict[kLepusObjcArrayKey], OBJC_ASSOCIATION_RETAIN);

  if (methodSignature.numberOfArguments > 2) {
    // async index: i = 2 ==> objc arguments: [this, _cmd, bridge_mehtod, args..., callback]
    // sync index: i = 2 ==> objc arguments: [this, _cmd, args...]
    // param async => entry_name, callback_id, bridge_method, args
    // param sync => entry_name, callback_id, args
    // callback will be added & injected in async func
    if (((methodSignature.numberOfArguments - objcParamsArray.count == 2) && isAsync) ||
        ((methodSignature.numberOfArguments - objcParamsArray.count == 1) && !isAsync)) {
      // Compatible with Lynx piper bridge call method or other async method
      [objcParamsArray insertObject:invDict[kLepusObjcJSBMethodKey] ?: @"__Method__" atIndex:2];
    }
    for (int i = 2; (NSUInteger)i < methodSignature.numberOfArguments; i++) {
      const char* objCArgType = [methodSignature getArgumentTypeAtIndex:i];
      if ((NSUInteger)i + (isAsync ? 1 : 0) > objcParamsArray.count) {
        // params out of range
        continue;
      }
      id arg = objcParamsArray[i];
      if (objCArgType[0] == _C_ID) {
        if (arg != nil) {
          [inv setArgument:(void*)&arg atIndex:i];
          continue;
        } else {
          // arg == nil or need to inject callback
          if (!((i - objcParamsArray.count == 0))) {
            [render onErrorOccurred:LYNX_ERROR_CODE_LEPUS_MODULE_ARGUS_ERROR
                            message:@"sub class of NSObject"];
          }
          continue;
        }
      } else {
        if (arg == nil) {
          ReportInvArgusError(objCArgType[0], render);
        }
        inv = SetArgusToMethodInvocation(i, arg, objCArgType[0], inv);
      }
    }
  }
  return inv;
}

void InvokeObjcMethod(NSInvocation* inv, id<TemplateRenderCallbackProtocol> render,
                      id<LynxModule> instance, NSDictionary* invDict) {
  [inv invokeWithTarget:instance];
  [render didInvokeMethod:invDict[kLepusObjcLepusMethodKey]
                 inModule:invDict[kLepusObjcModuleKey]
                errorCode:LYNX_ERROR_CODE_LEPUS_SUCCESS];
}

lepus::Value InvokeLepusMethodSync(NSInvocation* inv, id<TemplateRenderCallbackProtocol> render,
                                   NSDictionary* invDict) {
  const char* returnType = [[inv methodSignature] methodReturnType];
  if (returnType[0] == _C_ID) {
    void* rawResult;
    [inv getReturnValue:&rawResult];
    id result = (__bridge id)rawResult;
    return LynxConvertToLepusValue(result);
  } else {
    return GetObjcReturnValue(returnType[0], inv);
  }
}

void InvokeLepusMethodAsync(NSInvocation* inv, id<TemplateRenderCallbackProtocol> render,
                            id<LynxModule> instance, NSDictionary* invDict) {
  __strong NSInvocation* _inv = inv;
  __strong NSObject<LynxModule>* _instance = instance;
  __block NSMutableArray* objcParamsArray =
      [NSMutableArray arrayWithArray:[invDict objectForKey:kLepusObjcArrayKey]];
  // hold the callback for block
  bool needsCallback = _inv.methodSignature.numberOfArguments - objcParamsArray.count == 2;
  if (needsCallback) {
    __weak __typeof(render) weakRender = render;
    LynxCallbackBlock callback = ^void(id result) {
      // Methods from piper do not require callbacks
      if ([[objcParamsArray firstObject] isKindOfClass:NSNumber.class] &&
          ((NSNumber*)[objcParamsArray firstObject]).boolValue) {
        return;
      }
      __block NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:result];
      [dict addEntriesFromDictionary:@{@"entry_name" : [objcParamsArray objectAtIndex:0]}];
      dispatch_async(dispatch_get_main_queue(), ^{
        [weakRender invokeLepusFunc:[dict copy]
                         callbackID:[[objcParamsArray objectAtIndex:1] intValue]];
      });
    };
    [objcParamsArray addObject:callback];
    // set callback to target position
    NSUInteger i = _inv.methodSignature.numberOfArguments - 1;
    id arg = [objcParamsArray objectAtIndex:i - 1];
    [_inv setArgument:(void*)&arg atIndex:i];
  }
  InvokeObjcMethod(_inv, render, _instance, invDict);
}

lepus::Value InvokeMethod(NSInvocation* inv, NSMutableArray* objcParamsArray,
                          id<TemplateRenderCallbackProtocol> render, id<LynxModule> instance,
                          NSDictionary* invDict) {
  const char* returnType = [[inv methodSignature] methodReturnType];
  if (returnType[0] == _C_VOID) {
    return lepus::Value();
  } else {
    InvokeObjcMethod(inv, render, instance, invDict);
    return InvokeLepusMethodSync(inv, render, invDict);
  }
}

void InvokeMethodAsync(NSInvocation* inv, id<TemplateRenderCallbackProtocol> render,
                       id<LynxModule> instance, NSDictionary* invDict) {
  const char* returnType = [[inv methodSignature] methodReturnType];
  __strong NSInvocation* _inv = inv;
  __strong id<LynxModule> _instance = instance;
  if (returnType[0] == _C_VOID) {
    InvokeLepusMethodAsync(_inv, render, _instance, invDict);
  }
}

void TriggerLepusMethodAsync(const std::string& _js_method_name, const lepus::Value& _args,
                             id<TemplateRenderCallbackProtocol> render_) {
  lepus::Value args_ = ssr::FormatEventArgsForIOS(_js_method_name, _args);
  __block lepus::Value args = args_;
  __block std::string js_method_name = _js_method_name;
  __block id<TemplateRenderCallbackProtocol> _render = render_;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    __strong id<TemplateRenderCallbackProtocol> render = _render;
    NSMutableDictionary<NSString*, id>* modulesClasses_ = [render getLepusModulesClasses];
    NSDictionary* resolvedParams = [render_ enableAirStrictMode]
                                       ? GetMethodDetailParamsForAir(js_method_name, args)
                                       : GetMethodDetailParams(js_method_name, args, {});
    if ([resolvedParams objectForKey:kLepusObjcModuleKey] == nil) {
      return;
    }
    LynxModuleWrapper* wrapper = modulesClasses_[[resolvedParams objectForKey:kLepusObjcModuleKey]];
    if (wrapper == nil) {
      return;
    }
    Class<LynxModule> aClass = wrapper.moduleClass;
    id param = wrapper.param;
    if (aClass == nil) {
      return;
    }
    id<LynxModule> instance = GetLynxModuleInstance(_render, aClass, param);
    if (!instance) {
      return;
    }
    if ([aClass methodLookup][resolvedParams[kLepusObjcLepusMethodKey]] == nil) {
      return;
    }
    NSInvocation* inv = PrepareMethodInv(instance, aClass, render, resolvedParams, YES);
    InvokeMethodAsync(inv, render, instance, resolvedParams);
  });
}

lepus::Value TriggerLepusMethod(const std::string& js_method_name, const lepus::Value& args,
                                id<TemplateRenderCallbackProtocol> _render) {
  __strong id<TemplateRenderCallbackProtocol> render = _render;
  NSMutableDictionary<NSString*, id>* modulesClasses_ = [render getLepusModulesClasses];
  NSDictionary* resolvedParams = [render enableAirStrictMode]
                                     ? GetMethodDetailParamsForAir(js_method_name, args)
                                     : GetMethodDetailParams(js_method_name, args, {});

  if ([resolvedParams objectForKey:kLepusObjcArrayKey] == nil) {
    return lepus::Value();
  }
  LynxModuleWrapper* wrapper = modulesClasses_[[resolvedParams objectForKey:kLepusObjcModuleKey]];
  if (wrapper == nil) {
    return lepus::Value();
  }
  Class<LynxModule> aClass = wrapper.moduleClass;
  id param = wrapper.param;
  if (aClass == nil) {
    return lepus::Value();
  }
  id<LynxModule> instance = GetLynxModuleInstance(_render, aClass, param);
  if (!instance) {
    return lepus::Value();
  }
  if ([aClass methodLookup][[resolvedParams objectForKey:kLepusObjcLepusMethodKey]] == nil) {
    return lepus::Value();
  }
  NSInvocation* inv = PrepareMethodInv(instance, aClass, render, resolvedParams, NO);
  lepus::Value val = InvokeMethod(inv, [resolvedParams objectForKey:kLepusObjcArrayKey], render,
                                  instance, resolvedParams);
  if (!val.IsNil()) {
    return val;
  }
  const char* returnType = [[inv methodSignature] methodReturnType];
  LLogError(@"LynxModule, performMethodInvocation, returnType[0]: %c is an unknown type, return "
            @"undefined instead",
            returnType[0]);
  return lepus::Value();
}
}  // namespace piper
}  // namespace lynx
