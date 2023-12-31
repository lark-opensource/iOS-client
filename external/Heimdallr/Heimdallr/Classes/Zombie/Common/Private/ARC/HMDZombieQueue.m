//
//  HMDZombieQueue.m
//  Heimdallr
//
//  Created by maniackk on 2021/7/13.
//

#import "HMDZombieQueue.h"
#import <malloc/malloc.h>
#import <pthread/pthread.h>
#import "HMDZombieHandle.h"
#import <objc/runtime.h>
#import "HMDZombieMonitor.h"
#import "HeimdallrUtilities.h"

//#define ZombieCheckLog
#ifdef ZombieCheckLog
#define ZombieLog(...) HMDPrint(__VA_ARGS__)
#else
#define ZombieLog(...)
#endif

// 每次添加缓存就清理一次会频繁消耗性能，故清理时留有一定量buffer，避免频繁清理 10MB 预估对象平均大小128
static float     const kMaxCacheCleanFactor = 0.9;

@interface HMDZombieQueue()

@property (nonatomic, assign) pthread_mutex_t lock;
@property (nonatomic, assign) size_t zombieCacheSize;

@property (nonatomic, assign) HMDZombieCache *globalHeadCache;
@property (nonatomic, assign) HMDZombieCache *globalTailCache;
@property (nonatomic, assign) NSUInteger globalTotalCacheSize;
@property (nonatomic, assign) NSUInteger globalTotalCacheCount;
@property (nonatomic, assign) NSUInteger globalTotalBacktraceCount;
@property (nonatomic, assign) malloc_zone_t *globalCacheZone;

@property (nonatomic, assign) HMDZombieCache *mainHeadCache;
@property (nonatomic, assign) HMDZombieCache *mainTailCache;
@property (nonatomic, assign) NSUInteger mainTotalCacheSize;
@property (nonatomic, assign) NSUInteger mainTotalCacheCount;
@property (nonatomic, assign) NSUInteger mainTotalBacktraceCount;
@property (nonatomic, assign) malloc_zone_t *mainCacheZone;

@end

@implementation HMDZombieQueue

- (instancetype)init {
    self = [super init];
    if (self) {
        //create recursive attribute
        pthread_mutexattr_t attr;
        pthread_mutexattr_init(&attr);
        //set recursive attribute
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init(&_lock, &attr);
        self.zombieCacheSize = malloc_good_size(sizeof(HMDZombieCache));
        
        self.mainHeadCache = NULL;
        self.globalHeadCache = NULL;
        self.mainTailCache = NULL;
        self.globalTailCache = NULL;
        self.globalTotalCacheSize = 0;
        self.mainTotalCacheSize = 0;
        self.globalTotalCacheCount = 0;
        self.mainTotalCacheCount = 0;
        self.mainTotalBacktraceCount = 0;
        self.globalTotalBacktraceCount = 0;
    }
    return self;
}

- (void)pushCache:(HMDZombieCache *)cache isMainThread:(bool)isMainThread {
    NSAssert(cache, @"cache can not be null");
    HMDZombieCache **headCache = NULL;
    HMDZombieCache **tailCache = NULL;
    NSUInteger *totalCacheSize = NULL;
    NSUInteger *totalCacheCount = NULL;
    NSUInteger *totalBacktraceCount = NULL;
    
    if (isMainThread) {
        headCache = &_mainHeadCache;
        tailCache = &_mainTailCache;
        totalCacheSize = &_mainTotalCacheSize;
        totalCacheCount = &_mainTotalCacheCount;
        totalBacktraceCount = &_mainTotalBacktraceCount;
    }
    else {
        headCache = &_globalHeadCache;
        tailCache = &_globalTailCache;
        totalCacheSize = &_globalTotalCacheSize;
        totalCacheCount = &_globalTotalCacheCount;
        totalBacktraceCount = &_globalTotalBacktraceCount;
    }
    
    if ((*headCache) == NULL) {
        *headCache = cache;
        *tailCache = cache;
    } else {
        (*tailCache)->next = cache;
        *tailCache = cache;
    }
    
    (*totalCacheSize) += (cache->objSize + self.zombieCacheSize);
    (*totalCacheCount) += 1;
    if (cache->backtrace != NULL) {
        (*totalBacktraceCount) += 1;
    }
    
    // 避免峰值
    if ((*totalCacheSize) > self.maxCacheSize || (*totalCacheCount) > self.maxCacheCount) {
        [self cleanCachesIfNeed:isMainThread];
    }
}

