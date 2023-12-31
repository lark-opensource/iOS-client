//
//  TTMonitor.m
//  Heimdallr
//
//  Created by joy on 2018/3/25.
//

#import "HMDTTMonitor.h"
#import "HMDTTMonitorTracker.h"
#import <objc/runtime.h>
#import "HMDSwizzle.h"
#import "HMDInjectedInfo.h"
#import "HMDMonitorDataManager.h"
#import "HMDInjectedInfo.h"
#import "HMDGCD.h"
#import "HMDALogProtocol.h"
#import "HMDSessionTracker.h"
#import "HMDTTMonitorInterceptor.h"
#import "HMDTTMonitorTracker.h"
#import "HMDTTMonitorExchangeHelper.h"
#import "HMDTTMonitorHelper.h"
#import "HMDHermasManager.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
#import "HMDTTMonitorTracker2.h"
#import "HMDTTMonitorServiceProtocol.h"
#import "HMDTTMonitorInterceptorParam.h"

#import "HMDMacro.h"

#import <pthread/pthread.h>

static pthread_rwlock_t log_modify_block_lock = PTHREAD_RWLOCK_INITIALIZER;
static HMDTTMonitorLodModifyBlock _Nullable globalLogModifyBlock = nil;

NSString *const kHMDTTMonitorServiceLogTypeStr = @"service_monitor";

@interface HMDTTMonitor() <HMDTTMonitorServiceProtocol>

@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, strong) id<HMDTTMonitorTracker> tracker;
@property (nonatomic, strong) HMDMonitorDataManager *dataManager;
@property (nonatomic, strong) id<HMDTTMonitorInterceptor> interceptorChain;
@end

@implementation HMDTTMonitor

+ (void)initialize {
    if (self == [HMDTTMonitor class]) {
        [HMDHermasManager defaultManager];
    }
}

static HMDTTMonitor *s_manager;
+ (HMDTTMonitor *)defaultManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSAssert([HMDInjectedInfo defaultInfo].appID, @"The appid of the main app cannot be nil!");
        s_manager = [[HMDTTMonitor alloc] initMonitorWithAppID:[HMDInjectedInfo defaultInfo].appID injectedInfo:nil];
    });
    return s_manager;
}

+ (void)setUseShareQueueStrategy:(BOOL)on {
    [HMDTTMonitorTracker setUseShareQueueStrategy:on];
}

+ (dispatch_queue_t)globalSyncQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.hmdttmonitor.serialqueue", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

- (instancetype)initMonitorWithAppID:(NSString *)appID injectedInfo:(HMDTTMonitorUserInfo *)info {
    self = [super init];
    if (self) {
        self.appID = appID;
        
        if (hermas_enabled()) {
            // 由于Hermas内部已经有自己的队列，这里全局共享1个队列，不再为每个appid启动1个串行队列
            self.serialQueue = [self.class globalSyncQueue];
            self.tracker = [[HMDTTMonitorTracker2 alloc] initMonitorWithAppID:appID injectedInfo:info];
        } else {
            NSString *label = [NSString stringWithFormat:@"com.hmdttmonitor.serialqueue.%@",self.appID];
            self.serialQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
            self.tracker = [[HMDTTMonitorTracker alloc] initMonitorWithAppID:appID injectedInfo:info];
            self.dataManager = ((HMDTTMonitorTracker *)(self.tracker)).dataManager;
        }
        HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitor initialize with appID : %@, injected info : %@", appID, info ? info.appID : @"nil");

        [self setupInterceptorChain];
    }
    return self;
}

