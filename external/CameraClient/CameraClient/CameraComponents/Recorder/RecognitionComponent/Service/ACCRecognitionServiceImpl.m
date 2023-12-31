//
//  ACCRecognitionServiceImpl.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/6.
//

#import "ACCRecognitionServiceImpl.h"
#import <CameraClient/ACCRecordViewControllerInputData.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import "AWEVideoPublishViewModel+ACCTask.h"
#import <CameraClient/ACCHotPropDataManager.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <ReactiveObjC/RACSequence.h>
#import <ReactiveObjC/RACSubject.h>
#import <ReactiveObjC/NSArray+RACSequenceAdditions.h>
#import <ReactiveObjC/RACTuple.h>
#import <CameraClient/ACCRecognitionConfig.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import "ACCRecognitionScannerWrapper.h"
#import <EffectPlatformSDK/EffectPlatform.h>
#import <CameraClient/ACCRecognitionTrackModel.h>
#import <SmartScan/SSRecommendResult.h>
#import <SmartScan/SSScanResult.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <TTVideoEditor/IESMMEffectMessage.h>
#import <CreationKitArch/IESEffectModel+ACCSticker.h>
#import <ByteDanceKit/BTDReachability.h>
#import <CameraClient/ACCRecognitionEnumerate.h>
#import <CameraClient/AWERepoContextModel.h>
#import <CameraClient/AWERepoTrackModel.h>
#import <CameraClient/ACCKaraokeService.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CameraClient/ACCFlowerCampaignManagerProtocol.h>
#import <CameraClient/AWERepoDuetModel.h>
#import <CreativeKit/ACCMacros.h>
#import "ACCScanService.h"
#import "ACCFlowerService.h"

#define let const __auto_type
#define var __auto_type

typedef NS_ENUM(NSUInteger, ACCRecognitionDisable) {
    ACCRecognitionDisableNone,      /// can recognize
    ACCRecognitionDisableEntry,     /// can't recognize for wrong entry
    ACCRecognitionDisableMode,      /// can't recognize for wrong mode
    ACCRecognitionDisableModeHard,  /// can't recognize for wrong mode and clear recognition
    ACCRecognitionDisableRecording, /// can't recognize after begin record
};

NSString * const kACCRecogEnterMethodLongPress = @"long_press";
NSString * const kACCRecogEnterMethodIconClick = @"icon_click";
NSString * const kACCRecogEnterMethodFlowerPanelAuto = @"flower_panel_auto";
NSString * const kACCRecogEnterMethodFlowerPanelLongPress = @"flower_panel_long_press";

NSString * const kACCRecognitionBubbleShowKey = @"kACCRecognitionBubbleShowKey_";

NSString * const kACCRecognitionDetectModeAnimal = @"3";
NSString * const kACCRecognitionDetectModeQRCode = @"6";

@interface ACCRecognitionServiceImpl()
@property (nonatomic, assign) ACCRecognitionState recognitionState;
@property (nonatomic, copy, nullable) NSString *currentDetectModeStr;
@property (nonatomic, copy, nullable) NSArray<NSString *> *currentDetectModeArray;
@property (nonatomic, assign) ACCRecognitionDetectResult detectResult;
@property (nonatomic, strong) ACCHotPropDataManager *dataManager;
@property (nonatomic, strong) ACCRecordMode *recordMode;
@property (nonatomic, assign) ACCRecognitionRecorderState recordState;
@property (nonatomic, assign) ACCRecognitionDisable recognizeDisable;
@property (nonatomic, strong) ACCRecognitionScannerWrapper *scanner;
@property (nonatomic, strong) RACSubject<RACTwoTuple<SSRecommendResult *, NSString *> *> *recognitionResultSignal;
@property (nonatomic, strong) RACSubject *recognitionEffectsSignal;
@property (nonatomic, strong) RACSubject *disableRecognitionSignal;
@property (nonatomic, strong) RACSubject *hiddenSwitchModeSignal;
@property (nonatomic, strong) IESMMEffectMessage *recognitionMessage;
@property (nonatomic, strong) ACCRecognitionTrackModel *trackModel;

@end

@implementation ACCRecognitionServiceImpl

@synthesize inputData = _inputData;
@synthesize cameraService = _cameraService;
@synthesize propService = _propService;
@synthesize karaokeService = _karaokeService;
@synthesize stashedEffect = _stashedEffect;
@synthesize scanService = _scanService;
@synthesize flowerService = _flowerService;

