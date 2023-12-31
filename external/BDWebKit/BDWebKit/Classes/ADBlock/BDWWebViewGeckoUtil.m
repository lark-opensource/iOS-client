#import "BDWWebViewGeckoUtil.h"

#import <IESGeckoKit/IESGeckoKit.h>
#import <ByteDanceKit/ByteDanceKit.h>

@implementation BDWWebViewGeckoUtil

static NSString *bdw_geckoAccessKey = nil;
+ (void)updateGeckoAccessKey:(NSString *)geckoAccessKey {
    bdw_geckoAccessKey = [geckoAccessKey copy];
}

+ (NSString *)geckoAccessKey {
    if (BTD_isEmptyString(bdw_geckoAccessKey)) {
        return @"";
    }
    return [bdw_geckoAccessKey copy];
}

+ (BOOL)hasCacheForPath:(NSString *)path channel:(NSString *)channel {
    if (BTD_isEmptyString(path) || BTD_isEmptyString(channel)) {
        return NO;
    }
    NSString *accessKey = [self geckoAccessKey];
    return [IESGurdKit hasCacheForPath:path accessKey:accessKey channel:channel];
}

+ (NSData *)geckoDataForPath:(NSString *)path channel:(NSString *)channel {
    if (BTD_isEmptyString(path) || BTD_isEmptyString(channel)) {
        return nil;
    }
    
    NSString *accessKey = [self geckoAccessKey];
    BOOL res = [IESGurdKit hasCacheForPath:path accessKey:accessKey channel:channel];
    NSData *data = nil;
    if (res) {
        data = [IESGurdKit dataForPath:path accessKey:accessKey channel:channel];
    }
    return data;
}

+ (NSDictionary *)geckoSettingDict {
    static NSDictionary *geckoSettingDict = nil;
    if (!geckoSettingDict) {
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSString *settingsBundle = [mainBundle pathForResource:@"Settings" ofType:@"bundle"];
        geckoSettingDict = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"GeckoSetting.plist"]];
    }
    return geckoSettingDict;
}

+ (nullable NSString *)geckoVersionForChannel:(NSString *)channel {
    if (BTD_isEmptyString(channel)) {
        return nil;
    }
    uint64_t packageVersion = [IESGurdKit packageVersionForAccessKey:[self geckoAccessKey] channel:channel];
    if (packageVersion != 0) {
        return @(packageVersion).stringValue;
    }
    return nil;
}

@end
