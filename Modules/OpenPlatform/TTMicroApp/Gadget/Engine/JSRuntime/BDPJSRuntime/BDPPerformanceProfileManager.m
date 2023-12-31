//
//  BDPPerformanceProfileManager.m
//  TTMicroApp
//
//  Created by ChenMengqi on 2022/12/13.
//

#import "BDPPerformanceProfileManager.h"
#import "BDPPerformanceSocketConnection.h"
#import <ECOInfra/BDPUtils.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import "OPMicroAppJSRuntime.h"
#import "OPMicroAppJSRuntimeDelegate.h"
#import <ECOInfra/ECOConfig.h>
#import <ECOInfra/ECOConfigService.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import "BDPTaskManager.h"
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <OPFoundation/BDPI18n.h>
#import "BDPAppContainerController.h"
#import "BDPGetPerformanceEntry.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>

#define kBDPPerformanceExtra @"extra"
#define kBDPPerformanceStart @"start"
#define kBDPPerformanceEnd @"end"
#define kBDPPerformanceCurrentVersion @"1"


@interface BDPPerformanceProfileManager()<BDPPerformanceSocketConnectionDelegate>

//性能分析工具
@property (nonatomic, assign, readwrite) BOOL profileEnable;
@property (nonatomic, strong) BDPPerformanceSocketConnection *connection;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *performancePoints;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *flushPoints;
@property (nonatomic, weak) id<OPMicroAppJSRuntimeProtocol> jsThread;
@property (nonatomic, assign, readwrite) BOOL isDomready;
@property (nonatomic, assign) NSInteger performance_record_timeout_millis;
@property (nonatomic, assign) NSInteger websocket_prepare_timeout_millis;
@property (nonatomic, strong) dispatch_queue_t taskQueue;
@property (nonatomic, assign) BOOL profileInitSuccess;

//getPerformanceEntires API
@property (nonatomic, assign) BOOL apiEnable;
@property (nonatomic, strong) NSLock *lock;
//性能数据字典，
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray<BDPGetPerformanceEntry*> *> *performanceEntriesDic;

@end

@implementation BDPPerformanceProfileManager

+ (instancetype)sharedInstance {
    static id sInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sInstance = [[BDPPerformanceProfileManager alloc] init];
    });
    return sInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self parseSettings];
        [self parseFG];
    }
    return self;
}

-(void)initForProfileManager{
    if(!self.profileEnable && !self.apiEnable){
        return ;
    }
    [self initTaskQueue];
}

-(BOOL)enableProfileForCommon:(BDPCommon *)common{
    return !BDPIsEmptyString(common.performanceTraceAddress) && BDPPerformanceProfileManager.sharedInstance.profileEnable;
}

#pragma mark - connect delegate

-(void)buildConnectionWithAddress:(NSString *)address jsThread:(id<OPMicroAppJSRuntimeProtocol>)jsThread{
    if(!self.profileEnable){
        return ;
    }
    if(self.connection){
        //has connection
        BDPLogError(@"[PerformanceProfile] connection has exist, will not build connection again");
        return ;
    }
    BDPPerformanceSocketConnection *connection = [BDPPerformanceSocketConnection createConnectionWithAddress:address delegate:self];
    if(!connection){
        BDPLogError(@"[PerformanceProfile] connection init failed");
    }
    self.jsThread = jsThread;
    self.connection = connection;
    [self startConnectMaxtimeCountDown];
}

#pragma mark - public method for performance point

- (void)monitorLoadTimelineWithStartKey:(BDPPerformanceKey)key
                               uniqueId:(nullable BDPUniqueID *)uniqueId
                                  extra:(nullable NSDictionary *)extra{
    if( ![self performanceRecordEnable] ){
        return ;
    }
    NSUInteger time = (NSUInteger)([[NSDate date] timeIntervalSince1970]*1000);
    if(self.profileEnable){
        [self monitorForProfileWithStartKey:key uniqueId:uniqueId time:time extra:extra];
    }
    if(self.apiEnable){
        [self monitorForAPIWithStartKey:key uniqueId:uniqueId time:time extra:extra];
    }
}

