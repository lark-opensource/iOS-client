//
//  AWEPropSecurityTipsHelper.m
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/10/8.
//

#import "AWEPropSecurityTipsHelper.h"
#import <CreativeKit/ACCCacheProtocol.h>

static NSString *const kAWEProptSecurityTipsDisplayedKey = @"kAWEProptSecurityTipsDisplayedKey";

@implementation AWEPropSecurityTipsHelper

+ (BOOL)shouldShowSecurityTips
{
    return ![ACCCache() boolForKey:kAWEProptSecurityTipsDisplayedKey];
}

+ (void)handleSecurityTipsDisplayed
{
    [ACCCache() setBool:YES forKey:kAWEProptSecurityTipsDisplayedKey];
}

@end
