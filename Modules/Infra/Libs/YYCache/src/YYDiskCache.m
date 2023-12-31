//
//  YYDiskCache.m
//  YYCache <https://github.com/ibireme/YYCache>
//
//  Created by ibireme on 15/2/11.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "YYDiskCache.h"
#import "YYKVStorage.h"
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonCrypto.h>
#import <objc/runtime.h>
#import <time.h>

#define Lock() dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER)
#define Unlock() dispatch_semaphore_signal(self->_lock)

NSNotificationName const YYDiskCacheDidRemoveAllAfterCorruptedNotification = @"YYDiskCacheDidRemoveAllAfterCorruptedNotification";

NSNotificationName const YYDiskCacheWillTrimWALNotification = @"YYDiskCacheWillTrimWALNotification";

static const int extended_data_key;

/// Free disk space in bytes.
static int64_t _YYDiskSpaceFree() {
    NSError *error = nil;
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (error) return -1;
    int64_t space =  [[attrs objectForKey:NSFileSystemFreeSize] longLongValue];
    if (space < 0) space = -1;
    return space;
}

/// String's md5 hash.
static NSString *_YYNSStringMD5(NSString *string) {
    if (!string) return nil;
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG)data.length, result);
    return [NSString stringWithFormat:
                @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                result[0],  result[1],  result[2],  result[3],
                result[4],  result[5],  result[6],  result[7],
                result[8],  result[9],  result[10], result[11],
                result[12], result[13], result[14], result[15]
            ];
}

/// weak reference for all instances
static NSMapTable *_globalInstances;
static dispatch_semaphore_t _globalInstancesLock;

static void _YYDiskCacheInitGlobal() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _globalInstancesLock = dispatch_semaphore_create(1);
        _globalInstances = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0];
    });
}

static YYDiskCache *_YYDiskCacheGetGlobal(NSString *path) {
    if (path.length == 0) return nil;
    _YYDiskCacheInitGlobal();
    dispatch_semaphore_wait(_globalInstancesLock, DISPATCH_TIME_FOREVER);
    id cache = [_globalInstances objectForKey:path];
    dispatch_semaphore_signal(_globalInstancesLock);
    return cache;
}

static void _YYDiskCacheSetGlobal(YYDiskCache *cache) {
    if (cache.path.length == 0) return;
    _YYDiskCacheInitGlobal();
    dispatch_semaphore_wait(_globalInstancesLock, DISPATCH_TIME_FOREVER);
    [_globalInstances setObject:cache forKey:cache.path];
    dispatch_semaphore_signal(_globalInstancesLock);
}

static BOOL YYCacheTrimEnableAfterMemoryWarning;
static NSInteger YYCacheTrimMemoryWarningExpirationSeconds;

@interface YYDiskCache ()

@property NSTimeInterval memoryWarningTime;
@end

@implementation YYDiskCache {
    YYKVStorage * _kv;
    BOOL _needReinitialize;
    dispatch_semaphore_t _lock;
    dispatch_queue_t _queue;
    YYKVStorageType _type;
    BOOL _needAutoTrim;
}

- (void)_trimRecursively {
    if (_needAutoTrim) {
        __weak typeof(self) _self = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_autoTrimInterval * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            __strong typeof(_self) self = _self;
            if (!self) return;
            [self _trimInBackground];
            [self _trimRecursively];
        });
    }
}

- (void)_trimInBackground {
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        if (!self) return;
        Lock();
        [self _trimToCost:self.costLimit];
        [self _trimToCount:self.countLimit];
        [self _trimToAge:self.ageLimit];
        [self _trimToFreeDiskSpace:self.freeDiskSpaceLimit];
        Unlock();
    });
}

- (void)_trimWAL {
    NSString *path = _kv.dbWalPath;
    NSFileManager* manager = [NSFileManager defaultManager];
    unsigned long long size = 0;
    if ([manager fileExistsAtPath:path]){
        size = [[manager attributesOfItemAtPath:path error:nil] fileSize];
    }
    if (size > _walSizeLimit) {
        [[NSNotificationCenter defaultCenter] postNotificationName:YYDiskCacheWillTrimWALNotification object:nil userInfo:@{@"size" : @(size), @"path" : path}];
        [_kv trimWAL];
    }
}

- (void)_trimToCost:(NSUInteger)costLimit {
    if (costLimit >= LONG_MAX) return;
    if (YYCacheTrimEnableAfterMemoryWarning && ![self hasMemoryWarning]) return;
    [_kv removeItemsToFitSize:(int64_t)costLimit];

}

