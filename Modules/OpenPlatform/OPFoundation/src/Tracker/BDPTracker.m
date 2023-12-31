//
//  BDPTracker.m
//  Timor
//
//  Created by 维旭光 on 2018/12/7.
//

#import "BDPTracker.h"
#import "BDPUtils.h"
#import "BDPMacroUtils.h"
#import "BDPTimorClient.h"
#import "BDPTrackerEvent.h"
#import "BDPVersionManager.h"
#import "BDPTrackerParamInfo.h"

#import "BDPTracker+Private.h"
#import <JavaScriptCore/JavaScriptCore.h>

static NSString *const kLastPagePathKey = @"last_page_path";
static NSString *const kHasWebviewKey = @"has_webview";
static NSString *const kLastHasWebviewKey = @"last_has_webview";
static NSString *const kExitTypeKey = @"exit_type";

// 计算事件超时时间，单位秒
static const NSUInteger kTimingEventTimeout = 30 * 60;

// 清除超时计算事件任务间隔，单位秒
static const NSUInteger kClearOverdueTimingEventInterval = 5 * 60;

@interface BDPTracker ()

@property (nonatomic, strong) NSMutableDictionary<OPAppUniqueID *, BDPTrackerParamInfo *> *commonParamDic;
@property (nonatomic, strong) NSMutableDictionary<NSString *, BDPTrackerTimingEvent *> *timingEventDic;
@property (nonatomic, strong) NSMutableArray<BDPTrackerPageEvent *> *pageEventArr;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *tagDic;

@property (nonatomic, strong) NSTimer *clearOverdueEventTimer;

@property (nonatomic, strong) id<BDPTrackerPluginDelegate> trackerPlugin;

@end

@implementation BDPTracker

+ (instancetype)sharedInstance {
    static BDPTracker *sInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sInstance = [[self alloc] init];
    });
    return sInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _tagDic = [NSMutableDictionary new];
        _taskQueue = dispatch_queue_create("com.bytedance.timor.tracker.serialqueue", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(_taskQueue, (__bridge void *)[self class], (__bridge void *)self, NULL);
    }
    return self;
}


#pragma mark - Event Interface

+ (void)event:(NSString *)eventId attributes:(nullable NSDictionary *)attributes uniqueID:(nullable BDPUniqueID *)uniqueID {
    [self event:eventId attributes:attributes withCommonParams:YES uniqueID:uniqueID];
}

+ (void)event:(NSString *)eventId attributes:(nullable NSDictionary *)attributes withCommonParams:(BOOL)withCommonParams uniqueID:(nullable BDPUniqueID *)uniqueID {
    [[BDPTracker sharedInstance] _event:eventId attributes:attributes withCommonParams:withCommonParams uniqueID:uniqueID];
}

+ (void)beginEvent:(NSString *)eventId primaryKey:(NSString *)keyName attributes:(nullable NSDictionary *)attributes uniqueID:(nullable BDPUniqueID *)uniqueID {
    [BDPTracker beginEvent:eventId primaryKey:keyName attributes:attributes reportStart:YES uniqueID:uniqueID];
}

+(void)beginEvent:(NSString *)eventId primaryKey:(NSString *)keyName attributes:(NSDictionary *)attributes reportStart:(BOOL)reportStart uniqueID:(nullable BDPUniqueID *)uniqueID {
    [[BDPTracker sharedInstance] _beginEvent:eventId primaryKey:keyName attributes:attributes reportStart:reportStart uniqueID:uniqueID];
}

+ (void)endEvent:(NSString *)eventId primaryKey:(NSString *)keyName attributes:(nullable NSDictionary *)attributes uniqueID:(nullable BDPUniqueID *)uniqueID {
    [[BDPTracker sharedInstance] _endEvent:eventId primaryKey:keyName attributes:attributes uniqueID:uniqueID];
}

+ (void)beginLogPageView:(NSString *)pagePath query:(NSString *)query hasWebview:(BOOL)hasWebview uniqueID:(nullable BDPUniqueID *)uniqueID {
    [[BDPTracker sharedInstance] _beginLogPageView:pagePath query:query hasWebview:hasWebview uniqueID:uniqueID];
}