- (void)monitorLoadTimelineWithEndKey:(BDPPerformanceKey)key
                             uniqueId:(nullable BDPUniqueID *)uniqueId
                                extra:(nullable NSDictionary *)extra{
    if(![self performanceRecordEnable]){
        return ;
    }
    NSUInteger time = (NSUInteger)([[NSDate date] timeIntervalSince1970]*1000);
    if(self.profileEnable){
        [self monitorForProfileWithEndKey:key uniqueId:uniqueId time:time extra:extra];
    }
    if(self.apiEnable){
        [self monitorForAPIWithEndKey:key uniqueId:uniqueId time:time extra:extra];
    }
}

-(void)flushLaunchPointsWhenDomready {
    if(!self.profileEnable || !self.connection || !self.taskQueue){
        return ;
    }
    self.isDomready = YES;
    [self flushPointsToJSSDK];
}

-(void)flushJSSDKPerformanceData:(NSDictionary *)performanceData{
    if(!self.profileEnable || !self.connection || !self.taskQueue){
        return ;
    }
    BDPLogInfo(@"[PerformanceProfile] socket connection flushJSSDKPerformanceData");
    [self sendPerformanceDataToIDE:performanceData];
}

-(void)endProfileAfterFinishDebugButtonPressed{
    if(!self.profileEnable || !self.connection){
        return ;
    }
    [self stopDebugPerformanceAnalyzing];
}

-(void)endConnection{
    if(!self.profileEnable || !self.connection){
        return ;
    }
    [self executeBlkInTaskQueue:^{
        self.performancePoints = nil;
        self.flushPoints = nil;
    }];

    [self.connection disConnect];
    self.connection = nil;
    self.isDomready = NO;
    self.taskQueue = nil;
}

-(void)removePerformanceEntriesForUniqueId:(OPAppUniqueID *)uniqueId{
    if(!self.apiEnable) return;
    [self.lock lock];
    [self.performanceEntriesDic removeObjectForKey: BDPSafeString(uniqueId.fullString)];
    [self.lock unlock];
    if(self.performanceEntriesDic.count == 0){
        self.taskQueue = nil;
    }
}


#pragma mark - private method for performance profile

- (void)monitorForProfileWithStartKey:(BDPPerformanceKey)key
                             uniqueId: (OPAppUniqueID *)uniqueId
                                 time:(NSUInteger)time
                                  extra:(nullable NSDictionary *)extra{
    [self executeBlkInTaskQueue:^{
        BDPLogInfo(@"monitorLoadTimeline key start: %@, time %ld extra %@", [self convertStringWithKey:key], (long)time, extra);
        NSMutableDictionary *point = [NSMutableDictionary dictionary];
        [point setObject:BDPSafeString([self convertStringWithKey:key]) forKey:@"key"];
        [point setObject:@(time) forKey:@"start"];
        [point setObject:BDPSafeDictionary(extra) forKey:kBDPPerformanceExtra];
        [self.performancePoints addObject:point];

        //启动点只有start ，没有end
        if(key == BDPPerformanceLaunch){
            self.uniqueID = uniqueId; // 初始化设置下，只有性能测试需要用
            [self.flushPoints addObject:point];
        }
    }];
}

- (void)monitorForProfileWithEndKey:(BDPPerformanceKey)key
                             uniqueId: (OPAppUniqueID *)uniqueId
                                 time:(NSUInteger)time
                                  extra:(nullable NSDictionary *)extra{
    [self executeBlkInTaskQueue:^{
        BDPLogInfo(@"monitorLoadTimeline key end: %@, time %ld, extra %@", [self convertStringWithKey:key], (long)time, extra);
        for (NSMutableDictionary *point in self.performancePoints) {
            //找到相同key的start 数据
            if([[point bdp_objectForKey:@"key"] isEqualToString:BDPSafeString([self convertStringWithKey:key])] && [point bdp_objectForKey:@"start"]){
                NSUInteger startWebviewId = [[point bdp_objectForKey:kBDPPerformanceExtra] bdp_longValueForKey:kBDPPerformanceWebviewId];
                NSUInteger endWebviewId = [extra bdp_longValueForKey:kBDPPerformanceWebviewId];
                //配对后才能flush
                if(startWebviewId == endWebviewId){
                    [point setObject:@(time) forKey:@"end"];
                    //如果end 有extra，以end的extra为准，如 metaload package load等
                    if(extra){
                        [point setObject:BDPSafeDictionary(extra) forKey:kBDPPerformanceExtra];
                    }
                    [self.flushPoints addObject:point];
                    //如果已经domready，后续的点都直接flush to jssdk
                    if(self.isDomready){
                        [self flushPointsToJSSDK];
                    }
                    return ;
                }
            }
        }
    }];
}


