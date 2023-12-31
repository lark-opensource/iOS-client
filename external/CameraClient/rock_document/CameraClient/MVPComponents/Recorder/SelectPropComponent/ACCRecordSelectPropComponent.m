//
//  ACCRecordSelectPropComponent.m
//  Pods
//
//  Created by songxiangwu on 2019/7/30.
//

#import "AWERepoAuthorityModel.h"
#import "AWERepoContextModel.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/UILabel+ACCAdditions.h>
#import "ACCRecordSelectPropComponent.h"
#import <CameraClient/ACCRecordViewControllerNotificationDefine.h>
#import <CreationKitInfra/ACCDeviceAuth.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import "AWEStickerSwitchImageView.h"
#import "AWERedPackThemeService.h"

// sinkage
#import "ACCKaraokeService.h"
#import "ACCRecordTrackHelper.h"
#import "AWERecorderTipsAndBubbleManager.h"
#import "ACCRecordSelectPropViewModel.h"
#import "ACCPropViewModel.h"
#import "ACCRecordAuthService.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitInfra/ACCRecordAuthDefine.h>
#import <CreationKitArch/ACCRepoGameModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <EffectPlatformSDK/IESCategoryModel.h>
#import "ACCFlowerService.h"

@interface ACCRecordSelectPropComponent()<
ACCRecorderViewContainerItemsHideShowObserver,
ACCKaraokeServiceSubscriber,
ACCFlowerServiceSubscriber
>

@property (nonatomic, assign) BOOL hasCameraAndMicAuthorized;
@property (nonatomic, assign) BOOL hasContainerVCAppeared;
@property (nonatomic, strong) ACCAnimatedButton *stickerSwitchButton; // 道具按钮
@property (nonatomic, strong) AWEStickerSwitchImageView *stickerSwitchImageView; // 道具入口图片
@property (nonatomic, strong) UILabel *stickerSwitchLabel; // 道具文字configStickerBtnWithURLArray

@property (nonatomic, strong) ACCRecordSelectPropViewModel *viewModel;
@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCRecordAuthService> authService;
@property (nonatomic, weak) id<ACCKaraokeService> karaokeService;
@property (nonatomic, strong) id<AWERedPackThemeService> themeService;
@property (nonatomic, weak) id<ACCFlowerService> flowerService;

@end

@implementation ACCRecordSelectPropComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, authService, ACCRecordAuthService)

IESOptionalInject(self.serviceProvider, karaokeService, ACCKaraokeService)
IESOptionalInject(self.serviceProvider, flowerService, ACCFlowerService);
IESOptionalInject(self.serviceProvider, themeService, AWERedPackThemeService)

#pragma mark - Life Cycle
// TODO: @haoyipeng superEntrance 这里下个版本移出CameraClient，放在AWEStudio中，在AWEStudio中替换rootComponent来添加一个新的SuperEntranceComponent做这些逻辑
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] postNotificationName:AWEStudioSuperEntranceBubbleShowedNotification object:nil];
}

- (void)loadComponentView
{
    [self.viewContainer.layoutManager addSubview:self.stickerSwitchButton viewType:ACCViewTypeStickerSwitchButton];
    [self.viewContainer.layoutManager addSubview:self.stickerSwitchLabel viewType:ACCViewTypeStickerSwitchLabel];
}

- (void)componentDidMount
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    [self p_readExistData];
    [self p_bindViewModel];
    ACCLog(@"componentDidMount");
}

- (void)componentWillAppear
{
    ACCLog(@"componentWillAppear");
}

