//
//  IESLynxPerformanceDictionary.m
//  IESWebViewMonitor
//
//  Created by 小阿凉 on 2020/3/2.
//

#import "IESLynxPerformanceDictionary.h"
#import "IESLynxMonitorConfig.h"
#import <Heimdallr/HMDTTMonitor.h>
#import "BDApplicationStat.h"
#import "BDHybridCoreReporter.h"
#import "IESLiveMonitorUtils.h"
#import "BDMonitorThreadManager.h"
#import "BDHybridMonitor.h"

#define isString(ins) \
([ins isKindOfClass:[NSString class]] && [(NSString*)ins length])

NSString * const kLynxMonitorLogType = @"service_monitor";
NSString * const kLynxMonitorEventType = @"event_type";
NSString * const kKynxMonitorEvent = @"event";
NSString * const kLynxMonitorPid = @"pid";
NSString * const kLynxMonitorBid = @"bid";
NSString * const kLynxMonitorURL = @"url";
NSString * const kLynxMonitorLynxVersion = @"lynx_version";
NSString * const kLynxMonitorContext = @"context";
NSString * const kLynxMonitorVirtualAid = @"virtual_aid";
NSString * const kLynxMonitorSDKVersion = @"sdk_version";

NSString * const kLynxMonitorNavigationID = @"navigation_id";
NSString * const kLynxMonitorContainerType = @"container_type";
NSString * const kLynxMonitorClickStart = @"click_start";
NSString * const kLynxMonitorNativeBase = @"nativeBase";
NSString * const kLynxMonitorNativeInfo = @"nativeInfo";
NSString * const kLynxMonitorClientParams = @"client_params";
NSString * const kLynxMonitorClientMetric = @"client_metric";
NSString * const kLynxMonitorClientCategory = @"client_category";
NSString * const kLynxMonitorClientExtra = @"client_extra";
NSString * const kLynxMonitorEventName = @"event_name";
NSString * const kLynxMonitorServiceType = @"serviceType";
NSString * const kLynxMonitorScene = @"scene";
NSString * const kLynxMonitorState = @"state";

NSString * const kLynxMonitorLoadStart = @"load_start";
NSString * const kLynxMonitorLoadFinish = @"load_finish";
NSString * const kLynxMonitorLoadFailed = @"load_failed";
NSString * const kLynxMonitorReceiveError = @"receive_error";
NSString * const kLynxMonitorFirstScreen = @"first_screen";
NSString * const kLynxMonitorRuntimeReady = @"runtime_ready";
NSString * const kLynxMonitorDidUpdate = @"did_update";
NSString * const kLynxMonitorIsContainerReuse = @"container_reuse";
NSString * const kBDHMLynxMonitorAttachTs = @"attach_ts";
NSString * const kBDHMLynxMonitorDetachTs = @"detach_ts";
NSString * const kBDHMLynxMonitorCardVersion = @"page_version";

// add containerBase & containerInfo for event
static NSString * const kLynxMonitorContainerBase = @"containerBase";
static NSString * const kLynxMonitorContainerInfo = @"containerInfo";

static NSString * const kLynxMonitorClientCustomDirectly = @"kClientCustomDirectly";
static NSString * const kLynxMonitorAccumulateEvent = @"kAccumulateEvent";
static NSString *kClientRecordType = @"kClientRecordType";
static NSString *kClientRecordValue = @"kClientRecordValue";

NSString * const kCustomServiceName = @"ttlive_webview_timing_monitor_custom_service";

static const void * const SpecificKey = (const void*)&SpecificKey;

typedef NS_ENUM(NSInteger, IESLynxAddParamsType) {
    IESLynxAddByCover,
    IESLynxAddByAppend,
    IESLynxAddByCoverOnce,
};

typedef NS_ENUM(NSInteger, IESLynxClientParamsType) {
    DictionaryValue,
    ArrayValue
};

typedef NS_ENUM(NSInteger, IESLynxMonitorCustomReportType) {
    IESLynxMonitorCustomReportDirectly,
    IESLynxMonitorCustomReportCover
};