// 取出缓存
- (HMDZombieCache *)popCache:(bool)isMainThread {
    HMDZombieCache **headCache = NULL;
    HMDZombieCache **tailCache = NULL;
    NSUInteger *totalCacheSize = NULL;
    NSUInteger *totalCacheCount = NULL;
    NSUInteger *totalBacktraceCount = NULL;
    
    if (isMainThread) {
        headCache = &_mainHeadCache;
        tailCache = &_mainTailCache;
        totalCacheSize = &_mainTotalCacheSize;
        totalCacheCount = &_mainTotalCacheCount;
        totalBacktraceCount = &_mainTotalBacktraceCount;
    }
    else {
        headCache = &_globalHeadCache;
        tailCache = &_globalTailCache;
        totalCacheSize = &_globalTotalCacheSize;
        totalCacheCount = &_globalTotalCacheCount;
        totalBacktraceCount = &_globalTotalBacktraceCount;
    }
    HMDZombieCache *cache = *headCache;
    if (cache == NULL) {
        *tailCache = NULL;
        return cache;
    }
    *headCache = (*headCache)->next;
    (*totalCacheCount) -= 1;
    if (cache->backtrace != NULL) {
        (*totalBacktraceCount) -= 1;
    }
    (*totalCacheSize) -= (cache->objSize + self.zombieCacheSize);
    return cache;
}

// 缓存🧟‍♀️僵尸类
- (void)storeObj:(void * _Nonnull)zombieObj cfAllocator:(CFAllocatorRef _Nullable)cfAllocator backtrace:(const char * _Nullable)backtrace size:(size_t)size{
    if (pthread_main_np()) {
        HMDZombieCache *cache = (HMDZombieCache*)malloc_zone_malloc(self.mainCacheZone, sizeof(HMDZombieCache));
        cache->object = zombieObj;
        cache->objSize = size;
        cache->cfAllocator = cfAllocator;
        cache->next = NULL;
        cache->backtrace = NULL;
        if (backtrace) {
            if (self.mainTotalBacktraceCount <= [HMDZombieMonitor sharedInstance].zombieConfig.maxZombieDeallocCount) {
                cache->backtrace = backtrace;
            }
            else {
                free((void *)backtrace);
            }
        }
        [self pushCache:cache isMainThread:YES];
    } else {
        pthread_mutex_lock(&_lock);
        HMDZombieCache *cache = (HMDZombieCache*)malloc_zone_malloc(self.globalCacheZone, sizeof(HMDZombieCache));
        cache->object = zombieObj;
        cache->objSize = size;
        cache->cfAllocator = cfAllocator;
        cache->next = NULL;
        cache->backtrace = NULL;
        if (backtrace) {
            if (self.globalTotalBacktraceCount <= [HMDZombieMonitor sharedInstance].zombieConfig.maxZombieDeallocCount) {
                cache->backtrace = backtrace;
            }
            else {
                free((void *)backtrace);
            }
        }
        [self pushCache:cache isMainThread:NO];
        pthread_mutex_unlock(&_lock);
    }
}

// 释放🧟‍♀️僵尸类
- (void)freeZombieObject:(HMDZombieCache *)cache isMainThread:(bool)isMainThread {
    void * obj = cache->object;
    free((void *)cache->backtrace);
    ZombieLog("free-%p-%s\n", obj, (char *)class_getName(object_getClass((__bridge id _Nullable)(obj))));
    [HMDZombieHandle free:obj cfAllocator:cache->cfAllocator];
    if (isMainThread) {
        malloc_zone_free(self.mainCacheZone, cache);
    } else {
        malloc_zone_free(self.globalCacheZone, cache);
    }
}

