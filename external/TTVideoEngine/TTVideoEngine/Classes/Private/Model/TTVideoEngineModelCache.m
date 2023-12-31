//
//  TTVideoEngineModelCache.m
//  TTVideoEngine
//
//  Created by 黄清 on 2018/10/18.
//

#import "TTVideoEngineModelCache.h"
#import <pthread.h>
#import "NSArray+TTVideoEngine.h"
#import "TTVideoEngineUtil.h"
#import "TTVideoEngineKVStorage.h"
#import "TTVideoEngineUtil.h"
#import "TTVideoEngineUtilPrivate.h"

static const NSInteger s_min_disk_free_size = 100 * 1024 * 1024;// 100M

@interface _TTVideoEngineModelCacheItem : NSObject
@property (nonatomic, strong) id data;
@property (nonatomic,   copy) NSString *key;
@end

@implementation _TTVideoEngineModelCacheItem

+ (instancetype)item:(id)data key:(NSString *)key {
    _TTVideoEngineModelCacheItem *item = [_TTVideoEngineModelCacheItem new];
    item.data = data;
    item.key = key;
    return item;
}

@end

@interface TTVideoEngineModelCache(){
    pthread_mutex_t _lock;
    dispatch_queue_t _trashQueue;
}

@property(nonatomic, strong) NSMutableArray* caches;
@property(nonatomic, assign) NSInteger maxMemoryCount;
@property(nonatomic, assign) NSInteger maxCount;
@property(nonatomic, strong) TTVideoEngineKVStorage* diskStorage;

@end

@implementation TTVideoEngineModelCache

- (void)dealloc {
    [_caches removeAllObjects];
    _caches = nil;
    pthread_mutex_destroy(&_lock);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    if (self = [super init]) {
        pthread_mutex_init(&_lock, NULL);
        _caches = [NSMutableArray array];
        _trashQueue = dispatch_queue_create("vclould.engine.videoModel.cache.disk.queue", DISPATCH_QUEUE_SERIAL);
        _maxMemoryCount = 50;
        _maxCount = 400;
        NSString *beforeCachePath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"ttvideo-engine-video-model-cache-disk"];
        NSString *cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:TTVideoEngineBuildMD5(@"vclould.engine.videoMoodel.cache.disk")];
        BOOL isDir = NO;
        BOOL allocKVStorageInMainThread = YES;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:beforeCachePath isDirectory:&isDir]) {
            if (isDir) {
                allocKVStorageInMainThread = NO;
                dispatch_async(_trashQueue, ^{
                    NSError *error = nil;
                    [fileManager moveItemAtPath:beforeCachePath toPath:cachePath error:&error];
                    if (error) {
                        TTVideoEngineLog(@"videomodel cache move. error: %@",error);
                    }
                    
                    TTVideoRunOnMainQueue(^{
                        _diskStorage = [[TTVideoEngineKVStorage alloc] initWithPath:cachePath];
                    }, YES);
                });
            }
        }
        if (allocKVStorageInMainThread) {
            _diskStorage = [[TTVideoEngineKVStorage alloc] initWithPath:cachePath];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidReceiveMemoryWarningNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

+ (instancetype)shareCache {
    static TTVideoEngineModelCache* shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[TTVideoEngineModelCache alloc] init];
    });
    return shareInstance;
}

- (void)addItem:(id _Nonnull)item forKey:(nonnull NSString *)cacheKey {
    if (!item || !cacheKey || cacheKey.length == 0) {
        return;
    }
    
    pthread_mutex_lock(&_lock);
    [self _removeMemoryCacheIfExit:cacheKey];
    
    [self _insertItemInMemoryCache:cacheKey data:item];
    pthread_mutex_unlock(&_lock);
    
    [self saveItemToDisk:item forKey:cacheKey];
}

- (void)saveItemToDisk:(id<NSCoding> _Nonnull)item forKey:(NSString *)key {
    @weakify(self)
    [self _exect:^{
        @strongify(self)
        if (!self) {
            return;
        }
        
        if (TTVideoEngineGetDiskFreeSpecSize(self.diskStorage.path) < s_min_disk_free_size) {
            [self.diskStorage removeItemsToFitCount:[self.diskStorage getItemsSize] - 1];
        }
        
        @try {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:item];
            [self.diskStorage saveItemWithKey:key value:data];
            
            [self.diskStorage removeItemsToFitCount:self.maxCount - 1];
        } @catch (NSException *exception) {
            TTVideoEngineLog(@"archivedDataWithRootObject exception, %@",exception);
        }
    }];
}

