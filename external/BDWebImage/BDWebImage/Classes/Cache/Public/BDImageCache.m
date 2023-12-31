//
//  BDImageCache.m
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/11/28.
//

#import "BDImageCache.h"
#import "BDWebImageMacro.h"
#import "BDWebImageCompat.h"
#import "UIImage+BDWebImage.h"
#import "BDWebImageUtil.h"
#import "BDWebImageManager.h"
#import "BDImageNSCache.h"
#import "BDImageDiskFileCache.h"
#import "BDImageUserDefaults.h"
#import "BDImageRequestKey.h"
#import <MMKV/MMKV.h>

NSString * const BDImageCacheSmartCropInfo   = @"BDImageCacheSmartCropInfo";
NSString * const BDImageCacheScaleInfo   = @"BDImageCacheScaleInfo";
NSString * const BDImageCacheSizeInfo   = @"BDImageCacheSizeInfo";

static inline dispatch_queue_t BDImageCacheIOQueue()
{
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
}

@interface BDImageCache ()

@property (nonatomic, strong, readwrite) id<BDMemoryCache> memoryCache;
@property (nonatomic, strong, readwrite) id<BDDiskCache> diskCache;
@property (nonatomic, strong, readwrite) MMKV *imageExtendCache;    ///< 存储image info，包括image size、scale、smartCrop
@property (atomic, assign) BOOL mmkvInited;
@property (nonatomic, copy) NSString *rootPath;

@end

typedef NS_ENUM(NSUInteger, BDWebImageCacheStrategy) {
    BDWebImageCacheStrategyLowMemory = 10 * 1024 * 1024,
    BDWebImageCacheStrategyMidMemory = 100 * 1024 * 1024,
    BDWebImageCacheStrategyHighMemory = NSUIntegerMax,
};

@implementation BDImageCache

#pragma mark - Config
- (void)setConfig:(BDImageCacheConfig *)config
{
    NSParameterAssert(config);
    _config = [config copy];
    
    [self.memoryCache setConfig:config];
    [self.diskCache setConfig:config];
    if (config.shouldDisableiCloud) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURL *url = [NSURL fileURLWithPath:self.rootPath];
            [url setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
        });
    }
}

#pragma mark - decode from data

- (UIImage *)imageFromData:(NSData *)data
{
    return [self imageFromData:data options:0];
}

- (UIImage *)imageFromData:(NSData *)data
                   options:(BDImageRequestOptions)options
{
    return [self imageFromData:data options:options size:CGSizeZero cropRect:CGRectZero];
}

- (UIImage *)imageFromData:(NSData *)data
                   options:(BDImageRequestOptions)options
                      size:(CGSize)size
                  cropRect:(CGRect)cropRect
{
    return [self imageFromData:data options:options size:CGSizeZero cropRect:CGRectZero scale:1];
}

//TODO 后面重构一下，解码操作统一处理
- (UIImage *)imageFromData:(NSData *)data
                   options:(BDImageRequestOptions)options
                      size:(CGSize)size
                  cropRect:(CGRect)cropRect
                     scale:(CGFloat)scale
{
    static Class imageClass = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageClass = NSClassFromString(@"BDImage")?:[UIImage class];
    });

    if (scale <= 0) scale = 1;
    
    BOOL decode = (options & BDImageNotDecoderForDisplay) == 0;
    BOOL scaleDown = (options & BDImageScaleDownLargeImages) != 0;
    BOOL isCrop = (options & BDImageRequestSmartCorp) != 0;
    
    NSError *err = nil;
    return [BDWebImageUtil decodeImageData:data
                                imageClass:imageClass
                                     scale:scale
                          decodeForDisplay:decode
                           shouldScaleDown:scaleDown
                            downsampleSize:size
                                  cropRect:isCrop ? cropRect : CGRectZero
                                     error:&err];
}

#pragma mark - Cache
+ (instancetype)sharedImageCache
{
    static dispatch_once_t onceToken;
    static BDImageCache *imageCache;
    dispatch_once(&onceToken, ^{
        imageCache = [[BDImageCache alloc] init];
    });
    return imageCache;
}

- (instancetype)init
{
    return [self initWithName:nil];
}

