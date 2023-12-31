//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICERESOURCEPROTOCOL_H_
#define DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICERESOURCEPROTOCOL_H_
#import <Foundation/Foundation.h>
#import "LynxServiceProtocol.h"
#import "LynxServiceResourceRequestOperationProtocol.h"
#import "LynxServiceResourceRequestParameters.h"
#import "LynxServiceResourceResponseProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LynxServiceResourceProtocol <LynxServiceProtocol>

/// whether url is gecko CDN url
- (BOOL)isGeckoResource:(NSString *)url;

/// whether url can receive gecko resource, if not return nil
- (nullable NSString *)geckoResourcePathForURLString:(NSString *)url;

/// Fetch resource ASYNC according to URLString, requestParameters
/// The workflow will iterate all the fetchers to fetch resource until one fetch resource
/// successfully, or all fetchers failed.
/// @param url  resource url
/// @param parameters  additional request parameters
/// @param completionHandler  completion callback
/// @result  RequestOperation, can be used to cancel a request
- (nullable id<LynxServiceResourceRequestOperationProtocol>)
    fetchResourceAsync:(NSString *)url
            parameters:(nullable LynxServiceResourceRequestParameters *)parameters
            completion:(nullable LynxServiceResourceCompletionHandler)completionHandler;

/// Fetch resource ASYNC according to URLString, requestParameters
/// The workflow will iterate all the fetchers to fetch resource until one fetch resource
/// successfully, or all fetchers failed.
/// @param url  resource url
/// @param parameters  additional request parameters
/// @result  ResourceResponse, contains resource data and meta info
- (nullable id<LynxServiceResourceResponseProtocol>)
    fetchResourceSync:(NSString *)url
           parameters:(nullable LynxServiceResourceRequestParameters *)parameters
                error:(NSError *_Nullable *)errorPtr;

/// Preload media resource
- (void)preloadMedia:(NSString *)url
            cacheKey:(NSString *)cacheKey
             videoID:(nullable NSString *)videoID
          videoModel:(nullable NSDictionary *)videoModel
          resolution:(NSUInteger)resolution
          encodeType:(NSUInteger)encodeType
           apiString:(nullable NSString *)apiString
                size:(NSInteger)size;

/// Cancel preload media resource
- (void)cancelPreloadMedia:(NSString *)cacheKey
                   videoID:(nullable NSString *)videoID
                videoModel:(BOOL)videoModel;

@end

NS_ASSUME_NONNULL_END
#endif  // DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICERESOURCEPROTOCOL_H_
