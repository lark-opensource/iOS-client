//
//  SDInterface.m
//  BDWebImage
//
//  Created by 陈奕 on 2020/1/6.
//

#import "SDInterface.h"
#import <libkern/OSAtomic.h>

#pragma mark - Adapter

@interface SDInterface ()

@property (nonatomic, strong) BDWebImageManager *bdManager;

@property (atomic, assign) int64_t noOfTotalUrls;
@property (atomic, assign) int64_t noOfFinishedUrls;
@property (atomic, assign) int64_t noOfSkippedUrls;

@end

@implementation SDInterface

- (instancetype)initSharedInterface {
    self = [super init];
    if (self) {
        _bdManager = [BDWebImageManager sharedManager];
    }
    return self;
}

- (BDWebImageManager *)bdManager {
    if (!_bdManager) {
        _bdManager = [BDWebImageManager sharedManager];
    }
    return _bdManager;
}

+ (instancetype)sharedInterface {
    static dispatch_once_t onceToken;
    static SDInterface *interface;
    dispatch_once(&onceToken, ^{
        interface = [[SDInterface alloc] initSharedInterface];
    });
    return interface;
}

#pragma mark - Manager
- (BDWebImageRequest *)loadImageWithURL:(NSURL *)url
                                options:(BDImageRequestOptions)options
                               progress:(SDInterfaceDownloaderProgressBlock)progressBlock
                              completed:(SDInterfaceInternalCompletionBlock)completedBlock {
        BDWebImageRequest *request = [self.bdManager requestImage:url
                                                  alternativeURLs:nil
                                                          options:options
                                                        cacheName:nil
                                                         progress:progressBlock ? ^(BDWebImageRequest *request, NSInteger receivedSize, NSInteger expectedSize) {
                                                             progressBlock(receivedSize, expectedSize, request.currentRequestURL);
                                                         } :
                                                                                  nil
                                                         complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
                                                             if (completedBlock) {
                                                                 BDImageCacheType cacheType = BDImageCacheTypeNone;
                                                                 if (from == BDWebImageResultFromDiskCache) {
                                                                     cacheType = BDImageCacheTypeDisk;
                                                                 } else if (from == BDWebImageResultFromMemoryCache) {
                                                                     cacheType = BDImageCacheTypeMemory;
                                                                 }
                                                                 completedBlock(image, data, error, cacheType, YES, request.currentRequestURL);
                                                             }
                                                         }];
        return request;
}

- (void)cancelAll {
    [self.bdManager cancelAll];
}

- (NSString *)cacheKeyForURL:(NSURL *)url {
    return [self.bdManager requestKeyWithURL:url];
}

