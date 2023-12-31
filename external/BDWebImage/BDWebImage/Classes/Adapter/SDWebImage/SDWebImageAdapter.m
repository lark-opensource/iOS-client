//
//  SDWebImageAdapter.m
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/12/7.
//

#import "SDWebImageAdapter.h"
#import "SDWebImageAdapterConfig.h"
//#import "BDWebImage.h"
#import <SDWebImage/SDImageCache.h>
#import <libkern/OSAtomic.h>
#import "BDWebImageMacro.h"
#import "BDWebImageURLFilter.h"
#import "BDWebImageManager.h"
#import "BDWebImageRequest+TTMonitor.h"


inline BDImageRequestOptions BDOptionsWithSDManagerOptions(SDWebImageOptions sdOptions) {
    BDImageRequestOptions options = BDImageRequestDefaultOptions;
    if (sdOptions & SDWebImageLowPriority) {
        options |= BDImageRequestLowPriority;
    }
    if (sdOptions & SDWebImageHighPriority) {
        options |= BDImageRequestHighPriority;
    }
    if (sdOptions & SDWebImageCacheMemoryOnly) {
        options |= BDImageRequestNotCacheToDisk;
    }
    if (sdOptions & SDWebImageAvoidAutoSetImage) {
        options |= BDImageRequestSetDelaySetImage;
    }
    return options;
}

inline BDImageRequestOptions BDOptionsWithSDDownloaderOptions(SDWebImageDownloaderOptions sdOptions) {
    BDImageRequestOptions options = BDImageRequestDefaultPriority; // SDWebImageDownloader不查找缓存，下载完成也不缓存，保持行为一致
    if (sdOptions & SDWebImageDownloaderLowPriority) {
        options |= BDImageRequestLowPriority;
    }
    if (sdOptions & SDWebImageDownloaderHighPriority) {
        options |= BDImageRequestHighPriority;
    }
    if (sdOptions & SDWebImageDownloaderContinueInBackground) {
        options |= BDImageRequestContinueInBackground;
    }
    return options;
}

static BOOL sdAdapterUseBDImage = NO;
static BOOL sdAdapterInited = NO;
static BOOL sdNeedClearDisk = NO;

#pragma mark - Category


@interface BDWebImageRequest (SDAdapter) <SDWebImageAdapterOperationProtocol, SDWebImageAdapterTaskProtocol>

@end


@implementation BDWebImageRequest (SDAdapter)

- (NSURL *)url {
    return self.currentRequestURL;
}

@end


@interface SDWebImageDownloadToken (SDAdapter) <SDWebImageAdapterTaskProtocol>

@end


@implementation SDWebImageDownloadToken (SDAdapter)

@end


@interface SDWebImageManager (SDAdapter)

@property (nonatomic, weak) SDWebImagePrefetcher *sda_imagePrefetcher;

@end


@implementation SDWebImageManager (SDAdapter)

- (SDWebImagePrefetcher *)sda_imagePrefetcher {
    return BD_GET_WEAK(sda_imagePrefetcher);
}

- (void)setSda_imagePrefetcher:(SDWebImagePrefetcher *)sda_imagePrefetcher {
    BD_SET_WEAK(sda_imagePrefetcher);
}

@end


@interface SDImageCache (SDAdapter)

- (BOOL)sda_diskImageExistsWithKey:(NSString *)key;

@end


@implementation SDImageCache (SDAdapter)

- (BOOL)sda_diskImageExistsWithKey:(NSString *)key {
    BOOL exists = NO;

    // this is an exception to access the filemanager on another queue than ioQueue, but we are using the shared instance
    // from apple docs on NSFileManager: The methods of the shared NSFileManager object can be called from multiple threads safely.
    exists = [[NSFileManager defaultManager] fileExistsAtPath:[self defaultCachePathForKey:key]];

    // fallback because of https://github.com/rs/SDWebImage/pull/976 that added the extension to the disk file name
    // checking the key with and without the extension
    if (!exists) {
        exists = [[NSFileManager defaultManager] fileExistsAtPath:[[self defaultCachePathForKey:key] stringByDeletingPathExtension]];
    }

    return exists;
}

