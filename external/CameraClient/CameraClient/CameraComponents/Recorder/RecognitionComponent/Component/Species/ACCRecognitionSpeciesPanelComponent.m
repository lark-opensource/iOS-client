//
//  ACCRecognitionSpeciesPanelComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/17.
//

#import "ACCRecognitionSpeciesPanelComponent.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/ACCDeviceAuth.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <ReactiveObjC/ReactiveObjC.h>

#import "ACCRecognitionService.h"
#import "ACCFlowerService.h"
#import "ACCRecorderStickerServiceProtocol.h"
#import "ACCRecognitionSpeciesPannelView.h"
#import "ACCRecognitionSpeciesPanelViewModel.h"
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreativeKit/ACCMacros.h>
#import <TTVideoEditor/IESMMEffectMessage.h>
#import <TTVideoEditor/VERecorderPublicProtocol.h>
#import <SmartScan/SSRecommendData.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CameraClient/ACCRecordPropService.h>
#import <CameraClient/ACCRecordGestureService.h>
#import <CameraClient/AWEXScreenAdaptManager.h>
#import <CameraClient/AWECameraPreviewContainerView.h>
#import <CameraClient/ACCRecognitionConfig.h>

#import <CameraClient/ACCGrootStickerModel.h>
#import <CameraClient/ACCRecognitionTrackModel.h>
#import <CameraClient/AWERepoStickerModel.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>

@interface ACCRecognitionSpeciesPanelComponent ()<ACCEffectEvent, ACCRecordSwitchModeServiceSubscriber>

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCRecordGestureService> gestureService;
@property (nonatomic, strong) id<ACCRecognitionService> recognitionService;
@property (nonatomic, strong) id<ACCRecordPropService> propService;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) ACCRecognitionSpeciesPannelView *panelView;
@property (nonatomic, strong) ACCRecognitionSpeciesPanelViewModel *viewModel;
@property (nonatomic, weak  ) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, weak) id<ACCFlowerService> flowerService;

@end

@implementation ACCRecognitionSpeciesPanelComponent

IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, propService, ACCRecordPropService)
IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, gestureService, ACCRecordGestureService)
IESAutoInject(self.serviceProvider, recognitionService, ACCRecognitionService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, flowerService, ACCFlowerService)

#pragma mark - ACCComponentProtocol

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.cameraService.message addSubscriber:self]; // ACCEffectEvent
    [self.switchModeService addSubscriber:self];
}

#pragma mark - Component Lifecycle

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)dealloc
{

}

- (void)componentDidMount
{
    [self bindViewModel];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)receiveDidBecomeActive:(NSNotification *)notification
{
    [self sendCurrentSelectSpeciesInfoMessage];
}

#pragma mark - Private Methods
- (void)bindViewModel
{
    @weakify(self);
    [[[self.recognitionService.recognitionResultSignal takeUntil:[self rac_willDeallocSignal]] deliverOnMainThread] subscribeNext:^(RACTwoTuple<SSRecommendResult *,NSString *> * _Nullable x) {
        @strongify(self);
        if (self.recognitionService.detectResult == ACCRecognitionDetectResultSmartScan) {
            [self.viewModel updateRecommendResult:x.first];
        }
    }];

    [[[RACObserve(self.recognitionService, recognitionState) takeUntil:[self rac_willDeallocSignal]] deliverOnMainThread] subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        if (self.recognitionService.detectResult == ACCRecognitionDetectResultQRCode) {
            [self setupGrootModelResult:NO];
            return;
        }
        ACCRecognitionState state = x.integerValue;
        if (state == ACCRecognitionStateNormal){
            [self setupGrootModelResult:NO];
        }
        else if (state == ACCRecognitionStateRecognized && self.switchModeService.currentRecordMode.isPhoto){
            [self setupGrootModelResult:YES];
        }
    }];
    
    [[[self.viewModel.closePanelSignal takeUntil:[self rac_willDeallocSignal]] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self hidePanelWithCompletion:nil];
    }];
    
    [[[self.viewModel.selectItemSignal takeUntil:[self rac_willDeallocSignal]] deliverOnMainThread] subscribeNext:^(RACThreeTuple<SSRecognizeResult *, NSNumber *, NSNumber *> * _Nullable x) {
        @strongify(self);
        [self sendSelectSpeciesMessage:x.first];
        self.recognitionService.trackModel.speciesIndex = x.second.integerValue;
        [self hidePanelWithCompletion:^(BOOL result) {
            @strongify(self);
            [self resetDefaultSelectionIndex:[x.second integerValue]];
        }];
    }];

    [[self.viewModel.checkGrootSignal takeUntil:[self rac_willDeallocSignal]] subscribeNext:^(NSNumber * x){
        @strongify(self);
        [self setupGrootModelResult:YES];
    }];
    
    [RACObserve(self.cameraService.recorder, recorderState).deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        if ([self isRecognitionProps]) {
            ACCCameraRecorderState state = x.integerValue;
            if (state == ACCCameraRecorderStateRecording) {
                self.gestureService.sdkGesturesAction = ACCRecordGestureActionDisable;
            } else {
                self.gestureService.sdkGesturesAction = ACCRecordGestureActionRecover;
            }
        }

        if (x.integerValue == ACCCameraRecorderStateRecording){
            [self setupGrootModelResult:[self isRecognitionProps]];
        }
    }];
}

- (void)setupGrootModelResult:(BOOL)setup
{
    if (!ACCConfigBool(kConfigBool_sticker_support_groot)){
        return;
    }
    NSInteger index = self.recognitionService.trackModel.speciesIndex;
    if (!setup || index < 0 || index >= self.viewModel.recognizeResultData.imageTags.count){
        self.repository.repoSticker.grootModelResult = nil;
        self.repository.repoSticker.recorderGrootModelResult = nil;
        return;
    }

    let grootStickerModel = [self transform:self.viewModel.recognizeResultData selectedIndex:index];
    grootStickerModel.hasGroot = @(grootStickerModel.grootDetailStickerModels.count > 0);


    let selectedModelDict = [MTLJSONAdapter JSONDictionaryFromModel:grootStickerModel.selectedGrootStickerModel error:nil];
    self.recognitionService.trackModel.grootModel.stickerModel.userGrootInfo = selectedModelDict;

    grootStickerModel.userGrootInfo = selectedModelDict;
    grootStickerModel.fromRecord = YES;

    NSString *result = [grootStickerModel draftDataJsonString];

    self.repository.repoSticker.grootModelResult = self.repository.repoSticker.recorderGrootModelResult = [ACCGrootStickerModel grootModelResultFilterWithString:result];
}

- (ACCGrootStickerModel *)transform:(SSImageTags *)tags selectedIndex:(NSInteger)index
{
    ACCGrootStickerModel *model = [[ACCGrootStickerModel alloc] initWithEffectIdentifier:@"1148586"];
    model.allowGrootResearch = self.viewModel.allowResearch;
    model.hasGroot = @(YES);
    model.grootDetailStickerModels = [tags.imageTags btd_map:^id _Nullable(SSRecognizeResult * _Nonnull obj) {
        ACCGrootDetailsStickerModel *model = [ACCGrootDetailsStickerModel new];
        model.baikeId = @(obj.wikiID.integerValue);
        model.baikeHeadImage = obj.imageLinks.firstObject;
        model.speciesName = obj.chnName;
        model.commonName = obj.aliasName;
        model.categoryName = obj.clsSys;
        model.prob = @(obj.score);
        model.baikeIcon = obj.icon;
        return model;
    }];
    model.selectedGrootStickerModel = model.grootDetailStickerModels[index];

    return model;
}

- (BOOL)isRecognitionProps
{
  NSString *propID = self.propService.prop.effectIdentifier;
  NSString *stickerID = self.viewModel.recognizeResultData.stickerID;
  NSString *originalPropID = self.propService.prop.originalEffectID;
  return [stickerID isEqual:propID] || [stickerID isEqual:originalPropID];
}

- (void)sendPanelExposureMessage
{
    IESMMEffectMsg msg = (IESMMEffectMsg)(ACCRecognitionMsgRecognizedSpecies);
    IESMMEffectMessage *message = [IESMMEffectMessage messageWithType:msg];
    message.arg1 = ACCRecognitionMsgTypeSpeciesPanelDidShow;
    [self.cameraService.message sendMessageToEffect:message];
}

