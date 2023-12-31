//
//  HMDNetWorkMonitor.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import "HMDNetTrafficMonitor.h"
#import "HMDMonitorRecord+DBStore.h"
#import "HMDPerformanceReporter.h"
#import "HMDMonitor+Private.h"
#import "HMDNetTrafficMonitorRecord+Report.h"
#import "HMDNetTrafficMonitor+NetworkCollect.h"
#import "NSObject+HMDAttributes.h"
#import "HMDDynamicCall.h"
#import "hmd_section_data_utility.h"
#import "HMDNetworkTraffic.h"
#import "HMDDynamicCall.h"
#import "HMDNetTrafficUsageStatistics.h"
#import "HMDNetTrafficUsageModel+Report.h"
#import "HMDNetTrafficMonitor+Privated.h"
#import "HMDMonitor+Report.h"
#import "Heimdallr+Private.h"
#import "HMDMacro.h"
#import "HMDNetworkHelper.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDNetTrafficMonitor+TrafficConsume.h"
#import "NSArray+HMDSafe.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDUserDefaults.h"
#import "HMDGCD.h"
#import "HMDStoreMemoryDB.h"


#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

NSString *const kHMDModuleNetworkTrafficMonitor = @"network_traffic";

NSString *const kHMDTrafficMonitorCallbackTypeIntervalDeviceUsage = @"interval_usage";
NSString *const kHMDTrafficMonitorCallBackTypeIntervalAppUsage = @"interval_app_usage";

NSString *const kHMDTrafficMonitorCallbackInfoKeyTotal = @"total";
NSString *const kHMDTrafficMonitorCallbackInfoKeyWiFiFront = @"wifi_front";
NSString *const kHMDTrafficMonitorCallbackInfoKeyCellularFront =  @"mobile_front";
NSString *const kHMDTrafficMonitorCallbackInfoKeyWiFiBack = @"wifi_back";
NSString *const kHMDTrafficMonitorCallbackInfoKeyCellularBack = @"mobile_back";

static hmd_IOBytes hmdAppStartTraffic;
static HMDNetTrafficApplicationStateType hmdTrafficAppState;

static NSString *const kHMDTrafficLastProcStoreKey = @"kHMDNetTrafficLastProcessTrafficInfo";
static NSString *const kHMDTrafficLastProcStoreUsageKey = @"kHMDNetTrafficLastProcessUsageKey";
static NSString *const kHMDTrafficLastProcStoreInitTSKey = @"kHMDNetTrafficLastProcessInitTSKey";
static NSString *const kHMDTrafficLastProcStoreEndTSKey = @"kHMDNetTrafficLastProcessEndTSKey";

HMD_MODULE_CONFIG(HMDNetTrafficMonitorConfig)

@implementation HMDNetTrafficMonitorConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(refreshInterval, refresh_interval, @(0), @(0))
        HMD_ATTR_MAP_DEFAULT(enableIntervalTraffic, enable_interval_traffic, @(YES), @(YES))
        HMD_ATTR_MAP_DEFAULT(enableBizTrafficCollect, enable_biz_traffic_collect, @(YES), @(YES))
        HMD_ATTR_MAP_DEFAULT(enableExceptionDetailUpload, enable_exception_detail_upload, @(YES), @(YES))
        HMD_ATTR_MAP_DEFAULT(intervalTrafficThreshold, interval_traffic_threshold, @(100 * HMD_MB), @(100 * HMD_MB))
        HMD_ATTR_MAP_DEFAULT(backgroundTrafficThreshold, background_traffic_threshold, @(50 * HMD_MB), @(50 * HMD_MB))
        HMD_ATTR_MAP_DEFAULT(neverFrontTrafficThreshold, never_front_traffic_threshold, @(50 * HMD_MB), @(50 * HMD_MB))
        HMD_ATTR_MAP_DEFAULT(highFreqRequestThreshold, hight_freq_request_threshold, @(100), @(100))
        HMD_ATTR_MAP_DEFAULT(largeRequestThreshold, large_request_threshold, @(10 * HMD_MB), @(10 * HMD_MB))
        HMD_ATTR_MAP_DEFAULT(largeImageThreshold, large_image_threshold, @(10 * HMD_MB), @(10 * HMD_MB))
        HMD_ATTR_MAP_DEFAULT(disableNetworkTraffic, disable_network_traffic, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(disableTTPushTraffic, disable_ttpush_traffic, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(customTrafficSpanSample, custom_traffic_span_sample, @{}, @{})
    };
}