@end

#pragma mark - Filter


@interface SDWebImageAdapterURLFilter : BDWebImageURLFilter

@property (nonatomic, copy, nonnull) SDWebImageCacheKeyFilterBlock cacheKeyFilter;

+ (instancetype)filterWithCacheKeyFilter:(nonnull SDWebImageCacheKeyFilterBlock)cacheKeyFilter;

@end


@implementation SDWebImageAdapterURLFilter

+ (instancetype)filterWithCacheKeyFilter:(nonnull SDWebImageCacheKeyFilterBlock)cacheKeyFilter {
    NSParameterAssert(cacheKeyFilter);
    SDWebImageAdapterURLFilter *filter = [[SDWebImageAdapterURLFilter alloc] init];
    filter.cacheKeyFilter = cacheKeyFilter;
    return filter;
}

- (NSString *)identifierWithURL:(NSURL *)url {
    NSString *identifier;
    if (self.cacheKeyFilter) {
        identifier = self.cacheKeyFilter(url);
    }
    return identifier;
}

@end

#pragma mark - Adapter


@interface SDWebImageAdapter ()

@property (nonatomic, copy) SDWebImageAdapterConfig *config;
@property (nonatomic, strong) BDWebImageManager *bdManager;
@property (nonatomic, strong) SDWebImageManager *sdManager;

@property (atomic, assign) int64_t noOfTotalUrls;
@property (atomic, assign) int64_t noOfFinishedUrls;
@property (atomic, assign) int64_t noOfSkippedUrls;

@end


@implementation SDWebImageAdapter

static NSString *const SDADAPTER_USE_BDWEBIMAGE_KEY = @"sdadapter_use_bdwebimage";

+ (void)initialize {
    if (self == [SDWebImageAdapter class]) {
        sdAdapterUseBDImage = [[NSUserDefaults standardUserDefaults] boolForKey:SDADAPTER_USE_BDWEBIMAGE_KEY];
    }
}

#pragma mark - Config
- (instancetype)initWithConfig:(SDWebImageAdapterConfig *)config {
    self = [super init];
    if (self) {
        sdAdapterInited = YES;
        self.config = config;
        if (sdAdapterUseBDImage) {
            _bdManager = [[BDWebImageManager alloc] initWithCategory:isEmptyString(config.cacheNameSpace) ? nil : config.cacheNameSpace];
            if (config.cacheKeyFilter) {
                _bdManager.urlFilter = [SDWebImageAdapterURLFilter filterWithCacheKeyFilter:config.cacheKeyFilter];
            }
            if (config.executionOrder) {
                SEL setStackModeSEL = NSSelectorFromString(@"setStackMode:");
                if ([_bdManager.downloadManager respondsToSelector:setStackModeSEL]) {
                    NSUInteger stackMode = config.executionOrder;
                    NSMethodSignature *signature = [[_bdManager.downloadManager class] instanceMethodSignatureForSelector:setStackModeSEL];
                    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
                    invocation.selector = setStackModeSEL;
                    invocation.target = _bdManager.downloadManager;
                    [invocation setArgument:&stackMode atIndex:2];
                    [invocation invoke];
                }
            }
        } else {
            if (!isEmptyString(config.cacheNameSpace)) {
                SDImageCache *sdCache = [[SDImageCache alloc] initWithNamespace:config.cacheNameSpace];
                _sdManager = [[SDWebImageManager alloc] initWithCache:sdCache downloader:[SDWebImageDownloader sharedDownloader]];
            } else {
                _sdManager = [[SDWebImageManager alloc] init];
            }
            SDWebImagePrefetcher *prefetcher = [[SDWebImagePrefetcher alloc] initWithImageManager:_sdManager];
            _sdManager.sda_imagePrefetcher = prefetcher;
            if (config.cacheKeyFilter) {
                _sdManager.cacheKeyFilter = config.cacheKeyFilter;
            }
            if (config.executionOrder) {
                _sdManager.imageDownloader.executionOrder = config.executionOrder;
            }
        }
    }
    return self;
}

