//
//  ACCRecognitionComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by yanjianbo on 2021/06/01.
//  Copyright © 2021年 bytedance. All rights reserved
//

#import "ACCRecognitionComponent.h"

#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitArch/ACCRecorderToolBarDefines.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreationKitArch/ACCRecordTrackService.h>
#import <CameraClient/ACCRecordPropService.h>
#import <CameraClient/ACCKaraokeService.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CameraClient/ACCPropViewModel.h>
#import <CameraClient/ACCRecordGestureService.h>
#import <CameraClient/AWERecorderTipsAndBubbleManager.h>
#import <CreativeKit/ACCProtocolContainer.h>
#import <CameraClient/AWERecognitionLoadingView.h>

#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>

#import <CameraClient/ACCRecordFlowService.h>
#import "ACCRecognitionService.h"
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CameraClient/ACCRecognitionConfig.h>
#import <CameraClient/AWERepoContextModel.h>
#import <CameraClient/ACCRecognitionTrackModel.h>
#import <TTReachability/TTReachability.h>
#import <CameraClient/AWECameraPreviewContainerView.h>
#import "ACCRecognitionDownloadSubject.h"
#import "ACCResourceLoadingView.h"
#import <CameraClient/ACCRecognitionEnumerate.h>
#import <CameraClient/AWERepoTrackModel.h>
#import "ACCScanService.h" // 负责本地Bach算法扫码
#import "ACCQRCodeResultHandlerProtocol.h" // 把 AWEScanModuleService 的能力注入
#import "AWERepoContextModel.h"
#import "AWERepoFlowerTrackModel.h"
#import "ACCFlowerCampaignManagerProtocol.h"
#import "ACCFlowerService.h"
#import "ACCFlowerPanelEffectListModel.h"
#import <CameraClient/ACCRouterProtocolD.h>


#import <CreativeKit/ACCAnimatedButton.h>
#import <CreationKitInfra/UILabel+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>

ACCContextId(ACCFlowePanelRecog)

@interface ACCRecognitionComponent () <ACCCameraLifeCircleEvent, ACCRecordSwitchModeServiceSubscriber, ACCRecordPropServiceSubscriber, ACCKaraokeServiceSubscriber, ACCRecordGestureServiceSubscriber, ACCFlowerServiceSubscriber>

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, weak  ) id<ACCCameraService> cameraService;
@property (nonatomic, weak  ) id<ACCRecordTrackService> trackService;
@property (nonatomic, weak  ) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, weak  ) id<ACCRecordPropService> propService;
@property (nonatomic, weak  ) id<ACCRecordGestureService> gestureService;
@property (nonatomic, weak  ) id<ACCRecordFlowService> flowService;
@property (nonatomic, weak  ) id<ACCKaraokeService> karaokeService;
@property (nonatomic, weak) id<ACCFlowerService> flowerService;
@property (nonatomic, strong) id<ACCQRCodeResultHandlerProtocol> qrCodeHandler;
@property (nonatomic, assign) BOOL isPresenting;

@property (nonatomic, strong) id<ACCRecognitionService> recognitionService;

@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, assign) BOOL showedFlowerBubble; /// only show once in lifecycle
@property (nonatomic, assign) BOOL hasFirstFrameLoaded;  ///是否已完成首帧回调

@property (nonatomic, strong) AWERecognitionLoadingView *recognizingView;
@property (nonatomic, strong) UILabel *recognizePrivacyView;
@property (nonatomic, strong) ACCRecordMode *recordMode;

@property (nonatomic, strong) ACCRecognitionDownloadSubject *downloadSubject;

@end

@implementation ACCRecognitionComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, trackService, ACCRecordTrackService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, propService, ACCRecordPropService)
IESAutoInject(self.serviceProvider, gestureService, ACCRecordGestureService)
IESAutoInject(self.serviceProvider, recognitionService, ACCRecognitionService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)

IESOptionalInject(self.serviceProvider, karaokeService, ACCKaraokeService)

#pragma mark - ACCComponentProtocol

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.cameraService addSubscriber:self];
    [self.cameraService.cameraControl addSubscriber:self];
    [self.cameraService.message addSubscriber:self];
    [self.switchModeService addSubscriber:self];
    [self.propService addSubscriber:self];
    [self.gestureService addSubscriber:self];
    [self.karaokeService addSubscriber:self];
    self.recognitionService.cameraService = self.cameraService;
    self.recognitionService.propService = self.propService;
    self.recognitionService.karaokeService = self.karaokeService;
    self.recognitionService.scanService = IESAutoInline(serviceProvider, ACCScanService);
    self.flowerService = IESAutoInline(serviceProvider, ACCFlowerService);
    [self.flowerService addSubscriber:self];
    self.recognitionService.flowerService = self.flowerService;
    self.qrCodeHandler = IESAutoInline(serviceProvider, ACCQRCodeResultHandlerProtocol);
}

#pragma mark - ACCFeatureComponent

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}


