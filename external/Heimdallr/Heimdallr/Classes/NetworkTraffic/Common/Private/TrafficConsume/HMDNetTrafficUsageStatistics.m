//
//  HMDNetTrafficUsageManager.m
//  AWECloudCommand
//
//  Created by zhangxiao on 2020/8/17.
//

#import "HMDNetTrafficUsageStatistics.h"
#import "HMDNetTrafficSourceUsageModel.h"
#import "HMDNetTrafficFreqRequestTool.h"
#import "HMDNetworkReachability.h"
#import "NSDictionary+HMDJSON.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDNetTrafficMonitor.h"
#include "pthread_extended.h"
#import "NSString+HMDJSON.h"
#import "NSArray+HMDSafe.h"
#import "HMDALogProtocol.h"
#import "HMDDynamicCall.h"
#import <TTReachability/TTReachability.h>
#import "HMDMacro.h"
#import "HMDGCD.h"
#import "NSDictionary+HMDSafe.h"

#define kHMDNetTrafficSingleUsageInfoCacheCount 50
#define kHMDNetTrafficBizSouceIdCacheCount 10
#define kHMDNetTrafficBizUsageDetailCacheCount 10

typedef NS_ENUM(NSUInteger, HMDNetTrafficUsageBytesAddType) {
    HMDNetTrafficUsageBytesIncrement,  // 增加型, 传入的是增加的量
    HMDNetTrafficUsageBytesAccumulate, // 累积型, 传入的是累积的总量
};

typedef NS_ENUM(NSUInteger, HMDNetTrafficeUsageSourceType) {
    /// 业务自己注入的
    HMDNetTrafficeUsageTypeBussiness,
    /// 网络请求
    HMDNetTrafficeUsageTypeRequest,
    /// 图片
    HMDNetTrafficeUsageTypeImage,
};

static NSString *const kHMDNetTrafficCollectorProcess = @"hmd_all";
static NSString *const kHMDNetTrafficCollectorInterval = @"hmd_interval";

#pragma mark--- 异常流量监控配置 ---
@interface HMDNetTrafficUsageManagerConfig : NSObject

@property (nonatomic, assign) unsigned long long requestBytesThreshold;
@property (nonatomic, assign) unsigned long long imageBytesThreshold;
@property (nonatomic, assign) int requestFreqThreshold;

@end

@implementation HMDNetTrafficUsageManagerConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        self.requestBytesThreshold = (10 * HMD_MB);
        self.imageBytesThreshold = (50 * HMD_MB);
        self.requestFreqThreshold = 100;
    }
    return self;
}

@end

#pragma mark------ HMDNetTrafficUsageManager ------

@interface HMDNetTrafficUsageStatistics ()

/// 总的统计信息
@property (nonatomic, strong) NSMutableDictionary *totalBizUsage;
/// 业务方注入的使用信息
@property (nonatomic, strong) NSCache *bizSourceCache;
/// 大请求
@property (nonatomic, strong) NSMutableArray *largReqInfoes;
/// 间隔的统计
@property (nonatomic, strong) NSMutableDictionary *intervalBizUsage;
/// 高频请求
@property (nonatomic, strong) HMDNetTrafficFreqRequestTool *freqTool;
@property (nonatomic, strong) HMDNetTrafficUsageManagerConfig *thresholdConfig;

@property (nonatomic, assign) BOOL isWorking;
@property (nonatomic, strong) dispatch_queue_t operationQueue;
@property (atomic, assign) HMDNetTrafficSourceNetType netType;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary *> *trafficInfoCollectors;

@end

@implementation HMDNetTrafficUsageStatistics

#pragma mark --- life cycle
- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupData];
    }
    return self;
}

- (instancetype)initWithOperationQueue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        _operationQueue = queue;
        [self setupData];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupData {
    if (!self.operationQueue) {
        self.operationQueue = dispatch_queue_create("com.heimdallr.net.traffic.usage", DISPATCH_QUEUE_SERIAL);
    }
    self.isWorking = NO;
    self.thresholdConfig = [[HMDNetTrafficUsageManagerConfig alloc] init];

    self.bizSourceCache = [[NSCache alloc] init];
    self.bizSourceCache.countLimit = kHMDNetTrafficSingleUsageInfoCacheCount;

    self.largReqInfoes = [NSMutableArray array];
    self.totalBizUsage = [NSMutableDictionary dictionary];
    self.freqTool = [[HMDNetTrafficFreqRequestTool alloc] init];
    self.totalBizUsage = [NSMutableDictionary dictionary];
    self.intervalBizUsage = [NSMutableDictionary dictionary];

    self.trafficInfoCollectors = [NSMutableDictionary dictionaryWithDictionary:@{
        kHMDNetTrafficCollectorProcess: self.totalBizUsage?:@{}.mutableCopy,
        kHMDNetTrafficCollectorInterval: self.intervalBizUsage?:@{}.mutableCopy
    }];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hmdDidReciveMemoryWarning:)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkStatusChangedNotification:)
                                                 name:TTReachabilityChangedNotification
                                               object:nil];
}

