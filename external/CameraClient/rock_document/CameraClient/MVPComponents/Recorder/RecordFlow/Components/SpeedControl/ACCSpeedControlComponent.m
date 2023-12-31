//
//  ACCSpeedControlComponent.m
//  Pods
//
//  Created by liyingpeng on 2020/6/23.
//

#import <KVOController/NSObject+FBKVOController.h>

#import "ACCSpeedControlComponent.h"
#import "ACCRecordFlowService.h"
#import "ACCFlowerService.h"
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreationKitArch/ACCRecorderToolBarDefines.h>
#import "ACCPropViewModel.h"
#import "HTSVideoSpeedControl.h"
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import "AWEStickerHintView.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import <CreativeKit/ACCAnimatedButton.h>
#import "ACCConfigKeyDefines.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoGameModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import "ACCBarItem+Adapter.h"
#import <CreationKitArch/ACCRecordTrackService.h>

@interface ACCSpeedControlComponent () <ACCEffectEvent, ACCRecordSwitchModeServiceSubscriber, ACCRecorderViewContainerItemsHideShowObserver, ACCRecordVideoEventHandler>

@property (nonatomic, strong) ACCAnimatedButton *speedControlButton;                    // 速度按钮
@property (nonatomic, strong) HTSVideoSpeedControl *speedControl;

@property (nonatomic, weak) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCFlowerService> flowerService;

@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, strong) UIView *speedControlButtonCustomView;

//slow motion prop
@property (nonatomic, assign) BOOL isForceStandardSpeedState;
@property (nonatomic, assign) BOOL originSpeedControlButtonSelected;
@property (nonatomic, assign) BOOL ifNeededShowHintView;
@property (nonatomic, strong) AWEStickerHintView *propHintView;

@end

@implementation ACCSpeedControlComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, flowerService, ACCFlowerService)


- (void)loadComponentView
{
    [self setupUI];
}

- (void)componentDidMount
{
    self.isFirstAppear = YES;
    [self initVariableSpeedData];
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
}

- (void)componentWillAppear
{
    [self speedComponentInit];
}

- (void)speedComponentInit
{
    if (self.isFirstAppear) {
        if ([self.viewModel defalutEnableSpeedControl]) {
            [self updateSpeedControlButtonSelectedState:self.viewModel.speedControlButtonSelected];
            [self showSpeedControlIfNeeded];
        }

        self.flowService.selectedSpeed = [HTSVideoSpeedControl defaultSelectedSpeed];
        [self bindViewModel];
        [self p_bindViewModelObserver];
        [self addSpeedControlObserver];
        self.isFirstAppear = NO;
    }
}

- (void)createSpeedControlIfNeed
{
    if (!_speedControl){
        _speedControl = [[HTSVideoSpeedControl alloc] init];
        _speedControl.hidden = YES;
        [self.viewContainer.layoutManager addSubview:_speedControl viewType:ACCViewTypeSpeedControl];
        _speedControl.sourcePage = @"shoot_page";
        _speedControl.referExtra = self.repository.repoTrack.referExtra;
        [self p_bindViewModelObserver];
        [self addSpeedControlObserver];
    }
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)initVariableSpeedData
{
    self.isForceStandardSpeedState = NO;
    self.originSpeedControlButtonSelected = NO;
    self.ifNeededShowHintView = NO;
}

- (void)bindViewModel
{
    @weakify(self);
    [[self propViewModel].propSelectionSignal.deliverOnMainThread subscribeNext:^(ACCPropSelection * _Nullable x) {
        @strongify(self);
        if ([x.effect acc_forbidSpeedBarSelection]) {
            [self p_transformForceStandardSpeedState];
        } else {
            [self p_restoreSpeedState]; //apply other props or cancel now prop
        }
        if ([x.effect acc_isTypeSlowMotion]) {
            self.ifNeededShowHintView = YES;
        } else {
            self.ifNeededShowHintView = NO;
        }
    }];
}

