//
//  SDWebImageAdapter.h
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/12/7.
//

#import <Foundation/Foundation.h>
#import "UIImageView+SDAdapter.h"
#import "UIButton+SDAdapter.h"
#import "SDWebImageAdapterConfig.h"
#import <SDWebImage/SDWebImageManager.h>
#import <SDWebImage/SDWebImagePrefetcher.h>
#import "BDWebImageRequest.h"


FOUNDATION_EXPORT BDImageRequestOptions BDOptionsWithSDManagerOptions(SDWebImageOptions sdOptions);
FOUNDATION_EXPORT BDImageRequestOptions BDOptionsWithSDDownloaderOptions(SDWebImageDownloaderOptions sdOptions);

@protocol SDWebImageAdapterOperationProtocol <SDWebImageOperation>

@end

@protocol SDWebImageAdapterTaskProtocol <NSObject>

- (nullable NSURL *)url;

@end


@interface SDWebImageAdapter : NSObject

#pragma mark - Config
+ (BOOL)useBDWebImage;
+ (void)setUseBDWebImage:(BOOL)useBDWebImage;
+ (void)setNeedClearDiskWhenChangeImageMode:(BOOL)needClear;
/**
 创建一个新构造的Adapter实例，一般只有特殊业务（比如说缓存路径，取消部分任务）需要，其它的情况都使用sharedAdapter，内部也使用了新构造的Manager

 @param config 可以指定构造出来的Adapter的配置项，在构造完成后修改属性无效，配置参考SDWebImageAdapterConfig
 @return 新构造的实例
 */
- (nonnull instancetype)initWithConfig:(nullable SDWebImageAdapterConfig *)config;
- (nonnull instancetype)init NS_UNAVAILABLE;

/**
 获取共享的Adapter实例，内部也使用了共享的Manager

 @return 共享的实例
 */
+ (nonnull instancetype)sharedAdapter;

@end

// 以下接口是作为桥接的接口，根据开关是否开启，可以切换使用BDWebImage和SDWebImage的实现。各个接口基本保持了和原始接口一致，关于各个参数的说明，参考SDWebImage的原始方法的文档

#pragma mark - Manager


@interface SDWebImageAdapter (Manager)

- (nullable id<SDWebImageAdapterOperationProtocol>)loadImageWithURL:(nullable NSURL *)url
                                                            options:(SDWebImageOptions)options
                                                           progress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                                                          completed:(nullable SDInternalCompletionBlock)completedBlock;

- (void)cancelAll;

- (nullable NSString *)cacheKeyForURL:(nullable NSURL *)url;

@end

#pragma mark - Downloader


@interface SDWebImageAdapter (Downloader)

- (nullable id<SDWebImageAdapterTaskProtocol>)downloadImageWithURL:(nullable NSURL *)url
                                                           options:(SDWebImageDownloaderOptions)options
                                                          progress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                                                         completed:(nullable SDWebImageDownloaderCompletedBlock)completedBlock;

- (void)cancel:(nullable id<SDWebImageAdapterTaskProtocol>)token;

- (void)cancelAllDownloads;

@end

#pragma mark - Prefetcher


@interface SDWebImageAdapter (Prefetcher)

- (void)prefetchURLs:(nullable NSArray<NSURL *> *)urls;

- (void)prefetchURLs:(nullable NSArray<NSURL *> *)urls
            progress:(nullable SDWebImagePrefetcherProgressBlock)progressBlock
           completed:(nullable SDWebImagePrefetcherCompletionBlock)completionBlock;

- (void)cancelPrefetching;

@end

#pragma mark - Cache


@interface SDWebImageAdapter (Cache)

- (void)storeImage:(nullable UIImage *)image
            forKey:(nullable NSString *)key
            toDisk:(BOOL)toDisk
        completion:(nullable SDWebImageNoParamsBlock)completionBlock;

- (void)storeImage:(nullable UIImage *)image
         imageData:(nullable NSData *)imageData
            forKey:(nullable NSString *)key
            toDisk:(BOOL)toDisk
        completion:(nullable SDWebImageNoParamsBlock)completionBlock;

- (void)storeImageDataToDisk:(nullable NSData *)imageData forKey:(nullable NSString *)key;

/**
 缓存图片到*硬盘*，此接口不会缓存到内存。要注意：
 1. 如果业务方设置了urlFilter，那url会被urlFilter转化成cacheKey，再使用这个cacheKey来缓存。
 2. 使用这个接口缓存的图片，要使用`imageFromCacheForURL:`来获取，或者先使用`cacheKeyForURL:`把url转化为cacheKey之后再使用其他接口。

 @param image j要缓存的图片
 @param url 要生成cacheKey的链接
 */
- (void)saveImageToCache:(nullable UIImage *)image forURL:(nullable NSURL *)url;

- (BOOL)diskImageExistsWithKey:(nullable NSString *)key;

- (void)diskImageExistsWithKey:(nullable NSString *)key completion:(nullable SDWebImageCheckCacheCompletionBlock)completionBlock;

- (nullable NSOperation *)queryCacheOperationForKey:(nullable NSString *)key done:(nullable SDCacheQueryCompletedBlock)doneBlock;

- (nullable UIImage *)imageFromMemoryCacheForKey:(nullable NSString *)key;

- (nullable UIImage *)imageFromDiskCacheForKey:(nullable NSString *)key;

- (nullable UIImage *)imageFromCacheForKey:(nullable NSString *)key;

/**
 获取缓存图片，会把url转化成cacheKey，这个过程中如果业务指定了urlFilter则会使用它来转化。
 
 @param url 要生成cacheKey的链接
 @return 图片
 */
- (nullable UIImage *)imageFromCacheForURL:(nonnull NSURL *)url;

- (void)removeImageForKey:(nullable NSString *)key fromDisk:(BOOL)fromDisk withCompletion:(nullable SDWebImageNoParamsBlock)completion;

- (nullable NSString *)defaultCachePathForKey:(nullable NSString *)key;

- (void)clearMemory;

- (void)clearDiskOnCompletion:(nullable SDWebImageNoParamsBlock)completion;

- (NSUInteger)getSize;

@end