- (void)componentDidAppear
{
    if ([ACCDeviceAuth isCameraAuth] && [ACCDeviceAuth isMicroPhoneAuth]) {
        if ((!self.repository.repoAuthority.shouldShowGrant && self.viewModel.inputData.showStickerPanelAtLaunch && [self.viewModel.canShowStickerPanelAtLaunch evaluate]) || (self.viewModel.inputData.motivationTaskShowPropPanel)) {
            [self clickStickersBtn];
            self.viewModel.inputData.motivationTaskShowPropPanel = NO;
            self.viewModel.inputData.showStickerPanelAtLaunch = NO;
        }
    }
    
    // TODO: @haoyipeng superEntrance 这里下个版本移出CameraClient，放在AWEStudio中，在AWEStudio中替换rootComponent来添加一个新的SuperEntranceComponent做这些逻辑
    self.hasContainerVCAppeared = YES;
    [self showSuperEntranceBubbleIfNeeded];
    ACCLog(@"componentDidAppear");
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

#pragma mark - ACCRecorderViewContainerItemsHideShowObserver

- (void)shouldItemsShow:(BOOL)show animated:(BOOL)animated
{
    if (animated) {
        self.viewModel.selectPropDisplayType = (show ? ACCRecordSelectPropDisplayTypeFadeShow : ACCRecordSelectPropDisplayTypeFadeHidden);
    } else {
        self.viewModel.selectPropDisplayType = (show ? ACCRecordSelectPropDisplayTypeShow : ACCRecordSelectPropDisplayTypeHidden);
    }
}

#pragma mark - ACCKaraokeServiceSubscriber

- (void)karaokeService:(id<ACCKaraokeService>)service recordModeDidChangeFrom:(ACCKaraokeRecordMode)prevMode to:(ACCKaraokeRecordMode)mode
{
    if (mode == ACCKaraokeRecordModeAudio) {
        self.viewModel.selectPropDisplayType = ACCRecordSelectPropDisplayTypeFadeHidden;
    } else {
        self.viewModel.selectPropDisplayType = ACCRecordSelectPropDisplayTypeFadeShow;
    }
}

#pragma mark - ACCFlowerServiceSubscriber

- (void)flowerServiceDidEnterFlowerMode:(id<ACCFlowerService>)service
{
    self.viewModel.selectPropDisplayType = ACCRecordSelectPropDisplayTypeFadeHidden;
}

- (void)flowerServiceDidLeaveFlowerMode:(id<ACCFlowerService>)service
{
    self.viewModel.selectPropDisplayType = ACCRecordSelectPropDisplayTypeFadeShow;
}

#pragma mark - private methods

//when other component send signal in componentDidMount,this component's componentDidMount hasn't excute, so need read exist data;
- (void)p_readExistData
{
    if ([self propViewModel].appliedLocalEffect) {
        [self p_updateIcon:[self propViewModel].appliedLocalEffect];
    }
    if ([self propViewModel].didApplyEffectPack) {
        [self p_applyEffectWithPack:[self propViewModel].didApplyEffectPack];
    }
}

- (void)p_bindViewModel
{
    @weakify(self);
    [[[RACObserve(self.viewModel, selectPropDisplayType) deliverOnMainThread] ignore:nil] subscribeNext:^(NSNumber *x) {
        @strongify(self);
        ACCLog(@"selectPropDisplayType is %ld",(long)[x integerValue]);
        ACCRecordSelectPropDisplayType type = (ACCRecordSelectPropDisplayType)[x integerValue];
        
        if (type == ACCRecordSelectPropDisplayTypeDefault) {
            return;
        }
        ACCRecordModeIdentifier modeID = self.switchModeService.currentRecordMode.modeId;
        if (modeID == ACCRecordModeLive || (self.karaokeService.inKaraokeRecordPage && self.karaokeService.recordMode == ACCKaraokeRecordModeAudio)|| self.viewModel.inputData.publishModel.repoGame.gameType != ACCGameTypeNone || [self viewContainer].propPanelType != ACCRecordPropPanelNone || self.cameraService.recorder.recorderState == ACCCameraRecorderStateRecording || self.flowerService.inFlowerPropMode) {
            if (type == ACCRecordSelectPropDisplayTypeShow || type == ACCRecordSelectPropDisplayTypeFadeShow) {
                return;
            }
        }

        if (type == ACCRecordSelectPropDisplayTypeShow || type == ACCRecordSelectPropDisplayTypeHidden) {
            self.stickerSwitchButton.hidden = (type == ACCRecordSelectPropDisplayTypeHidden);
            self.stickerSwitchLabel.hidden = (type == ACCRecordSelectPropDisplayTypeHidden);
            self.stickerSwitchImageView.hidden = (type == ACCRecordSelectPropDisplayTypeHidden);
        } else {
            if (type == ACCRecordSelectPropDisplayTypeFadeShow) {
                [self.stickerSwitchButton acc_fadeShow];
                if ([self.viewModel.canShowUploadVideoLabel evaluate]) {
                    [self.stickerSwitchLabel acc_fadeShow];
                }
                [self.stickerSwitchImageView acc_fadeShow];
            } else {
                [self.stickerSwitchButton acc_fadeHidden];
                [self.stickerSwitchLabel acc_fadeHidden];
                [self.stickerSwitchImageView acc_fadeHidden];
            }
        }
    }];
    
    //prop
    [[self propViewModel].didApplyStickerSignal.deliverOnMainThread subscribeNext:^(ACCDidApplyEffectPack _Nullable x) {
        @strongify(self);
        [self p_applyEffectWithPack:x];
    }];
    // prop panel
    // should not update icon if it has already shown local sticker
    [[[self propViewModel].didFinishLoadEffectListSignal.deliverOnMainThread takeUntil:[self propViewModel].didApplyStickerSignal] subscribeNext:^(IESEffectModel *sticker) {
        @strongify(self);
        [self p_updateIcon:sticker];
    }];
    
    //cmd
    [self.viewContainer addObserver:self];
    
    [RACObserve(self.cameraService.recorder, recorderState).deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        ACCCameraRecorderState state = x.integerValue;
        ACCRecordMode *currentMode = self.switchModeService.currentRecordMode;
        ACCGameType gameType = self.viewModel.inputData.publishModel.repoGame.gameType;
        BOOL isKaraokeAudioMode = currentMode.modeId == ACCRecordModeKaraoke && self.karaokeService.recordMode == ACCKaraokeRecordModeAudio;
        switch (state) {
            case ACCCameraRecorderStateNormal:
                self.viewModel.selectPropDisplayType = \
                (self.viewContainer.isShowingAnyPanel ||
                 gameType != ACCGameTypeNone ||
                 isKaraokeAudioMode ||
                (!currentMode.isPhoto && !currentMode.isVideo)) ? ACCRecordSelectPropDisplayTypeHidden : ACCRecordSelectPropDisplayTypeShow;
                break;
            case ACCCameraRecorderStatePausing:
                self.viewModel.selectPropDisplayType = \
                (self.viewContainer.isShowingPanel ||
                 isKaraokeAudioMode ||
                 gameType != ACCGameTypeNone ||
                 (!currentMode.isPhoto && !currentMode.isVideo)) ? ACCRecordSelectPropDisplayTypeFadeHidden : ACCRecordSelectPropDisplayTypeFadeShow;
                break;
            case ACCCameraRecorderStateRecording:
                self.viewModel.selectPropDisplayType = ACCRecordSelectPropDisplayTypeFadeHidden;
                break;
            default:
                break;
        }
    }];
    
    [self.authService.confirmAllowUseCameraSignal.deliverOnMainThread subscribeNext:^(NSNumber *x) {
        @strongify(self);
        if (self.viewModel.inputData.showStickerPanelAtLaunch) {
            [self clickStickersBtn];
        }
    }];
    [self.authService.passCheckAuthSignal.deliverOnMainThread subscribeNext:^(NSNumber *x) {
        @strongify(self);
        ACCRecordAuthComponentAuthType authType = x.integerValue;
        if (authType == (ACCRecordAuthComponentCameraAuthed | ACCRecordAuthComponentMicAuthed)) {
            if (self.viewModel.inputData.showStickerPanelAtLaunch) {
                self.viewModel.inputData.showStickerPanelAtLaunch = NO;
                [self clickStickersBtn];
            }
        }
        // TODO: @haoyipeng superEntrance 这里下个版本移出CameraClient，放在AWEStudio中，在AWEStudio中替换rootComponent来添加一个新的SuperEntranceComponent做这些逻辑
        if (authType == (ACCRecordAuthComponentCameraAuthed | ACCRecordAuthComponentMicAuthed)) {
            self.hasCameraAndMicAuthorized = YES;
            [self showSuperEntranceBubbleIfNeeded];
        }
    }];
    [self.karaokeService addSubscriber:self];
    [self.flowerService addSubscriber:self];
}

