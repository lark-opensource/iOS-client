//
//  CJPayRequestParam+debug.m
//  Pods
//
//  Created by xiuyuanLee on 2021/5/10.
//

#import "CJPayRequestParam+debug.h"
#import <CJPay/CJPaySDKMacro.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import "CJPayDebugManager.h"

@implementation CJPayRequestParam (debug)

+ (void)swizzleDebugMethod {
    CJPayGaiaRegisterComponentMethod
    [self btd_swizzleClassMethod:@selector(webViewUA)
                            with:@selector(debugWebViewUA)];
}

+ (NSString *)debugWebViewUA {
    NSString *environment = [CJPayDebugManager boeIsOpen] ? @"BOE" : @"Build";
    NSString *ua = [[self debugWebViewUA] stringByAppendingFormat:@" Env/%@", environment];
    return ua;
}

@end
