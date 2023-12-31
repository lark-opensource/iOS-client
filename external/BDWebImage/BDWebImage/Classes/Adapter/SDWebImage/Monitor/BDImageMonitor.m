//
//  BDImageMonitor.m
//  BDWebImage
//
//  Created by fengyadong on 2017/12/6.
//

#import "BDImageMonitor.h"
#import "BDImageMonitor+Private.h"
#import <mach/mach_time.h>
#import <pthread.h>
#import <YYCache/YYCache.h>
#import <BDAlogProtocol/BDAlogProtocol.h>

@interface BDImageMonitor () {
    NSMutableDictionary *_recorder;
    pthread_mutex_t _mutex;
    YYCache *_cache;
    NSMutableDictionary *_store;
    pthread_mutex_t _storeMutex;
}
@end

@implementation BDImageMonitor

- (instancetype)initWithModule:(NSString *)module action:(NSString *)action {
    if (self = [super init]) {
        self.module = module ?: @"__all__";
        self.action = action ?: @"default";
        _recorder = [NSMutableDictionary dictionary];
        pthread_mutex_init(&_mutex, NULL);
        _cache = [YYCache cacheWithName:[NSString stringWithFormat:@"com.bd.imagemonitor.%@.%@",module,action]];
        
        pthread_mutex_init(&_storeMutex, NULL);
        _store = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Public Method

- (void)start:(NSString *)name {
    if (name.length <= 0) return;
    uint64_t begin = mach_absolute_time();
    pthread_mutex_lock(&_mutex);
    if (![_recorder objectForKey:name]) {
        [_recorder setValue:@(begin) forKey:name];
    }
    pthread_mutex_unlock(&_mutex);
}

- (NSTimeInterval)stop:(NSString *)name {
    if (name.length <= 0) return 0;
    uint64_t end = mach_absolute_time();
    pthread_mutex_lock(&_mutex);
    uint64_t begin = [_recorder[name] unsignedLongLongValue];
    NSTimeInterval interval = [[self class] microsecondsFromMachTime:end - begin];
#ifdef DEBUG
    NSLog(@"============Module:%@ Action:%@ Time taken for %@ is %g ms",
          self.module, self.action, name, interval);
#endif
    [_recorder removeObjectForKey:name];
    pthread_mutex_unlock(&_mutex);
    
    if (begin > end || begin == 0.0 || end == 0.0) {
        return 0.0;
    }
    return interval;
}

- (NSNumber *)recordValue:(NSNumber *)number forName:(NSString *)name {
    if (name.length <= 0) name = self.action;

    if (strcmp([number objCType], @encode(BOOL)) == 0) {
        //BOOL值累加无意义
        BDALOG_PROTOCOL_WARN_TAG(@"BDWebImage",@"this is a bool");
        return number;
    }

    NSNumber *value = (NSNumber *)[_cache objectForKey:name];
    NSDecimalNumber *total = [NSDecimalNumber decimalNumberWithDecimal:value.decimalValue];
    NSDecimalNumber *current = [NSDecimalNumber decimalNumberWithDecimal:number.decimalValue];
    NSNumber *result = [total decimalNumberByAdding:current];

    [_cache setObject:result forKey:name];

#ifdef DEBUG
    NSLog(@"============Module:%@ Action:%@ Total Value for %@ is %g",
          self.module, self.action, name, result.doubleValue);
#endif

    return result;
}

- (BOOL)ifExist:(NSString *)name {
    if (name.length <= 0) return NO;
    BOOL rst = NO;
    pthread_mutex_lock(&_mutex);
    rst = [_recorder objectForKey:name] != nil;
    pthread_mutex_unlock(&_mutex);
    return rst;
}


- (void)storeData:(NSDictionary *) data forKey:(NSString *)key {
    if (data == nil ||
        key.length <= 0) {
        return;
    }
    pthread_mutex_lock(&_storeMutex);
    [_store setObject:data forKey:key];
    pthread_mutex_unlock(&_storeMutex);
}
- (NSDictionary *)removeDataForKey:(NSString *)key {
    if (key.length <= 0) {
        return nil;
    }
    pthread_mutex_lock(&_storeMutex);
    NSDictionary *data = _store[key];
    [_store removeObjectForKey:key];
    pthread_mutex_unlock(&_storeMutex);
    return data;
}

- (void)reset {
    pthread_mutex_lock(&_mutex);
    [_recorder removeAllObjects];
    pthread_mutex_unlock(&_mutex);
    [_cache removeAllObjects];
    
    pthread_mutex_lock(&_storeMutex);
    [_store removeAllObjects];
    pthread_mutex_unlock(&_storeMutex);
}

#pragma mark - Helper

+ (double)microsecondsFromMachTime:(uint64_t)time {
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);
    return (double)time * (double)timebase.numer /
    (double)timebase.denom / 1e6;
}

@end
