// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESForestConfig : NSObject<NSCopying, NSMutableCopying>

/// Gecko accessKey
@property (nonatomic, copy, readonly) NSString *accessKey;
/// default prefixToAccessKey dictionary
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *defaultPrefixToAccessKey;
@property (nonatomic, strong, readonly) dispatch_queue_t completionQueue;

@property (nonatomic, strong, readonly) NSNumber *disableGecko;
@property (nonatomic, strong, readonly) NSNumber *disableBuiltin;
@property (nonatomic, strong, readonly) NSNumber *disableCDN;
@property (nonatomic, strong, readonly) NSNumber *waitGeckoUpdate;

/// enable memory cache, default vaule if NO
@property (nonatomic, strong, readonly) NSNumber *enableMemoryCache;
@property (nonatomic, copy, nullable, readonly) NSArray<NSNumber *> *fetcherSequence;

/// whether load resource in globalQueue, default value is YES
@property (nonatomic, strong, readonly) NSNumber *runWorkflowInGlobalQueue;

@end

@interface IESMutableForestConfig : IESForestConfig

@property (nonatomic, copy) NSString *accessKey;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *defaultPrefixToAccessKey;
@property (nonatomic, strong) dispatch_queue_t completionQueue;
@property (nonatomic, strong) NSNumber *disableGecko;
@property (nonatomic, strong) NSNumber *disableBuiltin;
@property (nonatomic, strong) NSNumber *disableCDN;

@property (nonatomic, strong) NSNumber *waitGeckoUpdate;
@property (nonatomic, strong) NSNumber *enableMemoryCache;
@property (nonatomic, copy) NSArray<NSNumber *> *fetcherSequence;
@property (nonatomic, strong) NSNumber *runWorkflowInGlobalQueue;

@end

NS_ASSUME_NONNULL_END
