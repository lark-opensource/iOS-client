//
//  CJPayBindCardManager+debug.m
//  Aweme
//
//  Created by cbc on 2023/7/30.
//

#import "CJPayBindCardManager+debug.h"

#import <CJPay/CJPaySDKMacro.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import "CJPayDebugManager.h"

@implementation CJPayBindCardManager (debug)

+ (void)swizzleDebugMethod {
    CJPayGaiaRegisterComponentMethod
    [self btd_swizzleInstanceMethod:NSSelectorFromString(@"geckoAccessKey")
                            with:@selector(debug_accessKey)];
}

- (NSString *)debug_accessKey {
    if ([CJPayDebugManager boeIsOpen]) {
        return @"36723dc3e85a23e701d1697d57de07ed";//内测部署Key
    } else {
        return @"5fb33cde3ebff01c8433ddc22aac0816";//线上部署Key
    }
}



@end