- (void)p_updateIcon:(IESEffectModel *)sticker
{
    if (![sticker.iconDownloadURLs count]) {
        [self.stickerSwitchImageView replaceCoverImageWithImage:nil isDynamic:NO];
    } else {
        BOOL isDynamic = NO;
        NSArray<NSString *> *iconURLArray = sticker.iconDownloadURLs;
        NSString *key = [NSString stringWithFormat:@"dynamic_icon_%@", sticker.effectIdentifier];
        BOOL isDynamicIconEverClicked = [ACCCache() boolForKey:key];
        BOOL enableShowingDynamicIcon = ACCConfigBool(kConfigBool_enable_sticker_dynamic_icon) && !ACC_isEmptyArray(sticker.dynamicIconURLs) && !isDynamicIconEverClicked;
        if (enableShowingDynamicIcon) {
            iconURLArray = sticker.dynamicIconURLs;
            isDynamic = YES;
        }

        @weakify(self);
        [self.viewModel configStickerBtnWithURLArray:iconURLArray index:0 completion:^(UIImage * _Nonnull image) {
            @strongify(self);
            [self.stickerSwitchImageView replaceCoverImageWithImage:image isDynamic:isDynamic];
        }];
    }
}

- (void)p_updateDyanmicIconStatus:(IESEffectModel *)sticker
{
    NSString *key = [NSString stringWithFormat:@"dynamic_icon_%@", sticker.effectIdentifier];
    BOOL isDynamicIconEverClicked = [ACCCache() boolForKey:key];
    BOOL enableShowingDynamicIcon = ACCConfigBool(kConfigBool_enable_sticker_dynamic_icon) && !ACC_isEmptyArray(sticker.dynamicIconURLs) && !isDynamicIconEverClicked;
    if (enableShowingDynamicIcon) {
        [ACCCache() setBool:YES forKey:key];
    }
}

