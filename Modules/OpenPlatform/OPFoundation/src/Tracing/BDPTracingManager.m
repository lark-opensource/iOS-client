//
//  BDPTracingManager.m
//  Timor
//
//  Created by changrong on 2020/3/9.
//

#import "BDPTracingManager.h"
#import <ECOInfra/BDPLog.h>
#import "BDPUniqueID.h"
#import <os/lock.h>

#import "BDPModuleEngineType.h"
#import "BDPTimorClient.h"
#import "OPResolveDependenceUtil.h"

@interface BDPTracingManager()

@property (nonatomic, strong, readwrite) BDPTracing *containerTrace;
@property (nonatomic, copy, nullable) GenerateNewTracing generateNewTracing;

@property (nonatomic, assign) os_unfair_lock traceMapUnfairLock;

/// 分桶的traceMap，目前不做合并，使用两个变量方便维护
@property (nonatomic, strong) NSMutableDictionary<OPAppUniqueID *, BDPTracing *> *gadgetTraceMap;
@property (nonatomic, strong) NSMutableDictionary<OPAppUniqueID *, BDPTracing *> *h5GadgetTraceMap;
@property (nonatomic, strong) NSMutableDictionary<OPAppUniqueID *, BDPTracing *> *blockTraceMap;

@end

static NSString *const kBDPThreadTracingKey = @"kBDPThreadTracingKey";
static NSUInteger const kBDPTraceIdMaxLength = 1000;

@implementation BDPTracingManager