- (void)removeItemForKey:(NSString *)cacheKey {
    if (cacheKey == nil || cacheKey.length == 0) {
        return;
    }
    
    pthread_mutex_lock(&_lock);
    [self _removeMemoryCacheIfExit:cacheKey];
    pthread_mutex_unlock(&_lock);
    
    [self removeItemFromDiskForKey:cacheKey];
}

- (void)removeItemFromDiskForKey:(NSString *)key {
    if (key == nil || key.length == 0) {
        return;
    }
    
    @weakify(self)
    [self _exect:^{
        @strongify(self)
        if (!self) {
            return;
        }
        
        [self.diskStorage removeItemForKey:key];
    }];
}

- (void)getItemForKey:(NSString *)cacheKey withBlock:(void (^)(NSString * _Nonnull, id<NSCoding> _Nullable))block {
    if (!cacheKey || cacheKey.length == 0) {
        !block ?: block(cacheKey, nil);
    }
    
    __block _TTVideoEngineModelCacheItem *obj = nil;
    pthread_mutex_lock(&_lock);
    obj = [self _removeMemoryCacheIfExit:cacheKey];
    if (obj) {
        [_caches ttvideoengine_insertObject:obj atIndex:0];
    }
    pthread_mutex_unlock(&_lock);
    if (obj) {
        !block ?: block(cacheKey,obj.data);
    }
    @weakify(self)
    [self getItemFromDiskForKey:cacheKey withBlock:^(NSString * _Nonnull key, id<NSCoding>  _Nullable object) {
        @strongify(self)
        if (!self) {
            return;
        }
        
        if (!obj) {
            !block ?: block(key, object);
            
            if (object) {
                pthread_mutex_lock(&self->_lock);
                [self _insertItemInMemoryCache:cacheKey data:object];
                pthread_mutex_unlock(&self->_lock);
            }
        }
    }];
}

- (void)getItemFromDiskForKey:(NSString *)cacheKey withBlock:(nullable void(^)(NSString *key, id<NSCoding> _Nullable object))block {
    
    @weakify(self)
    [self _exect:^{
        @strongify(self)
        if (!self) {
            return;
        }
        
        NSData *data = [self.diskStorage getItemValueForKey:cacheKey];
        if (!data) {
            !block ?: block(cacheKey, nil);
        } else {
            @try {
                id object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                if (object) {
                    !block ?: block(cacheKey, object);
                } else {
                    !block ?: block(cacheKey, nil);
                }
            } @catch (NSException *exception) {
                TTVideoEngineLog(@"unarchiveObjectWithData exception, %@",exception);
            }
        }
    }];
}

- (void)clearAllItems {
    [self clearAllMemoryItems];
    
    @weakify(self)
    [self _exect:^{
        @strongify(self)
        if (!self) {
            return;
        }
        
        [self.diskStorage removeAllItems];
    }];
}

- (void)clearAllMemoryItems {
    pthread_mutex_lock(&_lock);
    [_caches removeAllObjects];
    pthread_mutex_unlock(&_lock);
}

- (void)_exect:(void(^)(void)) block {
    dispatch_async(_trashQueue, ^{
        !block ?: block();
    });
}

- (_TTVideoEngineModelCacheItem *)_removeMemoryCacheIfExit:(NSString *)key {
    _TTVideoEngineModelCacheItem *obj = nil;
    for (NSInteger i = _caches.count - 1; i >= 0; i--) {
        _TTVideoEngineModelCacheItem *temObj = [_caches objectAtIndex:i];
        if ([temObj.key isEqualToString:key]) {
            obj = temObj;
            break;
        }
    }
    
    if (obj) {
        [_caches removeObject:obj];
    }
    
    return obj;
}

- (void)_insertItemInMemoryCache:(NSString *)cacheKey data:(id)data {
    _TTVideoEngineModelCacheItem *obj = nil;
    obj = [_TTVideoEngineModelCacheItem item:data key:cacheKey];
    [_caches ttvideoengine_insertObject:obj atIndex:0];
    
    if (_caches.count > _maxMemoryCount) {
        [_caches removeLastObject];
    }
}

//MARK: - UIApplicationDidReceiveMemoryWarningNotification

- (void)_applicationDidReceiveMemoryWarningNotification:(NSNotification*)notify {
    [self clearAllMemoryItems];
}

@end
