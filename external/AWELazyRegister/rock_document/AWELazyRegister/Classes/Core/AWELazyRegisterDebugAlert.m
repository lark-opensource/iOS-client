//
//  AWELazyRegisterDebugAlert.m
//  AWELazyRegister
//
//  Created by liqingyao on 2019/11/27.
//

#import "AWELazyRegisterDebugAlert.h"

AWELazyRegisterModule(AWELazyRegisterModuleDebugAlert)

void lazyRegistDebugAlertItems()
{
    [AWELazyRegister evaluateLazyRegisterForModule:@AWELazyRegisterModuleDebugAlert];
}

@implementation AWELazyRegisterDebugAlert

@end
