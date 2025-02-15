//
//  BDAutoTrackBatchService.m
//  Applog
//
//  Created by bob on 2019/1/28.
//

#import "BDAutoTrackBatchService.h"
#import "NSDictionary+VETyped.h"
#import "BDAutoTrackBatchData.h"
#import "BDTrackerCoreConstants.h"
#import "BDAutoTrackSessionHandler.h"
#import "BDAutoTrackReachability.h"
#import "BDAutoTrackUtility.h"

#import "BDAuoTrackEventBlock.h"
#import "BDAutoTrackBatchSchedule.h"
#import "BDAutoTrackBatchTimer.h"
#import "BDAutoTrackBatchPacker.h"
#import "BDAutoTrackParamters.h"
#import "BDAutoTrackEventUntils.h"

#import "BDAutoTrackDatabaseService.h"
#import "BDAutoTrackRemoteSettingService.h"
#import "BDAutoTrackRegisterService.h"

#import "BDAutoTrackServiceCenter.h"
#import "BDAutoTrackNetworkRequest.h"


#import "BDAutoTrack.h"
#import "BDAutoTrack+Private.h"
#import "BDAutoTrackSettingsRequest.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackURLHostProvider.h"

#import "RangersLog.h"
#import "RangersRouter.h"
#import "NSMutableDictionary+BDAutoTrackParameter.h"
#import "BDAutoTrackerDefines.h"
// 已经在sendingQueue上

static const NSUInteger        kEventMaxCountPerRequest    = 200;

@interface BDAutoTrackBatchService () {
    BOOL realtimeBatchInLine;
}

@property (nonatomic, strong) dispatch_queue_t sendingQueue;
@property (nonatomic, assign) BDAutoTrackTriggerSource fromType;
@property (nonatomic, strong) BDAutoTrackBatchSchedule *schedule;
@property (nonatomic, strong) BDAutoTrackBatchTimer *batchTimer;
@property (nonatomic, strong) BDAuoTrackEventBlock *eventBlcok;

@property (nonatomic, assign) CFTimeInterval requestStartTime;

@property (nonatomic, assign) long long lastManuallyTime;

/// appID关联的track实例
@property (nonatomic, weak) BDAutoTrack *associatedTrack;

@end

@implementation BDAutoTrackBatchService

#pragma mark - public

- (instancetype)initWithAppID:(NSString *)appID {
    self = [super initWithAppID:appID];
    if (self) {
        self.serviceName = BDAutoTrackServiceNameBatch;
        NSString *queueName = [NSString stringWithFormat:@"com.applog.log_%@",appID];
        self.sendingQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL);
        self.fromType = BDAutoTrackTriggerSourceInitApp;
        self.schedule = [[BDAutoTrackBatchSchedule alloc] initWithAppID:appID];
        self.batchTimer = [[BDAutoTrackBatchTimer alloc] initWithAppID:appID];
        self.batchTimer.request = self;
        self.eventBlcok = [[BDAuoTrackEventBlock alloc] initWithAppID:appID];
        self.lastManuallyTime = 0;
        self.associatedTrack = [BDAutoTrack trackWithAppID:appID];
        RL_INFO(self.associatedTrack,@"Uploader", @"Module enabled");
    }
    
    return self;
}


+ (BOOL)syncBatch:(BDAutoTrack *)tracker withEvents:(NSArray *)events
{
    NSString *appId = tracker.appID;
    NSString *requestURL = [[BDAutoTrackURLHostProvider sharedInstance] URLForURLType:BDAutoTrackRequestURLLog appID:appId];
    requestURL = bd_appendQueryToURL(requestURL, kBDAutoTrackAPPID, appId);
    
    //pack
    BDAutoTrackBatchData *batch = [BDAutoTrackBatchData new];
    batch.sendingTrackData = @{@"event_v3": events};
    [batch filterData];
    
    NSMutableDictionary *batchBody = [self postBody:tracker withBatchData:batch];
    
    //fix ssid, 监控埋点不依赖ssid属性，防止服务端针对ssid引起的性能问题，再header缺失ssid的场景下随机生成
    NSMutableDictionary* header = [batchBody objectForKey:kBDAutoTrackHeader];
    id ssid = [header objectForKey:kBDAutoTrackSSID];
    if (ssid == nil || ssid == [NSNull null]) {
        [header setValue:[NSUUID UUID].UUIDString forKey:kBDAutoTrackSSID];
    }
    
    NSDictionary *requestBody = bd_filterSensitiveParameters(batchBody, tracker.appID);
    bd_handleCommonParamters(requestBody, tracker, BDAutoTrackRequestURLLog);
    NSDictionary *responseDict = bd_network_syncRequestForURL(requestURL,
                                                              @"POST",
                                                              bd_headerField(appId),
                                                              requestBody,
                                                              tracker.networkManager);
    
    BOOL success = bd_isValidResponse(responseDict) && bd_isResponseMessageSuccess(responseDict);
    return success;
    
}


 




