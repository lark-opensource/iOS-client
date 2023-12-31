//
//  AWELazyRegisterRN.m
//  AWELazyRegister
//
//  Created by liqingyao on 2019/12/4.
//

#import "AWELazyRegisterRN.h"

AWELazyRegisterModule(AWELazyRegisterModuleRN)

static bool isLazy = NO;
void evaluateLazyRegisterRNHandler()
{
    isLazy = YES;
    [AWELazyRegister evaluateLazyRegisterForModule:@AWELazyRegisterModuleRN];
}

bool shouldRegisterRNHandler()
{
    NSCAssert(isLazy, @"AWERNBridgeRegister should use AWELazyRegisterRN() to register");
    return YES;
}

@implementation AWELazyRegisterRN

@end
