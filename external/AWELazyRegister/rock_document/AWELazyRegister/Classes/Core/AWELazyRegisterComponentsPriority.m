//
//  AWELazyRegisterComponentsPriority.m
//  AWELazyRegister
//
//  Created by liqingyao on 2019/11/28.
//

#import "AWELazyRegisterComponentsPriority.h"

AWELazyRegisterModule(AWELazyRegisterModuleComponentPriority)

static bool isLazy = NO;
void evaluateLazyRegisterComponentsPriority()
{
    isLazy = YES;
    [AWELazyRegister evaluateLazyRegisterForModule:@AWELazyRegisterModuleComponentPriority];
}

bool shouldRegisterComponentsPriority()
{
    NSCAssert(isLazy, @"AWEComponentsPriorityUtils should use AWELazyRegisterComponentPriority() to register");
    return YES;
}

@implementation AWELazyRegisterComponentsPriority

@end
