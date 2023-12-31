//
//  ACCPropComponentGrayAbilityPlugin.m
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/7/12.
//

#import "ACCPropComponentGrayAbilityPlugin.h"
#import "ACCPropComponentGrayAbilityPlugin+Private.h"

#import <Foundation/Foundation.h>

#import <EffectPlatformSDK/EffectPlatform.h>
#import <TTReachability/TTReachability.h>

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/NSObject+ACCProtocolContainer.h>
#import <CreationKitArch/IESEffectModel+ACCSticker.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreationKitRTProtocol/ACCCameraService.h>

#import <CameraClient/AWEEffectPlatformManager.h>
#import <CameraClient/ACCRecordPropService.h>
#import <CameraClient/ACCRecordFlowService.h>
#import <CameraClient/ACCPropComponentV2.h>
#import <CameraClient/ACCMessageFilterable.h>
#import <CameraClient/AWEVideoFragmentInfo.h>
#import <CameraClient/ACCScanService.h>

typedef void(^ACCGrayPropEffectModelBlock)(IESEffectModel *model);

static NSString * const kACCGrayPropEffectPanelName = @"xnlhd";
static NSString * const kACCGrayPropEffectCategoryName = @"dj";
static const CGFloat kACCGrayPropTrialDelaySeconds = 1;
static const NSInteger kACCGrayPropEffectMsgId = 0x5001; // 灰度道具打点

static NSString * const KGrayAbilitykInterfaceKey = @"interface";
static NSString * const kGrayAbilityInterfaceValueDownloadModel = @"downloadModel";
static NSString * const kGrayAbilityInterfaceValueGetCookie = @"cookie";
static NSString * const kGrayAbilityInterfaceValueRequest = @"requestServerMessage";
static NSString * const kGrayAbilityInterfaceValueDownload = @"download";
static const NSInteger kGrayAbilityEffectMsgId = 0x29; // 41
static const NSInteger kGrayAbilityStickerRecognizeMsgId = 0x14; // 20
static const NSInteger kGrayAbilityFaceCountMsgId = 0x1d; // 29
static const NSInteger kGrayAbilityClientMonitorMsgId = 0x11; // 17

@interface ACCPropComponentGrayAbilityPlugin () <
ACCRecordPropServiceSubscriber,
ACCRecordFlowServiceSubscriber,
ACCRecordSwitchModeServiceSubscriber,
ACCMessageFilterDelegate,
ACCEffectEvent
>

// ab
@property (nonatomic, assign) BOOL enableNewAbility;
@property (nonatomic, assign) NSInteger maxTrialTimes;
@property (nonatomic, strong, readwrite) NSArray<NSString *> *blackList;

// logic
@property (nonatomic, strong) IESEffectModel *grayProp;
@property (nonatomic, strong) NSDate *grayPropStartTimePoint;
@property (nonatomic, strong) NSArray *grayPropBlockModeArray;

// service
@property (nonatomic, assign) BOOL isCameraUsingGrayProp;
@property (nonatomic, assign) BOOL isMessageFilterEnabled;
@property (nonatomic, weak) id<ACCCameraService> cameraService;
@property (nonatomic, weak) id<ACCRecordPropService> propService;
@property (nonatomic, weak) id<ACCRecordFlowService> flowService;
@property (nonatomic, weak) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, weak) id<ACCScanService> scanService;

@end

@implementation ACCPropComponentGrayAbilityPlugin

@synthesize component = _component;

IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, propService, ACCRecordPropService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)


- (void)componentDidMount
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackgroundNotification) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterForegroundNotification) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)componentDidAppear
{
    [self p_configGrayAbilityAB];
    [self p_startGrayAbility];
}

- (void)componentWillDisappear
{
    [self p_trackGrayStickerRunInfoClient];
    [self p_checkAndRemoveGrayProp];
}


#pragma mark - getter

