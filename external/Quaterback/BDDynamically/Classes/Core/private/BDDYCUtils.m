//
//  BDDYCUtils.m
//  BDDynamically
//
//  Created by zuopengliu on 29/8/2018.
//

#import "BDDYCUtils.h"
#import <objc/runtime.h>
#import "BDBDQuaterback.h"
#import <BDAlogProtocol/BDAlogProtocol.h>
#import "BDBDQuaterback+Internal.h"

void BDDYCSwapClassMethods(Class cls, SEL original, SEL replacement)
{
    Method originalMethod = class_getClassMethod(cls, original);
    IMP originalImplementation = method_getImplementation(originalMethod);
    const char *originalArgTypes = method_getTypeEncoding(originalMethod);
    
    Method replacementMethod = class_getClassMethod(cls, replacement);
    IMP replacementImplementation = method_getImplementation(replacementMethod);
    const char *replacementArgTypes = method_getTypeEncoding(replacementMethod);
    
    if (class_addMethod(cls, original, replacementImplementation, replacementArgTypes)) {
        class_replaceMethod(cls, replacement, originalImplementation, originalArgTypes);
    } else {
        method_exchangeImplementations(originalMethod, replacementMethod);
    }
}

void BDDYCSwapInstanceMethods(Class cls, SEL original, SEL replacement)
{
    Method originalMethod = class_getInstanceMethod(cls, original);
    IMP originalImplementation = method_getImplementation(originalMethod);
    const char *originalArgTypes = method_getTypeEncoding(originalMethod);
    
    Method replacementMethod = class_getInstanceMethod(cls, replacement);
    IMP replacementImplementation = method_getImplementation(replacementMethod);
    const char *replacementArgTypes = method_getTypeEncoding(replacementMethod);
    
    if (class_addMethod(cls, original, replacementImplementation, replacementArgTypes)) {
        class_replaceMethod(cls, replacement, originalImplementation, originalArgTypes);
    } else {
        method_exchangeImplementations(originalMethod, replacementMethod);
    }
}

///////////////////
NSString *const  kBDDQuaterbackAppInforKey = @"kBDDQuaterbackAppInforKey";
NSString *const kCurrentChannel = @"kCurrentChannel";
NSString *const kCurrentAppVersion = @"kCurrentAppVersion";

@implementation BDDYCUtils

+ (void)updateAppInfoWithAppVersion:(NSString *)appVersion channel:(NSString *)channel {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSDictionary *appInfo = @{kCurrentAppVersion:appVersion?:@"",
                                      kCurrentChannel:channel?:@"",
                                      };
            [[NSUserDefaults standardUserDefaults] setObject:appInfo forKey:kBDDQuaterbackAppInforKey];
        });
    });
}

+ (NSDictionary *)appInfo {
    static NSDictionary *appInfo = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        id obj = [[NSUserDefaults standardUserDefaults] objectForKey:kBDDQuaterbackAppInforKey];
        if ([obj isKindOfClass:[NSDictionary class]]) {
            appInfo = (NSDictionary *)obj;
        }
    });
    return appInfo;
}

