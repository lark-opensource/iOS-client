//
//  AWECustomWebImageManager.m
//  Modeo
//
//  Created by 马超 on 2020/12/30.
//

#import "AWECustomWebImageManager.h"
#import <YYCache/YYCache.h>
#import <BDWebImage/BDWebImageManager.h>
#import <AWEBaseLib/AWEMacros.h>
#import <HTSServiceKit/AWEAppContext.h>
#import <HTSServiceKit/HTSServiceCenter.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AWEResizableImageConfig <HTSService>

- (BOOL)compatibleAnimatedImageView;
- (BOOL)enableImageCacheDomainAllowList;
- (BOOL)enable3ScaleImage;
- (BOOL)enableBDWebImage;
- (NSString *)getCustomBDWebImageCacheName;

@end

@protocol AWEReuseExternalImageConfig <HTSService>

- (BOOL)enableReuseExternalImage;

@end

NS_ASSUME_NONNULL_END

@implementation AWECustomWebImageConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.clearMemoryOnMemoryWarning = YES;
        self.clearMemoryWhenEnteringBackground = YES;
        self.shouldUseWeakMemoryCache = YES;
        self.memoryCountLimit = NSUIntegerMax;
        self.memorySizeLimit = 256 * 1024 * 1024;
        self.memoryAgeLimit = 12 * 60 * 60;
        self.trimDiskWhenEnteringBackground = YES;
        self.diskCountLimit = NSUIntegerMax;
        self.diskSizeLimit = 256 * 1024 * 1024;
        self.diskAgeLimit = 7 * 24 * 60 * 60;
    }
    return self;
}

@end

@interface AWECustomWebImageManager ()

@property (nonatomic, strong) NSMutableDictionary *customYYWebImageManagers;

@property (nonatomic, strong) NSMutableArray *cacheNames;

@property (nonatomic, strong) NSMutableDictionary *reuseCacheImageInfoDictionary;

@end

static dispatch_queue_t AWEImageManagerUpdateQueue = nil;
static dispatch_queue_t AWEReuseCacheImageInfoUpdateQueue = nil;

@implementation AWECustomWebImageManager

+ (void)runOnceForLazyRegister
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        evaluateLazyRegisterWebImageManager();
    });
}

+ (instancetype)sharedInstance
{
    static AWECustomWebImageManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
        manager.cacheNames = [NSMutableArray arrayWithCapacity:0];
        manager.customYYWebImageManagers = [NSMutableDictionary dictionaryWithCapacity:0];
        manager.reuseCacheImageInfoDictionary = [NSMutableDictionary dictionaryWithCapacity:0];
        AWEImageManagerUpdateQueue = dispatch_queue_create("AWECustomWebImageManagerUpdateQueue", DISPATCH_QUEUE_CONCURRENT);
        AWEReuseCacheImageInfoUpdateQueue = dispatch_queue_create("AWEReuseCacheImageInfoUpdateQueue", DISPATCH_QUEUE_SERIAL);
    });
    return manager;
}

- (void)registerCustomWebImage:(Class<AWECustomWebImageProtocol>)customWebImageManager
{
    dispatch_barrier_async(AWEImageManagerUpdateQueue , ^{
        AWECustomWebImageConfig *configModel = [customWebImageManager getWebImageConfig];
        NSString *cacheName = [customWebImageManager  getCacheName];
        if (BTD_isEmptyString(cacheName) || !configModel || [self.cacheNames containsObject:cacheName]) {
            return;
        }
        // BDImageCache
        [self getCustomBDWebImageManager:configModel cacheName:cacheName];
        [self.cacheNames addObject:cacheName];
    });
}

- (void)getCustomBDWebImageManager:(AWECustomWebImageConfig *)configModel cacheName:(NSString *)cacheName
{
    BDImageCacheConfig *cacheConfig = [[BDImageCacheConfig alloc] init];
    cacheConfig.clearMemoryOnMemoryWarning = configModel.clearMemoryOnMemoryWarning;
    cacheConfig.clearMemoryWhenEnteringBackground = configModel.clearMemoryWhenEnteringBackground;
    cacheConfig.memoryCountLimit = configModel.memoryCountLimit;
    cacheConfig.memorySizeLimit = configModel.memorySizeLimit;
    cacheConfig.memoryAgeLimit = configModel.memoryAgeLimit;
    cacheConfig.trimDiskWhenEnteringBackground = configModel.trimDiskWhenEnteringBackground;
    cacheConfig.diskCountLimit = configModel.diskCountLimit;
    cacheConfig.diskSizeLimit = configModel.diskSizeLimit;
    cacheConfig.diskAgeLimit = configModel.diskAgeLimit;
    
    BDImageCache *customCache = [[BDImageCache alloc] initWithName:cacheName];
    customCache.config = cacheConfig;
    [customCache clearDiskWithBlock:nil];
    BDWebImageManager *manager = [BDWebImageManager sharedManager];
    [manager registCache:customCache forKey:cacheName];
}