@interface IESLynxPerformanceContext : NSObject

@property (atomic, copy) NSString *navigationID;
@property (atomic, copy) NSString *url;
@property (atomic, copy) NSString *containerType;
@property (atomic, copy) NSString *cardVersion;
@property (atomic, assign) long clickStartTs;
@property (atomic, strong) NSArray *contextBlockList;
@property (atomic, strong) NSArray *containerUUIDList;
@property (atomic, copy) NSString *virtualAid;
@property (nonatomic, assign) BOOL isContainerReuse;
@property (nonatomic, assign) long long attachTS;
@property (nonatomic, assign) long long detachTS;

@end

@implementation IESLynxPerformanceContext

- (instancetype)init {
    if (self = [super init]) {
        self.containerType = @"lynx";
        self.contextBlockList = [[NSMutableArray alloc] init];
        self.containerUUIDList = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    if (self.containerUUIDList.count) {
        NSArray * uuidList = [self.containerUUIDList copy];
        [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
            for (NSString * obj in uuidList) {
                [BDHybridMonitor deleteData:obj isForce:NO];
            }
        }];
    }
}

- (NSDictionary*)toNativeBase {
    NSString *sdkVersion = [IESLiveMonitorUtils iesWebViewMonitorVersion];
    NSString *lynxVersion = [IESLynxMonitorConfig lynxVersion];
    NSString *cardVersion = self.cardVersion;
    return @{
        kLynxMonitorNavigationID: self.navigationID ?: @"",
        kLynxMonitorContainerType: self.containerType ?: @"",
        kLynxMonitorURL: self.url ?: @"",
        kLynxMonitorClickStart: @(self.clickStartTs),
        kLynxMonitorContext: [self fetchCustomBaseContext:self.url],
        kLynxMonitorVirtualAid: self.virtualAid ?:@"",
        kLynxMonitorIsContainerReuse: @(self.isContainerReuse),
        kLynxMonitorSDKVersion: sdkVersion?:@"",
        kLynxMonitorLynxVersion: lynxVersion?:@"",
        kBDHMLynxMonitorAttachTs: @(self.attachTS),
        kBDHMLynxMonitorDetachTs: @(self.detachTS),
        kBDHMLynxMonitorCardVersion: cardVersion?:@""
    };
}

- (NSDictionary *)fetchCustomBaseContext:(NSString *)url {
    if (self.contextBlockList.count< 0) {
        return @{};
    }
    NSMutableDictionary *context = [[NSMutableDictionary alloc] init];
    NSArray *contextBlockList = self.contextBlockList; //avoid list change while being enumerated.
    for (BDHMBaseContextBlock block in contextBlockList) {
        if (!block || (NSNull *)block == [NSNull null] ) {
            continue;
        }
            
        NSDictionary *item = block(url);
        if (item.allKeys.count > 0) {
            [context addEntriesFromDictionary:item];
        }
    }
    
    return [context copy];
}

@end

@interface IESLynxPerformanceDictionary ()

// 用来存储 大盘数据
//目前客户端插入的key包括 client_params, client_metric, client_category, client_extra,
//对应的value均为字典类型！！！！
@property (nonatomic) NSMutableDictionary<NSString*, NSMutableDictionary*> *overviewDic;
@property (nonatomic) NSMutableDictionary *pendingParams;
@property (nonatomic) dispatch_queue_t messageDispatchQueue;
@property (nonatomic) IESLynxPerformanceContext *context;

@end

@implementation IESLynxPerformanceDictionary