+ (NSString *)configKey {
    return kHMDModuleNetworkTrafficMonitor;
}

- (id<HeimdallrModule>)getModule {
    return [HMDNetTrafficMonitor sharedMonitor];
}

@end

@interface HMDNetTrafficMonitor ()

@property (nonatomic, assign, readwrite) hmd_IOBytes pageIOBytes;
@property (nonatomic, strong, readwrite) HMDNetTrafficUsageStatistics *statisticsTool;
@property (nonatomic, strong, readwrite) dispatch_source_t intervalTrafficTimer;
@property (nonatomic, strong, readwrite) dispatch_queue_t trafficCollectQueue;
@property (nonatomic, strong, readwrite) NSMutableDictionary *customSpanInfoDict;
@property (nonatomic, assign, readwrite) BOOL everFront;
@property (nonatomic, strong, readwrite) NSMutableArray *callbacks;
@property (nonatomic, assign) BOOL enableProcTraffic;
@property (nonatomic, assign) long long procStartTrafficTS;

@property (nonatomic, assign) BOOL enableIntervalTraffic;
@property (nonatomic, assign) BOOL enableNetworkTraffic;
@property (nonatomic, assign) BOOL enablePushTraffic;

@end
@implementation HMDNetTrafficMonitor

SHAREDMONITOR(HMDNetTrafficMonitor)

+ (void)initialize {
    if (self == [HMDNetTrafficMonitor class]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            hmdTrafficAppState = [UIApplication sharedApplication].applicationState == UIApplicationStateBackground ? HMDNetTrafficApplicationStateNeverFront : HMDNetTrafficApplicationStateForeground;
        });
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.customReportIMP = @(YES);
        self.trafficCollectQueue = dispatch_queue_create("com.heimdallr.traffic.detail.collect", DISPATCH_QUEUE_SERIAL);
        self.callbacks = [NSMutableArray array];
        self.statisticsTool = [[HMDNetTrafficUsageStatistics alloc] initWithOperationQueue:self.trafficCollectQueue];
        self.customSpanInfoDict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc {
    [self stop];
}

- (Class<HMDRecordStoreObject>)storeClass {
    return [HMDNetTrafficMonitorRecord class];
}

- (void)start {
    [super start];
    [self setupSubModuleWhenStart];
    [self recordProcessTraffic];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processWillExist) name:UIApplicationWillTerminateNotification object:nil];
}

- (void)stop {
    [super stop];
    [self stopTimeForIntervalTrafficUsageIfNeed];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

- (void)recordForSpecificScene:(NSString *)scene {

}

- (void)willEnterForeground:(NSNotification *)notification {
    BOOL stateChange = (hmdTrafficAppState == HMDNetTrafficApplicationStateBackground) ||
                       (hmdTrafficAppState == HMDNetTrafficApplicationStateNeverFront);
    hmdTrafficAppState = HMDNetTrafficApplicationStateForeground;
    [self notificateConsumeEnterForground:stateChange];
}

- (void)didEnterBackground:(NSNotification *)notification {
    BOOL stateChange = (hmdTrafficAppState == HMDNetTrafficApplicationStateForeground);
    hmdTrafficAppState = HMDNetTrafficApplicationStateBackground;
    [self notificateConsumeEnterBackground:stateChange];
}

#pragma mark --- info callback
- (void)addTrafficUsageInfoCallback:(HMDTrafficMonitorCallback _Nonnull )callback {
    if (!callback) { return; }
    __weak typeof(self) weakSelf = self;
    hmd_safe_dispatch_async(self.trafficCollectQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.callbacks hmd_addObject:callback];
    });
}

- (void)removeTrafficUsageInfoCallback:(HMDTrafficMonitorCallback _Nonnull )callback {
    if (!callback) { return; }
    __weak typeof(self) weakSelf = self;
    hmd_safe_dispatch_async(self.trafficCollectQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.callbacks removeObject:callback];
    });
}

