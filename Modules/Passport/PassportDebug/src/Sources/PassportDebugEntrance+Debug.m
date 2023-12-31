//
//  PassportDebugEntrance+Debug.m
//  PassportDebug
//
//  Created by ByteDance on 2022/7/27.
//

#import "PassportDebugEntrance+Debug.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import "PassportDebug-Swift.h"

@implementation  PassportDebugEntrance (Debug)

+ (void)load
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        [self btd_swizzleInstanceMethod:@selector(setup) with:@selector(p_setup)];
    });
}

- (void)p_setup
{
    [PassportDebugItemRegist regist];
    #if DEBUG || BETA || ALPHA
    [PassportAppLinkRegistry regist];
    #endif
}

@end
