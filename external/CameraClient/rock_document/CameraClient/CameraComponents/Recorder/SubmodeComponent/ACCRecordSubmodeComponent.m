//
//  ACCRecordSubmodeComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by Kevin Chen on 2020/12/21.
//

#import "ACCRecordSubmodeComponent.h"

#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIDevice+ACCHardware.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreationKitArch/ACCRepoGameModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitComponents/ACCFilterService.h>
#import <CreationKitInfra/ACCRACWrapper.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitRTProtocol/ACCCameraService.h>

#import "ACCRecordViewControllerInputData.h"
#import "ACCRecordModeFactory.h"
#import "ACCRecordContainerMode.h"
#import "ACCRecordSubmodeViewModel.h"
#import "ACCSwitchLengthView.h"
#import "ACCPropViewModel.h"
#import "ACCConfigKeyDefines.h"


//#import "ACCQuickAlbumViewModel.h"
#import "ACCRecordPropService.h"
#import "ACCRecordGestureService.h"
#import "ACCKaraokeService.h"
#import "ACCFlowerService.h"

#import "AWERepoContextModel.h"
#import "IESEffectModel+DStickerAddditions.h"

@interface ACCRecordSubmodeComponent () <
ACCRecordSwitchModeServiceSubscriber,
ACCSwitchLengthViewDelegate,
ACCRecorderViewContainerItemsHideShowObserver,
ACCRecordPropServiceSubscriber,
ACCRecordGestureServiceSubscriber,
ACCKaraokeServiceSubscriber,
ACCFlowerServiceSubscriber>

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCRecordModeFactory> modeFactory;
@property (nonatomic, strong) id<ACCFilterService> filterService;
@property (nonatomic, strong) id<ACCRecordPropService> propService;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordGestureService> gestureService;
@property (nonatomic, weak) id<ACCKaraokeService> karaokeService;
@property (nonatomic, weak) id<ACCFlowerService> flowerService;

@property (nonatomic, readonly) ACCRecordSubmodeViewModel *viewModel;
//@property (nonatomic, readonly) ACCQuickAlbumViewModel *quickAlbumViewModel;

@property (nonatomic, weak) ACCRecordContainerMode *containerMode;
@property (nonatomic, strong) ACCSwitchLengthView *switchLengthView;
@property (nonatomic, strong) UIView *bottomCoverView;
@property (nonatomic, strong) ACCAnimatedButton *bottomCloseButton;
@property (nonatomic, assign) BOOL bottomCoverViewShow;
@property (nonatomic, assign) BOOL hasSwitch60SecondForMultiSegProp;
@property (nonatomic, assign) BOOL isFirstAppear;

@end

@implementation ACCRecordSubmodeComponent


IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, modeFactory, ACCRecordModeFactory)
IESAutoInject(self.serviceProvider, filterService, ACCFilterService)
IESAutoInject(self.serviceProvider, propService, ACCRecordPropService)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, gestureService, ACCRecordGestureService)

IESOptionalInject(self.serviceProvider, karaokeService, ACCKaraokeService)
IESOptionalInject(self.serviceProvider, flowerService, ACCFlowerService)

#pragma mark - LifeCycle

- (instancetype)initWithContext:(id<IESServiceProvider>)context
{
    self = [super initWithContext:context];
    if (self) {
        _isFirstAppear = YES;
    }
    return self;
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)loadComponentView
{
    [self.viewContainer.layoutManager addSubview:self.switchLengthView viewType:ACCViewTypeSwitchSubmodeView];
    if (ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab) && ACCConfigBool(kConfigBool_horizontal_scroll_hide_bottom_bar)) {
        [self.viewContainer.switchModeContainerView addSubview:self.bottomCoverView];
        self.bottomCoverView.hidden = YES;
    }
}

- (void)componentDidMount
{
    if (ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab) && ACCConfigBool(kConfigBool_horizontal_scroll_change_subtab)) {
        [self addSwitchSubmodeGesture];
        self.viewModel.swipeGestureEnabled = YES;
        self.filterService.panGestureRecognizerEnabled = NO;
    }
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }

    [self bindViewModel];
    [self.viewContainer addObserver:self];
}