- (void)setupInterceptorChain {
    // immutable copy interceptor
    HMDTTMonitorImmutableCopyInterceptor *copyInterceptor = [[HMDTTMonitorImmutableCopyInterceptor alloc] init];
    // sample check interceptor
    HMDTTMonitorSampleInterceptor *sampleInterceptor = [[HMDTTMonitorSampleInterceptor alloc] initWithQueue:self.serialQueue tracker:self.tracker];
    // black list interceptor
    HMDTTMonitorBlacklistInterceptor *blacklistInterceptor = [[HMDTTMonitorBlacklistInterceptor alloc] initWithQueue:self.serialQueue];
    // frequence detector interceptor
    HMDTTMonitorFrequenceDetectInterceptor *frequenceDetector = [[HMDTTMonitorFrequenceDetectInterceptor alloc] init];
    // tracker interceptor
    HMDTTMonitorTrackerInterceptor *trackerInterceptor = [[HMDTTMonitorTrackerInterceptor alloc] initWithTracker:self.tracker queue:self.serialQueue];
    
    [copyInterceptor setNextInterceptor:sampleInterceptor];
    [sampleInterceptor setNextInterceptor:blacklistInterceptor];
    [blacklistInterceptor setNextInterceptor:frequenceDetector];
    [frequenceDetector setNextInterceptor:trackerInterceptor];
    self.interceptorChain = copyInterceptor;
}

- (void)hookTTMonitorInterfaceIfNeeded:(NSNumber *)needHook {
    [HMDTTMonitorExchangeHelper exchangeTTMonitorInterfaceIfNeeded:needHook];
}

- (void)cleanupNotUploadAndReportedPerformanceData {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if([self.tracker respondsToSelector:NSSelectorFromString(@"cleanupNotUploadAndReportedPerformanceData")]) {
        [self.tracker performSelector:NSSelectorFromString(@"cleanupNotUploadAndReportedPerformanceData")];
    }
#pragma clang diagnostic pop
}

#pragma mark -- Recommended interface for service monitoring
- (void)hmdTrackService:(NSString *)serviceName metric:(NSDictionary <NSString *, NSNumber *> *)metric category:(NSDictionary *)category extra:(NSDictionary *)extraValue {
    [self hmdTrackService:serviceName metric:metric category:category extra:extraValue storeType:HMDTTmonitorStoreActionNormal];
}

- (void)hmdTrackService:(NSString *)serviceName metric:(NSDictionary <NSString *, NSNumber *> *)metric category:(NSDictionary *)category extra:(NSDictionary *)extraValue syncWrite:(BOOL)syncWrite {
    HMDTTMonitorStoreActionType type = syncWrite ? HMDTTmonitorStoreActionStoreImmediately : HMDTTmonitorStoreActionNormal;
    [self hmdTrackService:serviceName metric:metric category:category extra:extraValue storeType:type];
}

- (void)hmdUploadImmediatelyTrackService:(NSString *)serviceName metric:(NSDictionary <NSString *, NSNumber *> *)metric category:(NSDictionary *)category extra:(NSDictionary *)extraValue {
    [self hmdTrackService:serviceName metric:metric category:category extra:extraValue storeType:HMDTTmonitorStoreActionUploadImmediately];
}

- (void)hmdUploadImmediatelyIfNeedTrackService:(NSString *)serviceName metric:(NSDictionary<NSString *,NSNumber *> *)metric category:(NSDictionary *)category extra:(NSDictionary *)extraValue {
    [self hmdTrackService:serviceName metric:metric category:category extra:extraValue storeType:HMDTTmonitorStoreActionUploadImmediatelyIfNeed];
}

#if RANGERSAPM
static NSString * const _Nonnull TTMonitorMetricKey = @"metrics";
static NSString * const _Nonnull TTMonitorCategoryKey = @"dimension";
static NSString * const _Nonnull TTMonitorExtraKey = @"extraValue";
#else
static NSString * const _Nonnull TTMonitorMetricKey = @"metric";
static NSString * const _Nonnull TTMonitorCategoryKey = @"category";
static NSString * const _Nonnull TTMonitorExtraKey = @"extra";
#endif

