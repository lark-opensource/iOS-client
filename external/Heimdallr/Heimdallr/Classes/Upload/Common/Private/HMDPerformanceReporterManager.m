//
//	HMDPerformanceReporterManager.m
// 	Heimdallr
// 	
// 	Created by Hayden on 2020/8/27. 
//

#import "HMDPerformanceReporterManager.h"
#if RANGERSAPM
#import "HMDPerformanceReporterManager+RangersAPMURLProvider.h"
#else
#import "HMDPerformanceReporterManager+HMDURLProvider.h"
#endif
#import "HMDInjectedInfo.h"
#import "HMDInjectedInfo+NetworkSchedule.h"
#import "HMDReportSizeLimitManager.h"
#import "HMDGCD.h"
#import "HMDWeakProxy.h"
#include "pthread_extended.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDSimpleBackgroundTask.h"
#import "HMDHeimdallrConfig.h"
#import "NSDictionary+HMDHTTPQuery.h"
#import "HMDDynamicCall.h"
#import "HMDPerformanceReporter+SizeLimitedReport.h"
#import "HMDALogProtocol.h"
#import "HMDMacro.h"
#import "HMDNetworkManager.h"
#import "HeimdallrUtilities.h"
#import "HMDMemoryUsage.h"
#import "HMDUploadHelper.h"
#if RANGERSAPM
#import "RangersAPMBalanceManager.h"
#import "RangersAPMSelfMonitor.h"
#import "RangersAPMUploadHelper.h"
#endif
#import "HMDDebugRealConfig.h"
#import "HMDExceptionReporter.h"
#import "HMDRecordStore.h"
#import "HMDStoreCondition.h"
#import "HMDStoreIMP.h"
#import "NSArray+HMDSafe.h"
#import "HMDRecordCleanALog.h"
#import "HMDNetworkReqModel.h"
#import "NSDictionary+HMDSafe.h"
#import "NSDictionary+HMDJSON.h"
#import "HMDGeneralAPISettings.h"
#import "HMDDoubleReporter.h"
#import "HMDReportDowngrador.h"
#import "HMDCustomReportManager.h"
#import "HMDURLHelper.h"
#import "HMDServerStateChecker.h"
#import "HMDServerStateService.h"
#import "HMDURLManager.h"
#import "HMDURLSettings.h"

static NSString *const kHMPeformanceUploadTimer = @"hmd.upload.timer";
NSString *const HMDPerformanceReportSuccessNotification = @"HMDPerformanceReportSuccessNotification";

static NSString *const HMDPerformanceReportBackgroundTask = @"com.heimdallr.performanceReport.backgroundTask";

static long long kHMDPerformanceOnceUploadMaxCount = 200;
static long long kHMDPerformanceReporterDataMinCount = 10;

@interface HMDPerformanceReporterManager () <HMDPerformanceReporterCheckPointProtocol, HMDDoubleReporterDelegate> {
    pthread_rwlock_t _rwlock;
}

@property (nonatomic, strong) NSMutableDictionary<NSString *,HMDPerformanceReporter *> *reporters;

@property (nonatomic, assign) NSTimeInterval reportPollingInterval;
@property (nonatomic, strong) NSTimer *autoReportTimer;
#if !RANGERSAPM
@property (atomic, assign, readwrite) BOOL isUploading;
#else
@property (atomic, assign, readwrite) NSInteger isUploading;
#endif
@property (nonatomic, strong) dispatch_queue_t reportorQueue;
@property (nonatomic, strong) HMDDoubleReporter *doubleReporter;

@property (nonatomic, strong) HMDServerStateChecker *serverStateChecker;

@end

@implementation HMDPerformanceReporterManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static HMDPerformanceReporterManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[HMDPerformanceReporterManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        rwlock_init_private(_rwlock);
        _reporters = [NSMutableDictionary dictionaryWithCapacity:4];
        _serverStateChecker = [HMDServerStateChecker stateCheckerWithReporter:HMDReporterPerformance];
        _reportorQueue = dispatch_queue_create("com.heimdallr.performance_report", DISPATCH_QUEUE_SERIAL);
        _doubleReporter = [HMDDoubleReporter sharedReporter];
        _doubleReporter.delegate = self;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleBackgroundNotification:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    return self;
}

- (void)doubleUploadNetworkRecordArray:(NSArray *)records toURLString:(NSString *)urlstring {
    records = [self performanceDataWithDowngradeFilter:records];
    if (records.count == 0) return;
    
    // 获取 query 参数
    id<HMDNetworkProvider> hostProvider = [self _getReporterSafeWithAppID:HMDInjectedInfo.defaultInfo.appID].provider;
    NSDictionary *commonParams = nil;
    if (hostProvider && [hostProvider respondsToSelector:@selector(reportCommonParams)]) {
        commonParams = [hostProvider reportCommonParams];
    }
    
    NSDictionary *headerInfo = nil;
    if (hostProvider && [hostProvider respondsToSelector:@selector(reportHeaderParams)]) {
        headerInfo = [hostProvider reportHeaderParams];
    }

    //防止业务层没配置通用参数，用headerInfo兜底，否则配置获取不正确
    if (HMDIsEmptyDictionary(commonParams)) {
        commonParams = headerInfo;
    }
    
    NSMutableDictionary *queryDic = [NSMutableDictionary dictionaryWithDictionary:commonParams];
    if (![queryDic valueForKey:@"update_version_code"]) {
        [queryDic setValue:headerInfo[@"update_version_code"] forKey:@"update_version_code"];
    }
    if (![queryDic valueForKey:@"os"]) {
        [queryDic setValue:headerInfo[@"os"] forKey:@"os"];
    }
    if (![queryDic valueForKey:@"aid"]) {
        [queryDic setValue:headerInfo[@"aid"] forKey:@"aid"];
    }
    if (![queryDic valueForKey:@"host_aid"]) {
        [queryDic setValue:[HMDInjectedInfo defaultInfo].appID forKey:@"host_aid"];
    }
    
    urlstring = [HMDURLHelper URLWithString:urlstring];
    if (!HMDIsEmptyDictionary(queryDic)) {
        NSString *queryString = [queryDic hmd_queryString];
        urlstring = [NSString stringWithFormat:@"%@?%@", urlstring, queryString];
    }
    
    NSMutableDictionary *reporterData = [NSMutableDictionary new];
    [reporterData setValue:records forKey:@"data"];
    [reporterData setValue:[headerInfo copy] forKey:@"header"];
    
    NSDictionary *body = @{@"list":@[[reporterData copy]]};
    
    NSMutableDictionary * headerDict = [NSMutableDictionary dictionaryWithCapacity:3];
    [headerDict setValue:@"application/json; encoding=utf-8" forKey:@"Content-Type"];
    [headerDict setValue:@"application/json" forKey:@"Accept"];
    [headerDict setValue:@"1" forKey:@"Version-Code"];
    [headerDict setValue:@"2085" forKey:@"sdk_aid"];

    HMDNetworkReqModel *reqModel = [HMDNetworkReqModel new];
    reqModel.requestURL = urlstring;
    reqModel.method = @"POST";
    reqModel.headerField = [headerDict copy];
    reqModel.params = body;
    reqModel.needEcrypt = [self shouldEncrypt];
    
    [[HMDNetworkManager sharedInstance] asyncRequestWithModel:reqModel callback:nil];
}

- (void)addReporter:(HMDPerformanceReporter *)reporter withAppID:(NSString *)appID {
    if (!appID) {
        NSAssert(false, @"[FATAL ERROR] Please inject correct appID into HMDPerformanceReporterManager.");
        return;
    }
    pthread_rwlock_wrlock(&_rwlock);
    [self.reporters setValue:reporter forKey:appID];
    pthread_rwlock_unlock(&_rwlock);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.autoReportTimer && [self.autoReportTimer isValid]) {
        [self.autoReportTimer invalidate];
        self.autoReportTimer = nil;
    }
}

