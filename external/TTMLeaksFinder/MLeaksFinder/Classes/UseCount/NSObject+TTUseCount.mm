//
//  NSObject+MemoryUse.m
//  MLeaksFinder
//
//  Created by renpengcheng on 2019/2/19.
//  Copyright © 2019 zeposhe. All rights reserved.
//

#import "NSObject+TTUseCount.h"
#import <stdatomic.h>
#import <objc/runtime.h>
#import "TTMLUtils.h"

static NSInteger CountCleanTimeInterval = 60;

@implementation TTMLFObjectWrapper

- (instancetype)initWithObj:(id)obj {
    if (self = [super init]) {
        _objWeakRef = obj;
    }
    return self;
}

- (NSString *)description {
    return [self.objWeakRef description];
}

@end

@interface TTMLFCountDictionary : NSObject

@property (nonatomic, strong) NSLock *countDicLock;

@end

@implementation TTMLFCountDictionary
{
    atomic_intptr_t _curDicAddr;
    NSMutableDictionary<Class, NSMutableArray*> *_countDic;
    NSMutableDictionary<Class, NSMutableArray*> *_backupCountDic;
    dispatch_queue_t _serialQueue;
    intptr_t _xor;
}

static void *partnerKey = &partnerKey;
static void setpartnerDic(NSMutableDictionary *dic1, NSMutableDictionary *dic2) {
    objc_setAssociatedObject(dic1, partnerKey, dic2, OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(dic2, partnerKey, dic1, OBJC_ASSOCIATION_RETAIN);
}

static NSMutableDictionary *getPartnerDic(NSMutableDictionary *dic) {
    return objc_getAssociatedObject(dic, partnerKey);
}

- (instancetype)init {
    if (self = [super init]) {
        _countDic = [NSMutableDictionary dictionary];
        _backupCountDic = [NSMutableDictionary dictionary];
        _curDicAddr = (intptr_t)_countDic;
        _xor = (intptr_t)_countDic ^ (intptr_t)_backupCountDic;
        setpartnerDic(_backupCountDic, _countDic);
        _countDicLock = [[NSLock alloc] init];
        _serialQueue = dispatch_queue_create("MLeaksFinderQ", NULL);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CountCleanTimeInterval * NSEC_PER_SEC)), _serialQueue, ^{
            [self startGC];
        });
    }
    return self;
}

- (void)addObject:(id)objcet forKey:(Class)key {
    [_countDicLock lock];
    if (![[self currentCountDic] objectForKey:key]) {
        [self currentCountDic][(id<NSCopying>)key] = [NSMutableArray array];
    }
    [[self currentCountDic][key] addObject:objcet];
    [_countDicLock unlock];
}

- (void)getObjectsForKey:(Class)key
           completion:(void(^)(NSArray*))completion {
    dispatch_async(_serialQueue, ^{
        NSMutableArray *objs = [NSMutableArray array];
        [self->_countDicLock lock];
        [objs addObjectsFromArray:[[self currentCountDic] objectForKey:key] ?: @[]];
        [self->_countDicLock unlock];
        // 与cleanUp为同一队列，所以不用加锁
        [objs addObjectsFromArray:[getPartnerDic([self currentCountDic]) objectForKey:key]];
        NSMutableIndexSet *cleanIdxes = [[NSMutableIndexSet alloc] init];
        [objs enumerateObjectsUsingBlock:^(TTMLFObjectWrapper *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!obj.objWeakRef) {
                [cleanIdxes addIndex:idx];
            }
        }];
        [objs removeObjectsAtIndexes:cleanIdxes];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(objs);
        });
    });
}

- (void)startGC {
    dispatch_async(_serialQueue, ^{
        NSMutableDictionary *cleanUpDic = [self currentCountDic];
        // 此处加锁是为了避免在insert的过程中切换字典。。。
        [self->_countDicLock lock];
        [self switchCountDic];
        [self->_countDicLock unlock];
        NSMutableArray *cleanClasses = [NSMutableArray array];
        [cleanUpDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSMutableArray *obj, BOOL * _Nonnull stop) {
            NSMutableIndexSet *cleanIdxes = [[NSMutableIndexSet alloc] init];
            [obj enumerateObjectsUsingBlock:^(TTMLFObjectWrapper *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (!obj.objWeakRef) {
                    [cleanIdxes addIndex:idx];
                }
            }];
            [obj removeObjectsAtIndexes:cleanIdxes];
            if (!obj.count) {
                [cleanClasses addObject:key];
            }
        }];
        [cleanUpDic removeObjectsForKeys:cleanClasses];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CountCleanTimeInterval * NSEC_PER_SEC)), _serialQueue, ^{
        [self startGC];
    });
}

- (void)removeAllObjects {
    dispatch_async(_serialQueue, ^{
        [self->_countDicLock lock];
        [[self currentCountDic] removeAllObjects];
        [self->_countDicLock unlock];
        [getPartnerDic([self currentCountDic]) removeAllObjects];
    });
}