- (void)componentDidMount
{
    self.isFirstAppear = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(reachaiblityDidChanged:)
                                               name:TTReachabilityChangedNotification
                                             object:nil];




    @weakify(self)
    [[self.recognitionService.recognitionResultSignal takeUntil:self.rac_willDeallocSignal].deliverOnMainThread subscribeNext:^(RACTwoTuple<SSRecommendResult *,NSString *> * _Nullable result) {
        @strongify(self)
        if (!result){
            [self showRetryBubble];
        } else if (self.recognitionService.detectResult == ACCRecognitionDetectResultQRCode) {
            UIView<ACCLoadingViewProtocol> *loading = [ACCLoading() showLoadingAndDisableUserInteractionOnView:self.viewContainer.interactionView];
            [self.recognitionService resetRecognition];
            [self.qrCodeHandler handleScanResult:result.second isShapedType:NO enterFrom:@"scan_cam" URLProcessBlock:^NSURL *(NSURL *url) {
                @strongify(self);
                return [self processURLWithURL:url];
            } completion:^{
                [loading dismiss];
            }];
        }
    }];
}

- (NSURL *)processURLWithURL:(NSURL *)URL
{
    if (!URL) {
        return nil;
    }
    NSString *URLString = URL.absoluteString;
    if (![URLString containsString:@"/user/profile"]) {
        return URL;
    }
    URLString = [ACCGetProtocol(IESAutoInline(self.serviceProvider, ACCRouterProtocol), ACCRouterProtocolD) URLString:URLString byAddingQueryDict:@{
        @"enter_from" : @"video_shoot_page",
        @"type" : @"camera_scan_add_friends",
        @"enter_method" : @"scan_cam",
    }];
    
    NSURLComponents *schemeURLComponents = [NSURLComponents componentsWithString:URLString];
    NSString *toUserID = [[schemeURLComponents.path lastPathComponent] stringByDeletingPathExtension];
    [self flowerTrackForEnterProfile:@"video_shoot_page" userID:toUserID];
    return [NSURL URLWithString:URLString];
}

- (AWECameraContainerToolButtonWrapView *)toolBarItemViewWithID:(void *)ID actionBlock:(void(^)(__kindof UIButton * _Nonnull sender))actionBlock icon:(UIImage *)icon labelText:(NSString *)labelText
{
    ACCAnimatedButton *button = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeScale];
    [button setImage:icon forState:UIControlStateNormal];
    
    UILabel *label = [[UILabel alloc] acc_initWithFont:[UIFont boldSystemFontOfSize:10]
                                             textColor:UIColor.whiteColor
                                                  text:labelText];
    label.textAlignment = NSTextAlignmentCenter;
    [label acc_addShadowWithShadowColor:ACCColorFromRGBA(22, 24, 35, 0.2) shadowOffset:CGSizeMake(0, 1) shadowRadius:1];
    label.isAccessibilityElement = NO;
    AWECameraContainerToolButtonWrapView *wrapView = [[AWECameraContainerToolButtonWrapView alloc] initWithButton:button label:label itemID:ACCFlowePanelRecog];

    wrapView.itemViewDidClicked = actionBlock;
    return wrapView;
}

- (void)reachaiblityDidChanged:(NSNotification *)noti
{
    if (![[TTReachability reachabilityForInternetConnection] isInternetConnection]){
        [self cancelCurrentRecognizing];
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)noti
{
    /// category(flower & plant) bubble
    [self showCategoryBubbleIfNeeded];

}

- (void)applicationWillResignActive:(NSNotification *)noti
{
    [self.recognitionService stopAutoScan];
}

- (void)cancelCurrentRecognizing
{
    [self forceResetRecognize:NO];
}

- (void)forceResetRecognize:(BOOL)force
{
    if (self.recognitionService.recognitionState == ACCRecognitionStateRecognizing || force){
        [self showRecognizingTip:NO];
        [self.recognitionService resetRecognition];
    }
}

- (void)componentWillUnmount
{
    [self.recognitionService willRelease];
    [self.downloadSubject willRelease];
}

- (void)componentDidUnmount
{
    self.cameraService = nil;
    [self.inputData.publishModel.repoTrack.repository removeExtensionModel:ACCRecognitionTrackModel.class];

    /// release scanner on subthread
    @weakify(self)
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @strongify(self)
        [self.recognitionService stopAutoScan];
        [self.recognitionService releaseScanner];
    });
}

- (void)componentDidAppear
{
    if (self.isFirstAppear) {
        self.isFirstAppear = NO;
        [self p_bindViewModelObserver];

        /// common tip
        if ([self shouldShowRecognitionBubble]){
            NSString *tip = [ACCRecognitionConfig onlySupportCategory]? @"长按识别花草": @"长按识别环境/物体";
            [AWERecorderTipsAndBubbleManager.shareInstance showRecognitionBubbleWithInputData:self.inputData forView:self.viewContainer.interactionView titleStr:tip contentStr:nil loopTimes:1 showedCallback:^{
                NSMutableDictionary *mDict = self.trackingParams.mutableCopy;
                [mDict setValue:@"long_press" forKey:@"popup_type"];
                [ACCTracker() trackEvent:@"reality_popup_show" params:mDict];
                [self.recognitionService markShowedBubble:ACCRecognitionBubbleLongPress];
            }];
        }

    }
    self.isPresenting = YES;
    /// category(flower & plant) bubble
    [self showCategoryBubbleIfNeeded];
}

- (void)componentWillDisappear
{
    self.isPresenting = NO;
    [self.recognitionService stopAutoScan];
    [self cancelCurrentRecognizing];
}

