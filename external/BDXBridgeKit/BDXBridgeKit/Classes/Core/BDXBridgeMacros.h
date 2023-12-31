//
//  BDXBridgeMacros.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/6/8.
//

#import <Foundation/Foundation.h>
#import <BDAlogProtocol/BDAlogProtocol.h>

NS_ASSUME_NONNULL_BEGIN

#if DEBUG
#define bdx_keywordify autoreleasepool {}
#else
#define bdx_keywordify try {} @catch (...) {}
#endif

#ifndef weakify
#define weakify(var) bdx_keywordify __weak __typeof__(var) _weak_ ## var = (var)
#endif

#ifndef strongify
#define strongify(var) bdx_keywordify __strong __typeof__(var) var = (_weak_ ## var)
#endif

#ifndef bdx_invoke_block
#define bdx_invoke_block(block, ...) !block ?: block(__VA_ARGS__)
#endif

#define BDX_BRIDGE_SEGMENT "__DATA"

#define bdx_bridge_register_global_method(method, sect) \
    __attribute((used, section(BDX_BRIDGE_SEGMENT","sect))) \
    static char * const BDXBridgeGlobalMethod_##method = #method

// Registering external global method
#define BDX_BRIDGE_EXTERNAL_METHODS_SECTION "XBMExternal"
#define bdx_bridge_register_external_global_method(method) \
    bdx_bridge_register_global_method(method, BDX_BRIDGE_EXTERNAL_METHODS_SECTION)

// ALog
#define bdx_alog_info(format, ...) \
BDALOG_PROTOCOL_INFO_TAG(BDXBridgeALogTag, format, ##__VA_ARGS__);

#define bdx_complete_if_not_implemented(implemented) do { \
    if (!implemented) { \
        BDXBridgeStatus *status = [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeNotImplemented message:@"The method named '%@' is not implemented.", self.methodName]; \
        bdx_invoke_block(completionHandler, nil, status); \
        return; \
    } \
} while (0)

NS_ASSUME_NONNULL_END