+ (void)endLogPageView:(NSString *)pagePath query:(NSString *)query duration:(NSUInteger)duration exitType:(NSString *)exitType uniqueID:(nullable BDPUniqueID *)uniqueID {
    [[BDPTracker sharedInstance] _endLogPageView:pagePath query:query duration:duration exitType:exitType uniqueID:uniqueID];
}


#pragma mark - Utils

+ (void)setTag:(NSString *)key value:(nullable NSString *)value {
    if (!BDPIsEmptyString(key)) {
        [[BDPTracker sharedInstance].tagDic setValue:value forKey:key];
    }
}

+ (NSString *)getTag:(NSString *)key {
    NSString *value = nil;
    if (!BDPIsEmptyString(key)) {
        value = [[BDPTracker sharedInstance].tagDic valueForKey:key];
    }
    return value;
}

+ (NSMutableDictionary *)buildJSContextParams:(JSContext *)context {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:2];
    JSValue *exception = [context exception];
    
    if (exception && ![exception isNull] && ![exception isUndefined]) {
        [params setValue:BDPTrackerResultFail forKey:BDPTrackerResultTypeKey];
        [params setValue:[exception toString] forKey:BDPTrackerErrorMsgKey];
    } else {
        [params setValue:BDPTrackerResultSucc forKey:BDPTrackerResultTypeKey];
        [params setValue:@"" forKey:BDPTrackerErrorMsgKey];
    }
    
    return params;
}

+ (NSString *)buildPrimaryKeyWithEventId:(NSString *)eventId uniqueID:(nullable BDPUniqueID *)uniqueID {
    NSString *pk = nil;
    if (!BDPIsEmptyString(eventId)) {
        pk = [NSString stringWithFormat:@"%@_%@", eventId, uniqueID ?: @""];
    }
    return pk;
}

+ (NSMutableDictionary *)enterPageCommonParam:(NSString *)pagePath query:(NSString *)query hasWebview:(BOOL)hasWebview uniqueID:(BDPUniqueID *)uniqueID {
    BDPTrackerParamInfo *paramInfo = [BDPTracker paramInfoForUniqueID:uniqueID];
    NSString *lastPagePath = paramInfo.lastPath ?: @"";
    NSMutableDictionary *param = [NSMutableDictionary new];
    [param setValue:pagePath forKey:BDPTrackerPagePathKey];
    [param setValue:@(hasWebview) forKey:kHasWebviewKey];
    [param setValue:lastPagePath forKey:kLastPagePathKey];
    return param;
}

#pragma Event Management

- (void)_addTimeingEvent:(NSString *)primaryKey {
    if (!BDPIsEmptyString(primaryKey)) {
        WeakSelf;
        [self executeBlkInTaskQueue:^{
            StrongSelfIfNilReturn;
            BDPTrackerTimingEvent *event = [[BDPTrackerTimingEvent alloc] init];
            [self.timingEventDic setValue:event forKey:primaryKey];
        }];
    }
}

- (BDPTrackerTimingEvent *)_getTimingEvent:(NSString *)primaryKey {
    BDPTrackerTimingEvent *event = nil;
    if (!BDPIsEmptyString(primaryKey)) {
        event = [_timingEventDic objectForKey:primaryKey];
    }
    return event;
}

- (void)_removeTimingEvent:(NSString *)primaryKey {
    if (!BDPIsEmptyString(primaryKey)) {
        WeakSelf;
        [self executeBlkInTaskQueue:^{
            StrongSelfIfNilReturn;
            [self.timingEventDic removeObjectForKey:primaryKey];
        }];
    }
}

- (void)_clearOverdueTimingEvent {
    WeakSelf;
    [self executeBlkInTaskQueue:^{
        StrongSelfIfNilReturn;
        NSMutableArray *keysToRemove = [NSMutableArray new];
        
        [self.timingEventDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, BDPTrackerTimingEvent * _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj.duration > kTimingEventTimeout * 1000) {
                [keysToRemove addObject:key];
            }
        }];
        
        if (!BDPIsEmptyArray(keysToRemove)) {
            [self.timingEventDic removeObjectsForKeys:keysToRemove];
        }
    }];
}