- (void)hmdTrackService:(NSString *)serviceName metric:(NSDictionary <NSString *, NSNumber *> *)metric category:(NSDictionary *)category extra:(NSDictionary *)extraValue storeType:(HMDTTMonitorStoreActionType)type {
    // As we import mutable content detector, the detector may find that the data has no mutable content and will skip it.
    // so we need copy nsdictionary here
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    if (metric && [metric isKindOfClass:[NSDictionary class]]) {
        [data setValue:metric.copy forKey:TTMonitorMetricKey];
    }
    if (category && [category isKindOfClass:[NSDictionary class]]) {
        [data setValue:category.copy forKey:TTMonitorCategoryKey];
    }
    if (extraValue && [extraValue isKindOfClass:[NSDictionary class]]) {
        [data setValue:extraValue.copy forKey:TTMonitorExtraKey];
    }

    BOOL needAbandoned = NO;
    [self modifyByUserBlockWithLogType:kHMDTTMonitorServiceLogTypeStr serviceName:serviceName data:&data needAbandoned:&needAbandoned];
    if (needAbandoned) {
        HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitor: service(%@) is abandoned by host compliance block.", serviceName);
        return;
    }
    
    HMDTTMonitorInterceptorParam *param = [[HMDTTMonitorInterceptorParam alloc] init];
    param.isNewInterface = YES;
    param.serviceName = serviceName;
    param.wrapData = [data copy];
    param.storeType = type;
    param.logType = kHMDTTMonitorServiceLogTypeStr;
    param.appID = self.appID;
    [self.interceptorChain handleRequest:param];
}


#pragma mark -- Service-based monitoring

- (void)hmdTrackService:(NSString *)serviceName value:(id)value extra:(NSDictionary *)extraValue {
    if([extraValue isKindOfClass:NSMutableDictionary.class]) extraValue = [extraValue copy];
    if(value != nil && ([value isKindOfClass:NSMutableArray.class] || [value isKindOfClass:NSMutableDictionary.class] || [value isKindOfClass:NSMutableData.class]))
        value = [value copy];
    BOOL extraValidJSON = [NSJSONSerialization isValidJSONObject:extraValue];
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    if ([value isKindOfClass:[NSDictionary class]]) { //如果是字典
        NSDictionary * valueDict = (NSDictionary *)value;
        if ([valueDict valueForKey:@"status"]) {
            [data setValue:[valueDict valueForKey:@"status"] forKey:@"status"];
        }else{
            [data setValue:@(0) forKey:@"status"];
        }
        [data setValue:value forKey:@"value"];
    }else {////如果不是字典
        [data setValue:@(0) forKey:@"status"];
        [data setValue:value forKey:@"value"];
    }
    //extra中的字段都放到最外层
    if ([extraValue isKindOfClass:[NSDictionary class]] && extraValue.count > 0 && extraValidJSON) {
        [data addEntriesFromDictionary:extraValue];
    }
    
    BOOL needAbandoned = NO;
    [self modifyByUserBlockWithLogType:kHMDTTMonitorServiceLogTypeStr serviceName:serviceName data:&data needAbandoned:&needAbandoned];
    if (needAbandoned) {
        HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitor: service(%@) is abandoned by host compliance block.", serviceName);
        return;
    }
    
    HMDTTMonitorInterceptorParam *param = [[HMDTTMonitorInterceptorParam alloc] init];
    param.isNewInterface = NO;
    param.serviceName = serviceName;
    param.storeType = HMDTTmonitorStoreActionNormal;
    param.logType = kHMDTTMonitorServiceLogTypeStr;
    param.wrapData = [data copy];
    param.appID = self.appID;
    [self.interceptorChain handleRequest:param];
}

//这个方法先不改，因为已经迁移了很久，改数据结构可能影响线上数据消费
- (void)hmdTrackService:(NSString *)serviceName status:(NSInteger)status extra:(NSDictionary *)extraValue {
    if([extraValue isKindOfClass:NSMutableDictionary.class]) extraValue = [extraValue copy];
    // 如果放到另一个线程中去做判断, 当 extraValue 的内容发生改变的时候 容易 crash; 如: extravalue 里面包含一个可变字典, 当可变字典在另外一个线程 remove 的时候, 有一定概率发生 crash
    BOOL isValidJSON = [NSJSONSerialization isValidJSONObject:extraValue];
    NSMutableDictionary * data = [[NSMutableDictionary alloc] init];
    [data setValue:@(status) forKey:@"status_monitor"];
    if (extraValue && isValidJSON) {
        NSMutableDictionary * valueDict = [[NSMutableDictionary alloc] init];
        if ([extraValue isKindOfClass:[NSDictionary class]]) {
            [valueDict addEntriesFromDictionary:extraValue];
        }
        [valueDict setValue:@(status) forKey:@"status"];
        [data setValue:[valueDict copy] forKey:@"value"];
    } else {
        [data setValue:@(status) forKey:@"status"];
    }
    
    BOOL needAbandoned = NO;
    [self modifyByUserBlockWithLogType:kHMDTTMonitorServiceLogTypeStr serviceName:serviceName data:&data needAbandoned:&needAbandoned];
    if (needAbandoned) {
        HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitor: service(%@) is abandoned by host compliance block.", serviceName);
        return;
    }
    
    HMDTTMonitorInterceptorParam *param = [[HMDTTMonitorInterceptorParam alloc] init];
    param.isNewInterface = NO;
    param.serviceName = serviceName;
    param.storeType = HMDTTmonitorStoreActionNormal;
    param.logType = kHMDTTMonitorServiceLogTypeStr;
    param.wrapData = [data copy];
    param.appID = self.appID;
    [self.interceptorChain handleRequest:param];
}

