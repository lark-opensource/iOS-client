//
//  AWELazyRegisterUserModel.m
//  AWELazyRegister
//
//  Created by liqingyao on 2019/12/1.
//

#import "AWELazyRegisterUserModel.h"

AWELazyRegisterModule(AWELazyRegisterModuleUserModel)

static bool isLazy = NO;
void evaluateLazyRegisterUserModel()
{
    isLazy = YES;
    [AWELazyRegister evaluateLazyRegisterForModule:@AWELazyRegisterModuleUserModel];
}

bool shouldRegisterUserModel()
{
    NSCAssert(isLazy, @"AWEUserModel should use AWELazyRegisterUserModel() to register");
    return YES;
}

@implementation AWELazyRegisterUserModel

@end