- (void)_trimToCount:(NSUInteger)countLimit {
    if (countLimit >= INT_MAX) return;
    [_kv removeItemsToFitCount:(int)countLimit];
}

- (void)_trimToAge:(NSTimeInterval)ageLimit {
    if (ageLimit <= 0) {
        [_kv removeAllItems];
        return;
    }
    long timestamp = time(NULL);
    if (timestamp <= ageLimit) return;
    long age = timestamp - ageLimit;
    if (age >= INT_MAX) return;
    [_kv removeItemsEarlierThanTime:(int)age];
}

- (void)_trimToFreeDiskSpace:(NSUInteger)targetFreeDiskSpace {
    if (targetFreeDiskSpace == 0) return;
    int64_t totalBytes = [_kv getItemsSize];
    if (totalBytes <= 0) return;
    int64_t diskFreeBytes = _YYDiskSpaceFree();
    if (diskFreeBytes < 0) return;
    int64_t needTrimBytes = targetFreeDiskSpace - diskFreeBytes;
    if (needTrimBytes <= 0) return;
    int64_t costLimit = totalBytes - needTrimBytes;
    if (costLimit < 0) costLimit = 0;
    [self _trimToCost:costLimit];
}

- (NSString *)_filenameForKey:(NSString *)key {
    NSString *filename = nil;
    if (_customFileNameBlock) filename = _customFileNameBlock(key);
    if (!filename) filename = _YYNSStringMD5(key);
    return filename;
}

- (void)_appWillBeTerminated {
    dispatch_async(_queue, ^{
        Lock();
        _kv = nil;
        Unlock();
    });
}

- (void)_appDidEnterBackground {
    if (_kv.isDatabaseMalformed) {
        dispatch_async(_queue, ^{
            [self removeAllObjects];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:YYDiskCacheDidRemoveAllAfterCorruptedNotification object:nil userInfo:@{@"path":self->_kv.path}];
            });
        });
    }
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        if (!self) return;
        Lock();
        [self _trimWAL];
        Unlock();
    });

}

- (void)_handleMemoryWarning
{
    self.memoryWarningTime = CACurrentMediaTime();
}

- (BOOL)hasMemoryWarning
{
    NSTimeInterval now =  CACurrentMediaTime();
    return now - self.memoryWarningTime <= YYCacheTrimMemoryWarningExpirationSeconds;
}

#pragma mark - public

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (instancetype)init {
    @throw [NSException exceptionWithName:@"YYDiskCache init error" reason:@"YYDiskCache must be initialized with a path. Use 'initWithPath:' or 'initWithPath:inlineThreshold:' instead." userInfo:nil];
    return [self initWithPath:@"" inlineThreshold:0 needAutoTrim: true];
}

- (instancetype)initWithPath:(NSString *)path {
    return [self initWithPath:path inlineThreshold:1024 * 20 needAutoTrim: true]; // 20KB
}

- (instancetype)initWithPath:(NSString *)path
             inlineThreshold:(NSUInteger)threshold
                needAutoTrim:(BOOL)needAutoTrim {
    self = [super init];
    if (!self) return nil;

    YYDiskCache *globalCache = _YYDiskCacheGetGlobal(path);
    if (globalCache) return globalCache;

    YYKVStorageType type;
    if (threshold == 0) {
        type = YYKVStorageTypeFile;
    } else if (threshold == NSUIntegerMax) {
        type = YYKVStorageTypeSQLite;
    } else {
        type = YYKVStorageTypeMixed;
    }

    YYKVStorage *kv = [[YYKVStorage alloc] initWithPath:path type:type];
    if (!kv) return nil;

    _type = type;
    _kv = kv;
    _path = path;
    _lock = dispatch_semaphore_create(1);
    _queue = dispatch_queue_create("com.ibireme.cache.disk", DISPATCH_QUEUE_CONCURRENT);
    _inlineThreshold = threshold;
    _countLimit = NSUIntegerMax;
    _costLimit = NSUIntegerMax;
    _ageLimit = DBL_MAX;
    _walSizeLimit = 20 * 1024 * 1024;
    _freeDiskSpaceLimit = 0;
    _autoTrimInterval = 60;
    _needReinitialize = NO;
    _needAutoTrim = needAutoTrim;

    [self _trimRecursively];
    _YYDiskCacheSetGlobal(self);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_appWillBeTerminated) name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    return self;
}