- (instancetype)initWithInputData:(ACCRecordViewControllerInputData *)inputData
{
    if (self = [super init]){
        _inputData = inputData;
        _dataManager = [[ACCHotPropDataManager alloc] initWithCount:(NSInteger)ACCConfigInt(kConfigInt_expose_prop_panel_count) + 5];  /// request more for filter
        _dataManager.testStatusType = ACCConfigInt(kConfigInt_effect_test_status_code);
        _dataManager.fromPropId = inputData.localSticker.effectIdentifier;
        _recognizeDisable = [self checkInputData:inputData];
        _recognitionResultSignal = [RACSubject subject];
        _recognitionEffectsSignal = [RACSubject subject];
        _disableRecognitionSignal = [RACSubject subject];
        _hiddenSwitchModeSignal = [RACSubject subject];
    }
    return self;
}

- (void)willRelease
{
    [_recognitionResultSignal sendCompleted];
    [_recognitionEffectsSignal sendCompleted];
    [_disableRecognitionSignal sendCompleted];
    [_hiddenSwitchModeSignal sendCompleted];
    [self stopAutoScan];
    [self releaseScanner];
}

- (ACCRecognitionDisable)checkInputData:(ACCRecordViewControllerInputData *)inputData
{
    BOOL isDuet = inputData.publishModel.repoDuet.isDuet;
    return (inputData.isSplitOrChallenge || isDuet) ? ACCRecognitionDisableEntry : ACCRecognitionDisableNone;
}

- (BOOL)disableRecognize
{
    return self.recognizeDisable != ACCRecognitionDisableNone;
}

- (void)askingHideSwithModeView:(BOOL)hidden
{
    [self.hiddenSwitchModeSignal sendNext:@(hidden)];
}

- (ACCRecognitionScannerWrapper *)scanner {

    if (_scanner) return _scanner;

    ACCRecognitionScannerWrapper *scanner = [ACCRecognitionScannerWrapper new];
    scanner.cameraService = self.cameraService;
    scanner.recognitionService = self;

    return _scanner = scanner;
}

#pragma mark - 长按/侧边栏 触发扫描

- (void)captureImagesAndRecognize:(NSString *)enter detectMode:(NSString * _Nullable)detectMode
{
    RECOG_LOG(@"begin recognize");
    self.currentDetectModeStr = detectMode;
    self.currentDetectModeArray = [detectMode componentsSeparatedByString:@","];
    self.recognitionState = ACCRecognitionStateRecognizing;

    if (![[BTDReachabilityManager sharedManager] isReachable]){
        RECOG_LOG(@"no network");
        self.recognitionState = ACCRecognitionStateRecognizeNoNetwork;
        return;
    }
    
    /// clear previous result
    self.trackModel = nil;

    self.trackModel = [ACCRecognitionTrackModel new];
    self.trackModel.enterMethod = enter;
    self.trackModel.begin = CACurrentMediaTime()*1000;
    self.trackModel.realityId = [NSUUID UUID].UUIDString;

    [self setupTrackModel:self.trackModel];

    RECOG_LOG(@"scan with mode %@", detectMode);

    /// cancel previous scanning (if exists)
    [self.scanService cancelBachPropScan];
    [self.scanner cancelRecognizeScanning];

    RECOG_LOG(@"scan begin %@", @(self.trackModel.begin));
    self.detectResult = ACCRecognitionDetectResultNone;
    
    BOOL applyQRCodeScan = [self qrCodeScanIsRequiredForModes:self.currentDetectModeArray];
    @weakify(self);
    if (applyQRCodeScan) {
        [self.scanService scanByBachProp:^(NSString * _Nullable r, NSError * _Nullable e) {
            @strongify(self);
            RECOG_LOG(@"bach prop completed: r=%@ hasError=%d", r, e != nil);
            if (ACC_isEmptyString(r) || e) {
                [self scanFailedWithQRScanResult:r ssResult:nil error:e];
            } else {
                [self scanSucceededWithDetectResult:ACCRecognitionDetectResultQRCode qrScanResult:r ssResult:nil];
            }
        }];
    }
    
    BOOL applySmartScan = [self smartScanIsRequiredForModes:self.currentDetectModeArray];
    if (applySmartScan) {
        [self.scanner scanForRecognizeWithMode:detectMode completion:^(SSRecommendResult *_Nullable result, NSError * _Nullable error) {
            @strongify(self);
            RECOG_LOG(@"smart scan completed: hasError=%d", error != nil);
            let imageTags = result.data.imgTags.imageTags;
            let recommendStickers = result.data.stickers.stickers;
            BOOL success = result && result.statusCode == 0 && (imageTags.count > 0 || recommendStickers.count > 0);
            BOOL smartScanRecognizedQRCode = success && imageTags.firstObject.tagInfoType == 2;
            if (smartScanRecognizedQRCode) {
                if (applyQRCodeScan) {
                    // wait for bach result
                    return;
                } else {
                    [self scanFailedWithQRScanResult:nil ssResult:result error:error];
                }
            }
            if (success) {
                [self scanSucceededWithDetectResult:ACCRecognitionDetectResultSmartScan qrScanResult:nil ssResult:result];
            } else {
                [self scanFailedWithQRScanResult:nil ssResult:result error:error];
            }
        }];
    }
}