- (instancetype)initSharedAdapter {
    self = [super init];
    if (self) {
        sdAdapterInited = YES;
        if (sdAdapterUseBDImage) {
            _bdManager = [BDWebImageManager sharedManager];
        } else {
            _sdManager = [SDWebImageManager sharedManager];
            _sdManager.sda_imagePrefetcher = [SDWebImagePrefetcher sharedImagePrefetcher];
        }
    }
    return self;
}

- (SDWebImageManager *)sdManager {
    if (!_sdManager) {
        _sdManager = [SDWebImageManager sharedManager];
        _sdManager.sda_imagePrefetcher = [SDWebImagePrefetcher sharedImagePrefetcher];
    }
    return _sdManager;
}

- (BDWebImageManager *)bdManager {
    if (!_bdManager) {
        _bdManager = [BDWebImageManager sharedManager];
    }
    return _bdManager;
}

+ (instancetype)sharedAdapter {
    static dispatch_once_t onceToken;
    static SDWebImageAdapter *adapter;
    dispatch_once(&onceToken, ^{
        adapter = [[SDWebImageAdapter alloc] initSharedAdapter];
    });
    return adapter;
}

+ (BOOL)useBDWebImage {
    return sdAdapterUseBDImage;
}

+ (void)setUseBDWebImage:(BOOL)useBDWebImage {
    if (!sdAdapterInited) {
        [self _clearDiskifNeeded];
        sdAdapterUseBDImage = useBDWebImage;
    } else {
        if (nil == NSClassFromString(@"BaseTestCase")) { // 单元测试频繁调用接口引起断言阻碍测试用例
            NSCAssert(NO, @"请保证 +setUseBDWebImage 调用在 SDWebImageAdapter 初始化之前");
        }
        sdAdapterUseBDImage = useBDWebImage;
    }
    [[NSUserDefaults standardUserDefaults] setBool:useBDWebImage forKey:SDADAPTER_USE_BDWEBIMAGE_KEY];
}

+ (void)setNeedClearDiskWhenChangeImageMode:(BOOL)needClear {
    sdNeedClearDisk = needClear;
}

#pragma mark - private Method

+ (void)_clearDiskifNeeded {
    if (sdNeedClearDisk) {
        [[[self class] sharedAdapter] clearDiskOnCompletion:nil];
    }
}

#pragma mark - Manager
- (id<SDWebImageAdapterOperationProtocol>)loadImageWithURL:(NSURL *)url
                                                   options:(SDWebImageOptions)options
                                                  progress:(SDWebImageDownloaderProgressBlock)progressBlock
                                                 completed:(SDInternalCompletionBlock)completedBlock {
    if (sdAdapterUseBDImage) {
        BDWebImageRequest *request = [self.bdManager requestImage:url
                                                  alternativeURLs:nil
                                                          options:BDOptionsWithSDManagerOptions(options)
                                                        cacheName:nil
                                                         progress:progressBlock ? ^(BDWebImageRequest *request, NSInteger receivedSize, NSInteger expectedSize) {
                                                             progressBlock(receivedSize, expectedSize, request.currentRequestURL);
                                                         } :
                                                                                  nil
                                                         complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                                                             if (completedBlock) {
                                                                 SDImageCacheType cacheType = SDImageCacheTypeNone;
                                                                 if (from == BDWebImageResultFromDiskCache) {
                                                                     cacheType = SDImageCacheTypeDisk;
                                                                 } else if (from == BDWebImageResultFromMemoryCache) {
                                                                     cacheType = SDImageCacheTypeMemory;
                                                                 }
                                                                 completedBlock(image, data, error, cacheType, YES, request.currentRequestURL);
                                                             }
                                                         }];
        return request;
    } else {
        return (id<SDWebImageAdapterOperationProtocol>)[self.sdManager loadImageWithURL:url options:options progress:progressBlock completed:completedBlock];
    }
}

- (void)cancelAll {
    if (sdAdapterUseBDImage) {
        [self.bdManager cancelAll];
    } else {
        [self.sdManager cancelAll];
    }
}