- (void)updateCustomWebImageConfig:(AWECustomWebImageConfig *)configModel cacheName:(NSString *)cacheName
{
    [self updateBDWebImageConfig:configModel cacheName:cacheName];
}

- (BDImageCache *)getRegisterBDImageCache:(NSString *)cacheName
{
    BDWebImageManager *bd_manager = [BDWebImageManager sharedManager];
    BDImageCache *bd_imageCache;
    if (!isEmptyString(cacheName)) {
        bd_imageCache = [bd_manager cacheForKey:cacheName];
    }
    return bd_imageCache;
}

- (void)updateBDWebImageConfig:(AWECustomWebImageConfig *)configModel cacheName:(NSString *)cacheName
{
    if (![self.cacheNames containsObject:cacheName]) {
        return;
    }
    BDWebImageManager *manager = [BDWebImageManager sharedManager];
    BDImageCache *imageCache =  [manager cacheForKey:cacheName];
    
    BDImageCacheConfig *cacheConfig = [[BDImageCacheConfig alloc] init];
    cacheConfig.clearMemoryOnMemoryWarning = configModel.clearMemoryOnMemoryWarning;
    cacheConfig.clearMemoryWhenEnteringBackground = configModel.clearMemoryWhenEnteringBackground;
    cacheConfig.memoryCountLimit = configModel.memoryCountLimit;
    cacheConfig.memorySizeLimit = configModel.memorySizeLimit;
    cacheConfig.memoryAgeLimit = configModel.memoryAgeLimit;
    cacheConfig.trimDiskWhenEnteringBackground = configModel.trimDiskWhenEnteringBackground;
    cacheConfig.diskCountLimit = configModel.diskCountLimit;
    cacheConfig.diskSizeLimit = configModel.diskSizeLimit;
    cacheConfig.diskAgeLimit = configModel.diskAgeLimit;
    
    [imageCache setConfig:cacheConfig];
}

- (void)removeCustomMemoryCache
{
    // BD
    BDWebImageManager *manager = [BDWebImageManager sharedManager];
    for (NSString *cacheName in self.cacheNames) {
        BDImageCache *imageCache =  [manager cacheForKey:cacheName];
        [imageCache.memoryCache removeAllObjects];
    }
}

- (void)removeCustomDiskCache
{
    // BD
    BDWebImageManager *manager = [BDWebImageManager sharedManager];
    for (NSString *cacheName in self.cacheNames) {
        BDImageCache *imageCache = [manager cacheForKey:cacheName];
        [imageCache.diskCache removeAllData];
    }
}

- (NSUInteger)totalCustomDiskCost
{
    NSUInteger totalCost = 0;
    // BD
    BDWebImageManager *manager = [BDWebImageManager sharedManager];
    for (NSString *cacheName in self.cacheNames) {
        BDImageCache *imageCache =  [manager cacheForKey:cacheName];
        totalCost += [imageCache.diskCache totalSize];
    }
    return totalCost;
}

- (void)removeMemoryCacheForName:(NSString *)cacheName
{
    // BD
    BDImageCache *bd_imageCache = [self getRegisterBDImageCache:cacheName];
    [bd_imageCache.memoryCache removeAllObjects];
}

- (BOOL)isRegisteredCacheName:(NSString *)cacheName
{
    if (BTD_isEmptyString(cacheName)) {
        return NO;
    }
    if ([self.cacheNames containsObject:cacheName]) {
        return YES;
    }
    return NO;
}

- (NSString *)getRegisteredCacheName:(NSString *)cacheName
{
    if ([self isRegisteredCacheName:cacheName]) {
        return cacheName;
    }
    return nil;
}

#pragma mark - Reuse Cache Image

- (nullable AWECoverImageCacheModel *)getCacheImageInfoWithIdentificationKey:(NSString *)identifier
{
    if (![APPContextIMP(AWEReuseExternalImageConfig) enableReuseExternalImage]) {
        return nil;
    }
    NSString *identificationKey = [NSString stringWithFormat:@"reuse_image_for_feed_play_%@",identifier];
    AWECoverImageCacheModel *cacheInfo = DynamicCast([self.reuseCacheImageInfoDictionary objectForKey:identificationKey], AWECoverImageCacheModel);
    return cacheInfo;
}

- (void)stagingImageInfo:(NSString *)imageURLString cacheName:(NSString *)cacheName identificationKey:(NSString *)identifier
{
    if (![APPContextIMP(AWEReuseExternalImageConfig) enableReuseExternalImage] || BTD_isEmptyString(imageURLString) || BTD_isEmptyString(identifier)) {
        return ;
    }
    dispatch_async(AWEReuseCacheImageInfoUpdateQueue, ^{
        NSString *identificationKey = [NSString stringWithFormat:@"reuse_image_for_feed_play_%@",identifier];
        AWECoverImageCacheModel *model = [[AWECoverImageCacheModel alloc] initWithCacheImageURLString:imageURLString cacheName:cacheName];
        [self.reuseCacheImageInfoDictionary setValue:model forKey:identificationKey];
    });
}

