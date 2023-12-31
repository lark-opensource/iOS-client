//
//  AWELazyRegisterTransition.m
//  AWETransition
//
//  Created by liqingyao on 2019/11/20.
//

#import "AWELazyRegisterTransition.h"

AWELazyRegisterModule(AWELazyRegisterModuleTransition)

void AWETransitionLazyRegisterPatterns()
{
    [AWELazyRegister evaluateLazyRegisterForModule:@AWELazyRegisterModuleTransition];
}

@implementation AWELazyRegisterTransition

@end