+ (instancetype)sharedInstance {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[BDPTracingManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if(self = [super init]) {
        _traceMapUnfairLock = OS_UNFAIR_LOCK_INIT;
        _gadgetTraceMap = [NSMutableDictionary dictionary];
        _h5GadgetTraceMap = [NSMutableDictionary dictionary];
        _blockTraceMap = [NSMutableDictionary dictionary];
    }
    return self;
}

/// 创建一个小程序生命周期的tracing
- (BDPTracing *)generateTracing {
    return [self generateTracingWithParent:nil];
}

/// 使用parent创建一个tracing，基于parent扩展span
/// traceId长度加了兜底长度，最大 kBDPTraceIdMaxLength
- (BDPTracing *)generateTracingWithParent:(BDPTracing * _Nullable)parent {
    if (!self.generateNewTracing) {
        BDPLogWarn(@"generateNewTracing is nil");
        NSAssert(NO, @"generateNewTracing is nil");
        return [[BDPTracing alloc] initWithTraceId:@"NO-GENERATE-TRACING"];
    }
    if (!parent) {
        parent = self.containerTrace;
    }
    NSString *traceId = self.generateNewTracing(parent.traceId);
    if (traceId.length > kBDPTraceIdMaxLength) {
        traceId = [traceId substringToIndex:kBDPTraceIdMaxLength];
    }
    return [[BDPTracing alloc] initWithTraceId:traceId];
}

/// 通过uniqueID创建Tracing，详见.h
- (BDPTracing *)generateTracingByUniqueID:(BDPUniqueID *)uniqueID {
    if (!uniqueID.isValid) {
        BDPLogWarn(@"uniqueID is invalid");
        NSAssert(NO, @"uniqueID is invalid");
        return nil;
    }
    os_unfair_lock_lock(&_traceMapUnfairLock);
    NSMutableDictionary<OPAppUniqueID *, BDPTracing *> * traceMap = [self traceMap:uniqueID.appType];
    if (traceMap[uniqueID]) {
        BDPLogWarn(@"uniqueID generate tracing repeat, traceId: %@", traceMap[uniqueID]);
        os_unfair_lock_unlock(&_traceMapUnfairLock);
        NSAssert(NO, @"uniqueID generate tracing repeat");
        return nil;
    }
    traceMap[uniqueID] = [self generateTracing];
    os_unfair_lock_unlock(&_traceMapUnfairLock);
    return [self getTracingByUniqueID:uniqueID];
}

/// 通过uniqueID清理Tracing，详见.h
- (void)clearTracingByUniqueID:(BDPUniqueID *)uniqueID {
    BDPLogDebug(@"clear tracing for uniqueID: %@", uniqueID)
    if (!uniqueID.isValid) {
        BDPLogWarn(@"uniqueID is invalid, do nothing");
        return;
    }
    os_unfair_lock_lock(&_traceMapUnfairLock);
    NSMutableDictionary<OPAppUniqueID *, BDPTracing *> * traceMap = [self traceMap:uniqueID.appType];
    [traceMap removeObjectForKey:uniqueID];
    os_unfair_lock_unlock(&_traceMapUnfairLock);
}

/// 通过所有Tracing，详见.h
- (void)clearAllTracing {
    BDPLogDebug(@"clear all tracing")
    os_unfair_lock_lock(&_traceMapUnfairLock);
    [self.gadgetTraceMap removeAllObjects];
    [self.h5GadgetTraceMap removeAllObjects];
    [self.blockTraceMap removeAllObjects];
    os_unfair_lock_unlock(&_traceMapUnfairLock);
    
}

/// 通过uniqueID获取tracing，详见.h
- (nullable BDPTracing *)getTracingByUniqueID:(BDPUniqueID *)uniqueID {
    if (!uniqueID.isValid) {
        BDPLogInfo(@"uniqueID is invalid");
        return nil;
    }
    os_unfair_lock_lock(&_traceMapUnfairLock);
    NSMutableDictionary *traceMap = [self traceMap:uniqueID.appType];
    if (!traceMap) {
        BDPLogWarn(@"do not support appType");
        os_unfair_lock_unlock(&_traceMapUnfairLock);
        return nil;
    }
    BDPTracing *trace = traceMap[uniqueID];
    os_unfair_lock_unlock(&_traceMapUnfairLock);
//    if (!trace &&
//        uniqueID.appType == OPAppTypeBlock &&
//        [uniqueID.blockTrace isKindOfClass: [BDPTracing class]]) {
//        trace = (BDPTracing *)uniqueID.blockTrace;
//    }
    
    if (!trace && uniqueID.appType == OPAppTypeBlock) {
        id<OPTraceProtocol> blockTrace = [OPResolveDependenceUtil blockTraceWithID:uniqueID];
        if([blockTrace isKindOfClass: [BDPTracing class]] ) {
            trace = (BDPTracing *)blockTrace;
        }
    }
    
    if (!trace) {
        BDPLogInfo(@"uniqueID:%@ do not have trace", uniqueID);
    }
    return trace;
}


/// /// 注册Tracing生成算法，并封装一个container维度的tracing
- (void)registerTracing:(NSString *)prefix
           generateFunc:(nonnull GenerateNewTracing)func {
    if (!func || !prefix) {
        BDPLogWarn(@"generateNewTracing func is null or prefix is null");
        return;
    }
    self.containerTrace = [[BDPTracing alloc] initWithTraceId:prefix];
    self.generateNewTracing = func;
}

- (nullable NSMutableDictionary<OPAppUniqueID *, BDPTracing *> *)traceMap:(BDPType)type {
    NSMutableDictionary *traceMap = nil;
    switch (type) {
        case BDPTypeNativeApp:
            traceMap = self.gadgetTraceMap;
            break;
        case BDPTypeBlock:
            traceMap = self.blockTraceMap;
            break;
        default:
            BDPLogWarn(@"do not support appType: %@", @(type));
            return nil;
    }
    return traceMap;
}



@end

@implementation BDPTracingManager (ThreadTracing)
+ (dispatch_block_t)convertTracingBlock:(dispatch_block_t)block {
    BDPTracing *tracing = [self getThreadTracing];
    dispatch_block_t tracingBlock = ^(void) {
        [self doBlock:block withLinkTracing:tracing];
    };
    return tracingBlock;
}

+ (BDPTracing *)getThreadTracing {
    NSMutableDictionary *threadLocalStorage = [NSThread currentThread].threadDictionary;
    return threadLocalStorage[kBDPThreadTracingKey];
}

+ (void)bindCurrentThreadTracing:(BDPTracing *)tracing {
    if (!tracing) {
        BDPLogWarn(@"can not bind a nil tracing!!!");
        return;
    }
    [self setThreadTracing:tracing];
}

+ (void)doBlock:(dispatch_block_t)block withLinkTracing:(BDPTracing * _Nullable)tracing {
    BDPTracing *newTracing = [BDPTracingManager.sharedInstance generateTracingWithParent:tracing];
    BDPTracing *currentTracing = [self getThreadTracing];
    [self setThreadTracing:newTracing];
    if (block) {
        block();
    }
    [self setThreadTracing:currentTracing];
}

+ (void)setThreadTracing:(BDPTracing *)tracing {
    if (!tracing) {
        [self removeThreadTracing];
        return;
    }
    NSMutableDictionary *threadLocalStorage = [NSThread currentThread].threadDictionary;
    threadLocalStorage[kBDPThreadTracingKey] = tracing;
}

+ (void)removeThreadTracing {
    NSMutableDictionary *threadLocalStorage = [NSThread currentThread].threadDictionary;
    if (!threadLocalStorage[kBDPThreadTracingKey]) {
        return;
    }
    [threadLocalStorage removeObjectForKey:kBDPThreadTracingKey];
}

@end