#pragma - mark Update Config
- (void)updateConfig:(HMDHeimdallrConfig *)config withAppID:(NSString *)appID {
    HMDPerformanceReporter *reporter = [self _getReporterSafeWithAppID:appID];
    if (reporter) {
        if ([appID isEqualToString:[HMDInjectedInfo defaultInfo].appID]) {
            if (config.apiSettings.performanceAPISetting) {
                self.needEncrypt = config.apiSettings.performanceAPISetting.enableEncrypt;
            } else if (config.apiSettings.allAPISetting) {
                self.needEncrypt = config.apiSettings.allAPISetting.enableEncrypt;
            } else {
                self.needEncrypt = NO;
            }
            self.maxRetryTimes = config.apiSettings.performanceAPISetting.maxRetryCount;
            self.reportFailBaseInterval = config.apiSettings.performanceAPISetting.reportFailBaseInterval;
            [HMDReportDowngrador sharedInstance].enabled = config.apiSettings.performanceAPISetting.enableDowngradeByChannel;
#if !RANGERSAPM
            [self.doubleReporter update:config];
#endif
        }
        [reporter updateConfig:config];
        
        NSArray *reporters = nil;
        pthread_rwlock_rdlock(&_rwlock);
        reporters = self.reporters.allValues;
        pthread_rwlock_unlock(&_rwlock);
        
        NSTimeInterval minPollingInterval = self.reportPollingInterval ?: reporter.reportPollingInterval;
        for (HMDPerformanceReporter *reporter in reporters) {
#if RANGERSAPM
            //避免自监控组件的配置影响上报间隔：取得是最小值，如果自监控组件的上报间隔小于用户的，则会导致用户的上报间隔配置无效
            if ([reporter.sdkAid isEqualToString:[RangersAPMSelfMonitor sdkID]]) {
                continue;
            }
#endif
            if (reporter.reportPollingInterval < minPollingInterval) {
                minPollingInterval = reporter.reportPollingInterval;
            }
        }
        self.reportPollingInterval = minPollingInterval;
    }
}

- (void)updateRecordCount:(NSInteger)count withAppID:(NSString *)appID {
    HMDPerformanceReporter *reporter = [self _getReporterSafeWithAppID:appID];
    if (reporter) {
        BOOL needReport = [reporter ifNeedReportAfterUpdatingRecordCount:count];
        if (needReport && !self.isUploading) {
            [self reportPerformanceDataAsyncWithAppID:appID block:NULL];
        }
    }
}

- (void)addReportModule:(id<HMDPerformanceReporterDataSource>)module withAppID:(NSString *)appID {
    if (!module) return;
    
    HMDPerformanceReporter *reporter = [self _getReporterSafeWithAppID:appID];
    if (reporter) {
        [reporter addReportModuleSafe:module];
    }
}

- (void)removeReportModule:(id<HMDPerformanceReporterDataSource>)module withAppID:(NSString *)appID {
    if (!module) return;
    
    HMDPerformanceReporter *reporter = [self _getReporterSafeWithAppID:appID];
    if (reporter) {
        [reporter removeReportModuleSafe:module];
    }
}

- (void)cleanupWithConfig:(HMDDebugRealConfig *)config {
    if (!config) return;
    
    HMDPerformanceReporter *reporter = [self _getReporterSafeWithAppID:[HMDInjectedInfo defaultInfo].appID];
    if (reporter) {
        hmd_safe_dispatch_async(self.reportorQueue, ^{
            [reporter cleanupWithConfigUnsafe:config];
        });
    }
}

#pragma - mark AutoTimer
- (void)startCollectFlushTimer {
    NSTimeInterval reportPollingInterval = self.reportPollingInterval;
    if(reportPollingInterval > 0) {
        NSTimer *previousTimer = self.autoReportTimer;
        
        NSTimer *timer = [NSTimer timerWithTimeInterval:reportPollingInterval
                                                 target:[HMDWeakProxy proxyWithTarget:self]
                                               selector:@selector(autoReportPerformanceData:)
                                               userInfo:nil
                                                repeats:NO];
        
        self.autoReportTimer = timer;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([previousTimer isValid]) {
                [previousTimer invalidate];
            }
            if (timer) {
                [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
            }
        });
    }
}

- (void)stopCollectFlushTimer {
    NSTimer *timer = self.autoReportTimer;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([timer isValid]) {
            [timer invalidate];
        }
    });
    self.autoReportTimer = nil;
}

- (void)autoReportPerformanceData:(NSTimer *)timer {
    [self resetFlushTimer];
    NSString *appID = [self _getHostAppID];
    [self _reportPerformanceDataIfAllowedWithAppID:appID reporterType:HMDPerformanceReporterTimer singleReporter:nil block:NULL];
}

- (void)resetFlushTimer {
    hmd_safe_dispatch_async(self.reportorQueue, ^{
        [self stopCollectFlushTimer];
        [self startCollectFlushTimer];
    });
}

#pragma - mark Reporting
///  检查上报时间间隔;
- (BOOL)checkServerAvailable
{
    return self.serverStateChecker && [self.serverStateChecker isServerAvailable];
}

// 手动调用
- (void)reportDataWithReporter:(HMDPerformanceReporter *)reporter block:(PerformanceReporterBlock)block {
    if (!reporter) {
        return;
    }
    
    if ([HMDCustomReportManager defaultManager].currentConfig.customReportMode != HMDCustomReportModeActivelyTrigger) {
        return;
    }
    
    hmd_safe_dispatch_async(self.reportorQueue, ^{
        [self _reportPerformanceDataWithBlock:block reporterType:HMDPerformanceReporterNormal singleReporter:reporter appID:nil];
    });
}

// sizeLimited模式调用
- (void)reportPerformanceDataAsyncWithSizeLimitedReporter:(HMDPerformanceReporter *)reporter block:(PerformanceReporterBlock)block {
    if ([[HMDInjectedInfo defaultInfo].disableNetworkRequest boolValue]) {
       return;
    }

    if ([HMDCustomReportManager defaultManager].currentConfig.customReportMode != HMDCustomReportModeSizeLimit) {
        return;
    }

    hmd_safe_dispatch_async(self.reportorQueue, ^{
       NSTimeInterval currentTimeInterval = [[NSDate date] timeIntervalSince1970];
       if (currentTimeInterval > reporter.sizeLimitAvailableTime) {
           [reporter stopSizeLimitedReportTimer];
           [self _reportPerformanceDataWithBlock:block reporterType:HMDPerformanceReporterSizeLimited singleReporter:reporter appID:nil];
           [reporter startSizeLimitedReportTimer];
       }
    });
}

//性能指标，业务埋点，UI交互事件等数据上报...
// record count达到数量后触发
- (void)reportPerformanceDataAsyncWithAppID:(NSString *)appID block:(PerformanceReporterBlock)block {
    if (!appID) {
        return;
    }
    [self _reportPerformanceDataIfAllowedWithAppID:appID reporterType:HMDPerformanceReporterNormal singleReporter:nil block:block];
}
// 此处可能会传入sdk appID
- (void)reportPerformanceDataAfterInitializeWithAppID:(NSString *)appID block:(PerformanceReporterBlock)block {
    if (!appID) {
        return;
    }
    [self _reportPerformanceDataIfAllowedWithAppID:appID reporterType:HMDPerformanceReporterInitialize singleReporter:nil block:block];
}


