//
//  HMDMacroManager.m
//  Pods
//
//  Created by wangyinhui on 2022/5/30.
//

#import "HMDMacroManager.h"
#import <TTMacroManager/TTMacroManager.h>
#import "HMDDynamicCall.h"


bool hmd_is_debug(void) {
    return [TTMacroManager isDebug];
}

bool hmd_is_release(void) {
    return [TTMacroManager isRelease];
}

bool hmd_is_inhouse(void) {
    return [TTMacroManager isInHouse];
}

/*
 only if the TTMacroManager's version is higher than 1.1.0, the result is valid
 */
bool hmd_is_address_sanitizer(void) {
    static dispatch_once_t once_token;
    static bool is_asan = false;
    dispatch_once(&once_token, ^{
        is_asan = DC_IS(DC_CL(TTMacroManager, isAddressSanitizer), NSNumber).boolValue;
    });
    return is_asan;
}

/*
 only if the TTMacroManager's version is higher than 1.1.0, the result is valid
 */
bool hmd_is_thread_sanitizer(void) {
    static dispatch_once_t once_token;
    static bool is_tsan = false;
    dispatch_once(&once_token, ^{
        is_tsan = DC_IS(DC_CL(TTMacroManager, isThreadSanitizer), NSNumber).boolValue;
    });
    return is_tsan;
}