- (void)p_applyEffectWithPack:(ACCDidApplyEffectPack _Nullable)pack
{
    IESEffectModel *sticker = pack.first;
    [self p_updateDyanmicIconStatus:sticker];
    // 贴纸应用成功后，判断是否是需要扫码解锁的商业化贴纸
    [self p_updateIcon:sticker];
}

#pragma mark - action

- (void)clickStickersBtn
{
    if (!self.isMounted) {
        return;
    }
    if (self.cameraService.recorder.isRecording) {
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ACCStickerSwitchButtonClicked object:self];
    [[AWERecorderTipsAndBubbleManager shareInstance] removeBubbleAndHintIfNeeded];
    AWEVideoPublishViewModel *publishModel = self.viewModel.inputData.publishModel;
    [ACCTracker() trackEvent:@"click_prop"
                                      label:@"shoot_page"
                                      value:nil
                                      extra:nil
                   attributes:[ACCRecordTrackHelper trackAttributesOfPhotoFeatureWithCamera:self.cameraService publishModel:self.viewModel.inputData.publishModel]];

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (publishModel.repoContext.isIMRecord || publishModel.repoContext.videoType == AWEVideoTypeKaraoke) {
        [params addEntriesFromDictionary:publishModel.repoTrack.referExtra];
    }

    [params setValue:self.viewModel.inputData.publishModel.repoTrack.referString forKey:@"shoot_way"];
    [params setValue:self.viewModel.inputData.publishModel.repoContext.createId forKey:@"creation_id"];
    [params setValue:@(self.viewModel.inputData.publishModel.repoDraft.editFrequency).stringValue forKey:@"draft_id"];
    params[@"enter_from"] = @"video_shoot_page";
    params[@"enter_method"] = @"normal";
    params[@"is_meteormode"] = @(self.repository.repoContext.isMeteorMode ? 1 : 0);
    NSString *eventName = self.viewModel.inputData.publishModel.repoContext.recordSourceFrom == AWERecordSourceFromUnknown ? @"click_prop_entrance" : @"im_click_prop_entrance";
    
    if (self.themeService.isThemeRecordMode && self.themeService.isVideoCaptureState) {
        params[@"enter_from"] = @"concept_shoot_page";
        params[@"concept_name"] = self.themeService.category.categoryName;
    }
    
    [ACCTracker() trackEvent:eventName params:params needStagingFlag:NO];

    [self.viewModel sendSignalAfterClickSelectPropBtn];
}