- (void)componentDidAppear
{
    if (self.isFirstAppear) {
        self.isFirstAppear = NO;
    }
    if (ACCConfigBool(kConfigInt_enable_record_left_slide_dismiss)) {
        self.viewModel.swipeGestureEnabled = NO;
    }
}

#pragma mark - Swipe Gestures

- (void)addSwitchSubmodeGesture
{
    CGFloat width = self.viewContainer.layoutManager.guide.containerWidth;
    CGFloat height = self.viewContainer.layoutManager.guide.containerHeight;
    self.viewModel.gestureResponseArea = CGRectMake(0, 0, width, height);
    UISwipeGestureRecognizer *(^makeSwipeGestureForDirection)(UISwipeGestureRecognizerDirection direction) = ^UISwipeGestureRecognizer *(UISwipeGestureRecognizerDirection direction){
        UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self.viewModel action:@selector(swipeSwitchSubmode:)];
        swipeGesture.direction = direction;
        swipeGesture.numberOfTouchesRequired = 1;
        swipeGesture.delegate = self.viewModel;
        RAC(swipeGesture, enabled) = RACObserve(self.viewModel, swipeGestureEnabled);
        return swipeGesture;
    };
    [self.viewContainer.preview addGestureRecognizer:makeSwipeGestureForDirection(UISwipeGestureRecognizerDirectionLeft)];
    [self.viewContainer.preview addGestureRecognizer:makeSwipeGestureForDirection(UISwipeGestureRecognizerDirectionRight)];
}

#pragma mark - <ACCRecordSwitchModeServiceSubscriber>

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    // todo: @yangying 埋点方案应该支持其他组件添加参数
    if (!self.isFirstAppear) {
        NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.repository.repoTrack.referExtra];
        referExtra[@"to_status"] = mode.trackIdentifier;
        referExtra[@"change_type"] = @"outer";
        if (self.viewModel.containerMode) {
            if ([oldMode isKindOfClass:ACCRecordContainerMode.class] && [mode isKindOfClass:ACCRecordContainerMode.class]) {
                referExtra[@"change_type"] = @"outer";
            } else {
                if ([self.viewModel.containerMode.submodes containsObject:mode]) {
                    referExtra[@"change_type"] = @"inner";
                    referExtra[@"change_method"] = self.viewModel.switchMethodString;
                }
            }
        }
        if (mode.modeId == ACCRecordModeText) {
            referExtra[@"content_type"] = @"text";
        } else if (mode.modeId == ACCRecordModeMiniGame) {
            referExtra[@"content_type"] = @"micro_game";
        } else if (mode.modeId == ACCRecordModeAudio) {
            referExtra[@"content_type"] = @"audio";
        }
        if (self.repository.repoContext.recordSourceFrom != AWERecordSourceFromIM) {
            [ACCTracker() trackEvent:@"change_record_mode" params:referExtra needStagingFlag:NO];
        }
    }
    
    if ([mode isKindOfClass:[ACCRecordContainerMode class]]) {
        ACCRecordContainerMode *containerMode = (ACCRecordContainerMode *)mode;
        if (![self.containerMode isEqual:containerMode]) {
            self.containerMode = containerMode;
        }
        self.viewModel.switchLengthViewHidden = NO;
        [self switchTo60SecondsModeWhenMultiSegPropApplied];
    } else {
        if (![self.containerMode.submodes containsObject:mode]) {
            self.containerMode = nil;
            self.viewModel.switchLengthViewHidden = YES;
        }
    }
}

#pragma mark - ACCRecordPropServiceSubscriber