// run block on monitor-thread, then get containerBase and containerInfo
static void reportSingleDicOnMonitorThread(NSDictionary * dic, NSString * serviceName, NSArray * containerUUIDList) {
    if (![dic isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSDictionary *originalDic = [dic copy];
    NSArray * uuidList = nil;
    if ([containerUUIDList isKindOfClass:[NSArray class]]) {
        uuidList = [containerUUIDList copy];
    }
    [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
        NSMutableDictionary *finalExtra = [NSMutableDictionary dictionary];
        if (uuidList != nil && uuidList.count != 0) {
            NSDictionary *containerBase = originalDic[kLynxMonitorContainerBase];
            NSDictionary *containerInfo = originalDic[kLynxMonitorContainerInfo];
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
            if ([BDMonitorThreadManager isMonitorThread]) {
                for (NSString * obj in uuidList) {
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
            finalExtra[kLynxMonitorContainerBase] = [finalContainerBase copy];
            finalExtra[kLynxMonitorContainerInfo] = [finalContainerInfo copy];
        }
        [finalExtra addEntriesFromDictionary:originalDic];
        // check ev_type/event_type in record, if none, add 'event_type':'eventTypeFromNativeInfo'
        NSDictionary *nativeInfo = finalExtra[kLynxMonitorNativeInfo];
        if (![[finalExtra allKeys] containsObject:kLynxMonitorEventType] &&
            [nativeInfo isKindOfClass:[NSDictionary class]] &&
            [nativeInfo[kLynxMonitorEventType] isKindOfClass:[NSString class]]) {
            // check length of 'event_type', do not set empty string
            if ([nativeInfo[kLynxMonitorEventType] length]) {
                finalExtra[kLynxMonitorEventType] = nativeInfo[kLynxMonitorEventType];
            }
        }
        [MonitorReporterInstance reportSingleDic:[finalExtra copy]
                                      forService:serviceName];
    }];
}

static NSDictionary *formatDicForRecord(NSDictionary *record, IESLynxMonitorConfig *config) {
    if (![record isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSMutableDictionary *finalExtra = [NSMutableDictionary dictionary];
    if (config.url.length) {
        NSURL *url = [NSURL URLWithString:config.url];
        !(url.host.length) ?: [finalExtra setObject:url.host forKey:@"host"];
        !(url.path.length) ?: [finalExtra setObject:url.path forKey:@"path"];
    }
    [finalExtra addEntriesFromDictionary:record];
    [finalExtra addEntriesFromDictionary:config.commonParams];
    [finalExtra setObject:@"custom" forKey:kLynxMonitorEventType];
    return [finalExtra copy];
};

static void reportWithDic(NSDictionary *dic, IESLynxMonitorConfig *config, NSArray * containerUUIDList) {
    if (![dic isKindOfClass:[NSDictionary class]]) {
        return;
    }
    [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSDictionary *record, BOOL * _Nonnull stop) {
        if (record.count) {
            reportSingleDicOnMonitorThread(formatDicForRecord(record, config), kCustomServiceName, containerUUIDList);
        }
    }];
}

static void reportSingleRecordDic(NSDictionary *record, IESLynxMonitorConfig *config, NSArray * containerUUIDList) {
    reportSingleDicOnMonitorThread(formatDicForRecord(record, config), kCustomServiceName, containerUUIDList);
}

- (instancetype)init {
    return [self initWithConfig:nil];
}

- (instancetype)initWithConfig:(IESLynxMonitorConfig *)config
{
    if (self = [super init]) {
        _config = config;
        _pendingParams = [NSMutableDictionary dictionary];
        _messageDispatchQueue = dispatch_queue_create("com.live.serial.queue", DISPATCH_QUEUE_SERIAL);
        self.overviewDic = [NSMutableDictionary dictionary];
        self.pendingParams = [NSMutableDictionary dictionary];
        self.context = IESLynxPerformanceContext.new;
        dispatch_queue_set_specific(_messageDispatchQueue, SpecificKey, (__bridge void *)(_messageDispatchQueue), NULL);
    }
    return self;
}

#define isString(ins) \
([ins isKindOfClass:[NSString class]] && [(NSString*)ins length])

- (void)updateNavigationID:(NSString *)navigationID
                       url:(NSString *)url
              needUpdateCS:(BOOL)needUpdateCS
               startLoadTs:(long)startLoadTs
              loadFinishTs:(long)loadFinishTs
             firstScreenTs:(long)firstScreenTs {
    [self setNavigationID:navigationID];
    [self setUrl:url];
    self.startLoadTs = startLoadTs;
    self.loadFinishTs = loadFinishTs;
    self.firstScreenTs = firstScreenTs;
    
    if (needUpdateCS) {
        [self updateClickStartTs];
    }
}

- (void)setNavigationID:(NSString *)navigationID {
    if (navigationID.length && ![navigationID isEqualToString:self.context.navigationID]) {
        self.context.navigationID = navigationID;
    }
}

- (void)setUrl:(NSString *)url {
    if (url.length) {
        self.context.url = url;
    }
}

- (NSString *)fetchCurrentUrl {
    return self.context.url;
}

- (void)attachNativeBaseContextBlock:(NSDictionary *(^)(NSString *url))block {
    NSMutableArray *mContextList = [[NSMutableArray alloc] initWithArray:self.context.contextBlockList];
    if (block) {
        [mContextList addObject:block];
        self.context.contextBlockList = [[NSArray alloc] initWithArray:mContextList];
    }
}

- (void)attachContainerUUID:(NSString *)containerUUID {
    NSMutableArray *mContainerUUIDList = [[NSMutableArray alloc] initWithArray:self.context.containerUUIDList];
    if (containerUUID) {
        [mContainerUUIDList addObject:containerUUID];
        self.context.containerUUIDList = [[NSArray alloc] initWithArray:mContainerUUIDList];
    }
}

- (void)reportContainerError:(NSString *)virtualAid errorCode:(NSInteger)code errorMsg:(NSString *)msg bizTag:(NSString *)bizTag {
    NSMutableDictionary *extraDic = [NSMutableDictionary dictionary];

    if (virtualAid && virtualAid.length) {
        NSMutableDictionary *nativeBaseDic = [[self.context toNativeBase] mutableCopy];
        nativeBaseDic[@"virtual_aid"] = virtualAid;
        extraDic[kLynxMonitorNativeBase] = [nativeBaseDic copy];
    } else {
        extraDic[kLynxMonitorNativeBase] = [[self.context toNativeBase] copy];
    }

    NSMutableDictionary *containerInfoDic = [NSMutableDictionary dictionary];
    containerInfoDic[@"container_load_error_code"] = @(code);
    containerInfoDic[@"container_load_error_msg"] = msg?:@"";
    extraDic[kLynxMonitorContainerInfo] = [containerInfoDic copy];

    NSString * eventType = @"containerError";
    extraDic[kLynxMonitorEventType] = eventType;
    NSString *serviceName = [NSString stringWithFormat:@"bd_hybrid_monitor_service_%@_%@"
                             ,eventType?:@""
                             ,bizTag?:@""];
    reportSingleDicOnMonitorThread([extraDic copy], serviceName, [self.context.containerUUIDList copy]);
}

- (void)setBdwm_virtualAid:(NSString *)bdwm_virtualAid {
    self.context.virtualAid = bdwm_virtualAid;
}

- (NSString *)bdwm_virtualAid {
    return self.context.virtualAid;
}

- (void)updateClickStartTs {
    self.context.clickStartTs = [BDApplicationStat getLatestClickTimestamp];
}

- (void)prepareCoverForNavigationID:(NSString *)navigationID
                          paramsKey:(NSString *)paramsKey {
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
            if ([paramsKey isEqualToString:kLynxMonitorClientParams]) {
                [clientParams addEntriesFromDictionary:self.config.commonParams];
            }
        };
        if (isString(paramsKey)) {
            prepare(paramsKey);
        }
        [self.pendingParams.allKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL * _Nonnull stop) {
            prepare(key);
        }];
        
        [self.overviewDic setObject:origDic forKey:navigationID];
    }
}

- (void)mergeAccumulateData {
    [self.overviewDic enumerateKeysAndObjectsUsingBlock:^(NSString *navigationID, NSMutableDictionary *overViewRecord, BOOL * _Nonnull stop) {
        NSMutableDictionary *accu = [overViewRecord[kLynxMonitorAccumulateEvent] mutableCopy];
        accu[kLynxMonitorNavigationID] = navigationID;
        [self coverClientParams:accu async:NO];
        [overViewRecord removeObjectForKey:kLynxMonitorAccumulateEvent];
    }];
}

- (NSDictionary *)formatWithDic:(NSDictionary *)dic evType:(NSString *)eventType {
    NSMutableDictionary *mutaDic = (dic[kLynxMonitorNativeBase] && dic[kLynxMonitorNativeInfo]) ? [dic mutableCopy] : [NSMutableDictionary dictionary];
    
    if ([dic count] > 0) {
        NSDictionary *base = mutaDic[kLynxMonitorNativeBase];
        if (!base) {
            mutaDic[kLynxMonitorNativeBase] = [[self.context toNativeBase] copy];
        } else if ([base isKindOfClass:[NSMutableDictionary class]]) {
            mutaDic[kLynxMonitorNativeBase] = [base copy];
        }
        
        NSDictionary *nInfo = mutaDic[kLynxMonitorNativeInfo];
        if (!nInfo) {
            NSMutableDictionary *info = [dic mutableCopy];
            info[kLynxMonitorEventType] = eventType;
            mutaDic[kLynxMonitorNativeInfo] = [info copy];
        } else if ([nInfo isKindOfClass:[NSMutableDictionary class]]) {
            mutaDic[kLynxMonitorNativeInfo] = [nInfo copy];
        }
    }
    
    return [mutaDic copy];
}

- (void)reportPerformance {
    if (self.hasReportPerf) {
        return;
    }
    self.hasReportPerf = YES;
    dispatch_async(self.messageDispatchQueue, ^{
        NSMutableArray *keys = [NSMutableArray array];
        [self.overviewDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSDictionary *record, BOOL * _Nonnull stop) {
            NSMutableDictionary *targetDic = [NSMutableDictionary dictionaryWithDictionary:record];
            long long ts = [IESLiveMonitorUtils formatedTimeInterval];
            [targetDic setValue:@(ts) forKey:@"report_ts"];
            [self reportDirectlyWithDic:targetDic evType:@"performance"];
            [keys addObject:key];
        }];
        // 上报完成后删除对应的key，避免重复上报
        [keys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.overviewDic removeObjectForKey:obj];
        }];
    });
}