#pragma mark - init methods

- (void)p_bindViewModelObserver
{

    @weakify(self)    
    [[[RACObserve(self.recognitionService, recognitionState) skip:1] takeUntil:self.rac_willDeallocSignal].deliverOnMainThread subscribeNext:^(NSNumber *  _Nullable x) {
        @strongify(self)
        ACCRecognitionState state = [x integerValue];

        if (state == ACCRecognitionStateRecognizing){
            if (@available(iOS 10.0, *)){
                [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
            }else{
                AudioServicesPlayAlertSoundWithCompletion(kSystemSoundID_Vibrate, nil);
            }
            [AWERecorderTipsAndBubbleManager.shareInstance removeBubbleAndHintIfNeeded];
            if ([self shouldShowPrivacyTip]){
                [self showPrivacyTip];
            }
            // 二维码扫描时会应用本地道具，道具包内已有动画，端上无需展示动画。
            if (![self.recognitionService.currentDetectModeArray containsObject:kACCRecognitionDetectModeQRCode]) {
                [self showRecognizingTip:YES];
            }
        }
        else if (state == ACCRecognitionStateRecognizeFailed){
            [self showRecognizingTip:NO];
            if (ACCRecognitionConfig.onlySupportCategory){
                [self.recognitionService resetRecognition];
            }

            [self showRetryBubble];
        }
        else{
            /// reset current prop while reset recognition
            /// but dont do that while recording
            if ([self.recognitionService isReadyForRecognition]){
                [self.viewContainer showItems:YES animated:NO];
                [AWERecorderTipsAndBubbleManager.shareInstance removeRecognitionBubble:YES];
                if (self.cameraService.recorder.recorderState != ACCCameraRecorderStateRecording){
                    [self.recognitionService applyProp:nil propSource:ACCPropSourceRecognition];
                }
            }
            [self showRecognizingTip:NO];
        }

        /// track 
        [self trackRecognitionResult:state];

    }];

        [[self.recognitionService.recognitionEffectsSignal takeUntil:self.rac_willDeallocSignal] subscribeNext:^(NSArray< IESEffectModel*>*  _Nullable x) {
            @strongify(self)
            // 这个回调只在春节使用，非春节模式走 FlowerPropPanelComponent
            if (!self.flowerService.inFlowerPropMode) {
                return;
            }
            // 可能已经切换到其他tab了
            if (self.flowerService.currentItem.dType != ACCFlowerEffectTypeRecognition) {
                return;
            }
            if (x.count <= 0){
                dispatch_async(dispatch_get_main_queue(), ^{ // 必须dispatch_async，不能 acc_dispatch_main_async_safe，因为resetRecognition 的时候会把所有数据清空，但其他subscriber可能还依赖这一轮的识别结果
                    [self.recognitionService resetRecognition];
                });
                return;
            }
            [self.propService rearInsertAtHotTabWithProps:x];
            /// download even if downloaded already
            let effect = x.firstObject;
            CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
            
            ACCResourceLoadingView *loadingView = [ACCResourceLoadingView new];
            ACCMasMaker(loadingView, {
                make.size.mas_equalTo(CGSizeMake(250, 130));
                make.center.equalTo(self.viewContainer.rootView);
            });
            /// dont delete those blanks, we need'em to fit longest width[no interface to update width :(]
            [loadingView startLoadingWithTitle:@"   道具加载中 0%   " onView:self.viewContainer.rootView closeBlock:^{

            }];

            let progressSignal = [self.downloadSubject progressSignalForEffect:effect];
            [[progressSignal takeUntil:self.rac_willDeallocSignal] subscribeNext:^(NSNumber*  _Nullable x) {

                [loadingView updateProgressTitle:[NSString stringWithFormat:@"道具加载中 %@%%", @((int)(x.floatValue *100))]];
            }];

            let finishSignal = [self.downloadSubject resultSignalForEffect:effect];
            [[finishSignal takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id  _Nullable res) {
                @strongify(self)
                [self.propService rearInsertAtHotTabWithProps:@[effect]];
                [self.recognitionService applyProp:effect propSource:ACCPropSourceRecognition];
                if (self.flowerService.inFlowerPropMode && self.flowerService.currentItem.dType == ACCFlowerEffectTypeRecognition) {
                    [self flowerTrackForGrootPropShow:effect];
                    [self flowerTrackForGrootPropClick:effect];
                    [self trackForFlowerPropDownload:startTime prop:effect error:nil];
                }
                [loadingView stopLoading];
            }];
            [finishSignal subscribeError:^(id  _Nullable x) {
                @strongify(self)
                [ACCToast() showError:@"道具下载失败，请重试"];
                [self trackForFlowerPropDownload:startTime prop:effect error:x];
                [self.recognitionService resetRecognition];
                [loadingView stopLoading];
            }];
            [self.downloadSubject downloadEffect:effect];
        }];

    /// correct real record state
    [[[[RACObserve(self.flowService, currentDuration) throttle:0.1] combineLatestWith:RACObserve(self.cameraService.recorder, recorderState)] takeUntil:self.rac_willDeallocSignal]  subscribeNext:^(RACTwoTuple *x) {
        @strongify(self)
        CGFloat duration = self.flowService.currentDuration;
        ACCCameraRecorderState state = self.cameraService.recorder.recorderState;

        /// duration is 0, means not started
        if (state == ACCCameraRecorderStatePausing && ACC_FLOAT_EQUAL_ZERO(duration)){
            [self.recognitionService updateRecordState:ACCRecognitionRecorderStateNormal];
        }
        else{
            if (![self isCombineMode:self.recordMode] &&
                state == ACCCameraRecorderStatePausing &&
                duration > 0){
                [self.recognitionService updateRecordState:ACCRecognitionRecorderStateFinished];
            }else{
                [self.recognitionService updateRecordState:(ACCRecognitionRecorderState)state];
            }
        }
    }];

    [[RACObserve(self.recognitionService, recordState) takeUntil:self.rac_willDeallocSignal] subscribeNext:^(NSNumber*  _Nullable x) {
        @strongify(self)
        /// cancel recognizing when start record
        if (self.recognitionService.recognitionState == ACCRecognitionStateRecognizing &&
            x.integerValue == ACCCameraRecorderStateRecording){
            [self cancelCurrentRecognizing];
        }
    }];


    __block BOOL showPropHintBubble = [self shouldShowPropHintBubble];
    [[RACObserve(self.recognitionService, recognitionMessage) takeUntil:self.rac_willDeallocSignal] subscribeNext:^(IESMMEffectMessage*  _Nullable x) {
        @strongify(self)
        /// effect is ready
        if (showPropHintBubble && x.arg1 == ACCRecognitionMsgTypeQueryPropInformation){
            /// query prop coordinates
            [self queryPropCoordinates];
        }
        /// click category info prop(dismiss bubble)
        else if (showPropHintBubble && x.arg1 == ACCRecognitionMsgTypeSpeciesPanelNeedShow){
            [AWERecorderTipsAndBubbleManager.shareInstance dismissWithOptions:AWERecoderHintsDismissRecognitionBubble];
        }
        /// recevied category info prop position(top-center)
        else if (showPropHintBubble && x.arg1 == ACCRecognitionMsgTypeReceivePropCoordinates){
            NSDictionary *points = [NSJSONSerialization JSONObjectWithData:[x.arg3 dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:NULL];
            CGFloat x = [points acc_doubleValueForKey:@"x"] ?: 100;
            CGFloat y = [points acc_doubleValueForKey:@"y"] ?: 223;
            [AWERecorderTipsAndBubbleManager.shareInstance showRecognitionPropHintBubble:@"点击切换物种" forView:self.viewContainer.rootView center:CGPointMake(x, y-30) completion:^{
                @strongify(self)
                [self.recognitionService markShowedBubble:ACCRecognitionBubblePropHint];
                /// reload showPropHintBubble
                showPropHintBubble = [self shouldShowPropHintBubble];
            }];
        }
    }];

    [[self.recognitionService.disableRecognitionSignal.distinctUntilChanged takeUntil:self.rac_willDeallocSignal] subscribeNext:^(RACTwoTuple*  _Nullable x) {
        @strongify(self)
        if ([x.first boolValue] && [x.last boolValue]){
            if ([self.propService.prop.panelName isEqualToString:@"recognition"]) {
                //切到k歌，清除智能识别应用的道具
                [self.recognitionService applyProp:nil propSource:ACCPropSourceReset];
            }
            [self forceResetRecognize:YES];
            [AWERecorderTipsAndBubbleManager.shareInstance removeRecognitionBubble:NO];
            [AWERecorderTipsAndBubbleManager.shareInstance removeRecognitionBubble:YES];
        }
    }];

    /// cancel recognizing if any panel showed
    [[RACObserve(self.viewContainer, isShowingPanel) takeUntil:self.rac_willDeallocSignal].deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        if ([x boolValue]){
            [self cancelCurrentRecognizing];
        }
    }];

    /// cancel recognizing if change camera position
    [[RACObserve(self.cameraService.cameraControl, currentCameraPosition) takeUntil:self.rac_willDeallocSignal].deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        if (self.flowerService.inFlowerPropMode) {
            // 春节tab里切换摄像头，不需要取消识别
            return;
        }
        [self cancelCurrentRecognizing];
        [self showCategoryBubbleIfNeeded];
    }];

    [[RACObserve(self.cameraService.cameraControl, status) takeUntil:self.rac_willDeallocSignal].deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self)
        if (x.integerValue == IESMMCameraStatusStopped){
            [self.recognitionService stopAutoScan];
        }else{
            [self showCategoryBubbleIfNeeded];
        }

    }];

   [[self.recognitionService.disableRecognitionSignal takeUntil:self.rac_willDeallocSignal].deliverOnMainThread subscribeNext:^(RACTwoTuple *_Nullable x) {
        @strongify(self)
        if ([x.first boolValue]){
            if ([x.second boolValue]){
                [self forceResetRecognize:YES];
            }else{
                [self cancelCurrentRecognizing];
                [self.recognitionService stopAutoScan];
            }
        }else {
            [self showCategoryBubbleIfNeeded];
            [self.recognitionService recoverRecognitionStateIfNeeded];
        }
    }];
}

