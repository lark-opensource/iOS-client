//
//  AWELazyRegisterAccountPlatform.m
//  AWELazyRegister
//
//  Created by liqingyao on 2019/12/3.
//

#import "AWELazyRegisterAccountPlatform.h"

AWELazyRegisterModule(AWELazyRegisterModuleAccountPlatform)

static bool isLazy = NO;
void evaluateLazyRegisterAccountPlatform()
{
    isLazy = YES;
    [AWELazyRegister evaluateLazyRegisterForModule:@AWELazyRegisterModuleAccountPlatform];
}

bool shouldRegisterAccountPlatform()
{
    NSCAssert(isLazy, @"NHAccountPlatformFactory should use AWELazyRegisterAccountPlatform() to register");
    return YES;
}

@implementation AWELazyRegisterAccountPlatform

@end
