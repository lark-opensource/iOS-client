//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICERESOURCERESPONSEPROTOCOL_H_
#define DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICERESOURCERESPONSEPROTOCOL_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LynxServiceResourceResponseProtocol <NSObject>

typedef NS_ENUM(NSInteger, LynxServiceResourceDataSourceType) {
  LynxServiceResourceDataSourceTypeMissing,  // default value
  LynxServiceResourceDataSourceTypeGeckoLocal,
  LynxServiceResourceDataSourceTypeGeckoUpdate,
  LynxServiceResourceDataSourceTypeCDNOnline,
  LynxServiceResourceDataSourceTypeCDNCache,
  LynxServiceResourceDataSourceTypeBuiltin,
  LynxServiceResourceDataSourceTypeOther,
};

typedef NS_ENUM(NSInteger, LynxServiceResourceFetcherType) {
  LynxServiceResourceFetcherTypeGecko,
  LynxServiceResourceFetcherTypeBuiltin,
  LynxServiceResourceFetcherTypeCDN,
  LynxServiceResourceFetcherTypeMemory,
  LynxServiceResourceFetcherTypeCDNDownloader,
};

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
@property(nonatomic, assign) LynxServiceResourceDataSourceType sourceType;

- (nullable NSString *)resolvedURL;

/// The expired date of resource
- (nullable NSDate *)expiredDate;

/// The fetcher of this resource
- (nullable NSString *)fetcher;
/// debug info
- (nullable NSString *)debugInfo;
- (nullable NSString *)cacheKey;

- (BOOL)isTemplate;
- (BOOL)isSuccess;

- (nullable NSDictionary *)loaderInfo;
- (nullable NSDictionary *)errorInfo;
- (nullable NSDictionary *)resourceInfo;
- (nullable NSDictionary *)metricInfo;
- (nullable NSDictionary *)extraInfo;
- (nullable NSDictionary *)calculatedMetricInfo;

- (nullable NSString *)sourceTypeDescription;

@end

typedef void (^LynxServiceResourceCompletionHandler)(
    id<LynxServiceResourceResponseProtocol> __nullable response, NSError *__nullable error);

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICERESOURCERESPONSEPROTOCOL_H_
