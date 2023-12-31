//
//  HMDTTMonitorTracker2.m
//  Heimdallr
//
//  Created by 崔晓兵 on 16/3/2022.
//

#import "HMDTTMonitorTracker2.h"
#import "HMDTTMonitorUserInfo.h"
#import "HMDTTMonitorTracker.h"
#import "HMDTTMonitorHelper.h"
#import "HMDTTMonitorCounter.h"
#import "HMDTTMonitorRecord.h"
#import "NSObject+HMDValidate.h"
#import "HMDALogProtocol.h"
#import "HMDNetworkHelper.h"
#import "HMDMonitorDataManager2.h"
#import "HMDGCD.h"
#import "HMDInjectedInfo.h"
#import "HMDTTMonitorTagHelper.h"
#import "HMDHermasHelper.h"
#import "HMDHermasManager.h"
#import "HMDReportDowngrador.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDDynamicCall.h"
#import "HMDMacro.h"
#import "HMDInjectedInfo+PerfOptSwitch.h"
#import "HMDTTMonitorInterceptorParam.h"
#import "HMDHeimdallrConfig+Private.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

extern NSString *const kHMDTTMonitorServiceLogTypeStr;

@interface HMDTTMonitorTracker2()<HMDTTMonitorOfflineCheckPointProtocol, HMDTTMonitorTraceProtocol>
@property (nonatomic, strong) HMDTTMonitorCounter *counter;
@property (nonatomic, strong) dispatch_queue_t syncQueue;
@property (nonatomic, strong) HMDMonitorDataManager2 *dataManager;
@property (nonatomic, strong) HMInstance *instance;
@property (nonatomic, strong) HMInstance *highPriorityInstance;
@end

@implementation HMDTTMonitorTracker2

@synthesize ignoreLogType;

+ (dispatch_queue_t)globalSyncQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.heimdallr.hmdttmonitor.syncQueue", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

- (instancetype)initMonitorWithAppID:(NSString *)appID injectedInfo:(HMDTTMonitorUserInfo *)info {
    self = [super init];
    if (self) {
        self.dataManager = [[HMDMonitorDataManager2 alloc] initMonitorWithAppID:appID injectedInfo:info];
        self.syncQueue = [self.class globalSyncQueue];
        self.counter = [[HMDTTMonitorCounter alloc] initCounterWithAppID:self.dataManager.appID];
        
        if ([HMDInjectedInfo defaultInfo].ttMonitorSampleOptEnable) {
            [HMDTTMonitorHelper registerCrashCallbackToLog];
        }
        
        hmd_safe_dispatch_async(self.syncQueue, ^{
            [HMDHermasManager defaultManager];
            if ([appID isEqualToString:[HMDInjectedInfo defaultInfo].appID]) {
                self.instance = [HMDHermasManager sharedPerformanceInstance];
                self.highPriorityInstance = [HMDHermasManager sharedHighPriorityInstance];
            } else {
                self.instance = [[HMEngine sharedEngine] instanceWithModuleId:kModulePerformaceName aid:appID];
                self.highPriorityInstance = [[HMEngine sharedEngine] instanceWithModuleId:kModuleHighPriorityName aid:appID];
            }
            
            __weak typeof(self) weakSelf = self;
            if (self.instance.sequenceNumberGenerator == nullptr) {
                self.instance.sequenceNumberGenerator = ^int64_t{
                    return [weakSelf.counter generateSequenceNumber];
                };
            }
           
            self.dataManager.stopCacheBlock = ^() {
                // 将缓存数据存入
                hmd_safe_dispatch_async(weakSelf.syncQueue, ^{
                    [weakSelf.instance stopCache];
                });
            };
      
            // Hermas的清理机制有自己的时钟，不需要在切后台的时候清理数据，所以这里的通知逻辑直接移除掉。
            HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker initialize with manager : %@", self.dataManager ? self.dataManager.appID : @"nil");
        });
        
    }
    return self;
}

- (BOOL)performanceDataSource {
    return NO;
}

