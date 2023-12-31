//
//  CJPayISecEngimaImpl+Debug.m
//  Pods
//
//  Created by 王新华 on 2022/8/2.
//

#import "CJPayISecEngimaImpl+Debug.h"
#import <CJPay/CJPaySDKMacro.h>
#import "CJPayDebugManager.h"

@implementation CJPayISecEngimaImpl(Debug)


+ (void)swizzleDebugMethod {
    CJPayGaiaRegisterComponentMethod
    [self btd_swizzleInstanceMethod:NSSelectorFromString(@"defaultToken")
                               with:@selector(debug_defaultToken)];
}

- (NSString *)debug_defaultToken {
    if ([CJPayDebugManager boeIsOpen]) {
        return @"BDp46nfioDU9dw+hDiWRCq7GN1SwsUkuBUV48tJh8q8wfzWahwojayB6ukmSVNqRBDBs+9SChmGK1ygJqZ1rmCM=";
    } else {
        return [self debug_defaultToken];
    }
}

@end
