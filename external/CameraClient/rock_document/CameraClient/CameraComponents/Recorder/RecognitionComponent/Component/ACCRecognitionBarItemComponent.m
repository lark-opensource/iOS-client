//
//  ACCRecognitionComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by yanjianbo on 2021/06/01.
//  Copyright © 2021年 bytedance. All rights reserved
//

#import "ACCRecognitionBarItemComponent.h"
#import <CameraClient/AWERepoTrackModel.h>
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import <CreationKitArch/AWECameraContainerToolButtonWrapView.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitArch/ACCRecorderToolBarDefines.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CameraClient/AWERecognitionModeSwitchButton.h>
#import <CameraClient/ACCBarItem+Adapter.h>
#import <CreationKitArch/ACCRecordTrackService.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <ReactiveObjC/ReactiveObjC.h>
#import <CreationKitInfra/UILabel+ACCAdditions.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import "ACCRecognitionService.h"
#import <CameraClient/AWERecorderTipsAndBubbleManager.h>
#import <CreationKitArch/ACCRecorderViewModel.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CameraClient/ACCRecognitionConfig.h>
#import <CameraClient/AWERepoContextModel.h>
#import <CameraClient/ACCRecognitionTrackModel.h>
#import "ACCFlowerService.h"

@interface ACCRecognitionBarItemComponent () <ACCCameraLifeCircleEvent, ACCRecordSwitchModeServiceSubscriber, ACCFlowerServiceSubscriber>

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordTrackService> trackService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCRecognitionService> recognitionService;
@property (nonatomic, weak) id<ACCFlowerService> flowerService;

@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, strong) AWERecognitionModeSwitchButton *recogitionButton;
@property (nonatomic, strong) UILabel *recognitionButtonLabel;

@end

@implementation ACCRecognitionBarItemComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, trackService, ACCRecordTrackService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, recognitionService, ACCRecognitionService)

#pragma mark - ACCComponentProtocol

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.cameraService addSubscriber:self];
    [self.cameraService.cameraControl addSubscriber:self];
    [self.cameraService.message addSubscriber:self];
    [self.switchModeService addSubscriber:self];
    self.flowerService = IESAutoInline(serviceProvider, ACCFlowerService);
    [self.flowerService addSubscriber:self];
}

#pragma mark - ACCFeatureComponent

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)loadComponentView
{
    [self configRecognitionBarItem];
}

- (void)componentDidMount
{
    self.isFirstAppear = YES;
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    
}

#define let const __auto_type

- (void)componentDidAppear
{
    if (self.isFirstAppear) {
        self.isFirstAppear = NO;
        [self p_bindViewModelObserver];

    }
}

- (void)showBublleIfNeeded
{
    if ([self shouldShowRecognitionItemBubble]){
        let barItem = [self.viewContainer.barItemContainer viewWithBarItemID:ACCRecorderToolBarRecognitionContext];

        /// baritems may changed at begining
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [AWERecorderTipsAndBubbleManager.shareInstance showRecognitionItemBubbleWithInputData:self.inputData forView:barItem.barItemButton bubbleStr:@"点击开启识别" showedCallback:^{
                NSMutableDictionary *mDict = self.trackingParams.mutableCopy;
                [mDict setValue:@"click_icon" forKey:@"popup_type"];
                [ACCTracker() trackEvent:@"reality_popup_show" params:mDict];
                [self.recognitionService markShowedBubble:ACCRecognitionBubbleRightItem];
            }];
        });
    }
}

#pragma mark - set UI

- (void)configRecognitionBarItem
{

    let config = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCRecorderToolBarRecognitionContext];

    if (config) {
        AWECameraContainerToolButtonWrapView *recognitionCustomView = [[AWECameraContainerToolButtonWrapView alloc] initWithButton:self.recogitionButton label:self.recognitionButtonLabel itemID:ACCRecorderToolBarRecognitionContext];
        ACCBarItem *recongnitionBarItem = [[ACCBarItem alloc] initWithCustomView:recognitionCustomView itemId:ACCRecorderToolBarRecognitionContext];
        @weakify(self);
        recongnitionBarItem.needShowBlock = ^BOOL{
            @strongify(self);
            return !self.recognitionService.disableRecognize && !self.flowerService.inFlowerPropMode;
        };
        [recongnitionBarItem setShowBubbleBlock:^{
            @strongify(self);
            [self showBublleIfNeeded];
        }];
        [self.viewContainer.barItemContainer addBarItem:recongnitionBarItem];
        self.recogitionButton.isAccessibilityElement = YES;
        self.recogitionButton.accessibilityTraits = UIAccessibilityTraitButton;
        self.recogitionButton.accessibilityLabel = [NSString stringWithFormat:@"%@%@", self.recognitionButtonLabel.text, self.recogitionButton.isOn ? @"已开启":@"已关闭"];
    }
}

- (ACCRecordViewControllerInputData *)inputData
{
    return [[self getViewModel:ACCRecorderViewModel.class] inputData];
}

/// should show bar item leading bubble
- (BOOL)shouldShowRecognitionItemBubble
{
    return [self.recognitionService shouldShowBubble:ACCRecognitionBubbleRightItem];
}

