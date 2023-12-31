//
//  AWELazyRegisterTabBar.m
//  AWELazyRegister-Pods-Aweme
//
//  Created by 陈煜钏 on 2021/4/9.
//

#import "AWELazyRegisterTabBar.h"

AWELazyRegisterModule(AWELazyRegisterModuleNormalTabBar)
AWELazyRegisterModule(AWELazyRegisterModuleTeenModeTabBar)

void AWEEvaluateLazyRegisterNormalTabBar()
{
    [AWELazyRegister evaluateLazyRegisterForModule:@AWELazyRegisterModuleNormalTabBar];
}

void AWEEvaluateLazyRegisterTeenModeTabBar()
{
    [AWELazyRegister evaluateLazyRegisterForModule:@AWELazyRegisterModuleTeenModeTabBar];
}

@implementation AWELazyRegisterTabBar

@end