- (void)propServiceDidApplyProp:(IESEffectModel *)prop success:(BOOL)success
{
    // 多段道具需要隐藏选择时间的条
    self.viewModel.switchLengthViewHidden = prop.isMultiSegProp && !self.switchModeService.currentRecordMode.isPhoto;
    if (prop.gameType == ACCGameTypeEffectControlGame) {
        self.viewModel.switchLengthViewHidden = YES;
    }
    
    [self switchTo60SecondsModeWhenMultiSegPropApplied];
}

// I really really dont want to write code like this, but it is required by other rd.
- (void)switchTo60SecondsModeWhenMultiSegPropApplied
{
    // if current is 15 seconds mode, and user choose the multi seg prop
    // we will switch to 60 seconds mode automatically.
    if (self.propService.prop.isMultiSegProp && self.containerMode) {
        if (self.containerMode.lengthMode == ACCRecordLengthModeStandard) {
            [(ACCRecordContainerMode *)self.containerMode setCurrentMode:[self.modeFactory modeWithLength:ACCRecordLengthMode60Seconds]];
            self.viewModel.modeIndex = self.containerMode.currentIndex;
            self.hasSwitch60SecondForMultiSegProp = YES;
        }
    }
    
    // if user choose other prop
    // we will switch to 15 seconds mode back automatically.
    if (!self.propService.prop.isMultiSegProp && self.containerMode && self.containerMode.realModeId == ACCRecordModeCombined && self.hasSwitch60SecondForMultiSegProp) {
        [(ACCRecordContainerMode *)self.containerMode setCurrentMode:[self.modeFactory modeWithLength:ACCRecordLengthModeStandard]];
        self.viewModel.modeIndex = self.containerMode.currentIndex;
        self.hasSwitch60SecondForMultiSegProp = NO;
    }
}

#pragma mark - ACCKaraokeServiceSubscriber

- (void)karaokeService:(id<ACCKaraokeService>)service inKaraokeRecordPageDidChangeFrom:(BOOL)prevState to:(BOOL)state
{
    self.viewModel.switchLengthViewHidden = state;
    self.viewModel.swipeGestureEnabled = !state;
}

#pragma mark - ACCFlowerServiceSubscriber

- (void)flowerServiceWillEnterFlowerMode:(id<ACCFlowerService>)service
{
    if (self.containerMode.realModeId == ACCRecordModeStoryCombined && self.containerMode.modeId != ACCRecordModeStory) {
        [self.containerMode.submodes enumerateObjectsUsingBlock:^(ACCRecordMode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.modeId == ACCRecordModeStory) {
                self.viewModel.modeIndex = idx;
                *stop = YES;
            }
        }];
    }
}

- (void)flowerServiceDidEnterFlowerMode:(id<ACCFlowerService>)service
{
    self.viewModel.switchLengthViewHidden = YES;
    self.viewModel.swipeGestureEnabled = NO;
}

- (void)flowerServiceDidLeaveFlowerMode:(id<ACCFlowerService>)service
{
    self.viewModel.switchLengthViewHidden = NO;
    self.viewModel.swipeGestureEnabled = YES;
}

#pragma mark - <ACCSwitchLengthViewDelegate>

- (void)modeIndexDidChangeTo:(NSInteger)index method:(submodeSwitchMethod)method
{
    self.viewModel.switchMethod = method;
    self.viewModel.modeIndex = index;
}

#pragma mark - Private Method

