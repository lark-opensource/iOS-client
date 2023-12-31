//
//  IESLiveWebViewPerformanceDictionary.m
//
//  Created by renpengcheng on 2019/5/24.
//

#import "IESLiveWebViewPerformanceDictionary.h"
#import "IESLiveWebViewMonitorSettingModel.h"
#import "IESLiveWebViewNavigationMonitor.h"
#import "BDWebViewDelegateRegister.h"
#import "IESLiveWebViewMonitor+Private.h"
#import "IESWebViewCustomReporter.h"
#import "IESLiveMonitorUtils.h"
#import "BDApplicationStat.h"
#import "BDMonitorThreadManager.h"
#import <Heimdallr/HMDTTMonitor.h>
#import "BDWebView+BDWebViewMonitor.h"
#import "BDHybridCoreReporter.h"
#import "BDHybridMonitor.h"
#import "BDHybridMonitorDefines.h"

NSString * const kBDWebViewMonitorNavigationID = @"navigation_id";
NSString * const kBDWebViewMonitorContainerType = @"container_type";
NSString * const kBDWebViewMonitorNativePage = @"native_page";
NSString * const kBDWebViewMonitorClickStart = @"click_start";
NSString * const kBDWebViewMonitorContext = @"context";
NSString * const kBDWebViewMonitorVirtualAid = @"virtual_aid";
NSString * const kBDWebViewMonitorSDKVersion = @"sdk_version";

NSString * const kBDWebViewMonitorContainerInitTs = @"container_init_ts";
NSString * const kBDWebViewMonitorAttachTs = @"attach_ts";
NSString * const kBDWebViewMonitorDetachTs = @"detach_ts";
NSString * const kBDWebViewMonitorIsPreload = @"is_preload_container";
NSString * const kBDWebViewMonitorIsContainerReuse = @"container_reuse";
NSString * const kBDWebViewMonitorIsPrefetch = @"is_prefetch_data";
NSString * const kBDWebViewMonitorIsOffline = @"is_offline";
NSString * const kBDWebViewMonitorURL = @"url";
NSString * const kBDWebViewMonitorPid = @"pid";
NSString * const kBDWebViewMonitorBid = @"bid";
NSString * const kBDWebViewMonitorNativeBase = @"nativeBase";

NSString * const kBDWebViewMonitorClientParams = @"nativeInfo";
NSString * const kBDWebViewMonitorClientMetric = @"client_metric";
NSString * const kBDWebViewMonitorClientCategory = @"client_category";
NSString * const kBDWebViewMonitorClientExtra = @"client_extra";
NSString * const kBDWebViewMonitorServiceType = @"serviceType";
NSString * const kBDWebViewMonitorClientCustomDirectly = @"kClientCustomDirectly";
NSString * const kBDWebViewMonitorEvent = @"event";
NSString * const kBDWebViewMonitorAccumulateEvent = @"kAccumulateEvent";
NSString * const kBDWebViewMonitorEventType = @"event_type";
NSString * const kBDWebViewMonitorScene = @"scene";
NSString * const vBDWMHttpStatusCodeError = @"httpStatusCodeError";
NSString * const vBDWMNavigationFail = @"navigationFail";

NSString * const kBDWMRequestStart = @"request_start";
NSString * const kBDWMRequestFail = @"request_fail";
NSString * const kBDWMNavigationStart = @"navigation_start";
NSString * const kBDWMNavigationFinish = @"navigation_finish";
NSString * const kBDWMRedirectDetail = @"redirect_detail";
NSString * const kBDWMNavigationFail = @"navigation_fail";

// add containerBase & containerInfo for event
static NSString * const kBDWebViewMonitorContainerBase = @"containerBase";
static NSString * const kBDWebViewMonitorContainerInfo = @"containerInfo";

static NSString * const kEventName = @"event_name";
static NSInteger maxRecordCount = 1;
static NSMutableArray<NSDictionary*(^)(NSString*)> *pInitParamsBlocks = nil;
static NSMutableArray<NSDictionary*(^)(NSDictionary*,NSString**)> *pFormatBlocks = nil;
static NSString *kClientRecordType = @"kClientRecordType";
static NSString *kClientRecordValue = @"kClientRecordValue";

@interface IESLiveWebViewPerformanceDictionary ()

@property (nonatomic, copy, readonly) IESLiveWebViewMonitorSettingModel *settingModel;
// 用来存储 大盘数据
//目前客户端插入的key包括 client_params, client_metric, client_category, client_extra,
//对应的value均为字典类型！！！！
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSMutableDictionary*> *overviewDic;
// 用来存储 fps，mem等性能数据
//    "5175bd0e-3b4d-413e-a2fd-9f81a3cf4d6e" =     {
//        fps =  @[report1, report2]
//        };
//    };
@property (nonatomic, strong) NSMutableDictionary<NSString*,NSMutableDictionary*> *averageDic;
@property (nonatomic, strong) NSMutableDictionary *pendingParams;
// pv 上报策略

@property (nonatomic, assign) NSInteger lastReportIndex;
@property (nonatomic, copy) NSString *currentNativeNavigationID;
@property (nonatomic, copy) NSString *currentNativeUrl;
@property (nonatomic, copy) NSString *currentNativeVC;
@property (nonatomic, assign) long clickStartTs;
@property (nonatomic, copy, readwrite) NSString *currentUrl;
@property (nonatomic, weak) id webView;
@property (nonatomic, strong) Class webViewClass;

@end

@implementation IESLiveWebViewPerformanceDictionary

static NSString *serviceNameForService(NSString *service, BOOL isLive, Class webViewCls) {
    
    NSDictionary *settingMap = [IESLiveWebViewMonitorSettingModel settingMapForWebView:webViewCls];
    if ([settingMap isKindOfClass:[NSDictionary class]]) {
        NSString *bizTag = settingMap[kBDWMBizTag] ?: @"";
        if ([service isEqualToString:@"custom"]) { // 自定义走原来的老逻辑
            return [NSString stringWithFormat:@"tt%@_webview_timing_monitor_custom_service",settingMap[kBDWMBizTag] ?: @""];
        } else {
            return service.length ? [NSString stringWithFormat:@"bd_hybrid_monitor_service_%@_%@_%@", service, [IESLiveWebViewPerformanceDictionary containerType], bizTag] : @"bd_hybrid_monitor_default_service";
        }
    } else {
        // 不能走到这里来
        NSCAssert(NO, @"not turn on monitor with service: %@,and class : %@",service?:@"",NSStringFromClass(webViewCls));
        return @"bd_hybrid_monitor_default_service";
    }
}

static NSString *bizTagForClass(Class webViewCls) {
    NSDictionary *settingMap = [IESLiveWebViewMonitorSettingModel settingMapForWebView:webViewCls];
    NSString *bizTag = @"";
    if ([settingMap isKindOfClass:[NSDictionary class]]) {
         bizTag = settingMap[kBDWMBizTag] ?: @"";
    }
    return bizTag;
}

