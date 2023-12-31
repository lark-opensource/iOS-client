//
//  OneKitApp.m
//  OneKit
//
//  Created by bob on 2021/1/13.
//

#import "OneKitApp.h"
#import "OKStartUpScheduler.h"
#import "NSDictionary+OK.h"
#import "OKApplicationInfo.h"

@implementation OneKitApp

// 已过期，下个版本移除
+ (void)start {
    [self startWithLaunchOptions:nil];
}

+ (void)startWithLaunchOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    [[OKStartUpScheduler sharedScheduler] startWithLaunchOptions:launchOptions];
}

@end