- (void)showSpeedControlIfNeeded
{
    if (self.cameraService.recorder.recorderState == ACCCameraRecorderStateRecording) {
        return;
    }

    BOOL show = self.viewModel.speedControlButtonSelected;
    show = show && !self.flowerService.isShowingPhotoProp;
    for (ACCSpeedControlShouldShowPredicate aPredicate in [self viewModel].predicateEnumerator) {
        show &= aPredicate();
        if (!show) {
            break;
        }
    }
    self.speedControlButton.selected = show;
    [self showSpeedControlIfShould:show animated:YES];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [IESAutoInline(self.serviceProvider, ACCRecordTrackService) registRecordVideoHandler:self];
    [self.cameraService.message addSubscriber:self];
    [self.switchModeService addSubscriber:self];
}

- (void)p_bindViewModelObserver
{
    @weakify(self);
    [self.viewContainer addObserver:self];
    
    [[RACObserve(self.viewModel, speedControlButtonSelected).deliverOnMainThread skip:ACCConfigBool(kConfigBool_enable_quick_upload) ? 1 : 0]
     subscribeNext:^(NSNumber *_Nullable x) {
        @strongify(self);
        [self handleSpeedButtonHasChangedSelected:x.boolValue];
    }];

    [RACObserve(self.cameraService.recorder, recorderState).deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        ACCCameraRecorderState state = x.integerValue;
        switch (state) {
            case ACCCameraRecorderStateNormal:
                [self showSpeedControlIfShould:YES animated:YES];
                break;
            case ACCCameraRecorderStatePausing: {
                if (self.repository.repoGame.gameType == ACCGameTypeNone) {
                    [self removePropHint];
                    [self showSpeedControlIfShould:YES animated:NO];
                }
                break;
            }
            case ACCCameraRecorderStateRecording:
                [self showSpeedControlIfShould:NO animated:NO];
                break;
            default:
                break;
        }
    }];
}

#pragma mark - UI

- (void)setupUI
{
    ACCBarItemResourceConfig *barConfig = [[self.serviceProvider resolveObject:@protocol(ACCBarItemResourceConfigManagerProtocol)] configForIdentifier:ACCRecorderToolBarSpeedControlContext];
    if (barConfig) {
        ACCBarItem *bar = [[ACCBarItem alloc] init];
        bar.title = barConfig.title;
        bar.imageName = barConfig.imageName;
        bar.selectedImageName = barConfig.selectedImageName;
        bar.useAnimatedButton = NO;
        bar.itemId = ACCRecorderToolBarSpeedControlContext;
        bar.type = ACCBarItemFunctionTypeDefault;
        
        @weakify(self);
        bar.barItemActionBlock = ^(UIView * _Nonnull itemView) {
            @strongify(self);
            if (!self.isMounted) {
                return;
            }
            [self handleClickSpeedControlAction];
        };
        bar.needShowBlock = ^BOOL{
            @strongify(self);
            ACCRecordMode *mode = self.switchModeService.currentRecordMode;
            return mode.isVideo && [self.viewModel.barItemShowPredicate evaluate] && ![self.cameraService.recorder isRecording] && !self.flowerService.isShowingPhotoProp;
        };

        [self.viewContainer.barItemContainer addBarItem:bar];

        self.speedControlButton.accessibilityLabel = [NSString stringWithFormat:@"%@%@", bar.title, self.viewModel.speedControlButtonSelected ? @"已开启":@"已关闭"];
    }
}

- (void)updateSpeedControlButtonSelectedState:(BOOL)value
{
    self.viewModel.speedControlButtonSelected = value;
    if (value) {
        [self createSpeedControlIfNeed];
    }
    [self handleSpeedButtonHasChangedSelected:value];
}

- (void)handleSpeedButtonHasChangedSelected:(BOOL)show
{
    self.speedControlButton.selected = show;
    ACCBarItem *speedItem = [self.viewContainer.barItemContainer barItemWithItemId:ACCRecorderToolBarSpeedControlContext];

    self.speedControlButton.accessibilityLabel = [NSString stringWithFormat:@"%@%@", speedItem.title, show ? @"已开启":@"已关闭"];
    if (!self.isForceStandardSpeedState) {
        self.originSpeedControlButtonSelected = self.viewModel.speedControlButtonSelected;
    }
    [self.viewContainer.layoutManager showSpeedControl:show animated:YES];
}