- (void)scanFailedWithQRScanResult:(nullable NSString *)qrScanResult ssResult:(nullable SSRecommendResult *)ssResult error:(NSError *)error
{
    // clean up
    [self.scanner cancelRecognizeScanning];
    [self.scanService cancelBachPropScan];
    self.detectResult = ACCRecognitionDetectResultNone;
    
    // track scan duration
    let end = CACurrentMediaTime()*1000;
    RECOG_LOG(@"scan end %@", @(end));
    self.trackModel.duration = (end - self.trackModel.begin);
    self.trackModel.isSuccess = NO;
    [ACCTracker() trackEvent:@"smart_scan_recognition_duration" params:@{
        @"duration" : @(self.trackModel.duration),
        @"is_flower" : self.flowerService.inFlowerPropMode ? @(1) : @(0),
    } needStagingFlag:NO];
    
    
    RECOG_ERR(@"failed with error: %@", error);
    self.trackModel.realityType = @"prop_recommend";
    [ACCTracker() trackEvent:@"smart_scan_recognition_success_rate"
                      params:@{@"is_success":@1,  /// yes, it's not typo, is_success is 1 when failed. :(
                               @"status_code": ssResult? @(ssResult.statusCode) : @(error.code),
                               @"error_msg": [NSString stringWithFormat:@"%@ %@", ssResult.message, ssResult.dataExtra.logID],
                               @"is_flower" : self.flowerService.inFlowerPropMode ? @(1) : @(0),
                      } needStagingFlag:NO];
    [self.recognitionResultSignal sendNext:nil];
    [self.recognitionEffectsSignal sendNext:nil];
    self.recognitionState = ACCRecognitionStateRecognizeFailed;

}