- (void)sendTrackDataFrom:(NSInteger)from {
    [self sendTrackDataFrom:from flushTimeInterval:10];  // Flush
}

/// `sendTrackDataFrom:` 的实现。私有方法。
/// @param from 上报触发源
/// @param flushTimeInterval 当来源为BDAutoTrackTriggerSourceManually时生效。为两次flush操作间的最小时间间隔。默认为10. 若设置为<=0，则立即flush。
- (void)sendTrackDataFrom:(NSInteger)from flushTimeInterval:(NSInteger)flushTimeInterval {
    // 网络不通，不上报
    RL_DEBUG(self.associatedTrack,@"Uploader",@"Trigger upload [source: %d]", from);
    // 没有注册，不上报
    if (!bd_registerServiceAvailableForAppID(self.appID)) {
        [self.batchTimer endBackgroundTask];
        RL_WARN(self.associatedTrack,@"Uploader",@"terminate due to NOT Register successful.");
        return;
    }
    
    if (from == BDAutoTrackTriggerSourceManually) {
        long long now = CACurrentMediaTime();
        if (now - self.lastManuallyTime < flushTimeInterval) {
            RL_WARN(self.associatedTrack,@"Uploader",@"terminate due to MANUALLY TOO OFFEN.");
            return;
        }
        self.lastManuallyTime = now;
    }
    
    dispatch_async(self.sendingQueue,^{
        @autoreleasepool {
            [self sendTrackDataInternalFrom:from
                                    options:nil
                                    handler:nil];
        }
    });
}

- (void)realtimeEventBatch
{
    if (self->realtimeBatchInLine) {
        return;
    }
    self->realtimeBatchInLine = YES;
    dispatch_async(self.sendingQueue,^{
        self->realtimeBatchInLine = NO;
        [self sendTrackDataInternalFrom:BDAutoTrackTriggerSourceRealtime
                                options:@{@"priority":@(BDAutoTrackEventPriorityRealtime)}
                                handler:nil];
        
    });
}

#pragma mark - private

