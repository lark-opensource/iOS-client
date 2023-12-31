//
//  TTAdSplashCache.h
//  Gallery
//
//  Created by Zhang Leonardo on 12-6-18.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kTopViewVideoInfoPreloadKey;

extern NSString * cachePathForKeyWithHashFolder(NSString *key);

/** 该类中使用的TTAdSplashImageInfosModel，一定要存在URI， 其他的可以没有 */
@class TTAdSplashImageInfosModel;

/// 开屏资源类型
typedef NS_ENUM(NSInteger, BDASplashResourceType) {
    BDASplashResourceTypeImage = 0, ///< 图片资源
    BDASplashResourceTypeVideo,     ///< 视频资源
};

@interface TTAdSplashCache : NSObject

+ (instancetype)sharedCache;

/**
 检测资源是否存在

 @param url 资源远程链接
 @return 存在返回 YES，否则返回 NO
 */
- (BOOL)isCacheExist:(NSString *)url;

/**
 检测图片资源是否存在
 
 @param model 图片数据 model
 @return 存在返回 YES，否则返回 NO
 */
- (BOOL)isImageInfosModelCacheExist:(TTAdSplashImageInfosModel *)model;

/**
 获取图片数据本地链接

 @param model 图片数据 model
 @return 本地存储路径
 */
- (NSString *)imageInfoModelCachePathIfExist:(TTAdSplashImageInfosModel *)model;

/**
 存储数据，主要用来存储图片数据

 @param data 资源二进制数据
 @param key 资源标识，一般为 URL，URI 等，这个 key 会进行 MD5 加密作为真正的存储关联 key
 @param expires 过期时间，传 0 的默认 10 天；传非 0 最大十天，即 MIN(expires, 10d）
 */
- (void)setData:(NSData *)data forKey:(NSString *)key expires:(NSTimeInterval)expires;

/// 根据 URI 构造一个存储这条数据的 path
/// @param key 图片对应的 URI
- (NSString *)cachePathWithKey:(NSString *)key;

/// 存储除了二进制数据之外的其他数据。二进制数据已经在其他地方存储了，然后调用此方法存储一些关联关系在磁盘
/// @param key 图片数据的 URI
/// @param expires 图片过期时间
- (void)saveInfoExceptDataWithKey:(NSString *)key expires:(NSTimeInterval)expires;

- (void)deleteDirtyPath:(NSString *)path;

/**
 根据 URL(或 URI) 获取数据，主要获取图片数据
 
 @param url 资源链接
 @return 资源二进制数据
 */
- (NSData *)dataForUrl:(NSString *)url;

/**
 根据视频的 id 来检测视频是否已经存储
 
 @param videoId 视频 id
 @return 已存储返回 YES，否则返回 NO
 */
+ (BOOL)isVideoCacheExistWithVideoId:(NSString *)videoId;

/**
 存储视频资源

 @param data 视频二进制数据
 @param videoId 视频唯一标识符，存储时这个 id 会进行 MD5 加密作为存储 key
 @param expires 过期时间，传 0 的默认 10 天；传非 0 最大十天，即 MIN(expires, 10d）
 */
- (void)setData:(NSData *)data forVideoId:(NSString *)videoId expires:(NSTimeInterval)expires;

/**
 获取视频本地存储路径
 
 @param videoId 视频唯一 id
 @return 本地存储路径
 */
+ (NSString *)cachePath4VideoWithVideoId:(NSString *)videoId;

/**
 更新缓存时间。如果是预览广告，会多次下发相同的创意，这个方法会频繁调用，造成不必要浪费。
 通常线上更改投放时间的情况比较少，此方法也就会调用比较少.

 @param key 资源标识符，存储时这个 key 会进行 MD5 加密作为存储 realKey
 @param expires 新的过期时间
 @param type 资源类型
 */
- (void)updateResourceExpiresWithKey:(NSString *)key expires:(NSTimeInterval)expires type:(BDASplashResourceType)type;

/**
 图片 or 视频资源缓存路径，json model 数据都存在了 NSUserDefaults 中，没有在这个路径下。

 @return 相对缓存路径
 */
- (NSString *)cachePath;

/**
 缓存数据大小，单位 MB
 
 @return 缓存数据大小
 */
+ (float)cacheSize;

/**
 *  进入后台时，清除过期资源。
 */
- (void)enterBackgroundClear;

/**
 清除缓存，同时清除 json model 数据和图片视频资源
 */
- (void)clearCache;

- (NSUInteger)getSize;
- (NSUInteger)getDiskCount;
- (void)calculateSizeWithCompletionBlock:(void (^)(NSUInteger fileCount, CGFloat totoalSize))completionBlock;

- (void)deletePreloadKeyForSplashAdid:(NSString *)splashAdId;
- (NSDictionary *)preloadVideoInfoForSplashAdId:(NSString *)splashAdId;
- (NSString *)preloadKeyForSplashAdId:(NSString *)splashAdId;
- (void)setPreloadVideoInfo:(NSDictionary *)videoInfo
              forSplashAdId:(NSString *)splashAdId
        withTimeoutInterval:(NSTimeInterval)timeoutInterval;

@end