- (NSString *)cacheKeyForURL:(NSURL *)url {
    NSString *key;
    if (sdAdapterUseBDImage) {
        key = [self.bdManager requestKeyWithURL:url];
    } else {
        key = [self.sdManager cacheKeyForURL:url];
    }
    return key;
}

#pragma mark - Downloader
- (id<SDWebImageAdapterTaskProtocol>)downloadImageWithURL:(NSURL *)url
                                                  options:(SDWebImageDownloaderOptions)options
                                                 progress:(SDWebImageDownloaderProgressBlock)progressBlock
                                                completed:(SDWebImageDownloaderCompletedBlock)completedBlock {
    if (sdAdapterUseBDImage) {
        BDImageRequestOptions bdOptions = BDOptionsWithSDDownloaderOptions(options) | BDImageRequestIgnoreCache;
        BDWebImageRequest *request = [self.bdManager requestImage:url
                                                  alternativeURLs:nil
                                                          options:bdOptions
                                                        cacheName:nil
                                                         progress:progressBlock ? ^(BDWebImageRequest *request, NSInteger receivedSize, NSInteger expectedSize) {
                                                             progressBlock(receivedSize, expectedSize, request.currentRequestURL);
                                                         } :
                                                                                  nil
                                                         complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                                                             if (completedBlock) {
                                                                 completedBlock(image, data, error, YES);
                                                             }
                                                         }];
        return request;
    } else {
        return [self.sdManager.imageDownloader downloadImageWithURL:url options:options progress:progressBlock completed:completedBlock];
    }
}

- (void)cancel:(id<SDWebImageAdapterTaskProtocol>)token {
    if (!token) {
        return;
    }
    if (sdAdapterUseBDImage) {
        if ([token isKindOfClass:[BDWebImageRequest class]]) {
            [((BDWebImageRequest *)token)cancel];
        }
    } else {
        if ([token isKindOfClass:[SDWebImageDownloadToken class]]) {
            SDWebImageDownloadToken *sdToken = (SDWebImageDownloadToken *)token;
            [self.sdManager.imageDownloader cancel:sdToken];
        }
    }
}

- (void)cancelAllDownloads {
    if (sdAdapterUseBDImage) {
        [self.bdManager cancelAll];
    } else {
        [self.sdManager.imageDownloader cancelAllDownloads];
    }
}

#pragma mark - Prefetcher
- (void)prefetchURLs:(NSArray<NSURL *> *)urls {
    [self prefetchURLs:urls progress:nil completed:nil];
}

- (void)prefetchURLs:(NSArray<NSURL *> *)urls
            progress:(SDWebImagePrefetcherProgressBlock)progressBlock
           completed:(SDWebImagePrefetcherCompletionBlock)completionBlock {
    if (sdAdapterUseBDImage) {
        [self.bdManager cancelAllPrefetchs];
        NSArray<BDWebImageRequest *> *requests = [self.bdManager prefetchImagesWithURLs:urls
                                                                               category:nil
                                                                                options:BDImageRequestDefaultOptions];
        self.noOfTotalUrls = requests.count;
        self.noOfSkippedUrls = 0;
        self.noOfFinishedUrls = 0;

        for (BDWebImageRequest *request in requests) {
            __weak typeof(self) wself = self;
            request.completedBlock = ^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                __strong typeof(wself) self = wself;
                if (!error) {
                    [self atomicIncrementFinishedUrls];
                } else {
                    [self atomicIncrementSkippedUrls];
                }
                if (progressBlock) {
                    progressBlock(self.noOfFinishedUrls, self.noOfTotalUrls);
                }
                if (self.noOfFinishedUrls + self.noOfSkippedUrls == self.noOfTotalUrls) {
                    if (completionBlock) {
                        completionBlock(self.noOfFinishedUrls, self.noOfSkippedUrls);
                    }
                }
            };
        }
    } else {
        [self.sdManager.sda_imagePrefetcher prefetchURLs:urls progress:progressBlock completed:completionBlock];
    }
}

- (void)atomicIncrementFinishedUrls {
    self.noOfFinishedUrls = OSAtomicIncrement64(&_noOfFinishedUrls);
}