static NSDictionary *formatDicForRecord(NSDictionary *record, NSArray *containerUUIDList, BOOL isLive) {
    if (![record isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSMutableDictionary *finalExtra = [NSMutableDictionary dictionary];
    if (isLive) {
        finalExtra[@"tag"] = @"ttlive_sdk";
    }
    
    NSDictionary *nativeBase = record[kBDWebViewMonitorNativeBase];
    if ([nativeBase isKindOfClass:[NSDictionary class]]) {
        if ([nativeBase[kBDWebViewMonitorURL] length]) {
            NSString *urlStr = nativeBase[kBDWebViewMonitorURL];
            NSURL *url = [NSURL URLWithString:urlStr];
            !(url.host.length) ?: [finalExtra setObject:url.host forKey:@"host"];
            !(url.path.length) ?: [finalExtra setObject:url.path forKey:@"path"];
        }
    }
    
    [finalExtra addEntriesFromDictionary:record];

    // check ev_type/event_type in record, if none, add 'event_type':'eventTypeFromNativeInfo'
    NSDictionary *nativeInfo = finalExtra[kBDWebViewMonitorClientParams];
    if (![[finalExtra allKeys] containsObject:kBDWebViewMonitorEventType] &&
        [nativeInfo isKindOfClass:[NSDictionary class]] &&
        [nativeInfo[kBDWebViewMonitorEventType] isKindOfClass:[NSString class]]) {
        // check length of 'event_type', do not set empty string
        if ([nativeInfo[kBDWebViewMonitorEventType] length]) {
            finalExtra[kBDWebViewMonitorEventType] = nativeInfo[kBDWebViewMonitorEventType];
        }
    }

    // add containerBase & containerInfo on monitor-thread
    if (containerUUIDList != nil &&
        [containerUUIDList isKindOfClass:[NSArray class]] &&
        containerUUIDList.count != 0) {
        NSDictionary *containerBase = record[kBDWebViewMonitorContainerBase];
        NSDictionary *containerInfo = record[kBDWebViewMonitorContainerInfo];
        NSMutableDictionary *finalContainerBase = [NSMutableDictionary dictionary];
        NSMutableDictionary *finalContainerInfo = [NSMutableDictionary dictionary];
        if (containerBase &&
            [containerBase isKindOfClass:[NSDictionary class]] &&
            containerBase.count) {
            [finalContainerBase addEntriesFromDictionary:containerBase];
        }
        if (containerInfo &&
            [containerInfo isKindOfClass:[NSDictionary class]] &&
            containerInfo.count) {
            [finalContainerInfo addEntriesFromDictionary:containerInfo];
        }
        // 限制在monitor-thread对ContainerData访问
        if ([BDMonitorThreadManager isMonitorThread]) {
            for (NSString * obj in containerUUIDList) {
                [BDHybridMonitor fetchContainerData:obj block:^(NSDictionary * containerBaseDic, NSDictionary * containerInfoDic) {
                    if (containerBaseDic && containerBaseDic.count) {
                        [finalContainerBase addEntriesFromDictionary:containerBaseDic];
                    }
                    if (containerInfoDic && containerInfoDic.count) {
                        [finalContainerInfo addEntriesFromDictionary:containerInfoDic];
                    }
                }];
            }
        }
        finalExtra[kBDWebViewMonitorContainerBase] = [finalContainerBase copy];
        finalExtra[kBDWebViewMonitorContainerInfo] = [finalContainerInfo copy];
    }

    [pFormatBlocks enumerateObjectsUsingBlock:^(NSDictionary*(^ _Nonnull formatBlock)(NSDictionary*, NSString**),
                                                NSUInteger idx,
                                                BOOL * _Nonnull stop) {
        NSString *key = nil;
        NSDictionary *formatExtra = formatBlock(finalExtra, &key);
        if (formatExtra.count) {
            if (key.length) {
                finalExtra[key] = [formatExtra copy];
            } else {
                [finalExtra addEntriesFromDictionary:formatExtra];
            }
        }
    }];
    return [finalExtra copy];
};

//static BOOL shouldReport(NSDictionary *record) {
//    if ([record isKindOfClass:[NSDictionary class]]) {
//        NSDictionary *nativeBase = record[kBDWebViewMonitorNativeBase];
//
//        if ([nativeBase isKindOfClass:[NSDictionary class]]) {
//            NSString *url = nativeBase[kBDWebViewMonitorURL];
//            if (!url.length
//                && [record[kBDWebViewMonitorClientParams] isKindOfClass:[NSDictionary class]]) {
//                url = record[kBDWebViewMonitorClientParams][kBDWebViewMonitorURL];
//            }
//
//            if (url && ![url containsString:@"waitfix"]) {
//                return YES;
//            }
//        }
//    }
//    return NO;
//}

static void reportWithDic(NSDictionary *dic,
                          BOOL isLive,
                          Class webViewCls,
                          NSArray * containerUUIDList,
                          IESLiveWebViewReportType type) {
    if (![dic isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSDictionary *dicCpy = [dic copy];
    NSArray * uuidList = nil;
    if ([containerUUIDList isKindOfClass:[NSArray class]]) {
        uuidList = [containerUUIDList copy];
    }
    [dicCpy enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSDictionary *record, BOOL * _Nonnull stop) {
        NSString *service = serviceNameForService(record[kBDWebViewMonitorServiceType], isLive, webViewCls);
        [MonitorReporterInstance reportSingleDic:formatDicForRecord(record, uuidList, isLive)
                                      forService:service];
    }];
}

static void reportSingleRecordDic(NSDictionary *record,
                                  BOOL isLive,
                                  Class webViewCls,
                                  NSArray * containerUUIDList,
                                  IESLiveWebViewReportType type) {
    NSDictionary *dic = [record copy];
    NSArray * uuidList = nil;
    if ([containerUUIDList isKindOfClass:[NSArray class]]) {
        uuidList = [containerUUIDList copy];
    }
    NSString *serviceType = dic[kBDWebViewMonitorServiceType];
    if (serviceType.length <= 0) {
        serviceType = dic[kBDWebViewMonitorEventType];
        if (serviceType.length <= 0) {
            NSDictionary *nativeInfo = dic[kBDWebViewMonitorClientParams];
            if ([nativeInfo isKindOfClass:NSDictionary.class]) {
                serviceType = nativeInfo[kBDWebViewMonitorEventType];
            }
        }
    }
    [MonitorReporterInstance reportSingleDic:formatDicForRecord(dic, uuidList, isLive)
                                  forService:serviceNameForService(serviceType, isLive, webViewCls)];
}

#define isLegalNumber(ins, intValue) \
(([ins isKindOfClass:[NSNumber class]] \
|| [ins isKindOfClass:[NSString class]]) \
&& [ins respondsToSelector:@selector(intValue)]) \

static NSDictionary *accumulatedDic(NSDictionary*srcDic, NSMutableDictionary *origDic) {
    if (!(origDic.count)) {
        return srcDic;
    }
    NSMutableDictionary *accumulatedDic = [srcDic mutableCopy];
    [srcDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSNumber *obj, BOOL * _Nonnull stop) {
        if (isLegalNumber(obj, intValue)) {
            NSNumber *count = origDic[key];
            if (count) {
                [accumulatedDic setObject:@([count intValue] + [obj intValue]) forKey:key];
            }
        }
    }];
    return [accumulatedDic copy];
}

- (instancetype)initWithSettingModel:(IESLiveWebViewMonitorSettingModel *)settingModel
                             webView:(id)webView {
    if (self = [super init]) {
        _settingModel = settingModel;
        _lastReportIndex = 0;
        _pendingParams = [NSMutableDictionary dictionary];
        _webView = webView;
        _webViewClass = [webView class];
    }
    return self;
}

- (void)calAverageDicAndMerge {
    NSDictionary *averageDic = [self.averageDic copy];
    [averageDic enumerateKeysAndObjectsUsingBlock:^(NSString *navigationID, NSDictionary *performances, BOOL * _Nonnull stop) {
        NSMutableDictionary<NSString*, NSMutableArray*> *valueDic = [NSMutableDictionary dictionary];
        [performances enumerateKeysAndObjectsUsingBlock:^(NSString *eventType, NSArray *eventRecords, BOOL * _Nonnull stop) {
            [eventRecords enumerateObjectsUsingBlock:^(NSDictionary *eventRecord, NSUInteger idx, BOOL * _Nonnull stop) {
                // 从这一层开始是前端格式
                if ([eventRecord isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *valuesDic = [eventRecord[@"event"] copy];
                    if ([valueDic isKindOfClass:[NSDictionary class]]) {
                        [valuesDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull performanceKey, NSNumber *obj, BOOL * _Nonnull stop) {
                            if (!valueDic[performanceKey]) {
                                valueDic[performanceKey] = [NSMutableArray array];
                            }
                            if (isLegalNumber(obj, doubleValue)) {
                                [valueDic[performanceKey] addObject:obj];
                            }
                        }];
                    }
                }
            }];
        }];
        [valueDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray * _Nonnull obj, BOOL * _Nonnull stop) {
            NSInteger count = 0;
            double sum = 0;
            for (NSNumber *value in obj) {
                double dVal = [value doubleValue];
                if (dVal >= 0) {
                    sum += dVal;
                    count += 1;
                }
            }
            double average = count > 0 ? (sum / count) : 0;
            [self coverClientParams:@{key : @(average > 1000 ? (NSInteger)average : (double)average)} async:NO];
            [self coverClientParams:@{[key stringByAppendingString:@"PointCount"] : @(count)} async:NO];
        }];
    }];
}

#define isString(ins) \
([ins isKindOfClass:[NSString class]] && [(NSString*)ins length])

- (void)reportIfNeededWithDic:(NSDictionary *)dic {
    NSDictionary *nativeBase = dic[kBDWebViewMonitorNativeBase];
    if (![nativeBase isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    NSString *navigationID = nativeBase[kBDWebViewMonitorNavigationID];
    if (isString(navigationID)) {
        void (^reportNavigationID)(NSString*) = ^(NSString *navigationID) {
            if (navigationID.length) {
                [self calAverageDicAndMerge];
                [self mergeAccumulateData];
                if (self.overviewDic[navigationID].count || self.averageDic[navigationID].count) {
                    [self reportCurrentPagePerf:navigationID];
                }
            }
        };
        // 如果navigation不一致，则计算平均值
        if (!self.overviewDic[navigationID]) {
            [self.overviewDic.allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull naviID, NSUInteger idx, BOOL * _Nonnull stop) {
                reportNavigationID(naviID);
            }];
            
            if (self.overviewDic.count >= maxRecordCount
                && !self.overviewDic[navigationID]) {
                reportWithDic(self.overviewDic, self.isLive, self.webViewClass, [self.containerUUIDList copy], IESLiveWebViewCover);
                [self.overviewDic removeAllObjects];
                reportWithDic(self.averageDic, self.isLive, self.webViewClass, [self.containerUUIDList copy], IESLiveWebViewAverage);
                [self.averageDic removeAllObjects];
            }
            
            NSMutableDictionary *origDic = self.overviewDic[navigationID];
            // 如果阶段一致或已经上报load，则认为是第二次进入该网页
            if ([dic[@"step"] length] &&
                ([origDic[@"step"] isEqualToString:dic[@"step"]]
                 || [origDic[@"step"] isEqualToString:@"load"])) {
                if (self.bdwm_reportTime == BDWebViewMonitorPerfReportTime_Default) {
                    // 只有在选择为默认上报场景下才上报，否则就会在之前就上报
                    reportNavigationID(navigationID);
                }
            }
        }
    }
}

- (BOOL)inBlockList:(NSString *)url {
    return isString(url) &&
    [self.settingModel.blockList containsObject:url];
}

- (void)prepareCoverForNavigationID:(NSString *)navigationID
                          paramsKey:(NSString *)paramsKey
                                url:(NSString *)url {
    if (!self.overviewDic) {
        self.overviewDic = [NSMutableDictionary dictionary];
    }
    if (isString(url)) {
        self.currentUrl = url;
    }
    if (isString(navigationID)) {
        NSMutableDictionary *origDic = self.overviewDic[navigationID];
        if (!origDic) {
            origDic = [NSMutableDictionary dictionary];
        }
        void (^prepare)(NSString *paramsKey) = ^(NSString *paramsKey) {
            if (!origDic[paramsKey]) {
                NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                origDic[paramsKey] = dic;
            }
            NSMutableDictionary *clientParams = origDic[paramsKey];
            if ([self.pendingParams[paramsKey] isKindOfClass:[NSDictionary class]]) {
                [clientParams addEntriesFromDictionary:self.pendingParams[paramsKey]];
                [self.pendingParams removeObjectForKey:paramsKey];
            }
            // 针对 client_params需要单独处理
            if ([paramsKey isEqualToString:kBDWebViewMonitorClientParams]) {
                [pInitParamsBlocks enumerateObjectsUsingBlock:^(NSDictionary *(^ _Nonnull block)(NSString *), NSUInteger idx, BOOL * _Nonnull stop) {
                    NSDictionary *initParams = block(navigationID);
                    !initParams ?: [clientParams addEntriesFromDictionary:initParams];
                }];
            }
        };
        if (isString(paramsKey)) {
            prepare(paramsKey);
        }
        
        if ([paramsKey isEqualToString:kBDWebViewMonitorAccumulateEvent]
            && self.pendingParams[kBDWebViewMonitorAccumulateEvent]) {
            NSDictionary *events = self.pendingParams[kBDWebViewMonitorAccumulateEvent];
            [self accumulateWithDic:events];
            [self.pendingParams removeObjectForKey:kBDWebViewMonitorAccumulateEvent];
        }
        [self.pendingParams.allKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL * _Nonnull stop) {
            prepare(key);
        }];
        
        [self.overviewDic setObject:origDic forKey:navigationID];
    }
}

- (void)mergeToOverViewDic:(NSDictionary *)dic {
    NSDictionary *nativeBase = dic[kBDWebViewMonitorNativeBase];
    
    if (![nativeBase isKindOfClass:[NSDictionary class]] ||[self inBlockList:nativeBase[kBDWebViewMonitorURL]]) {
        return;
    }
    NSString *navigationID = nativeBase[kBDWebViewMonitorNavigationID];
    if (isString(navigationID)) {
        [self prepareCoverForNavigationID:navigationID
                                paramsKey:nil
                                      url:nativeBase[kBDWebViewMonitorURL]];
        [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [self.overviewDic[navigationID] setObject:obj forKey:key];
        }];
    }
}