#pragma mark - public method for performance API

-(NSArray *)getPerformanceEntriesByUniqueId:(BDPUniqueID *)uniqueId{
    [self.lock lock];
    NSArray *performanceEntries = [[self.performanceEntriesDic bdp_objectForKey:uniqueId.fullString] copy];
    [self.lock unlock];
    return performanceEntries;
}

#pragma mark - private method for performance API

- (void)monitorForAPIWithStartKey:(BDPPerformanceKey)key
                         uniqueId: (OPAppUniqueID *)uniqueId
                                 time:(NSUInteger)time
                                  extra:(nullable NSDictionary *)extra{
    if(![uniqueId isValid] ) {
        BDPLogWarn(@"monitorForAPI uniqueID is invalid");
        return ;
    }
    if([self convertEntryNameWithKey:key].length == 0){
        BDPLogInfo(@"monitorForAPI the key %lu is not for API",(unsigned long)key);
        return ;
    }
    [self executeBlkInTaskQueue:^{
        BDPLogInfo(@"monitorForAPIWithStartKey key start: %@, time %ld extra %@", [self convertEntryNameWithKey:key], (long)time, extra);
        [self.lock lock];
        NSMutableArray *performanceEntries = [self.performanceEntriesDic bdp_objectForKey:uniqueId.fullString];
        if(!performanceEntries || performanceEntries.count == 0){
            performanceEntries = [NSMutableArray array];
        }
        if(key == BDPPerformanceDomready){
            for (BDPGetPerformanceEntry *entry in performanceEntries) {
                if(entry.name == [self convertEntryNameWithKey:BDPPerformanceDomready]){
                    //first-paint 只上报一次
                    [self.lock unlock];
                    return ;
                }
            }
        }
        BDPGetPerformanceEntry *entry = [BDPGetPerformanceEntry new];
        entry.name = [self convertEntryNameWithKey:key];
        entry.entryType = [self convertEntryTypeWithKey:key];
        entry.startTime = time;
        entry.fileName = [self convertFileNameWithKey:key];
        entry.webviewId = [[extra bdp_objectForKey:kBDPPerformanceWebviewId] longValue];
        [performanceEntries addObject:entry];
        [self.performanceEntriesDic setObject:performanceEntries forKey:BDPSafeString(uniqueId.fullString)];
        [self.lock unlock];
    }];
}

- (void)monitorForAPIWithEndKey:(BDPPerformanceKey)key
                         uniqueId: (OPAppUniqueID *)uniqueId
                                 time:(NSUInteger)time
                            extra:(nullable NSDictionary *)extra{
    if(![uniqueId isValid] ) {
        BDPLogWarn(@"monitorForAPI uniqueID is invalid");
        return ;
    }
    [self executeBlkInTaskQueue:^{
        BDPLogInfo(@"monitorForAPIWithEndKey key end: %@, time %ld extra %@", [self convertEntryNameWithKey:key], (long)time, extra);
        [self.lock lock];
        NSMutableArray *performanceEntries = [self.performanceEntriesDic bdp_objectForKey:uniqueId.fullString];
        BDPGetPerformanceEntry *currentEntry = nil;
        for (BDPGetPerformanceEntry *performanceEntry in performanceEntries) {
            if([performanceEntry.name isEqualToString:[self convertEntryNameWithKey:key]]){
                if(key == BDPPerformancePageFrameJSRun && ([[extra bdp_objectForKey:kBDPPerformanceWebviewId] longValue] == performanceEntry.webviewId)) {
                    currentEntry = performanceEntry;
                    break;
                } else if(key != BDPPerformancePageFrameJSRun){
                    currentEntry = performanceEntry;
                    break;
                }
            }
        }
        currentEntry.isPreload = [[extra bdp_objectForKey:@"isCache"] boolValue]; //当前只有有包情况下有意义
        currentEntry.duration = time - currentEntry.startTime;
        [self.lock unlock];
    }];
}



