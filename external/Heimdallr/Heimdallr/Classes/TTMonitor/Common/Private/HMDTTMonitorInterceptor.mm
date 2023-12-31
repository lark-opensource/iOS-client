//
//  HMDTTMonitorInterceptor.m
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 29/4/2022.
//

#import "HMDTTMonitorInterceptor.h"
#import "NSDictionary+HMDImmutableCopy.h"
#import "HMDALogProtocol.h"
#import "HMDTTMonitor+FrequenceDetect.h"
#import "HMDConfigManager.h"
#import "HMDCustomEventSetting.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDTTMonitorTracker.h"
#import "HMDReportDowngrador.h"
#import "HMDServerStateService.h"
#import "HMDTTMonitorInterceptorParam.h"
#import "HMDInjectedInfo+PerfOptSwitch.h"
#import "HMDServerStateService.h"
#import "HMDHermasHelper.h"
#import "HMDDynamicCall.h"
#import "HMDMacro.h"
#import "HMDGCD.h"
#include <vector>
#include <string>
#include <map>
#include <math.h>
#import <pthread/pthread.h>

CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

static double average(const std::vector<double>& vec) {
    if (vec.size() == 0) return 0.f;
    double sum = 0;
    for (int i = 0; i < vec.size(); i++)
        sum += vec[i];
    return sum / vec.size();
}

static double coefficientVariation(const std::vector<double>& vec) {
    double sum = 0;
    double avg = average(vec);
    for (int i = 0; i < vec.size(); i++)
        sum += (vec[i] - avg) * (vec[i] - avg);
    double temp = sum / (vec.size() - 1);
    return sqrt(temp) / avg;
}

static double sortAndComputeCoefficientVariation(const std::vector<double>& vec) {
    if (vec.size() == 0) return 0.f;
    std::vector<double> temp{vec};
    std::sort(temp.begin(),temp.end());
    double first = temp[0];
    for (int i = 0; i < temp.size(); ++i) temp[i] -= first;
    return coefficientVariation(temp);
}

// export the tracker to interceptor
@interface HMDTTMonitor()
@property (nonatomic, strong) HMDTTMonitorTracker *tracker;
@end


@interface HMDTTMonitorImmutableCopyInterceptor ()
@property (nonatomic, strong) id<HMDTTMonitorInterceptor> nextInterceptor;
@end

@implementation HMDTTMonitorImmutableCopyInterceptor

- (void)handleRequest:(HMDTTMonitorInterceptorParam *)request {
    BOOL hasMutableContent = [request.wrapData hmd_hasMutableContainer];
//    NSAssert(hasMutableContent == NO, @"HMDTTMonitor detector find that the data has mutable content, servicename = %@, data content = %@", request.serviceName, request.wrapData);
    if (hasMutableContent) {
        request.wrapData = [request.wrapData hmd_immutableCopy];
    }
    
    if (self.nextInterceptor) {
        [self.nextInterceptor handleRequest:request];
    }
}

- (void)setNextInterceptor:(id<HMDTTMonitorInterceptor>)interceptor {
    _nextInterceptor = interceptor;
}

@end

@interface HMDTTMonitorSampleInterceptor ()
@property (nonatomic, weak) dispatch_queue_t serialQueue;
@property (nonatomic, weak) HMDTTMonitorTracker *tracker;
@property (nonatomic, strong) id<HMDTTMonitorInterceptor> nextInterceptor;

@end

@implementation HMDTTMonitorSampleInterceptor

- (instancetype)initWithQueue:(dispatch_queue_t)queue tracker:(HMDTTMonitorTracker *)tracker {
    if (self = [super init]) {
        self.serialQueue = queue;
        self.tracker = tracker;
    }
    return self;
}