// TTMonitor会掉用
- (void)reportImmediatelyPerformanceCacheDataWithAppID:(NSString *)appID block:(PerformanceReporterBlock)block {
    if (!appID) {
        return;
    }
    HMDPerformanceReporter *reporter = [self _getReporterSafeWithAppID:appID];
    if (!reporter) {
        return;
    }
    hmd_safe_dispatch_async(self.reportorQueue, ^{
        [self _reportPerformanceDataWithBlock:block reporterType:HMDPerformanceReporterImmediatelyData singleReporter:reporter appID:appID];
    });
}


- (void)reportOTDataWithReporter:(HMDPerformanceReporter *)reporter block:(PerformanceReporterBlock)block {
    if (!reporter) {
        return;
    }
    [self _reportPerformanceDataIfAllowedWithAppID:nil reporterType:HMDPerformanceReporterOpenTrace singleReporter:reporter block:block];
}

- (void)_reportPerformanceDataIfAllowedWithAppID:(NSString * _Nullable)appID reporterType:(HMDPerformanceReporterType)reporterType singleReporter:(HMDPerformanceReporter * _Nullable)singleReporter block:(PerformanceReporterBlock)block {
    [self resetFlushTimer];
    
    if ([[HMDInjectedInfo defaultInfo].disableNetworkRequest boolValue]) {
        return;
    }
    if ([HMDCustomReportManager defaultManager].currentConfig != NULL) {
        return;
    }
    
    if (!singleReporter) {
        singleReporter = [self _getReporterSafeWithAppID:appID];
    }
    if (!singleReporter) {
        return;
    }
    
    hmd_safe_dispatch_async(self.reportorQueue, ^{
        [self _reportPerformanceDataWithBlock:block reporterType:reporterType singleReporter:singleReporter appID:appID];
    });
}

