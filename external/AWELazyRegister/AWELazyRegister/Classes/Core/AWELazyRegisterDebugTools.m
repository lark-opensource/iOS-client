//
//  AWELazyRegisterDebugTools.m
//  AWELazyRegister
//
//  Created by 陈煜钏 on 2020/12/25.
//

#if INHOUSE_TARGET

#import "AWELazyRegisterDebugTools.h"

AWELazyRegisterModule(AWELazyRegisterModuleDebugTools)

void AWEEvaluateLazyRegisterDebugTools()
{
    [AWELazyRegister evaluateLazyRegisterForModule:@AWELazyRegisterModuleDebugTools];
}

@implementation AWELazyRegisterDebugTools

@end

#endif