- (void)handleRequest:(HMDTTMonitorInterceptorParam *)request {
    dispatch_async(self.serialQueue, ^{
        
        if (![HMDInjectedInfo defaultInfo].ttMonitorSampleOptEnable) {
            if (self.nextInterceptor) {
                [self.nextInterceptor handleRequest:request];
            }
            return;
        }
        
        BOOL isHighPriority = [self.tracker isHighPriorityWithLogType:request.logType serviceType:request.serviceName];
        if (isHighPriority) {
            request.storeType = HMDTTmonitorHighPriotityIgnoreSampling;
        }
        
        // quota
        BOOL isDropData = false;
        if (hermas_enabled() && !isHighPriority) {
            isDropData = hermas_drop_data_sdk(kModulePerformaceName, request.appID);
        } else if (hermas_enabled() && isHighPriority) {
            isDropData = hermas_drop_data_sdk(kModuleHighPriorityName, request.appID);
        } else {
            isDropData = hmd_drop_data_sdk(HMDReporterPerformance, request.appID);
        }
        if (isDropData) {
            HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker eventData write to alog after dropdata : serviceName = %@, logType = %@, data = %@", request.serviceName, request.logType, request.wrapData);
            return;
        }
        
        // down grade by channel
        BOOL isDownGrade = [[HMDReportDowngrador sharedInstance] needUploadWithLogType:request.logType serviceName:request.serviceName aid:request.appID];
        if (!isDownGrade) {
            HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker eventData write to alog after downgrade : serviceName = %@, logType = %@, data = %@", request.serviceName, request.logType, request.wrapData);
            
            return;
        }
        
        // sample and movingline
        NSDictionary *extra = [NSDictionary dictionary];
        NSString *traceParent;
        BOOL isTraceParentHit = NO;
        BOOL isMovingLine = NO;
        if (request.wrapData) {
            extra = [request.wrapData hmd_dictForKey:@"extra"];
        }
        if (extra && extra.count > 0) {
            traceParent = [extra hmd_stringForKey:@"traceparent"];
        }
        if (traceParent && traceParent.length == 55) {
            isMovingLine = YES;
            NSString *flag = [traceParent substringFromIndex:traceParent.length - 2];
            if ([flag isEqualToString:@"01"]) {
                isTraceParentHit = YES;
            }
        }
        
        BOOL needUpload = [self.tracker needUploadWithLogTypeStr:request.logType serviceType:request.serviceName data:request.wrapData];
        needUpload = needUpload || isHighPriority || request.storeType == HMDTTmonitorStoreActionUploadImmediately;
        
        BOOL enableCacheMovingLineUnHitLog = NO;
        enableCacheMovingLineUnHitLog = [DC_OB(DC_CL(HMDOTManagerConfig, defaultConfig), GetEnableCacheUnHitLogStrValue) boolValue];
        enableCacheMovingLineUnHitLog = enableCacheMovingLineUnHitLog && isMovingLine;
        
        NSInteger singlePointOnly = 0;
        BOOL needUpdateSinglePointOnly = isTraceParentHit || (isMovingLine && !isTraceParentHit && enableCacheMovingLineUnHitLog);
        if (!needUpload && needUpdateSinglePointOnly && request.storeType != HMDTTmonitorStoreActionUploadImmediately) {
            singlePointOnly = 1;
        }
        
        request.needUpload = needUpload || isTraceParentHit;
        request.traceParent = traceParent;
        request.singlePointOnly = singlePointOnly;
        
        
        if ([HMDInjectedInfo defaultInfo].stopWriteToDiskWhenUnhit && !request.needUpload && !request.singlePointOnly) {
            return;
        }
        
        if (self.nextInterceptor) {
            [self.nextInterceptor handleRequest:request];
        }
    });
}

- (void)setNextInterceptor:(id<HMDTTMonitorInterceptor>)interceptor {
    _nextInterceptor = interceptor;
}

@end

static pthread_rwlock_t block_list_lock = PTHREAD_RWLOCK_INITIALIZER;

@interface HMDTTMonitorBlacklistInterceptor ()
@property (nonatomic, strong) id<HMDTTMonitorInterceptor> nextInterceptor;
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, weak) dispatch_queue_t serialQueue;
@end

@implementation HMDTTMonitorBlacklistInterceptor

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithQueue:(dispatch_queue_t)queue {
    if (self = [super init]) {
        self.serialQueue = queue;
        dispatch_async(self.serialQueue, ^{
            [self updateBlacklist];
        });
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(configDidUpdate:)
                                                     name:HMDConfigManagerDidUpdateNotification
                                                   object:nil];
    }
    return self;
}

+ (NSMutableDictionary *)serviceTypeBlacklist {
    static NSMutableDictionary *dict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dict = @{}.mutableCopy;
    });
    return dict;
}

+ (NSMutableDictionary *)logTypeBlacklist {
    static NSMutableDictionary *dict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dict = @{}.mutableCopy;
    });
    return dict;
}

#pragma mark - HMDTTMonitorInterceptor

- (void)handleRequest:(HMDTTMonitorInterceptorParam *)request {
    // try to check if the data hit the blacklist
    dispatch_async(self.serialQueue, ^{
        BOOL hitBlacklist = NO;
        pthread_rwlock_rdlock(&block_list_lock);
        if ([request.logType isEqualToString:kHMDTTMonitorServiceLogTypeStr]) {
            hitBlacklist = [self.class.serviceTypeBlacklist hmd_boolForKey:request.serviceName];
        } else {
            hitBlacklist = [self.class.logTypeBlacklist hmd_boolForKey:request.logType];
        }
        pthread_rwlock_unlock(&block_list_lock);

        if (hitBlacklist) {
            HMDALOG_PROTOCOL_INFO_TAG(@"HMDTTMonitorFrequenceDetector", @"HMDTTMonitor detect that the data hit the balcklist, logtype = %@, servicename = %@", request.logType, request.serviceName);
            return;
        }
        if (self.nextInterceptor) {
            [self.nextInterceptor handleRequest:request];
        }
    });
}