- (void)showSpeedControlIfShould:(BOOL)show animated:(BOOL)animated
{
    if (!self.viewModel.speedControlButtonSelected) {
        return;
    }
    
    if (show) {
        [self createSpeedControlIfNeed];
    }

    show = show && !self.viewContainer.isShowingPanel && self.repository.repoGame.gameType == ACCGameTypeNone &&
    self.switchModeService.currentRecordMode.isVideo;
    show = show && !self.flowerService.isShowingPhotoProp;
    for (ACCSpeedControlShouldShowPredicate aPredicate in [self viewModel].predicateEnumerator) {
        if (!show) {
            break;
        }
        show &= aPredicate();
    }

    [self.viewContainer.layoutManager showSpeedControl:show animated:animated];
}

#pragma mark - speed control

- (void)addSpeedControlObserver
{
    @weakify(self);
    [self.KVOController
     observe:self.speedControl
     keyPath:NSStringFromSelector(@selector(selectedSpeed))
     options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
     block:^(typeof(self) observer, typeof(self.speedControl) object, NSDictionary<NSString *,id> * changes) {
        @strongify(self);
        NSNumber *currentSpeedNumber = ACCDynamicCast(changes[NSKeyValueChangeNewKey], NSNumber);
        self.flowService.selectedSpeed = (HTSVideoSpeed)currentSpeedNumber.doubleValue;
    }];
}

- (void)handleClickSpeedControlAction
{
    if (self.isForceStandardSpeedState) {
        [ACCToast() show:ACCLocalizedString(@"slomo_cannot_adjust_speed", @"此道具不支持调整速度")];
        return;
    }
    [self updateSpeedControlButtonSelectedState:!self.viewModel.speedControlButtonSelected];
    [ACCTracker() trackEvent:@"speed_edit"
                        label:@"shoot_page"
                        value:nil
                        extra:nil
                   attributes:@{ @"shoot_way" : self.repository.repoTrack.referString?:@""}];

    NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.repository.repoTrack.referExtra];
    referExtra[@"to_status"] = !self.viewModel.speedControlButtonSelected ? @"hide" : @"show";

    [ACCTracker() trackEvent:@"edit_speed" params:referExtra needStagingFlag:NO];
}

/**
 * @discussion 两种途径改变拍摄速度：
 * 1. 由内而外，通过选择快慢速托盘上的按钮
 * 2. 由外及内：比如使用了 audio graph 道具或进入K歌模式，需要强制使用 normal speed。
 *
 * 此接口适用于 2，供外部改变拍摄速度。
 */
- (void)externalSelectSpeed:(HTSVideoSpeed)speed
{
    [self.speedControl selectSpeedByCode:speed];
    [self.speedControl setNeedsDisplay];
    self.flowService.selectedSpeed = speed;
}

#pragma mark - handle slow motion prop

- (void)p_restoreSpeedState
{
    if (self.isForceStandardSpeedState == NO) { //don't need to recover speed state
        return;
    }
    self.isForceStandardSpeedState = NO;
    [self updateSpeedControlButtonSelectedState:self.originSpeedControlButtonSelected];
    self.flowService.selectedSpeed = self.speedControl ? self.speedControl.selectedSpeed : [HTSVideoSpeedControl defaultSelectedSpeed];
    [self updateSpeedControlButtonCustomViewAlpha:1.0];
}

- (void)p_transformForceStandardSpeedState
{
    self.isForceStandardSpeedState = YES;
    [self updateSpeedControlButtonSelectedState:NO];
    self.flowService.selectedSpeed = HTSVideoSpeedNormal;
    [self updateSpeedControlButtonCustomViewAlpha:0.34];
}

- (void)p_updateSpeedBarItemViewGrayingIfNeeded
{
    if (self.isForceStandardSpeedState == NO) { //don't need to Graying speedBar
        return;
    }
    [self updateSpeedControlButtonCustomViewAlpha:0.34];
}

- (void)updateSpeedControlButtonCustomViewAlpha:(CGFloat)alpha
{
    ACCBarItem *speedItem = [self.viewContainer.barItemContainer barItemWithItemId:ACCRecorderToolBarSpeedControlContext];
    if (speedItem.needShowBlock()) {
        self.speedControlButtonCustomView.alpha = alpha;
    }
}