- (void)queryPropCoordinates
{
    IESMMEffectMessage *message = [IESMMEffectMessage messageWithType:(IESMMEffectMsg)ACCRecognitionMsgRecognizedSpecies];
//    message.msgId = ;
    message.arg1 = ACCRecognitionMsgTypeQueryPropCoordinates;
    CGRect frame = self.cameraService.cameraPreviewView.camera.previewView.frame;
    NSDictionary *effectFrame = @{@"screen_size":@{
                                      @"width":@(ACC_SCREEN_WIDTH),
                                      @"height":@(ACC_SCREEN_HEIGHT)
                                  },
                                  @"effect_frame":@{
                                      @"x":@(CGRectGetMinX(frame)),
                                      @"y":@(CGRectGetMinY(frame)),
                                      @"width":@(CGRectGetWidth(frame)),
                                      @"height":@(CGRectGetHeight(frame)),
                                  }

    };
    message.arg3 = [effectFrame acc_dictionaryToJson];
    [self.cameraService.message sendMessageToEffect:message];
}

- (ACCRecognitionDownloadSubject *)downloadSubject
{
    if (!_downloadSubject){
        _downloadSubject = [ACCRecognitionDownloadSubject new];
    }
    return _downloadSubject;
}

- (void)automaticallyRecognizing
{
    if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive ||
        self.cameraService.cameraControl.status == IESMMCameraStatusStopped){
        return;
    }
    
    // for optimize,  start autoscan after camera first frame loaded
    if (ACCConfigEnum(kACCConfigInt_tools_camera_smart_recognition_optimize, ACCRecognitionOptimizeType) != ACCRecognitionOptimizeTypeNone &&
        !self.hasFirstFrameLoaded) {
        return;
    }

    @weakify(self)
    [self.recognitionService startAutoScanWithFilter:^BOOL(RACTwoTuple *model) {
        @strongify(self)
        return
        [model.first isEqual:@"Flower"] &&
        [model.last floatValue] > [self.recognitionService thresholdFor:ACCRecognitionThreasholdFlower];
    } completion:^(RACTwoTuple * model, NSError *error) {
        @strongify(self)
        if (error){
            return;
        }

        if (self.recognitionService.isReadyForRecognition){
            [AWERecorderTipsAndBubbleManager.shareInstance showRecognitionBubbleWithInputData:self.inputData forView:self.viewContainer.rootView titleStr:@"检测到花草，长按可识别" contentStr:nil loopTimes:1 showedCallback:^{
                self.showedFlowerBubble = YES;
                [self.recognitionService stopAutoScan];
                [self.recognitionService markShowedBubble:ACCRecognitionBubbleFlower];
            }];
        }

    }];
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber
- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    self.recordMode = mode;
    [self.recognitionService updateRecordMode:mode];

    /// reset recognizing when switch between quick & combine
    if (([self isQuickStoryMode:oldMode] && [self isCombineMode:mode]) ||
        ([self isQuickStoryMode:mode] && [self isCombineMode:oldMode])) {
        [self cancelCurrentRecognizing];
    }
}