- (void)atomicIncrementSkippedUrls {
    self.noOfSkippedUrls = OSAtomicIncrement64(&_noOfSkippedUrls);
}

- (void)cancelPrefetching {
    if (sdAdapterUseBDImage) {
        [self.bdManager cancelAllPrefetchs];
    } else {
        [self.sdManager.sda_imagePrefetcher cancelPrefetching];
    }
}

#pragma mark - Cache
- (void)storeImage:(nullable UIImage *)image
            forKey:(nullable NSString *)key
            toDisk:(BOOL)toDisk
        completion:(nullable SDWebImageNoParamsBlock)completionBlock {
    [self storeImage:image imageData:nil forKey:key toDisk:toDisk completion:completionBlock];
}
- (void)storeImage:(UIImage *)image imageData:(NSData *)imageData forKey:(NSString *)key toDisk:(BOOL)toDisk completion:(SDWebImageNoParamsBlock)completionBlock {
    if (!image || !key) {
        if (completionBlock) {
            completionBlock();
        }
        return;
    }
    if (sdAdapterUseBDImage) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            BDImageCacheType type;
            if (toDisk) {
                type = BDImageCacheTypeAll;
            } else {
                type = BDImageCacheTypeMemory;
            }
            [self.bdManager.imageCache setImage:image imageData:imageData forKey:key withType:type];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionBlock) {
                    completionBlock();
                }
            });
        });
    } else {
        [self.sdManager.imageCache storeImage:image imageData:imageData forKey:key toDisk:toDisk completion:completionBlock];
    }
}

- (void)storeImageDataToDisk:(NSData *)imageData forKey:(NSString *)key {
    if (!imageData || !key) {
        return;
    }
    if (sdAdapterUseBDImage) {
        [self.bdManager.imageCache saveImageToDisk:nil data:imageData forKey:key];
    } else {
        [self.sdManager.imageCache storeImageDataToDisk:imageData forKey:key];
    }
}

- (void)saveImageToCache:(nullable UIImage *)image forURL:(nullable NSURL *)url {
    if (!image || !url) {
        return;
    }
    if (sdAdapterUseBDImage) {
        NSString *key = [self cacheKeyForURL:url];
        [self.bdManager.imageCache saveImageToDisk:image data:nil forKey:key callBack:nil];
    } else {
        [self.sdManager saveImageToCache:image forURL:url];
    }
}

- (BOOL)diskImageExistsWithKey:(NSString *)key {
    BOOL exists = NO;
    if (sdAdapterUseBDImage) {
        exists = [self.bdManager.imageCache containsImageForKey:key type:BDImageCacheTypeDisk];
    } else {
        exists = [self.sdManager.imageCache sda_diskImageExistsWithKey:key];
    }
    return exists;
}

- (void)diskImageExistsWithKey:(NSString *)key completion:(SDWebImageCheckCacheCompletionBlock)completionBlock {
    if (!key) {
        if (completionBlock) {
            completionBlock(NO);
        }
        return;
    }
    if (sdAdapterUseBDImage) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            BOOL isInCache = [self.bdManager.imageCache containsImageForKey:key type:BDImageCacheTypeDisk];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionBlock) {
                    completionBlock(isInCache);
                }
            });
        });
    } else {
        [self.sdManager.imageCache diskImageExistsWithKey:key completion:completionBlock];
    }
}

- (NSOperation *)queryCacheOperationForKey:(NSString *)key done:(SDCacheQueryCompletedBlock)doneBlock {
    if (!key) {
        if (doneBlock) {
            doneBlock(nil, nil, SDImageCacheTypeNone);
        }
        return nil;
    }
    NSOperation *operation;
    if (sdAdapterUseBDImage) {
        operation = [NSOperation new];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (operation.isCancelled) {
                // do not call the completion if cancelled
                return;
            }
            BDImageCacheType type = BDImageCacheTypeMemory;
            NSData *imageData = [self.bdManager.imageCache imageDataForKey:key];
            UIImage *image = [self.bdManager.imageCache imageForKey:key withType:&type];
            if (type == BDImageCacheTypeNone) {
                // not in memory
                type = BDImageCacheTypeDisk;
                image = [self.bdManager.imageCache imageForKey:key withType:&type];
            }
            SDImageCacheType cacheType = SDImageCacheTypeNone;
            if (type == BDImageCacheTypeMemory) {
                cacheType = SDImageCacheTypeMemory;
            } else if (type == BDImageCacheTypeDisk) {
                cacheType = SDImageCacheTypeDisk;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (doneBlock) {
                    doneBlock(image, imageData, cacheType);
                }
            });
        });
    } else {
        operation = [self.sdManager.imageCache queryCacheOperationForKey:key done:doneBlock];
    }
    return operation;
}