- (void)_startClearOverdueTimingEvent {
    self.clearOverdueEventTimer = [NSTimer scheduledTimerWithTimeInterval:kClearOverdueTimingEventInterval target:self selector:@selector(_clearOverdueTimingEvent) userInfo:nil repeats:YES];
}

- (void)_stopClearOverdueTimingEvent {
    [self.clearOverdueEventTimer invalidate];
    self.clearOverdueEventTimer = nil;
}

- (void)_pushPageEvent:(NSString *)pagePath hasWebview:(BOOL)hasWebview {
    BDPTrackerPageEvent *event = [[BDPTrackerPageEvent alloc] initWithPath:pagePath hasWebview:hasWebview];
    [self.pageEventArr addObject:event];
}

- (void)_popPageEvent {
    if (!BDPIsEmptyArray(_pageEventArr)) {
        [self.pageEventArr removeLastObject];
    }
}

- (void)_setLastPagePath:(NSString *)pagePath forUniqueID:(BDPUniqueID *)uniqueID {
    BDPTrackerParamInfo *paramInfo = [BDPTracker paramInfoForUniqueID:uniqueID];
    paramInfo.lastPath = pagePath;
}

- (void)_setParamInfo:(BDPTrackerParamInfo *)paramInfo forUniqueID:(BDPUniqueID *)uniqueID {
    if (uniqueID.isValid) {
        WeakSelf;
        [self executeBlkInTaskQueue:^{
            StrongSelfIfNilReturn;
            self.commonParamDic[uniqueID] = paramInfo;
        }];
    }
}

- (void)_removeParamInfoForUniqueID:(BDPUniqueID *)uniqueID {
    if (uniqueID.isValid) {
        WeakSelf;
        [self executeBlkInTaskQueue:^{
            StrongSelfIfNilReturn;
            [self.commonParamDic removeObjectForKey:uniqueID];
        }];
    }
}

- (void)_event:(NSString *)eventId attributes:(NSDictionary *)attributes withCommonParams:(BOOL)withCommonParams uniqueID:(BDPUniqueID *)uniqueID {
    if (!BDPIsEmptyString(eventId)) {
        NSDictionary *attributesCopy = [attributes copy];
        [self executeBlkInTaskQueue:^{
            NSDictionary *param = attributesCopy;
            if (withCommonParams) {
                NSMutableDictionary *mergeDict = [[BDPTracker commonParamsForUniqueID:uniqueID] mutableCopy];
                [mergeDict addEntriesFromDictionary:attributesCopy];
                param = mergeDict;
            }
            if ([self.trackerPlugin respondsToSelector:@selector(bdp_event:params:)]) {
                [self.trackerPlugin bdp_event:eventId params:param];
            } else {
                BDPLogInfo(@"%@ %@", eventId, param);
            }
        }];
    }
}

- (void)_beginEvent:(NSString *)eventId primaryKey:(NSString *)keyName attributes:(NSDictionary *)attributes reportStart:(BOOL)reportStart uniqueID:(nullable BDPUniqueID *)uniqueID {
    NSString *primaryKey = BDP_STRING_CONCAT(keyName ?: @"", uniqueID.fullString ?: @"");
    if (!BDPIsEmptyString(eventId) && !BDPIsEmptyString(primaryKey)) {
        WeakSelf;
        NSDictionary *attributesCopy = [attributes copy];
        [self executeBlkInTaskQueue:^{
            StrongSelfIfNilReturn;
            if (reportStart) {
                [self _event:eventId attributes:attributesCopy withCommonParams:YES uniqueID:uniqueID];
            }
            [self _addTimeingEvent:primaryKey];
        }];
    }
}