- (void)scanSucceededWithDetectResult:(ACCRecognitionDetectResult)detectResult qrScanResult:(nullable NSString *)qrScanResult ssResult:(nullable SSRecommendResult *)ssResult
{
    // clean up
    [self.scanner cancelRecognizeScanning];
    [self.scanService cancelBachPropScan];
    self.detectResult = detectResult;
    
    // track scan duration
    RECOG_LOG(@"scan success detectResult %lu", (unsigned long)detectResult);
    let end = CACurrentMediaTime()*1000;
    RECOG_LOG(@"scan end %@", @(end));
    self.trackModel.duration = (end - self.trackModel.begin);
    self.trackModel.isSuccess = YES;
    [ACCTracker() trackEvent:@"smart_scan_recognition_duration" params:@{
        @"duration" : @(self.trackModel.duration),
        @"is_flower" : self.flowerService.inFlowerPropMode ? @(1) : @(0),
    } needStagingFlag:NO];
    
    //MARK: 识别结果是 码
    if (detectResult == ACCRecognitionDetectResultQRCode) {
        [self setupTrackModel:nil]; // 如果识别到二维码，清空 RepoModel，因为二维码不能拍视频，直接跳转到落地页了。
        // 识别二维码，也上报qr_code_scan_enter
        [ACCTracker() trackEvent:@"qr_code_scan_enter" params:@{@"enter_from":@"video_shoot_page",
                                                                @"enter_method":@"long_press", // 不区分长按和侧边栏
                                                                @"params_for_special": @"flower",
                                                                @"activity_id" :  ACCConfigString(kConfigString_tools_flower_activity_id),
                                                                @"act_id" : [ACCFlowerCampaignManager() activityHashString],
                                                       }];
        [ACCTracker() trackEvent:@"smart_scan_recognition_success_rate"
                          params:@{@"is_success":@0,
                                   @"status_code":@0,
                                   @"error_msg": @"",
                                   @"is_flower" : self.flowerService.inFlowerPropMode ? @(1) : @(0),
                          } needStagingFlag:NO];
        // 识别到码 需要先更新 recognitionState，再发送 recognitionResultSignal，因为 RecognitionComponent 接收到 recognitionResultSignal 时，会 resetRecognition（退出扫码模式），将 recognitionState 设置为 Normal。
        self.recognitionState = ACCRecognitionStateRecognized;
        [self.recognitionResultSignal sendNext:[RACTwoTuple pack:ssResult :qrScanResult]]; // 虽然只识别到了二维码，但可以把两个结果都发出去，没影响
        return;
    }
    //MARK: 识别结果是 智识
    [ACCTracker() trackEvent:@"smart_scan_recognition_success_rate"
                      params:@{@"is_success":@0,
                               @"status_code":ssResult? @(ssResult.statusCode) : @(0),
                               @"error_msg": [NSString stringWithFormat:@"%@ %@", ssResult.message, ssResult.dataExtra.logID],
                               @"is_flower" : self.flowerService.inFlowerPropMode ? @(1) : @(0),
                      } needStagingFlag:NO];
    let imageTags = ssResult.data.imgTags.imageTags;
    let recommendStickers = ssResult.data.stickers.stickers;
    /// wiki first
    if (imageTags.count > 0){
        self.trackModel.realityType = @"wiki_reality";
    }
    else{
        self.trackModel.realityType = @"general_reality";
    }
    [self setupTrackModel:self.trackModel];

    [self.recognitionResultSignal sendNext:[RACTwoTuple pack:ssResult :qrScanResult]];

    /// extract propIds
    NSArray *propIds = imageTags.count > 0 ? @[ssResult.data.imgTags.stickerID] : @[];
    if (ACCRecognitionConfig.supportScene){
        NSArray *scenePropIds = [recommendStickers.rac_sequence map:^id _Nullable(SSRecommendSticker * _Nullable value) {
            return value.stickerID;
        }].array;
        /// makesure wiki result is valid
        if (scenePropIds.count > 0){
            propIds = [propIds arrayByAddingObjectsFromArray:scenePropIds];
        }
    }

    /// download props
    if (propIds.count > 0){
        [EffectPlatform fetchEffectListWithEffectIDS:propIds completion:^(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects, NSArray<IESEffectModel *> * _Nullable bindEffects) {
            /// Reset alreay
            if (self.recognitionState != ACCRecognitionStateRecognizing){
                return;
            }
            RECOG_LOG(@"fetch %@ effect", @(effects.count));
            [self.recognitionEffectsSignal sendNext:effects];

            self.recognitionState = ACCRecognitionStateRecognized;
        }];
    } else {
        ACCAssert(NO, @"stickerID %@ recommendIDs %@", ssResult.data.imgTags.stickerID, recommendStickers);
        RECOG_ERR(@"sticker id is empty");
        /// impossible? also treat as failed
        [self.recognitionEffectsSignal sendNext:@[]];
        self.recognitionState = ACCRecognitionStateRecognizeFailed;
    }
}

- (void)setupTrackModel:(ACCRecognitionTrackModel *)trackModel
{
    AWERepoContextModel *contextModel = [self.inputData.publishModel extensionModelOfClass:AWERepoContextModel.class];

    if (trackModel){
        contextModel.feedType = ACCFeedTypeRecognition;
        [self.inputData.publishModel.repoTrack.repository setExtensionModelByClass:trackModel];
    }else{
        contextModel.feedType = ACCFeedTypeGeneral;
        [self.inputData.publishModel.repoTrack.repository removeExtensionModel:ACCRecognitionTrackModel.class];
    }
}

- (void)startAutoScanWithFilter:(ACCRecognitionFilterBlock)filter completion:(ACCRecognitionBlock)completion {
    @weakify(self)

    RECOG_LOG(@"begin autoscan");
    [self.scanner startAutoScanWithFliter:^BOOL(SSScanResult * _Nullable result) {
        return filter([self getMaxClarityScoreResult:result.recognitionResult]);
    } completion:^(SSScanResult * _Nullable result, NSError * _Nullable error) {

        @strongify(self)

        if (result){
            RECOG_LOG(@"autoscan success");
            completion([self getMaxClarityScoreResult:result.recognitionResult], nil);
        }else{
            RECOG_ERR(@"autoscan fail: %@", error.localizedDescription);
            completion(nil, error);
        }
    }];
}

