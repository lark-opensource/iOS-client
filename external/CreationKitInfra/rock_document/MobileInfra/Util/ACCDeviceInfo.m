//
//  ACCDeviceInfo.m
//  CameraClient
//
//  Created by Liu Deping on 2019/12/4.
//

#import "ACCDeviceInfo.h"
#import "NSDictionary+ACCAddition.h"

@implementation ACCDeviceInfo

+ (NSString *)acc_appDisplayName
{
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] acc_stringValueForKey:@"CFBundleDisplayName"];
    if (!appName)
    {
        appName = [[[NSBundle mainBundle] infoDictionary] acc_stringValueForKey:@"CFBundleName"];
    }
    
    return appName;
}

+ (NSString *)acc_platformName
{
    NSString *result = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? @"ipad" : @"iphone";
    return result;
}

+ (NSString *)acc_versionName
{
    return [[[NSBundle mainBundle] infoDictionary] acc_stringValueForKey:@"CFBundleShortVersionString"];
}

+ (NSString *)acc_appName
{
    return [[[NSBundle mainBundle] infoDictionary] acc_stringValueForKey:@"AppName"];
}

+ (NSString *)acc_appID
{
    return [[[NSBundle mainBundle] infoDictionary] acc_stringValueForKey:@"SSAppID"];
}

+ (NSString *)acc_bundleIdentifier
{
    return [[[NSBundle mainBundle] infoDictionary] acc_stringValueForKey:@"CFBundleIdentifier"];
}

+ (NSString *)acc_currentChannel
{
    return [[[NSBundle mainBundle] infoDictionary] acc_stringValueForKey:@"CHANNEL_NAME"];
}

+ (NSString *)acc_OSVersion
{
    return [[UIDevice currentDevice] systemVersion];
}

@end
