//
//  BDXWebContentPreloadManager.h
//  BDXWebKit-Pods-AwemeCore
//
//  Created by bytedance on 2022/5/5.
//

#import <Foundation/Foundation.h>

@class BDPreloadCachedResponse;

@interface BDWebContentPreloadManager: NSObject

/// 预加载web页面
/// @param urls 预加载页面的url列表
/// @param userAgent 请求的UA
+ (void)preloadPageWithURLs:(NSArray * _Nonnull)urls userAgent:(NSString * _Nonnull)userAgent;


/// 预加载web页面
/// @param urls 预加载页面的url列表
/// @param userAgent 请求的UA
/// @param useHttpCaches 是否使用 HttpCaches 缓存策略
+ (void)preloadPageWithURLs:(NSArray * _Nonnull)urls userAgent:(NSString * _Nonnull)userAgent useHttpCaches:(BOOL)useHttpCaches;

/// 同步获取CDNCache
/// @params url url
+ (BDPreloadCachedResponse  * _Nullable)fetchWebResourceSync:(NSString * _Nonnull)url;


/// 保存response
/// @param response response
/// @param urlString url
+ (void)saveResponse:(nullable BDPreloadCachedResponse *)response forURLString:(NSString * _Nonnull)urlString;


/// 取消下载任务
/// @param urls urls
+ (void)cancelTasks:( NSArray * _Nonnull )urls;


/// 判断页面是否存在缓存
/// @param urlString url
+ (BOOL)existPageCacheForURLString:( NSString * _Nonnull)urlString;

@end