- (void)reportDirectlyWithDic:(NSDictionary *)dic evType:(NSString *)eventType {
    if ([dic count] == 0) {
        return;
    }
    
    void (^reportBlock)(void) = ^{
        NSDictionary *newDic = [self formatWithDic:dic evType:eventType];
        NSString *serviceName = [NSString stringWithFormat:@"bd_hybrid_monitor_service_%@_lynx_%@"
                                 ,eventType?:@""
                                 ,self.bizTag?:@""];
        reportSingleDicOnMonitorThread(newDic, serviceName, [self.context.containerUUIDList copy]);
    };
    
    if (dispatch_get_specific(SpecificKey) == (__bridge void *)(self.messageDispatchQueue)) {
        reportBlock();
    } else {
        dispatch_async(self.messageDispatchQueue, ^{
            reportBlock();
        });
    }
    
}

- (void)reportCurrentPage:(NSDictionary *)overview config:(IESLynxMonitorConfig *)config
{
    NSDictionary *overviewDic = [overview copy];
    NSArray *uuidList = [self.context.containerUUIDList copy];
    void(^reportBlock)(void) = ^{
        NSArray *customCoverKeys = @[kLynxMonitorClientMetric, kLynxMonitorClientCategory, kLynxMonitorClientExtra];
        NSArray *customDirectly = @[kLynxMonitorClientCustomDirectly];
        NSArray<NSArray*> *keysGroup = @[customCoverKeys, customDirectly];
        NSArray<NSString*> *serviceGroup = @[@"custom", @"custom"];
        NSMutableArray<NSDictionary*> *valuesGroup = [NSMutableArray array];
        [overviewDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull navigationID, NSMutableDictionary *singleRecord, BOOL * _Nonnull stop) {
            [keysGroup enumerateObjectsUsingBlock:^(NSArray *keys, NSUInteger groupIdx, BOOL * _Nonnull stop) {
                NSMutableDictionary *navigationIDDic = [NSMutableDictionary dictionary];
                valuesGroup[groupIdx] = navigationIDDic;
                [keys enumerateObjectsUsingBlock:^(NSString *customKey, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSDictionary *value = singleRecord[customKey];
                    if (value) {
                        IESLynxClientParamsType type = [value[kClientRecordType] integerValue];
                        void (^formatSrcRecord)(NSMutableDictionary*, NSDictionary*) =
                        ^(NSMutableDictionary *formatRecord, NSDictionary *srcRecord) {
                            formatRecord[kLynxMonitorServiceType] = serviceGroup[groupIdx];
                            formatRecord[kLynxMonitorEventType] = @"custom";
                            formatRecord[kLynxMonitorNavigationID] = navigationID;
                            formatRecord[kLynxMonitorURL] = srcRecord[kLynxMonitorURL];
                            formatRecord[kLynxMonitorPid] = srcRecord[kLynxMonitorPid];
                            formatRecord[kLynxMonitorBid] = srcRecord[kLynxMonitorBid];
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
            reportWithDic(overviewDic, config, uuidList);
        }
        if (valuesGroup.count) {
            for (NSDictionary *navigationRecord in valuesGroup) {
                for (id obj in navigationRecord.allValues) {
                    if ([obj isKindOfClass:[NSDictionary class]]) {
                        reportSingleRecordDic(obj, config, uuidList);
                    } else if ([obj isKindOfClass:[NSArray class]]) {
                        [(NSArray*)obj enumerateObjectsUsingBlock:^(id  _Nonnull record, NSUInteger idx, BOOL * _Nonnull stop) {
                            reportSingleRecordDic(record, config, uuidList);
                        }];
                    }
                }
            }
        }
    };
    if (dispatch_get_specific(SpecificKey) == (__bridge void *)(self.messageDispatchQueue)) {
        reportBlock();
    } else {
        dispatch_async(self.messageDispatchQueue, ^{
            reportBlock();
        });
    }

}

- (NSDictionary*)formatORIGDic:(NSDictionary *)dic {
    NSMutableDictionary *muteDic = [dic mutableCopy];
    if (!muteDic[kLynxMonitorNavigationID] || [muteDic[@"firstPage"] boolValue]) {
        muteDic[kLynxMonitorNavigationID] = self.config.sessionID ?: @"";
    }
    return [muteDic copy];
}

#pragma mark - public api

- (void)coverWithDic:(NSDictionary *)srcDic {
    if (![srcDic isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSString *curNavID = [self.context.navigationID copy];
    void(^block)(void) = ^{
        NSString *navigationId = curNavID ? curNavID : self.context.navigationID;
        NSMutableDictionary *overviewDic = self.overviewDic;
        if (isString(navigationId)) {
            NSMutableDictionary *origDic = overviewDic[navigationId];
            if (![origDic isKindOfClass:[NSMutableDictionary class]]) {
                origDic = [NSMutableDictionary dictionary];
                overviewDic[navigationId] = origDic;
            }
            if (!origDic[kLynxMonitorNativeBase]) {
                NSDictionary *nativeBaseDic = [self.context toNativeBase];
                if (![curNavID isEqualToString: nativeBaseDic[kLynxMonitorNavigationID]]) {
                    NSMutableDictionary *mutDict = [nativeBaseDic mutableCopy];
                    mutDict[kLynxMonitorNavigationID] = curNavID;
                    nativeBaseDic = mutDict;
                }
                origDic[kLynxMonitorNativeBase] = [nativeBaseDic copy];
            }

            NSMutableDictionary *nativeInfo = origDic[kLynxMonitorNativeInfo];
            if (![nativeInfo isKindOfClass:[NSMutableDictionary class]]) {
                nativeInfo = [NSMutableDictionary dictionary];
                nativeInfo[kLynxMonitorEventType] = @"performance";
                origDic[kLynxMonitorNativeInfo] = nativeInfo;
            }
            
            [srcDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                nativeInfo[key] = obj;
            }];
        }
    };
    
    if (dispatch_get_specific(SpecificKey) == (__bridge void *)(self.messageDispatchQueue)) {
        block();
    } else {
        dispatch_async(self.messageDispatchQueue, block);
    }
}

- (void)coverClientParams:(NSDictionary *)srcDic async:(BOOL)async
{
    [self addClientParams:srcDic paramsKey:kLynxMonitorClientParams addType:IESLynxAddByCover async:async];
};

- (void)addClientParams:(NSDictionary *)srcDic
              paramsKey:(NSString *)paramsKey
                addType:(IESLynxAddParamsType)addType
                  async:(BOOL)async
{
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
        NSMutableArray *records = muteDic[kClientRecordValue] ?: [NSMutableArray array];
        if (srcDic.count) {
            [records addObject:srcDic];
            muteDic[kClientRecordValue] = records;
        }
        return muteDic;
    };
    
    void(^block)(void) = ^{
        NSDictionary *dic = [self formatORIGDic:srcDic];
        NSString *navigationID = dic[kLynxMonitorNavigationID];
        if (isString(navigationID)) {
            [self prepareCoverForNavigationID:navigationID
                                    paramsKey:paramsKey];
            if (isString(paramsKey)) {
                self.overviewDic[navigationID][paramsKey] = (addType == IESLynxAddByCover ? mergedCustomReportDic(self.overviewDic[navigationID][paramsKey]) :
                                                             addType == IESLynxAddByCoverOnce ?
                    mergedCustomReportDicOnce(self.pendingParams[paramsKey]):
                    appendCustomReportDic(self.overviewDic[navigationID][paramsKey]));
            }
        } else if (isString(paramsKey)) {
            self.pendingParams[paramsKey] = (addType == IESLynxAddByCover ? mergedCustomReportDic(self.pendingParams[paramsKey]) :
                                             addType == IESLynxAddByCoverOnce ?
            mergedCustomReportDicOnce(self.pendingParams[paramsKey]) :
                appendCustomReportDic(self.pendingParams[paramsKey]));
        }
    };
    if (async) {
        if (dispatch_get_specific(SpecificKey) == (__bridge void *)(self.messageDispatchQueue)) {
            block();
        } else {
            dispatch_async(self.messageDispatchQueue, block);
        }
    } else {
        block();
    }
}

- (void)reportRequestError:(NSError *)error {
    [self reportRequestError:error isCustom:NO];
}

- (void)feCustomReportRequestError:(NSError *)error {
    [self reportRequestError:error isCustom:YES];
}

// 上报request error
- (void)reportRequestError:(NSError *)error isCustom:(BOOL)isCustom {
    NSString *message = [error.userInfo valueForKey:@"message"];
    if (!message ||  ![message isKindOfClass:NSString.class]) {
        NSError *sourceError = [error.userInfo objectForKey:@"sourceError"];
        if (sourceError && [sourceError isKindOfClass:NSError.class]) {
            message = sourceError.localizedDescription?:@"";
        } else {
            message = error.domain ?: @"";
        }
    }
    NSDictionary *errorDic = @{kLynxMonitorNativeBase: [self.context toNativeBase],
                 kLynxMonitorNativeInfo:
                     @{  kLynxMonitorEventType: @"nativeError",
                         kLynxMonitorScene: isCustom?@"lynx_error_custom":@"lynx_error",
                         @"error_code" : @(error.code),
                         @"error_msg" : message?:@""
                     }
    };
    
    [self reportDirectlyWithDic:errorDic evType:@"nativeError"];
}

// 上报navigationstart
- (void)reportNavigationStart {
    long long ts = [IESLiveMonitorUtils formatedTimeInterval];
    NSDictionary *dic = @{
        kLynxMonitorEventType: @"navigationStart",
        @"invoke_ts": @(ts)
    };
    [self reportDirectlyWithDic:dic evType:@"navigationStart"];
}

#pragma mark custom report
// 自定义埋点上报（覆盖类型）
- (void)coverWithEventName:(NSString *)eventName
              clientMetric:(NSDictionary *)metric
            clientCategory:(NSDictionary *)category
                     extra:(NSDictionary *)extra
                       url:(NSString *)url
{
    if (!eventName.length) {
        return;
    }
    dispatch_async(self.messageDispatchQueue, ^{
        NSMutableDictionary *muteExtra = [extra ?: @{} mutableCopy];
        muteExtra[kLynxMonitorEventName] = eventName;
        NSDictionary *dic = @{
            kLynxMonitorClientMetric : metric ?: @{},
            kLynxMonitorClientCategory : category ?: @{},
            kLynxMonitorClientExtra : [muteExtra copy] ?: @{},
        };
        [dic enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL * _Nonnull stop) {
            [self addClientParams:obj paramsKey:key addType:IESLynxAddByCover async:NO];
        }];
    });
}

// 立即上报自定义埋点
- (void)reportDirectlyWithEventName:(NSString *)eventName
                       clientMetric:(NSDictionary *)metric
                     clientCategory:(NSDictionary *)category
                              extra:(NSDictionary *)extra
                                url:(NSString *)url
{
    if (!eventName.length) {
        return;
    }
    NSMutableDictionary *muteExtra = [extra ?: @{} mutableCopy];
    muteExtra[kLynxMonitorEventName] = eventName;
    NSDictionary *record = @{
        kLynxMonitorClientMetric : metric ?: @{},
        kLynxMonitorClientCategory : category ?: @{},
        kLynxMonitorClientExtra : [muteExtra copy] ?: @{},
    };
    [self addClientParams:record paramsKey:kLynxMonitorClientCustomDirectly addType:IESLynxAddByAppend async:YES];
}

- (void)reportCustomWithDic:(NSDictionary *)dic {
    if ([dic isKindOfClass:[NSDictionary class]]) {
        NSDictionary *metric = [dic[@"metrics"] isKindOfClass:[NSDictionary class]] ? dic[@"metrics"] : @{};
        NSDictionary *category = [dic[@"category"] isKindOfClass:[NSDictionary class]] ? dic[@"category"] : @{};
        NSDictionary *extra = [dic[@"extra"] isKindOfClass:[NSDictionary class]] ? dic[@"extra"] : @{};
        NSString *url = [dic[@"url"] isKindOfClass:[NSString class]] ? dic[@"url"] : self.config.url;
        NSInteger type = [dic[@"type"] integerValue];
        
        switch (type) {
            case IESLynxMonitorCustomReportDirectly:
                [self reportDirectlyWithEventName:extra[kLynxMonitorEventName]
                                     clientMetric:metric
                                   clientCategory:category
                                            extra:extra
                                              url:url];
                break;
                
            case IESLynxMonitorCustomReportCover:
                [self coverWithEventName:extra[kLynxMonitorEventName]
                            clientMetric:metric
                          clientCategory:category
                                   extra:extra
                                     url:url];
            default:
                break;
        }
    }
}

- (void)setContainerReuse:(BOOL)isReuse {
    self.context.isContainerReuse = isReuse;
}

- (void)updateAttachTS:(long long)attachTS {
    self.context.attachTS = attachTS;
    self.context.detachTS = 0; // 每次更新attach的时候 把detach时间置为0, 防止detach的时间是上次生命周期的;
}

- (void)updateDetachTS:(long long)detachTS {
    self.context.detachTS = detachTS;
}

- (void)updateLynxCardVersion:(NSString *)cardVersion {
    self.context.cardVersion = cardVersion;
}

- (long long)attachTS {
    return self.context.attachTS;
}

@end