- (BOOL)containsObjectForKey:(NSString *)key {
    if (!key) return NO;
    Lock();
    BOOL contains = [_kv itemExistsForKey:key];
    Unlock();
    return contains;
}

- (void)containsObjectForKey:(NSString *)key withBlock:(void(^)(NSString *key, BOOL contains))block {
    if (!block) return;
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        BOOL contains = [self containsObjectForKey:key];
        block(key, contains);
    });
}

- (id<NSCoding>)objectForKey:(NSString *)key {
    if (!key) return nil;
    Lock();
    YYKVStorageItem *item = [_kv getItemForKey:key];
    Unlock();
    if (!item.value) return nil;

    id object = nil;
    if (_customUnarchiveBlock) {
        object = _customUnarchiveBlock(item.value);
    } else {
        @try {
            object = [NSKeyedUnarchiver unarchiveObjectWithData:item.value];
        }
        @catch (NSException *exception) {
            // nothing to do...
        }
    }
    if (object && item.extendedData) {
        [YYDiskCache setExtendedData:item.extendedData toObject:object];
    }
    return object;
}

- (void)objectForKey:(NSString *)key withBlock:(void(^)(NSString *key, id<NSCoding> object))block {
    if (!block) return;
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        id<NSCoding> object = [self objectForKey:key];
        block(key, object);
    });
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key {
    if (!key) return;
    if (!object) {
        [self removeObjectForKey:key];
        return;
    }

    NSData *extendedData = [YYDiskCache getExtendedDataFromObject:object];
    NSData *value = nil;
    if (_customArchiveBlock) {
        value = _customArchiveBlock(object);
    } else {
        @try {
            value = [NSKeyedArchiver archivedDataWithRootObject:object];
        }
        @catch (NSException *exception) {
            // nothing to do...
        }
    }
    if (!value) return;
    NSString *filename = nil;
    if (_kv.type != YYKVStorageTypeSQLite) {
        if (value.length > _inlineThreshold) {
            filename = [self _filenameForKey:key];
        }
    }

    Lock();
    [_kv saveItemWithKey:key value:value filename:filename extendedData:extendedData];
    Unlock();
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key withBlock:(void(^)(void))block {
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        [self setObject:object forKey:key];
        if (block) block();
    });
}

- (void)removeObjectForKey:(NSString *)key {
    if (!key) return;
    Lock();
    [_kv removeItemForKey:key];
    Unlock();
}

- (void)removeObjectForKey:(NSString *)key withBlock:(void(^)(NSString *key))block {
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        [self removeObjectForKey:key];
        if (block) block(key);
    });
}

- (void)removeAllObjects {
    Lock();
    [_kv removeAllItems];
    Unlock();
}

- (void)removeAllObjectsWithBlock:(void(^)(void))block {
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        [self removeAllObjects];
        if (block) block();
    });
}

- (void)removeAllObjectsWithProgressBlock:(void(^)(int removedCount, int totalCount))progress
                                 endBlock:(void(^)(BOOL error))end {
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        if (!self) {
            if (end) end(YES);
            return;
        }
        Lock();
        [_kv removeAllItemsWithProgressBlock:progress endBlock:end];
        Unlock();
    });
}

- (void)addEntriesFromDictionary:(NSDictionary<NSString *,id<NSCoding>> *)dictionary {
    if (!dictionary || dictionary.count == 0) {
        return;
    }
    NSMutableDictionary *dataDic = NSMutableDictionary.dictionary;
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id<NSCoding>  _Nonnull obj, BOOL * _Nonnull stop) {
        NSData *extendedData = nil;
        NSData *value = nil;
        if (obj != [NSNull null]) {
            extendedData = [YYDiskCache getExtendedDataFromObject:obj];
            if (_customArchiveBlock) {
                 value = _customArchiveBlock(obj);
             } else {
                 @try {
                     value = [NSKeyedArchiver archivedDataWithRootObject:obj];
                 }
                 @catch (NSException *exception) {
                     // nothing to do...
                 }
             }
             if (!value) return;
        }

        NSString *filename = nil;
        if (_kv.type != YYKVStorageTypeSQLite) {
            if (value.length > _inlineThreshold) {
                filename = [self _filenameForKey:key];
            }
        }
        YYKVStorageItem *item = YYKVStorageItem.new;
        item.value = value;
        item.extendedData = extendedData;
        item.filename = filename;
        [dataDic setObject:item forKey:key];
    }];

    Lock();
    [_kv saveItemsFromDictionary:dataDic.copy];
    Unlock();
}