- (void)trackDataWithParam:(HMDTTMonitorInterceptorParam *)params {
    // 排查问题临时将事件的 serviceName、logType、appId 写入Alog
    if ([HMDInjectedInfo defaultInfo].ttMonitorSampleOptEnable) {
        [HMDTTMonitorHelper saveLatestLogWithServiceName:params.serviceName logType:params.logType appID:params.appID];
    } else {
        HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace_ServiceName", @"HMDTTMonitorTracker（serviceName、logType、appID) write to alog : serviceName = %@, logType = %@, appID = %@", params.serviceName, params.logType, params.appID);
    }
    
    if ([self respondsToSelector:@selector(recordDataGeneratedCheckPointWithServiceName:logType:data:)]) {
        [self recordDataGeneratedCheckPointWithServiceName:params.serviceName logType:params.logType data:params.wrapData];
    }
    
    NSInteger uniqueCode = [self.counter generateUniqueCode];
    if ([self respondsToSelector:@selector(recordGeneratedCheckPointWithlogType:serviceType:appID:actionType:uniqueCode:)]) {
        [self recordGeneratedCheckPointWithlogType:params.logType serviceType:params.serviceName appID:params.appID actionType:params.storeType uniqueCode:uniqueCode];
    }
    
    NSAssert(params.appID != nil,@"The appID cannot be nil!");
    // 当 service 有值的时候, 才去判断是否覆盖了
    if (params.serviceName && params.serviceName.length > 0) {
        params.wrapData = [HMDTTMonitorHelper filterTrackerReservedKeysWithDataDict:params.wrapData];
    }
    
#ifdef DEBUG
    NSMutableString *str = [NSMutableString string];
    if(![params.wrapData hmd_performValidate:(CAValidateType)(CAValidateTypeJSON | CAValidateTypeImmutable) saveResult:str prefixBlank:0 increaseblank:4]) {
        const char *warningStringBegin =
        " -------------------------------------------------------------------------------------- \n"
        "          HMDTTMonitor customizes types of incoming records   Check report\n"
        " -------------------------------------------------------------------------------------- \n";
        const char *warningStringEnd =
        " -------------------------------------------------------------------------------------- \n"
        "     Immutable incoming type - JSON detection failed, which may result in online CRASH  \n"
        " -------------------------------------------------------------------------------------- \n";
        NSString *serviceInfo =
        [NSString stringWithFormat:@"logType: %@; serviceName: %@;\n",params.logType, params.serviceName];
        HMDPrint("%s%s%s%s", warningStringBegin, serviceInfo.UTF8String, str.UTF8String, warningStringEnd);
    }