+ (id)hostIdentifier
{
    return [ACCPropComponentV2 class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.scanService = IESAutoInline(serviceProvider, ACCScanService);
    [self.cameraService addSubscriber:self];
    [self.propService addSubscriber:self];
    [self.flowService addSubscriber:self];
    [self.cameraService.message addSubscriber:self];
    [self.switchModeService addSubscriber:self];
}

- (ACCPropComponentV2 *)hostComponent
{
    return self.component;
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

#pragma mark - apply grap prop

// start
- (void)p_startGrayAbility
{
    self.isMessageFilterEnabled = NO;
    if (![self p_checkUsability]) {
        return;
    }

    // fetch effect model
    @weakify(self);
    ACCGrayPropEffectModelBlock fetchCompletion = ^(IESEffectModel *model) {
        @strongify(self);
        self.grayProp = model;
        [self p_checkAndApplyGrayProp:model];
    };

    [self p_fetchGrayPropWithCompletion:fetchCompletion];
}


// check and apply
- (void)p_checkAndApplyGrayProp:(IESEffectModel *)model
{
    // check
    if (![self p_shouldApplyGrayProp:model]) {
        return;
    }

    // apply
    @weakify(self);
    ACCGrayPropEffectModelBlock applyBlock = ^(IESEffectModel *model) {
        @strongify(self);
        [self p_applyGrayProp:model];
    };

    if (model.downloaded) {
        ACCBLOCK_INVOKE(applyBlock, model);
    } else {
        [self p_downloadGrayProp:model completion:applyBlock];
    }
}

// apply
- (void)p_applyGrayProp:(IESEffectModel *)model
{
    // check
    if (![self p_shouldApplyGrayProp:model]) {
        return;
    }

    // check prop state
    IESEffectModel *currentModel = [self.cameraService.effect currentSticker];
    if (currentModel && ![currentModel.effectIdentifier isEqualToString:model.effectIdentifier]) {
        return;
    }

    // use gray ability prop
    self.isMessageFilterEnabled = YES;
    self.grayPropStartTimePoint = [NSDate date];
    [[(NSObject *)self.cameraService.message acc_getProtocol:@protocol(ACCMessageFilterable)] setMessageFilter:self];
    [self.cameraService.effect acc_applyStickerEffect:model];

    // monitor, log
    [self p_increaseCachedTimesOfGrayProp:model];

    NSDictionary *referExtra = [self.propService trackReferExtra];

    if (referExtra != nil) {
        model.recordTrackInfos = @{
            @"creation_id": referExtra[@"creation_id"] ?: @"",
            @"shoot_way": referExtra[@"shoot_way"] ?: @"",
            @"content_source": referExtra[@"content_source"] ?: @"",
            @"content_type": referExtra[@"content_type"] ?: @"",
            @"enter_from": referExtra[@"enter_from"] ?: @"",
            @"prop_id": model.effectIdentifier ?: @""
        };
    }
    [ACCTracker() trackEvent:@"prop_try" params:model.recordTrackInfos needStagingFlag:NO];
}

#pragma mark - check

- (BOOL)p_checkUsability
{
    BOOL isWifiConnected = [[TTReachability reachabilityForInternetConnection] currentReachabilityStatus] == ReachableViaWiFi;
    if (!self.enableNewAbility || !isWifiConnected) {
        return NO;
    }
    return YES;
}

- (BOOL)p_shouldApplyGrayProp:(IESEffectModel *)model
{
    if (![self p_checkUsability]) {
        return NO;
    }

    if ([self.scanService bachPropScanIsRunning]) {
        return NO;
    }

    if ([self isCameraUsingGrayProp]) {
        return NO;
    }

    if (model == nil) {
        return NO;
    }

    if ([self.blackList containsObject:model.effectIdentifier]) {
        return NO;
    }

    NSInteger cacheCount = [self p_cachedTimesOfGrayProp:model];
    if (cacheCount >= self.maxTrialTimes) {
        return NO;
    }

    return YES;
}

- (NSInteger)p_cachedTimesOfGrayProp:(IESEffectModel *)model
{
    NSString *cacheKey = [NSString stringWithFormat:@"gray-ability-prop-%@", model.effectIdentifier];
    NSInteger times = [ACCCache() integerForKey:cacheKey];
    return MAX(times, 0);
}

- (void)p_increaseCachedTimesOfGrayProp:(IESEffectModel *)model
{
    NSString *cacheKey = [NSString stringWithFormat:@"gray-ability-prop-%@", model.effectIdentifier];
    NSInteger times = [self p_cachedTimesOfGrayProp:model] + 1;
    [ACCCache() setInteger:times forKey:cacheKey];
}

- (BOOL)isCameraUsingGrayProp
{
    IESEffectModel *currentModel = [self.cameraService.effect currentSticker];
    if (currentModel && [currentModel.effectIdentifier isEqualToString:self.grayProp.effectIdentifier]) {
        return YES;
    }
    return NO;
}

#pragma mark - download

- (void)p_fetchGrayPropWithCompletion:(ACCGrayPropEffectModelBlock)completion
{
    [EffectPlatform downloadEffectListWithPanel:kACCGrayPropEffectPanelName category:kACCGrayPropEffectCategoryName pageCount:0 cursor:0 sortingPosition:0 completion:^(NSError * _Nullable error, IESEffectPlatformNewResponseModel * _Nullable response) {
        NSMutableDictionary *json = [NSMutableDictionary dictionary];
            if (!error && response.categoryEffects.effects.count > 0) {
                NSArray *effectsList = response.categoryEffects.effects;
                IESEffectModel *first = effectsList.firstObject;
                json[@"sticker_id"] = first.effectIdentifier;
                ACCBLOCK_INVOKE(completion, first);
            } else {
                AWELogToolError(AWELogToolTagRecord, @"Prop Gray Ability fetch Effect Model, error=%@", error);
            }
            NSInteger status = (error) ? 1 : 0;
            [ACCMonitor() trackService: @"fetch_gray_sticker_id" status:status extra: json];
    }];
}

- (void)p_downloadGrayProp:(IESEffectModel *)model
                completion:(ACCGrayPropEffectModelBlock)completion
{
    [EffectPlatform downloadEffect:model progress:nil completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
        NSMutableDictionary *json = [NSMutableDictionary dictionary];
        json[@"sticker_id"] = model.effectIdentifier;
        NSInteger status = (error) ? 1 : 0;
        [ACCMonitor() trackService: @"fetch_gray_sticker" status:status extra:json];
        if (filePath && !error) {
            ACCBLOCK_INVOKE(completion, model);
        } else {
            AWELogToolError(AWELogToolTagNone, @"Prop Gray Ability download Effect Model, error=%@", error);
        }
    }];
}

#pragma mark - ACCRecordPropService - Subscriber
// 监听非灰度道具的应用
- (void)propServiceWillApplyProp:(IESEffectModel *)prop propSource:(ACCPropSource)propSource
{
    if (prop == nil && propSource != ACCPropSourceKeepWhenEdit) {
        // 取消道具使用，尝试使用灰度道具
        @weakify(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kACCGrayPropTrialDelaySeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @strongify(self);
            [self p_checkAndApplyGrayProp:self.grayProp];
        });
    } else {
        // 准备使用正式道具,打开消息传递
        [self p_trackGrayStickerRunInfoClient]; // 在应用道具之前，调用
        self.isMessageFilterEnabled = NO;
    }
}