#if !RANGERSAPM
- (void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) _reportPerformanceDataWithBlock:(PerformanceReporterBlock _Nullable)block reporterType:(HMDPerformanceReporterType)reporterType singleReporter:(HMDPerformanceReporter *)singleReporter appID:(NSString * _Nullable)appID {
    
    id<HMDNetworkProvider> hostProvider = singleReporter.provider;
    id<HMDURLPathProvider> urlPathProvider = self;
    HMDReporter hmdreporter = HMDReporterPerformance;
    
    NSDictionary *commonParams = nil;
    if (hostProvider && [hostProvider respondsToSelector:@selector(reportCommonParams)]) {
        commonParams = [hostProvider reportCommonParams];
    }
    
    NSDictionary *headerInfo = nil;
    if (hostProvider && [hostProvider respondsToSelector:@selector(reportHeaderParams)]) {
        headerInfo = [hostProvider reportHeaderParams];
    }

    //防止业务层没配置通用参数，用headerInfo兜底，否则配置获取不正确
    if (HMDIsEmptyDictionary(commonParams)) {
        commonParams = headerInfo;
    }
    
    if ([commonParams valueForKey:@"aid"]) {
        appID = commonParams[@"aid"];
    }
    else if ([headerInfo valueForKey:@"aid"]) {
        appID = headerInfo[@"aid"];
    }
    
    if (reporterType == HMDPerformanceReporterOpenTrace) {
        hmdreporter = HMDReporterOpenTrace;
        appID = HMDInjectedInfo.defaultInfo.appID;
        urlPathProvider = [[HMDPerformanceReporterURLPathProvider alloc] initWithProvider:hostProvider];
    }
    
    if(self.isUploading || !hmd_is_server_available_sdk(hmdreporter, appID)) {
        if(block) {
            block(NO);
        }
        return;
    }
    NSString *requestURL = [HMDURLManager URLWithHostProvider:self pathProvider:urlPathProvider forAppID:appID];
    if (requestURL == nil) {
        if (block) {
            block(NO);
        }
        return;
    }

    self.isUploading = YES;
    
    pthread_rwlock_rdlock(&_rwlock);
    NSDictionary *reportersDic = [self.reporters copy];
    pthread_rwlock_unlock(&_rwlock);
    
    NSMutableArray *dataArray = [NSMutableArray new];
    BOOL maybeMoreData = NO;
    NSString *eventLog = @"";
    NSMutableArray *addedModules = [NSMutableArray new];
    NSMutableArray *addedReporters = [NSMutableArray new];
    [self _recordPerformanceReportMemoryBefore];
    
    if (reporterType == HMDPerformanceReporterTimer
        || reporterType == HMDPerformanceReporterInitialize
        || reporterType == HMDPerformanceReporterBackground) {
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
        NSInteger maxCount = kHMDPerformanceOnceUploadMaxCount;
        
        for (NSString *appID in reportersDic.allKeys) {
            HMDPerformanceReporter *reporter = [reportersDic valueForKey:appID];
            if (currentTime <= reporter.enableTimeStamp) {
                continue;
            }
            
            id<HMDNetworkProvider> provider = reporter.provider;
            NSDictionary *bodyDic = [self _bodyDataFromReporter:reporter andProvider:provider addedModules:addedModules reporterType:reporterType maybeMoreData:&maybeMoreData reporterMaxCount:&maxCount eventLog:&eventLog];
            if (bodyDic) {
                [addedReporters hmd_addObject:reporter];
                [dataArray hmd_addObject:bodyDic];
            }
        }
        
        if (reporterType == HMDPerformanceReporterInitialize && maxCount < kHMDPerformanceOnceUploadMaxCount - 50) {
            if (block) {
                block(NO);
            }

            self.isUploading = NO;
            return;
        }
    }
    else {
        NSDictionary *bodyDic = [self _bodyDataFromReporter:singleReporter andProvider:hostProvider addedModules:addedModules reporterType:reporterType maybeMoreData:nil reporterMaxCount:NULL eventLog:&eventLog];
        if (bodyDic) {
            [dataArray hmd_addObject:bodyDic];
            [addedReporters hmd_addObject:singleReporter];
        }
    }
    
    //return if no data to report
    if (dataArray.count < 1) {
       if (block) {
           block(NO);
       }

       self.isUploading = NO;
       return;
    }
    
    [self _recordPerfomanceReportMemoryAfterWithModules:addedModules];
    
    NSDictionary *body = nil;
    if (reporterType == HMDPerformanceReporterOpenTrace) {
        body = dataArray.firstObject;
    }
    else {
        body = @{@"list":[dataArray copy]};
    }
    
    // 如果是限制包大小的上传模式 计算上传的时间间隔
    if (reporterType == HMDPerformanceReporterSizeLimited) {
        [singleReporter _sizeLimitedTimeAvaliableWithBody:body];
    }
    
    // 添加query参数，兼容端容灾策略
    NSMutableDictionary *queryDic = [NSMutableDictionary dictionaryWithDictionary:commonParams];
    if (![queryDic valueForKey:@"update_version_code"]) {
        [queryDic setValue:headerInfo[@"update_version_code"] forKey:@"update_version_code"];
    }
    if (![queryDic valueForKey:@"os"]) {
        [queryDic setValue:headerInfo[@"os"] forKey:@"os"];
    }
    if (![queryDic valueForKey:@"aid"]) {
        [queryDic setValue:headerInfo[@"aid"] forKey:@"aid"];
    }
    if (![queryDic valueForKey:@"host_aid"]) {
        [queryDic setValue:[HMDInjectedInfo defaultInfo].appID forKey:@"host_aid"];
    }
    
    if ([HMDInjectedInfo defaultInfo].useDebugLogLevel && ![queryDic valueForKey:@"log_level_"]) {
        [queryDic setValue:@"debug" forKey:@"_log_level"];
    }

    if (!HMDIsEmptyDictionary(queryDic)) {
        NSString *queryString = [queryDic hmd_queryString];
        requestURL = [NSString stringWithFormat:@"%@?%@", requestURL, queryString];
    }

    NSMutableDictionary * headerDict = [NSMutableDictionary dictionaryWithCapacity:3];
    [headerDict setValue:@"application/json; encoding=utf-8" forKey:@"Content-Type"];
    [headerDict setValue:@"application/json" forKey:@"Accept"];
    [headerDict setValue:@"1" forKey:@"Version-Code"];
    [headerDict setValue:@"2085" forKey:@"sdk_aid"];

    HMDNetworkReqModel *reqModel = [HMDNetworkReqModel new];
    reqModel.requestURL = requestURL;
    reqModel.method = @"POST";
    reqModel.headerField = [headerDict copy];
    reqModel.params = body;
    reqModel.needEcrypt = [self shouldEncrypt];
    
    [[HMDNetworkManager sharedInstance] asyncRequestWithModel:reqModel callback:^(NSError *error, id maybeDictionary)
     {
        hmd_safe_dispatch_async(self.reportorQueue, ^{
            NSDictionary *decryptedDict = nil;
            NSInteger statusCode = error ? error.code : 0;
            HMDServerState serverState = HMDServerStateUnknown;
            BOOL isSuccess = NO;
            
            if ([maybeDictionary isKindOfClass:NSDictionary.class]) {
                NSDictionary *resultDictionary;
                if((resultDictionary = [maybeDictionary hmd_dictForKey:@"result"]) != nil) {
                    NSString *base64String;
                    if((base64String = [resultDictionary hmd_stringForKey:@"data"]) != nil) {
                        NSData *encyptedData = [base64String dataUsingEncoding:NSUTF8StringEncoding];
                        //ran is the key for aes
                        NSString *ran = [maybeDictionary hmd_stringForKey:@"ran"];
                        if(ran != nil && [ran isKindOfClass:[NSString class]]){
                            decryptedDict = [HeimdallrUtilities payloadWithDecryptData:encyptedData
                                                                               withKey:ran
                                                                                    iv:ran];
                            [self excuteCloudCommandIfAvailable:encyptedData ran:ran];
                        }
                    }
                }
                statusCode = [maybeDictionary hmd_integerForKey:@"status_code"];
                if (eventLog.length) {
                    HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"Uploaded event log id : %@, %@", [maybeDictionary hmd_stringForKey:@"x-tt-logid"] ?: @"", eventLog);
                }
                
                // update downgrade rule
                NSDictionary *downgradeRule = [decryptedDict hmd_dictForKey:@"downgrade_rule"];
                [[HMDReportDowngrador sharedInstance] updateDowngradeRule:downgradeRule forAid:appID];
            }
            serverState = [self checkErrorCodeAndDebugRealWithResponse:decryptedDict statusCode:statusCode addedReporters:[addedReporters copy] addedModules:[addedModules copy] hmdreporter:hmdreporter appID:appID];
            for (HMDPerformanceReporter *reporter in addedReporters) {
                [reporter clearRecordCountAfterReportingSuccessfully];
            }
            if ((serverState & HMDServerStateSuccess) == HMDServerStateSuccess) {
                if (reporterType == HMDPerformanceReporterTimer
                    || reporterType == HMDPerformanceReporterInitialize) {
                    for (HMDPerformanceReporter *reporter in addedReporters) {
                        [reporter updateEnableTimeStampAfterReporting];
                    }
                }
                isSuccess = YES;
            }
            if (block) {
                block(isSuccess);
            }
            
            if(!isSuccess && hmd_log_enable()) {
                HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDPerformanceReporter _reportPerformanceDataWithBlock:] upload error !!!! error = %@, response = %@, server state = %ld", error, decryptedDict, serverState);
            }
            for (id module in addedModules) {
                if(reporterType == HMDPerformanceReporterSizeLimited) {
                    if ([module respondsToSelector:@selector(performanceSizeLimitedDataDidReportSuccess:)]) {
                        [module performanceSizeLimitedDataDidReportSuccess:isSuccess];
                    }
                } else {
                    if ([module respondsToSelector:@selector(performanceDataDidReportSuccess:)]) {
                        [module performanceDataDidReportSuccess:isSuccess];
                    }
                }
            }
            if(isSuccess) {
                if(reporterType == HMDPerformanceReporterSizeLimited) {
                    hmdSizeLimitPerfReportClearDataALog();
                } else {
                    hmdPerfReportClearDataALog();
                }
            }
                
            if (isSuccess) {
                if ([self respondsToSelector:@selector(dataReportSuccessedCheckPointWithReporter:)]) {
                    [self dataReportSuccessedCheckPointWithReporter:[NSString stringWithFormat:@"%p", self]];
                }
            }
            else {
                if ([self respondsToSelector:@selector(dataReportFailedCheckPointWithReporter:error:response:)]) {
                    [self dataReportFailedCheckPointWithReporter:[NSString stringWithFormat:@"%p", self] error:error response:decryptedDict];
                }
            }
            
            self.isUploading = NO;
            
            if (DC_CL(HMDOfflineHook, onOfflineMode) && maybeMoreData) {
                [self _reportPerformanceDataWithBlock:block reporterType:reporterType singleReporter:singleReporter appID:appID];
            }
        });
    }];
    
    if ([self respondsToSelector:@selector(dataReportingCheckPointWithReporter:)]) {
        [self dataReportingCheckPointWithReporter:[NSString stringWithFormat:@"%p", self]];
    }
}
#else
- (void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) _reportPerformanceDataWithBlock:(PerformanceReporterBlock _Nullable)block reporterType:(HMDPerformanceReporterType)reporterType singleReporter:(HMDPerformanceReporter *)singleReporter appID:(NSString * _Nullable)appID {
    if (self.isUploading || ![self checkServerAvailable]) {
        if (block) {
            block(NO);
        }
        return;
    }
        
    self.isUploading ++;

    // body data
    pthread_rwlock_rdlock(&_rwlock);
    NSDictionary *reportersDic = [self.reporters copy];
    pthread_rwlock_unlock(&_rwlock);
    
    //ToB SDK监控各SDK单独上报日志
    if (reporterType == HMDPerformanceReporterTimer
        || reporterType == HMDPerformanceReporterInitialize
        || reporterType == HMDPerformanceReporterBackground) {
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
        
        for (NSString *appID in reportersDic.allKeys) {
            HMDPerformanceReporter *reporter = [reportersDic valueForKey:appID];
            if (currentTime <= reporter.enableTimeStamp) {
                continue;
            }
            
            [self _reportPerformanceDataWithReporter:reporter reporterType:reporterType block:block];
        }
    }
    else {
        [self _reportPerformanceDataWithReporter:singleReporter reporterType:reporterType block:block];
    }
    
    self.isUploading --;
    
}