- (void)mergeAccumulateData {
    [self.overviewDic enumerateKeysAndObjectsUsingBlock:^(NSString *navigationID, NSMutableDictionary *overViewRecord, BOOL * _Nonnull stop) {
        NSMutableDictionary *accu = [overViewRecord[kBDWebViewMonitorAccumulateEvent] mutableCopy];
        accu[kBDWebViewMonitorNavigationID] = navigationID;
        [self coverClientParams:accu async:NO];
        [overViewRecord removeObjectForKey:kBDWebViewMonitorAccumulateEvent];
    }];
}

+ (BOOL)canReportInCover:(NSDictionary *)jsInfo {
    if ([jsInfo isKindOfClass:NSDictionary.class]) {
        NSInteger fp = [[jsInfo objectForKey:@"fp"] integerValue];
        NSInteger fmp = [[jsInfo objectForKey:@"fmp"] integerValue];
        NSInteger tti = [[jsInfo objectForKey:@"tti"] integerValue];
        if (fp > 0 || fmp > 0 || tti > 0) {
            return YES;
        }
    }
    return NO;
}

- (void)reportCurrentNavigationPagePerf {
    [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
        if (self.currentNativeNavigationID.length >=0 ) {
            [self reportCurrentPagePerf:self.currentNativeNavigationID];
        }
    }];
}

