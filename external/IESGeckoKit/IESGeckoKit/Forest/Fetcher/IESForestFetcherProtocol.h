// Copyright 2022. The Cross Platform Authors. All rights reserved.

NS_ASSUME_NONNULL_BEGIN

@protocol IESForestResponseProtocol;
@class IESForestRequest;

typedef void (^IESForestFetcherCompletionHandler)(id<IESForestResponseProtocol> __nullable response, NSError *__nullable error);

typedef NS_ENUM(NSInteger, IESForestDataSourceType) {
    IESForestDataSourceTypeMissing,          // default value
    IESForestDataSourceTypeGeckoLocal,
    IESForestDataSourceTypeGeckoUpdate,
    IESForestDataSourceTypeCDNOnline,
    IESForestDataSourceTypeCDNCache,
    IESForestDataSourceTypeBuiltin,
    IESForestDataSourceTypeOther,
};

typedef NS_ENUM(NSInteger, IESForestFetcherType) {
    IESForestFetcherTypeGecko,
    IESForestFetcherTypeBuiltin,
    IESForestFetcherTypeCDN,
    IESForestFetcherTypeMemory,
    IESForestFetcherTypeCDNDownloader,
};

#pragma mark -- IESGForestFetcherProtocol

@protocol IESForestFetcherProtocol <NSObject>

@property (nonatomic, copy, readonly) NSString *name;

/// @abstract override this method to fetch resource
/// @param request request parameters
/// @param completion  completion callback
- (void)fetchResourceWithRequest:(IESForestRequest *)request
                      completion:(nullable IESForestFetcherCompletionHandler)completion;

/// @abstract override this method to cancel fetch resource
- (void)cancelFetch;

@optional

- (NSString *)debugMessage;
+ (NSString *)fetcherName;

@end

NS_ASSUME_NONNULL_END