- (void)setNextInterceptor:(id<HMDTTMonitorInterceptor>)interceptor {
    _nextInterceptor = interceptor;
}

#pragma mark - Notification

- (void)configDidUpdate:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[NSDictionary class]]) {
        NSArray *appIDs = notification.object[HMDConfigManagerDidUpdateAppIDKey];
        HMDConfigManager *updatedConfigManager = notification.object[HMDConfigManagerDidUpdateConfigKey];
        // 所有的黑名单都需要配置在宿主侧，且宿主配置的黑名单对宿主和SDK都生效
        if (appIDs.count && [appIDs containsObject:[HMDInjectedInfo defaultInfo].appID] && updatedConfigManager == [HMDConfigManager sharedInstance]) {
            [self updateBlacklist];
        }
    }
}

- (void)updateBlacklist {
    // 更新宿主配置的黑名单列表
    HMDHeimdallrConfig *config = [[HMDConfigManager sharedInstance] remoteConfigWithAppID:[HMDInjectedInfo defaultInfo].appID];
    pthread_rwlock_wrlock(&block_list_lock);
    [self.class.serviceTypeBlacklist removeAllObjects];
    [self.class.logTypeBlacklist removeAllObjects];
    [config.customEventSetting.serviceTypeBlacklist enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.class.serviceTypeBlacklist setValue:@(YES) forKey:obj];
    }];
    [config.customEventSetting.logTypeBlacklist enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.class.logTypeBlacklist setValue:@(YES) forKey:obj];
    }];
    pthread_rwlock_unlock(&block_list_lock);
}

@end

@interface HMDTTMonitorFrequenceDetectInterceptor() {
    std::map<std::string, std::vector<double>> statistic;
    std::map<std::string, double> timestamps;
    double stanardCoeff;
    NSTimeInterval lastCleanupTime;
    
}
@property (nonatomic, strong) id<HMDTTMonitorInterceptor> nextInterceptor;
@property (nonatomic, strong) HMDFrequenceDetectParam *detectParam;
@end


@implementation HMDTTMonitorFrequenceDetectInterceptor

+ (dispatch_queue_t)globalQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.heimdallr.hmdttmonitor.frequence.detector", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    if (self = [super init]) {
        [self setupParams];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frequenceDetectParamDidChange:) name:kHMDFrequenceDetectParamDidChangeNotification object:nil];
    }
    return self;
}

- (void)setupParams {
    lastCleanupTime = CFAbsoluteTimeGetCurrent();
    self.detectParam = [HMDTTMonitor getFrequenceDetectParam];
    std::vector<double> temp;
    for (int i = 0; i < _detectParam.maxCount; ++i) temp.push_back(i);
    stanardCoeff = sortAndComputeCoefficientVariation(temp);
}

- (void)frequenceDetectParamDidChange:(NSNotification *)noti {
    __weak __typeof(self) wself = self;
    dispatch_async(self.class.globalQueue, ^{
        // 如果在运行中，参数发生了改变，直接重置所有参数
        __strong __typeof(wself) sself = wself;
        sself->statistic.clear();
        sself->timestamps.clear();
        [sself setupParams];
    });
}

#pragma mark - HMDTTMonitorInterceptor

- (void)handleRequest:(HMDTTMonitorInterceptorParam *)request {
    __weak __typeof(self) wself = self;
    dispatch_async(self.class.globalQueue, ^{
        __strong __typeof(wself) sself = wself;
        
        // 如果没有开启频繁检测功能，直接跳到nextInterceptor
        if (![sself shouldHandleRequest:request]) {
            if (sself.nextInterceptor) {
                [sself.nextInterceptor handleRequest:request];
            }
            return;
        }
        
        std::string key = request.serviceName.UTF8String;
        
        if (sself->statistic.find(key) == sself->statistic.end()){
            sself->statistic[key] = std::vector<double>{};
        }
        
        // remove expired data first
        std::vector<double>& times = sself->statistic[key];
        auto iter = times.begin();
        NSTimeInterval currentTime = CFAbsoluteTimeGetCurrent();
        while (iter != times.end()) {
            double delta = currentTime - *iter;
            if (delta > sself.detectParam.duration) {
                iter = times.erase(iter);
            } else {
                break;
            }
        }
        
        // add current time
        times.push_back(currentTime);
        
        if (times.size() >= sself.detectParam.maxCount * 0.5 && times.size() < sself.detectParam.maxCount) {
            // if the count is between 0.5 * maxCount ~ maxCount, compute variance
            double coeff = sortAndComputeCoefficientVariation(times);
            if (coeff < sself->stanardCoeff) {
                // we thought the servicename is too frequent so that we should report it.
                request.accumulateCount = times.size();
                [sself reportDetectedResultIfNeeded:request];
            }
        } else if (times.size() >= sself.detectParam.maxCount) {
            // if the count is more than maxCount, report it
            request.accumulateCount = times.size();
            [sself reportDetectedResultIfNeeded:request];
        }
        
        // execute cleanup logic every 10s
        if (currentTime - sself->lastCleanupTime > 10) {
            [sself cleanStatisticData];
            sself->lastCleanupTime = currentTime;
        }

        // pass to the next interceptor
        if (sself.nextInterceptor) {
            [sself.nextInterceptor handleRequest:request];
        }
    });
}

