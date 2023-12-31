//
//  ADFGBridgeDefines.h
//  ADFGBridgeUnify
//
//  Modified from TTRexxar of muhuai.
//  Created by iCuiCui on 2020/04/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 这个宏用来保证注册时的native方法存在
 
 例：
 TTRegisterAllBridge(ADFGClassBridgeMethod(TTAppBridge, appInfo), @"app.getAppInfo");
 等价于
 TTRegisterAllBridge(@"TTAppBridge.appInfo", @"app.getAppInfo");
 
 当方法不存在时编译器会提示错误
 */
#define ADFGClassBridgeMethod(CLASS, METHOD) \
((void)(NO && ((void)[((CLASS *)(nil)) METHOD##WithParam:nil callback:nil engine:nil controller:nil], NO)), [NSString stringWithFormat:@"%@.%@", @(#CLASS), @(#METHOD)])


#define ADFGBRIDGE_CALLBACK_SUCCESS \
if (callback) {\
callback(ADFGBridgeMsgSuccess, @{}, nil);\
}\

#define ADFGBRIDGE_CALLBACK_FAILED \
if (callback) {\
callback(ADFGBridgeMsgFailed, @{}, nil);\
}\

#define ADFGBRIDGE_CALLBACK_FAILED_MSG(msg) \
if (callback) {\
callback(ADFGBridgeMsgFailed, @{@"msg": [NSString stringWithFormat:msg]? :@""}, nil);\
}\

#define ADFGBRIDGE_CALLBACK_WITH_MSG(status, msg) \
if (callback) {\
callback(status, @{@"msg": [NSString stringWithFormat:msg]? [NSString stringWithFormat:msg] :@""}, nil);\
}\

#ifndef ADFG_isEmptyString
#define ADFG_isEmptyString(str) (!str || ![str isKindOfClass:[NSString class]] || str.length == 0)
#endif

#ifndef adfg_dispatch_async_safe
#define adfg_dispatch_async_safe(queue, block)\
if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(queue)) {\
    block();\
} else {\
    dispatch_async(queue, block);\
}
#endif

#ifndef adfg_dispatch_async_main_thread_safe
#define adfg_dispatch_async_main_thread_safe(block) adfg_dispatch_async_safe(dispatch_get_main_queue(), block)
#endif

typedef NSString * ADFGBridgeName;

NS_ASSUME_NONNULL_END