- (void)reportCurrentPagePerf:(NSString *)navigationID {
    if (navigationID.length <= 0) {
        if (!_overviewDic || _overviewDic.allValues.count<=0) {
            return;
        }
        [IESLiveWebViewPerformanceDictionary reportCurrentPage:_overviewDic
                                                   averageDic:_averageDic
                                                    customDic:_customDic
                                            doubleReportBlock:_doubleReportBlock
                                             doubleReportKeys:_doubleReportKeys
                                                   webViewCls:_webViewClass
                                            containerUUIDList:[self.containerUUIDList copy]
                                                          bid:_bid
                                                          pid:_pid
                                                       isLive:_isLive];
        [self.overviewDic removeAllObjects];
        [self.averageDic removeAllObjects];
    } else {
        NSDictionary *navigationDic = self.overviewDic[navigationID];
        if (!navigationDic) {
            return;
        }
        [[self class] reportCurrentPage:@{navigationID : [self.overviewDic[navigationID] mutableCopy] ?: @{}}
                             averageDic:@{navigationID : [self.averageDic[navigationID] mutableCopy] ?: @{}}
                              customDic:[self.customDic copy]
                      doubleReportBlock:self.doubleReportBlock
                       doubleReportKeys:[self.doubleReportKeys copy]
                             webViewCls:self.webViewClass
                      containerUUIDList:[self.containerUUIDList copy]
                                    bid:self.bid
                                    pid:self.pid
                                 isLive:self.isLive];
        [self.overviewDic[navigationID] removeAllObjects];
        [self.averageDic[navigationID] removeAllObjects];
    }
}

+ (void)reportCurrentPage:(NSDictionary*)ovDic
               averageDic:(NSDictionary*)averageDic
                customDic:(NSDictionary*)ctDic
        doubleReportBlock:(void(^)(NSDictionary*))crBlock
         doubleReportKeys:(NSArray *)crKeys
               webViewCls:(Class)webViewCls
        containerUUIDList:(NSArray *)containerUUIDList
                      bid:(NSString *)bid
                      pid:(NSString *)pid
                   isLive:(BOOL)isLive {
    // 将overviewDic中的 customDic 摘出
    NSDictionary *overviewDic = [ovDic copy];
    NSDictionary *customDic = [ctDic copy];
    NSArray *doubleReportKeys = [crKeys copy];
    NSArray * uuidList = nil;
    if ([containerUUIDList isKindOfClass:[NSArray class]]) {
        uuidList = [containerUUIDList copy];
    }
    void(^doubleReportBlock)(NSDictionary*) = crBlock;
    void(^reportBlock)(void) = ^{
        static NSInteger customReportKeysIndex = 0;
        NSArray *customCoverKeys = @[kBDWebViewMonitorClientMetric, kBDWebViewMonitorClientCategory, kBDWebViewMonitorClientExtra];
        NSArray *customDirectly = @[kBDWebViewMonitorClientCustomDirectly];
        NSArray<NSArray*> *keysGroup = @[customCoverKeys, customDirectly];
        NSArray<NSString*> *serviceGroup = @[@"custom", @"custom"];
        NSMutableArray<NSDictionary*> *valuesGroup = [NSMutableArray array];
        [overviewDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull navigationID, NSMutableDictionary *singleRecord, BOOL * _Nonnull stop) {
            if ([singleRecord[kBDWebViewMonitorNativeBase] isKindOfClass:[NSMutableDictionary class]]) {
                if (![singleRecord[kBDWebViewMonitorNativeBase][kBDWebViewMonitorNavigationID] length]) {
                    singleRecord[kBDWebViewMonitorNativeBase][kBDWebViewMonitorNavigationID] = navigationID;
                }
                
                void (^setDefaultValue)(NSString *key, NSString *dfValue) = ^(NSString *key, NSString *dfValue) {
                    singleRecord[kBDWebViewMonitorNativeBase][key] =
                    isString(singleRecord[kBDWebViewMonitorNativeBase][key]) ?
                    singleRecord[kBDWebViewMonitorNativeBase][key]
                    : (dfValue ?: @"");
                };
                setDefaultValue(kBDWebViewMonitorPid, pid);
                setDefaultValue(kBDWebViewMonitorBid, bid);
                setDefaultValue(kBDWebViewMonitorContainerType, [IESLiveWebViewPerformanceDictionary containerType]);
            }
            
            if ([singleRecord[kBDWebViewMonitorClientParams] isKindOfClass:[NSMutableDictionary class]]) {
                if (![singleRecord[kBDWebViewMonitorClientParams][kBDWebViewMonitorEventType] length]) {
                    singleRecord[kBDWebViewMonitorClientParams][kBDWebViewMonitorEventType] = @"performance";
                }
            }
            
            singleRecord[kBDWebViewMonitorServiceType] = singleRecord[kBDWebViewMonitorServiceType] ?: @"overview";

            [keysGroup enumerateObjectsUsingBlock:^(NSArray *keys, NSUInteger groupIdx, BOOL * _Nonnull stop) {
                NSMutableDictionary *navigationIDDic = [NSMutableDictionary dictionary];
                valuesGroup[groupIdx] = navigationIDDic;
                [keys enumerateObjectsUsingBlock:^(NSString *customKey, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSDictionary *value = singleRecord[customKey];
                    if (value) {
                        IESWebViewClientParamsType type = [value[kClientRecordType] integerValue];
                        void (^formatSrcRecord)(NSMutableDictionary*, NSDictionary*) =
                        ^(NSMutableDictionary *formatRecord, NSDictionary *srcRecord) {
                            formatRecord[kBDWebViewMonitorServiceType] = serviceGroup[groupIdx];
                            formatRecord[kBDWebViewMonitorEventType] = @"custom";
                            formatRecord[kBDWebViewMonitorNavigationID] = navigationID;
                            formatRecord[kBDWebViewMonitorURL] = srcRecord[kBDWebViewMonitorURL];
                            formatRecord[kBDWebViewMonitorPid] = srcRecord[kBDWebViewMonitorPid];
                            formatRecord[kBDWebViewMonitorBid] = srcRecord[kBDWebViewMonitorBid];
                        };
                        switch (type) {
                            case DictionaryValue: {
                                NSMutableDictionary *customDic = navigationIDDic[navigationID];
                                if (!customDic) {
                                    customDic = [NSMutableDictionary dictionary];
                                    navigationIDDic[navigationID] = customDic;
                                    formatSrcRecord(customDic, singleRecord);
                                }
                                customDic[customKey] = singleRecord[customKey];
                                break;
                            }
                            case ArrayValue: {
                                NSMutableArray *customArr = navigationIDDic[navigationID];
                                if (!customArr) {
                                    customArr = [NSMutableArray array];
                                    navigationIDDic[navigationID] = customArr;
                                }
                                [(NSArray*)singleRecord[customKey][kClientRecordValue] enumerateObjectsUsingBlock:^(NSDictionary *record, NSUInteger idx, BOOL * _Nonnull stop) {
                                    NSMutableDictionary *muteRecord = [record mutableCopy];
                                    formatSrcRecord(muteRecord, singleRecord);
                                    [customArr addObject:muteRecord];
                                }];
                                break;
                            }
                            default:
                                break;
                        }
                        [singleRecord removeObjectForKey:customKey];
                    }
                }];
            }];
        }];
        if (overviewDic.count) {
            reportWithDic(overviewDic, isLive, webViewCls, uuidList, IESLiveWebViewCover);
        }
        if (valuesGroup.count) {
            for (NSDictionary *navigationRecord in valuesGroup) {
                for (id obj in navigationRecord.allValues) {
                    if ([obj isKindOfClass:[NSDictionary class]]) {
                        reportSingleRecordDic(obj, isLive, webViewCls, uuidList, IESLiveWebViewReportCustom);
                    } else if ([obj isKindOfClass:[NSArray class]]) {
                        [(NSArray*)obj enumerateObjectsUsingBlock:^(id  _Nonnull record, NSUInteger idx, BOOL * _Nonnull stop) {
                            reportSingleRecordDic(record, isLive, webViewCls, uuidList, IESLiveWebViewReportCustom);
                        }];
                    }
                }
            }
        }
        // fps等数据暂时不报
//        if (averageRecordDic.count) {
//            [averageRecordDic enumerateKeysAndObjectsUsingBlock:^(NSString *navigationID, NSDictionary *events, BOOL * _Nonnull stop) {
//                [events enumerateKeysAndObjectsUsingBlock:^(NSString *eventType, NSArray *records, BOOL * _Nonnull stop) {
//                    [records enumerateObjectsUsingBlock:^(NSDictionary *record, NSUInteger idx, BOOL * _Nonnull stop) {
//                        reportSingleRecordDic(record, isLive, webViewCls, IESLiveWebViewAverage);
//                    }];
//                }];
//            }];
//        }
        
        // 摘取需要字段二次上报
        if (doubleReportBlock) {
            [overviewDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull navigationID, NSMutableDictionary *singleRecord, BOOL * _Nonnull stop) {
                if (singleRecord.count) {
                    NSMutableDictionary *doubleDic = [NSMutableDictionary dictionary];
                    if ([customDic isKindOfClass:[NSDictionary class]]) {
                        [doubleDic addEntriesFromDictionary:customDic];
                    }
                    if ([valuesGroup[customReportKeysIndex] isKindOfClass:[NSDictionary class]]) {
                        NSDictionary *customRecords = valuesGroup[customReportKeysIndex];
                        NSDictionary *record = customRecords[navigationID];
                        if ([record isKindOfClass:[NSDictionary class]]) {
                            NSDictionary *metrics = record[kBDWebViewMonitorClientMetric];
                            [metrics enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                                if ([doubleReportKeys containsObject:key]) {
                                    doubleDic[key] = obj;
                                }
                            }];
                        }
                    }
                    doubleDic[kBDWebViewMonitorURL] = singleRecord[kBDWebViewMonitorURL];
                    doubleDic[kBDWebViewMonitorPid] = singleRecord[kBDWebViewMonitorPid];
                    doubleDic[kBDWebViewMonitorBid] = singleRecord[kBDWebViewMonitorBid];
                    doubleDic[kBDWebViewMonitorNavigationID] = navigationID;
                    
                    if ([singleRecord[kBDWebViewMonitorEvent] isKindOfClass:[NSDictionary class]]) {
                        doubleDic[@"performanceTiming"] = singleRecord[kBDWebViewMonitorEvent][@"navigation"];
                    }
                    NSDictionary *clientParams = singleRecord[kBDWebViewMonitorClientParams];
                    doubleDic[@"init_time"] = clientParams[@"init_time"];
                    doubleReportBlock([doubleDic copy]);
                }
            }];
        }
    };
    [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
        reportBlock();
    }];
}

