// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESForestRemoteParameters : NSObject

@property (nonatomic, copy, nullable) NSString *accessKey;
@property (nonatomic, copy, nullable) NSString *channel;
@property (nonatomic, copy, nullable) NSString *bundle;

@property (nonatomic, copy, nullable) NSArray<NSNumber *> *fetcherSequence;
@property (nonatomic, copy, nullable) NSArray<NSString *> *shuffleDomains;
@property (nonatomic, strong, nullable) NSNumber *waitGeckoUpdate;
@property (nonatomic, strong, nullable) NSNumber *disableCdnCache;
@property (nonatomic, strong, nullable) NSNumber *cdnRetryTimes;
@property (nonatomic, assign) BOOL fromCustomConfig;

/// extrac prefix, channel, bundle from url string
+ (nullable NSDictionary *)extractGeckoInfoFormURL:(NSString *)urlString;

+ (nullable instancetype)remoteParametersWithURLString:(NSString *)urlString defaultPrefixToAccessKey:(nullable NSDictionary *)defaultPrefixToAccessKey;

@end

NS_ASSUME_NONNULL_END
