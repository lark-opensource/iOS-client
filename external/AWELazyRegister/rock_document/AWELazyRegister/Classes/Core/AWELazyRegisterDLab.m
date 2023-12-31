//
//  AWELazyRegister
//
//  Created by liqingyao on 2019/11/28.
//

#import "AWELazyRegisterDLab.h"

AWELazyRegisterModule(AWELazyRegisterModuleDLab)

static bool isLazy = NO;

void evaluateLazyRegisterDLabIdea()
{
    isLazy = YES;
    [AWELazyRegister evaluateLazyRegisterForModule:@AWELazyRegisterModuleDLab];
}

void evaluateLazyRegisterDLabIdeaForKey(NSString *key)
{
    isLazy = YES;
    [AWELazyRegister evaluateLazyRegisterForKey:key ofModule:@AWELazyRegisterModuleDLab];
}

bool shouldRegisterDLabIdea()
{
    NSCAssert(isLazy, @"AWEDLabCenter should use AWELazyRegisterDLab() to register");
    return YES;
}

@implementation AWELazyRegisterDLab

@end
