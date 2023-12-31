//
//  CJPayBizWebViewController+debug.m
//  Pods
//
//  Created by 尚怀军 on 2021/1/25.
//

#import "CJPayBizWebViewController+debug.h"
#import <CJPay/CJPaySDKMacro.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import "CJPayDebugManager.h"

@implementation CJPayBizWebViewController (debug)

+ (void)swizzleDebugMethod {
    CJPayGaiaRegisterComponentMethod
    [self btd_swizzleInstanceMethod:NSSelectorFromString(@"appendHeaderWithRequest:")
                               with:@selector(debug_appendHeaderWithRequest:)];
}

- (void)debug_appendHeaderWithRequest:(NSMutableURLRequest *)request {
    [self debug_appendHeaderWithRequest:request];
    if ([CJPayDebugManager boeIsOpen]) {
        [CJPayDebugManager p_setBOEHeader:request];
    }
}

@end
