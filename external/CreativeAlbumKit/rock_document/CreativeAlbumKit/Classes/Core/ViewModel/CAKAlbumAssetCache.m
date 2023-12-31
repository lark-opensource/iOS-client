//
//  CAKAlbumAsssetCache.m
//  CreativeAlbumKit-Pods-Aweme
//
//  Created by Liyingpeng on 2021/7/13.
//

#import "CAKAlbumAssetCache.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>

@interface CAKAlbumCacheNil : NSObject

+ (CAKAlbumCacheNil *)cacheNil;

@end

@implementation CAKAlbumCacheNil

+ (CAKAlbumCacheNil *)cacheNil {
    static dispatch_once_t onceToken;
    static CAKAlbumCacheNil *cacheNil = nil;
    dispatch_once(&onceToken, ^{
        cacheNil = [[self alloc] init];
    });
    
    return cacheNil;
}

@end

@implementation CAKAlbumAssetCacheKey

+ (instancetype)keyWithAscending:(BOOL)ascending type:(AWEGetResourceType)resourceType localizedTitle:(nullable NSString *)localizedTitle {
    CAKAlbumAssetCacheKey *result = [CAKAlbumAssetCacheKey new];
    result.ascending = ascending;
    result.resourceType = resourceType;
    result.collectionLocalizedTitle = localizedTitle;
    return result;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSUInteger)hash {
    return self.ascending ^ self.resourceType ^ [self.collectionLocalizedTitle hash];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[CAKAlbumAssetCacheKey class]]) {
        return NO;
    }
    
    CAKAlbumAssetCacheKey *keyObject = (CAKAlbumAssetCacheKey *)object;
    
    BOOL titleEqual = (self.collectionLocalizedTitle && keyObject.collectionLocalizedTitle && [self.collectionLocalizedTitle isEqualToString:keyObject.collectionLocalizedTitle]) || (self.collectionLocalizedTitle.length <= 0 && keyObject.collectionLocalizedTitle.length <= 0);
    
    return self.ascending == keyObject.ascending && self.resourceType == keyObject.resourceType && titleEqual;
}

@end


@interface CAKAlbumAssetCache ()

@property (nonatomic, strong) NSMutableDictionary *assetCacheHash;
@property (nonatomic, getter=isCancelled) BOOL cancelled;
@property (nonatomic, strong) NSMutableDictionary *pendingCompletions;
@property (nonatomic, strong) dispatch_queue_t dataSourceQueue;
@property (nonatomic, strong) dispatch_queue_t libraryLoadingQueue;

@end

@implementation CAKAlbumAssetCache

- (instancetype)initWithPrefetchData:(NSDictionary *)prefetchData
{
    self = [super init];
    if (self) {
        self.assetCacheHash = [NSMutableDictionary dictionaryWithDictionary:prefetchData];
        self.dataSourceQueue = dispatch_queue_create("com.creativealbumkit.data.source.queue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(self.dataSourceQueue, dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0));
        self.libraryLoadingQueue = dispatch_queue_create("com.creativealbumkit.photo.library.loading.queue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (dispatch_queue_t)loadingQueue {
    return self.libraryLoadingQueue;
}

- (NSMutableDictionary *)assetCacheHash {
    if (!_assetCacheHash) {
        _assetCacheHash = @{}.mutableCopy;
    }
    return _assetCacheHash;
}

- (NSMutableDictionary *)pendingCompletions {
    if (!_pendingCompletions) {
        _pendingCompletions = @{}.mutableCopy;
    }
    return _pendingCompletions;
}

- (void)loadCollectionDataWithType:(AWEGetResourceType)type
                         sortStyle:(CAKAlbumAssetSortStyle)sortStyle
                         ascending:(BOOL)ascending
                    fromAlbumModel:(nullable CAKAlbumModel *)albumModel
                         isCurrent:(BOOL)isCurrent
                          useCache:(BOOL)useCache
                        completion:(nullable void (^)(PHFetchResult *))completion {
    dispatch_queue_t loadQueue = (isCurrent && self.useQueueOpt) ? self.dataSourceQueue : self.libraryLoadingQueue;
    [self p_fetchPHAssetResultWithType:type sortStyle:sortStyle ascending:ascending fromAlbumModel:albumModel loadingQueue:loadQueue useCache:useCache completion:completion];
}

- (void)p_fetchPHAssetResultWithType:(AWEGetResourceType)type
                           sortStyle:(CAKAlbumAssetSortStyle)sortStyle
                           ascending:(BOOL)ascending
                      fromAlbumModel:(nullable CAKAlbumModel *)albumModel
                        loadingQueue:(dispatch_queue_t)loadingQueue
                            useCache:(BOOL)useCache
                          completion:(nullable void (^)(PHFetchResult *))completion {
    self.cancelled = NO;
    CAKAlbumAssetCacheKey *key = [CAKAlbumAssetCacheKey keyWithAscending:ascending type:type localizedTitle:albumModel.assetCollection.localizedTitle];
    
    __block id result = [self.assetCacheHash objectForKey:key];
    if (result && useCache) {
        if (result == [CAKAlbumCacheNil cacheNil]) {
            [self addPendingCompletions:completion forKey:key];
            // pending waiting result return
            return;
        }
        ACCBLOCK_INVOKE(completion, result);
    } else {
        if ([key isEqual:albumModel.resultKey] && albumModel.result) {
            ACCBLOCK_INVOKE(completion, albumModel.result);
            return;
        }
        [self.assetCacheHash acc_setObject:[CAKAlbumCacheNil cacheNil] forKey:key];
        [self addPendingCompletions:completion forKey:key];
        dispatch_async(loadingQueue, ^{
            if (albumModel.assetCollection) {
                result = [CAKPhotoManager getAssetsFromCollection:albumModel.assetCollection
                                                        sortStyle:sortStyle
                                                         withType:type
                                                        ascending:ascending];
                [self makeCompletionWithResult:result andKey:key];
            } else {
                [CAKPhotoManager getAllAssetsWithType:type
                                            sortStyle:sortStyle
                                            ascending:ascending
                                           completion:^(PHFetchResult *result) {
                    [self makeCompletionWithResult:result andKey:key];
                }];
            }
        });
    }
}

- (void)makeCompletionWithResult:(PHFetchResult *)result andKey:(CAKAlbumAssetCacheKey *)key {
    acc_dispatch_main_async_safe(^{
        if (self.isCancelled || !key) {
            return;
        }
        if (result) {
            [self.assetCacheHash acc_setObject:result forKey:key];
        } else {
            [self.assetCacheHash removeObjectForKey:key];
        }
        for (void (^completion)(PHFetchResult *) in [self.pendingCompletions objectForKey:key]) {
            ACCBLOCK_INVOKE(completion, result);
        }
        [self.pendingCompletions removeObjectForKey:key];
    });
}

- (void)addPendingCompletions:(void (^)(PHFetchResult *))completion forKey:(CAKAlbumAssetCacheKey *)key {
    if (!completion || !key) {
        return;
    }
    acc_dispatch_main_async_safe(^{
        NSMutableArray *completions = ACCDynamicCast([self.pendingCompletions objectForKey:key], NSMutableArray);

        if (!completions) {
            [self.pendingCompletions acc_setObject:@[completion] forKey:key];
        } else {
            [completions acc_addObject:completion];
        }
    });
}

- (void)clear {
    self.cancelled = YES;
    self.assetCacheHash = nil;
    self.pendingCompletions = nil;
}

@end