- (void)setNextInterceptor:(id<HMDTTMonitorInterceptor>)interceptor {
    _nextInterceptor = interceptor;
}

#pragma mark - Private Method

- (BOOL)shouldHandleRequest:(HMDTTMonitorInterceptorParam *)request {
    if (!self.detectParam.enabled) return NO;
    if (!request.serviceName || request.serviceName.length == 0) return NO;
    return YES;
}

- (void)cleanStatisticData {
    auto it = statistic.begin();
    NSTimeInterval currentTime = CFAbsoluteTimeGetCurrent();
    while (it != statistic.end()) {
        std::vector<double>& times = it->second;
        auto iter = times.begin();
        while (iter != times.end()) {
            double delta = currentTime - *iter;
            if (delta > 1.f) {
                iter = times.erase(iter);
            } else {
                ++iter;
            }
        }
        if (times.size() == 0) {
            it = statistic.erase(it);
        } else {
            ++it;
        }
    }
}

- (void)reportDetectedResultIfNeeded:(HMDTTMonitorInterceptorParam *)request {
    // we thought the servicename is too frequent so that we need report it.
    std::string key = request.serviceName.UTF8String;
    NSTimeInterval currentTime = CFAbsoluteTimeGetCurrent();
    if (self->timestamps.find(key) != self->timestamps.end()) {
        double timestamp = self->timestamps[key];
        if (currentTime - timestamp > self.detectParam.reportInterval) {
            [self reportDetectedResult:request];
        }
    } else {
        [self reportDetectedResult:request];
    }
    self->timestamps[key] = currentTime;
}


- (void)reportDetectedResult:(HMDTTMonitorInterceptorParam *)request {
    // alog the event online
    HMDALOG_PROTOCOL_INFO_TAG(@"HMDTTMonitorFrequenceDetector", @"HMDTTMonitor detect that the trace is too frequent, servicename = %@, accumule count = %lu", request.serviceName, request.accumulateCount);
    
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    NSDictionary *category = @{
        @"origin_service_name" : request.serviceName ?: @"",
        @"origin_log_type" : request.logType ?: @"",
        @"origin_appid" : request.appID ?: @""
    };
    NSDictionary *extra = @{ @"accumute_count" : @(request.accumulateCount)};
    [data setValue:category forKey:@"category"];
    [data setValue:extra forKey:@"extra"];

    // 频繁埋点的报警数据采用立即上传策略
    // 无论是App本身的埋点，还是SDK的埋点，只要检测到频繁埋点，都统一上报到App，由App统一消费
    HMDTTMonitorInterceptorParam *param = [[HMDTTMonitorInterceptorParam alloc] init];
    param.wrapData = [data copy];
    param.logType = kHMDTTMonitorServiceLogTypeStr;
    param.serviceName = @"frequent_service";
    param.appID = [HMDInjectedInfo defaultInfo].appID;
    param.storeType = HMDTTmonitorStoreActionUploadImmediately;
    [[HMDTTMonitor defaultManager].tracker trackDataWithParam:param];
}

@end

@interface HMDTTMonitorTrackerInterceptor ()
@property (nonatomic, weak) HMDTTMonitorTracker *tracker;
@property (nonatomic, weak) dispatch_queue_t serialQueue;
@property (nonatomic, strong) id<HMDTTMonitorInterceptor> nextInterceptor;
@end

@implementation HMDTTMonitorTrackerInterceptor

- (instancetype)initWithTracker:(HMDTTMonitorTracker *)tracker queue:(dispatch_queue_t)queue {
    if (self = [super init]) {
        self.tracker = tracker;
        self.serialQueue = queue;
    }
    return self;
}

#pragma mark - HMDTTMonitorInterceptor

- (void)handleRequest:(HMDTTMonitorInterceptorParam *)param {
    hmd_safe_dispatch_async(self.serialQueue, ^{
        [self.tracker trackDataWithParam:param];
    });
}

- (void)setNextInterceptor:(id<HMDTTMonitorInterceptor>)interceptor {
    _nextInterceptor = interceptor;
}

@end