- (void)bindViewModel
{
    self.viewModel.viewContainer = self.viewContainer;
    @weakify(self);
    // Skip 1 for initialization
    [[[RACObserve(self.viewModel, modeIndex) deliverOnMainThread] skip:1] subscribeNext:^(NSNumber *index) {
        @strongify(self)
        NSInteger modeIndex = index.intValue;
        if (modeIndex < 0 || modeIndex >= self.containerMode.submodes.count) {
            return;
        }
        self.containerMode.currentIndex = modeIndex;
        [self.switchLengthView setModeIndex:modeIndex animated:YES];
        if (ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab) && ACCConfigBool(kConfigBool_horizontal_scroll_hide_bottom_bar)) {
            ACCRecordContainerMode *storyCombined = (ACCRecordContainerMode *)[self.modeFactory modeWithIdentifier:ACCRecordModeStoryCombined];
            if ([self.containerMode isEqual:storyCombined]) {
                [self updateBottomCoverView];
            }
        }
    }];
    [[RACObserve(self.viewModel, switchLengthViewHidden) deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        self.switchLengthView.hidden = [x boolValue];
    }];
    [[RACObserve(self.cameraService.recorder, recorderState) deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        ACCCameraRecorderState state = [x intValue];
        switch (state) {
            case ACCCameraRecorderStateNormal:
                self.viewModel.switchLengthViewHidden = NO;
                break;
            case ACCCameraRecorderStatePausing:
                if (self.repository.repoGame.gameType == ACCGameTypeNone) {
                    self.viewModel.switchLengthViewHidden = NO;
                }
                break;
            case ACCCameraRecorderStateRecording:
                self.viewModel.switchLengthViewHidden = YES;
                break;
            default:
                break;
        }
    }];
    
//    // 规避快捷相册上传
//    if (ACCConfigBool(kConfigBool_enable_quick_upload)) {
//        [self.quickAlbumViewModel.quickAlbumShowStateSignal subscribeNext:^(id  _Nullable x) {
//            @strongify(self)
//            BOOL show = [x boolValue];
//            self.viewModel.quickAlbumShow = show;
//            self.viewModel.switchLengthViewHidden = show;
//        }];
//    }
    
    [[self propViewModel].didApplyStickerSignal.deliverOnMainThread subscribeNext:^(ACCDidApplyEffectPack _Nullable x) {
        @strongify(self);
        IESEffectModel *prop = x.first;
        BOOL success = x.second.boolValue;
        [self propServiceDidApplyProp:prop success:success];
    }];

    [self.karaokeService addSubscriber:self];
}

- (ACCPropViewModel *)propViewModel
{
    return [self getViewModel:ACCPropViewModel.class];
}

#pragma mark - <ACCRecorderViewContainerItemsHideShowObserver>

- (void)shouldItemsShow:(BOOL)show animated:(BOOL)animated
{
    self.viewModel.switchLengthViewHidden = !show;
}

- (void)bottomCloseButtonClicked
{
    [self trackCloseIconClick];
    self.switchLengthView.needForceSwitch = YES;
    self.viewModel.switchMethod = submodeSwitchMethodClickCross;
    self.viewModel.modeIndex = self.containerMode.defaultIndex;
}

- (void)trackCloseIconClick
{
    NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.viewModel.inputData.publishModel.repoTrack.referExtra];
    referExtra[@"prop_panel_open"] = @NO;
    referExtra[@"tab_name"] = self.switchModeService.currentRecordMode.trackIdentifier;
    [ACCTracker() trackEvent:@"click_cross_icon" params:referExtra];
}

# pragma mark - Bottom Cover View Animation

- (void)updateBottomCoverView
{
    [self.bottomCoverView.layer removeAllAnimations];
    [self.bottomCloseButton.layer removeAllAnimations];
    [self.viewContainer.switchModeContainerView.collectionView.layer removeAllAnimations];
    BOOL shouldShow = self.containerMode.currentIndex != self.containerMode.defaultIndex;
    if (shouldShow == self.bottomCoverViewShow) {
        return;
    }
    if (shouldShow) {
        [self showBottomCoverView];
    } else {
        [self hideBottomCoverView];
    }
}

- (void)showBottomCoverView
{
    self.bottomCoverViewShow = YES;
    self.bottomCoverView.transform = CGAffineTransformMakeTranslation(0, 30);
    self.bottomCloseButton.transform = CGAffineTransformMakeScale(0.7, 0.7);
    self.bottomCloseButton.alpha = 0;
    self.bottomCoverView.hidden = NO;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.bottomCoverView.transform = CGAffineTransformIdentity;
        self.bottomCloseButton.transform = CGAffineTransformIdentity;
        self.bottomCloseButton.alpha = 1;
        self.viewContainer.switchModeContainerView.collectionView.transform = CGAffineTransformMakeTranslation(0, -10);
        self.viewContainer.switchModeContainerView.collectionView.alpha = 0;
    } completion:nil];
}