- (void)hmdTrackService:(NSString *)serviceName
             attributes:(NSDictionary *)attributes {
    if([attributes isKindOfClass:NSMutableDictionary.class]) attributes = [attributes copy];
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    if ([attributes isKindOfClass:[NSDictionary class]]) {
        [data setValue:attributes forKey:@"value"];
        if (![attributes valueForKey:@"status"]) {
            [data setValue:@(0) forKey:@"status"];
        }
    }
    
    BOOL needAbandoned = NO;
    [self modifyByUserBlockWithLogType:kHMDTTMonitorServiceLogTypeStr serviceName:serviceName data:&data needAbandoned:&needAbandoned];
    if (needAbandoned) {
        HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitor: service(%@) is abandoned by host compliance block.", serviceName);
        return;
    }
    
    HMDTTMonitorInterceptorParam *param = [[HMDTTMonitorInterceptorParam alloc] init];
    param.isNewInterface = NO;
    param.serviceName = serviceName;
    param.storeType = HMDTTmonitorStoreActionNormal;
    param.logType = kHMDTTMonitorServiceLogTypeStr;
    param.wrapData = [data copy];
    param.appID = self.appID;
    [self.interceptorChain handleRequest:param];
}

#pragma mark -- modify by user
+ (void)setLogModifyBlock:(HMDTTMonitorLodModifyBlock)block {
    pthread_rwlock_wrlock(&log_modify_block_lock);
    globalLogModifyBlock = block;
    pthread_rwlock_unlock(&log_modify_block_lock);
    
    HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitor: Set HMDTTMonitor Log Modify Block.");
}

- (void)modifyByUserBlockWithLogType:(NSString *)logType serviceName:(NSString *)serviceName data:(NSDictionary **)data needAbandoned:(BOOL *)needAbandoned {
    pthread_rwlock_rdlock(&log_modify_block_lock);
    if (globalLogModifyBlock) {
        globalLogModifyBlock(kHMDTTMonitorServiceLogTypeStr, serviceName, data, needAbandoned);
        pthread_rwlock_unlock(&log_modify_block_lock);
    }
    pthread_rwlock_unlock(&log_modify_block_lock);
}

#pragma mark -- sampling rate

- (BOOL)needUploadWithlogTypeStr:(NSString *)logTypeStr serviceName:(NSString *)serviceName {
    if (!logTypeStr || !logTypeStr.length) {
        logTypeStr = kHMDTTMonitorServiceLogTypeStr;
    }
    return [self.tracker needUploadWithlogTypeStr:logTypeStr serviceType:serviceName];
}

- (BOOL)logTypeEnabled:(NSString *)logType {
    if (!logType || !logType.length) return NO;
    return [self.tracker logTypeEnabled:logType];
}

- (BOOL)serviceTypeEnabled:(NSString *)serviceType {
    if (!serviceType || !serviceType.length) return NO;
    return [self.tracker serviceTypeEnabled:serviceType];
}

- (BOOL)configurationAvailable {
    return [self.tracker ttmonitorConfigurationAvailable];
}

- (void)configTTLiveEventIgnoreLogType:(BOOL)ignore {
    self.tracker.ignoreLogType = ignore;
}

#pragma mark -- custom ttmonitor