- (BOOL)isQuickStoryMode:(ACCRecordMode *)mode
{
    return
    mode.serverMode == ACCServerRecordModeQuick ||
    mode.serverMode == ACCServerRecordModePhoto;
}

- (BOOL)isCombineMode:(ACCRecordMode *)mode
{
    return
    mode.serverMode == ACCServerRecordModeCombine ||
    mode.serverMode == ACCServerRecordModeCombine60 ||
    mode.serverMode == ACCServerRecordModeCombine15 ||
    mode.serverMode == ACCServerRecordModeCombine180;
}


- (void)showCategoryBubbleIfNeeded
{
    if ([self shouldShowCategoryBubble] &&
        self.isPresenting &&
        [ACCRecognitionConfig enableAutoScanForRecogitionOptimize] &&
        self.recognitionService.isReadyForRecognition &&
        !self.recognitionService.disableRecognize &&
        self.cameraService.cameraControl.currentCameraPosition == AVCaptureDevicePositionBack){
        [self automaticallyRecognizing];
    }
}


#pragma mark - ACCKaraokeServiceSubscriber

- (void)karaokeService:(id<ACCKaraokeService>)service didChangeFromRecordMode:(ACCKaraokeRecordMode)oldMode toMode:(ACCKaraokeRecordMode)newMode
{
    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarRecognitionContext];
}

- (void)karaokeService:(id<ACCKaraokeService>)service inKaraokeRecordPageDidChangeFrom:(BOOL)prevState to:(BOOL)state
{
    [self.recognitionService enterDisablePage:state];
}

#pragma mark - ACCFlowerServiceSubscriber

- (void)flowerServiceDidEnterFlowerMode:(id<ACCFlowerService>)service
{
    [self cancelCurrentRecognizing];
}

- (void)flowerServiceDidChangeFromItem:(ACCFlowerPanelEffectModel *)prevItem toItem:(ACCFlowerPanelEffectModel *)item
{
    if (item.dType == ACCFlowerEffectTypeRecognition) {
        self.repository.repoFlowerTrack.isInRecognition = YES;
        if (self.recognitionService.recognitionState == ACCRecognitionStateRecognizing) {
            return;
        }
        if (self.recognitionService.disableRecognize) {
            return;
        }
        [self.cameraService.cameraControl switchToCameraPosition:AVCaptureDevicePositionBack];
        [self.recognitionService captureImagesAndRecognize:kACCRecogEnterMethodFlowerPanelAuto detectMode:kACCRecognitionDetectModeAnimal];
        [self flowerTrackForEnterRecognition];
    } else if (prevItem.dType == ACCFlowerEffectTypeRecognition) {
        self.repository.repoFlowerTrack.isInRecognition = NO;
        [self forceResetRecognize:YES];
        [AWERecorderTipsAndBubbleManager.shareInstance removeBubbleAndHintIfNeeded];
    }
}

