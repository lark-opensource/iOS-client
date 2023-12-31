//
//  IESGurdFileMetaManager.m
//  Pods
//
//  Created by 陈煜钏 on 2019/9/29.
//

#import "IESGurdFileMetaManager+Private.h"

#import "IESGeckoDefines.h"
#import "IESGeckoDefines+Private.h"
#import "IESGurdFilePaths.h"
#import "IESGurdKitUtil.h"
#import "IESGurdAppLogger.h"

static dispatch_queue_t IESGurdMetaFileQueue (void) {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = IESGurdKitCreateSerialQueue("com.IESGurdKit.MetaFileQueue");
    });
    return queue;
}

#define FILE_MANAGER        [NSFileManager defaultManager]

typedef NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> * IESGurdMetaDictionary;

@interface IESGurdFileMetaManager ()

@property (class, nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, IESGurdInactiveCacheMeta *> *> * inactiveMetaDictionary;

@property (class, nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, IESGurdActivePackageMeta *> *> * activeMetaDictionary;

@property (class, nonatomic, assign) BOOL needSynchronizeActiveMeta;

@property (class, nonatomic, assign) BOOL needSynchronizeInactiveMeta;

@end

@implementation IESGurdFileMetaManager

#pragma mark - Meta - Public

+ (void)synchronizeMetaData
{
    GurdLog(@"Synchronize meta data");
    @synchronized (self) {
        [self setupMetaDataIfNeeded];
        
        if (self.needSynchronizeActiveMeta) {
            [self innerSynchronizeMetaDataWithDictionary:[self copiedDictionaryWithMetaDictionary:(IESGurdMetaDictionary)self.activeMetaDictionary]
                                                    path:IESGurdFilePaths.activeMetaDataPath];
            self.needSynchronizeActiveMeta = NO;
        }
        if (self.needSynchronizeInactiveMeta) {
            [self innerSynchronizeMetaDataWithDictionary:[self copiedDictionaryWithMetaDictionary:(IESGurdMetaDictionary)self.inactiveMetaDictionary]
                                                    path:IESGurdFilePaths.inactiveMetaDataPath];
            self.needSynchronizeInactiveMeta = NO;
        }
    }
}

+ (void)saveInactiveMeta:(IESGurdInactiveCacheMeta *)meta
{
    GurdLog(@"Save inactive meta : accessKey(%@) channel(%@) version(%llu)", meta.accessKey, meta.channel, meta.version);
    NSString *accessKey = meta.accessKey;
    NSString *channel = meta.channel;
    if (accessKey.length == 0 || channel.length == 0) {
        return;
    }
    @synchronized (self) {
        [self setupMetaDataIfNeeded];
        [self innerSaveMetaWithMetaDictionary:self.inactiveMetaDictionary
                                    accessKey:accessKey
                                      channel:channel
                                         meta:meta];
        self.needSynchronizeInactiveMeta = YES;
    }
}

+ (void)saveActiveMeta:(IESGurdActivePackageMeta *)meta
{
    GurdLog(@"Save active meta : accessKey(%@) channel(%@) version(%llu)", meta.accessKey, meta.channel, meta.version);
    NSString *accessKey = meta.accessKey;
    NSString *channel = meta.channel;
    if (accessKey.length == 0 || channel.length == 0) {
        return;
    }
    @synchronized (self) {
        [self setupMetaDataIfNeeded];
        [self innerSaveMetaWithMetaDictionary:self.activeMetaDictionary
                                    accessKey:accessKey
                                      channel:channel
                                         meta:meta];
        self.needSynchronizeActiveMeta = YES;
    }
}

+ (IESGurdInactiveCacheMeta * _Nullable)inactiveMetaForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    __block IESGurdInactiveCacheMeta *meta = nil;
    @synchronized (self) {
        [self setupMetaDataIfNeeded];
        meta = self.inactiveMetaDictionary[accessKey][channel];
    }
    return meta;
}

+ (IESGurdActivePackageMeta * _Nullable)activeMetaForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    __block IESGurdActivePackageMeta *meta = nil;
    @synchronized (self) {
        [self setupMetaDataIfNeeded];
        meta = self.activeMetaDictionary[accessKey][channel];
    }
    return meta;
}

+ (void)deleteInactiveMetaForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    if (accessKey.length == 0 || channel.length == 0) {
        return;
    }
    @synchronized (self) {
        [self setupMetaDataIfNeeded];
        self.inactiveMetaDictionary[accessKey][channel] = nil;
        
        self.needSynchronizeInactiveMeta = YES;
    }
}

+ (void)deleteActiveMetaForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    if (accessKey.length == 0 || channel.length == 0) {
        return;
    }
    @synchronized (self) {
        [self setupMetaDataIfNeeded];
        self.activeMetaDictionary[accessKey][channel] = nil;
        
        self.needSynchronizeActiveMeta = YES;
    }
}

