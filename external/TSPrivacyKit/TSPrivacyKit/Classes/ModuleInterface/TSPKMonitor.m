//
//  TSPKMonitor.m
//  TSPrivacyKit-Pods-Aweme
//
//  Created by bytedance on 2021/8/24.
//

#import "TSPKMonitor.h"

#import "TSPKAccessEntrySubscriber.h"
#import "TSPKKeyPathEventSubscriber.h"
#import "TSPKIgnoreDetectSubscriber.h"
#import "TSPKApiStatisticsSubscriber.h"
#import "TSPKRuleEngineFrequencyManager.h"
#import "TSPKEventManager.h"
#import "TSPKEntryManager.h"
#import "TSPKDetectPipeline.h"
#import "TSPKConfigs.h"
#import "TSPKMediaNotificationObserver.h"
#import "TSPKPageStatusStore.h"
#import "TSPKGuardEngineSubscriber.h"
#import "TSPKGuardFuseEngineSubscriber.h"
#import "TSPKLock.h"
#import "TSPKStoreManager.h"
#import "TSPKMonitorBuilder.h"

// cahce
#import "TSPKCacheSubscriber.h"
#import "TSPKCacheEnv.h"
#import "TSPKCacheProcessor.h"
#import "TSPKCacheStore.h"
#import "TSPKCacheUpdateStrategy.h"
#import "TSPKCacheGroup.h"
#import "TSPKCacheStoreFactory.h"
#import "TSPKCacheStrategyFactory.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import "TSPKNetworkManager.h"

#import <TSPrivacyKit/TSPKEntryManager.h>

#import "TSPKCallStackFilter.h"
#import "UIViewController+TSAddition.h"
#import "TSPKAppLifeCycleObserver.h"
#import "TSPKDetectManager.h"
#import "TSPKDetectTrigger.h"

// for rule engine
#import "TSPKRuleEngineManager.h"

#import "TSPKCustomAnchorMonitor.h"
#import "TSPKAPICostTimeManager.h"
#import "TSPKReleaseAPIBizInfoSubscriber.h"
#import "TSPKApiLogSubscriber.h"
#import "TSPKBacktraceStore.h"
#import <TSPrivacyKit/TSPKSignalManager+public.h>

NSString *const TSPKPrivacyMonitorKey = @"ios_privacy_kit_monitor";

@interface TSPKMonitor ()

@property (nonatomic, strong) NSMutableArray *pipelines;
@property (nonatomic, strong) id<TSPKLock> pipelineLock;

@end

@implementation TSPKMonitor

+ (instancetype)sharedMonitor {
    static TSPKMonitor *env;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        env = [[TSPKMonitor alloc] init];
    });
    return env;
}

- (instancetype)init
{
    if (self = [super init]) {
        _pipelineLock = [TSPKLockFactory getLock];
        _loadTaskStatus = TSPKLoadTaskStatusUnInit;
    }
    return self;
}

#pragma mark - set reporter
+ (void)registerCustomCanReportBuilder:(TSPKCustomCanReportBuilder)builder {
    [[TSPKReporter sharedReporter] registerCustomCanReportBuilder:builder];
}

#pragma mark - set config

+ (void)setMonitorConfig:(NSDictionary *)config {
    if ([TSPKConfigs sharedConfig].monitorConfig) {
        // update rule&detector part if version changed
        TSPKConfigs *newConfigs = [TSPKConfigs new];
        newConfigs.monitorConfig = config;
        
        NSString *newConfigSettingVersion = newConfigs.settingVersion;
        NSString *oldConfigSettingVersion = [TSPKConfigs sharedConfig].settingVersion;
        
        if (![newConfigSettingVersion isEqualToString:oldConfigSettingVersion]) {
            [[TSPKConfigs sharedConfig] updateRuleAndDetectorPartOfMonitorConfig:config];
            [[TSPKDetectManager sharedManager] setupRules];
            // unregister plan
            [[TSPKDetectManager sharedManager] unregisterAllDetectPlans];
            // unregister all trigger type subscriber
            [TSPKEventManager unregisterSubscribersWithJudgeBlock:^BOOL(id<TSPKSubscriber> subscriber) {
                return [subscriber isKindOfClass:[TSPKDetectTrigger class]];
            }];
            // setup plan & subscriber
            for (TSPKDetectPipeline *pipeline in [TSPKMonitor sharedMonitor].pipelines) {
                [[TSPKDetectManager sharedManager] setupPlan:pipeline];
            }
        }
    } else {
        [TSPKConfigs sharedConfig].monitorConfig = config;
        [[TSPKDetectManager sharedManager] setupRules];
        [[TSPKDetectManager sharedManager] generateSceneRuleModelList];
    }
}