- (void)dealloc {
    [self calAverageDicAndMerge];
    [self mergeAccumulateData];
    
    if (self.bdwm_reportTime == BDWebViewMonitorPerfReportTime_Default) {
        if (_overviewDic.count > 0 || _averageDic.count > 0) {
            [self reportCurrentPagePerf:nil];
        }
    }

    if (self.containerUUIDList.count) {
        NSArray * uuidList = [self.containerUUIDList copy];
        [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
            for (NSString * obj in uuidList) {
                [BDHybridMonitor deleteData:obj isForce:NO];
            }
        }];
    }
}

- (void)prepareAverageForNavigationID:(NSString*)navigationID eventType:(NSString *)eventType {
    if (eventType.length) {
        NSMutableDictionary *eventDic = self.averageDic[navigationID];
        if (!eventDic) {
            eventDic = [NSMutableDictionary dictionary];
            self.averageDic[navigationID] = eventDic;
        }
        if (!eventDic[eventType]) {
            eventDic[eventType] = [NSMutableArray array];
        }
    }
}

- (NSDictionary*)formatORIGDic:(NSDictionary *)dic {
    return [self formatORIGDic:dic nativeCommon:nil];
}

- (NSDictionary*)formatORIGDic:(NSDictionary *)dic nativeCommon:(nullable NSDictionary *)commonInfo {
    NSMutableDictionary *muteDic = [dic mutableCopy];
    NSMutableDictionary *nativeBaseDic = nil;
    
    if ([commonInfo isKindOfClass:[NSDictionary class]]) {
        muteDic[kBDWebViewMonitorNativeBase] = [commonInfo copy];
    } else {
        NSDictionary *srcNativeBaseDic = muteDic[kBDWebViewMonitorNativeBase];
        
        if (srcNativeBaseDic && [srcNativeBaseDic isKindOfClass:[NSDictionary class]]) {
            nativeBaseDic = [srcNativeBaseDic mutableCopy];
        } else {
            nativeBaseDic = [NSMutableDictionary dictionary];
        }
        
        if (self.currentNativeNavigationID.length) {
            nativeBaseDic[kBDWebViewMonitorNavigationID] = self.currentNativeNavigationID;
        }
        
        nativeBaseDic[kBDWebViewMonitorURL] = nativeBaseDic[kBDWebViewMonitorURL] ?: (self.currentNativeUrl ?: @"");
        nativeBaseDic[kBDWebViewMonitorContainerType] = [[self class] containerType];
        nativeBaseDic[kBDWebViewMonitorClickStart] = @(self.clickStartTs);
        nativeBaseDic[kBDWebViewMonitorNativePage] = [self fetchCurrentAttachVCName];
        nativeBaseDic[kBDWebViewMonitorContext] = [self fetchCustomBaseContext:nativeBaseDic[kBDWebViewMonitorURL]];
        nativeBaseDic[kBDWebViewMonitorVirtualAid] = self.bdwm_virtualAid?:@"";
        
        nativeBaseDic[kBDWebViewMonitorContainerInitTs] = @(self.bdwm_webViewInitTs);
        nativeBaseDic[kBDWebViewMonitorAttachTs] = @(self.bdwm_attachTs);
        nativeBaseDic[kBDWebViewMonitorDetachTs] = @(self.bdwm_detachTs);
        nativeBaseDic[kBDWebViewMonitorIsPreload] = @(self.bdwm_isPreload);
        nativeBaseDic[kBDWebViewMonitorIsContainerReuse] = @(self.bdwm_isContainerReuse);
        nativeBaseDic[kBDWebViewMonitorIsPrefetch] = @(self.bdwm_isPrefetch);
        nativeBaseDic[kBDWebViewMonitorIsOffline] = @(self.bdwm_isOffline);
        nativeBaseDic[kBDWebViewMonitorSDKVersion] = [IESLiveMonitorUtils iesWebViewMonitorVersion];
        
        muteDic[kBDWebViewMonitorNativeBase] = [nativeBaseDic copy];
    }
    
    return [muteDic copy];
}

- (NSString *)fetchCurrentAttachVCName {
    if (self.currentNativeVC.length > 0) {
        return self.currentNativeVC;
    } else {
        NSString *page = [IESLiveMonitorUtils pageNameForAttachView:self.webView];
        return page.length>0?page:@"";
    }
}

#pragma mark - public api
- (void)setNavigationID:(NSString *)navigationID {
    [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
        if (navigationID.length) {
            self.currentNativeNavigationID = navigationID;
            self.currentNativeVC = [IESLiveMonitorUtils pageNameForAttachView:self.webView];
        }
    }];
}

- (void)setUrl:(NSString *)url {
    [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
        if (url.length) {
            self.currentNativeUrl = url;
        }
    }];
}

- (NSString *)fetchCurrentUrl {
    return self.currentNativeUrl;
}

- (NSString *)fetchBizTag {
    return bizTagForClass(self.webViewClass);
}

- (NSMutableArray *)containerUUIDList {
    if (!_containerUUIDList) {
        _containerUUIDList = [[NSMutableArray alloc] init];
    }
    return _containerUUIDList;
}