- (void)switchCountDic {
    atomic_fetch_xor(&_curDicAddr, _xor);
}

- (NSMutableDictionary<Class, NSMutableArray*>*)currentCountDic {
    return (__bridge NSMutableDictionary*)(void*)atomic_load(&_curDicAddr);
}
@end

@implementation NSObject (TTUseCount)

static TTMLFCountDictionary *_countDic;
static NSMutableSet *_monitorClasses;

+ (instancetype)tt_allocWithZone:(struct _NSZone *)zone {
    id ins = [self tt_allocWithZone:zone];
    if (ins) {
        TTMLFObjectWrapper *wrapper = [[TTMLFObjectWrapper alloc] initWithObj:ins];
        // 诉求是尽可能降低insert操作竞争概率
        Class targetCls = nil;
        NSSet *monitorClasses = nil;
        @synchronized (_monitorClasses) {
            monitorClasses = [_monitorClasses copy];
        }
        for (Class cls in monitorClasses) {
            if ([ins isKindOfClass:cls]) {
                targetCls = cls;
            }
        }
//        HMDThreadBacktrace *backtrace = [HMDThreadBacktrace backtraceOfCurrentThread];
//        wrapper.backtrace = backtrace;
        [_countDic addObject:wrapper forKey:targetCls ?: [self class]];
    }
    return ins;
};

// 开始统计每种class的实例个数
+ (void)tt_startMonitorInsOfClasses:(NSArray<Class>*)classes {
    NSAssert([NSThread isMainThread], @"must in main thread");
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _countDic = [[TTMLFCountDictionary alloc] init];
        _monitorClasses = [NSMutableSet set];
    });
    NSSet<Class> *set = nil;
    @synchronized (_monitorClasses) {
        set = [_monitorClasses copy];
        [_monitorClasses addObjectsFromArray:classes];
    }
    for (Class cls in classes) {
        if (![set containsObject:cls]) {
            [TTMLUtil tt_swizzleClass:object_getClass(cls)
                               SEL:@selector(allocWithZone:)
                           withSEL:@selector(tt_allocWithZone:)];
        }
    }

}

+ (void)tt_stopMonitorInsOfClasses:(NSArray<Class>*)classes {
    NSAssert([NSThread isMainThread], @"must in main thread");
    NSSet<Class> *set = nil;
    @synchronized (_monitorClasses) {
        set = [_monitorClasses copy];
    }
    for (Class cls in classes) {
        if ([set containsObject:cls]) {
            [TTMLUtil tt_swizzleClass:object_getClass(cls)
                               SEL:@selector(allocWithZone:)
                           withSEL:@selector(tt_allocWithZone:)];
        }
    }
}

+ (void)tt_stopMonitor {
    NSAssert([NSThread isMainThread], @"must in main thread");
    NSSet<Class> *set = nil;
    @synchronized (_monitorClasses) {
        set = [_monitorClasses copy];
    }
    for (Class cls in set) {
        [TTMLUtil tt_swizzleClass:object_getClass(cls)
                           SEL:@selector(allocWithZone:)
                       withSEL:@selector(tt_allocWithZone:)];
    }
    [_countDic removeAllObjects];
    for (NSTimer *timer in _reportTimers) {
        [timer invalidate];
    }
    [_reportTimers removeAllObjects];
}

// 获取某种class的实例个数
+ (void)tt_getInsOfClass:(Class)cls
           completion:(void(^)(NSArray<TTMLFObjectWrapper*>*))completion {
    return [_countDic getObjectsForKey:cls completion:completion];
}

static NSMutableArray<NSTimer*> *_reportTimers;
+ (void)tt_reportInsOfClasses:(NSArray<Class>*)classes
            reportInterval:(NSTimeInterval)interval
               reportBlock:(void(^)(Class cls, NSArray<TTMLFObjectWrapper*>*))reportBlock {
    NSAssert([NSThread isMainThread]
             && interval > 5 //太频繁影响性能
             && [classes isKindOfClass:[NSArray class]]
             && reportBlock, @"must in main thread and make sure params correct");
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _reportTimers = [NSMutableArray array];
    });
    [self tt_startMonitorInsOfClasses:classes];
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                      target:self
                                                    selector:@selector(reportInsOfClassesPeriodically:)
                                                    userInfo:@{@"classes":classes, @"block":[reportBlock copy]}
                                                     repeats:YES];
    [_reportTimers addObject:timer];
}

+ (void)reportInsOfClassesPeriodically:(NSTimer*)timer {
    NSDictionary *userInfo = timer.userInfo;
    NSArray<Class> *classes = userInfo[@"classes"];
    [classes enumerateObjectsUsingBlock:^(Class cls, NSUInteger idx, BOOL * _Nonnull stop) {
        [self tt_getInsOfClass:cls completion:^(NSArray<TTMLFObjectWrapper *> *array) {
            ((void(^)(Class cls, NSArray<TTMLFObjectWrapper*>*))userInfo[@"block"])(cls, array);
        }];
    }];
}

@end
