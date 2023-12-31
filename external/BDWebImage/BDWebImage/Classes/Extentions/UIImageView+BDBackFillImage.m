//
//  UIImageView+BDBackFillImage.m
//  BDWebImage
//
//  Created by qiuyang on 2018/12/20.
//

#import "UIImageView+BDBackFillImage.h"
#import <objc/runtime.h>
#import "UIImageView+BDWebImage.h"


@interface _BDBackFillStore : NSObject

@property (nonatomic, assign) NSUInteger countLimit;
@property (nonatomic, strong) NSMutableDictionary *dbCache;

+ (instancetype)sharedInstance;

- (void)insertObject:(UIImageView *)obj forKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;
- (NSPointerArray *)objectForKey:(NSString *)key;
- (void)clear;

@end


@implementation _BDBackFillStore

+ (instancetype)sharedInstance {
    static id __sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [[self alloc] init];
    });
    return __sharedInstance;
}

#pragma mark - Life Cycle
- (instancetype)init {
    self = [super init];
    if (self) {
        _countLimit = NSUIntegerMax;
        _dbCache = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)insertObject:(UIImageView *)obj forKey:(NSString *)key {
    if (key.length <= 0) {
        return;
    }
    if (_dbCache.count > _countLimit) {
        [_dbCache removeAllObjects];
    }
    NSPointerArray *dbArray = [_dbCache objectForKey:key];
    if (!(dbArray && [dbArray isKindOfClass:[NSPointerArray class]])) {
        dbArray = [NSPointerArray weakObjectsPointerArray];
    }
    [dbArray addPointer:(__bridge void *_Nullable)(obj)];
    [_dbCache setObject:dbArray forKey:key];
}

- (NSPointerArray *)objectForKey:(NSString *)key {
    if (key.length <= 0) {
        return nil;
    }
    NSPointerArray *cache = _dbCache[key];
    return cache;
}

- (void)removeObjectForKey:(NSString *)key {
    if (key.length <= 0) {
        return;
    }
    [_dbCache removeObjectForKey:key];
}

- (void)clear {
    [_dbCache removeAllObjects];
}

@end


@implementation BDBackFill

@end


@implementation UIImageView (BDBackFillImage)

- (void)bd_backFillSetImage:(UIImage *)image {
    self.bd_backfillRequestURL = nil;
    [self setImage:image];
}

- (void)setBd_backfillRequestURL:(NSURL *)bd_backfillRequestURL {
    objc_setAssociatedObject(self, @selector(bd_backfillRequestURL), bd_backfillRequestURL, YES);
}

- (NSURL *)bd_backfillRequestURL {
    return objc_getAssociatedObject(self, @selector(bd_backfillRequestURL));
}

- (void)bd_setImageViewToBackFill:(NSURL *)imageURL {
    if (imageURL && imageURL.absoluteString.length > 0) {
        self.bd_backfillRequestURL = imageURL;
        _BDBackFillStore *store = [_BDBackFillStore sharedInstance];
        NSString *storeKey = [[BDWebImageManager sharedManager] requestKeyWithURL:imageURL];
        [store insertObject:self forKey:storeKey];
    }
}

- (BDWebImageRequest *)bd_setImageWithBackFill:(nonnull BDBackFill *)backFill {
    return [self bd_setImageWithBackFill:backFill placeholder:nil options:BDImageRequestDefaultOptions progress:NULL completion:NULL];
}

- (BDWebImageRequest *)bd_setImageWithBackFill:(nonnull BDBackFill *)backFill placeholder:(nullable UIImage *)placeholder {
    return [self bd_setImageWithBackFill:backFill placeholder:placeholder options:BDImageRequestDefaultOptions progress:NULL completion:NULL];
}

- (BDWebImageRequest *)bd_setImageWithBackFill:(nonnull BDBackFill *)backFill options:(BDImageRequestOptions)options {
    return [self bd_setImageWithBackFill:backFill placeholder:nil options:options progress:NULL completion:NULL];
}

- (BDWebImageRequest *)bd_setImageWithBackFill:(nonnull BDBackFill *)backFill
                                   placeholder:(nullable UIImage *)placeholder
                                       options:(BDImageRequestOptions)options
                                    completion:(nullable BDImageRequestCompletedBlock)completion {
    return [self bd_setImageWithBackFill:backFill placeholder:placeholder options:options progress:NULL completion:completion];
}

- (BDWebImageRequest *)bd_setImageWithBackFill:(nonnull BDBackFill *)backFill
                                   placeholder:(nullable UIImage *)placeholder
                                       options:(BDImageRequestOptions)options
                                      progress:(nullable BDImageRequestProgressBlock)progress
                                    completion:(nullable BDImageRequestCompletedBlock)completion {
    return [self bd_setImageWithBackFill:backFill placeholder:placeholder options:options cacheName:nil progress:progress completion:completion];
}

- (BDWebImageRequest *)bd_setImageWithBackFill:(nonnull BDBackFill *)backFill
                                   placeholder:(nullable UIImage *)placeholder
                                       options:(BDImageRequestOptions)options
                                     cacheName:(nullable NSString *)cacheName
                                      progress:(nullable BDImageRequestProgressBlock)progress
                                    completion:(nullable BDImageRequestCompletedBlock)completion {
    return [self bd_setImageWithBackFill:backFill alternativeURLs:nil placeholder:placeholder options:options cacheName:cacheName transformer:nil progress:progress completion:completion];
}

- (BDWebImageRequest *)bd_setImageWithBackFill:(nonnull BDBackFill *)backFill
                                   placeholder:(nullable UIImage *)placeholder
                                       options:(BDImageRequestOptions)options
                                   transformer:(nullable BDBaseTransformer *)transformer
                                      progress:(nullable BDImageRequestProgressBlock)progress
                                    completion:(nullable BDImageRequestCompletedBlock)completion {
    return [self bd_setImageWithBackFill:backFill alternativeURLs:nil placeholder:placeholder options:options cacheName:nil transformer:transformer progress:progress completion:completion];
}

- (BDWebImageRequest *)bd_setImageWithBackFill:(nonnull BDBackFill *)backFill
                               alternativeURLs:(nullable NSArray *)alternativeURLs
                                   placeholder:(nullable UIImage *)placeholder
                                       options:(BDImageRequestOptions)options
                                     cacheName:(nullable NSString *)cacheName
                                   transformer:(nullable BDBaseTransformer *)transformer
                                      progress:(nullable BDImageRequestProgressBlock)progress
                                    completion:(nullable BDImageRequestCompletedBlock)completion {
    return [self bd_setImageWithBackFill:backFill
                         alternativeURLs:alternativeURLs
                             placeholder:placeholder
                                 options:options
                         timeoutInterval:0
                               cacheName:cacheName
                             transformer:transformer
                                progress:progress
                              completion:completion];
}

- (BDWebImageRequest *)bd_setImageWithBackFill:(nonnull BDBackFill *)backFill
                               alternativeURLs:(nullable NSArray *)alternativeURLs
                                   placeholder:(nullable UIImage *)placeholder
                                       options:(BDImageRequestOptions)options
                               timeoutInterval:(CFTimeInterval)timeoutInterval
                                     cacheName:(nullable NSString *)cacheName
                                   transformer:(nullable BDBaseTransformer *)transformer
                                      progress:(nullable BDImageRequestProgressBlock)progress
                                    completion:(nullable BDImageRequestCompletedBlock)completion {
    if (options & BDImageRequestCallbackNotInMainThread) {
        options &= ~BDImageRequestCallbackNotInMainThread;
    }
    NSURL *imageURL = nil;
    switch (backFill.imageType) {
        case BDImageResolutionTypeThumb:
            imageURL = backFill.thumbImageURL;
            break;
        case BDImageResolutionTypePreview:
            imageURL = backFill.previewImageURL;
            break;
        case BDImageResolutionTypeOrigin:
            imageURL = backFill.originalImageURL;
            break;
        default:
            break;
    }

    return [self bd_setImageWithURL:imageURL
                    alternativeURLs:alternativeURLs
                        placeholder:placeholder
                            options:options
                    timeoutInterval:timeoutInterval
                          cacheName:cacheName
                        transformer:transformer
                           progress:progress
                         completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        if (error) {
            ///< 请求失败，需要cache
            [self bd_setImageViewToBackFill:imageURL];
        } else {
            ///< 请求成功，检查回填
            if (image) {
                [self p_bd_backFill:backFill image:image];
            }
        }
        if (completion) {
            completion(request, image, data, error, from);
        }
    }];
}