#pragma mark --- NetType Check
- (void)networkStatusChangedNotification:(NSNotification *)notification {
    dispatch_async(self.operationQueue, ^{
        if ([HMDNetworkReachability isWifiConnected]) {
            self.netType = self.isBackground ? HMDNetTrafficSourceNetTypeWiFiBack : HMDNetTrafficSourceNetTypeWiFiFront;
        } else {
            self.netType = self.isBackground ? HMDNetTrafficSourceNetTypeMobileBack : HMDNetTrafficSourceNetTypeMobileFront;
        }
    });
}

- (void)setIsBackground:(BOOL)isBackground {
    _isBackground = isBackground;
    dispatch_async(self.operationQueue, ^{
        if ([HMDNetworkReachability isWifiConnected]) {
            self.netType = isBackground ? HMDNetTrafficSourceNetTypeWiFiBack : HMDNetTrafficSourceNetTypeWiFiFront;
        } else {
            self.netType = isBackground ? HMDNetTrafficSourceNetTypeMobileBack : HMDNetTrafficSourceNetTypeMobileFront;
        }
    });
}

- (void)updateTrafficConfig:(HMDNetTrafficMonitorConfig *)config {
    BOOL enableCollect = config.enableBizTrafficCollect;
    dispatch_async(self.operationQueue, ^{
        if (self.isWorking && !enableCollect) {
            [self resetStatisticsData];
        }
        self.isWorking = enableCollect;
        self.freqTool.frequencyThreashold = config.highFreqRequestThreshold;
        self.thresholdConfig.requestFreqThreshold = config.highFreqRequestThreshold;
        self.thresholdConfig.requestBytesThreshold = config.largeRequestThreshold;
        self.thresholdConfig.imageBytesThreshold = config.largeImageThreshold;
    });
}

#pragma mark --- traffic collect
- (void)networkTrafficUsageWithURL:(NSString *)url
                         sendBytes:(unsigned long long)sendBytes
                         recvBytes:(unsigned long long)recvBytes
                        clientType:(NSString *)clientType
                          MIMEType:(NSString *)MIMEType {
    if (!url || url.length == 0) {return;}
    NSString *urlCopy = [url copy];
    NSString *clientCopy = [clientType copy];
    long long timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    HMDNetTrafficSourceNetType currentNetType = self.netType;
    hmd_safe_dispatch_async(self.operationQueue, ^{
        if (!self.isWorking) { return;}
        NSURL *transformURL = [NSURL URLWithString:urlCopy];
        NSString *host = transformURL.host;
        NSString *path = transformURL.path;
        NSString *uniqueKey = [NSString stringWithFormat:@"%@%@", host, path];
        unsigned long long totalUsage = sendBytes + recvBytes;
        HMDNetTrafficeUsageSourceType usageType = HMDNetTrafficeUsageTypeRequest;
        [self aggreateTrafficUsageInfoWithUniqueKey:uniqueKey
                                       trafficUsage:totalUsage
                                          timestamp:timestamp
                                          bussiness:clientCopy
                                 usageCalculateType:HMDNetTrafficUsageBytesIncrement
                                          usageType:usageType
                                     currentNetType:currentNetType];
    });
}

- (void)networkTrafficUsageWithURL:(NSString *)url requestLog:(NSString *)requestLog clientType:(NSString *)clientType MIMEType:(NSString *)MIMEType {
    if (url.length == 0 || requestLog.length == 0) { return; }
    NSString *urlCopy = [url copy];
    NSString *clientCopy = [clientType copy];
    NSString *mimeTypeCopy = [MIMEType copy];
    NSString *requestLogCopy = [requestLog copy];
    hmd_safe_dispatch_async(self.operationQueue, ^{
        if (!self.isWorking) { return; }
        NSDictionary *requestLogJSON = [requestLogCopy hmd_jsonDict];
        NSDictionary *responseDict = requestLogJSON ? ([requestLogJSON hmd_dictForKey:@"response"]) : nil;
        if (responseDict) {
            unsigned long long sendBytes = [responseDict hmd_unsignedLongLongForKey:@"sent_bytes"];
            unsigned long long recvBytes = [responseDict hmd_unsignedLongLongForKey:@"received_bytes"];
            [self networkTrafficUsageWithURL:urlCopy sendBytes:sendBytes recvBytes:recvBytes clientType:clientCopy MIMEType:mimeTypeCopy];
        }
    });
}