- (void)executePublicCallBackWithMonitorType:(NSString *)monitorType usage:(NSDictionary *)usage biz:(NSDictionary *)biz {
    __weak typeof(self) weakSelf = self;
    hmd_safe_dispatch_async(self.trafficCollectQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        for (HMDTrafficMonitorCallback callback in strongSelf.callbacks) {
            callback(monitorType, usage, biz);
        }
    });
}

- (void)setupSubModuleWhenStart {
    if (self.enableIntervalTraffic) {
        [self setupTimerForIntervalTrafficUsage];
    }

    if (self.enableNetworkTraffic) {
        [self switchNetworkCollectStatus:YES];
    }

    if (self.enablePushTraffic) {
        [self switchTTPushCollectStatus:YES];
    }
}

#pragma mark --- process traffic ---
// record app process total traffic usage
- (void)recordProcessTraffic {
    CFTimeInterval appTime = [HMDSessionTracker currentSession].timeInSession;
    if (appTime < 5) {
        self.enableProcTraffic = YES;
        self.procStartTrafficTS = [[NSDate date] timeIntervalSince1970];
        hmdAppStartTraffic = hmd_getFlowIOBytes();
        __weak typeof(self) weakSelf = self;
        atexit_b(^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf processWillExist];
        });
    }

    dispatch_on_monitor_queue(^{
        NSDictionary *lastProcessInfo = [[HMDUserDefaults standardUserDefaults] objectForKey:kHMDTrafficLastProcStoreKey];
        if (lastProcessInfo && [lastProcessInfo isKindOfClass:[NSDictionary class]]) {
            NSNumber *totalUsage = [lastProcessInfo hmd_objectForKey:kHMDTrafficLastProcStoreUsageKey class:[NSNumber class]];
            NSNumber *initTime = [lastProcessInfo hmd_objectForKey:kHMDTrafficLastProcStoreInitTSKey class:[NSNumber class]];
            NSNumber *endTime = [lastProcessInfo hmd_objectForKey:kHMDTrafficLastProcStoreEndTSKey class:[NSNumber class]];
            long long usageTime = 0;
            long long initTimeTS = initTime ? [initTime longLongValue] : 0;
            long long endTimeTS = endTime ? [endTime longLongValue] : 0;
            if (initTimeTS && endTimeTS > initTimeTS) {
                usageTime = endTimeTS - initTimeTS;
            }
            HMDNetTrafficMonitorRecord *record = [HMDNetTrafficMonitorRecord newRecord];
            record.customExtra = @{
                @"init_time": @(initTimeTS),
                @"end_time": @(endTimeTS)
            };

            record.customExtraStatus = @{
                @"usage_time": @(usageTime)
            };

            record.customExtraValue = @{
                @"total_usage": totalUsage?:@(0)
            };
            
            [self processRecordUniformly:record];
            
            [[HMDUserDefaults standardUserDefaults] removeObjectForKey:kHMDTrafficLastProcStoreKey];
        }
    });
}

- (void)processRecordUniformly:(HMDNetTrafficMonitorRecord *)record {
    if (hermas_enabled()) {
        // set enableUpload value in advance for hermas refactor reason
        record.enableUpload = [self enableUploadWithRecord:record];
        
        // add info
        [record addInfo];
        
        // normal data
        [self.curve pushRecord:record];
        
        // exception data
        if (record.isExceptionTraffic && [self.config isKindOfClass:[HMDNetTrafficMonitorConfig class]] && [(HMDNetTrafficMonitorConfig *)self.config enableExceptionDetailUpload]) {
            [self.curve recordDataDirectly:record.exceptionTrafficDictionary];
        }
        
    } else {
        // origal logic
        [self.curve pushRecord:record];
    }
}