- (void)_endEvent:(NSString *)eventId primaryKey:(NSString *)keyName attributes:(nullable NSDictionary *)attributes uniqueID:(nullable BDPUniqueID *)uniqueID {
    NSString *primaryKey = BDP_STRING_CONCAT(keyName ?: @"", uniqueID.fullString ?: @"");
    if (!BDPIsEmptyString(eventId) && !BDPIsEmptyString(primaryKey)) {
        WeakSelf;
        NSDictionary *attributesCopy = [attributes copy];
        [self executeBlkInTaskQueue:^{
            StrongSelfIfNilReturn;
            BDPTrackerTimingEvent *event = [self _getTimingEvent:primaryKey];
            if (event) {
                NSMutableDictionary *param = [NSMutableDictionary new];
                [param setValue:@(event.duration) forKey:BDPTrackerDurationKey];
                [param addEntriesFromDictionary:attributesCopy];
                [self _event:eventId attributes:param withCommonParams:YES uniqueID:uniqueID];
                [self _removeTimingEvent:primaryKey];
            }
        }];
    }
}

- (void)_beginLogPageView:(NSString *)pagePath query:(NSString *)query hasWebview:(BOOL)hasWebview uniqueID:(nullable BDPUniqueID *)uniqueID {
    if (!BDPIsEmptyString(pagePath)) {
        WeakSelf;
        [self executeBlkInTaskQueue:^{
            StrongSelfIfNilReturn;
            NSMutableDictionary *param = [BDPTracker enterPageCommonParam:pagePath query:query hasWebview:hasWebview uniqueID:uniqueID];
            [self _pushPageEvent:pagePath hasWebview:hasWebview];
            [self _event:BDPTEEnterPage attributes:param withCommonParams:YES uniqueID:uniqueID];
        }];
    }
}

- (void)_endLogPageView:(NSString *)pagePath query:(NSString *)query duration:(NSUInteger)duration exitType:(NSString *)exitType uniqueID:(nullable BDPUniqueID *)uniqueID {
    if (!BDPIsEmptyString(pagePath)) {
        WeakSelf;
        [self executeBlkInTaskQueue:^{
            StrongSelfIfNilReturn;
            NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
            [param setValue:pagePath forKey:BDPTrackerPagePathKey];
            [param setValue:@(duration) forKey:BDPTrackerDurationKey];
            [param setValue:exitType forKey:kExitTypeKey];
            [self _event:BDPTEStayPage attributes:param withCommonParams:YES uniqueID:uniqueID];
            [self _popPageEvent];
            [self _setLastPagePath:pagePath forUniqueID:uniqueID];
        }];
    }
}

#pragma mark - Common Params

+ (NSDictionary *)defaultCommonParams {
//    NSString *localLibVersion = [BDPVersionManager localLibVersionString];
    NSString *localSDKVersion = [BDPVersionManager localSDKVersionString];
    
    NSDictionary *params = @{
//                             BDPTrackerAppIDKey: @"",
//                             BDPTrackerLaunchFromKey: @"",
                             BDPTrackerParamSpecialKey: BDPTrackerApp,
//                             BDPTrackerLibVersionKey: localLibVersion ?: @"",
//                             BDPTrackerJSEngineVersion: @"",
                             BDPTrackerSDKVersionKey: localSDKVersion
//                             BDPTrackerMPNameKey: @"",
//                             BDPTrackerLocationKey: @"",
//                             BDPTrackerBizLocationKey: @"",
//                             BDPTrackerBDPLogKey: @"",
//                             BDPTrackerSceneKey: @"",
//                             BDPTrackerSubSceneKey: @"",
//                             BDPTrackerMPGIDKey: @""
                             };
    return params;
}

+ (nullable BDPTrackerParamInfo *)paramInfoForUniqueID:(BDPUniqueID *)uniqueID {
    BDPTrackerParamInfo *paramInfo = nil;
    
    if (uniqueID.isValid) {
        paramInfo = [BDPTracker sharedInstance].commonParamDic[uniqueID];
    }
    
    return paramInfo;
}

+ (NSDictionary *)commonParamsForUniqueID:(BDPUniqueID *)uniqueID {
    NSDictionary *commonParams = nil;
    
    if (uniqueID.isValid) {
        BDPTrackerParamInfo *paramInfo = [BDPTracker paramInfoForUniqueID:uniqueID];
        commonParams = paramInfo.commonParams;
    }
    
    if (BDPIsEmptyDictionary(commonParams)) {
        commonParams = [BDPTracker defaultCommonParams];
    }
    
    return commonParams;
}

