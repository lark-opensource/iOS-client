//
//  AWELazyRegisterJSBridge.m
//  AWELazyRegister
//
//  Created by liqingyao on 2019/12/4.
//

#import "AWELazyRegisterJSBridge.h"

AWELazyRegisterModule(AWELazyRegisterModulePiper)

static bool isLazy = NO;
void evaluateLazyRegisterPiperHandler()
{
    isLazy = YES;
    [AWELazyRegister evaluateLazyRegisterForModule:@AWELazyRegisterModulePiper];
}

bool shouldRegisterPiperHandler()
{
	NSCAssert(isLazy, @"AWEPiper should use AWELazyRegisterModulePiper() to register");
    return YES;
}

@implementation AWELazyRegisterPiper

@end