- (UIImage *)imageFromMemoryCacheForKey:(NSString *)key {
    if (!key) {
        return nil;
    }
    UIImage *image;
    if (sdAdapterUseBDImage) {
        BDImageCacheType type = BDImageCacheTypeMemory;
        image = [self.bdManager.imageCache imageForKey:key withType:&type];
    } else {
        image = [self.sdManager.imageCache imageFromMemoryCacheForKey:key];
    }
    return image;
}

- (UIImage *)imageFromDiskCacheForKey:(NSString *)key {
    if (!key) {
        return nil;
    }
    UIImage *image;
    if (sdAdapterUseBDImage) {
        BDImageCacheType type = BDImageCacheTypeDisk;
        image = [self.bdManager.imageCache imageForKey:key withType:&type];
    } else {
        image = [self.sdManager.imageCache imageFromDiskCacheForKey:key];
    }
    return image;
}

- (UIImage *)imageFromCacheForKey:(NSString *)key {
    if (!key) {
        return nil;
    }
    UIImage *image;
    if (sdAdapterUseBDImage) {
        BDImageCacheType type = BDImageCacheTypeAll;
        image = [self.bdManager.imageCache imageForKey:key withType:&type];
    } else {
        image = [self.sdManager.imageCache imageFromCacheForKey:key];
    }
    return image;
}

- (nullable UIImage *)imageFromCacheForURL:(nonnull NSURL *)url {
    NSString *cacheKey = [self cacheKeyForURL:url];
    return [self imageFromCacheForKey:cacheKey];
}

- (void)removeImageForKey:(NSString *)key fromDisk:(BOOL)fromDisk withCompletion:(SDWebImageNoParamsBlock)completion {
    if (!key) {
        if (completion) {
            completion();
        }
        return;
    }
    if (sdAdapterUseBDImage) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            BDImageCacheType type;
            if (fromDisk) {
                type = BDImageCacheTypeAll;
            } else {
                type = BDImageCacheTypeMemory;
            }
            [self.bdManager.imageCache removeImageForKey:key withType:type];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion();
                }
            });
        });
    } else {
        [self.sdManager.imageCache removeImageForKey:key fromDisk:fromDisk withCompletion:completion];
    }
}

- (NSString *)defaultCachePathForKey:(NSString *)key {
    NSString *cachePath;
    if (sdAdapterUseBDImage) {
        cachePath = [self.bdManager.imageCache cachePathForKey:key];
    } else {
        cachePath = [self.sdManager.imageCache defaultCachePathForKey:key];
    }
    return cachePath;
}

- (void)clearMemory {
    if (sdAdapterUseBDImage) {
        [self.bdManager.imageCache clearMemory];
    } else {
        [self.sdManager.imageCache clearMemory];
    }
}

- (void)clearDisk {
    [self clearDiskOnCompletion:nil];
}

- (void)clearDiskOnCompletion:(SDWebImageNoParamsBlock)completion {
    if (sdAdapterUseBDImage) {
        [self.bdManager.imageCache clearDiskWithBlock:completion];
    } else {
        [self.sdManager.imageCache clearDiskOnCompletion:completion];
    }
}

- (NSUInteger)getSize {
    NSUInteger size;
    if (sdAdapterUseBDImage) {
        size = [self.bdManager.imageCache totalDiskSize];
    } else {
        size = [self.sdManager.imageCache getSize];
    }
    return size;
}

@end
