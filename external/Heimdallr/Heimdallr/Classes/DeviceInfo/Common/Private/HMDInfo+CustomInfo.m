//
//  HMDInfo+CustomInfo.m
//  Heimdallr
//
//  Created by joy on 2018/4/27.
//

#import "HMDInfo+CustomInfo.h"
#import "HMDInfo+AppInfo.h"
#import "HMDMacro.h"
#import "NSDictionary+HMDSafe.h"

static NSString *const kTTHMDAppVersion = @"kTTInstallAppVersion";//兼容TTTracker

@implementation HMDInfo (CustomInfo)

- (BOOL)isInHouseApp {
    NSRange isRange = [[self bundleIdentifier] rangeOfString:@"inHouse" options:NSCaseInsensitiveSearch];
    if (isRange.location != NSNotFound) {
        return YES;
    }
    return NO;
}

- (NSString *)ssAppMID {
    NSString * mid = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"SSMID"];
    return mid;
}

- (NSString *)ssAppScheme {
    NSString * mid = [self ssAppMID];
    if (mid) {
        NSString *s = @"nss";
        return [NSString stringWithFormat:@"s%@dk%@://", s, mid];
    }
    return nil;
}

- (NSString *)appOwnURL {
    NSArray *urlTypes = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleURLTypes"];
    NSDictionary *urlDic = [[urlTypes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"CFBundleURLName=%@",@"own"]] firstObject];
    NSString *url = [[urlDic valueForKey:@"CFBundleURLSchemes"] firstObject];
    return url;
}

- (BOOL)isUpgradeUser {
    //兼容头条系历史代码
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"exploreIsUpgradeUserKey"]) {
        return [[[NSUserDefaults standardUserDefaults] objectForKey:@"exploreIsUpgradeUserKey"] boolValue];
    }
    
    //记下用户首次安装的版本号
    NSString *preAppVersion = [[NSUserDefaults standardUserDefaults] stringForKey:kTTHMDAppVersion];
    if (HMDIsEmptyString(preAppVersion)) {
        [[NSUserDefaults standardUserDefaults] setObject:[self shortVersion] forKey:kTTHMDAppVersion];
        return NO;
    } else if ([[self shortVersion] isEqualToString:preAppVersion]) {
        return NO;
    }
    
    return YES;
}

@end
