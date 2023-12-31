//
//  HMDDomesticURLSettings.m
//  Heimdallr
//
//  Created by fengyadong on 2018/3/9.
//

#import "HMDDomesticURLSettings.h"

static NSString * const kRemoteConfigHost1 = @"https://mon.zijieapi.com";
static NSString * const kRemoteConfigHost2 = @"https://mon.toutiaocloud.com";
static NSString * const kRemoteConfigHost3 = @"https://mon.toutiaocloud.net";
static NSString * const kDefaultUploadHost = @"https://mon.zijieapi.com";

@implementation HMDDomesticURLSettings

#pragma mark - HMDURLHostSettings

+ (NSArray<NSString *> *)defaultHosts {
    return @[kDefaultUploadHost];
}

+ (NSArray<NSString *> *)configFetchDefaultHosts {
    return @[kRemoteConfigHost1, kRemoteConfigHost2, kRemoteConfigHost3];
}

@end
