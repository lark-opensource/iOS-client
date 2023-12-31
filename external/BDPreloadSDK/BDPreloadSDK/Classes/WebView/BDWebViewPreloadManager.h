//
//  BDWebViewPreloadManager.h
//  BDPreloadSDK
//
//  Created by wealong on 2019/8/12.
//

#import <Foundation/Foundation.h>
#import <YYCache/YYDiskCache.h>

#import "BDPreloadCachedResponse.h"

NS_ASSUME_NONNULL_BEGIN

@class BDWebViewPreloadTask;

@interface BDWebViewPreloadManager : NSObject


+ (instancetype)sharedInstance;

// 内部的预加载资源，提供给外界做磁盘管理
@property (nonatomic, strong, readonly) YYDiskCache *diskCache;

// 预加载 WebView 资源接口
- (void)fetchDataForURLString:(NSString *)urlString
                  headerField:(NSDictionary *)headerField
                cacheDuration:(NSTimeInterval)cacheDuration
                queuePriority:(NSOperationQueuePriority)priority
                   completion:(void(^)(NSError *error))callback;

/**
 @param urlString The url string that you want to preload.
 @param headerField The header that you want to add to the request.
 @param useHttpCaches If you want to use the HTTP caches strategy. If this param is equal to YES, then we will use the HTTP strategy to cache the response. Otherwise, we will use cache duration as the cache duration.
 @param cacheDuration The time that the current resource is expected to cache. If useHttpCaches is equal to YES, we will ignore this param.
 @param queuePriority The priority of the current task queue.
 @param completion Callback of the request.
 @Note: When using this API to preload a resource, we will disable follow redirection, which means we will not redirect the 3xx response automatically. You will get a 3xx callback when the resource you are requesting return a 3xx code.
 */
- (void)fetchDataForURLString:(NSString *)urlString
                  headerField:(NSDictionary *)headerField
                useHttpCaches:(BOOL)useHttpCaches
                cacheDuration:(NSTimeInterval)cacheDuration
                queuePriority:(NSOperationQueuePriority)priority
                   completion:(void(^)(NSError *error))callback;


- (void)fetchDataForURLString:(NSString *)urlString
                  headerField:(NSDictionary *)headerField
                useHttpCaches:(BOOL)useHttpCaches
                cacheDuration:(NSTimeInterval)cacheDuration
                queuePriority:(NSOperationQueuePriority)priority
               dataCompletion:(void(^)(NSData * _Nullable data, NSError * _Nullable error))callback;

- (void)clearDataForURLString:(NSString *)urlString;
- (nullable BDPreloadCachedResponse *)responseForURLString:(NSString *)urlString;
- (nullable BDWebViewPreloadTask *)taskForURLString:(NSString *)urlString;
- (void)setTask:(BDWebViewPreloadTask *)preloadTask URLString:(NSString *)urlString;
- (void)saveResponse:(nullable BDPreloadCachedResponse *)response forURLString:(NSString *)urlString;

@end

NS_ASSUME_NONNULL_END
