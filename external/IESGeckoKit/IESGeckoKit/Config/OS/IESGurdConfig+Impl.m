//
//  IESGurdConfig+Impl.m
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/6/3.
//

#import "IESGurdConfig+Impl.h"

#import <IESGeckoKit/IESGeckoKit.h>

@implementation IESGurdConfig (Impl)

#pragma mark - Public

+ (void)setPlatformDomainType:(IESGurdPlatformDomainType)type
{
    switch (type) {
        case IESGurdPlatformDomainTypeSG: {
            IESGurdKit.platformDomain = @"gecko-sg.byteoversea.com";
            break;
        }
        case IESGurdPlatformDomainTypeVA: {
            IESGurdKit.platformDomain = @"gecko-va.byteoversea.com";
            break;
        }
    }
}

#pragma mark - Override

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

+ (NSString *)platformDomain
{
    NSAssert(NO, @"Please call +[IESGurdConfig setPlatformDomainType:]");
    return @"";
}

+ (NSString *)monitorAppId
{
    return @"3261";
}

#pragma clang diagnostic pop

@end