#endif
    BOOL isConfirmCoding = NO;
    if ([HMDInjectedInfo defaultInfo].ttmonitorCodingProtocolOptEnabled) {
        isConfirmCoding = [HMDTTMonitorHelper fastCheckDictionaryDataFormat:params.wrapData];
    } else {
        isConfirmCoding = [HMDTTMonitorHelper checkDictionaryDataFormat:params.wrapData];
    }
    // 判断打点数据是否都满足实现 NSCoding 协议
    if (!isConfirmCoding) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker : Service(%@) is not response NSCoding protocol, appid : %@", params.serviceName, params.appID ?: @"");
        return;
    }

    // 判断一个对象能否转换成JSON对象，如果不能则不往数据库存储
    BOOL isValidJson = NO;
    try {
        isValidJson = [NSJSONSerialization isValidJSONObject:params.wrapData];
    } catch (NSException *exception) {
        isValidJson = NO;
    }
    if (!isValidJson) {
        NSAssert(false,@"TTMonitor - The data of the event tracing cannot satisfy isValidJSONObject.");
        HMDALOG_PROTOCOL_ERROR_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker : Service(%@) is valid json object, appid : %@", params.serviceName, params.appID ?: @"");
        return;
    }
    
    BOOL isHighPriority = NO;
    if (![HMDInjectedInfo defaultInfo].ttMonitorSampleOptEnable) {
        // 高保事件单独用一个接口，独立容灾
        isHighPriority = [self isHighPriorityWithLogType:params.logType serviceType:params.serviceName];
        if (isHighPriority) {
            params.storeType = HMDTTmonitorHighPriotityIgnoreSampling;
            if (hermas_drop_data_sdk(kModuleHighPriorityName, params.appID)) {
                HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker high priority eventData write to alog after dropdata : serviceName = %@, logType = %@, data = %@", params.serviceName, params.logType, params.wrapData);
                return;
            }
        } else {
            if (hermas_drop_data_sdk(kModulePerformaceName, params.appID)) {
                HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker eventData write to alog after dropdata : serviceName = %@, logType = %@, data = %@", params.serviceName, params.logType, params.wrapData);
                return;
            }
        }
        
        // check if the data hit downgrade rule (the priority of downgrade is greater than the sampling ratio)
        BOOL isDownGrade = [[HMDReportDowngrador sharedInstance] needUploadWithLogType:params.logType serviceName:params.serviceName aid:params.appID];
        if (!isDownGrade) {
            return;
        }
    }
    
    NSMutableDictionary *tmpData = [[NSMutableDictionary alloc] initWithDictionary:params.wrapData];
    if (![tmpData objectForKey:@"network_type"]) {
        [tmpData setValue:@([HMDNetworkHelper connectTypeCode]) forKey:@"network_type"];
    }

    HMDTTMonitorRecord *record = [HMDTTMonitorRecord newRecord];
    // #warning:sdkversion在header中有了，日志内容还要保存吗
    if (self.dataManager.injectedInfo) {
        record.sdkVersion = self.dataManager.injectedInfo.sdkVersion;
    }
    record.extra_values = tmpData;
    record.log_type = params.logType;
    record.service = params.serviceName;
    record.log_id = [HMDTTMonitorHelper generateLogID];  // 暂时不知道有啥用
    record.appID = params.appID;
    record.uniqueCode = uniqueCode;
    record.customTag = [HMDTTMonitorTagHelper getMonitorTag];
    
    if ([HMDInjectedInfo defaultInfo].ttMonitorSampleOptEnable) {
        record.needUpload = params.needUpload;
        record.traceParent = params.traceParent;
        record.singlePointOnly = params.singlePointOnly;
    } else {
        [self setMovingLineAndNeedUploadForRecord:record isHighPriority:isHighPriority storeType:params.storeType];
        
        if ([HMDInjectedInfo defaultInfo].stopWriteToDiskWhenUnhit && !record.needUpload && !record.singlePointOnly) {
            return;
        }
    }
    
    hmd_safe_dispatch_async(self.syncQueue, ^{
        @try {
            switch (params.storeType) {
                case HMDTTmonitorStoreActionNormal:
                case HMDTTmonitorStoreActionStoreImmediately: {
                    // 未获得采样率前，先缓存数据，等待获取到采样率后，再更新needupload
                    if (self.dataManager.needCache) {
                        [self.instance recordCache:record.reportDictionary];
                    }
                    else {
                        // 先停止写cache，Hermas内部会把cache的数据读出来
                        [self.instance stopCache];
                        
                        BOOL is_service_monitor = [params.logType isEqualToString:kHMDTTMonitorServiceLogTypeStr];
                        if (record.needUpload && is_service_monitor) {
                            record.sequenceNumber = [self.counter generateSequenceNumber];
                        }
                        BOOL forceSave = record.singlePointOnly;
                        [self.instance recordData:record.reportDictionary priority:HMRecordPriorityDefault forceSave:forceSave];
                        
                        if ([self respondsToSelector:@selector(recordCachedCheckPointWithServiceName:data:)]) {
                            [self recordCachedCheckPointWithServiceName:record.service data:record.extra_values];
                        }
                        
                    }
                    break;
                }
                
                case HMDTTmonitorStoreActionUploadImmediatelyIfNeed:{
                    if (!self.dataManager.needCache && !record.needUpload) break;
                }
                case HMDTTmonitorStoreActionUploadImmediately:{
                    record.sequenceNumber = [self.counter generateSequenceNumber];
                    [self.instance recordData:record.reportDictionary priority:HMRecordPriorityRealTime];
                    break;
                }
                case HMDTTmonitorHighPriotityIgnoreSampling:{
                    record.sequenceNumber = [self.counter generateSequenceNumber];
                    [self.highPriorityInstance recordData:record.reportDictionary];
                }
                
                default:
                    break;
            }
        }
        @catch (NSException *exception) {
        }
        @finally {
            
        }
    });
}

- (void)countEvent:(NSString *)type label:(NSString *)label value:(float)value needAggregate:(BOOL)needAggr appID:(NSString *)appID {
    // do nothing
}

- (void)timerEvent:(NSString *)type label:(NSString *)label value:(float)value needAggregate:(BOOL)needAggr appID:(NSString *)appID {
    // do nothing
}
                            
- (HMDHeimdallrConfig *)customConfig {
    return self.dataManager.config;
}
                            

- (BOOL)ttmonitorConfigurationAvailable {
    return self.customConfig.configurationAvailable;
}

- (BOOL)needUploadWithlogTypeStr:(NSString *)logTypeStr serviceType:(NSString *)serviceType {
    return [self needUploadWithLogTypeStr:logTypeStr serviceType:serviceType data:nil];
}