- (void)hmdTrackData:(NSDictionary *)data
          logTypeStr:(NSString *)logType {
    [self hmdTrackData:data logTypeStr:logType storeType:HMDTTmonitorStoreActionNormal];
}

- (void)hmdUploadImmediatelyIfNeedTrackData:(NSDictionary *)data
                                 logTypeStr:(NSString *)logType {
    [self hmdTrackData:data logTypeStr:logType storeType:HMDTTmonitorStoreActionUploadImmediatelyIfNeed];
}

- (void)hmdUploadImmediatelyTrackData:(NSDictionary *)data
                           logTypeStr:(NSString *)logType {
    [self hmdTrackData:data logTypeStr:logType storeType:HMDTTmonitorStoreActionUploadImmediately];
}

- (void)hmdTrackData:(NSDictionary *)data
          logTypeStr:(NSString *)logType storeType:(HMDTTMonitorStoreActionType)type {
    if([data isKindOfClass:NSMutableDictionary.class]) data = [data copy];
    
    BOOL needAbandoned = NO;
    [self modifyByUserBlockWithLogType:logType serviceName:nil data:&data needAbandoned:&needAbandoned];
    if (needAbandoned) {
        HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitor: logtype(%@) is abandoned by host compliance block.", logType);
        return;
    }
    
    HMDTTMonitorInterceptorParam *param = [[HMDTTMonitorInterceptorParam alloc] init];
    param.isNewInterface = YES;
    param.serviceName = nil;
    param.logType = logType;
    param.wrapData = data;
    param.storeType = type;
    param.appID = self.appID;
    [self.interceptorChain handleRequest:param];
}


#pragma mark -- monitoring mode ii

- (void)hmdTrackData:(NSDictionary *)data
                type:(HMDTTMonitorTrackerType)type
{
    BOOL dataValid = [data isKindOfClass:[NSDictionary class]] && [data count] > 0;
    if (!dataValid) {
        return;
    }
    
    if([data isKindOfClass:NSMutableDictionary.class]) data = [data copy];
    NSString *logTypeStr = [HMDTTMonitorHelper logTypeStrForType:type];
    
    BOOL needAbandoned = NO;
    [self modifyByUserBlockWithLogType:logTypeStr serviceName:nil data:&data needAbandoned:&needAbandoned];
    if (needAbandoned) {
        HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitor: HMDTTMonitorTrackerType(%ld) is abandoned by host compliance block.", (long)type);
        return;
    }
    
    HMDTTMonitorInterceptorParam *param = [[HMDTTMonitorInterceptorParam alloc] init];
    param.isNewInterface = NO;
    param.serviceName = nil;
    param.logType = logTypeStr;
    param.trackType = type;
    param.wrapData = data;
    param.appID = self.appID;
    [self.interceptorChain handleRequest:param];
}


#pragma mark -- monitoring mode i
- (void)event:(NSString *)type label:(NSString *)label count:(NSUInteger)count needAggregate:(BOOL)needAggr
{
    hmd_safe_dispatch_async(self.serialQueue, ^{
        if ([self isKindOfClass:[HMDTTMonitor class]]) {
            [self.tracker countEvent:type label:label value:count needAggregate:needAggr appID:self.appID];
        } else {
            [[HMDTTMonitor defaultManager].tracker countEvent:type label:label value:count needAggregate:needAggr appID:[HMDInjectedInfo defaultInfo].appID];
        }
    });
}

- (void)event:(NSString *)type label:(NSString *)label needAggregate:(BOOL)needAggr
{
    [self event:type label:label count:1 needAggregate:needAggr];
}

- (void)event:(NSString *)type label:(NSString *)label duration:(float)duration needAggregate:(BOOL)needAggr
{
    hmd_safe_dispatch_async(self.serialQueue, ^{
        if ([self isKindOfClass:[HMDTTMonitor class]]) {
            [self.tracker timerEvent:type label:label value:duration needAggregate:needAggr appID:self.appID];
        } else {
            [[HMDTTMonitor defaultManager].tracker timerEvent:type label:label value:duration needAggregate:needAggr appID:[HMDInjectedInfo defaultInfo].appID];
        }
    });
}

@end