- (void)flowerServiceDidOpenTaskPanel:(id<ACCFlowerService>)service
{
    [self cancelCurrentRecognizing];
}

- (void)flowerServiceDidCloseTaskPanel:(id<ACCFlowerService>)service
{
    if (service.currentItem.dType == ACCFlowerEffectTypeRecognition && self.recognitionService.recognitionState != ACCRecognitionStateRecognized) {
        [self.recognitionService captureImagesAndRecognize:kACCRecogEnterMethodFlowerPanelAuto detectMode:kACCRecognitionDetectModeAnimal];
    }
}

#pragma mark - ACCCameraLifeCircleEvent
- (void)onCameraDidStartRender:(id<ACCCameraService>)cameraService
{
    self.hasFirstFrameLoaded = YES;
    [self showCategoryBubbleIfNeeded];
}

#pragma mark - ACCGestureServiceSubscriber
- (void)longPressGestureDidRecognized:(UILongPressGestureRecognizer *)longPress
{
    if (self.recognitionService.disableRecognize ||
        ![ACCRecognitionConfig longPressEntry]){
        return;
    }
    
    // 在春节面板，但没有定位在物体识别道具，禁用长按识别
    if (self.flowerService.inFlowerPropMode && self.flowerService.currentItem.dType != ACCFlowerEffectTypeRecognition) {
        return;
    }

    if (longPress.state != UIGestureRecognizerStateBegan){
        return;
    }

    if (self.recognitionService.recognitionState == ACCRecognitionStateRecognizing){
        return;
    }
    NSString * enterMethod = nil;
    NSSet<NSString *> *detectModes;
    if (self.flowerService.inFlowerPropMode) {
        enterMethod = kACCRecogEnterMethodFlowerPanelLongPress;
        detectModes = [NSSet setWithObject:kACCRecognitionDetectModeAnimal]; // 春节tab里的物体识别，只识别花草+动物
    } else {
        enterMethod = kACCRecogEnterMethodLongPress;
        NSMutableSet<NSString *> * mdetectModes = [NSMutableSet setWithArray:([[ACCRecognitionConfig smartScanDetectModeFromSettings] componentsSeparatedByString:@","] ?: @[])];
        if (ACCConfigBool(kConfigBool_tools_record_support_scan_qr_code)) { // 命中实验，除了支持settings下发的种类，还可以二维码扫描
            [mdetectModes addObject:kACCRecognitionDetectModeQRCode];
        }
        detectModes = [mdetectModes copy];
    }
    NSString *detectModeStr = [detectModes.allObjects componentsJoinedByString:@","];
    [self.recognitionService captureImagesAndRecognize:enterMethod detectMode:detectModeStr];

    if (self.flowerService.inFlowerPropMode) {
        [self flowerTrackForEnterRecognition];
    } else {
        [ACCTracker() trackEvent:@"click_trigger_reality" params:self.trackingParams];
        
        if ([detectModes containsObject:kACCRecognitionDetectModeQRCode]) {
            // 主相机触发qr scan埋点
            [self flowerTrackForEnterQRCodeScan:@"long_press"];
        }
    }
}

- (void)showRecognizingTip:(BOOL)show
{
    acc_dispatch_main_async_safe(^{
        if (show){
            self.recognizingView.tipTitleLabel.text = @"对准目标，识别中...";
            
            self.recognizingView.tipHintLabel.text = self.hintText;

            [self.recognizingView play];

        }else{
            [self.recognizingView stop];
        }
    });
}

- (NSString *)hintText
{
    if (self.flowerService.inFlowerPropMode) {
        return @"试试对准花草树木";
    }
    
    if ([ACCRecognitionConfig supportScene]){
        if ([ACCRecognitionConfig supportCategory]){
            NSString *animalTip = [ACCRecognitionConfig supportAnimal]? @"/动物" :@"";
            return [@"试试对准天空/地面/花草" stringByAppendingString:animalTip];
        }else{
            return @"试试对准天空/地面/室外";
        }
    }

    return @"";
}

- (ACCRecordViewControllerInputData *)inputData
{
    return [[self getViewModel:ACCRecorderViewModel.class] inputData];
}

#pragma mark - private methods

- (void)showRetryBubble
{
    if (self.flowerService.inFlowerPropMode) {
        [AWERecorderTipsAndBubbleManager.shareInstance showRecognitionBubbleWithInputData:self.inputData forView:self.viewContainer.rootView titleStr:@"对准植物，长按识别" contentStr:@"再靠近一些，识别更准确" loopTimes:10 showedCallback:^{
        }];
    } else {
        NSString *title = ACCRecognitionConfig.supportScene? @"未识别到内容，试试热门道具" : @"未识别到内容";
        NSString *hint = [ACCRecognitionConfig longPressEntry]?@"长按可重新识别":@"";

        [AWERecorderTipsAndBubbleManager.shareInstance showRecognitionBubbleForView:self.viewContainer.rootView bubbleTitle:title bubbleTipHint:hint completion:^{
        }];
    }
}