- (NSMutableArray *)contextBlockList {
    if (!_contextBlockList) {
        _contextBlockList = [[NSMutableArray alloc] init];
    }
    return _contextBlockList;
}

- (NSDictionary *)fetchCustomBaseContext:(NSString *)url {
    if (self.contextBlockList.count< 0) {
        return @{};
    }
    NSMutableDictionary *context = [[NSMutableDictionary alloc] init];
    [self.contextBlockList enumerateObjectsUsingBlock:^(BDHMBaseContextBlock  _Nonnull block, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *item = block(url);
        if (item.allKeys.count > 0) {
            [context addEntriesFromDictionary:item];
        }
    }];
    return [context copy];
}

- (void)updateClickStartTs {
    [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
        self.clickStartTs = [BDApplicationStat getLatestClickTimestamp];
    }];
}

- (NSDictionary *)getNativeCommonInfo {
    NSString* nativePage = [self fetchCurrentAttachVCName];
    if(!nativePage){
        nativePage = @"";
    }
    NSString *sdkVersion = [IESLiveMonitorUtils iesWebViewMonitorVersion];
    return @{
        kBDWebViewMonitorClickStart: @(self.clickStartTs),
        kBDWebViewMonitorNativePage: nativePage,
        kBDWebViewMonitorContainerType: [[self class] containerType],
        kBDWebViewMonitorNavigationID: self.currentNativeNavigationID ?: @"",
        kBDWebViewMonitorURL: self.currentNativeUrl ?: @"",
        kBDWebViewMonitorContext: [self fetchCustomBaseContext:self.currentNativeUrl],
        kBDWebViewMonitorVirtualAid:self.bdwm_virtualAid ?: @"",
        kBDWebViewMonitorContainerInitTs:_webView?@(self.bdwm_webViewInitTs):@(0),
        kBDWebViewMonitorAttachTs:_webView?@(self.bdwm_attachTs):@(0),
        kBDWebViewMonitorDetachTs:_webView?@(self.bdwm_detachTs):@(0),
        kBDWebViewMonitorIsPreload:_webView?@(self.bdwm_isPreload):@(0),
        kBDWebViewMonitorIsContainerReuse: _webView?@(self.bdwm_isContainerReuse):@(NO),
        kBDWebViewMonitorIsPrefetch:_webView?@(self.bdwm_isPrefetch):@(0),
        kBDWebViewMonitorIsOffline:_webView?@(self.bdwm_isOffline):@(0),
        kBDWebViewMonitorSDKVersion: sdkVersion?:@"unknown"
    };
}

+ (NSString*)containerType {
    return @"web";
}

- (void)coverClientParams:(NSDictionary *)srcDic {
    [self coverClientParams:srcDic async:YES];
}

- (void)coverClientParamsOnce:(NSDictionary *)srcDic {
    [self addClientParams:srcDic paramsKey:kBDWebViewMonitorClientParams addType:AddByCoverOnce async:YES];
}

- (void)appendClientParams:(NSDictionary *)srcDic forKey:(NSString *)subKey {
    [self addClientParams:srcDic paramsKey:kBDWebViewMonitorClientParams subParamsKey:subKey addType:AddByAppend async:YES];
}

- (void)coverClientParams:(NSDictionary *)srcDic async:(BOOL)async {
    [self addClientParams:srcDic paramsKey:kBDWebViewMonitorClientParams addType:AddByCover async:async];
};

typedef NS_ENUM(NSInteger, IESWebViewAddParamsType) {
    AddByCover,
    AddByAppend,
    AddByCoverOnce,
};

typedef NS_ENUM(NSInteger, IESWebViewClientParamsType) {
    DictionaryValue,
    ArrayValue
};

- (void)appendParams:(NSDictionary *)dic path:(NSString*)path {
    [self appendParams:dic path:path async:YES];
}

// 数组参数类型需要添加元素时使用 @yangyi.peter
- (void)appendParams:(NSDictionary *)srcDic path:(NSString*)path async:(BOOL)async {
    void(^block)(void) = ^{
        if ([srcDic count] == 0 || path.length == 0) {
            return;
        }
        
        NSDictionary *dic = [self formatORIGDic:srcDic];
        NSDictionary *nativeBase = dic[kBDWebViewMonitorNativeBase];
        
        if ([nativeBase isKindOfClass:[NSDictionary class]]) {
            NSString *navigationID = nativeBase[kBDWebViewMonitorNavigationID];
            // 暂时只支持有navigation_id的情况
            if (isString(navigationID)) {
                NSString *realPath = [NSString stringWithFormat:@"%@.%@", navigationID, path];
                NSArray<NSString *> *keys = [realPath componentsSeparatedByString:@"."];
                NSUInteger count = [keys count];
                __block NSMutableDictionary *dic = self.overviewDic;
                __block NSString *destKey = nil;
                [keys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (![dic isKindOfClass:[NSMutableDictionary class]]) {
                        dic = nil;
                        *stop = YES;
                    }
                    
                    if (idx < count - 1) {
                        dic = dic[key];
                    } else {
                        destKey = key;
                    }
                }];
                
                if (dic && destKey) {
                    NSMutableArray *records = nil;
                    if (dic[destKey]) {
                        if ([dic[destKey] isKindOfClass:[NSMutableArray class]]) {
                            records = dic[destKey];
                        }
                    } else {
                        records = [NSMutableArray array];
                    }
                    
                    if (records) {
                        [records addObject:[srcDic mutableCopy]];
                        dic[destKey] = records;
                    }
                }
            }
        }
    };
    
    if (async) {
        [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
            block();
        }];
    } else {
        block();
    }
}

- (void)addClientParams:(NSDictionary *)srcDic
              paramsKey:(NSString *)paramsKey
                addType:(IESWebViewAddParamsType)addType
                  async:(BOOL)async {
    [self addClientParams:srcDic paramsKey:paramsKey subParamsKey:nil addType:addType async:async];
}

- (void)addClientParams:(NSDictionary *)srcDic
              paramsKey:(NSString *)paramsKey
           subParamsKey:(NSString *)subParamsKey
                addType:(IESWebViewAddParamsType)addType
                  async:(BOOL)async {
    NSMutableDictionary *(^mergedCustomReportDic)(NSDictionary *) = ^(NSDictionary *customReport) {
        NSMutableDictionary *muteDic = ([customReport isKindOfClass:[NSMutableDictionary class]]) ?
        customReport : [customReport ?: @{} mutableCopy];
        [srcDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            muteDic[key] = obj;
        }];
        return muteDic;
    };
    
    NSMutableDictionary *(^mergedCustomReportDicOnce)(NSDictionary *) = ^(NSDictionary *customReport) {
        NSMutableDictionary *muteDic = ([customReport isKindOfClass:[NSMutableDictionary class]]) ?
        customReport : [customReport ?: @{} mutableCopy];
        [srcDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if (!muteDic[key]) {
                muteDic[key] = obj;
            }
        }];
        return muteDic;
    };

    NSMutableDictionary *(^appendCustomReportDic)(NSDictionary *) = ^(NSDictionary *customReport) {
        NSMutableDictionary *muteDic = ([customReport isKindOfClass:[NSMutableDictionary class]]) ?
        customReport : [customReport ?: @{} mutableCopy];
        muteDic[kClientRecordType] = @(ArrayValue);
        NSMutableArray *records = muteDic[subParamsKey ?: kClientRecordValue] ?: [NSMutableArray array];
        if (srcDic.count) {
            [records addObject:srcDic];
            muteDic[subParamsKey ?: kClientRecordValue] = records;
        }
        return muteDic;
    };
    
    void(^block)(void) = ^{
        NSDictionary *dic = [self formatORIGDic:srcDic];
        NSDictionary *nativeBase = dic[kBDWebViewMonitorNativeBase];
        
        if ([nativeBase isKindOfClass:[NSDictionary class]]) {
            NSString *navigationID = nativeBase[kBDWebViewMonitorNavigationID];
            if (isString(navigationID)) {
                [self prepareCoverForNavigationID:navigationID
                                        paramsKey:paramsKey
                                              url:nativeBase[kBDWebViewMonitorURL]];
                if (isString(paramsKey)) {
                    self.overviewDic[navigationID][paramsKey] = (addType == AddByCover ? mergedCustomReportDic(self.overviewDic[navigationID][paramsKey]) :
                                                                 addType == AddByCoverOnce ?
                        mergedCustomReportDicOnce(self.overviewDic[navigationID][paramsKey]):
                        appendCustomReportDic(self.overviewDic[navigationID][paramsKey]));
                    if ([paramsKey isEqualToString:kBDWebViewMonitorClientParams]) {
                        self.overviewDic[navigationID][kBDWebViewMonitorServiceType] = @"perf";
                    }
                }
            } else if (isString(paramsKey)) {
                self.pendingParams[paramsKey] = (addType == AddByCover ? mergedCustomReportDic(self.pendingParams[paramsKey]) :
                                                 addType == AddByCoverOnce ?
                mergedCustomReportDicOnce(self.pendingParams[paramsKey]) :
                    appendCustomReportDic(self.pendingParams[paramsKey]));
            }
        }
    };
    if (async) {
        [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
            block();
        }];
    } else {
        block();
    }
}

