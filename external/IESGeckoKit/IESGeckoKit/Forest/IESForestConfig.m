// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestConfig.h"
#import "IESForestFetcherProtocol.h"

@interface IESForestConfig ()

@property (nonatomic, copy) NSString *accessKey;
@property (nonatomic, strong) dispatch_queue_t completionQueue;
@property (nonatomic, strong) NSNumber *disableGecko;
@property (nonatomic, strong) NSNumber *disableBuiltin;
@property (nonatomic, strong) NSNumber *disableCDN;
@property (nonatomic, strong) NSNumber *waitGeckoUpdate;
@property (nonatomic, strong) NSNumber *enableMemoryCache;
@property (nonatomic, strong) NSNumber *runWorkflowInGlobalQueue;
@property (nonatomic, copy) NSArray<NSNumber *> *fetcherSequence;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *defaultPrefixToAccessKey;

@end

@implementation IESForestConfig

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return self;
}

- (nonnull id)mutableCopyWithZone:(nullable NSZone *)zone {
    IESMutableForestConfig *config = [[IESMutableForestConfig allocWithZone:zone] init];
    config.accessKey = [self.accessKey copy];
    config.completionQueue = self.completionQueue;
    config.disableGecko = self.disableGecko;
    config.disableBuiltin = self.disableBuiltin;
    config.disableCDN = self.disableCDN;
    config.waitGeckoUpdate = self.waitGeckoUpdate;
    config.enableMemoryCache = self.enableMemoryCache;
    config.runWorkflowInGlobalQueue = self.runWorkflowInGlobalQueue;
    config.fetcherSequence = [self.fetcherSequence copy];
    config.defaultPrefixToAccessKey = [self.defaultPrefixToAccessKey copy];
    return config;
}

- (NSArray<NSNumber *>*)fetcherSequence
{
    if (_fetcherSequence) {
        return _fetcherSequence;
    }
    return @[@(IESForestFetcherTypeGecko), @(IESForestFetcherTypeBuiltin), @(IESForestFetcherTypeCDN)];
}

@end

@implementation IESMutableForestConfig

@dynamic defaultPrefixToAccessKey;
@dynamic accessKey;
@dynamic disableGecko;
@dynamic disableBuiltin;
@dynamic disableCDN;
@dynamic waitGeckoUpdate;
@dynamic enableMemoryCache;
@dynamic fetcherSequence;
@dynamic completionQueue;
@dynamic runWorkflowInGlobalQueue;

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    IESForestConfig *config = [[IESForestConfig allocWithZone:zone] init];
    config.accessKey = [self.accessKey copy];
    config.completionQueue = self.completionQueue;
    config.disableGecko = self.disableGecko;
    config.disableBuiltin = self.disableBuiltin;
    config.disableCDN = self.disableCDN;
    config.waitGeckoUpdate = self.waitGeckoUpdate;
    config.enableMemoryCache = self.enableMemoryCache;
    config.runWorkflowInGlobalQueue = self.runWorkflowInGlobalQueue;
    config.fetcherSequence = [self.fetcherSequence copy];
    config.defaultPrefixToAccessKey = [self.defaultPrefixToAccessKey copy];
    return config;
}

@end