+ (void)setCommonParams:(NSDictionary *)params forUniqueID:(BDPUniqueID *)uniqueID {
    if (uniqueID.isValid && !BDPIsEmptyDictionary(params)) {
        NSMutableDictionary *commonParams = [[BDPTracker defaultCommonParams] mutableCopy];
        [commonParams addEntriesFromDictionary:params];
        BDPTrackerParamInfo *paramInfo = [BDPTrackerParamInfo new];
        paramInfo.commonParams = commonParams;
        [[BDPTracker sharedInstance] _setParamInfo:paramInfo forUniqueID:uniqueID];
    }
}

+ (void)removeCommomParamsForUniqueID:(BDPUniqueID *)uniqueID {
    if (uniqueID.isValid) {
        [[BDPTracker sharedInstance] _removeParamInfoForUniqueID:uniqueID];
    }
}

+ (void)executeBlkInTrackerQueue:(dispatch_block_t)blk {
    if (!blk) { return; }
    [[self sharedInstance] executeBlkInTaskQueue:blk];
}

#pragma mark -
- (void)executeBlkInTaskQueue:(dispatch_block_t)blk {
    if (!blk) { return; }
    if (dispatch_get_specific((__bridge void *)[self class])) {
        blk();
    } else {
        dispatch_async(self.taskQueue, blk);
    }
}

#pragma mark - LazyLoading
- (id<BDPTrackerPluginDelegate>)trackerPlugin {
    if (!_trackerPlugin) {
        _trackerPlugin = (id<BDPTrackerPluginDelegate>)[[(Class)[BDPTimorClient sharedClient].trackerPlugin alloc] init];
    }
    return _trackerPlugin;
}

- (NSMutableDictionary<NSString *,BDPTrackerTimingEvent *> *)timingEventDic {
    if (!_timingEventDic) {
        _timingEventDic = [[NSMutableDictionary<NSString *,BDPTrackerTimingEvent *> alloc] init];
    }
    return _timingEventDic;
}

- (NSMutableDictionary<OPAppUniqueID *,BDPTrackerParamInfo *> *)commonParamDic {
    if (!_commonParamDic) {
        _commonParamDic = [[NSMutableDictionary<OPAppUniqueID *,BDPTrackerParamInfo *> alloc] init];
    }
    return _commonParamDic;
}

- (NSMutableArray<BDPTrackerPageEvent *> *)pageEventArr {
    if (!_pageEventArr) {
        _pageEventArr = [[NSMutableArray<BDPTrackerPageEvent *> alloc] init];
    }
    return _pageEventArr;
}

- (NSMutableDictionary<BDPUniqueID *,NSString *> *)lifecycleIdsDict {
    if (!_lifecycleIdsDict) {
        _lifecycleIdsDict = [[NSMutableDictionary<BDPUniqueID *,NSString *> alloc] init];
    }
    return _lifecycleIdsDict;
}

@end


#pragma MARK -
@implementation BDPTracker (BDPMonitor)

+ (void)monitorService:(NSString *)service extra:(NSDictionary *)extra uniqueID:(nullable BDPUniqueID *)uniqueID {
    [self monitorService:service metric:nil category:nil extra:extra uniqueID:uniqueID];
}

+ (void)monitorService:(NSString *)service
                metric:(NSDictionary<NSString *,NSNumber *> *)metric
              category:(NSDictionary *)category
                 extra:(NSDictionary *)extra
  uniqueID:(nullable BDPUniqueID *)uniqueID {
    if (!service.length) {
        return;
    }
    [[BDPTracker sharedInstance] executeBlkInTaskQueue:^{
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        if (uniqueID) {
            NSDictionary *commons = [BDPTracker commonParamsForUniqueID:uniqueID];
            if (commons.count) {
                [params addEntriesFromDictionary:commons];
            }
        }
        [params addEntriesFromDictionary:extra];
        if ([[BDPTracker sharedInstance].trackerPlugin respondsToSelector:@selector(bdp_monitorService:metric:category:extra:)]) {
            [[BDPTracker sharedInstance].trackerPlugin bdp_monitorService:service metric:metric category:category extra:[params copy]];
        } else {
            BDPLogInfo(@"[Monitor] %@: %@", service, params);
        }
    }];
}

@end