/// caller：`sendTrackDataFrom: flushTimeInterval:`
/// 执行队列: self.sendingQueue
/// @param from 上报触发源
- (void)sendTrackDataInternalFrom:(NSInteger)from
                          options:(nullable NSDictionary *)options
                          handler:(void(^)(void))handler {
    
    if (from != BDAutoTrackTriggerSourceRealtime) {
        //realtime batch do not restore bulk counter;
        [self.associatedTrack.eventGenerator restoreBulkCounter];
    }
    self.fromType = from;
    // 耗时操作：需要读数据库和反序列化。
    // 将多个表的埋点数据汇聚到sendingTask(BDAutoTrackBatchData)。
    NSDictionary<NSString *, NSArray *> *allTracks = [bd_databaseServiceForAppID(self.appID) allTracksForBatchReport:options];
    
    NSArray *tasks = bd_batchPackAllTracksSplitByUUID(allTracks, kEventMaxCountPerRequest);
    if (tasks.count == 0) {
        RL_DEBUG(self.associatedTrack,@"Uploader",@"terminate due to NO DATA.");
    }
    // 耗时操作：上报埋点（同步网络请求）
    __block NSUInteger currentEventCount = 0;
    __block BOOL tasksAllSuccess = YES;
    [tasks enumerateObjectsUsingBlock:^(BDAutoTrackBatchData*  _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
        
        task.source = from;
        
        currentEventCount += task.maxEventCount;
        
        if (task.maxEventCount < 1)  {
            RL_DEBUG(self.associatedTrack,@"Uploader",@"terminate due to NO DATA.");
            return;
        }
        
        if ([task.ssID length] == 0) { //SSID 回补
            NSString *ssid = [RangersRouter sync:[RangersRouting routing:@"ssid"
                                                                    base:self.appID
                                                              parameters: @{
                kBDAutoTrackEventUserID: task.userUniqueID?:[NSNull null],
                kBDAutoTrackEventUserIDType: task.userUniqueIDType?:[NSNull null]
            }]];
            if ([ssid length] > 0) {
                task.ssID = ssid;
            } else {
                tasksAllSuccess = NO;
                RL_WARN(self.associatedTrack,@"Uploader",@"terminate due to FAILURE FIX SSID.");
                return;
            }
            
        }
        
        [task checkSendData:task.ssID];
        
        task.autoTrackEnabled = bd_remoteSettingsForAppID(self.appID).autoTrackEnabled;
        [task filterData];
        if (task.realSentData.count < 1) {
            tasksAllSuccess = NO;
            [self.batchTimer endBackgroundTask];
            RL_INFO(self.associatedTrack,@"Uploader",@"terminate due to NO DATA.");
            return;
        }
        
        if (from != BDAutoTrackTriggerSourceRealtime) {
            if (![self.schedule actionInSchedule]) {
                if (from != BDAutoTrackTriggerSourceEnterBackground) {
                    tasksAllSuccess = NO;
                    [self.batchTimer endBackgroundTask];
                    RL_WARN(self.associatedTrack,@"Uploader",@"terminate due to FLOW CONTROL.");
                    return;
                }
            }
        }

        BOOL success = [self sendTrackDataInternalFirstTime:YES task:task];
        if (success) {
            RL_DEBUG(self.associatedTrack,@"Uploader",@"request successful .");
        } else {
            tasksAllSuccess = NO;
            RL_DEBUG(self.associatedTrack,@"Uploader",@"request failure .");
        }
    }];
    
    if (handler != nil) {
        handler();
    }
    /// 要尽量上报 且上报成功 且还有日志
    /// 批量上报，每次最多200条(kEventMaxCountPerRequest)，直到库存日志<200条。
        
    if (tasksAllSuccess
        && currentEventCount >= kEventMaxCountPerRequest) {
        [self sendTrackDataFrom:from];
    } else {
        /// 后台上报成功之后，Vacuum或者迁移到Vacuum的DB
        if (from == BDAutoTrackTriggerSourceEnterBackground && tasksAllSuccess) {
            [bd_databaseServiceForAppID(self.appID) vacuumDatabase];
        }
        
        [self.batchTimer endBackgroundTask];
    }
}

#pragma mark request
/// HTTP 请求 body
- (NSMutableDictionary *)requestParametersWithData:(NSDictionary *)data {
    NSMutableDictionary *result = [NSMutableDictionary new];
    /* BEGIN header */
    NSMutableDictionary *header = bd_requestPostHeaderParameters(self.appID);
    bd_addABVersions(header, self.appID);
    /* END header */
    
    [result setValue:BDAutoTrackMagicTag forKey:kBDAutoTrackMagicTag];
    
    
#if TARGET_OS_IOS
    /* alink utm */
    BDAutoTrack *track = [BDAutoTrack trackWithAppID:self.appID];
    NSDictionary *utmData = [track.alinkActivityContinuation alink_utm_data];
    [header addEntriesFromDictionary:utmData];
    [header setValue:[track.alinkActivityContinuation tracerData] forKey:kBDAutoTrackTracerData];
#endif
    [result setValue:header forKey:kBDAutoTrackHeader];
    [result setValue:[track.localConfig serverTime] forKey:kBDAutoTrackTimeSync];
    [result setValue:@(bd_currentInterval().longLongValue) forKey:kBDAutoTrackLocalTime];

    if ([data isKindOfClass:[NSDictionary class]] && data.count > 0) {
        [result addEntriesFromDictionary:data];
    }
    
    return result;
}