+ (void)setupDefaultSubscribersWithBuilder:(TSPKMonitorBuilder *)builder
{
    // Access Entry
    [TSPKEventManager registerSubsciber:[TSPKRuleEngineFrequencyManager sharedManager] onEventType:TSPKEventTypeAccessEntryHandle];
    
    if (builder && builder.setupSubscribers) {
        builder.setupSubscribers();
        if ([[TSPKConfigs sharedConfig] cacheConfigs]) {
            [TSPKEventManager registerSubsciber:[TSPKCacheSubscriber new] onEventType:TSPKEventTypeAccessEntryHandle];
        }
    } else {
        [TSPKMonitor setupGuardSubscribers];
    }
    
    if ([[TSPKConfigs sharedConfig] apiStatisticsConfigs]) {
        [TSPKEventManager registerSubsciber:[TSPKApiStatisticsSubscriber new] onEventType:TSPKEventTypeAccessEntryResult];
    }
    
    // alog about enter method
    [TSPKEventManager registerSubsciber:[TSPKAccessEntrySubscriber new] onEventType:TSPKEventTypeAccessEntryResult apiTypes:@[TSPKPipelineAudioOfAudioOutput, TSPKPipelineVideoOfAVCaptureSession, TSPKPipelineAudioOfAVAudioRecorder, TSPKPipelineAudioOfAUGraph]];
    // alog about key path
    [TSPKEventManager registerSubsciber:[TSPKKeyPathEventSubscriber new] onEventType:TSPKEventTypeExecuteReleaseDetect];
    // alog about ignore event
    [TSPKEventManager registerSubsciber:[TSPKIgnoreDetectSubscriber new] onEventType:TSPKEventTypeIgnoreDetect];
    // cost time statistics
    [TSPKEventManager registerSubsciber:[TSPKAPICostTimeManager sharedInstance] onEventType:TSPKEventTypeReleaseAPICallInfo apiTypes:@[TSPKPipelineAudioOfAudioOutput, TSPKPipelineVideoOfAVCaptureSession]];
    // release API biz
    if ([[TSPKConfigs sharedConfig] enableBizInfoUpload]) {
        [TSPKEventManager registerSubsciber:[TSPKReleaseAPIBizInfoSubscriber sharedInstance] onEventType:TSPKEventTypeReleaseAPIBizCallInfo apiTypes:@[TSPKPipelineAudioOfAudioOutput, TSPKPipelineVideoOfAVCaptureSession]];
    }
    [TSPKEventManager registerSubsciber:[TSPKApiLogSubscriber new] onEventType:TSPKEventTypeAccessEntryResult];
}

+ (void)setupGuardSubscribers
{
    id<TSPKSubscriber> guardSubscriber = [TSPKGuardEngineSubscriber new];
    [TSPKEventManager registerSubsciber:[TSPKGuardFuseEngineSubscriber new] onEventType:TSPKEventTypeAccessEntryHandle];
    if ([[TSPKConfigs sharedConfig] cacheConfigs]) {
        [TSPKEventManager registerSubsciber:[TSPKCacheSubscriber new] onEventType:TSPKEventTypeAccessEntryHandle];
    }
    [TSPKEventManager registerSubsciber:guardSubscriber onEventType:TSPKEventTypeAccessEntryHandle];
    [TSPKEventManager registerSubsciber:guardSubscriber onEventType:TSPKEventTypeDetectBadCase];
}