+ (void)cleanCacheMetaData
{
    @synchronized (self) {
        self.inactiveMetaDictionary = [NSMutableDictionary dictionary];
        self.activeMetaDictionary = [NSMutableDictionary dictionary];
        
        dispatch_queue_async_safe(IESGurdMetaFileQueue(), ^{
            [FILE_MANAGER removeItemAtPath:IESGurdFilePaths.inactiveMetaDataPath error:NULL];
            [FILE_MANAGER removeItemAtPath:IESGurdFilePaths.activeMetaDataPath error:NULL];
        });
    }
}

+ (NSDictionary<NSString *, NSDictionary<NSString *, IESGurdInactiveCacheMeta *> *> *)copyInactiveMetadataDictionary
{
    @synchronized (self) {
        [self setupMetaDataIfNeeded];
        return [self copiedDictionaryWithMetaDictionary:(IESGurdMetaDictionary)self.inactiveMetaDictionary];
    }
}

+ (NSDictionary<NSString *, NSDictionary<NSString *, IESGurdActivePackageMeta *> *> *)copyActiveMetadataDictionary
{
    @synchronized (self) {
        [self setupMetaDataIfNeeded];
        return [self copiedDictionaryWithMetaDictionary:(IESGurdMetaDictionary)self.activeMetaDictionary];
    }
}

#pragma mark - Migrate

+ (BOOL)shouldMigrate
{
    @synchronized (self) {
        [self setupMetaDataIfNeeded];
        
        if (self.inactiveMetaDictionary.count > 0 || self.activeMetaDictionary.count > 0) {
            return YES;
        }
        return NO;
    }
}

+ (void)enumerateInactiveMetaUsingBlock:(void (^)(IESGurdInactiveCacheMeta *meta))block
{
    if (!block) {
        return;
    }
    @synchronized (self) {
        [self setupMetaDataIfNeeded];
        [self.inactiveMetaDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSMutableDictionary<NSString *,IESGurdInactiveCacheMeta *> *obj, BOOL *stop) {
            [obj enumerateKeysAndObjectsUsingBlock:^(NSString *key, IESGurdInactiveCacheMeta *meta, BOOL *stop) {
                block(meta);
            }];
        }];
    }
}

+ (void)enumerateActiveMetaUsingBlock:(void (^)(IESGurdActivePackageMeta *meta))block
{
    if (!block) {
        return;
    }
    @synchronized (self) {
        [self setupMetaDataIfNeeded];
        [self.activeMetaDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSMutableDictionary<NSString *,IESGurdActivePackageMeta *> *obj, BOOL *stop) {
            [obj enumerateKeysAndObjectsUsingBlock:^(NSString *key, IESGurdActivePackageMeta *meta, BOOL *stop) {
                block(meta);
            }];
        }];
    }
}

#pragma mark - Meta - Private

+ (void)setupMetaDataIfNeeded
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setupMetaDataNotification];
        
        if ([FILE_MANAGER fileExistsAtPath:IESGurdFilePaths.inactiveMetaDataPath] ||
            [FILE_MANAGER fileExistsAtPath:IESGurdFilePaths.activeMetaDataPath]) {
            self.inactiveMetaDictionary = [self localMetaDataWithPath:IESGurdFilePaths.inactiveMetaDataPath];
            self.activeMetaDictionary = [self localMetaDataWithPath:IESGurdFilePaths.activeMetaDataPath];
            
            // 数据纠正
            [self.activeMetaDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSMutableDictionary<NSString *,IESGurdActivePackageMeta *> *obj, BOOL *stop) {
                [obj enumerateKeysAndObjectsUsingBlock:^(NSString *channel, IESGurdActivePackageMeta *meta, BOOL *stop) {
                    IESGurdInactiveCacheMeta *inactiveMeta = self.inactiveMetaDictionary[accessKey][channel];
                    if (meta.version == inactiveMeta.version) {
                        self.inactiveMetaDictionary[accessKey][channel] = nil;
                    }
                }];
            }];
        } else {
            self.inactiveMetaDictionary = [NSMutableDictionary dictionary];
            self.activeMetaDictionary = [NSMutableDictionary dictionary];
        }
        
        GurdLog(@"Inactive meta : %@", self.inactiveMetaDictionary);
        GurdLog(@"Active meta : %@", self.activeMetaDictionary);
    });
}

+ (void)setupMetaDataNotification
{
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    void (^synchronizeMetaDataBlock)(NSNotification *) = ^(NSNotification *note) {
        [self synchronizeMetaData];
    };
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                      object:nil
                                                       queue:mainQueue
                                                  usingBlock:synchronizeMetaDataBlock];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification
                                                      object:nil
                                                       queue:mainQueue
                                                  usingBlock:synchronizeMetaDataBlock];
}

+ (NSMutableDictionary *)localMetaDataWithPath:(NSString *)dataPath {
    NSMutableDictionary *metaDictionary = [NSMutableDictionary dictionary];
    dispatch_queue_sync_safe(IESGurdMetaFileQueue(), (^{
        NSArray *classes = @[ [NSDictionary class], [IESGurdInactiveCacheMeta class], [IESGurdActivePackageMeta class] ];
        NSDictionary *localDictionary = IESGurdKitKeyedUnarchiveObject(dataPath, classes);
        
        if ([localDictionary isKindOfClass:[NSDictionary class]]) {
            [localDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSDictionary *dictionary, BOOL *stop) {
                if (![dictionary isKindOfClass:[NSDictionary class]]) {
                    return;
                }
                if (dictionary.count > 0) {
                    metaDictionary[accessKey] = [dictionary mutableCopy];
                }
            }];
        }
    }));
    return metaDictionary;
}

