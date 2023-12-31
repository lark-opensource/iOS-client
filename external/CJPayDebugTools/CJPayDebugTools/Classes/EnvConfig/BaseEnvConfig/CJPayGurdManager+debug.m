//
//  CJPayGurdManager+debug.m
//  Pods
//
//  Created by 易培淮 on 2021/4/22.
//

#import "CJPayGurdManager+debug.h"
#import <CJPay/CJPaySDKMacro.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import "CJPayDebugManager.h"

@implementation CJPayGurdManager (debug)

+ (void)swizzleDebugMethod {
    CJPayGaiaRegisterComponentMethod
    [self btd_swizzleInstanceMethod:NSSelectorFromString(@"accessKey")
                            with:@selector(debug_accessKey)];
}

- (NSString *)debug_accessKey {
    if ([CJPayDebugManager boeIsOpen]) {
        return @"d8694356c0aca73481d38c00960da5a8";//内测部署Key
    } else {
        return @"c0493580c3e3829043cb33227b6e2d80";//线上部署Key
    }
}



@end
