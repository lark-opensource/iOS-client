//
//  HMDZombieQueue.h
//  Heimdallr
//
//  Created by maniackk on 2021/7/13.
//

#import <Foundation/Foundation.h>

typedef struct ZombieCache {
    void * _Nonnull object;
    struct ZombieCache * _Nullable next;
    CFAllocatorRef _Nullable cfAllocator;
    const char * _Nullable backtrace;
    size_t objSize;
} HMDZombieCache;

NS_ASSUME_NONNULL_BEGIN

@interface HMDZombieQueue : NSObject

// 缓存大小 默认10MB*0.8
@property (nonatomic, assign) NSUInteger maxCacheSize;
// 检测数量 默认80 * 1024*0.8
@property (nonatomic, assign) NSUInteger maxCacheCount;

- (void)createCacheZone;

- (void)storeObj:(void * _Nonnull)zombieObj cfAllocator:(CFAllocatorRef _Nullable)cfAllocator backtrace:(const char * _Nullable)backtrace size:(size_t)size;

- (const char*)getBacktrace:(void *)obj;

- (void)cleanupZombieCache;

@end

NS_ASSUME_NONNULL_END
