//
//  NSBundle+BTDAdditions.m
//  Pods
//
//  Created by yanglinfeng on 2019/7/2.
//

#import "NSBundle+BTDAdditions.h"

@implementation NSBundle (BTDAdditions)

+ (NSString*)btd_appDisplayName {
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    if (!appName) {
        appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    }
    return appName;
}

+ (NSString*)btd_versionName {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

+ (NSString*)btd_bundleIdentifier {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
}

@end