#pragma mark--- feature implementation
- (void)hmdBizConsumeWithTrafficBytes:(long long)trafficBytes
                             sourceId:(NSString *)sourceId
                             business:(NSString *)business
                                scene:(NSString *)scene
                          extraStatus:(NSDictionary *)extraStatus
                             extraLog:(NSDictionary *)extraLog
                  isCurrentTotalUsage:(BOOL)isCurrentTotalUsage
                          trafficType:(HMDNetTrafficMonitorTrafficType)trafficType {
    long long timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    HMDNetTrafficSourceNetType currentNetType = self.netType;
    hmd_safe_dispatch_async(self.operationQueue, ^{
        if (!self.isWorking) { return; }
        NSString *uniqueKey = sourceId ?: [NSString stringWithFormat:@"%@_unknown", business];
        NSString *usedScene = scene ? scene : (DC_IS(DC_OB(DC_CL(HMDUITrackerManager, sharedManager), scene), NSString));
        NSString *usedBussiness = trafficType != HMDNetTrafficMonitorLocalTraffic ? business : ([NSString stringWithFormat:@"local_%@", business]);
        if (hmd_log_enable()) {
            NSString *extraStatusStr = [extraStatus hmd_jsonString];
            NSString *extraLogStr = [extraLog hmd_jsonString];
            BOOL isWiFi = [HMDNetworkReachability isWifiConnected];
            NSString *trafficInfoAlog = [NSString stringWithFormat:@"trafficBytes: %lld, sourceId: %@, business: %@, scene:%@, extra_status:%@, extra_log:%@, isWiFi:%@, isTotalUse:%@",
                                                                   trafficBytes,
                                                                   sourceId,
                                                                   business,
                                                                   usedScene,
                                                                   extraStatusStr,
                                                                   extraLogStr,
                                                        isWiFi?@"true":@"false",
                                            isCurrentTotalUsage?@"true":@"false"];
            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"HMDNetTrafficMonitor Traffic consume:%@", trafficInfoAlog);
        }
        HMDNetTrafficUsageBytesAddType addType = isCurrentTotalUsage ? HMDNetTrafficUsageBytesAccumulate : HMDNetTrafficUsageBytesIncrement;
        [self aggreateTrafficUsageInfoWithUniqueKey:uniqueKey
                                       trafficUsage:trafficBytes
                                          timestamp:timestamp
                                          bussiness:usedBussiness
                                 usageCalculateType:addType
                                          usageType:HMDNetTrafficeUsageTypeBussiness
                                     currentNetType:currentNetType];
    });
}

/// 累加当前的流量
- (void)aggreateTrafficUsageInfoWithUniqueKey:(NSString *)sourceId
                                 trafficUsage:(unsigned long long)usageBytes
                                    timestamp:(long long)timestamp
                                    bussiness:(NSString *)bussiness
                           usageCalculateType:(HMDNetTrafficUsageBytesAddType)dealType
                                    usageType:(HMDNetTrafficeUsageSourceType)usageType
                               currentNetType:(HMDNetTrafficSourceNetType)netType {
    // check is valid
    if (!sourceId || sourceId.length == 0) { return; }

    if (!bussiness || bussiness.length == 0) {
        bussiness = @"unknown";
    }
    if (timestamp == 0) {
        timestamp = MilliSecond([[NSDate date] timeIntervalSince1970]);
    }

    // fetch cache
    HMDNetTrafficSourceUsageModel *sourceUsage = nil;
    NSString *searchId = [NSString stringWithFormat:@"%@+%@",bussiness, sourceId];
    if (usageType == HMDNetTrafficeUsageTypeBussiness && sourceId) {
        sourceUsage = [self.bizSourceCache objectForKey:searchId];
    } else if (usageType == HMDNetTrafficeUsageTypeRequest) {
        sourceUsage = [self.freqTool cachedSourceInfoWithKey:sourceId];
    }

    // initilizer model if no exist
    if (sourceUsage == nil) {
        sourceUsage = [[HMDNetTrafficSourceUsageModel alloc] initWithSourceId:sourceId business:bussiness];
    }

    // calculate increament traffic
    long long usageIncrement = 0;
    unsigned long long oriUsage = sourceUsage.usageBytes;
    if (dealType == HMDNetTrafficUsageBytesIncrement) {
        sourceUsage.usageBytes = oriUsage + usageBytes;
        usageIncrement = usageBytes;
    } else {
        usageIncrement = usageBytes - oriUsage;
        sourceUsage.usageBytes = usageBytes;
    }
    [sourceUsage addTrafficUsage:usageIncrement netType:netType];
    sourceUsage.executeCount = sourceUsage.executeCount + 1;
    // update last timestamp
    sourceUsage.resetTimestamp = timestamp;

    /// if traffic usage from bussin consume
    if (usageType == HMDNetTrafficeUsageTypeBussiness) {
        // store biz's source traffic usage
        [self.bizSourceCache setObject:sourceUsage forKey:searchId];
    } else if (usageType == HMDNetTrafficeUsageTypeRequest) {
        // high frequency request (use LRU-K)
        [self.freqTool cacheSourceUsageInfo:sourceUsage];
        // large request
        if (usageBytes > self.thresholdConfig.requestBytesThreshold) {
            HMDNetTrafficSourceUsageModel *largUsage = [[HMDNetTrafficSourceUsageModel alloc] initWithSourceId:sourceId business:bussiness];
            largUsage.usageBytes = usageBytes;
            [largUsage addTrafficUsage:usageBytes netType:netType];
            [self.largReqInfoes hmd_addObject:largUsage];
        }
    } 

    // 以业务为维度 计算总的流量使用
    if (usageIncrement > 0) {
        [self statisticBizUsageDetailWithUsageInfo:sourceUsage bussiness:bussiness increamentBytes:usageIncrement usageType:usageType netType:netType];
    }
}