- (void)_reportPerformanceDataWithReporter:(HMDPerformanceReporter *)reporter reporterType:(HMDPerformanceReporterType)reporterType block:(PerformanceReporterBlock)block {
    if (![[RangersAPMBalanceManager sharedInstance] enoughBalanceForAppID:reporter.sdkAid]) {
        return;
    }
    self.isUploading ++;
    NSMutableArray *addedModules = [NSMutableArray new];
    NSInteger maxCount = (int)kHMDPerformanceOnceUploadMaxCount;
    
    id<HMDNetworkProvider> provider = reporter.provider;
    
    NSString *performanceUploadURL = [HMDURLManager URLWithProvider:self forAppID:reporter.sdkAid];
    if (performanceUploadURL == nil) {
        if (block) {
            block(NO);
        }
        self.isUploading --;
        return;
    }
    
    NSDictionary *body = [self _bodyDataFromReporter:reporter andProvider:provider addedModules:addedModules reporterType:reporterType maybeMoreData:nil reporterMaxCount:&maxCount eventLog:nil];
    if (!body) {
        if (block) {
            block(NO);
        }
        
        self.isUploading --;
        return;
    }
    
    if (reporterType == HMDPerformanceReporterInitialize && maxCount < kHMDPerformanceOnceUploadMaxCount - 50) {
        if (block) {
            block(NO);
        }
        
        self.isUploading --;
        return;
    }
    
    // 如果是限制包大小的上传模式 计算上传的时间间隔
    if (reporterType == HMDPerformanceReporterSizeLimited) {
        [reporter _sizeLimitedTimeAvaliableWithBody:body];
    }
    
    NSDictionary *headerInfo = nil;
    if (provider && [provider respondsToSelector:@selector(reportHeaderParams)]) {
        headerInfo = [provider reportHeaderParams];
    }
    
    // 添加query参数，兼容端容灾策略
    NSMutableDictionary *queryDic = [NSMutableDictionary dictionaryWithDictionary:headerInfo];
    
    //判断是否可以执行回捞命令
    [queryDic hmd_setObject:([self enableCloudCommand] ? @"true" : @"false") forKey:@"enable_cc"];

    if (!HMDIsEmptyDictionary(queryDic)) {
        NSString *queryString = [queryDic hmd_queryString];
        performanceUploadURL = [NSString stringWithFormat:@"%@?%@",performanceUploadURL,queryString];
    }

    NSMutableDictionary *customHeaderDict = [NSMutableDictionary dictionaryWithCapacity:3];
    [customHeaderDict setValue:@"application/json; encoding=utf-8" forKey:@"Content-Type"];
    [customHeaderDict setValue:@"application/json" forKey:@"Accept"];
    [customHeaderDict setValue:@"1" forKey:@"Version-Code"];
    
    NSDictionary *headerDict = [RangersAPMUploadHelper headerFieldsForAppID:reporter.sdkAid withCustomHeaderFields:customHeaderDict];
    
    BOOL needEncrypt = YES;
    
#if DEBUG
    needEncrypt = NO;
#endif
    
    HMDNetworkReqModel *reqModel = [HMDNetworkReqModel new];
    reqModel.requestURL = performanceUploadURL;
    reqModel.method = @"POST";
    reqModel.params = body;
    reqModel.headerField = [headerDict copy];
    reqModel.needEcrypt = needEncrypt;
    [[HMDNetworkManager sharedInstance] asyncRequestWithModel:reqModel callback:^(NSError *error, id maybeDictionary) {
        hmd_safe_dispatch_async(self.reportorQueue, ^{
            NSDictionary *decryptedDict = nil;
            NSInteger statusCode = error ? error.code : 0;
            HMDServerState serverState = HMDServerStateUnknown;
            BOOL isSuccess = NO;
            
            if ([maybeDictionary isKindOfClass:NSDictionary.class]) {
                NSDictionary *resultDictionary;
                if((resultDictionary = [maybeDictionary hmd_dictForKey:@"result"]) != nil) {
                    NSString *base64String;
                    if((base64String = [resultDictionary hmd_stringForKey:@"data"]) != nil) {
                        NSData *encyptedData = [base64String dataUsingEncoding:NSUTF8StringEncoding];
                        //ran is the key for aes
                        NSString *ran = [maybeDictionary hmd_stringForKey:@"ran"];
                        if(ran != nil && [ran isKindOfClass:[NSString class]]){
                            decryptedDict = [HeimdallrUtilities payloadWithDecryptData:encyptedData
                                                                               withKey:ran
                                                                                    iv:ran];
                            [self excuteCloudCommandIfAvailable:encyptedData ran:ran];
                        }
                    }
                }
                statusCode = [maybeDictionary hmd_integerForKey:@"status_code"];
            }
            
            // update downgrade rule
            NSDictionary *downgradeRule = [decryptedDict hmd_dictForKey:@"downgrade_rule"];
            [[HMDReportDowngrador sharedInstance] updateDowngradeRule:downgradeRule forAid:reporter.sdkAid];
            
            serverState = [self checkErrorCodeAndDebugRealWithResponse:decryptedDict statusCode:statusCode addedReporters:@[reporter]];

            [reporter clearRecordCountAfterReportingSuccessfully];
            
            if ((serverState & HMDServerStateSuccess) == HMDServerStateSuccess) {
                if (reporterType == HMDPerformanceReporterTimer
                    || reporterType == HMDPerformanceReporterInitialize) {
                        [reporter updateEnableTimeStampAfterReporting];
                }
                isSuccess = YES;
            }
            if (block) {
                block(isSuccess);
            }
            
            for (id module in addedModules) {
                if(reporterType == HMDPerformanceReporterSizeLimited) {
                    if ([module respondsToSelector:@selector(performanceSizeLimitedDataDidReportSuccess:)]) {
                        [module performanceSizeLimitedDataDidReportSuccess:isSuccess];
                    }
                } else {
                    if ([module respondsToSelector:@selector(performanceDataDidReportSuccess:)]) {
                        [module performanceDataDidReportSuccess:isSuccess];
                    }
                }
            }
            
            self.isUploading --;
        });
    }];
}

- (BOOL)enableCloudCommand {
    Class clz = NSClassFromString(@"AWECloudCommandManager");
    return clz;
}
#endif

- (NSDictionary *)_bodyDataFromReporter:(HMDPerformanceReporter *)reporter andProvider:(id<HMDNetworkProvider>)provider addedModules:(NSMutableArray *)addedModules reporterType:(HMDPerformanceReporterType)reporterType maybeMoreData:(BOOL *)maybeMoreData reporterMaxCount:(NSInteger *)maxCount eventLog:(NSString **)eventLog {

    NSDictionary *headers = nil;
    if (provider && [provider respondsToSelector:@selector(reportHeaderParams)]) {
        headers = [provider reportHeaderParams];
    } else {
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr",@"Heimdallr perfomaceReporter reportHeader not confirm");
        }
        NSAssert(NO, @"[FATAL ERROR] Please preserve current environment"
                    " and contact Heimdallr developer ASAP.");
        return nil;
    }
    
    // 除立即上报类型外的埋点, devic_id为“0“，空字符串或者不存在时，不进行取数据上报
    if(reporterType != HMDPerformanceReporterImmediatelyData){
        NSString* did = [headers hmd_stringForKey:@"device_id"];
        if(did == nil || did.length == 0 || [did isEqualToString:@"0"]){
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"The value of device_id is error in Heimdallr perfomaceReporter reportHeader");
            return nil;
        }
    }
    
    NSArray<id<HMDPerformanceReporterDataSource>> *modules = reporter.allReportingModules;

    NSArray *moduleData = nil;
    if (reporterType == HMDPerformanceReporterSizeLimited) {
        moduleData = [reporter _dataArrayForSizeLimitedReportWithAddedMoudle:addedModules modules:modules];
    }
    else if( reporterType == HMDPerformanceReporterImmediatelyData) {
        moduleData = [self _dataArrayForImmediatelyUploadeWithAddedMoudle:addedModules modules:modules];
    }
    else {
        NSInteger onceMaxDataCount = maxCount ? *maxCount : kHMDPerformanceOnceUploadMaxCount;
        moduleData = [self _dataArrayForNormalReportWithAddedMoudle:addedModules modules:modules maybeMoreData:maybeMoreData reporterMaxCount:onceMaxDataCount reporter:reporter];
        if (maxCount) {
            *maxCount = *maxCount > moduleData.count ? *maxCount - moduleData.count : kHMDPerformanceReporterDataMinCount;
        }
    }
    
    // downgrade filter
    moduleData = [self performanceDataWithDowngradeFilter:moduleData];
    
    if (!moduleData.count) {
        return nil;
    }

    // event log info for uploading
    NSInteger eventCount = 0;
    NSString *eventRange = [self _eventDataSequenceNumberRange:moduleData eventCount:&eventCount];
    NSInteger accumulation = [self _accumulationOfEventDataWithAppID:headers[@"aid"]] - eventCount;
    if (eventRange) {
        *eventLog = [NSString stringWithFormat:@"%@range : %@, accumulation : %ld, aid : %@\n", *eventLog, eventRange, accumulation, headers[@"aid"]];
    }
    
    NSMutableDictionary *headerInfo = [NSMutableDictionary dictionaryWithDictionary:headers];
    [headerInfo setValue:[NSString stringWithFormat:@"%ld", eventCount] forKey:@"event-count"];
    if (accumulation >= 0) {
        [headerInfo setValue:[NSString stringWithFormat:@"%ld", accumulation]  forKey:@"store-db-number"];
    }
    
    NSMutableDictionary *reporterData = [NSMutableDictionary new];
    
    NSArray *metricCountDataArray = nil;
    NSArray *metricTimerDataArray = nil;
    if (reporterType == HMDPerformanceReporterNormal) {
        metricCountDataArray = [self _metricCountForNormalReportWithAddedMoudle:addedModules modules:modules];
        metricTimerDataArray = [self _metricTimerForNormalReportWithAddedMoudle:addedModules modules:modules];
    }
    
    
    [reporterData setValue:moduleData forKey:@"data"];
    if (metricCountDataArray && metricCountDataArray.count > 0) {
        [reporterData setValue:metricCountDataArray forKey:@"count"];
    }
    if (metricTimerDataArray && metricTimerDataArray.count > 0) {
        [reporterData setValue:metricTimerDataArray forKey:@"timer"];
    }
    [reporterData setValue:[headerInfo copy] forKey:@"header"];
        
    return [reporterData copy];
}