#pragma mark - load task

- (void)preloadTask
{
    if (![[TSPKConfigs sharedConfig] enable]) {
        return;
    }
    
    if ([[TSPKConfigs sharedConfig] enableViewControllerPreload]) {
        [UIViewController tspk_preload];        
    }

    [_pipelineLock lock];
    for (TSPKDetectPipeline *pipeline in self.pipelines) {
        if ([pipeline deferPreload]) {
            continue;
        }
        
        NSString *entryType = [[pipeline class] entryType];
        BOOL enable = [[pipeline class] entryEnable];
        [[TSPKEntryManager sharedManager] setEntryType:entryType enable:enable];
    }
    [_pipelineLock unlock];
}

- (void)delayLoadTask {
    if (![[TSPKConfigs sharedConfig] enable]) {
        return;
    }
    
    [_pipelineLock lock];
    for (TSPKDetectPipeline *pipeline in self.pipelines) {
        if (![pipeline deferPreload]) {
            continue;
        }
        
        NSString *entryType = [[pipeline class] entryType];
        BOOL enable = [[pipeline class] entryEnable];
        [[TSPKEntryManager sharedManager] setEntryType:entryType enable:enable];
    }
    [_pipelineLock unlock];
}

#pragma mark - signal

+ (void)addSignalWithType:(NSUInteger)signalType
            permissionType:(nonnull NSString *)permissionType
                  content:(nonnull NSString *)content {
    [TSPKSignalManager addSignalWithType:signalType
                          permissionType:permissionType
                                 content:content];
}

+ (void)addSignalWithType:(NSUInteger)signalType
            permissionType:(nonnull NSString *)permissionType
                  content:(nonnull NSString *)content
                extraInfo:(nullable NSDictionary*)extraInfo {
    [TSPKSignalManager addSignalWithType:signalType
                          permissionType:permissionType
                                 content:content
                               extraInfo:extraInfo];
}

+ (nullable NSArray *)signalFlowWithPermissionType:(nonnull NSString *)permissionType {
    return [TSPKSignalManager signalFlowWithPermissionType:permissionType];
}

+ (nullable NSDictionary *)pairSignalInfoWithPermissionType:(nonnull NSString *)permissionType needFormatTime:(BOOL)needFormatTime {
    return [TSPKSignalManager pairSignalInfoWithPermissionType:permissionType needFormatTime:needFormatTime];
}

#pragma mark - pipeline

+ (void)registerDetectPipeline:(TSPKDetectPipeline *_Nonnull)detectPipeline;
{
    [[TSPKMonitor sharedMonitor] registerDetectPipeline:detectPipeline];
}

