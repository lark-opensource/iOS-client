//
//  CJPaySDKHTTPRequestSerializer+debug.m
//  Pods
//
//  Created by 尚怀军 on 2021/1/25.
//

#import "CJPaySDKHTTPRequestSerializer+debug.h"
#import <CJPay/CJPaySDKMacro.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import "CJPayDebugManager.h"

@implementation CJPaySDKHTTPRequestSerializer (debug)

+ (void)swizzleDebugMethod {
    CJPayGaiaRegisterComponentMethod
    [self btd_swizzleInstanceMethod:NSSelectorFromString(@"getEnvParams")
                               with:@selector(debug_getEnvParams)];
}

- (NSDictionary *)debug_getEnvParams {
    if ([CJPayDebugManager boeIsOpen]) {
        if ([CJPayDebugManager boeEnvDictionary]) {
            return [CJPayDebugManager boeEnvDictionary];
        } else {
            return [self debug_getEnvParams];
        }
    } else {
        return [self debug_getEnvParams];
    }
}

@end