+ (void)innerSaveMetaWithMetaDictionary:(NSMutableDictionary *)metaDictionary
                              accessKey:(NSString *)accessKey
                                channel:(NSString *)channel
                                   meta:(id)meta
{
    if (accessKey.length == 0 || channel.length == 0 || !meta) {
        return;
    }
    NSMutableDictionary *channelDictionary = metaDictionary[accessKey];
    if (!channelDictionary) {
        channelDictionary = [NSMutableDictionary dictionary];
        metaDictionary[accessKey] = channelDictionary;
    }
    channelDictionary[channel] = meta;
}

+ (void)innerSynchronizeMetaDataWithDictionary:(NSDictionary *)dictionary path:(NSString *)path
{
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return;
    }
    dispatch_queue_async_safe(IESGurdMetaFileQueue(), ^{
        IESGurdKitKeyedArchive(dictionary, path);
    });
}

+ (NSDictionary *)copiedDictionaryWithMetaDictionary:(IESGurdMetaDictionary)metaDictionary
{
    NSMutableDictionary *copiedDictionary = [NSMutableDictionary dictionary];
    [metaDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSMutableDictionary *obj, BOOL *stop) {
        if (obj.count > 0) {
            copiedDictionary[key] = [obj copy];
        }
    }];
    return [copiedDictionary copy];
}

#pragma mark - Accessor

static NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, IESGurdInactiveCacheMeta *> *> *kIESGurdInactiveMetaDictionary = nil;
static NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, IESGurdActivePackageMeta *> *> *kIESGurdActiveMetaDictionary = nil;

+ (NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, IESGurdInactiveCacheMeta *> *> *)inactiveMetaDictionary
{
    return kIESGurdInactiveMetaDictionary;
}

+ (void)setInactiveMetaDictionary:(NSMutableDictionary<NSString *,NSMutableDictionary<NSString *,IESGurdInactiveCacheMeta *> *> *)inactiveMetaDictionary
{
    kIESGurdInactiveMetaDictionary = inactiveMetaDictionary;
}

+ (NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, IESGurdActivePackageMeta *> *> *)activeMetaDictionary
{
    return kIESGurdActiveMetaDictionary;
}

+ (void)setActiveMetaDictionary:(NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, IESGurdActivePackageMeta *> *> *)activeMetaDictionary
{
    kIESGurdActiveMetaDictionary = activeMetaDictionary;
}

static BOOL kIESGurdNeedSynchronizeActiveMeta = NO;
static NSTimer *kSynchronizeActiveMetaTimer = nil;

+ (BOOL)needSynchronizeActiveMeta
{
    return kIESGurdNeedSynchronizeActiveMeta;
}

+ (void)setNeedSynchronizeActiveMeta:(BOOL)needSynchronizeActiveMeta
{
    kIESGurdNeedSynchronizeActiveMeta = needSynchronizeActiveMeta;
    
    if (needSynchronizeActiveMeta) {
        if (!kSynchronizeActiveMetaTimer) {
            kSynchronizeActiveMetaTimer = [NSTimer timerWithTimeInterval:5
                                                                  target:self
                                                                selector:@selector(synchronizeMetaData)
                                                                userInfo:nil
                                                                 repeats:NO];
            [[NSRunLoop mainRunLoop] addTimer:kSynchronizeActiveMetaTimer forMode:NSRunLoopCommonModes];
        }
    } else {
        [kSynchronizeActiveMetaTimer invalidate];
        kSynchronizeActiveMetaTimer = nil;
    }
}

static BOOL kIESGurdNeedSynchronizeInactiveMeta = NO;
static NSTimer *kSynchronizeInactiveMetaTimer = nil;

+ (BOOL)needSynchronizeInactiveMeta
{
    return kIESGurdNeedSynchronizeInactiveMeta;
}

+ (void)setNeedSynchronizeInactiveMeta:(BOOL)needSynchronizeInactiveMeta
{
    kIESGurdNeedSynchronizeInactiveMeta = needSynchronizeInactiveMeta;
    
    if (needSynchronizeInactiveMeta) {
        if (!kSynchronizeInactiveMetaTimer) {
            kSynchronizeInactiveMetaTimer = [NSTimer timerWithTimeInterval:5
                                                                    target:self
                                                                  selector:@selector(synchronizeMetaData)
                                                                  userInfo:nil
                                                                   repeats:NO];
            [[NSRunLoop mainRunLoop] addTimer:kSynchronizeInactiveMetaTimer forMode:NSRunLoopCommonModes];
        }
    } else {
        [kSynchronizeInactiveMetaTimer invalidate];
        kSynchronizeInactiveMetaTimer = nil;
    }
}

@end

#undef FILE_MANAGER
