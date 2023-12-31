//
//  BDPSandBoxHelper.m
//  Timor
//
//  Created by yinyuan on 2019/3/22.
//

#import "BDPSandBoxHelper.h"

@implementation BDPSandBoxHelper

+ (NSString*)appDisplayName {
    NSString *appName = [[NSBundle mainBundle] localizedStringForKey:@"CFBundleDisplayName" value:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"] table:@"InfoPlist"];
    if (!appName || [appName isEqualToString:@"CFBundleDisplayName"]) {
        appName = [[NSBundle mainBundle] localizedStringForKey:@"CFBundleName" value:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"] table:@"InfoPlist"];
    };
    return appName;
}

@end
