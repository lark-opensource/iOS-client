//
//  IESFalconInfo.m
//  Pods
//
//  Created by 陈煜钏 on 2019/10/9.
//

#import "IESFalconInfo.h"

static NSString * kIESFalconDeviceId = nil;
static NSString * kIESFalconPlatformDomain = nil;
static BDWKGetDeviceIDBlock sGetDeviceIDBlock = nil;

@implementation IESFalconInfo

+ (NSString *)deviceId
{
    NSString *deviceID = kIESFalconDeviceId;
    if (!deviceID && sGetDeviceIDBlock) {
        deviceID = sGetDeviceIDBlock();
    }
    return deviceID;
}

+ (void)setDeviceId:(NSString *)deviceId
{
    kIESFalconDeviceId = deviceId;
}

+ (void)setGetDeviceIDBlock:(BDWKGetDeviceIDBlock)getDeviceIDBlock
{
    sGetDeviceIDBlock = [getDeviceIDBlock copy];
}

+ (NSString *)platformDomain
{
    return kIESFalconPlatformDomain;
}

+ (void)setPlatformDomain:(NSString *)platformDomain
{
    kIESFalconPlatformDomain = platformDomain;
}

@end