- (void)showPrivacyTip{
    [self.viewContainer.rootView addSubview:self.recognizePrivacyView];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.recognizePrivacyView removeFromSuperview];
        self.recognizePrivacyView = nil;
    });
    [self.recognitionService markShowedBubble:ACCRecognitionBubblePrivacy];
}

/// should show longpress leading bubble
- (BOOL)shouldShowRecognitionBubble
{
    /// bar item bubble first
    if ([ACCRecognitionConfig barItemEntry] &&
        [self.recognitionService shouldShowBubble:ACCRecognitionBubbleRightItem]){
        return NO;
    }
    return [ACCRecognitionConfig longPressEntry] && [self.recognitionService shouldShowBubble:ACCRecognitionBubbleLongPress];
}

- (BOOL)shouldShowCategoryBubble
{
    return
    !self.showedFlowerBubble &&
    [ACCRecognitionConfig supportCategory] &&  /// category recognition function is supported
    [self.recognitionService shouldShowBubble:ACCRecognitionBubbleFlower];
}

- (BOOL)shouldShowPropHintBubble
{
    return [self.recognitionService shouldShowBubble:ACCRecognitionBubblePropHint];
}

- (BOOL)shouldShowPrivacyTip
{
    return [self.recognitionService shouldShowBubble:ACCRecognitionBubblePrivacy];
}

// flower track

- (void)flowerTrackForGrootPropShow:(IESEffectModel *)prop
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"record_mode"] = @"sf_2022_activity_camera";
    params[@"enter_from"] = @"video_shoot_page";
    params[@"enter_method"] = @"video_shoot_page";
    params[@"prop_id"] = prop.effectIdentifier;
    params[@"reality_id"] = self.recognitionService.trackModel.realityId ?: @"";
    params[@"shoot_way"] = self.repository.repoTrack.referString ?: @"direct_shoot";
    params[@"creation_id"] = self.repository.repoContext.createId ?: @"";
    params[@"content_type"] = @"reality";
    params[@"prop_selected_from"] = @"flower";
    params[@"activity_id"] = ACCConfigString(kConfigString_tools_flower_activity_id);
    params[@"act_id"] = [ACCFlowerCampaignManager() activityHashString];
    // flower通用参数
    params[@"params_for_special"] = @"flower";
    [ACCTracker() trackEvent:@"prop_show" params:params];
}

- (void)flowerTrackForGrootPropClick:(IESEffectModel *)prop
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"record_mode"] = @"sf_2022_activity_camera";
    params[@"enter_method"] = @"video_shoot_page";
    params[@"enter_from"] = @"video_shoot_page";
    params[@"prop_id"] = prop.effectIdentifier;
    params[@"shoot_way"] = self.repository.repoTrack.referString ?: @"direct_shoot";
    params[@"creation_id"] = self.repository.repoContext.createId ?: @"";
    params[@"content_type"] = @"reality";
    params[@"content_source"] = @"shoot";
    params[@"activity_id"] = ACCConfigString(kConfigString_tools_flower_activity_id);
    params[@"act_id"] = [ACCFlowerCampaignManager() activityHashString];
    // flower通用参数
    params[@"params_for_special"] = @"flower";
    [ACCTracker() trackEvent:@"prop_click" params:params];
}

- (void)flowerTrackForEnterRecognition
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.trackingParams];
    params[@"enter_from"] = @"video_shoot_page";
    params[@"record_mode"] = @"sf_2022_activity_camera";
    params[@"enter_method"] = [self.repository.repoFlowerTrack lastChooseMethod] ?: @"sf_2022_activity_camera";
    params[@"shoot_way"] = self.repository.repoTrack.referString ?: @"direct_shoot";
    params[@"content_type"] = @"reality";
    params[@"creation_id"] = self.repository.repoContext.createId ?: @"";
    params[@"reality_id"] = self.recognitionService.trackModel.realityId ?: @"";
    // flower通用参数
    params[@"params_for_special"] = @"flower";
    [ACCTracker() trackEvent:@"click_trigger_reality" params:params];
}

- (void)flowerTrackForEnterQRCodeScan:(NSString *)enterMethod
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"enter_from"] = @"video_shoot_page";
    params[@"enter_method"] = enterMethod ?: @"long_press";
    params[@"activity_id"] = ACCConfigString(kConfigString_tools_flower_activity_id);
    params[@"act_id"] = [ACCFlowerCampaignManager() activityHashString];
    // flower通用参数
    params[@"params_for_special"] = @"flower";
    [ACCTracker() trackEvent:@"qr_code_scan_enter" params:params];
}

- (void)flowerTrackForEnterProfile:(NSString *)enterFrom userID:(NSString *)userID
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"enter_from"] = enterFrom;
    params[@"enter_method"] = @"scan_cam";
    params[@"user_id"] = userID;
    // flower通用参数
    params[@"params_for_special"] = @"flower";
    [ACCTracker() trackEvent:@"sf_2022_camera_scan_enter_personal_detail" params:params];
}

