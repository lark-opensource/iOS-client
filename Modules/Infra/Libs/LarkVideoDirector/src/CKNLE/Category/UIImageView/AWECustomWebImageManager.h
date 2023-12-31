//
//  AWECustomWebImageManager.h
//  Modeo
//
//  Created by 马超 on 2020/12/30.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@class AWECustomWebImageConfig;
@protocol AWECustomWebImageProtocol <NSObject>

+ (BOOL)enableCache;

+ (nullable NSString *)getCacheName;

+ (AWECustomWebImageConfig *)getWebImageConfig;

@end

@interface AWECustomWebImageConfig : NSObject

#pragma mark - Memory

@property (nonatomic, assign) BOOL clearMemoryOnMemoryWarning; // 是否内存低时清除所有内存缓存，默认YES
@property (nonatomic, assign) BOOL clearMemoryWhenEnteringBackground; // 是否进入后台时清除所有内存缓存，默认YES
@property (assign, nonatomic) BOOL shouldUseWeakMemoryCache; //是否使用 weak cache 优化内存缓存
@property (nonatomic, assign) NSUInteger memoryCountLimit; // 最大内存缓存对象数量限制，默认无限制
@property (nonatomic, assign) NSUInteger memorySizeLimit; // 最大内存缓存大小，字节数（Attention，单位 byte），默认256MB
@property (nonatomic, assign) NSUInteger memoryAgeLimit; // 最大内存过期时间，秒数，默认12小时

#pragma mark - Disk

@property (nonatomic, assign) BOOL trimDiskWhenEnteringBackground; // 是否进入后台时清除超限或者过期磁盘缓存，默认YES
@property (nonatomic, assign) NSUInteger diskCountLimit; // 最大磁盘缓存对象数量限制，默认无限制
@property (nonatomic, assign) NSUInteger diskSizeLimit; // 最大磁盘缓存大小，字节数，默认256MB
@property (nonatomic, assign) NSUInteger diskAgeLimit; // 最大磁盘缓存过期时间，秒数，默认7天

@end

extern void evaluateLazyRegisterWebImageManager();

@class AWECoverImageCacheModel, BDImageCache;
@interface AWECustomWebImageManager : NSObject

+ (void)runOnceForLazyRegister;

+ (instancetype)sharedInstance;

- (void)registerCustomWebImage:(Class<AWECustomWebImageProtocol>)customWebImageManager;

- (void)updateCustomWebImageConfig:(AWECustomWebImageConfig *)configModel cacheName:(NSString *)cacheName;

- (BOOL)isRegisteredCacheName:(NSString *)cacheName;
- (nullable NSString *)getRegisteredCacheName:(NSString *)cacheName;

// clean
- (void)removeCustomMemoryCache;
- (void)removeCustomDiskCache;

- (NSUInteger)totalCustomDiskCost;

// reuse image
- (void)stagingImageInfo:(NSString *)imageURLString cacheName:(nullable NSString *)cacheName identificationKey:(NSString *)identifier;
- (nullable AWECoverImageCacheModel *)getCacheImageInfoWithIdentificationKey:(NSString *)identifier;

@end

@interface AWECoverImageCacheModel : NSObject

@property (nonatomic, strong) NSString *cacheImageURLString;
@property (nonatomic, strong) NSString *cacheName;

- (instancetype)initWithCacheImageURLString:(NSString *)cacheImageURLString cacheName:(nullable NSString *)cacheName;


@end

@interface AWEWebImageManagerTools : NSObject

// Is exist in the default image cache , BDImageCache && YYImageCache
+ (BOOL)isExistInDefaultImageCache:(NSArray *)imageUrlArray;

//Is exist in the specified image cache , BDImageCache && YYImageCache
+ (BOOL)isExistInCacheName:(NSString *)imageCacheName imageUrlArray:(NSArray *)imageUrlArray;

+ (void)removeAllMemoryCache;

//This method may blocks the calling thread until file delete finished.
+ (void)removeAllDiskCache;

+ (NSUInteger)totalDiskCost;

@end

NS_ASSUME_NONNULL_END