/// module  response to  performanceDataWithCountLimit
- (NSArray *)_dataArrayForNormalReportWithAddedMoudle:(NSMutableArray *)addedModules modules:(NSArray *)modules maybeMoreData:(BOOL *)maybeMoreData reporterMaxCount:(NSInteger)reporterMaxCount reporter:(HMDPerformanceReporter *)reporter {
    NSMutableArray *dataArray = [NSMutableArray new];
    for (id module in modules) {
        @autoreleasepool {
            if ([module respondsToSelector:@selector(performanceDataWithCountLimit:)]) {
                if (dataArray.count < reporterMaxCount) {
                    NSInteger properLimitCount = 20;
                    if ([module respondsToSelector:@selector(reporterPriority)]) {
                        properLimitCount = reporterMaxCount - dataArray.count;
                    }
                    if ([module respondsToSelector:@selector(properLimitCount)]) {
                        properLimitCount = [module properLimitCount];
                    }
                    NSArray *result = nil;
                    if(reporter.isSDKReporter && reporter.sdkAid.length > 0 && [module respondsToSelector:@selector(performanceSDKDataWitLimitCount:sdkAid:)]) { // only network
                        result = [module performanceSDKDataWitLimitCount:properLimitCount sdkAid:reporter.sdkAid];
                    } else {
                        result = [module performanceDataWithCountLimit:properLimitCount];
                    }
                    if (result && result.count > 0) {
                        [dataArray addObjectsFromArray:result];
                        [addedModules hmd_addObject:module];
                        if (result.count == properLimitCount && maybeMoreData) {
                            *maybeMoreData = YES;
                        }
                        HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker : fetch data from module: %@, count: %zd, sdkAid: %@", NSStringFromClass([module class]), result.count, reporter.sdkAid);
                    }
                }
            }
        }
    }
    return dataArray;
}

/// module reponse to metricCountPerformanceData
- (NSArray *)_metricCountForNormalReportWithAddedMoudle:(NSMutableArray *)addedModules modules:(NSArray *)modules {
    NSMutableArray *metricCountDataArray = [NSMutableArray new];
    for (id module in modules) {
        @autoreleasepool {
            if ([module respondsToSelector:@selector(metricCountPerformanceData)]) {
                NSArray *result = [module metricCountPerformanceData];
                if (result) {
                    [metricCountDataArray addObjectsFromArray:result];
                    if (![addedModules containsObject:module]) {
                        [addedModules hmd_addObject:module];
                    }
                }
            }
        }
    }
    return metricCountDataArray;
}

/// module reponse to metricTimerPerformanceData
- (NSArray *)_metricTimerForNormalReportWithAddedMoudle:(NSMutableArray *)addedModules modules:(NSArray *)modules {
    NSMutableArray *metricTimerDataArray = [NSMutableArray new];
    for (id module in modules) {
        @autoreleasepool {
            if ([module respondsToSelector:@selector(metricTimerPerformanceData)]) {
                NSArray *result = [module metricTimerPerformanceData];
                if (result) {
                    [metricTimerDataArray addObjectsFromArray:result];
                }
                if (![addedModules containsObject:module]) {
                    [addedModules hmd_addObject:module];
                }
            }
        }
    }
    return metricTimerDataArray;
}

- (NSArray *)_dataArrayForImmediatelyUploadeWithAddedMoudle:(NSMutableArray *)addedModules modules:(NSArray *)modules {
    NSMutableArray *dataArray = [NSMutableArray new];
    for (id module in modules) {
        @autoreleasepool {
            if ([module respondsToSelector:@selector(performanceCacheDataImmediatelyUpload)]) {
                NSArray *result = [module performanceCacheDataImmediatelyUpload];
                if(result && result.count > 0) {
                    [dataArray addObjectsFromArray:result];
                    [addedModules hmd_addObject:module];
                }
            }
        }
    }
    return dataArray;
}

// event range
- (NSString *)_eventDataSequenceNumberRange:(NSArray *)dataArray eventCount:(NSInteger *)eventCount {
    __block int64_t minSequenceNumber = INT64_MAX;
    __block int64_t maxSequenceNumber = INT64_MIN;
    __block NSInteger count = 0;
    [dataArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:NSDictionary.class]) {
            NSString *moduleType = [obj hmd_stringForKey:@"module"];
            if (moduleType && [moduleType isEqualToString:@"event"]) {
                NSNumber *sequenceNumber = [obj hmd_objectForKey:@"seq_no_type" class:NSNumber.class];
                if (sequenceNumber) {
                    count ++;
                    if (minSequenceNumber > sequenceNumber.integerValue) {
                        minSequenceNumber = sequenceNumber.integerValue;
                    }
                    if (maxSequenceNumber < sequenceNumber.integerValue) {
                        maxSequenceNumber = sequenceNumber.integerValue;
                    }
                }
            }
        }
    }];
    
    *eventCount = count;
    NSString *range = nil;
    if (count > 0) {
        range = [NSString stringWithFormat:@"[%lld, %lld] count : %ld", minSequenceNumber, maxSequenceNumber, count];
    }
    
    return range;
}

- (NSInteger)_accumulationOfEventDataWithAppID:(NSString *)appID {
    NSString *tableName = DC_OB(DC_CL(HMDTTMonitorRecord, class), tableName);
    if (!tableName) {
        return -2;
    }
    
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"needUpload";
    condition1.threshold = 1;
    condition1.judgeType = HMDConditionJudgeEqual;

    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"appID";
    condition2.stringValue = appID;
    condition2.judgeType = HMDConditionJudgeEqual;

    NSArray<HMDStoreCondition *> *normalCondition = @[condition1,condition2];
    
    NSInteger count = [[HMDRecordStore shared].database recordCountForTable:tableName andConditions:normalCondition orConditions:nil];
    
    return count;
}