#pragma mark - socket connection delegate

- (void)connection:(nonnull BDPPerformanceSocketConnection *)connection didReceiveMessage:(nonnull BDPPerformanceSocketMessage *)message {
    NSString *eventName = message.event;
    BDPLogInfo(@"[PerformanceProfile] socket connection didReceiveMessage %@ event",eventName);
    if([eventName isEqualToString:@"init"]){
        [self processInitMessage:message];
    } else if([eventName isEqualToString:@"close"]){
        [self processCloseMessage:message];
    } else if([eventName isEqualToString:@"stop"]){
        [self processStopMessage:message];
    } else {
        NSAssert(NO, @"[PerformanceProfile] can't handle this message event");
    }
}

- (void)connection:(nonnull BDPPerformanceSocketConnection *)connection statusChanged:(BDPPerformanceSocketStatus)status {
    if (status == BDPPerformanceSocketStatusConnected) {
        BDPExecuteOnMainQueue(^{
            [self onSocketDebugConnected];
        });
    } else if (status == BDPPerformanceSocketStatusDisconnected) {
            BDPExecuteOnMainQueue(^{
                [self onSocketDebugDisconnected];
            });
    } else if (status == BDPPerformanceSocketStatusFailed) {
            BDPExecuteOnMainQueue(^{
                [self onSocketDebugConnectFailed];
            });
    } else {
        BDPLogError(@"unknow connection status");
    }

}

#pragma mark - process socket connection IDE to Client

-(void)processInitMessage:(BDPPerformanceSocketMessage *)message{
    self.profileInitSuccess = YES;
    NSString *profileVersion = [message.data bdp_stringValueForKey:@"AppVersion"];
    if([profileVersion isEqualToString:kBDPPerformanceCurrentVersion]){
        BLOCK_EXEC_IN_MAIN(^{
            BDPTask *task = BDPTaskFromUniqueID(self.uniqueID);
            UIViewController *topVC = task.containerVC;
            BDPPlugin(alertPlugin, BDPAlertPluginDelegate);
            if ([topVC isKindOfClass: BDPAppContainerController.class] && [alertPlugin respondsToSelector:@selector(bdp_showAlertWithTitle:content:confirm:fromController:confirmCallback:showCancel:)]) {
                WeakSelf;
                NSString *content = BDPI18n.OpenPlatform_GadgetAnalytics_FailedToInitialize1;
                [alertPlugin bdp_showAlertWithTitle:BDPI18n.OpenPlatform_GadgetAnalytics_RecExitedTtl content:content confirm:BDPI18n.determine fromController:topVC confirmCallback:^{
                    StrongSelfIfNilReturn;
                    [self endConnection];
                    [(BDPAppContainerController *)topVC forceClose:GDMonitorCode.debug_exit];
                } showCancel:NO];
            } else {
                [self endConnection];
                [(BDPAppContainerController *)topVC forceClose:GDMonitorCode.debug_exit];
            }
        });
    }
    [self sendInitMessageToIDE];
    [self startProfileMaxtimeCountDown];
}

-(void)processCloseMessage:(BDPPerformanceSocketMessage *)message{
    [self endConnection];
}

-(void)processStopMessage:(BDPPerformanceSocketMessage *)message{
    ///中断录制
    [self stopDebugPerformanceAnalyzing];
}

#pragma mark - process socket connection client to IDE

-(void)sendInitMessageToIDE {
    BDPPerformanceSocketMessage *message = [BDPPerformanceSocketMessage new];
    message.event = @"init";
    message.data = @{
        @"type":@"performance_analysis",
        @"version":kBDPPerformanceCurrentVersion,
        @"AppVersion":BDPDeviceTool.bundleShortVersion,
        @"platform":@"iOS",
        @"from":@"client"
    };

    [self.connection sendMessage:message];
}

-(void)sendCloseMessageToIDE {
    BDPPerformanceSocketMessage *message = [BDPPerformanceSocketMessage new];
    message.event = @"close";
    message.data = @{
        @"code":@(400),
        @"message":@"timeout",
        @"from":@"client"
    };

    [self.connection sendMessage:message];
    [self endConnection];
}