- (void)processWillExist {
    if (self.enableProcTraffic) {
        self.enableProcTraffic = NO;
        dispatch_on_monitor_queue(^{
            hmd_IOBytes current = hmd_getFlowIOBytes();
            long long usage = (current.totalSent - hmdAppStartTraffic.totalSent) + (current.totalReceived - hmdAppStartTraffic.totalReceived);
            NSTimeInterval currentTS = [[NSDate date] timeIntervalSince1970];
            NSDictionary *storeTrafficInfo = @{
                kHMDTrafficLastProcStoreUsageKey: @(usage),
                kHMDTrafficLastProcStoreInitTSKey: @(self.procStartTrafficTS),
                kHMDTrafficLastProcStoreEndTSKey: @(currentTS)
            };
            [[HMDUserDefaults standardUserDefaults] setObject:storeTrafficInfo forKey:kHMDTrafficLastProcStoreKey];
        });
    }
}

#pragma mark HeimdallrModule
- (void)updateConfig:(HMDModuleConfig *)config
{
    [super updateConfig:config];
    if ([self.config isKindOfClass:[HMDNetTrafficMonitorConfig class]]) {
        HMDNetTrafficMonitorConfig *trafficConfig = (HMDNetTrafficMonitorConfig *)self.config;
        [self updateSubModuleStateWithConfig:trafficConfig];

        self.enableIntervalTraffic = trafficConfig.enableIntervalTraffic;
        self.enableNetworkTraffic = !trafficConfig.disableNetworkTraffic;
        self.enablePushTraffic = !trafficConfig.disableTTPushTraffic;
        [self.statisticsTool updateTrafficConfig:trafficConfig];
    }
}

// must call the method before self.enableIntervalTraffic ... 's setter
- (void)updateSubModuleStateWithConfig:(HMDNetTrafficMonitorConfig *)config {
    if (self.isRunning) {
        [self switchIntervalTimerWithStatus:config.enableIntervalTraffic];
        [self switchNetworkCollectStatus:!config.disableNetworkTraffic];
        [self switchTTPushCollectStatus:!config.disableTTPushTraffic];
     }
}

#pragma mark - override

- (void)didEnterScene:(NSString *)scene {
    self.pageIOBytes = hmd_getFlowIOBytes();
}

- (void)willLeaveScene:(NSString *)scene {
    [self recordForSpecificScene:scene];
}

- (BOOL)monitorCurve:(HMDMonitorCurve *)monitorCurve willSaveRecords:(NSArray <HMDNetTrafficMonitorRecord *>*)records
{
    if (records.count == 0) {
        return NO;
    }

    [records hmd_enumerateObjectsUsingBlock:^(HMDNetTrafficMonitorRecord * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.enableUpload = [self enableUploadWithRecord:obj];
    } class:HMDMonitorRecord.class];

    BOOL result = [self.heimdallr.database insertObjects:records
                                                          into:[[[records firstObject] class] tableName]];
    if (!result) {
        result = [self.heimdallr.store.memoryDB insertObjects:records into:[[[records firstObject] class] tableName] appID:self.heimdallr.userInfo.appID];
    }

    if (result) {
        [self.heimdallr updateRecordCount:records.count];
    }
    return result;
}

- (BOOL)enableUploadWithRecord:(HMDNetTrafficMonitorRecord *)record {
    __block NSUInteger enableUpload = self.config.enableUpload ? 1 : 0;
    NSDictionary *customSpanSample = nil;
    if ([self.config isKindOfClass:[HMDNetTrafficMonitorConfig class]] &&
        ((HMDNetTrafficMonitorConfig *)self.config).customTrafficSpanSample.count > 0) {
        customSpanSample = ((HMDNetTrafficMonitorConfig *)self.config).customTrafficSpanSample;
    }
    if (enableUpload == 0 && customSpanSample && [record isKindOfClass:[HMDNetTrafficMonitorRecord class]] && record.isCustomSpan) {
        NSString *spanName = record.customExtraValue.allKeys.firstObject;
        if (spanName) {
            BOOL customEnable = [customSpanSample hmd_boolForKey:spanName];
            enableUpload = customEnable ? 1 : 0;
        }
    }
    return enableUpload;
}

#pragma - mark upload

- (NSUInteger)reporterPriority {
    return HMDReporterPriorityNetTrafficMonitor;
}

#pragma mark --- app state

+ (void)changeTrafficAppState:(HMDNetTrafficApplicationStateType)state {
    hmdTrafficAppState = state;
}

+ (HMDNetTrafficApplicationStateType)currentTrafficAppState {
    return hmdTrafficAppState;
}

@end
