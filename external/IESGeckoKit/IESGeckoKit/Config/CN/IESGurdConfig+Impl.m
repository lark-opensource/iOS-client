//
//  IESGurdConfig+Impl.m
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/6/3.
//

#import "IESGurdConfig+Impl.h"

#import <IESGeckoKit/IESGeckoKit.h>

@implementation IESGurdConfig (Impl)

#pragma mark - Override

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

+ (NSString *)platformDomain
{
    return @"gurd.snssdk.com";
}

+ (NSString *)monitorAppId
{
    return @"3262";
}

#pragma clang diagnostic pop

@end