-(void)sendPerformanceDataToIDE:(NSDictionary *)performanceData {
    BDPPerformanceSocketMessage *message = [BDPPerformanceSocketMessage new];
    message.event = @"sendPerformanceData";
    message.data = performanceData;
    [self.connection sendMessage:message];
}

#pragma mark - socket connection


- (void)onSocketDebugConnected {
    BDPTask *task = BDPTaskFromUniqueID(self.uniqueID);
    if(task.containerVC && [task.containerVC respondsToSelector:@selector(onSocketPerformanceConnected)]) {
        [task.containerVC onSocketPerformanceConnected];
    }
}

- (void)onSocketDebugConnectFailed {
    BDPTask *task = BDPTaskFromUniqueID(self.uniqueID);
    if(task.containerVC && [task.containerVC respondsToSelector:@selector(onSocketPerformanceConnectFailed)]) {
        [task.containerVC onSocketPerformanceConnectFailed];
    }
}


- (void)onSocketDebugDisconnected {
    BDPTask *task = BDPTaskFromUniqueID(self.uniqueID);
    if(task.containerVC && [task.containerVC respondsToSelector:@selector(onSocketPerformanceDisconnected)]) {
        [task.containerVC onSocketPerformanceDisconnected];
    }
}


#pragma mark - private method

-(BOOL)performanceRecordEnable{
    return (self.profileEnable || self.apiEnable) && self.taskQueue;
}

-(void)parseSettings {
    id<ECOConfigService> service = [ECOConfig service];
    //获取settings配置
    NSDictionary *performance_profile_config = BDPSafeDictionary([service getLatestDictionaryValueForKey: @"openplatform_gadget_performance_profile"]);
    self.profileEnable = [performance_profile_config bdp_boolValueForKey2:@"enable"];
    self.performance_record_timeout_millis = MAX([performance_profile_config bdp_longValueForKey:@"performance_record_timeout_millis"],30000);
    self.websocket_prepare_timeout_millis = MAX([performance_profile_config bdp_longValueForKey:@"websocket_prepare_timeout_millis"],10000);
}

-(void)parseFG{
    _apiEnable = [EMAFeatureGating boolValueForKey:@"openplatform.gadget.enable_getentries"];
}