- (instancetype)initWithName:(NSString *)name
{
    if (isEmptyString(name)) {
        name = @"com.bdimage.diskcache";
    }
    name = name.lowercaseString;
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *oldPath = [cachePath stringByAppendingPathComponent:@"com.bytedance.imagecache"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:oldPath]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[NSFileManager defaultManager] removeItemAtPath:oldPath
                                                       error:nil];
        });
    }
    return [self initWithStorePath:[cachePath stringByAppendingPathComponent:name] inlineThreshold:0];
}

- (instancetype)initWithStorePath:(NSString *)path
                  inlineThreshold:(NSUInteger)threshold
{
    id<BDMemoryCache> memoryCache = [BDImageNSCache new];
    return [self initWithMemoryCache:memoryCache
                           storePath:path
                     inlineThreshold:threshold];
}

- (instancetype)initWithMemoryCache:(id<BDMemoryCache>)memoryCache
                          storePath:(NSString *)path
                    inlineThreshold:(NSUInteger)threshold
{
    id<BDDiskCache> diskCache = [[BDImageDiskFileCache alloc] initWithCachePath:path];
    
    if (!memoryCache || !diskCache) return nil;
    
    self = [super init];
    if (self) {
        self.rootPath = path;
        self.name = path.lastPathComponent;

        _memoryCache = memoryCache;
        _diskCache = diskCache;
        __weak typeof(self)weakSelf = self;
        _diskCache.trimBlock = ^(NSString * _Nonnull key) {
            [weakSelf removeImageInfoWithPathKey:key];
        };
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.imageExtendCache = [MMKV mmkvWithID:@"com.bd.image.extend" relativePath:path];
            self.mmkvInited = YES;
        });
        _priority = 1.f;//提供一个默认的大于0的 priority，应对和空的 priority 比较的场景

        self.config = [[BDImageCacheConfig alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        
        return self;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

#pragma mark - UIApplicationDidEnterBackgroundNotification
-(void)applicationDidEnterBackground:(NSNotification *)notification {
    if (self.config.trimDiskWhenEnteringBackground || self.diskCache.trimDiskInBG) {
#if !defined(BDWEBIMAGE_APP_EXTENSIONS)
        __block UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            // Clean up any unfinished task business by marking where you
            // stopped or ending the task outright.
            [[UIApplication sharedApplication] endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self trimDiskCache];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] endBackgroundTask:bgTask];
                bgTask = UIBackgroundTaskInvalid;
            });
        });
#endif
    }
}

#pragma mark - Save Image
- (void)setImage:(UIImage *)image forKey:(NSString *)key
{
    [self setImage:image imageData:nil forKey:key withType:BDImageCacheTypeAll];
}

- (void)setImage:(UIImage *)image
       imageData:(NSData *)imageData
          forKey:(NSString *)key
        withType:(BDImageCacheType)type
{
    if (!key || (image == nil && imageData.length == 0)) return;
    
    if (type & BDImageCacheTypeMemory) {
        if (!image && imageData) {
            image = [self imageFromData:imageData];
        }
        if (image) {
            [_memoryCache setObject:image forKey:key cost:[image bd_imageCost]];
        }
    }
    if (type & BDImageCacheTypeDisk) {
        [self saveImageToDisk:image data:imageData forKey:key];
    }
}

- (void)setImage:(UIImage *)image
       imageData:(NSData *)imageData
          forKey:(NSString *)key
        withType:(BDImageCacheType)type
        callBack:(BDImageCacheCallback)callback
{
    if (!key || (image == nil && imageData.length == 0)) return;
    
    if (type & BDImageCacheTypeMemory) {
        if (!image && imageData) {
            image = [self imageFromData:imageData];
        }
        if (image) {
            [_memoryCache setObject:image forKey:key cost:[image bd_imageCost]];
        }
    }
    if (type & BDImageCacheTypeDisk) {
        [self saveImageToDisk:image data:imageData forKey:key callBack:^(UIImage *image, NSString *cachePath) {
            if (callback) {
                callback(image, cachePath);
            }
        }];
    }
    else {
        if (callback) {
            callback(image, nil);
        }
    }
}