// 如果对应的pipeline需要权限，请同步修正TSPKPermissionChecker的start和pipeline2PermissionDic函数
// if you do some changes about pipelines, plz fix method start and pipeline2PermissionDic which defined in class TSPKPermissionChecker.
+ (NSArray<NSString *> *)__pipelineNameArray
{
    return @[
        // Album
        @"TSPKAlbumOfALAssetsLibraryPipeline",
        @"TSPKAlbumOfPHAssetPipeline",
        @"TSPKAlbumOfPHAssetChangeRequestPipeline",
        @"TSPKAlbumOfPHAssetCollectionPipeline",
        @"TSPKAlbumOfPHCollectionListPipeline",
        @"TSPKAlbumOfPHImageManagerPipeline",
        @"TSPKAlbumOfPHPhotoLibraryPipeline",
        @"TSPKAlbumOfPHPickerViewControllerPipeline",
        @"TSPKAlbumOfUIImagePickerControllerPipeline",
        // Audio
        @"TSPKAudioOfAudioOutputPipeline",
        @"TSPKAudioOfAudioQueuePipeline",
        @"TSPKAudioOfAVAudioRecorderPipeline",
        @"TSPKAudioOfAVAudioSessionPipeline",
        @"TSPKAudioOfAVCaptureDevicePipeline",
        @"TSPKAudioOfAUGraphPipeline",
        // Calendar
        @"TSPKCalendarOfEKEventStorePipeline",
        @"TSPKCalendarOfEKEventPipeline",
        // CallCenter
        @"TSPKCallCenterOfCTCallCenterPipeline",
        // Clipboard
        @"TSPKClipboardOfUIPasteboardPipeline",
        // Contact
        @"TSPKContactOfABPersonPipeline",
        @"TSPKContactOfCNContactStorePipeline",
        @"TSPKContactOfCNContactPipeline",
        // DNS
        @"TSPKLocalNetworkOfCFHostPipeline",
        @"TSPKLocalNetworkOfDnsSdPipeline",
        @"TSPKLocalNetworkOfIfAddrsPipeline",
        @"TSPKLocalNetworkOfNetdbPipeline",
        // Health
        @"TSPKHealthOfHKHealthStorePipeline",
        // IDFA
        @"TSPKIDFAOfASIdentifierManagerPipeline",
        @"TSPKIDFAOfATTrackingManagerPipeline",
        // IDFV
        @"TSPKIDFVOfUIDevicePipeline",
        // IP
        @"TSPKIPOfIfAddrsPipeline",
        // Location
        @"TSPKLocationOfCLLocationManagerPipeline",
        @"TSPKLocationOfCLLocationManagerReqAlwaysAuthPipeline",
        // LockID
        @"TSPKLockIDOfLAContextPipeline",
        // Media
        @"TSPKMediaOfMPMediaLibraryPipeline",
        @"TSPKMediaOfMPMediaQueryPipeline",
        // Message
        @"TSPKMessageOfMFMessageComposeViewControllerPipeline",
        // Motion
        @"TSPKMotionOfCLLocationManagerPipeline",
        @"TSPKMotionOfCMAltimeterPipeline",
        @"TSPKMotionOfCMMotionActivityManagerPipeline",
        @"TSPKMotionOfCMMotionManagerPipeline",
        @"TSPKMotionOfCMPedometerPipeline",
        @"TSPKMotionOfUIDevicePipeline",
        // Network
        @"TSPKNetworkOfCLGeocoderPipeline",
        @"TSPKNetworkOfCTCarrierPipeline",
        @"TSPKNetworkOfNSLocalePipeline",
        @"TSPKNetworkOfCTTelephonyNetworkInfoPipeline",
        // Push
        @"TSPKPushOfUNUserNotificationCenterPipeline",
        // ScrrenRecorder
        @"TSPKScreenRecordOfRPScreenRecorderPipeline",
        @"TSPKScreenRecorderOfRPSystemBroadcastPickerViewPipeline",
        // Snapshot
        @"TSPKSnapShotOfUIGraphicsPipeline",
        @"TSPKSnapShotOfUIViewPipeline",
        // Video
        @"TSPKVideoOfAVCaptureStillImageOutputPipeline",
        @"TSPKVideoOfAVCaptureDevicePipeline",
        @"TSPKVideoOfAVCaptureSessionPipeline",
        @"TSPKVideoOfARSessionPipeline",
        // Wifi
        @"TSPKWifiOfCaptiveNetworkPipeline",
        @"TSPKWifiOfNEHotspotNetworkPipeline",
        // application
        @"TSPKApplicationOfUIApplicationPipeline",
        // ciad
        @"TSPKCIADOfBDInstallPipeline",
        // openudid
        @"TSPKOpenUDIDOfOpenUDIDPipeline",
        // user_input
        @"TSPKUserInputOfUITextFieldPipeline",
        @"TSPKUserInputOfUITextViewPipeline",
        @"TSPKUserInputOfYYTextViewPipeline"
    ];
}

- (void)setupPipelines
{
    NSArray<NSString *> *allPipelines = [self.class __pipelineNameArray];
    for (NSString *pipeline in allPipelines) {
        Class class = NSClassFromString(pipeline);
        if (class) {
            TSPKDetectPipeline *pipeline = [class new];
            if ([pipeline isKindOfClass:[TSPKDetectPipeline class]]) {
                [_pipelineLock lock];
                [self.pipelines addObject:pipeline];
                [_pipelineLock unlock];
            }
        }
    }
}