- (void)showPropHintOn:(UIView *)view withSpeed:(float)speed
{
    acc_dispatch_main_async_safe(^{
        if (!self.propHintView) {
            self.propHintView = [[AWEStickerHintView alloc] initWithFrame:CGRectZero];
        }
        if (self.propHintView.superview != nil && self.propHintView.superview != view) {
            [self.propHintView removeFromSuperview];
        }
        if (!self.propHintView.superview) {
            [view addSubview:self.propHintView];
            ACCMasMaker(self.propHintView, {
                make.bottom.equalTo(view.mas_bottom).offset(-240 - ACC_IPHONE_X_BOTTOM_OFFSET);
                make.top.equalTo(view.mas_top);
                make.left.equalTo(view.mas_left);
                make.width.equalTo(view.mas_width);
            });
        }
        if (speed > 1) {
            [self.propHintView showWithTitleRepeat:ACCLocalizedString(@"fast_speed_recording", @"加速录制中")];
        } else if (speed < 1){
            [self.propHintView showWithTitleRepeat:ACCLocalizedString(@"slomo_recording", @"慢动作录制中")];
        }
    });
}

- (void)removePropHint
{
    if (self.propHintView) {
        acc_dispatch_main_async_safe(^{
            [self.propHintView remove];
        });
    }
}

#pragma mark - ACCEffectEvent

- (void)onEffectMessageReceived:(IESMMEffectMessage *)message
{
    if (message.type == IESMMEffectMsgVideoRecordSpeed) {
        if (ACC_isEmptyString(message.arg3)) {
            return;
        }
        NSData *jsonData = [message.arg3 dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSDictionary *jsonInfo = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        if (error != nil) {
            AWELogToolError2(@"prop", AWELogToolTagRecord, @"Error:%@ parsing effect json into object : %@", error, message.arg3);
            return;
        }
        if (![jsonInfo isKindOfClass:[NSDictionary class]]) {
            return;
        }
        float recordRate = [[jsonInfo objectForKey:@"recordRate"] floatValue];
        if (self.ifNeededShowHintView && self.cameraService.recorder.isRecording) {
            [self showPropHintOn:self.viewContainer.interactionView withSpeed:recordRate];
        }
    }
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    if (mode.isVideo && self.repository.repoGame.gameType == ACCGameTypeNone) {
        [self showSpeedControlIfShould:YES animated:YES];
    } else {
        [self showSpeedControlIfShould:NO animated:YES];
    }
    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarSpeedControlContext];
    [self p_updateSpeedBarItemViewGrayingIfNeeded];
}

#pragma mark - ACCRecorderViewContainerItemsHideShowObserver

- (void)shouldItemsShow:(BOOL)show animated:(BOOL)animated
{
    [self showSpeedControlIfShould:show animated:NO];
}

#pragma mark - ACCRecordVideoEventHandler

- (NSDictionary *)recordVideoEvent
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    NSArray *speedModes = @[@"slowest",@"slower",@"normal",@"faster",@"fastest"];
    NSUInteger speedIndex = HTSIndexForSpeed(self.flowService.selectedSpeed);
    if (speedIndex < speedModes.count) {
        params[@"speed_mode"] = speedModes[speedIndex];
    }
    params[@"camera"] = self.cameraService.cameraControl.currentCameraPosition == AVCaptureDevicePositionFront ? @"front" : @"back";
    return [params copy];
}

#pragma mark - viewModel

- (ACCSpeedControlViewModel *)viewModel
{
    ACCSpeedControlViewModel *viewModel = [self getViewModel:ACCSpeedControlViewModel.class];
    return viewModel;
}

- (ACCPropViewModel *)propViewModel
{
    ACCPropViewModel *propViewModel = [self getViewModel:ACCPropViewModel.class];
    NSAssert(propViewModel, @"should not be nil");
    return propViewModel;
}

#pragma mark - Lazy loading

- (UIButton *)speedControlButton
{
    return [self.viewContainer.barItemContainer viewWithBarItemID:ACCRecorderToolBarSpeedControlContext].barItemButton;
}

- (UIView *)speedControlButtonCustomView
{
    return (UIView *)[self.viewContainer.barItemContainer viewWithBarItemID:ACCRecorderToolBarSpeedControlContext];
}

@end