- (void)saveImageToDisk:(UIImage *)image
                   data:(NSData *)imageData
                 forKey:(NSString *)key
{
    NSData *data = imageData;
    if (!data && image) {
//        data = UIImageJPEGRepresentation(image, 0.9);//这里有问题？如果其他格式呢。
        data = [image bd_imageDataRepresentation];
    }
    if (data) {
        if (image.scale) {
            [self setImageInfo:@(image.scale) forKey:key withInfoType:BDImageCacheScaleInfo];
        }
        [self.diskCache setData:data forKey:key];
    }
}

- (void)saveImageToDisk:(UIImage *)image
                   data:(NSData *)imageData
                 forKey:(NSString *)key
               callBack:(BDImageCacheCallback)callback
{
    dispatch_async(BDImageCacheIOQueue(), ^{
        [self saveImageToDisk:image data:imageData forKey:key];
        if (callback) {
            callback(image,[self cachePathForKey:key]);
        }
    });
}

#pragma mark - Remove Image
- (void)removeImageForKey:(NSString *)key
{
    [self removeImageForKey:key withType:BDImageCacheTypeAll];
}

- (void)removeImageForKey:(NSString *)key withType:(BDImageCacheType)type
{
    if (type & BDImageCacheTypeMemory) [_memoryCache removeObjectForKey:key];
    if (type & BDImageCacheTypeDisk){
        [_imageExtendCache removeValueForKey:key];
        [_diskCache removeDataForKey:key];
    }
}

- (void)removeImageFromDiskForKey:(NSString *)key callBack:(void(^)(NSString *key))callback
{
    [_diskCache removeDataForKey:key withBlock:^(NSString * _Nonnull key) {
        if (callback) {
            callback(key);
        }
    }];
}

#pragma mark - Check Image
- (BDImageCacheType)containsImageForKey:(NSString *)key
{
    return [self containsImageForKey:key type:BDImageCacheTypeAll];
}

- (BDImageCacheType)containsImageForKey:(NSString *)key type:(BDImageCacheType)type
{
    BDImageCacheType cacheType = BDImageCacheTypeNone;
    if (type & BDImageCacheTypeMemory) {
        if ([_memoryCache containsObjectForKey:key]){
            cacheType |= BDImageCacheTypeMemory;
        };
    }
    if (type & BDImageCacheTypeDisk) {
        if ([_diskCache containsDataForKey:key])
        {
            cacheType |= BDImageCacheTypeDisk;
        }
    }
    return cacheType;
}

#pragma mark - Get Image
- (UIImage *)imageFromMemoryCacheForKey:(NSString *)key {
    BDImageCacheType type = BDImageCacheTypeMemory;
    return [self imageForKey:key withType:&type];
}

- (UIImage *)imageFromDiskCacheForKey:(NSString *)key {
    return [self imageFromDiskCacheForKey:key options:0];
}

- (UIImage *)imageFromDiskCacheForKey:(NSString *)key options:(BDImageRequestOptions)options{
    BDImageCacheType type = BDImageCacheTypeDisk;
    return [self imageForKey:key
                    withType:&type
                     options:options
                        size:CGSizeZero
                decryptBlock:nil];
}

- (UIImage *)imageForKey:(NSString *)key
{
    BDImageCacheType type = BDImageCacheTypeAll;
    return [self imageForKey:key
                    withType:&type
                     options:0
                        size:CGSizeZero
                decryptBlock:nil];
}

- (UIImage *)imageForKey:(NSString *)key
                withType:(BDImageCacheType *)type
{
    return [self imageForKey:key
                    withType:type
                     options:0
                        size:CGSizeZero
                decryptBlock:nil];
}

- (UIImage *)imageForKey:(NSString *)key
                withType:(BDImageCacheType *)type
                 options:(BDImageRequestOptions)options
{
    return [self imageForKey:key
                    withType:type
                     options:options
                        size:CGSizeZero
                decryptBlock:nil];
}

- (UIImage *)imageForKey:(NSString *)key
                withType:(BDImageCacheType *)type
                 options:(BDImageRequestOptions)options
                    size:(CGSize)size
{
    return [self imageForKey:key
                    withType:type
                     options:options
                        size:size
                decryptBlock:nil];
}