- (NSMutableArray *)pipelines
{
    if (_pipelines == nil) {
        _pipelines = [[NSMutableArray alloc] init];
    }
    return _pipelines;
}

+ (NSArray <NSString *> *)enabledPipelineTypes
{
    return [TSPKMonitor sharedMonitor].enabledPipelineTypes;
}

- (NSArray <NSString *> *)enabledPipelineTypes
{
    NSMutableArray *array = [NSMutableArray array];
    
    for (TSPKDetectPipeline *pipeline in self.pipelines) {
        if ([[pipeline class] entryEnable]) {
            [array addObject:[[pipeline class] entryType]];
        }
    }
    
    return array.copy;
}

#pragma mark - subscriber

+ (void)registerSubsciber:(nullable id<TSPKSubscriber>)subscriber onEventType:(TSPKEventType)eventType {
    [TSPKEventManager registerSubsciber:subscriber onEventType:eventType];
}

+ (void)unregisterSubsciber:(nullable id<TSPKSubscriber>)subscriber onEventType:(TSPKEventType)eventType {
    [TSPKEventManager unregisterSubsciber:subscriber onEventType:eventType];
}

#pragma mark - context

+ (void)setContextBlock:(TSPKFetchDetectContextBlock)contextBlock forApiType:(NSString *_Nonnull)apiType
{
    [[TSPKDetectManager sharedManager].context setContextBlock:contextBlock forApiType:apiType];
}

#pragma mark - Biz start&stop using camera&audio

+ (void)markCameraStartWithCaseId:(NSString *)caseId description:(NSString *)description {
    [[TSPKCustomAnchorMonitor shared] markCameraStartWithCaseId:caseId description:description];
}

+ (void)markCameraStopWithCaseId:(NSString *)caseId description:(NSString *)description {
    [[TSPKCustomAnchorMonitor shared] markCameraStopWithCaseId:caseId description:description];
}

+ (void)markAudioStartWithCaseId:(NSString *)caseId description:(NSString *)description {
    [[TSPKCustomAnchorMonitor shared] markAudioStartWithCaseId:caseId description:description];
}

+ (void)markAudioStopWithCaseId:(NSString *)caseId description:(NSString *)description {
    [[TSPKCustomAnchorMonitor shared] markAudioStopWithCaseId:caseId description:description];
}

#pragma mark - cache
+ (void)setupCache {
    NSArray *cacheConfig = [[TSPKConfigs sharedConfig] cacheConfigs];
    NSMutableArray<TSPKCacheGroup *> *array = [NSMutableArray array];
    [cacheConfig enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dict = (NSDictionary *)obj;
            TSPKCacheGroup *group = [TSPKCacheGroup new];
            group.apiList = [dict btd_arrayValueForKey:@"apis"];
            group.params = [dict btd_dictionaryValueForKey:@"params"];
            group.strategy = [dict btd_stringValueForKey:@"strategy"];
            group.store = [dict btd_stringValueForKey:@"store"];
            [array addObject:group];
        }
    }];
    
    if (array.count > 0) {
        [array enumerateObjectsUsingBlock:^(TSPKCacheGroup * _Nonnull obj, NSUInteger idx_obj, BOOL * _Nonnull stop_obj) {
            id<TSPKCacheUpdateStrategy> strategy = [TSPKCacheStrategyFactory getStrategy:obj.strategy params:obj.params];
            id<TSPKCacheStore> store = [TSPKCacheStoreFactory getStore:obj.store];
            if (strategy && store) {
                TSPKCacheProcessor *processor = [TSPKCacheProcessor initWithStrategy:strategy store:store];
                [obj.apiList enumerateObjectsUsingBlock:^(id  _Nonnull api, NSUInteger idx_api, BOOL * _Nonnull stop_api) {
                    [[TSPKCacheEnv shareEnv] registerProcessor:processor key:api];
                }];
            }
        }];
    }
}

