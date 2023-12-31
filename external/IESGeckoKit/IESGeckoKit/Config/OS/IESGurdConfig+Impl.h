//
//  IESGurdConfig+Impl.h
//  IESGeckoKit-ByteSync-Config_OS-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/6/3.
//

#import <IESGeckoKit/IESGurdConfig.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, IESGurdPlatformDomainType) {
    IESGurdPlatformDomainTypeSG,
    IESGurdPlatformDomainTypeVA
};

@interface IESGurdConfig (Impl)

+ (void)setPlatformDomainType:(IESGurdPlatformDomainType)type;

@end

NS_ASSUME_NONNULL_END