- (void)coverWithDic:(NSDictionary *)srcDic {
    [self coverWithDic:srcDic nativeCommon:nil];
}

- (void)coverWithDic:(NSDictionary *)srcDic nativeCommon:(NSDictionary * __nullable)commonInfo {
    if (![srcDic isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    NSDictionary *dic = [self formatORIGDic:srcDic nativeCommon:commonInfo];
    [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
        NSDictionary *nativeBase = dic[kBDWebViewMonitorNativeBase];
        if ([nativeBase isKindOfClass:[NSDictionary class]]) {
            NSString *navigationID = nativeBase[kBDWebViewMonitorNavigationID];
            if (isString(navigationID)) {
                [self reportIfNeededWithDic:dic];
                [self mergeToOverViewDic:dic];
            #if DEBUG
                NSLog(@"%@", dic);
            #endif
            }
        }
    }];
}

// jsError, resourceError, HttpError 累加
- (void)accumulateWithDic:(NSDictionary *)srcDic {
    if (![srcDic isKindOfClass:[NSDictionary class]]) {
        return;
    }
    [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
        NSDictionary *dic = [self formatORIGDic:srcDic];
        NSString *navigationID = dic[kBDWebViewMonitorNavigationID];
        NSDictionary *accuDic = nil;
        if (isString(navigationID)) {
            accuDic = accumulatedDic(dic[kBDWebViewMonitorEvent], [self.overviewDic[navigationID][kBDWebViewMonitorAccumulateEvent] copy]);
        } else {
            accuDic = accumulatedDic(dic[kBDWebViewMonitorEvent], [self.pendingParams[kBDWebViewMonitorAccumulateEvent] copy]);
        }
        [self addClientParams:accuDic paramsKey:kBDWebViewMonitorAccumulateEvent addType:AddByCover async:NO];
    }];
}

- (void)mergeDicToCalAverage:(NSDictionary *)srcDic {
    if (![srcDic isKindOfClass:[NSDictionary class]]) {
        return;
    }
    [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
        NSDictionary *dic = [self formatORIGDic:srcDic];
        NSString *navigationID = dic[kBDWebViewMonitorNavigationID];
        NSString *evType = dic[@"ev_type"];
        if (isString(navigationID)
            && isString(evType)
            && [dic[@"event"] isKindOfClass:[NSDictionary class]]) {
            if (!self.averageDic) {
                self.averageDic = [NSMutableDictionary dictionary];
            }
            [self prepareAverageForNavigationID:navigationID eventType:evType];
            [self.averageDic[navigationID][evType] addObject:dic];
        }
    }];
}

- (void)reportBatchWithDic:(NSArray *)srcDic webView:(WKWebView *)webview {
    if (!srcDic || ![srcDic isKindOfClass:NSArray.class]) {
        return;
    }
    for (NSUInteger i = 0;  i < srcDic.count; ++i) {
        NSDictionary *object = srcDic[i];
        
        if ([object isKindOfClass:[NSDictionary class]] && !object[kBDWebViewMonitorServiceType]) {
            [self reportCustomWithDic:object webView:webview];
        } else if ([IESLiveWebViewPerformanceDictionary checkIsPerfTypeData:object]) {
            NSMutableDictionary *nativeBaseDic = [[self getNativeCommonInfo] mutableCopy];
            [self coverWithDic:object nativeCommon:nativeBaseDic];
            
            if (self.bdwm_reportTime == BDWebViewMonitorPerfReportTime_JSPerfReady) {
                if ([object isKindOfClass:NSDictionary.class] && [IESLiveWebViewPerformanceDictionary canReportInCover:object[@"jsInfo"]]) {
                    [self reportCurrentNavigationPagePerf];
                }
            }
        } else {
            [self reportDirectlyWithDic:object nativeCommon:nil];
        }
    }
}

+ (BOOL)checkIsPerfTypeData:(NSDictionary *)dict {
    if ([dict isKindOfClass:[NSDictionary class]]) {
        NSString *eventType = dict[kBDWebViewMonitorServiceType];
        if ([eventType isKindOfClass:NSString.class]) {
            return [eventType isEqualToString:@"perf"];
        }
    }
    return NO;
}

- (void)reportDirectlyWithDic:(NSDictionary *)srcDic {
    [self reportDirectlyWithDic:srcDic nativeCommon:nil];
}

- (void)reportDirectlyWithDic:(NSDictionary *)srcDic nativeCommon:(NSDictionary * _Nullable )commonInfo {
    if (![srcDic isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
        NSDictionary *dic = [self formatORIGDic:srcDic nativeCommon:commonInfo];
        BOOL isLive = self.isLive;
        Class cls = self.webViewClass;
        reportSingleRecordDic(dic,
                              isLive,
                              cls,
                              [self.containerUUIDList copy],
                              IESLiveWebViewReportDirectly);
    }];
}

- (void)reportDirectlyWrapNativeInfoWithDic:(NSDictionary *)srcDic {
    if (!srcDic || ![srcDic isKindOfClass:NSDictionary.class]) {
        return;
    }
    NSDictionary *nativeInfo = @{kBDWebViewMonitorClientParams:srcDic};
    [self reportDirectlyWithDic:nativeInfo];
}

- (void)reportPVWithURLStr:(NSString *)urlStr {
    [self reportPVWithStageDic:@{@"stage" : @"requestStart",
                                 kBDWebViewMonitorURL : urlStr ?: @""
    }];
}