#pragma mark - Backtraces

+ (void)saveCustomCallBacktraceWithPipelineType:(nonnull NSString *)pipelineType {
    [[TSPKBacktraceStore shared] saveCustomCallBacktraceWithPipelineType:pipelineType];
}

#pragma mark - pipeline & plan
- (void)setupPipeline:(TSPKDetectPipeline *)pipeline {
    TSPKStoreType storeType = [[pipeline class] storeType];
    if (storeType != TSPKStoreTypeNone) {
        [[TSPKStoreManager sharedManager] initStoreOfStoreId:[[pipeline class] pipelineType] storeType:storeType];
    }
    
    [[TSPKEntryManager sharedManager] registerEntryType:[[pipeline class] entryType] entryModel:[pipeline entryModel]];
    [[TSPKDetectManager sharedManager] setupPlan:pipeline];
}

#pragma mark - start

+ (void)start
{
    [[TSPKMonitor sharedMonitor] startWithPolicyDecisionBuilder:nil];
}

+ (void)startWithPolicyDecisionBuilder:(TSPKMonitorBuilder *)builder
{
    [[TSPKMonitor sharedMonitor] startWithPolicyDecisionBuilder:builder];
}

#pragma mark - private

- (void)registerDetectPipeline:(TSPKDetectPipeline *_Nonnull)detectPipeline;
{
    if (_loadTaskStatus != TSPKLoadTaskStatusUnInit) {
        NSAssert(false, @"register pipeline must before guard SDK start");
    }
    
    [_pipelineLock lock];
    [self.pipelines addObject:detectPipeline];
    [_pipelineLock unlock];
}

- (void)startWithPolicyDecisionBuilder:(TSPKMonitorBuilder *)builder
{
    if (![[TSPKConfigs sharedConfig] enable]) {
        return;
    }
    
    _loadTaskStatus = TSPKLoadTaskStatusInProgress;
    
    if ([[TSPKConfigs sharedConfig] enableNetworkInit]) {
        [[TSPKNetworkManager shared] initializeNetworkInfo];
    }
    
    NSDictionary *signalConfigs = [[TSPKConfigs sharedConfig] signalConfigs];
    if (signalConfigs) {
        [[TSPKSignalManager sharedManager] setConfig:signalConfigs];
    }

    NSDictionary *callFilterConfigs = [[TSPKConfigs sharedConfig] callFilterConfigs];
    NSInteger callFilterInitDelay = [callFilterConfigs btd_integerValueForKey:@"init_delay"];    
    if (callFilterInitDelay > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(callFilterInitDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[TSPKCallStackFilter shared] updateWithConfigs:callFilterConfigs];
        });
    } else {
        [[TSPKCallStackFilter shared] updateWithConfigs:callFilterConfigs];
    }

    [TSPKMonitor setupDefaultSubscribersWithBuilder:builder];
    [TSPKMonitor setupCache];

    [self setupPipelines];
    for (TSPKDetectPipeline *pipeline in self.pipelines) {
        [self setupPipeline:pipeline];
    }
    // set up when sdk start, in order to record info about page change
    if ([[TSPKConfigs sharedConfig] enableSetupAppLifeCycleObserver]) {
        [[TSPKAppLifeCycleObserver sharedObserver] setup];
    }
    
    if ([[TSPKConfigs sharedConfig] enableSetupMediaNotificationObserver]) {
        [TSPKMediaNotificationObserver setup];
    }
    
    NSArray *pageStatusConfigs = [[TSPKConfigs sharedConfig] pageStatusConfigs];
    if (pageStatusConfigs.count > 0) {
        [[TSPKPageStatusStore shared] setConfigs:pageStatusConfigs];
        [[TSPKPageStatusStore shared] addObserver];
    }
    
    // will execute hook
    [self preloadTask];
    // The execution may cost some time, should call it after launch and put it on background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self delayLoadTask];
        self.loadTaskStatus = TSPKLoadTaskStatusDone;
    });
}

@end