- (void)removeObjectsForKeys:(NSArray<NSString *> *)keyArray {
    if (!keyArray) return;
    Lock();
    [_kv removeItemForKeys:keyArray];
    Unlock();
}

- (NSInteger)totalCount {
    Lock();
    int count = [_kv getItemsCount];
    Unlock();
    return count;
}

- (void)totalCountWithBlock:(void(^)(NSInteger totalCount))block {
    if (!block) return;
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        NSInteger totalCount = [self totalCount];
        block(totalCount);
    });
}

- (NSUInteger)totalCost {
    Lock();
    int64_t count = [_kv getItemsSize];
    Unlock();
    return count;
}

- (void)totalCostWithBlock:(void(^)(NSUInteger totalCost))block {
    if (!block) return;
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        NSUInteger totalCost = [self totalCost];
        block(totalCost);
    });
}

- (void)trimToCount:(NSUInteger)count {
    Lock();
    [self _trimToCount:count];
    Unlock();
}

- (void)trimToCount:(NSUInteger)count withBlock:(void(^)(void))block {
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        [self trimToCount:count];
        if (block) block();
    });
}

- (void)trimToCost:(NSUInteger)cost {
    Lock();
    [self _trimToCost:cost];
    Unlock();
}

- (void)trimToCost:(NSUInteger)cost withBlock:(void(^)(void))block {
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        [self trimToCost:cost];
        if (block) block();
    });
}

- (void)trimToAge:(NSTimeInterval)age {
    Lock();
    [self _trimToAge:age];
    Unlock();
}

- (void)trimToAge:(NSTimeInterval)age withBlock:(void(^)(void))block {
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        [self trimToAge:age];
        if (block) block();
    });
}

+ (void)setYYCacheTrimEnableAfterMemoryWarning:(BOOL)enable expirationSeconds:(NSInteger)expirationSeconds {
    YYCacheTrimEnableAfterMemoryWarning = enable;
    YYCacheTrimMemoryWarningExpirationSeconds = expirationSeconds;
}

+ (NSData *)getExtendedDataFromObject:(id)object {
    if (!object) return nil;
    return (NSData *)objc_getAssociatedObject(object, &extended_data_key);
}

+ (void)setExtendedData:(NSData *)extendedData toObject:(id)object {
    if (!object) return;
    objc_setAssociatedObject(object, &extended_data_key, extendedData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)description {
    if (_name) return [NSString stringWithFormat:@"<%@: %p> (%@:%@)", self.class, self, _name, _path];
    else return [NSString stringWithFormat:@"<%@: %p> (%@)", self.class, self, _path];
}

- (BOOL)errorLogsEnabled {
    Lock();
    BOOL enabled = _kv.errorLogsEnabled;
    Unlock();
    return enabled;
}

- (void)setErrorLogsEnabled:(BOOL)errorLogsEnabled {
    Lock();
    _kv.errorLogsEnabled = errorLogsEnabled;
    Unlock();
}

// MARK: File
- (BOOL)saveFileWith:(NSString*)key fileName:(NSString*)fileName size:(int)size extendData:(nullable NSData*)data {
    NSString* filePath = [[_path stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        Lock();
        [_kv removeItemForKey:key];
        Unlock();
        return false;
    } else {
        Lock();
        BOOL result = [_kv saveFileWith:key fileName:fileName size:size extendedData:data];
        Unlock();
        return result;
    }
}

- (YYKVStorageItem*)storageItem:(NSString*)key {
    if (!key) return nil;
    Lock();
    YYKVStorageItem* item = [_kv getFileOrDataItem:key];
    Unlock();
    return item;
}

- (void)removeFile: (NSString *)fileName {
    [self removeObjectForKey:fileName];
}

- (YYKVStorage *)kv {
    if (_needReinitialize) {
        [self reinitializeWithoutLock];
    }
    return _kv;
}

/// 关闭DB
- (void)closeDB {
    Lock();
    [_kv closeDB];
    _needReinitialize = YES;
    Unlock();
}
/// 重新建立DB
- (void)reinitialize {
    Lock();
    [self reinitializeWithoutLock];
    Unlock();
}

/// 重新建立DB
- (void)reinitializeWithoutLock {
    YYKVStorage *kv = [[YYKVStorage alloc] initWithPath:_path type:_type];
    _kv = kv;
    _needReinitialize = NO;
}
@end