#pragma mark - Private Method
- (void)p_bd_backFill:(BDBackFill *)backFill image:(UIImage *)image {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        UIImage *downImage = [self p_bd_imageForBackFill:backFill sourceImage:image];
        if (BDImageResolutionTypeOrigin == backFill.imageType) {
            ///< 缓存
            UIImage *thumbImage = [self p_bd_cacheImage:downImage keyURL:backFill.thumbImageURL];
            UIImage *previewImage = [self p_bd_cacheImage:downImage keyURL:backFill.previewImageURL];
            ///< 回填
            [self p_bd_callbackFillImage:thumbImage keyURL:backFill.thumbImageURL];
            [self p_bd_callbackFillImage:previewImage keyURL:backFill.previewImageURL];
            [self p_bd_callbackFillImage:image keyURL:backFill.originalImageURL];
        } else if (BDImageResolutionTypePreview == backFill.imageType) {
            ///< 中图不需要降采样
            UIImage *thumbImage = [self p_bd_cacheImage:downImage keyURL:backFill.thumbImageURL];
            [self p_bd_callbackFillImage:thumbImage keyURL:backFill.thumbImageURL];
            [self p_bd_callbackFillImage:image keyURL:backFill.previewImageURL];
        } else if (BDImageResolutionTypeThumb == backFill.imageType) {
            [self p_bd_callbackFillImage:image keyURL:backFill.thumbImageURL];
        }
    });
}