- (void)statisticBizUsageDetailWithUsageInfo:(HMDNetTrafficSourceUsageModel *)sourceUsage
                                   bussiness:(NSString *)bussiness
                             increamentBytes:(unsigned long long)businessIncrement
                                   usageType:(HMDNetTrafficeUsageSourceType)usageType
                                     netType:(HMDNetTrafficSourceNetType)netType {
    if (self.trafficInfoCollectors.count == 0) { return; }
    [self.trafficInfoCollectors enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, NSMutableDictionary *  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSMutableDictionary class]] && [key isKindOfClass:[NSString class]]) {
            HMDNetTrafficBizUsageModel *bizInfo = [obj hmd_objectForKey:bussiness class:[HMDNetTrafficBizUsageModel class]];
            if (!bizInfo) {
                bizInfo = [[HMDNetTrafficBizUsageModel alloc] init];
                bizInfo.bizName = bussiness;
            }
            [self updateBizUsageInfoWithTargetBiz:bizInfo sourceUsage:sourceUsage increamentBytes:businessIncrement usageType:usageType netType:netType needSource:(![key isEqualToString:kHMDNetTrafficCollectorProcess])];
            [obj hmd_setObject:bizInfo forKey:bussiness];
        }
    }];
}

- (void)updateBizUsageInfoWithTargetBiz:(HMDNetTrafficBizUsageModel *)bizInfo
                            sourceUsage:(HMDNetTrafficSourceUsageModel *)sourceUsage
                        increamentBytes:(unsigned long long)businessIncrement
                              usageType:(HMDNetTrafficeUsageSourceType)usageType
                                netType:(HMDNetTrafficSourceNetType)netType
                             needSource:(BOOL)needSource {
    if (!bizInfo || !sourceUsage) { return; }
    bizInfo.totalUsage = bizInfo.totalUsage + businessIncrement;

    switch (netType) {
        case HMDNetTrafficSourceNetTypeMobileFront:
            bizInfo.mobileFrontUsage += businessIncrement;
            break;
        case HMDNetTrafficSourceNetTypeMobileBack:
            bizInfo.mobileBackUsage += businessIncrement;
            break;
        case HMDNetTrafficSourceNetTypeWiFiFront:
            bizInfo.wifiFrontUsage += businessIncrement;
            break;
        case HMDNetTrafficSourceNetTypeWiFiBack:
            bizInfo.wifiBackUsage += businessIncrement;
            break;
        default:
            break;
    }

    if (usageType == HMDNetTrafficeUsageTypeBussiness && needSource) { // Only report business consume traffic info
        [bizInfo.detailMap hmd_setObject:sourceUsage forKey:sourceUsage.souceId?:@""];
        // clear old record
        if (bizInfo.detailMap.count > kHMDNetTrafficBizSouceIdCacheCount) {
            __block NSString *willRemoveKey = sourceUsage.souceId;
            __block unsigned long long minUsage = sourceUsage.usageBytes;
            [bizInfo.detailMap
                enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull enumKey, HMDNetTrafficSourceUsageModel *_Nonnull enumUsageInfo, BOOL *_Nonnull stop) {
                    if (enumUsageInfo.usageBytes < minUsage) {
                        willRemoveKey = enumKey;
                        minUsage = enumUsageInfo.usageBytes;
                    }
            }];
            if (willRemoveKey) {
                [bizInfo.detailMap removeObjectForKey:willRemoveKey?:@""];
            }
        }
    }
}

