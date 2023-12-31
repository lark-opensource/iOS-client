//
//  EMAAppEngineConfig.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2020/2/19.
//

#import "EMAAppEngineConfig.h"
#import <OPFoundation/OPFoundation-Swift.h>

@interface EMAAppEngineConfig ()

@property (nonatomic, copy, readwrite) NSString *channel;

@property (nonatomic, assign, readwrite) OPEnvType envType;

@property (nonatomic, strong, readwrite) MicroAppDomainConfig *domainConfig;

@end

@implementation EMAAppEngineConfig

- (instancetype)initWithEnvType:(OPEnvType)envType
                   domainConfig:(MicroAppDomainConfig * _Nonnull)domainConfig
                        channel:(NSString * _Nonnull)channel {
    self = [super init];
    if (self) {
        _envType = envType;
        _domainConfig = domainConfig;
        _channel = channel;
    }
    return self;
}

@end