- (UIImage *)p_bd_imageForBackFill:(BDBackFill *)backFill sourceImage:(UIImage *)image {
    UIImage *downImage = image;
    if (BDImageResolutionTypeOrigin == backFill.imageType) {
        NSString *thumImageKey = [[BDWebImageManager sharedManager] requestKeyWithURL:backFill.thumbImageURL];
        NSString *previewImageKey = [[BDWebImageManager sharedManager] requestKeyWithURL:backFill.previewImageURL];
        if (thumImageKey.length <= 0 && previewImageKey.length <= 0) {
            ///< 不需要中图和小图，不进行压缩处理
            return downImage;
        }
        if ([[BDImageCache sharedImageCache] cachePathForKey:previewImageKey]) {
            ///< 中图存在，取中图
            downImage = [[BDImageCache sharedImageCache] imageForKey:previewImageKey];
        } else if ([[BDImageCache sharedImageCache] cachePathForKey:thumImageKey]) {
            ///< 小图存在，取小图
            downImage = [[BDImageCache sharedImageCache] imageForKey:thumImageKey];
        } else {
            ///< 需要中图或者小图，但是中图小图都不存在，压缩
            @autoreleasepool {
                NSData *imageData = UIImageJPEGRepresentation(image, 0.75f);
                downImage = [UIImage imageWithData:imageData];
            }
        }
    }
    return downImage;
}

- (UIImage *)p_bd_cacheImage:(UIImage *)image keyURL:(NSURL *)keyURL {
    NSString *imageKey = [[BDWebImageManager sharedManager] requestKeyWithURL:keyURL];
    if (imageKey.length > 0 && ![[BDImageCache sharedImageCache] cachePathForKey:imageKey]) {
        [[BDImageCache sharedImageCache] setImage:image forKey:imageKey];
        return image;
    }
    if (imageKey.length > 0) {
        return [[BDImageCache sharedImageCache] imageForKey:imageKey];
    }
    return image;
}

- (void)p_bd_callbackFillImage:(UIImage *)image keyURL:(NSURL *)keyURL {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!keyURL || keyURL.absoluteString.length <= 0) {
            return;
        }
        NSString *storeKey = [[BDWebImageManager sharedManager] requestKeyWithURL:keyURL];
        NSPointerArray *cache = [[_BDBackFillStore sharedInstance] objectForKey:storeKey];
        if (cache.allObjects.count > 0) {
            for (UIImageView *imageView in cache.allObjects) {
                if (imageView && [imageView isKindOfClass:[UIImageView class]]) {
                    if ([[[BDWebImageManager sharedManager] requestKeyWithURL:imageView.bd_backfillRequestURL] isEqualToString:storeKey]) {
                        [imageView bd_backFillSetImage:image];
                    }
                }
            }
            [[_BDBackFillStore sharedInstance] removeObjectForKey:storeKey];
        }
    });
}

@end