// alog 添加各模块日志之前的内存使用情况
- (void)_recordPerformanceReportMemoryBefore {
    if (hmd_log_enable()) {
        hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
        float appMemory = (float)memoryBytes.appMemory/HMD_MB;
        NSString *beforeMemoryUsageLog = [NSString stringWithFormat:@"app total memory usage before performance data load into memory:%fMB",appMemory];
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr",@"%@",beforeMemoryUsageLog);
    }
}

// alog 添加各个模块之后的内存使用情况
- (void)_recordPerfomanceReportMemoryAfterWithModules:(NSArray *)addedModules {
    if (hmd_log_enable()) {
       hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
       float appMemory = (float)memoryBytes.appMemory/HMD_MB;
       NSMutableArray *reportingModules = [NSMutableArray array];
       [addedModules enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           NSString *desc = [obj description];
           if (desc) {
               [reportingModules hmd_addObject:desc];
           }
       }];
       NSString *modulesLog = [reportingModules componentsJoinedByString:@";"];
       NSString *afterMemoryUsage = [NSString stringWithFormat:@"app total memory usage after performance data load into memory:%fMB,uploading modules:%@",appMemory, modulesLog];
       HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr",@"%@",afterMemoryUsage);
   }
}

#pragma mark --- 上报 debugReal
- (void)reportDebugRealPerformanceDataWithConfig:(HMDDebugRealConfig *)config
{
    hmd_safe_dispatch_async(self.reportorQueue, ^{
        [self _reportDebugRealPerformanceDataWithConfig:config];
    });
}

- (void)__attribute__((annotate("oclint:suppress[block captured instance self]"))) _reportDebugRealPerformanceDataWithConfig:(HMDDebugRealConfig *)config {
#if !RANGERSAPM
    if (self.isUploading || ![self checkServerAvailable]) {
        return;
    }
    
    HMDPerformanceReporter *reporter = [self _getReporterSafeWithAppID:[HMDInjectedInfo defaultInfo].appID];
    if (!reporter) return;
    
    NSArray<id<HMDPerformanceReporterDataSource>> *modules = reporter.allReportingModules;
    
    NSMutableArray *allDebugRealData = [NSMutableArray array];
    NSMutableArray *addedModules = [NSMutableArray new];

    for (id<HMDPerformanceReporterDataSource> module in modules) {
        if ([module respondsToSelector:@selector(debugRealPerformanceDataWithConfig:)]) {
            [addedModules addObject:module];
            [allDebugRealData addObjectsFromArray:[module debugRealPerformanceDataWithConfig:config]];
        }
    }
    
    if (allDebugRealData.count < 1) {
        self.isUploading = NO;
        return;
    }
    
    NSString *requestURL = [HMDURLManager URLWithProvider:self forAppID:[HMDInjectedInfo defaultInfo].appID];
    if (requestURL == nil) {
        self.isUploading = NO;
        return;
    }
    
    self.isUploading = YES;
    
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    [body setValue:allDebugRealData forKey:@"data"];
    [body setValue:[HMDUploadHelper sharedInstance].headerInfo forKey:@"header"];
    
    id maybeDictionary = [HMDInjectedInfo defaultInfo].commonParams;
    if (!HMDIsEmptyDictionary(maybeDictionary)) {
        NSString *queryString = [[HMDInjectedInfo defaultInfo].commonParams hmd_queryString];
        requestURL = [NSString stringWithFormat:@"%@?%@", requestURL, queryString];
    }
    
    NSMutableDictionary * headerDict = [NSMutableDictionary dictionaryWithCapacity:2];
    [headerDict setValue:@"application/json; encoding=utf-8" forKey:@"Content-Type"];
    [headerDict setValue:@"application/json" forKey:@"Accept"];
    [headerDict setValue:@"1" forKey:@"Version-Code"];
    [headerDict setValue:@"2085" forKey:@"sdk_aid"];
    
    HMDNetworkReqModel *reqModel = [HMDNetworkReqModel new];
    reqModel.requestURL = requestURL;
    reqModel.method = @"POST";
    reqModel.headerField = [headerDict copy];
    reqModel.params = body;
    reqModel.needEcrypt = [self shouldEncrypt];
    
    [[HMDNetworkManager sharedInstance] asyncRequestWithModel:reqModel callback:^(NSError *error, id maybeDictionary)
     {
         hmd_safe_dispatch_async(self.reportorQueue, ^{
             NSDictionary *decryptedDict = nil;
             NSInteger statusCode = error ? error.code : 0;
             
             if ([maybeDictionary isKindOfClass:[NSDictionary class]]) {
                 NSString *base64String = [[maybeDictionary hmd_dictForKey:@"result"] hmd_stringForKey:@"data"];
                 NSData *encyptedData = [base64String dataUsingEncoding:NSUTF8StringEncoding];
                 //ran is the key for aes
                 NSString *ran = [maybeDictionary hmd_stringForKey:@"ran"];
                 if(ran != nil && [ran isKindOfClass:[NSString class]]){
                     decryptedDict = [HeimdallrUtilities payloadWithDecryptData:encyptedData withKey:ran iv:ran];
                 }
                 statusCode = [maybeDictionary hmd_integerForKey:@"status_code"];
             }
             
             HMDServerState serverState = [self checkErrorCodeAndDebugRealWithResponse:decryptedDict statusCode:statusCode addedReporters:@[reporter] addedModules:[addedModules copy] hmdreporter:HMDReporterCloudCommandDebugReal appID:[HMDInjectedInfo defaultInfo].appID];

             [reporter clearRecordCountAfterReportingSuccessfully];
             
             if ((serverState & HMDServerStateSuccess) == HMDServerStateSuccess) {
                 for (id module in modules) {
                     if ([module respondsToSelector:@selector(cleanupPerformanceDataWithConfig:)]) {
                         [module cleanupPerformanceDataWithConfig:config];
                     }
                 }
                 hmdDebugRealReportClearDataALog();
            }
             
             self.isUploading = NO;
         });
     }];
#endif
}

- (void)excuteCloudCommandIfAvailable:(NSData *)commandData ran:(NSString *)ran{
#if !RANGERSAPM
    DC_OB(DC_CL(HMDCloudCommandManager, sharedInstance), executeCommandWithData:ran:, commandData, ran);
#else
    DC_OB(DC_CL(AWECloudCommandManager, sharedInstance), executeCommandWithData:ran:, commandData, ran);
#endif
}

- (NSArray *)allDebugRealPeformanceDataWithConfig:(HMDDebugRealConfig *)config
{
    NSMutableArray *allDebugRealData = [NSMutableArray array];
    HMDPerformanceReporter *reporter = [self _getReporterSafeWithAppID:[HMDInjectedInfo defaultInfo].appID];
    if (!reporter) return allDebugRealData;
    
    dispatch_sync(self.reportorQueue, ^{
        NSArray<id<HMDPerformanceReporterDataSource>> *modules = reporter.allReportingModules;
        for (id<HMDPerformanceReporterDataSource> module in modules) {
            if ([module respondsToSelector:@selector(debugRealPerformanceDataWithConfig:)]) {
                @autoreleasepool {
                    [allDebugRealData addObjectsFromArray:[module debugRealPerformanceDataWithConfig:config]];
                }
            }
        }
    });
    return allDebugRealData;
}

#pragma mark --- 解析返回结果
// 判断是否进入容灾策略
// doc https://bytedance.feishu.cn/docs/doccnmOYpBUZAVSWunfBfCqwCic#
- (HMDServerState)checkErrorCodeAndDebugRealWithResponse:(id)jsonObj
                                              statusCode:(NSInteger)statusCode
