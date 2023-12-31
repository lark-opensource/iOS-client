//
//  AWELazyRegisterWebImage.m
//  AWELazyRegister
//
//  Created by liqingyao on 2019/12/1.
//

#import "AWELazyRegisterWebImage.h"

AWELazyRegisterModule(AWELazyRegisterModuleWebImage)

static bool isLazy = NO;
void evaluateLazyRegisterWebImageManager()
{
    isLazy = YES;
    [AWELazyRegister evaluateLazyRegisterForModule:@AWELazyRegisterModuleWebImage];
}

bool shouldRegisterWebImageManager()
{
    NSCAssert(isLazy, @"AWEYYWebImageManagerFactory should use AWELazyRegisterWebImage() to register");
    return YES;
}

@implementation AWELazyRegisterWebImage

@end