- (void)sendPanelDismissMessage
{
    IESMMEffectMsg msg = (IESMMEffectMsg)(ACCRecognitionMsgRecognizedSpecies);
    IESMMEffectMessage *message = [IESMMEffectMessage messageWithType:msg];
    message.arg1 = ACCRecognitionMsgTypeSpeciesPanelDidHide;
    [self.cameraService.message sendMessageToEffect:message];
}

- (void)sendLimitOperationScopeMessage
{
    CGFloat topOffset = ACC_STATUS_BAR_NORMAL_HEIGHT + 48;
    CGFloat bottomOffset = 226;
    if (@available(iOS 11.0,*)) {
        if ([AWEXScreenAdaptManager needAdaptScreen]) {
            topOffset = ACC_STATUS_BAR_NORMAL_HEIGHT + 64;
            bottomOffset = ACC_IPHONE_X_BOTTOM_OFFSET + 173 + 26;
            if ([UIDevice acc_isIPhoneXsMax]) {
                bottomOffset = ACC_IPHONE_X_BOTTOM_OFFSET + 185 + 26;
            }
        }
    }
    
    CGRect frame = self.cameraService.cameraPreviewView.camera.previewView.frame;
    NSDictionary *insets = @{@"top":@(topOffset), @"left":@(14.5),
                             @"bottom":@(bottomOffset), @"right":@56};
    NSDictionary *screenSize = @{@"width":@(ACC_SCREEN_WIDTH), @"height":@(ACC_SCREEN_HEIGHT)};
    NSDictionary *effectFrame = @{@"x":@(CGRectGetMinX(frame)),
                                  @"y":@(CGRectGetMinY(frame)),
                                  @"width":@(CGRectGetWidth(frame)),
                                  @"height":@(CGRectGetHeight(frame))};
    NSDictionary *dict = @{@"insets":insets,
                           @"screen_size":screenSize,
                           @"effect_frame":effectFrame};
    
    IESMMEffectMsg msg = (IESMMEffectMsg)(ACCRecognitionMsgRecognizedSpecies);
    IESMMEffectMessage *message = [IESMMEffectMessage messageWithType:msg];
    message.arg1 = ACCRecognitionMsgTypeLimitOperationScope;
    message.arg3 = [dict acc_dictionaryToJson];
    [self.cameraService.message sendMessageToEffect:message];
}

- (void)sendCurrentSelectSpeciesInfoMessage
{
    id item = [self.viewModel itemAtIndex:self.panelView.currentSelectedIndex];
    if (item) {
        [self sendSelectSpeciesMessage:item];
    }
}

- (void)sendSelectSpeciesMessage:(SSRecognizeResult *)species
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:species.clsSys ? : @"" forKey:@"des1"];
    [dict setValue:species.chnName ? : @"" forKey:@"name"];
    [dict setValue:species.aliasName ? : @"" forKey:@"des2"];
    
    IESMMEffectMsg msg = (IESMMEffectMsg)(ACCRecognitionMsgRecognizedSpecies);
    IESMMEffectMessage *message = [IESMMEffectMessage messageWithType:msg];
    message.arg1 = ACCRecognitionMsgTypeSendPropInformation;
    message.arg3 = [dict acc_dictionaryToJson];
    
    [self.cameraService.message sendMessageToEffect:message];
}

- (void)resetDefaultSelectionIndex:(NSUInteger)index
{
    [self.panelView resetDefaultSelectionIndex:index];
}