- (BOOL)needUploadWithLogTypeStr:(NSString *)logTypeStr serviceType:(NSString *)serviceType data:(NSDictionary *)data {
    BOOL needUpload = NO;
    if ([logTypeStr isEqualToString:kHMDTTMonitorServiceLogTypeStr] && serviceType) {
        // fixme : For MT's ttlive events only
        if (self.ignoreLogType && [serviceType hasPrefix:@"ttlive_"]) {
            needUpload = [self serviceTypeEnabled:serviceType];
        } else if ([serviceType hasPrefix:@"hermas_refactor"]) {
            needUpload = YES;
        } else {
            needUpload = [self logTypeEnabled:logTypeStr] && [self serviceTypeEnabled: serviceType];
        }
    } else {
        needUpload = [self.customConfig logTypeEnabled:logTypeStr];
        if (needUpload && data) {
            needUpload = [self.customConfig customLogTypeEnable:logTypeStr withMonitorData:data];
        }
    }
    
    return needUpload;
}

- (BOOL)logTypeEnabled:(NSString *)logType {
    return [self.customConfig logTypeEnabled:logType];
}

- (BOOL)serviceTypeEnabled:(NSString *)serviceType {
    return [self.customConfig serviceTypeEnabled:serviceType];
}

- (BOOL)isHighPriorityWithLogType:(NSString *)logTypeStr serviceType:(NSString *)serviceType {
    BOOL isHighPriority = NO;
    if ([logTypeStr isEqualToString:kHMDTTMonitorServiceLogTypeStr] && serviceType) {
        isHighPriority = [self isHighPriorityWithService:serviceType];
    } else if (logTypeStr) {
        isHighPriority = [self isHighPriorityWithLogType:logTypeStr];
    }
    
    return isHighPriority;
}

- (BOOL)isHighPriorityWithLogType:(NSString *)logType {
    return [self.customConfig logTypeHighPriorityEnable:logType];
}

- (BOOL)isHighPriorityWithService:(NSString *)service {
    return [self.customConfig serviceHighPriorityEnable:service];
}

#pragma - mark HMDTTMonitorTraceProtocol
                            
// 记录record生产成功
- (void)recordGeneratedCheckPointWithlogType:(NSString *)logTypeStr
                                 serviceType:(NSString*)serviceType
                                       appID:(NSString *)appID
                                  actionType:(HMDTTMonitorStoreActionType)actionType
                                  uniqueCode:(int64_t)uniqueCode
{
    if (!self.customConfig.enableEventTrace) return;
    
    HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitorTracker event log type : %@, service type : %@, app id : %@, action type : %ld, unique code : %lld", logTypeStr, serviceType ?: @"", appID ?: @"", actionType, uniqueCode);
}

// recordSavedCheckPointWithRecords记录了落盘成功后，落盘记录没了，理解需要在hermas recorder记录后添加Alog

// recordFetchedCheckPointWithRecords记录数据获取成功， 数据获取不在这做，下掉此Alog日志

# pragma mark - movingline
- (void) setMovingLineAndNeedUploadForRecord:(HMDTTMonitorRecord *)record isHighPriority:(BOOL)isHighPriority storeType:(HMDTTMonitorStoreActionType)storeType {
    // movingline
    NSDictionary *extra = [NSDictionary dictionary];
    NSString *traceParent;
    BOOL isTraceParentHit = NO;
    BOOL isMovingLine = NO;
    
    if (record.extra_values) {
        extra = [record.extra_values hmd_dictForKey:@"extra"];
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
    
    BOOL needUpload = isHighPriority || [self needUploadWithLogTypeStr:record.log_type serviceType:record.service data:record.extra_values] || storeType == HMDTTmonitorStoreActionUploadImmediately;
    
    BOOL enableCacheMovingLineUnHitLog = NO;
    enableCacheMovingLineUnHitLog = [DC_OB(DC_CL(HMDOTManagerConfig, defaultConfig), GetEnableCacheUnHitLogStrValue) boolValue];
    enableCacheMovingLineUnHitLog = enableCacheMovingLineUnHitLog && isMovingLine;
    
    NSInteger singlePointOnly = 0;
    BOOL needUpdateSinglePointOnly = isTraceParentHit || (isMovingLine && !isTraceParentHit && enableCacheMovingLineUnHitLog);
    
    if (!needUpload && needUpdateSinglePointOnly && storeType != HMDTTmonitorStoreActionUploadImmediately) {
        singlePointOnly = 1;
    }
    
    record.needUpload = needUpload || isTraceParentHit;
    record.traceParent = traceParent;
    record.singlePointOnly = singlePointOnly;
}
@end