/// 上报埋点
/// 发送网络请求的方法是同步的 `bd_network_syncRequestForURL`
/// @param first 是否为本次重试策略的第一次请求上报。如果非第一次上报，则启用备选URL。
- (BOOL)sendTrackDataInternalFirstTime:(BOOL)first task:(BDAutoTrackBatchData *)task {
    
    
    self.requestStartTime = CFAbsoluteTimeGetCurrent();
    NSString *appID = self.appID;
    
    BDAutoTrackRequestURLType type = first ? BDAutoTrackRequestURLLog : BDAutoTrackRequestURLLogBackup;
    
    NSString *requestURL = [[BDAutoTrackURLHostProvider sharedInstance] URLForURLType:type appID:appID];
    requestURL = bd_appendQueryToURL(requestURL, kBDAutoTrackAPPID, appID);
    RL_DEBUG(self.associatedTrack,@"Uploader",@"request start use primay(%d) (count:%d). (%@)",first, task.maxEventCount, requestURL);
    task.sendTime = [[NSDate date] timeIntervalSince1970];
    
    NSDictionary *requestBody = [self postHandlerParameters:task];
    //sensitive fields filter
    requestBody = bd_filterSensitiveParameters(requestBody, self.associatedTrack.appID);
    bd_handleCommonParamters(requestBody, self.associatedTrack, type);
    NSDictionary *responseDict = bd_network_syncRequestForURL(requestURL,
                                                              @"POST",
                                                              bd_headerField(appID),
                                                              requestBody,
                                                              self.associatedTrack.networkManager);

    return [self handleBatchSendCallback:responseDict firstTime:first task:task];
}

- (NSMutableDictionary *)postHandlerParameters:(BDAutoTrackBatchData *)task
{
    NSDictionary *data = task.realSentData;
    NSMutableDictionary *body = [self requestParametersWithData:data];
    
    //update header from event
    //user_unique_id
    //$user_unique_id_type
    
    id _any = [body objectForKey:kBDAutoTrackHeader];
    if ([_any isKindOfClass:NSDictionary.class]) {
        NSMutableDictionary *header = [_any mutableCopy];
        [header setValue:task.userUniqueID ?: [NSNull null] forKey:kBDAutoTrackEventUserID];
        [header setValue:task.userUniqueIDType ?: [NSNull null] forKey:kBDAutoTrackEventUserIDType];
        [header setValue:task.ssID forKey:kBDAutoTrackSSID];
        [header bdheader_keyFormat];
        [body setValue:header forKey:kBDAutoTrackHeader];
    }
    return body;
}

+ (NSMutableDictionary *)postBody:(BDAutoTrack *)tracker withBatchData:(BDAutoTrackBatchData *)batch
{
    NSMutableDictionary *result = [NSMutableDictionary new];
    /* BEGIN header */
    NSMutableDictionary *header = bd_requestPostHeaderParameters(tracker.appID);
    bd_addABVersions(header, tracker.appID);
    /* END header */
    [result setValue:BDAutoTrackMagicTag forKey:kBDAutoTrackMagicTag];
    
    
#if TARGET_OS_IOS
    /* alink utm */
    NSDictionary *utmData = [tracker.alinkActivityContinuation alink_utm_data];
    [header addEntriesFromDictionary:utmData];
    [header setValue:[tracker.alinkActivityContinuation tracerData] forKey:kBDAutoTrackTracerData];
#endif
    [result setValue:header forKey:kBDAutoTrackHeader];
    [result setValue:[tracker.localConfig serverTime] forKey:kBDAutoTrackTimeSync];
    [result setValue:@(bd_currentInterval().longLongValue) forKey:kBDAutoTrackLocalTime];

    id batchEvents = batch.realSentData;
    if (batchEvents && [batchEvents isKindOfClass:[NSDictionary class]]) {
        [result addEntriesFromDictionary:batchEvents];
    }
    return result;
}


#pragma mark - response handling