- (void)hideBottomCoverView
{
    self.bottomCoverViewShow = NO;
    self.viewContainer.switchModeContainerView.collectionView.transform = CGAffineTransformMakeTranslation(0, -10);
    self.viewContainer.switchModeContainerView.collectionView.alpha = 0;
    self.bottomCloseButton.alpha = 1;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.viewContainer.switchModeContainerView.collectionView.transform = CGAffineTransformIdentity;
        self.viewContainer.switchModeContainerView.collectionView.alpha = 1;
        self.bottomCoverView.transform = CGAffineTransformMakeTranslation(0, 30);
        self.bottomCloseButton.transform = CGAffineTransformMakeScale(0.7, 0.7);
        self.bottomCloseButton.alpha = 0;
    } completion:^(BOOL finished) {
        self.bottomCoverView.hidden = finished;
    }];
}

#pragma mark - Getter & Setter

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.switchModeService addSubscriber:self];
    [self.propService addSubscriber:self];
    [self.gestureService addSubscriber:self];
    [self.flowerService addSubscriber:self];
}

- (ACCSwitchLengthView *)switchLengthView
{
    if (!_switchLengthView) {
        _switchLengthView = [[ACCSwitchLengthView alloc] initWithFrame:CGRectMake(0, 0, SUBMODE_CELL_WIDTH * 5, SUBMODE_CELL_HEIGHT)];
        _switchLengthView.delegate = self;
        if ([self.controller enableFirstRenderOptimize] && [self.switchModeService.initialRecordMode isKindOfClass:[ACCRecordContainerMode class]]) {
            _switchLengthView.containerMode = (ACCRecordContainerMode *)self.switchModeService.initialRecordMode;
        }
    }
    return _switchLengthView;
}

- (ACCRecordSubmodeViewModel *)viewModel
{
    return [self getViewModel:[ACCRecordSubmodeViewModel class]];
}

- (void)setContainerMode:(ACCRecordContainerMode *)containerMode
{
    _containerMode = containerMode;
    self.switchLengthView.containerMode = containerMode;
    self.viewModel.containerMode = containerMode;
}

- (UIView *)bottomCoverView
{
    if (!_bottomCoverView) {
        _bottomCoverView = [[UIView alloc] init];
        CGRect frame = self.viewContainer.switchModeContainerView.frame;
        frame.size.height = 48;
        frame.origin.y = 0;
        _bottomCoverView.frame = frame;
        _bottomCoverView.backgroundColor = [UIDevice acc_isIPhoneX] ? UIColor.blackColor : UIColor.clearColor;
        _bottomCloseButton = [[ACCAnimatedButton alloc] initWithFrame:CGRectMake(0, 0, 64, 48)];
        [_bottomCloseButton addTarget:self action:@selector(bottomCloseButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        [_bottomCloseButton setImage:[UIImage acc_imageWithName:@"ic_submode_close_button"] forState:UIControlStateNormal];
        _bottomCloseButton.acc_centerX = _bottomCoverView.acc_centerX;
        [_bottomCoverView addSubview:_bottomCloseButton];
    }
    return _bottomCoverView;
}

//- (ACCQuickAlbumViewModel *)quickAlbumViewModel
//{
//    return [self getViewModel:ACCQuickAlbumViewModel.class];
//}

#pragma mark - ACCRecordGestureServiceSubscriber

- (void)gesturesWillDisabled
{
    [self viewModel].swipeGestureEnabled = NO;
}

- (void)gesturesWillEnable
{
    // TODO: deserves better impl - corresponding to the `gesturesWillEnable` in accfiltercomponent, if changed, please also modify that.
    if (ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab) && ACCConfigBool(kConfigBool_horizontal_scroll_change_subtab) && !self.repository.repoContext.isIMRecord) {
        [self viewModel].swipeGestureEnabled = YES;
    }
}

@end