#pragma mark - ACCRecordFlowService - Subscriber
// 抽帧
- (void)flowServiceDidAddFragment:(AWEVideoFragmentInfo *)fragment
{
    NSString *currentPropId = self.cameraService.effect.currentSticker.effectIdentifier;
    if (self.grayProp && [self.grayProp.effectIdentifier isEqualToString:currentPropId]) {
        fragment.isSupportExtractFrame = YES;
    }
}

- (void)flowServiceWillEnterNextPageWithMode:(ACCRecordMode *)mode
{
    // 进入编辑页后,收不到Effect消息,此处做兜底
    [self p_trackGrayStickerRunInfoClient];
}

#pragma mark - MessageWrapper - ACCEffectEvent
// 灰度道具使用过程中的消息监听
- (BOOL)shouldTransferMessage:(IESMMEffectMessage *)message
{
    return [self shouldTransferGrayAbilityMessage:message];
}

#pragma mark - ACCRecordSwitchModeService - Subscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    BOOL shouldRemove = [self.grayPropBlockModeArray containsObject:@(mode.modeId)];
    BOOL shouldReapply = [self.grayPropBlockModeArray containsObject:@(oldMode.modeId)] &&
                         ![self.grayPropBlockModeArray containsObject:@(mode.modeId)];

    if (shouldRemove) {
        [self p_trackGrayStickerRunInfoClient];
        [self p_checkAndRemoveGrayProp];
    } else if (shouldReapply) {
        [self p_checkAndApplyGrayProp:self.grayProp];
    }
}

