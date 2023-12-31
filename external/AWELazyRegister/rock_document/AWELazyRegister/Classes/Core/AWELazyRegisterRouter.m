//
//  AWELazyRegisterRouter.m
//  AWELazyRegister-Pods-Aweme
//
//  Created by 陈煜钏 on 2020/4/26.
//

#import "AWELazyRegisterRouter.h"

AWELazyRegisterModule(AWELazyRegisterModuleRouter)
AWELazyRegisterModule(AWELazyRegisterModuleRouterBackup)

#if INHOUSE_TARGET && TEST_MODE
AWELazyRegisterModule(AWELazyRegisterModuleRouterRecord)
#endif

BOOL AWECanEvaluateLazyRegisterRouterInfo(NSString *URLString)
{
    return [AWELazyRegister canEvaluateLazyRegisterForKey:URLString ofModule:@AWELazyRegisterModuleRouter];
}

void AWEEvaluateLazyRegisterRouterInfo(NSString *URLString)
{
    [AWELazyRegister evaluateLazyRegisterForKey:URLString ofModule:@AWELazyRegisterModuleRouter];
}

void AWEEvaluateLazyRegisterRouterBackup()
{
    [AWELazyRegister evaluateLazyRegisterForModule:@AWELazyRegisterModuleRouterBackup];
}

#if INHOUSE_TARGET && TEST_MODE
void AWEEvaluateLazyRegisterRouterRecord()
{
    [AWELazyRegister evaluateLazyRegisterForModule:@AWELazyRegisterModuleRouterRecord];
}
#endif

@implementation AWELazyRegisterRouter

@end
