//
//  EMAAppEngineConfig.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2020/2/19.
//

#import <Foundation/Foundation.h>
#import "OPEnvTypeHelper.h"

@class MicroAppDomainConfig;

NS_ASSUME_NONNULL_BEGIN

@interface EMAAppEngineConfig : NSObject

/// 渠道
@property (nonatomic, copy, readonly) NSString *channel;

/// 环境
@property (nonatomic, assign, readonly) OPEnvType envType;

/// 私有部署配置
@property (nonatomic, strong, readonly) MicroAppDomainConfig *domainConfig;

- (instancetype)initWithEnvType:(OPEnvType)envType
                   domainConfig:(MicroAppDomainConfig * _Nonnull)domainConfig
                        channel:(NSString * _Nonnull)channel;

- (instancetype _Nonnull)init NS_UNAVAILABLE;

+ (instancetype _Nonnull)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