-(void)initTaskQueue{
    if(_taskQueue) return;
    _taskQueue = dispatch_queue_create("com.bytedance.openplatform.BDPPerformanceProfileManager.serialqueue", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_set_specific(_taskQueue, (__bridge void *)[self class], (__bridge void *)self, NULL);

}

- (void)executeBlkInTaskQueue:(dispatch_block_t)blk {
    if(!self.taskQueue || !blk) return;
    if (dispatch_get_specific((__bridge void *)[self class])) {
        blk();
    } else {
        dispatch_async(self.taskQueue, blk);
    }
}


-(void)flushPointsToJSSDK{
    BDPLogInfo(@"[PerformanceProfile] flushPointsToJSSDK");
    [self.jsThread bdp_fireEventV2:@"onDebugNativePerformanceData" data:@{@"data":self.flushPoints}];
    self.flushPoints = nil;
}

-(void)stopDebugPerformanceAnalyzing{
    BDPLogInfo(@"[PerformanceProfile] onDebugPerformanceAnalyzingStop");
    [self.jsThread bdp_fireEventV2:@"onDebugPerformanceAnalyzingStop" data:nil];
}


/**
 - serviceContainerLoad: 小程序 Service 容器加载
 - webviewContainerLoad: 小程序 WebView 容器加载
 - serviceJSSDKLoad: 小程序 Service JSSDK 加载
 - webviewJSSDKLoad: 小程序 Service JSSDK 加载
 - metaLoad: 小程序 meta 加载
 - packageLoad: 小程序代码包加载
 - appServiceJSRun: app-service.js  执行
 - pageFrameJSRun: page-frame.js 执行
 - subAppServiceJSRun: sub-app-service.js 执行（客户端一期不包含，后续再支持）
 - subPageFrameJSRun: sub-app-service.js 执行（客户端一期不包含，后续再支持）
 */

-(NSString *)convertStringWithKey:(BDPPerformanceKey)key{
    switch(key){
        case BDPPerformanceLaunch:
            return @"launch";
        case BDPPerformanceMetaLoad:
            return @"metaLoad";
        case BDPPerformancePackageLoad:
            return @"packageLoad";
        case BDPPerformanceServiceContainerLoad:
            return @"serviceContainerLoad";
        case BDPPerformanceWebviewContainerLoad:
            return @"webviewContainerLoad";
        case BDPPerformanceServiceJSSDKLoad:
            return @"serviceJSSDKLoad";
        case BDPPerformanceWebviewJSSDKLoad:
            return @"webviewJSSDKLoad";
        case BDPPerformanceAppServiceJSRun:
            return @"appServiceJSRun";
        case BDPPerformancePageFrameJSRun:
            return @"pageFrameJSRun";
        default:
            return @"";
    }
}

-(BDPGetPerformanceEntryType)convertEntryTypeWithKey:(BDPPerformanceKey)key{
    switch(key){
        case BDPPerformanceLaunch:
            return BDPGetPerformanceEntryTypeLaunch;
        case BDPPerformanceMetaLoad:
            return BDPGetPerformanceEntryTypeResource;
        case BDPPerformancePackageLoad:
            return BDPGetPerformanceEntryTypeResource;
        case BDPPerformanceAppServiceJSRun:
            return BDPGetPerformanceEntryTypeScript;
        case BDPPerformancePageFrameJSRun:
            return BDPGetPerformanceEntryTypeScript;
        case BDPPerformanceDomready:
            return BDPGetPerformanceEntryTypePaint;
        case BDPPerformanceWarmLaunch:
            return BDPGetPerformanceEntryTypeLaunch;
        default:
            return BDPGetPerformanceEntryTypeDefault;
    }
}

-(NSString *)convertEntryNameWithKey:(BDPPerformanceKey)key{
    switch(key){
        case BDPPerformanceLaunch:
            return @"appLaunch";
        case BDPPerformanceMetaLoad:
            return @"meta";
        case BDPPerformancePackageLoad:
            return @"package";
        case BDPPerformanceAppServiceJSRun:
            return @"app-service";
        case BDPPerformancePageFrameJSRun:
            return @"page-frame";
        case BDPPerformanceWarmLaunch:
            return @"warmLaunch";
        case BDPPerformanceDomready:
            return @"first-paint";
        default:
            return @"";
    }
}

-(NSString *)convertFileNameWithKey:(BDPPerformanceKey)key{
    switch(key){
        case BDPPerformanceAppServiceJSRun:
            return @"app-service.js";
        case BDPPerformancePageFrameJSRun:
            return @"page-frame.js";
        default:
            return @"";
    }
}



-(void)startProfileMaxtimeCountDown{
    BDPLogInfo(@"[PerformanceProfile] start countdomwn the maxtime %ld", (long)self.performance_record_timeout_millis);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.performance_record_timeout_millis * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        if(self.connection.status != BDPPerformanceSocketStatusDisconnected){
            BDPLogWarn(@"[PerformanceProfile] reach the maxtime %ld", (long)self.performance_record_timeout_millis);
            [self stopDebugPerformanceAnalyzing];
        }
    });
}

-(void)startConnectMaxtimeCountDown{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.websocket_prepare_timeout_millis * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        if(!self.profileInitSuccess){
            [self endConnection];
        }
    });
}


-(NSMutableArray<NSDictionary *> *)performancePoints{
    if(!_performancePoints){
        _performancePoints = [NSMutableArray array];
    }
    return _performancePoints;
}

-(NSMutableArray<NSDictionary *> *)flushPoints{
    if(!_flushPoints){
        _flushPoints = [NSMutableArray array];
    }
    return _flushPoints;
}


-(NSLock *)lock{
    if(!_lock){
        _lock = [NSLock new];
    }
    return _lock;
}

- (NSMutableDictionary<NSString*, NSArray<BDPGetPerformanceEntry*> *> *)performanceEntriesDic{
    if(!_performanceEntriesDic){
        _performanceEntriesDic = [NSMutableDictionary dictionary];
    }
    return _performanceEntriesDic;
}



@end
