//
//  EMASandBoxHelper.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/4.
//

#import "EMASandBoxHelper.h"

@implementation EMASandBoxHelper

@end

@implementation EMASandBoxHelper (EMAPlist)

+ (NSString*)appDisplayName {
    NSString *appName = [[NSBundle mainBundle] localizedStringForKey:@"CFBundleDisplayName" value:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"] table:@"InfoPlist"];
    if (!appName || [appName isEqualToString:@"CFBundleDisplayName"]) {
        appName = [[NSBundle mainBundle] localizedStringForKey:@"CFBundleName" value:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"] table:@"InfoPlist"];
    }
    return appName;
}

+ (NSString*)versionName {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

+ (NSString*)bundleIdentifier {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
}

+ (NSString *)buildVerion{
    NSString* buildVersionRaw = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString * buildVersionNew = [buildVersionRaw stringByReplacingOccurrencesOfString:@"." withString:@""];
    return buildVersionNew;
}

+ (NSString*)appName {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"AppName"];
}

+ (BOOL)gadgetDebug {
    NSNumber *value = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"GADGET_DEBUG"];
    if (!value || ![value isKindOfClass:[NSNumber class]]) {
        return NO;
    }
    return [value boolValue];
}

@end