- (UIImage *)imageForKey:(NSString *)key
                withType:(BDImageCacheType *)type
                 options:(BDImageRequestOptions)options
                    size:(CGSize)size
            decryptBlock:(BDImageRequestDecryptBlock)decryptBlock
{
    UIImage *image = nil;
    BDImageCacheType requestType = *type;
    if (requestType & BDImageCacheTypeMemory) {
        NSString *targetKey = [self targetImageKey:key option:options size:size];
        image = [_memoryCache objectForKey:targetKey];
        if (image) {
            *type = BDImageCacheTypeMemory;
            return image;
        }
    }
    
    if (!image && (requestType & BDImageCacheTypeDisk)) {
        NSData *data = (NSData *)[_diskCache dataForKey:key];
        NSError *decodeError = nil;
        if (data) {
            if (decryptBlock){
                data = decryptBlock(data, &decodeError);
            }
            CGFloat scale = [(NSNumber *)[self imageInfoForkey:key withInfoType:BDImageCacheScaleInfo] doubleValue];
            NSString *rectStr = [self imageInfoForkey:key withInfoType:BDImageCacheSmartCropInfo];
            CGRect cropRect = CGRectFromString(rectStr);
            image = [self imageFromData:data
                                options:options
                                   size:size
                               cropRect:cropRect
                                  scale:scale];//感觉在这里做图片解码和存内存违反了单一职责原则
            
            *type = BDImageCacheTypeDisk;
            if (image && (requestType & BDImageCacheTypeMemory) &&
                [BDWebImageManager sharedManager].enableCacheToMemory) {//TODO
                [_memoryCache setObject:image
                                 forKey:key
                                   cost:[image bd_imageCost]]; //这里逻辑有问题，queryCache vs canCacheTo,但若改动影响较大TODO
            }
        }
    }
    
    if (!image) {
        *type = BDImageCacheTypeNone;
    }
    
    return image;
}

- (void)imageForKey:(NSString *)key
           withType:(BDImageCacheType)type
          withBlock:(void (^)(UIImage *, BDImageCacheType))block
{
    [self imageForKey:key withType:type options:0 size:CGSizeZero withBlock:block decryptBlock:nil];
}

- (void)imageForKey:(NSString *)key
           withType:(BDImageCacheType)type
            options:(BDImageRequestOptions)options
               size:(CGSize)size
          withBlock:(void(^)(UIImage * image, BDImageCacheType type))block
{
    [self imageForKey:key withType:type options:options size:size withBlock:block decryptBlock:nil];
}

- (void)imageForKey:(NSString *)key
           withType:(BDImageCacheType)type
            options:(BDImageRequestOptions)options
               size:(CGSize)size
          withBlock:(void(^)(UIImage * image, BDImageCacheType type))block
       decryptBlock:(BDImageRequestDecryptBlock)decryptBlock
{
    if (!block) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BDImageCacheType cacheType = type;
        UIImage *image = [self imageForKey:key
                                  withType:&cacheType
                                   options:options size:size
                              decryptBlock:decryptBlock];
        dispatch_async(dispatch_get_main_queue(), ^{
            block(image, cacheType);
        });
    });
}

- (NSData *)imageDataForKey:(NSString *)key
{
    return (NSData *)[_diskCache dataForKey:key];
}

- (void)imageDataForKey:(NSString *)key withBlock:(void(^)(NSData *imageData))block
{
    if (!block) return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = (NSData *)[self.diskCache dataForKey:key];
        dispatch_async(dispatch_get_main_queue(), ^{
            block(data);
        });
    });
}

- (NSString *)targetImageKey:(NSString *)key
                      option:(BDImageRequestOptions)options
                        size:(CGSize)size
{
    if (key.length < 1) {
        return key;
    }
    if (options & BDImageRequestSmartCorp || !CGSizeEqualToSize(CGSizeZero, size)) {
        if (![key containsString:@"smartCrop"] && ![key containsString:@"downsample"]) {
            // 传入的 key 没有经过 smartCrop、downsample 修改过，需要重新生成
            BDImageRequestKey *originKey = [[BDImageRequestKey alloc] initWithURL:key];
            originKey.smartCrop = (options & BDImageRequestSmartCorp) == BDImageRequestSmartCorp;
            if (!CGSizeEqualToSize(CGSizeZero, size)) {
                originKey.downsampleSize = size;
            }
            originKey.builded = YES;
            return originKey.targetkey;
        }
    }
    return key;
}