- (RACTwoTuple *)getMaxClarityScoreResult:(NSDictionary *)result
{
    return [result.allKeys.rac_sequence foldLeftWithStart:nil reduce:^id _Nullable(RACTwoTuple*  _Nullable current, NSString*  _Nullable key) {

        CGFloat score = [result btd_floatValueForKey:key];
        if (score > [current.second floatValue]){
            return [RACTwoTuple pack:key :@(score)];
        }
        return current;
    }];
}

- (void)stopAutoScan {
    [_scanner stopAutoScan];
}

- (void)releaseScanner
{
    RECOG_LOG(@"release scanner");
    self.scanner = nil;
}


- (void)resetRecognition {
    self.recognitionState = ACCRecognitionStateNormal;
    self.trackModel = nil;
    self.stashedEffect = nil;

    RECOG_LOG(@"reset recognition");

    [self setupTrackModel:nil];

    [self.scanner cancelRecognizeScanning];
    if ([self qrCodeScanIsRequiredForModes:self.currentDetectModeArray]) {
        [self.scanService cancelBachPropScan];
    }
    self.detectResult = ACCRecognitionDetectResultNone;
    self.currentDetectModeStr = nil;
    self.currentDetectModeArray = nil;

    [self askingHideSwithModeView:NO];
}

- (void)applyProp:(IESEffectModel *)prop propSource:(ACCPropSource)propSource
{
    /// supportScene means prop came from recognition prop panel
    if (prop && [ACCRecognitionConfig supportScene]){
        let json = [MTLJSONAdapter JSONDictionaryFromModel:prop error:nil];
        prop = [MTLJSONAdapter modelOfClass:IESEffectModel.class fromJSONDictionary:json error:nil];
        prop.panelName = @"recognition";
    }
    /// propSource changes in too many cases, effectIdentifier will be better
    else if (!prop && ![self.propService.prop.effectIdentifier isEqualToString:self.stashedEffect.effectIdentifier] &&
             propSource != ACCPropSourceReset){
        return;
    }

    [self.propService applyProp:prop propSource:propSource propIndexPath:nil];

    /// stash prop when non-nil or force reset
    if (prop || (!prop && propSource == ACCPropSourceReset)){
        self.stashedEffect = prop;
    }
}

- (void)setStashedEffect:(IESEffectModel *)stashedEffect
{
    _stashedEffect = stashedEffect;
    if (stashedEffect) {
        
    }
}

- (BOOL)shouldShowSwitchMode
{
    if (self.stashedEffect){
        return NO;
    }

    /// inserted homeItem, and current item is homeItem
    if (_trackModel && _trackModel.propIndex == 0){
        return NO;
    }
    return YES;
}

- (void)recoverRecognitionStateIfNeeded
{
    if (!self.stashedEffect){
        return;
    }
    self.recognizeDisable = ACCRecognitionDisableNone;
    self.recognitionState = ACCRecognitionStateRecognizeRecover;
    [self applyProp:self.stashedEffect propSource:ACCPropSourceRecognition];
//    self.stashedEffect = nil;

}

#pragma mark - Scan QRCode with Bach Prop

#pragma mark - bubble & tip

- (BOOL)shouldShowBubble:(ACCRecognitionBubble)bubble
{
    /// direct shoot from "+" tab & not come with 'shoot same'
    if (![self.inputData.publishModel.repoTrack.referString isEqualToString:@"direct_shoot"] ||
        self.inputData.sameStickerMusic ||
        self.inputData.sameMVTemplateModel ||
        self.inputData.statusTemplateModel ||
//        [GET_PROTOCOL(AWEStudioModuleService) isSpecialPlusBtn] ||
        self.inputData.statusTemplateId) {
        return NO;
    }

    /// has showed bubble already
    if ([self bubbleShowed:bubble]){
        return NO;
    }

    return ![self isTodayFirstRecord];
}

- (NSString *)keyForBubble:(ACCRecognitionBubble)bubble
{
    return [kACCRecognitionBubbleShowKey stringByAppendingString:@(bubble).stringValue];
}

