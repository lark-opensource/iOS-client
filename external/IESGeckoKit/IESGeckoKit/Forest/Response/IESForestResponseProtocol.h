// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, IESForestDataSourceType);

@protocol IESForestResponseProtocol <NSObject>

/// resource url
- (nullable NSString *)sourceUrl;

/// Gecko AccessKey
- (nullable NSString *)accessKey;
/// Gecko channel
- (nullable NSString *)channel;
/// Gecko bundle - resource relative path
- (nullable NSString *)bundle;
/// Gecko version
- (uint64_t)version;

/// The absolute local resource path
- (nullable NSString *)absolutePath;
/// The content of resource
- (nullable NSData *)data;

/// The source type of resource
- (IESForestDataSourceType)sourceType;

/// The expired date of resource
@property (nonatomic, strong) NSDate *expiredDate;
/// The fetcher of this resource
@property (nonatomic, copy, readonly) NSString *fetcher;

/// debug info
@property (nonatomic, copy) NSString *debugInfo;

@end

NS_ASSUME_NONNULL_END
