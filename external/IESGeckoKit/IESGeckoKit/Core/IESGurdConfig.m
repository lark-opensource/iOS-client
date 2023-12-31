//
//  IESGurdConfig.m
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/6/3.
//

#import "IESGurdConfig.h"

@implementation IESGurdConfig

+ (NSString *)platformDomain
{
    NSAssert(NO, @"Gecko depends on Config/CN or Config/OS subspec");
    return @"";
}

+ (NSString *)monitorAppId
{
    NSAssert(NO, @"Gecko depends on Config/CN or Config/OS subspec");
    return @"";
}

@end