- (void)reportPVWithStageDic:(NSDictionary *)stageDic {
    if(!stageDic || ![stageDic isKindOfClass:[NSDictionary class]]) {
        return;
    }
    if (isString(stageDic[kBDWebViewMonitorURL])
        && [self inBlockList:stageDic[kBDWebViewMonitorURL]]) {
        return;
    }
    static dispatch_once_t onceToken;
    static NSDictionary *stage2code = nil;
    dispatch_once(&onceToken, ^{
        stage2code = @{@"requestStart" : @"0",
                       @"DomContentLoaded" : @"1",
                       vBDWMFinishNavigation : @"2",
                       vBDWMHttpStatusCodeError : @"3",
                       vBDWMNavigationFail : @"4"
        };
    });
    NSString *stage = stageDic[@"stage"];
    if (isString(stage)) {
        NSMutableDictionary *pvDic = [@{
            @"isWk" : @([self.webView isKindOfClass:[WKWebView class]] ? 1 : 0),
            @"clientSuccess" : stage2code[stage] ?: @"",
            @"stage" : stage ?: @"",
            
            
        } mutableCopy];
        if ([stage isEqualToString:@"DomContentLoaded"]) {
            pvDic[@"dom_content_loaded"] = @([IESLiveMonitorUtils formatedTimeInterval]);
        }
        if ([stageDic[kBDWebViewMonitorURL] length]) {
            pvDic[kBDWebViewMonitorURL] = stageDic[kBDWebViewMonitorURL] ?: @"";
        }
        [self coverClientParams:[pvDic copy]];
    }
}

#pragma mark custom report
// 自定义埋点上报（覆盖类型）
- (void)coverWithEventName:(NSString *)eventName
              clientMetric:(NSDictionary *)metric
            clientCategory:(NSDictionary *)category
                     extra:(NSDictionary *)extra {
    if (!eventName.length) {
        return;
    }
    [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
        NSMutableDictionary *muteExtra = [extra ?: @{} mutableCopy];
        muteExtra[kEventName] = eventName;
        NSDictionary<NSString*,NSDictionary*> *dic = @{
            kBDWebViewMonitorClientMetric : metric ?: @{},
            kBDWebViewMonitorClientCategory : category ?: @{},
            kBDWebViewMonitorClientExtra : [muteExtra copy] ?: @{},
        };
        [dic enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL * _Nonnull stop) {
            [self addClientParams:obj paramsKey:key addType:AddByCover async:NO];
        }];
    }];
}

// 立即上报自定义埋点
- (void)reportDirectlyWithEventName:(NSString *)eventName
                       clientMetric:(NSDictionary *)metric
                     clientCategory:(NSDictionary *)category
                              extra:(NSDictionary *)extra {
    if (!eventName.length) {
        return;
    }
    NSMutableDictionary *muteExtra = [extra ?: @{} mutableCopy];
    muteExtra[kEventName] = eventName;
    NSDictionary *record = @{
        kBDWebViewMonitorClientMetric : metric ?: @{},
        kBDWebViewMonitorClientCategory : category ?: @{},
        kBDWebViewMonitorClientExtra : [muteExtra copy] ?: @{},
    };
    [self addClientParams:record paramsKey:kBDWebViewMonitorClientCustomDirectly addType:AddByAppend async:YES];
}

- (void)reportCustomWithDic:(NSDictionary *)dic webView:(WKWebView *)webview {
    if ([dic isKindOfClass:[NSDictionary class]]) {
        NSDictionary *metric = [dic[@"metric"] isKindOfClass:[NSDictionary class]] ? dic[@"metric"] : @{};
        NSDictionary *category = [dic[@"category"] isKindOfClass:[NSDictionary class]] ? dic[@"category"] : @{};
        NSDictionary *extra = [dic[@"extra"] isKindOfClass:[NSDictionary class]] ? dic[@"extra"] : @{};
//        NSDictionary *commonParams = [dic[@"commonParams"] isKindOfClass:[NSDictionary class]] ? dic[@"commonParams"] : @{};
        NSDictionary *timing = [dic[@"timing"] isKindOfClass:[NSDictionary class]] ? dic[@"timing"] : @{};
        NSString *eventName = dic[@"eventName"]?:@"";
        BOOL maySample = 1;
        if (dic[@"canSample"]) {
            NSInteger value = [dic[@"canSample"] integerValue];
            maySample = (value == 1);
        }
        [BDHybridMonitor webReportCustomWithEventName:eventName
                                              webView:webview
                                               metric:metric
                                             category:category
                                                extra:extra
                                               timing:timing
                                            maySample:maySample];
    }
}

// 上报request error
- (void)reportRequestError:(NSError *)error withURLStr:(NSString *)urlStr {
    NSString *errorMsg = [error.userInfo valueForKey:@"message"];
    NSMutableDictionary *errorDic = [[NSMutableDictionary alloc] initWithDictionary:
                     @{  kBDWebViewMonitorEventType: @"nativeError",
                         kBDWebViewMonitorScene:@"main_frame",
                         @"error_code" : @(error.code),
                         @"error_msg" : [NSString stringWithFormat:@"error domain:%@ ,error message:%@",error.domain ?: @"", errorMsg?:@""]
                     }];
    if ([error.userInfo valueForKey:@"httpStatusCode"]) {
        [errorDic setObject:[error.userInfo valueForKey:@"httpStatusCode"]
                     forKey:@"http_status"];
    }
    [self reportDirectlyWrapNativeInfoWithDic:errorDic];
}

- (void)reportContainerError:(NSString *)virtualAid errorCode:(NSInteger)code errorMsg:(NSString *)msg bizTag:(NSString *)bizTag {
    NSArray * uuidList = [self.containerUUIDList copy];
    [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
        NSMutableDictionary *extraDic = [NSMutableDictionary dictionary];
        [extraDic addEntriesFromDictionary:[self formatORIGDic:extraDic]];  // get nativeBase
        if (virtualAid && virtualAid.length) {
            NSMutableDictionary *nativeBaseDic = [extraDic[kBDWebViewMonitorNativeBase] mutableCopy];
            nativeBaseDic[@"virtual_aid"] = virtualAid;
            extraDic[kBDWebViewMonitorNativeBase] = [nativeBaseDic copy];
        }

        NSMutableDictionary *containerInfoDic = [NSMutableDictionary dictionary];
        containerInfoDic[@"container_load_error_code"] = @(code);
        containerInfoDic[@"container_load_error_msg"] = msg?:@"";
        extraDic[kBDWebViewMonitorContainerInfo] = [containerInfoDic copy];

        NSString * eventType = @"containerError";
        extraDic[kBDWebViewMonitorEventType] = eventType;
        NSString *serviceName = [NSString stringWithFormat:@"bd_hybrid_monitor_service_%@_%@"
                                 ,eventType?:@""
                                 ,bizTag?:@""];
        [MonitorReporterInstance reportSingleDic:formatDicForRecord(extraDic, uuidList, NO)
                                      forService:serviceName];
    }];
}

- (void)reportTerminate:(NSError *)error {
    NSInteger errorCode = error?error.code:-1;
    NSString *errorMsg = [error.userInfo valueForKey:@"message"];
    NSMutableDictionary *errorDic = [[NSMutableDictionary alloc] initWithDictionary:
                     @{  kBDWebViewMonitorEventType: @"nativeError",
                         kBDWebViewMonitorScene:@"web_process_terminate",
                         @"error_code" : @(errorCode),
                         @"error_msg" : [NSString stringWithFormat:@"error domain:%@ ,error message:%@",error ? error.domain: @"", errorMsg?:@""]
                     }];
    [self reportDirectlyWrapNativeInfoWithDic:errorDic];
}

- (void)reportNavigationStart {
    long long ts = [IESLiveMonitorUtils formatedTimeInterval];
    NSDictionary *dic = @{
        kBDWebViewMonitorEventType: @"navigationStart",
        @"invoke_ts": @(ts)
    };
    [self reportDirectlyWrapNativeInfoWithDic:dic];
}

#pragma mark register observer
+ (void)registerInitParamsBlock:(NSDictionary*(^)(NSString *navigation))initParamsBlock {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pInitParamsBlocks = [NSMutableArray array];
    });
    [pInitParamsBlocks addObject:initParamsBlock];
}

+ (void)registerFormatBlock:(NSDictionary*(^)(NSDictionary *record, NSString **key))formatBlock {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pFormatBlocks = [NSMutableArray array];
    });
    [pFormatBlocks addObject:formatBlock];
}

@end