- (NSArray *)grayPropBlockModeArray
{
    if (!_grayPropBlockModeArray) {
        _grayPropBlockModeArray = @[
            @(ACCRecordModeMV),
            @(ACCRecordModeLive),
            @(ACCRecordModeText),
            @(ACCRecordModeKaraoke)
        ];
    }
    return _grayPropBlockModeArray;
}

- (void)p_checkAndRemoveGrayProp
{
    if (self.isCameraUsingGrayProp) {
        [self.cameraService.effect acc_applyStickerEffect:nil];
    }
}

#pragma mark - Background

- (void)enterBackgroundNotification
{
    [self p_trackGrayStickerRunInfoClient];
    [self p_checkAndRemoveGrayProp];
}

- (void)enterForegroundNotification
{
    [self p_checkAndApplyGrayProp:self.grayProp];
}


#pragma mark - Track

- (void)p_trackGrayStickerRunInfoClient
{
    if (self.grayPropStartTimePoint) {
        NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:self.grayPropStartTimePoint];
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        params[@"duration"] = @(duration);
        params[@"from"] = @"Client";
        params[@"prop_id"] = self.grayProp ? self.grayProp.effectIdentifier : @"";
        params[@"info_ext"] = @"Client: new ability run is ok";
        [ACCTracker() trackEvent:@"gray_sticker_run_info" params:params];
        self.grayPropStartTimePoint = nil;
    }
}

#pragma mark - AB

- (void)p_configGrayAbilityAB
{
    NSDictionary *dict = ACCConfigDict(kConfigDict_studio_new_ability_gray_prop);
    self.enableNewAbility = [dict acc_boolValueForKey:@"record_sticker_gray"];
    self.maxTrialTimes = [dict acc_integerValueForKey:@"run_max_count"];

    NSString *blackListString = [dict acc_stringValueForKey:@"sticker_id_block_lists" defaultValue:nil];
    self.blackList = [blackListString componentsSeparatedByString:@","];
}


#pragma mark - Gray Message Filter

/// 允许传递的消息就过滤，不允许的会弹窗(每进入一次拍摄页只弹一次)
/// hook: ACCPropComponentGrayAbilityPlugin+Debug
- (BOOL)shouldTransferGrayAbilityMessage:(IESMMEffectMessage *)message
{
    if (!self.isMessageFilterEnabled) {
        return YES;
    }

    NSDictionary *jsonDict = [self p_getJsonFromString:message.arg3];

    BOOL shouldTransfer = NO;
    shouldTransfer = [self handleInterfaceMessage:message withDataJson:jsonDict] ||
                     [self handleRecognizeMessage:message withDataJson:jsonDict] ||
                     [self handleFaceCountMessage:message withDataJson:jsonDict] ||
                     [self handleGrayPropMessage:message withDataJson:jsonDict] ||
                     [self handleClientMonitorMessage:message withDataJson:jsonDict];

    if (!shouldTransfer) {
        NSMutableDictionary *extra = [NSMutableDictionary dictionary];
        extra[@"sticker_id"] = self.grayProp ? self.grayProp.effectIdentifier : @"";
        extra[@"message_type"] = @(message.msgId);
        extra[@"arg1"] = @(message.arg1);
        extra[@"arg2"] = @(message.arg2);
        extra[@"arg3"] = message.arg3;
        [ACCMonitor() trackService: @"received_effect_msg_for_gray_sticker" status:0 extra:extra];
    }

    return shouldTransfer;
}



