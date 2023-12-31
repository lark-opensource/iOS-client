//
//  HMDMacroManager.m
//  Pods
//
//  Created by wangyinhui on 2022/5/30.
//

#import "HMDMacroManager.h"
#if !RANGERSAPM
#import <TTMacroManager/TTMacroManager.h>
#endif
#import "HMDDynamicCall.h"

bool hmd_is_debug(void) {
#if RANGERSAPM
#if DEBUG
    return YES;
#else
    return NO;
#endif /* DEBUG */
#else
    return [TTMacroManager isDebug];
#endif /* RANGERSAPM */
}

bool hmd_is_release(void) {
#if RANGERSAPM
#if DEBUG
    return NO;
#else
    return YES;
#endif /* DEBUG */
#else
    return [TTMacroManager isRelease];
#endif /* RANGERSAPM */
}

bool hmd_is_inhouse(void) {
#if RANGERSAPM
    return NO;
#else
    return [TTMacroManager isInHouse];
#endif /* RANGERSAPM */
}

// Only if the TTMacroManager's version is higher than 1.1.0, the result is valid.
bool hmd_is_address_sanitizer(void) {
    static dispatch_once_t once_token;
    static bool is_asan = false;
    dispatch_once(&once_token, ^{
        is_asan = DC_IS(DC_CL(TTMacroManager, isAddressSanitizer), NSNumber).boolValue;
    });
    return is_asan;
}

// Only if the TTMacroManager's version is higher than 1.1.0, the result is valid.
bool hmd_is_thread_sanitizer(void) {
    static dispatch_once_t once_token;
    static bool is_tsan = false;
    dispatch_once(&once_token, ^{
        is_tsan = DC_IS(DC_CL(TTMacroManager, isThreadSanitizer), NSNumber).boolValue;
    });
    return is_tsan;
}