- (BOOL)bubbleShowed:(ACCRecognitionBubble)bubble
{
    NSInteger count = [ACCCache() integerForKey:[self keyForBubble:bubble]];

    NSInteger max = 1;
    switch (bubble) {
        case ACCRecognitionBubbleLongPress:
        case ACCRecognitionBubbleRightItem:
        case ACCRecognitionBubblePrivacy:
            max = 1;
            break;
        case ACCRecognitionBubblePropHint:
            max = 3;
            break;
        case ACCRecognitionBubbleFlower:
            max = [ACCRecognitionConfig autoScanHintDailyShowMaxCount];
            break;
            
        default:
            break;
    }

    return count >= max;
}

/// is first enter today?
- (BOOL)isTodayFirstRecord
{
    NSInteger record = [ACCCache() integerForKey:@"camera_enter_in_day"];
    NSDate *previousAccess = [NSDate dateWithTimeIntervalSince1970:record];
    if ([NSCalendar.currentCalendar isDateInToday:previousAccess]){
        return NO;
    }

    [ACCCache() setInteger:[NSDate.date timeIntervalSince1970] forKey:@"camera_enter_in_day"];
    return YES;
}

- (void)markShowedBubble:(ACCRecognitionBubble)bubble
{
    NSString *key = [self keyForBubble:bubble];
    NSInteger count = [ACCCache() integerForKey:key];
    [ACCCache() setInteger:count+1 forKey:key];
}

#pragma mark - state

- (void)updateRecordMode:(ACCRecordMode *)mode
{
    self.recordState = ACCRecognitionRecorderStateNormal;
    self.recordMode = mode;

    /// only handle disable for mode
    if (self.recognizeDisable != ACCRecognitionDisableNone &&
        self.recognizeDisable != ACCRecognitionDisableMode){
        return;
    }

    /// KaraokeRecord and audioOnlyRecord is not allowed
    BOOL isCorrectMode = (self.recordMode.isVideo || self.recordMode.isPhoto) && (self.recordMode.modeId != ACCRecordModeKaraoke) && ![self.karaokeService inKaraokeRecordPage] && (self.recordMode.modeId != ACCRecordModeAudio);
    self.recognizeDisable = isCorrectMode ? ACCRecognitionDisableNone : ACCRecognitionDisableMode;
}

- (void)enterDisablePage:(BOOL)enter
{
    /// just quit recognition, no recovery
    if (enter && self.recognizeDisable == ACCRecognitionDisableNone){
        self.recognizeDisable = ACCRecognitionDisableModeHard;
        [self resetRecognition];
    }
    else if (!enter && (self.recognizeDisable == ACCRecognitionDisableMode ||self.recognizeDisable == ACCRecognitionDisableModeHard)){
        self.recognizeDisable = ACCRecognitionDisableNone;
    }
}

- (void)setRecognizeDisable:(ACCRecognitionDisable)recognizeDisable
{
    BOOL old = [self disableRecognize];
    _recognizeDisable = recognizeDisable;
    BOOL new = [self disableRecognize];
    if (old != new){
        [self.disableRecognitionSignal sendNext:[RACTwoTuple pack:@([self disableRecognize]) :@(recognizeDisable == ACCRecognitionDisableModeHard)]];
    }
}

- (BOOL)isReadyForRecognition
{
    return
    self.recognitionState == ACCRecognitionStateNormal ||
    self.recognitionState == ACCRecognitionStateRecognizeNoNetwork;

}

- (void)updateRecordState:(ACCRecognitionRecorderState)state
{
    self.recordState = state;

    /// only handle disable for recording
    if (self.recognizeDisable != ACCRecognitionDisableNone &&
        self.recognizeDisable != ACCRecognitionDisableRecording){
        return;
    }

    self.recognizeDisable = self.recordState != ACCCameraRecorderStateNormal? ACCRecognitionDisableRecording: ACCRecognitionDisableNone;

}

- (void)updateMessage:(IESMMEffectMessage *)message
{
    self.recognitionMessage = message;
}

- (double)thresholdFor:(ACCRecognitionThreashold)threshold
{
    return [ACCRecognitionConfig thresholdFor:threshold];
}

- (void)updateTrackModel
{
    [self setupTrackModel:self.trackModel];
}

- (BOOL)qrCodeScanIsRequiredForModes:(NSArray<NSString *> *)modes
{
    return [modes containsObject:kACCRecognitionDetectModeQRCode];
}

- (BOOL)smartScanIsRequiredForModes:(NSArray<NSString *> *)modes
{
    return !ACC_isEmptyArray(modes);
}

@end