#if !RANGERSAPM
                                          addedReporters:(NSArray<HMDPerformanceReporter *> *)addedReporters
                                            addedModules:(NSArray<id<HMDPerformanceReporterDataSource>>*)addedModules
                                             hmdreporter:(HMDReporter)hmdreporter
                                                   appID:(NSString *)appID {
#else
                                          addedReporters:(NSArray<HMDPerformanceReporter *> *)addedReporters {
#endif
    NSDictionary *result = (NSDictionary*)jsonObj;
#if !RANGERSAPM
    HMDServerState serverState = hmd_update_server_checker_sdk(hmdreporter, appID, result, statusCode);
#else
    HMDServerState serverState = [self.serverStateChecker updateStateWithResult:result statusCode:statusCode];
#endif
    NSMutableArray<id<HMDPerformanceReporterDataSource>> *modules = [NSMutableArray new];
    
    pthread_rwlock_rdlock(&_rwlock);
    NSDictionary *reporterDic = [self.reporters copy];
    pthread_rwlock_unlock(&_rwlock);
    
    for (HMDPerformanceReporter *reporter in reporterDic.allValues) {
        if (reporter.allReportingModules.count) {
            [modules addObjectsFromArray:reporter.allReportingModules];
        }
    }

    // 成功
    if ((serverState & HMDServerStateSuccess) == HMDServerStateSuccess) {
        [[NSNotificationCenter defaultCenter] postNotificationName:HMDPerformanceReportSuccessNotification object:addedReporters];
    }

    // drop data
    if ((serverState & HMDServerStateDropData) == HMDServerStateDropData) {
#if RANGERSAPM
        for (id<HMDPerformanceReporterDataSource> module in modules) {
            if ([module respondsToSelector:@selector(setDropData:)]) {
                module.dropData = YES;
            }
        }
#endif
        hmdPerfDropDataALog();
    }
    // drop all data
    else if ((serverState & HMDServerStateDropAllData) == HMDServerStateDropAllData) {
#if !RANGERSAPM
        for (id<HMDPerformanceReporterDataSource> module in addedModules) {
#else
        for (id<HMDPerformanceReporterDataSource> module in modules) {
            if ([module respondsToSelector:@selector(setDropData:)]) {
                module.dropData = YES;
            }
#endif
            if ([module respondsToSelector:@selector(dropAllDataForServerState)]) {
                [module dropAllDataForServerState];
            }
#if !RANGERSAPM
            if ([module respondsToSelector:@selector(dropAllDataForServerStateWithAid:)]) {
                [module dropAllDataForServerStateWithAid:appID];
            }
#endif
        }
        hmdPerfDropAllDataALog();
    }
#if RANGERSAPM
    // 设置drop data 为NO
    else {
        for (id<HMDPerformanceReporterDataSource> module in modules) {
            if ([module respondsToSelector:@selector(setDropData:)]) {
                module.dropData = NO;
            }
        }
    }
#endif
    
    if ([result isKindOfClass:[NSDictionary class]]) {
        NSDictionary *configs = [result valueForKey:@"configs"];
        NSDictionary *debugSettings = [configs valueForKey:@"debug_settings"];
        
        //performance & exception upload check
        BOOL needDebugRealUpload = [debugSettings hmd_boolForKey:@"should_submit_debugreal"];
        if (needDebugRealUpload) {
            HMDDebugRealConfig *config = [[HMDDebugRealConfig alloc] initWithParams:debugSettings];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self reportDebugRealPerformanceDataWithConfig:config];
                [[HMDExceptionReporter sharedInstance] reportDebugRealExceptionData:config exceptionTypes:@[@(HMDDefaultExceptionType)]];
            });
        }
    }
    
    return serverState;
}
    
#pragma - mark Enter Background
- (void)__attribute__((annotate("oclint:suppress[block captured instance self]")))handleBackgroundNotification:(NSNotification *)notification {
    pthread_rwlock_t *rwlock = &_rwlock;
    [HMDSimpleBackgroundTask detachBackgroundTaskWithName:HMDPerformanceReportBackgroundTask
                                               expireTime:30.0
                                                     task:^(void (^ _Nonnull completeHandle)(void)) {
        pthread_rwlock_rdlock(rwlock);
        NSArray *reporters = self.reporters.allValues;
        pthread_rwlock_unlock(rwlock);
        
        for (HMDPerformanceReporter *reporter in reporters) {
            if (reporter.allReportingModules.count) {
                for (id<HMDPerformanceReporterDataSource> module in reporter.allReportingModules) {
                    if ([module respondsToSelector:@selector(saveEventDataToDiskWhenEnterBackground)]) {
                        [module saveEventDataToDiskWhenEnterBackground];
                    }
                }
            }
        }
        
        [self _reportPerformanceDataIfAllowedWithAppID:[self _getHostAppID] reporterType:HMDPerformanceReporterBackground singleReporter:nil block:^(BOOL success) {
            if (completeHandle) completeHandle();
        }];
    }];
}

- (void)triggerAllReporterUpload {
    pthread_rwlock_rdlock(&_rwlock);
    NSMutableDictionary<NSString *,HMDPerformanceReporter *> *reporters = [self.reporters copy];
    [reporters enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, HMDPerformanceReporter * _Nonnull obj, BOOL * _Nonnull stop) {
        [self reportDataWithReporter:obj block:NULL];
    }];
    pthread_rwlock_unlock(&_rwlock);
}

#pragma - mark Private
- (HMDPerformanceReporter *)_getReporterSafeWithAppID:(NSString *)appID {
    HMDPerformanceReporter *reporter = nil;
    
    if (!appID) {
        return reporter;
    }
    
    pthread_rwlock_rdlock(&_rwlock);
    reporter = [self.reporters hmd_objectForKey:appID class:HMDPerformanceReporter.class];
    pthread_rwlock_unlock(&_rwlock);
    
    return reporter;
}

- (NSString * _Nullable)_getHostAppID {
    NSString *appID = [HMDInjectedInfo defaultInfo].appID;
    if (!appID) {
        pthread_rwlock_rdlock(&_rwlock);
        NSArray *appIDArray = self.reporters.allKeys;
        pthread_rwlock_unlock(&_rwlock);

        if (appIDArray.count) {
            appID = appIDArray.firstObject;
        }
    }
    return appID;
}

- (NSArray *)performanceDataWithDowngradeFilter:(NSArray *)originArray {
    // 如果未开启分通道降级功能，则直接返回originArray
    if (![HMDReportDowngrador sharedInstance].enabled) return originArray;
    
    CFTimeInterval currentTime = CFAbsoluteTimeGetCurrent();
    NSMutableArray *result = @[].mutableCopy;
    [originArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *logType = [obj hmd_stringForKey:@"log_type"];
#if !RANGERSAPM
        NSString *serviceName = [obj hmd_stringForKey:@"service"];
        NSString *aid = [obj hmd_stringForKey:@"aid"];
#else
        NSDictionary *payload = [obj hmd_dictForKey:@"payload"];
        //自定义埋点上报 ToB 使用的是 'event_log'，但内部使用的是 service_monitor，容灾这里 ToB 和内部使用相同协议，因此这里做一下转化
        if ([logType isEqualToString:@"event_log"]) {
            logType = @"service_monitor";
        }
        NSString *serviceName = [payload hmd_stringForKey:@"event_name"];
        NSString *aid = [payload  hmd_stringForKey:@"aid"];
        if (!aid) {
            aid = [HMDInjectedInfo defaultInfo].appID;
        }
#endif
        BOOL needUpload = [[HMDReportDowngrador sharedInstance] needUploadWithLogType:logType serviceName:serviceName aid:aid currentTime:currentTime];
        if (needUpload) [result addObject:obj];
    }];
    return result;
}

@end
