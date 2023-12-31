//
//  HMDOverseasURLSettings.m
//  Heimdallr
//
//  Created by fengyadong on 2018/3/9.
//

#import "HMDOverseasURLSettings.h"

static NSString * const kOverseasExceptionAndConfigHost = @"https://mon.isnssdk.com";

@implementation HMDOverseasURLSettings

#pragma mark - HMDURLHostSettings

+ (NSArray<NSString *> *)defaultHosts {
    return @[kOverseasExceptionAndConfigHost];
}

+ (NSArray<NSString *> *)configFetchDefaultHosts {
    return @[kOverseasExceptionAndConfigHost];
}

@end