#pragma mark - init methods

- (void)p_bindViewModelObserver
{
    @weakify(self);
    [[[self.recognitionService.disableRecognitionSignal takeUntil:self.rac_willDeallocSignal] deliverOnMainThread] subscribeNext:^(RACTwoTuple*  _Nullable x) {
        @strongify(self);
        if (!self.cameraService.cameraHasInit) {
            return;
        }
        [self updateRecognitionButton];
    }];

    [[[[RACObserve(self.recognitionService, recognitionState) distinctUntilChanged] takeUntil:self.rac_willDeallocSignal] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        self.recogitionButton.isOn = ![self.recognitionService isReadyForRecognition];
    }];

    [[[[[RACObserve(self.cameraService.cameraControl, currentCameraPosition) skip:1] takeUntil:self.rac_willDeallocSignal] deliverOnMainThread] distinctUntilChanged] subscribeNext:^(id  _Nullable x) {
        [AWERecorderTipsAndBubbleManager.shareInstance removeRecognitionBubble:NO];
    }];

}

#pragma mark - ACCCameraLifeCircleEvent
- (void)onCreateCameraCompleteWithCamera:(id<ACCCameraService>)cameraService
{
    [self updateRecognitionButton];
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    [self updateRecognitionButton];
}

#pragma mark - ACCFlowerServiceSubscriber

- (void)flowerServiceDidEnterFlowerMode:(id<ACCFlowerService>)service
{
    [self updateRecognitionButton];
}

- (void)flowerServiceDidLeaveFlowerMode:(id<ACCFlowerService>)service
{
    [self updateRecognitionButton];
}

#pragma mark - private methods

- (void)updateRecognitionButton
{
    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarRecognitionContext];
}


#pragma mark - call back methods

- (void)clickRecognitionButton:(AWERecognitionModeSwitchButton *)sender
{
    if (!self.isMounted) {
        return;
    }

    [sender toggle];

    if (sender.isOn){
        NSMutableSet<NSString *> * detectModes = [NSMutableSet setWithArray:([[ACCRecognitionConfig smartScanDetectModeFromSettings] componentsSeparatedByString:@","] ?: @[])];
        if (ACCConfigBool(kConfigBool_tools_record_support_scan_qr_code)) { // 命中实验，除了支持settings下发的种类，还可以二维码扫描
            [detectModes addObject:kACCRecognitionDetectModeQRCode];
        }
        NSString *detectMode = [detectModes.allObjects componentsJoinedByString:@","];
        [self.recognitionService captureImagesAndRecognize:@"icon_click" detectMode:detectMode];
        [ACCTracker() trackEvent:@"click_trigger_reality"
                          params:self.trackingParams];
    }else{
        [ACCTracker() trackEvent:@"close_trigger_reality"
                          params:self.trackingParams];

        [self.recognitionService resetRecognition];
    }

    self.recogitionButton.accessibilityLabel = [NSString stringWithFormat:@"%@%@", self.recognitionButtonLabel.text, self.recogitionButton.isOn ? @"已开启":@"已关闭"];

}

#pragma mark - getter

- (UILabel *)recognitionButtonLabel
{
    if (!_recognitionButtonLabel) {
        NSString *key = [ACCRecognitionConfig onlySupportCategory] ? @"花草识别":@"识别";
        
        _recognitionButtonLabel = [self p_createButtonLabel: ACCLocalizedCurrentString(key)];
    }
    return _recognitionButtonLabel;
}

- (UILabel *)p_createButtonLabel:(NSString *)text
{
    UILabel *label = [[UILabel alloc] acc_initWithFontSize:10 isBold:YES textColor:ACCResourceColor(ACCUIColorConstTextInverse) text:text];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 2;
    [label acc_addShadowWithShadowColor:ACCResourceColor(ACCUIColorConstLinePrimary) shadowOffset:CGSizeMake(0, 1) shadowRadius:2];
    label.isAccessibilityElement = NO;
    return label;
}

- (AWERecognitionModeSwitchButton *)recogitionButton
{
    if (!_recogitionButton) {
        _recogitionButton = [[AWERecognitionModeSwitchButton alloc] initWithType:ACCAnimatedButtonTypeScale];
            [_recogitionButton addTarget:self action:@selector(clickRecognitionButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _recogitionButton;
}

- (NSDictionary *)trackingParams
{

    AWERepoContextModel *contextModel = [self.inputData.publishModel extensionModelOfClass:AWERepoContextModel.class];
    AWERepoTrackModel *trackModel = [self.inputData.publishModel extensionModelOfClass:AWERepoTrackModel.class];
    
    return @{
        @"enter_method": @"click_icon",
        @"content_type": @"reality",
        @"shoot_way": trackModel.referString?: @"",
        @"creation_id":[contextModel createId] ?: @"",
        @"record_mode": trackModel.tabName ?: @"",
        @"enter_from": @"video_shoot_page",
        @"reality_id": self.recognitionService.trackModel.realityId ?: @"",
    };
}

@end