/// 处理批量上报结果的回调. 若响应为成功，则删除已成功的上报；若响应为失败，则重试上报。
/// caller: -[BDAutoTrackBatchServicex sendTrackDataInternalFirstTime:]
/// @param responseDict 响应数据
/// @param first 是否为本轮的第一次上报
/// @param sendingTask 本轮上报要发生的数据
- (BOOL)handleBatchSendCallback:(NSDictionary *)responseDict firstTime:(BOOL)first task:(BDAutoTrackBatchData *)sendingTask {
    BOOL sendingSuccess = bd_isValidResponse(responseDict) && bd_isResponseMessageSuccess(responseDict);
    NSInteger statusCode = [responseDict vetyped_integerForKey:kBDAutoTrackRequestHTTPCode];
    NSString *appID = self.appID;

    if (statusCode == 200 && sendingSuccess) {
        [self.schedule scheduleWithHTTPCode:statusCode];
        
        //统计耗时
        BDAutoTrack *tracker = [BDAutoTrack trackWithAppID:self.appID];
        
        [tracker.localConfig updateServerTime:responseDict];
        
        NSTimeInterval sendTime = sendingTask.sendTime;
        [sendingTask.sendingTrackData enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray * _Nonnull events, BOOL * _Nonnull stop) {
            
            [events enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                NSNumber *eventTime = [obj objectForKey:@"local_time_ms"];
                if ([eventTime isKindOfClass:[NSNumber class]]) {
                    NSTimeInterval delay = sendTime*1000 - [eventTime doubleValue];
                    [[BDAutoTrack trackWithAppID:self.appID].monitorAgent trackMetrics:BDroneUsageDataUploadDelay value:@(delay) category:BDroneUsageCategory dimensions:@{@"data_type":key ?:@""}];
                }
                if (tracker.eventBlock) {
                    NSString *event = [obj objectForKey:@"event"];
                    BDAutoTrackEventAllType type = bd_get_event_alltype(key, event);
                    if (!event) {
                        if (type == BDAutoTrackEventAllTypeLaunch) {
                            event = @"$launch";
                        } else if (type == BDAutoTrackEventAllTypeTerminate) {
                            event = @"$terminate";
                        }
                    }
                    tracker.eventBlock(BDAutoTrackEventStatusReported, type, event, obj);
                }
            }];
            
        }];
        // 删除已成功发送的埋点
        bd_databaseRemoveTracks(sendingTask.sendingTrackID, appID);
        
        // 更新 blockList
        NSDictionary *blockListAll = [responseDict vetyped_dictionaryForKey:@"blocklist"];
        if (blockListAll) {
            NSArray *blockList = [blockListAll vetyped_arrayForKey:@"v3"];
            [self.eventBlcok updateBlockList:blockList];
        } else {
            [self.eventBlcok updateBlockList:@[]];
        }
        
    } else {
        // 上报埋点数据失败
        if (first) {
            // 重试发送，标记为非首次发送以使用备用URL。
            sendingSuccess = [self sendTrackDataInternalFirstTime:NO task:sendingTask];
            return sendingSuccess;
        }
        
        [self.schedule scheduleWithHTTPCode:statusCode];
        if (sendingTask.source == BDAutoTrackTriggerSourceRealtime) {
            bd_databaseDowngradeTracks(sendingTask.sendingTrackID, appID);
        }
    }
    
    return sendingSuccess;
}

@end

#pragma mark - C

void bd_batchUpdateTimer(CFTimeInterval interval, BOOL skipLaunch, NSString *appID) {
    BDAutoTrackBatchService *service = (BDAutoTrackBatchService *)bd_standardServices(BDAutoTrackServiceNameBatch, appID);
    [service.batchTimer updateTimerInterval:interval];
    service.batchTimer.skipLaunch = skipLaunch;
}

BOOL bd_batchIsEventInBlockList(NSString *event, NSString *appID) {
    BDAutoTrackBatchService *service = (BDAutoTrackBatchService *)bd_standardServices(BDAutoTrackServiceNameBatch, appID);
    if (service && [service.eventBlcok hasEvent:event]) {
        return YES;
    }

    return NO;
}