#pragma mark - superEntrance // TODO: @haoyipeng superEntrance 这里下个版本移出CameraClient，放在AWEStudio中，在AWEStudio中替换rootComponent来添加一个新的SuperEntranceComponent做这些逻辑
- (void)showSuperEntranceBubbleIfNeeded
{
    if (!self.hasContainerVCAppeared || !self.hasCameraAndMicAuthorized) {
        return;
    }
    NSString *superEntranceEffectTagKey = @"AWEStudioSuperEntranceEffectKey";
    if ([ACCConfigArray(kConfigArray_super_entrance_effect_ids) containsObject:self.viewModel.inputData.localSticker.effectIdentifier] &&
        ![ACCCache() boolForKey:superEntranceEffectTagKey] &&
        !ACC_isEmptyString(ACCConfigString(kConfigString_super_entrance_effect_applyed_bubble_string))) {
        
        [ACCCache() setBool:YES forKey:superEntranceEffectTagKey];
        [ACCBubble() showBubble:ACCLocalizedString(ACCConfigString(kConfigString_super_entrance_effect_applyed_bubble_string), nil)
                           forView:self.stickerSwitchButton
                       inDirection:ACCBubbleDirectionUp
                           bgStyle:ACCBubbleBGStyleDefault];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:AWEStudioSuperEntranceBubbleShowedNotification object:nil];
}

#pragma mark - getter & setter

- (ACCRecordSelectPropViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self getViewModel:ACCRecordSelectPropViewModel.class];
    }
    NSAssert(_viewModel, @"viewModel should not be nil");
    return _viewModel;
}

- (ACCAnimatedButton *)stickerSwitchButton
{
    if (!_stickerSwitchButton) {
        _stickerSwitchButton = [[ACCAnimatedButton alloc] init];
        [_stickerSwitchButton addSubview:self.stickerSwitchImageView];
        ACCMasMaker(self.stickerSwitchImageView, {
            make.edges.equalTo(_stickerSwitchButton);
        });
        _stickerSwitchButton.layer.shadowOffset = CGSizeMake(0, 1);        
        _stickerSwitchButton.layer.shadowColor = ACCResourceColor(ACCUIColorConstSDInverse).CGColor;
        _stickerSwitchButton.layer.shadowRadius = 1;
        _stickerSwitchButton.accessibilityLabel = ACCLocalizedCurrentString(@"tool");
        [_stickerSwitchButton addTarget:self action:@selector(clickStickersBtn) forControlEvents:UIControlEventTouchUpInside];
    }
    return _stickerSwitchButton;
}

- (AWEStickerSwitchImageView *)stickerSwitchImageView
{
    if (!_stickerSwitchImageView) {
        UIImage *img = ACCResourceImage(@"icon_sticker");
        _stickerSwitchImageView = [[AWEStickerSwitchImageView alloc] initWithFrame:CGRectMake(0, 0, img.size.width, img.size.height)];
        _stickerSwitchImageView.image = img;
    }
    return _stickerSwitchImageView;
}

- (UILabel *)stickerSwitchLabel
{
    if (!_stickerSwitchLabel) {
        _stickerSwitchLabel = [[UILabel alloc] acc_initWithFont:[ACCFont() acc_boldSystemFontOfSize:11]
                                                      textColor:ACCResourceColor(ACCUIColorConstBGContainer4)
                                                           text:(self.viewModel.stickerSwitchText ?: ACCLocalizedCurrentString(@"tool"))];
        _stickerSwitchLabel.textAlignment = NSTextAlignmentCenter;
        _stickerSwitchLabel.numberOfLines = 2;
        _stickerSwitchLabel.preferredMaxLayoutWidth = 90;
        _stickerSwitchLabel.isAccessibilityElement = NO;
    }
    return _stickerSwitchLabel;
}

- (ACCPropViewModel *)propViewModel
{
    ACCPropViewModel *propViewModel = [self getViewModel:ACCPropViewModel.class];
    NSAssert(propViewModel, @"should not be nil");
    return propViewModel;
}

@end