+ (BOOL)isValidPatchWithConfig:(id<BDQuaterbackConfigProtocol>)config needStrictCheck:(BOOL)needStrictCheck {
    NSString *appVersion = [BDBDQuaterback sharedMain].conf.appVersion;
    NSString *channel = [BDBDQuaterback sharedMain].conf.channel;
    NSString *osVersionStr = [[UIDevice currentDevice].systemVersion stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    NSString *osMin = [[config.osVersionRange objectForKey:@"os_version_min"] isKindOfClass:[NSString class]]?[config.osVersionRange objectForKey:@"os_version_min"]:@"0";
    NSString *osMax = [[config.osVersionRange objectForKey:@"os_version_max"] isKindOfClass:[NSString class]]?[config.osVersionRange objectForKey:@"os_version_max"]:@"0";

    if ([osMin isEqualToString:@"0.0"] || [osMin isEqualToString:@".0"] || [osMin isEqualToString:@"0.0.0"]) {
        osMin = @"0";
    }
    if ([osMax isEqualToString:@"0.0"] || [osMax isEqualToString:@".0"] || [osMax isEqualToString:@"0.0.0"]) {
        osMax = @"0";
    }

    NSComparisonResult osMinCompareMax = [osMin compare:osMax options:NSNumericSearch];
    NSComparisonResult osMinCompareO = [osMin compare:@"0" options:NSNumericSearch];
    NSComparisonResult osMaxCompareO = [osMax compare:@"0" options:NSNumericSearch];

    if ((osMinCompareO == NSOrderedDescending || osMinCompareO ==  NSOrderedSame)
        && (osMaxCompareO == NSOrderedDescending || osMinCompareO ==  NSOrderedSame)
        && osMinCompareMax == NSOrderedDescending) {
        osMin = [[config.osVersionRange objectForKey:@"os_version_max"] isKindOfClass:[NSString class]]?[config.osVersionRange objectForKey:@"os_version_max"]:@"0";
        osMax = [[config.osVersionRange objectForKey:@"os_version_min"] isKindOfClass:[NSString class]]?[config.osVersionRange objectForKey:@"os_version_min"]:@"0";
    }

    NSComparisonResult osMinCompareOFix = [osMin compare:@"0" options:NSNumericSearch];
    NSComparisonResult osMaxCompareOFix = [osMax compare:@"0" options:NSNumericSearch];
    NSComparisonResult osMinCompareVerson = [osVersionStr compare:osMin options:NSNumericSearch];
    NSComparisonResult osMaxCompareVerson = [osMax compare:osVersionStr options:NSNumericSearch];

    BOOL isMatchosVersion = NO;
    if ((osMinCompareOFix == NSOrderedSame && osMaxCompareOFix == NSOrderedSame) ||(!config.osVersionRange)) {
        isMatchosVersion = YES;
    } else if (osMinCompareOFix == NSOrderedSame && osMaxCompareOFix == NSOrderedDescending) {
        isMatchosVersion = osMaxCompareVerson == NSOrderedDescending || osMaxCompareVerson == NSOrderedSame;
    } else if (osMinCompareOFix == NSOrderedDescending && osMaxCompareOFix == NSOrderedSame) {
        isMatchosVersion = (osMinCompareVerson == NSOrderedDescending || osMinCompareVerson == NSOrderedSame);
    } else if (osMinCompareOFix == NSOrderedDescending && osMaxCompareOFix == NSOrderedDescending) {
        isMatchosVersion = ((osMaxCompareVerson == NSOrderedDescending || osMaxCompareVerson == NSOrderedSame) && (osMinCompareVerson == NSOrderedDescending ||  osMinCompareVerson == NSOrderedSame));
    } else {
        isMatchosVersion = NO;
    }

    BOOL isMatchAppVersion = NO;
    BOOL isMatchChannel = NO;
    if (needStrictCheck) {
        isMatchAppVersion = [config.appVersionList containsObject:appVersion];
        isMatchChannel = [config.channelList containsObject:channel];
    } else {
        isMatchAppVersion = config.appVersionList.count == 0?YES:[config.appVersionList containsObject:appVersion];
        isMatchChannel = config.channelList.count == 0?YES:[config.channelList containsObject:channel];
    }

    BOOL isValidPatch = (isMatchAppVersion && isMatchChannel && isMatchosVersion);
    NSString *logContent = [NSString stringWithFormat: @"%@\n app version :%@\n channel: %@\n OS version: %@\n\n app version list : %@\n channel list: %@\n OS range : %@",(needStrictCheck?@"download verification":@"load verification"),appVersion,channel,osVersionStr,config.appVersionList, config.channelList, config.osVersionRange];
    if (!isValidPatch) {
        BDALOG_PROTOCOL_ERROR_TAG(@"Better",@"%@",logContent);
    } else {
        BDALOG_PROTOCOL_INFO_TAG(@"Better", @"%@",logContent);
    }

    return isValidPatch;
}

@end