#pragma mark - Cache Image Info

- (void)setImageInfo:(id)info
              forKey:(NSString *)key
        withInfoType:(NSString *)type
{
    if (!info || key.length < 1 || type.length < 1 || !self.mmkvInited) {
        return;
    }
    
    BOOL isAcceptableValue = [info isKindOfClass:[NSString class]] || [info isKindOfClass:[NSNumber class]] ||
    [info isKindOfClass:[NSArray class]] || [info isKindOfClass:[NSDictionary class]] ||
    [info isKindOfClass:[NSDate class]] || [info isKindOfClass:[NSData class]];
    if (!isAcceptableValue) {
        return;
    }
    
    NSString *pathKey = [[_diskCache cachePathForKey:key] lastPathComponent];
    NSString *infoStr = [_imageExtendCache getStringForKey:pathKey];
    NSMutableDictionary *infoDict;
    if (infoStr.length > 0) {
        NSError *error = nil;
        infoDict = [[NSJSONSerialization JSONObjectWithData:[infoStr dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error] mutableCopy];
    }
    
    if (infoDict == nil) {
        infoDict = [NSMutableDictionary dictionary];
    }
    [infoDict setObject:info forKey:type];
    NSData *data = [NSJSONSerialization dataWithJSONObject:infoDict
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:nil];
    if (data) {
        [_imageExtendCache setObject:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] forKey:pathKey];
    }
    
}

- (id)imageInfoForkey:(NSString *)key withInfoType:(NSString *)type
{
    if (key.length < 1 || type.length < 1 || !self.mmkvInited) {
        return nil;
    }
    NSString *pathKey = [[_diskCache cachePathForKey:key] lastPathComponent];
    NSString *infoStr = [_imageExtendCache getStringForKey:pathKey];
    NSDictionary *infoDict;
    if (infoStr.length > 0) {
        NSError *error = nil;
        infoDict = [NSJSONSerialization JSONObjectWithData:[infoStr dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];
    }
    if (infoDict) {
        return [infoDict objectForKey:type];
    }
    return nil;
}

- (CGRect)smartCropRateRectForkey:(NSString *)key
{
    if (key.length < 1) {
        return CGRectZero;
    }
    CGRect cropRect = CGRectFromString([self imageInfoForkey:key withInfoType:BDImageCacheSmartCropInfo]);
    CGSize imageSize = CGSizeFromString([self imageInfoForkey:key withInfoType:BDImageCacheSizeInfo]);
    if (!CGRectEqualToRect(cropRect, CGRectZero) && !CGSizeEqualToSize(imageSize, CGSizeZero)) {
        double x = cropRect.origin.x / imageSize.width;
        double y = cropRect.origin.y / imageSize.height;
        double w = cropRect.size.width / imageSize.width;
        double h = cropRect.size.height / imageSize.height;
        return CGRectMake(x, y, w, h);
    } else {
        return CGRectZero;
    }
}

- (void)removeImageInfoWithPathKey:(NSString *)pathKey
{
    if (pathKey.length < 1) {
        return;
    }
    [_imageExtendCache removeValueForKey:pathKey];
}

#pragma mark - Util
- (NSString *)cachePathForKey:(NSString *)key
{
    if ([self.diskCache containsDataForKey:key]) {
        return [self.diskCache cachePathForKey:key];
    }
    return nil;
}

- (void)clearMemory
{
    [self.memoryCache removeAllObjects];
}

- (void)clearDiskWithBlock:(void (^)(void))block
{
    [_imageExtendCache clearAll];
    [self.diskCache removeAllDataWithBlock:block];
}

- (void)trimDiskCache
{
    [self.diskCache removeExpiredData];
}

- (NSUInteger)totalDiskSize
{
    return [self.diskCache totalSize];
}

@end
