//
//  AWELazyRegisterCarrierService.m
//  AWELazyRegister
//
//  Created by liqingyao on 2019/12/3.
//

#import "AWELazyRegisterCarrierService.h"

AWELazyRegisterModule(AWELazyRegisterModuleCarrierService)

static bool isLazy = NO;
void evaluateLazyRegisterCarrierService()
{
    isLazy = YES;
    [AWELazyRegister evaluateLazyRegisterForModule:@AWELazyRegisterModuleCarrierService];
}

bool shouldRegisterCarrierService()
{
    NSCAssert(isLazy, @"AWEPassportCarrierServiceManager should use AWELazyRegisterCarrierService() to register");
    return YES;
}

@implementation AWELazyRegisterCarrierService

@end