#pragma mark--- dump exception
- (void)intervalTrafficDetailWithModel:(void(^)(HMDNetTrafficIntervalUsageModel *))completion {
    hmd_safe_dispatch_async(self.operationQueue, ^{
        HMDNetTrafficIntervalUsageModel *intervalUsage = [self convertToIntervalUsageInfoFromBizUsage:self.intervalBizUsage.allValues];
        intervalUsage.largeRequest = [self.largReqInfoes copy];
        intervalUsage.highFrequencyRequest = [self.freqTool dumpHighFrequencyUsageWithThreshold:self.thresholdConfig.requestFreqThreshold];
        if (completion) {
            completion(intervalUsage);
        }
        [self resetStatisticsData];
    });
}

- (void)resetStatisticsDataOnSafeThread {
    hmd_safe_dispatch_async(self.operationQueue, ^{
        [self resetStatisticsData];
    });
}

- (void)resetStatisticsData {
    // 清空本轮缓存的业务信息
    [self.bizSourceCache removeAllObjects];
    // 清空大请求
    [self.largReqInfoes removeAllObjects];
    // 清空本轮的业务流量使用信息
    [self.intervalBizUsage removeAllObjects];
    [self.trafficInfoCollectors hmd_setObject:self.intervalBizUsage forKey:kHMDNetTrafficCollectorInterval];
    // 清空高频请求
    [self.freqTool cleanCache];
}

#pragma mark --- custom span info collect
- (void)addCustomSpanTrafficCollect:(NSString *)collectorName {
    if (![collectorName isKindOfClass:[NSString class]]) { return; }
    if (!collectorName || collectorName.length == 0) { return; }
    hmd_safe_dispatch_async(self.operationQueue, ^{
        NSMutableDictionary *collectorBizCache = [NSMutableDictionary dictionary];
        [self.trafficInfoCollectors hmd_setObject:collectorBizCache forKey:collectorName];
    });
}

- (void)endCustomSpanTrafficCollect:(NSString *)collectorName completion:(HMDTrafficIntervalCallback)completion {
    if (![collectorName isKindOfClass:[NSString class]]) { return; }
    if (!collectorName || collectorName.length == 0) { return; }
    hmd_safe_dispatch_async(self.operationQueue, ^{
        NSMutableDictionary *spanUsageDict = [self.trafficInfoCollectors hmd_objectForKey:collectorName class:[NSDictionary class]];
        if (![spanUsageDict isKindOfClass:[NSMutableDictionary class]]) {
            NSAssert(NO, @"HMDNetTraffic: trafficInfoCollectors cache type error");
            return;
        }
        HMDNetTrafficIntervalUsageModel *intervalUsage = [self convertToIntervalUsageInfoFromBizUsage:spanUsageDict.allValues];
        if (completion) {
            completion(intervalUsage);
        }
        [spanUsageDict removeAllObjects];
        [self.trafficInfoCollectors removeObjectForKey:collectorName];
    });
}

- (HMDNetTrafficIntervalUsageModel *)convertToIntervalUsageInfoFromBizUsage:(NSArray<HMDNetTrafficBizUsageModel *> *)businessInfo {
    HMDNetTrafficIntervalUsageModel *intervalUsage = [[HMDNetTrafficIntervalUsageModel alloc] init];
    if (![businessInfo isKindOfClass:[NSArray class]]) {
        NSAssert(NO, @"HMDNetTraffic Error: type Error");
        return intervalUsage;
    }
    NSMutableArray *legalBizInfos = [NSMutableArray array];
    [businessInfo enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[HMDNetTrafficBizUsageModel class]]) {
            [legalBizInfos hmd_addObject:obj];
        }
    }];
    intervalUsage.businessUsage = [legalBizInfos copy];
    return intervalUsage;
}

#pragma mark--- override
- (void)setAnchorTS:(long long)anchorTS {
    _anchorTS = anchorTS;
    self.freqTool.anchorTS = anchorTS;
}

#pragma mark --- revieve memroy warning
- (void)hmdDidReciveMemoryWarning:(NSNotification *)notification {
    hmd_safe_dispatch_async(self.operationQueue, ^{
        [self resetStatisticsData];
    });
}


@end