// monitor
- (void)trackForFlowerPropDownload:(CFTimeInterval)startTime prop:(IESEffectModel *)prop error:(NSError * __nullable)error
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (error) {
        params[@"error_code"] = @(error.code);
        params[@"error_msg"] = error.description ?: @"";
    } else {
        params[@"duration"] = @((CFAbsoluteTimeGetCurrent() - startTime) * 1000);
    }
    // 1npc道具，2春节横滑道具，3扫一扫道具，4物种识别道具，5拍照道具
    params[@"flower_sticker_type"] = @(4);
    params[@"sticker_id"] = prop.effectIdentifier ?: @"";
    [ACCMonitor() trackService:@"flower_sticker_download_error_rate"
                        status:error ? 1 : 0
                         extra:params];
}

#pragma mark - getter

- (AWERecognitionLoadingView *)recognizingView
{
    if (!_recognizingView){
        _recognizingView = [[AWERecognitionLoadingView alloc] initWithFrame:CGRectMake(0, 0, 270, 65+300)];
        [[self.viewContainer rootView] addSubview:_recognizingView];

        ACCMasMaker(_recognizingView, {
            make.centerX.equalTo(self.viewContainer.rootView);
            make.centerY.equalTo(self.viewContainer.rootView).multipliedBy(0.85);
            make.size.mas_equalTo(CGSizeMake(270, 65+300));
        });

    }
    return _recognizingView;
}

- (UILabel *)recognizePrivacyView {

    if (_recognizePrivacyView) return _recognizePrivacyView;

    UILabel *recognizePrivacyView = [UILabel new];
    recognizePrivacyView.textColor =[UIColor.whiteColor colorWithAlphaComponent:0.75];
    recognizePrivacyView.textAlignment = NSTextAlignmentCenter;
    recognizePrivacyView.font = [UIFont systemFontOfSize:12];
    recognizePrivacyView.numberOfLines = 3;
    recognizePrivacyView.text = @"识别功能需要上传拍摄的图像至云端处理，处理完成后不会存储";
    CGSize size = CGSizeMake(self.viewContainer.rootView.acc_width-140, 100);
    size = [recognizePrivacyView sizeThatFits:size];
    recognizePrivacyView.acc_size = size;
    CGFloat safeAreaBottom = 0;
    if (@available(iOS 11.0, *)) {
        safeAreaBottom = [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom;
    }
    recognizePrivacyView.center = CGPointMake(self.viewContainer.rootView.acc_width/2, self.viewContainer.rootView.acc_height - 255 - safeAreaBottom);

    return _recognizePrivacyView = recognizePrivacyView;
}

- (void)trackRecognitionResult:(ACCRecognitionState)state{
    if ([ACCRecognitionConfig supportScene] &&
        (state == ACCRecognitionStateRecognized ||
        state == ACCRecognitionStateRecognizeFailed)){
        NSMutableDictionary *params = [self.trackingParams mutableCopy];
        [params addEntriesFromDictionary:@{
            @"is_success": @(state == ACCRecognitionStateRecognized),
            @"enter_method": self.recognitionService.trackModel.enterMethod ?: @"",
            @"duration": @(self.recognitionService.trackModel.duration),
        }];

        /// realityType is special, it's nil when failed, make sure there is no empty string in params.
        [params setValue:self.recognitionService.trackModel.realityType forKey:@"reality_type"];

        if (self.flowerService.inFlowerPropMode) {
            params[@"enter_from"] = @"video_shoot_page";
            params[@"record_mode"] = @"sf_2022_activity_camera";
            params[@"enter_method"] = [self.repository.repoFlowerTrack lastChooseMethod] ?: @"sf_2022_activity_camera";
            params[@"shoot_way"] = self.repository.repoTrack.referString ?: @"direct_shoot";
            params[@"content_type"] = @"reality";
            params[@"creation_id"] = self.repository.repoContext.createId ?: @"";
            params[@"reality_id"] = self.recognitionService.trackModel.realityId ?: @"";
            [params setValue:self.recognitionService.trackModel.realityType forKey:@"reality_type"];
            params[@"is_success"] = @(state == ACCRecognitionStateRecognized);
            // flower通用参数
            params[@"params_for_special"] = @"flower";
            [ACCTracker() trackEvent:@"reality_result_show" params:params];
        } else {
            [ACCTracker() trackEvent:@"reality_result_show" params:params];
        }
    }
}

- (NSDictionary *)trackingParams
{

    AWERepoContextModel *contextModel = [self.inputData.publishModel extensionModelOfClass:AWERepoContextModel.class];
    AWERepoTrackModel *trackModel = [self.inputData.publishModel extensionModelOfClass:AWERepoTrackModel.class];

    return @{
        @"enter_method": @"long_press",
        @"content_type": @"reality",
        @"shoot_way": trackModel.referString?: @"",
        @"creation_id":[contextModel createId] ?: @"",
        @"record_mode": trackModel.tabName ?: @"",
        @"enter_from": @"video_shoot_page",
        @"reality_id": self.recognitionService.trackModel.realityId ?: @"",
    };
}

- (void)propServiceWillApplyProp:(IESEffectModel *)prop propSource:(ACCPropSource)propSource
{
    prop.propSelectedFrom = self.recognitionService.trackModel.realityType;
}

@end