#pragma mark - message handler
/// handler:
/// 如果不是自己负责消息， 返回NO
/// 如果是自己负责消息，根据自己的需要返回YES 或者NO

// interface
- (BOOL)handleInterfaceMessage:(IESMMEffectMessage *)message withDataJson:(NSDictionary *)jsonDict
{
    if (message.type == IESMMEffectMsgOther && message.msgId == kGrayAbilityEffectMsgId) {
        NSString *interface = [jsonDict acc_stringValueForKey:KGrayAbilitykInterfaceKey];
        if ([self isAllowedInterface:interface]) {
            return YES;
        }
    }
    return NO;
}

// face
- (BOOL)handleFaceCountMessage:(IESMMEffectMessage *)message withDataJson:(NSDictionary *)jsonDict
{
    if (message.type == IESMMEffectMsgOther && message.msgId == kGrayAbilityFaceCountMsgId) {
        return YES;
    }
    return NO;
}


// gray prop
- (BOOL)handleGrayPropMessage:(IESMMEffectMessage *)message withDataJson:(NSDictionary *)jsonDict
{
    /// Effect 传递的灰度道具消息，返回YES，避免弹窗
    if (message.type == IESMMEffectMsgOther && message.msgId == kACCGrayPropEffectMsgId) {
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        params[@"duration"] = [jsonDict acc_objectForKey:@"duration"];
        params[@"from"] = @"Effect";
        params[@"prop_id"] = self.grayProp ? self.grayProp.effectIdentifier : @"";
        params[@"info_ext"] = [jsonDict acc_stringValueForKey:@"info_ext"];
        [ACCTracker() trackEvent:@"gray_sticker_run_info" params:params];
        return YES;
    }

    return NO;
}

// recognize
- (BOOL)handleRecognizeMessage:(IESMMEffectMessage *)message withDataJson:(NSDictionary *)jsonDict
{
    if (message.type == IESMMEffectMsgStickerRecognize && message.msgId == kGrayAbilityStickerRecognizeMsgId) {
        return YES;
    }
    return NO;
}

- (BOOL)handleClientMonitorMessage:(IESMMEffectMessage *)message withDataJson:(NSDictionary *)jsonDict
{
    if (message.type == IESMMEffectMsgOther && message.msgId == kGrayAbilityClientMonitorMsgId) {
        return YES;
    }
    return NO;
}

- (BOOL)isAllowedInterface:(NSString *)interfaceStr
{
    NSArray *allowedInterfaces = @[kGrayAbilityInterfaceValueGetCookie,
                                   kGrayAbilityInterfaceValueRequest,
                                   kGrayAbilityInterfaceValueDownload,
                                   kGrayAbilityInterfaceValueDownloadModel];
    return [allowedInterfaces containsObject:interfaceStr];
}

- (NSDictionary *)p_getJsonFromString:(NSString *)string
{
    NSDictionary *jsonDict = [NSDictionary dictionary];
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    if (data) {
        NSError *error = nil;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (!error && [dict isKindOfClass:NSDictionary.class]) {
            jsonDict = dict;
        } else {
            AWELogToolError(AWELogToolTagNone, @"ACCPropComponenGrayAbilityPlugin JSON serialization failed, error=%@", error);
        }
    }
    return jsonDict;
}

@end