// 定时清理
- (void)cleanCachesIfNeed:(bool)isMainThread {
    NSUInteger *totalCacheSize = NULL;
    NSUInteger *totalCacheCount = NULL;
    NSUInteger *totalBacktraceCount = NULL;
    
    if (isMainThread) {
        totalCacheSize = &_mainTotalCacheSize;
        totalCacheCount = &_mainTotalCacheCount;
        totalBacktraceCount = &_mainTotalBacktraceCount;
    }
    else {
        totalCacheSize = &_globalTotalCacheSize;
        totalCacheCount = &_globalTotalCacheCount;
        totalBacktraceCount = &_globalTotalBacktraceCount;
    }
    ZombieLog("clean if need %10d %10d\n", (*totalCacheCount), (*totalCacheSize));
    while ((*totalCacheCount) > self.maxCacheCount * kMaxCacheCleanFactor ||
           (*totalCacheSize) > self.maxCacheSize * kMaxCacheCleanFactor) {
        HMDZombieCache *cache = [self popCache:isMainThread];
        if (cache == NULL) {
            break;
        }
        [self freeZombieObject:cache isMainThread:isMainThread];
    }
}

// 内存⚠️释放所有缓存
- (void)cleanupZombieCache {
    hmd_dispatch_main_sync_safe(^{
        HMDZombieCache *cache = [self popCache:YES];
        while (cache) {
            [self freeZombieObject:cache isMainThread:YES];
            cache = [self popCache:YES];
        }
        // 强制回收zone内所有cache，并开启新的zone
        if (self.mainCacheZone) {
            malloc_destroy_zone(self.mainCacheZone);
        }
        self.mainCacheZone = malloc_create_zone(0, 0);
        malloc_set_zone_name(self.mainCacheZone, "HMDMainZombie");
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 外部调取用需加锁保护, 保证该zone下的cache都回收
        pthread_mutex_lock(&self->_lock);
        HMDZombieCache *cache = [self popCache:NO];
        while (cache) {
            [self freeZombieObject:cache isMainThread:NO];
            cache = [self popCache:NO];
        }
        // 强制回收zone内所有cache，并开启新的zone
        if (self.globalCacheZone) {
            malloc_destroy_zone(self.globalCacheZone);
        }
        self.globalCacheZone = malloc_create_zone(0, 0);
        malloc_set_zone_name(self.globalCacheZone, "HMDGlobalZombie");
        pthread_mutex_unlock(&self->_lock);
    });
}

- (const char*)getBacktrace:(void *)obj {
    __block const char *backtrace = NULL;
    __block BOOL isEnd = NO;
    hmd_dispatch_main_sync_safe(^{
        HMDZombieCache *cache = self.mainHeadCache;
        while (cache)
        {
            if (cache->object == obj) {
                isEnd = YES;
                if (cache->backtrace) {
                    backtrace = strdup(cache->backtrace);
                }
                break;
            }
            cache = cache->next;
        }
    });
    if (isEnd || backtrace) {
        return backtrace;
    }
    pthread_mutex_lock(&_lock);
    HMDZombieCache *cache = self.globalHeadCache;
    while (cache)
    {
        if (cache->object == obj) {
            if (cache->backtrace) {
                backtrace = strdup(cache->backtrace);
            }
            break;
        }
        cache = cache->next;
    }
    pthread_mutex_unlock(&_lock);
    return backtrace;
}

- (void)createCacheZone {
    // 创建一个 zone
    if (self.globalCacheZone) {
        malloc_destroy_zone(self.globalCacheZone);
    }
    self.globalCacheZone = malloc_create_zone(0, 0);
    malloc_set_zone_name(self.globalCacheZone, "HMDGlobalZombie");
    
    if (self.mainCacheZone) {
        malloc_destroy_zone(self.mainCacheZone);
    }
    self.mainCacheZone = malloc_create_zone(0, 0);
    malloc_set_zone_name(self.mainCacheZone, "HMDMainZombie");
}

@end