#pragma mark - Downloader
- (BDWebImageRequest *)downloadImageWithURL:(NSURL *)url
                                    options:(BDImageRequestOptions)options
                                   progress:(SDInterfaceDownloaderProgressBlock)progressBlock
                                  completed:(SDInterfaceDownloaderCompletedBlock)completedBlock {
        BDWebImageRequest *request = [self.bdManager requestImage:url
                                                  alternativeURLs:nil
                                                          options:(options | BDImageRequestNeedCachePath)
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
}

- (void)cancel:(BDWebImageRequest *)token {
    if (!token) {
        return;
    }
    [token cancel];
}

- (void)cancelAllDownloads {
    [self.bdManager cancelAll];
}

#pragma mark - Prefetcher
- (void)prefetchURLs:(NSArray<NSURL *> *)urls {
    [self prefetchURLs:urls progress:nil completed:nil];
}

- (void)prefetchURLs:(NSArray<NSURL *> *)urls
            progress:(SDInterfacePrefetcherProgressBlock)progressBlock
           completed:(SDInterfacePrefetcherCompletionBlock)completionBlock {
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
}

- (void)atomicIncrementFinishedUrls {
    self.noOfFinishedUrls = OSAtomicIncrement64(&_noOfFinishedUrls);
}

- (void)atomicIncrementSkippedUrls {
    self.noOfSkippedUrls = OSAtomicIncrement64(&_noOfSkippedUrls);
}

- (void)cancelPrefetching {
    [self.bdManager cancelAllPrefetchs];
}

#pragma mark - Cache
- (void)storeImage:(nullable UIImage *)image
            forKey:(nullable NSString *)key
            toDisk:(BOOL)toDisk
        completion:(nullable SDInterfaceNoParamsBlock)completionBlock {
    [self storeImage:image imageData:nil forKey:key toDisk:toDisk completion:completionBlock];
}
- (void)storeImage:(UIImage *)image imageData:(NSData *)imageData forKey:(NSString *)key toDisk:(BOOL)toDisk completion:(SDInterfaceNoParamsBlock)completionBlock {
    if (!image || !key) {
        if (completionBlock) {
            completionBlock();
        }
        return;
    }
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
}

- (void)storeImageDataToDisk:(NSData *)imageData forKey:(NSString *)key {
    if (!imageData || !key) {
        return;
    }
    [self.bdManager.imageCache saveImageToDisk:nil data:imageData forKey:key];
}

- (void)saveImageToCache:(nullable UIImage *)image forURL:(nullable NSURL *)url {
    if (!image || !url) {
        return;
    }
    NSString *key = [self cacheKeyForURL:url];
    [self.bdManager.imageCache saveImageToDisk:image data:nil forKey:key callBack:nil];
}

- (BOOL)diskImageExistsWithKey:(NSString *)key {
    return [self.bdManager.imageCache containsImageForKey:key type:BDImageCacheTypeDisk];
}

- (void)diskImageExistsWithKey:(NSString *)key completion:(SDInterfaceCheckCacheCompletionBlock)completionBlock {
    if (!key) {
        if (completionBlock) {
            completionBlock(NO);
        }
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL isInCache = [self.bdManager.imageCache containsImageForKey:key type:BDImageCacheTypeDisk];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionBlock) {
                completionBlock(isInCache);
            }
        });
    });
}

- (NSOperation *)queryCacheOperationForKey:(NSString *)key done:(SDInterfaceCacheQueryCompletedBlock)doneBlock {
    if (!key) {
        if (doneBlock) {
            doneBlock(nil, nil, BDImageCacheTypeNone);
        }
        return nil;
    }
    NSOperation *operation;
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
        BDImageCacheType cacheType = BDImageCacheTypeNone;
        if (type == BDImageCacheTypeMemory) {
            cacheType = BDImageCacheTypeMemory;
        } else if (type == BDImageCacheTypeDisk) {
            cacheType = BDImageCacheTypeDisk;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (doneBlock) {
                doneBlock(image, imageData, cacheType);
            }
        });
    });
    return operation;
}

- (UIImage *)imageFromMemoryCacheForKey:(NSString *)key {
    if (!key) {
        return nil;
    }
    BDImageCacheType type = BDImageCacheTypeMemory;
    return [self.bdManager.imageCache imageForKey:key withType:&type];
}

- (UIImage *)imageFromDiskCacheForKey:(NSString *)key {
    if (!key) {
        return nil;
    }
    BDImageCacheType type = BDImageCacheTypeDisk;
    return [self.bdManager.imageCache imageForKey:key withType:&type];
}

- (UIImage *)imageFromCacheForKey:(NSString *)key {
    if (!key) {
        return nil;
    }
    BDImageCacheType type = BDImageCacheTypeAll;
    return [self.bdManager.imageCache imageForKey:key withType:&type];
}

- (nullable UIImage *)imageFromCacheForURL:(nonnull NSURL *)url {
    NSString *cacheKey = [self cacheKeyForURL:url];
    return [self imageFromCacheForKey:cacheKey];
}

- (void)removeImageForKey:(NSString *)key fromDisk:(BOOL)fromDisk withCompletion:(SDInterfaceNoParamsBlock)completion {
    if (!key) {
        if (completion) {
            completion();
        }
        return;
    }
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
}

- (NSString *)defaultCachePathForKey:(NSString *)key {
    return [self.bdManager.imageCache cachePathForKey:key];
}

- (void)clearMemory {
    [self.bdManager.imageCache clearMemory];
}

- (void)clearDisk {
    [self clearDiskOnCompletion:nil];
}

- (void)clearDiskOnCompletion:(SDInterfaceNoParamsBlock)completion {
    [self.bdManager.imageCache clearDiskWithBlock:completion];
}

- (NSUInteger)getSize {
    return [self.bdManager.imageCache totalDiskSize];
}

@end


