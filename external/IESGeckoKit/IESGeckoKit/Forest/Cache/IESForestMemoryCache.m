// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestMemoryCache.h"

#import "IESForestMemoryCacheManager.h"
#import <IESGeckoKit/IESGurdLogProxy.h>
#import <IESGeckoKit/IESGeckoKit.h>
#import <ByteDanceKit/BTDMacros.h>

static const int MEGA_BYTE_PER_BYTE = 1024 * 1024;
static const int DEFAULT_CACHE_LIMIT = 10 * MEGA_BYTE_PER_BYTE;

@interface IESForestMemoryCache () <IESGurdEventDelegate, NSCacheDelegate>

@property (nonatomic, assign) NSInteger cacheLimit;
@property (nonatomic, strong) NSCache *sharedCache;
@property (nonatomic, assign) pthread_mutex_t keysLock;
@property (nonatomic, strong) NSMutableSet *cacheKeys;

@end

@implementation IESForestMemoryCache

- (void)updateCacheLimit:(NSInteger)cacheLimit
{
    if (cacheLimit == 0) {
        [self.sharedCache removeAllObjects];
    }
    if (cacheLimit <= 0 || cacheLimit >= 100 * MEGA_BYTE_PER_BYTE) {
        cacheLimit = DEFAULT_CACHE_LIMIT;
    }
    self.cacheLimit = cacheLimit;
    self.sharedCache.totalCostLimit = self.cacheLimit;
}

+ (instancetype)sharedInstance
{
    static IESForestMemoryCache *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (void)updateCacheLimit:(NSInteger)cacheLimit
{
    [[self sharedInstance] updateCacheLimit:cacheLimit];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        pthread_mutexattr_t attr;
        pthread_mutexattr_init(&attr);
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init(&_keysLock, &attr);
        pthread_mutexattr_destroy(&attr);

        [IESGurdKit registerEventDelegate:self];
        _cacheKeys = [[NSMutableSet alloc] init];
        _sharedCache = [[NSCache alloc] init];
        [self updateCacheLimit:DEFAULT_CACHE_LIMIT];
    }
    return self;
}

- (void)dealloc
{
    pthread_mutex_destroy(&_keysLock);
}

- (void)gurdDidFinishApplyingPackageForAccessKey:(NSString *)accessKey channel:(NSString *)channel succeed:(BOOL)succeed error:(NSError * _Nullable)error
{
    if (!succeed) {
        return;
    }
//    IESGurdLogInfo(@"Forest - IESForestMemoryCache gecko channel has update!");
    [_cacheKeys enumerateObjectsUsingBlock:^(NSString* key, BOOL * _Nonnull stop) {
        if ([key hasPrefix:[NSString stringWithFormat:@"%@-%@", accessKey, channel]]) {
            [self.sharedCache removeObjectForKey:key];
        }
    }];
}

#pragma mark - NSCacheDelegate

- (void)cache:(NSCache *)cache willEvictObject:(id)obj
{
    NSString *cacheKey = ((IESForestResponse *)obj).cacheKey;
    pthread_mutex_lock(&_keysLock);
    [_cacheKeys removeObject:cacheKey];
    pthread_mutex_unlock(&_keysLock);
}


- (nullable IESForestResponse *)responseForKey:(NSString *)key
{
    if (BTD_isEmptyString(key)) {
        return nil;
    }
    if ([self.sharedCache objectForKey:key]) {
//        IESGurdLogInfo(@"Forest - [get Response from memory]-key-%@", key);
        return [self.sharedCache objectForKey:key];
    }
    return nil;
}

- (void)setResponse:(IESForestResponse *)response forKey:(NSString *)key
{
    if (BTD_isEmptyString(key)) {
        return;
    }

    if (response.data.length <= 0) {
        return;
    }
    
//    IESGurdLogInfo(@"Forest - set Response for key: %@", key);
    pthread_mutex_lock(&_keysLock);
    [self.sharedCache setObject:response forKey:key cost:response.data.length];
    [_cacheKeys addObject:key];
    pthread_mutex_unlock(&_keysLock);
}

- (void)removeResponseForKey:(NSString *)key
{
    if (BTD_isEmptyString(key)) {
        return;
    }
    [self.sharedCache removeObjectForKey:key];
}

- (void)removeAll
{
    [self.sharedCache removeAllObjects];
}

@end