#pragma mark - ACCEffectEvent
- (void)onEffectMessageReceived:(IESMMEffectMessage *)message
{
    if (self.cameraService.recorder.recorderState == ACCCameraRecorderStateRecording) {
        return;
    }
    
    if (message.msgId == ACCRecognitionMsgRecognizedSpecies) {
        ACCRecognitionMsgType type = (ACCRecognitionMsgType)message.arg1;
        switch (type) {
            case ACCRecognitionMsgTypeSpeciesPanelNeedShow: {
                if (self.flowerService.inFlowerPropMode) {
                    [self.viewModel flowerTrackForClickChangeSpecies];
                } else {
                    [self.viewModel trackClickChangeSpecies:NO];
                }
                [self showPanelIfNeeded];
                break;
            }
            case ACCRecognitionMsgTypeQueryPropInformation: {
                [self sendCurrentSelectSpeciesInfoMessage];
                [self sendLimitOperationScopeMessage];
                break;
            }
            case ACCRecognitionMsgTypeDragStateDidChanged: {
                NSInteger dragState = message.arg2;
                if (dragState == 0) {        // 开始拖动
                    [self startDraggingProps];
                } else { // dragState == 1，停止拖动
                    [self endDraggingProps];
                }
                break;
            }
            default:
                break;
        }
        [self.recognitionService updateMessage:message];
    }
}

#pragma mark - UI
- (void)endDraggingProps
{
    if (self.viewModel.isNeedRedisplay) {
        self.viewModel.isNeedRedisplay = NO;
        [self showPanelIfNeeded];
    } else {
        [self.viewContainer showItems:YES animated:YES];
        [self.recognitionService askingHideSwithModeView:YES];
    }
}

- (void)startDraggingProps
{
    if (self.viewModel.isShowingPanel) {
        self.viewModel.isNeedRedisplay = YES;
        [self showPanelView:NO animated:YES onCompletion:nil];
    }
    [self.viewContainer showItems:NO animated:YES];
}

- (void)showPanelIfNeeded
{
    if ([self canShowSpeciesPanel]) {
        self.recognitionService.trackModel.isClickByGroot = NO;
        [self setupExposePanelViewIfNeeded];
        [self.panelView resetSelectionAsDefault];
        [self showPanelView:YES animated:YES onCompletion:nil];
        [self.viewContainer showItems:NO animated:YES];
    }
}

- (void)hidePanelWithCompletion:(void (^)(BOOL result))completion
{
    [self showPanelView:NO animated:YES onCompletion:completion];
    [self.viewContainer showItems:YES animated:YES];

    if (![ACCRecognitionConfig onlySupportCategory]){
        [self.recognitionService askingHideSwithModeView:YES];
    }
}

- (void)showPanelView:(BOOL)show animated:(BOOL)animated onCompletion:(void (^)(BOOL result))completion
{
    if (self.viewModel.isShowingPanel == show && self.panelView.hidden == !show) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    if (!animated) {
        self.panelView.hidden = !show;
        if (completion) {
            completion(YES);
        }
    } else {
        if (show) {
            [self.panelView acc_fadeShowWithCompletion:^{
                if (completion) {
                    completion(YES);
                }
            }];
        } else {
            [self.panelView acc_fadeHiddenWithCompletion:^{
                if (completion) {
                    completion(YES);
                }
            }];
        }
    }
    self.viewModel.isShowingPanel = show;
    
    if (show) {
        [self sendPanelExposureMessage];
    } else {
        [self sendPanelDismissMessage];
    }
}

- (void)setupExposePanelViewIfNeeded
{
    if (!_panelView) {
        _panelView = [[ACCRecognitionSpeciesPannelView alloc] init];
        _panelView.alpha = 0;
        _panelView.panelViewModel = self.viewModel;
        @weakify(self);
        _panelView.closePanelCallback = ^{
            @strongify(self);
            [self hidePanelWithCompletion:nil];
        };
        _panelView.frame = self.viewContainer.rootView.bounds;
        [self.viewContainer.rootView addSubview:_panelView];
    }
}

- (BOOL)canShowSpeciesPanel
{
    return ([ACCDeviceAuth isCameraAuth] && [ACCDeviceAuth isMicroPhoneAuth] && [self.viewModel canShowSpeciesPanel]);
}

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    if (mode.isPhoto){
        [self setupGrootModelResult:[self isRecognitionProps]];
    }else{
        [self setupGrootModelResult:NO];
    }
}

#pragma mark - Getter
- (ACCRecognitionSpeciesPanelViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self getViewModel:[ACCRecognitionSpeciesPanelViewModel class]];
    }
    return _viewModel;
}

@end