@end


@implementation AWECoverImageCacheModel

- (instancetype)initWithCacheImageURLString:(NSString *)cacheImageURLString cacheName:(NSString *)cacheName
{
    self = [super init];
    if (self) {
        _cacheImageURLString = cacheImageURLString;
        _cacheName = cacheName;
    }
    return self;
}

@end

@implementation AWEWebImageManagerTools

+ (void)removeAllMemoryCache
{
    [[AWECustomWebImageManager sharedInstance] removeCustomMemoryCache];
    // Default - BD
    BDImageCache *BDImageCache = nil;
    NSString *imageCacheName = [APPContextIMP(AWEResizableImageConfig) getCustomBDWebImageCacheName];
    if (!BTD_isEmptyString(imageCacheName)) {
        BDImageCache = [[BDWebImageManager sharedManager] cacheForKey:imageCacheName];
        [BDImageCache.memoryCache removeAllObjects];
    }
    [[BDWebImageManager sharedManager].imageCache.memoryCache removeAllObjects];
}

+ (void)removeAllDiskCache
{
    [[AWECustomWebImageManager sharedInstance] removeCustomDiskCache];
    // Default - BD (Custom + Default)
    BDImageCache *BDImageCache = nil;
    NSString *imageCacheName = [APPContextIMP(AWEResizableImageConfig) getCustomBDWebImageCacheName];
    if (!BTD_isEmptyString(imageCacheName)) {
        BDImageCache = [[BDWebImageManager sharedManager] cacheForKey:imageCacheName];
        [BDImageCache.diskCache removeAllData];
    }
    [[BDWebImageManager sharedManager].imageCache.diskCache removeAllData];
}

+ (NSUInteger)totalDiskCost
{
    NSUInteger totalCost = 0;
    
    totalCost += [[AWECustomWebImageManager sharedInstance] totalCustomDiskCost];
    // Default - BD (Custom + Default)
    BDImageCache *BDImageCache = nil;
    NSString *imageCacheName = [APPContextIMP(AWEResizableImageConfig) getCustomBDWebImageCacheName];
    if (!BTD_isEmptyString(imageCacheName)) {
        BDImageCache = [[BDWebImageManager sharedManager] cacheForKey:imageCacheName];
        totalCost += BDImageCache.diskCache.totalSize;
    }
    totalCost += [BDWebImageManager sharedManager].imageCache.diskCache.totalSize;
    
    return totalCost;
}

/**
 is exists in the default image cache , BDImageCache & YYImageCache
 */
+ (BOOL)isExistInDefaultImageCache:(NSArray *)imageUrlArray
{
    if (imageUrlArray.count == 0) {
        return NO;
    }
    BOOL contain = NO;
    BDImageCache *BDImageCache = nil;
    NSString *imageCacheName = [APPContextIMP(AWEResizableImageConfig) getCustomBDWebImageCacheName];
    if (!BTD_isEmptyString(imageCacheName)) {
        BDImageCache = [[BDWebImageManager sharedManager] cacheForKey:imageCacheName];
    }
    BDImageCache = BDImageCache ?: [BDWebImageManager sharedManager].imageCache;
    for (id url in imageUrlArray) {
        if (![url isKindOfClass:[NSString class]] &&
            ![url isKindOfClass:[NSURL class]]) {
            return NO;
        }
        NSURL *imageURL = nil;
        if ([url isKindOfClass:[NSString class]]) {
            imageURL = [NSURL URLWithString:url];
        } else {
            imageURL = url;
        }
        NSString *cacheKey = [[BDWebImageManager sharedManager] requestKeyWithURL:imageURL];
        contain = [BDImageCache containsImageForKey:cacheKey];
        if (contain) {
            return YES;
        }
    }
    return NO;
}

/**
 is exists in the specified image cache , BDImageCache & YYImageCache
 */
+ (BOOL)isExistInCacheName:(NSString *)imageCacheName imageUrlArray:(NSArray *)imageUrlArray
{
    if (imageUrlArray.count == 0 || BTD_isEmptyString(imageCacheName)) {
        return NO;
    }
    BOOL contain = NO;
    BDImageCache *BDImageCache = nil;
    BDImageCache = [[BDWebImageManager sharedManager] cacheForKey:imageCacheName];
    if (!BDImageCache) {
        return NO;
    }
    for (id url in imageUrlArray) {
        if (![url isKindOfClass:[NSString class]] &&
            ![url isKindOfClass:[NSURL class]]) {
            return NO;
        }
        NSURL *imageURL = nil;
        if ([url isKindOfClass:[NSString class]]) {
            imageURL = [NSURL URLWithString:url];
        } else {
            imageURL = url;
        }
        NSString *cacheKey = [[BDWebImageManager sharedManager] requestKeyWithURL:imageURL];
        contain = [BDImageCache containsImageForKey:cacheKey];
        if (contain) {
            return YES;
        }
    }
    return NO;
}


@end
