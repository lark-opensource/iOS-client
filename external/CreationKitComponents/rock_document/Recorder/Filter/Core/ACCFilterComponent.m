//
//  ACCFilterComponent.m
//  ASVE
//
//Created by Hao Yipeng on August 5, 2019
//

#import "ACCFilterComponent.h"
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>

// sinkage
#import "AWETabFilterViewController.h"
#import <CreationKitArch/ACCRecorderToolBarDefines.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import "ACCFilterDefines.h"
#import "ACCFilterPrivateService.h"
#import <CreationKitArch/ACCRecordTrackService.h>
#import <CreationKitArch/AWEColorFilterDataManager.h>
#import <CreationKitInfra/ACCTapticEngineManager.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import "ACCFilterConfigKeyDefines.h"
#import <CreationKitInfra/ACCConfigManager.h>
#import "ACCFilterDataService.h"
#import "ACCFilterTrackerSender.h"
#import "AWECameraFilterConfiguration.h"
#import <CreativeKit/ACCServiceBinding.h>
#import <CreationKitInfra/ACCRTLProtocol.h>

@interface ACCFilterComponent () <
UIGestureRecognizerDelegate,
AWERecordFilterVCDelegate,
ACCPanelViewDelegate,
ACCRecordVideoEventHandler,
ACCRecordSwitchModeServiceSubscriber>

@property (nonatomic, strong) AWETabFilterViewController *filterController;
@property (nonatomic, strong) NSMutableSet<IESEffectModel *> *scrollBrowsedFilters;

@property (nonatomic, assign) CGRect gestureResponseArea;
@property (nonatomic, assign) NSInteger switchFilterDirection;
@property (nonatomic, strong) IESEffectModel *switchToFilter;
@property (nonatomic, assign) BOOL filterAniTiming;
@property (nonatomic, assign) double autoRenderProgress;
@property (nonatomic, assign) BOOL isCompeleteWhenFilterAniBegin;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) BOOL isSwitchFilter;

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) ACCFilterTrackerSender *trackSender;
@property (nonatomic, strong) id<ACCFilterDataService> dataService;

@property (nonatomic, strong) id<ACCFilterPrivateService> filterService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;

@end

@implementation ACCFilterComponent


IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, dataService, ACCFilterDataService)
IESAutoInject(self.serviceProvider, filterService, ACCFilterPrivateService)

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithContext:(id<IESServiceProvider>)context
{
    self = [super initWithContext:context];
    if (self) {
        _scrollBrowsedFilters = [NSMutableSet setWithCapacity:1];
        @weakify(self);
        [[NSNotificationCenter defaultCenter] addObserverForName:kAWEStudioColorFilterUpdateNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            @strongify(self);
            if (self.isMounted) {
                [self.filterService.filterConfiguration updateFilterData];
                IESEffectModel *currentFilter = self.filterService.currentFilter;
                NSString *prevFilterId = self.filterController.selectedFilter.effectIdentifier;
                if (currentFilter != nil && ![prevFilterId isEqualToString:currentFilter.effectIdentifier]) {
                    [self.filterService applyFilter:currentFilter
                                   withShowFilterName:YES
                                    sendManualMessage:YES];
                    self.filterController.selectedFilter = currentFilter;
                }
            }
        }];
    }
    return self;
}

#pragma mark - Component Lifecycle


- (void)componentDidMount
{
    [self.viewContainer.panelViewController registerObserver:self];
    [self bindViewModel];
    [self configFilterSwitchComponent];
}

- (void)componentDidAppear {
    [self startSwitchDisplayLink];
}

- (void)componentDidUnmount
{
    [self.viewContainer.panelViewController unregisterObserver:self];
    [self stopSwitchDisplayLink];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)bindViewModel
{

}

- (void)configFilterSwitchComponent
{
    // check if containerView did load
    CGFloat width = self.viewContainer.layoutManager.guide.containerWidth;
    CGFloat height = self.viewContainer.layoutManager.guide.containerHeight;
    
    [self addFilterSwitchGestureForView:self.viewContainer.preview gestureResponseArea:CGRectMake(0, 0, width, height)];
}

- (void)filterSwitchFinishWithModel:(IESEffectModel *)filter
{
    [self refreshSelectedFilterWithModel:filter];
    [self.trackSender sendFilterSlideSwitchCompleteSignal:filter];
}

- (void)componentWillLayoutSubviews
{
    CGFloat width = self.viewContainer.layoutManager.guide.containerWidth;
    CGFloat height = self.viewContainer.layoutManager.guide.containerHeight;
    self.gestureResponseArea = CGRectMake(0, 0, width, height);
}

#pragma mark - AWERecordFilterVCDelegate
// AWERecordFilterVCDelegate
- (void)applyFilter:(IESEffectModel *)filter
{
    // track event when delete filter
    self.filterService.hasDeselectionBeenMadeRecently = filter ? NO : YES;
    [self applyFilter:filter withShowFilterName:YES];
}

- (void)applyFilter:(IESEffectModel *)filter indensity:(float)indensity
{
    [self.filterService applyFilter:filter indensity:indensity];
}

- (float)filterIndensity:(IESEffectModel *)filter
{
    return [self.filterService filterIndensity:filter];
}

- (void)applyFilter:(IESEffectModel *)filter withShowFilterName:(BOOL)show
{
    [self.filterService applyFilter:filter withShowFilterName:show sendManualMessage:YES];
}

- (AWEColorFilterConfigurationHelper *)currentFilterHelper
{
    return [self.filterService currentFilterHelper];
}

- (BOOL)enableFilterIndensity
{
    return YES;
}

- (void)didClickedCategory:(IESCategoryModel *)category
{
    [self.trackSender sendFilterViewDidClickCategorySignal:category];
}

- (void)didClickedFilter:(IESEffectModel *)item
{
    [self.trackSender sendFilterViewDidClickFilterSignal:item];
}

#pragma mark -

- (void)refreshSelectedFilterWithModel:(nonnull IESEffectModel *)effectModel
{
    [self.filterController selectFilterByCode:effectModel];
    if (self.filterController.view.superview) {
        [self.filterController selectFilterByCode:effectModel];
    } else {
        if (effectModel) {
            [self.scrollBrowsedFilters addObject:effectModel];
        }
    }
}

- (void)showOnView:(nonnull UIView *)containerView
{
    self.filterController.selectedFilter = self.filterService.currentFilter;
    [self.filterService applyFilter:self.filterService.currentFilter withShowFilterName:NO sendManualMessage:YES];
    [self.viewContainer.panelViewController showPanelView:self.filterController duration:0.49];
    [self.filterController reloadData];
}

- (NSString *)tabNameForFilter:(nonnull IESEffectModel *)filter
{
    return [self.filterController tabNameForFilter:filter];
}

#pragma mark - switch filter

- (void)addFilterSwitchGestureForView:(nonnull UIView *)view gestureResponseArea:(CGRect)gestureResponseArea
{
    UIView *targetView = view;
    self.gestureResponseArea = gestureResponseArea;
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panSwitchFilter:)];
    panGestureRecognizer.cancelsTouchesInView = NO;
    panGestureRecognizer.maximumNumberOfTouches = 1;
    panGestureRecognizer.delegate = self;
    [targetView addGestureRecognizer:panGestureRecognizer];
    RAC(panGestureRecognizer, enabled) = RACObserve(self.filterService, panGestureRecognizerEnabled);
    self.filterService.panGestureRecognizer = panGestureRecognizer;
}

- (BOOL)enableFilterSwitch
{
    return self.dataService.videoType == AWEVideoTypeReplaceMusicVideo ? NO : YES;
}

- (void)panSwitchFilter:(UIPanGestureRecognizer *)gestureRecognizer
{
    if (![self enableFilterSwitch]) {
        return ;
    }
    UIView *panView = gestureRecognizer.view;
    CGPoint location = [gestureRecognizer locationInView:panView];
    if (!CGRectEqualToRect(self.gestureResponseArea,CGRectZero)) {
        if (location.x < self.gestureResponseArea.origin.x || location.x > self.gestureResponseArea.size.width ||
            location.y < self.gestureResponseArea.origin.y || location.y > self.gestureResponseArea.size.height) {
            return;
        }
    }

    double translationX = [gestureRecognizer translationInView:panView].x;
    double velocityX = [gestureRecognizer velocityInView:panView].x;
    double velocityY = [gestureRecognizer velocityInView:panView].y;
    
    if ([ACCRTL() isRTL]) {
        translationX = -translationX;
        velocityX = -velocityX;
    }
    
    //Filter switching progress
    __block CGFloat progressFilter = fabs(translationX) / CGRectGetWidth(panView.frame);
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            if (fabs(velocityY) <= fabs(velocityX)) { //The large lateral velocity indicates that the filter needs to slide
                self.isSwitchFilter = YES;
                [self.filterService recoverFilterIfNeeded]; // Restore the filter when the filter is empty
                
                //Determine which direction to switch the filter
                //1 means that the new filter will appear from the right side of the screen- 1 means the new filter will appear on the left side of the screen
                self.switchFilterDirection = velocityX > 0 ? -1 : 1;

                if (self.switchFilterDirection == -1) {
                    self.switchToFilter = [self.filterService prevFilterOfCurrentFilter];
                } else {
                    self.switchToFilter = [self.filterService nextFilterOfCurrentFilter];
                }
            } else { //Vertical speed is large, which means sliding music effects
                self.isSwitchFilter = NO;
            }
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            if (self.isSwitchFilter) {
                //Call the interface of switching filter according to the progress
                if ((translationX > 0 ? -1 : 1) == self.switchFilterDirection) {
                    IESEffectModel *leftModel = nil;
                    IESEffectModel *rightModel = nil;
                    CGFloat actualFilterProgress = progressFilter;
                    if (self.switchFilterDirection == 1) {
                        leftModel = self.currentFilter;
                        rightModel = self.switchToFilter;
                        actualFilterProgress = 1 - progressFilter;
                    } else {
                        leftModel = self.switchToFilter;
                        rightModel = self.currentFilter;
                    }
                    //Correction to prevent a thin edge on the filter
                    if (actualFilterProgress < 0.025) {
                        actualFilterProgress = 0;
                    }
                    if (actualFilterProgress > 1 - 0.025) {
                        actualFilterProgress = 1;
                    }
                    [self.filterService switchFilterWithFilterOne:leftModel FilterTwo:rightModel direction:self.switchFilterDirection progress:actualFilterProgress];

                    [self changeFilterRelatedUIWithProgress:progressFilter];
                }
            }
        }
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: //Cancel calls the same logic
        {
            if (self.isSwitchFilter) {
                BOOL isCompelete = (fabs(velocityX) > 500 && ((velocityX > 0 ? -1 : 1) == self.switchFilterDirection)) || (fabs(progressFilter) > 0.5 && (translationX > 0 ? -1 : 1) == self.switchFilterDirection);
                [self applyFilterWithBeginProgress:progressFilter isCompelete:isCompelete];
            }
        }
            break;
        default:
            break;
    }
}

- (void)applyFilterWithBeginProgress:(double)progress isCompelete:(BOOL)isCompelete
{
    if ((progress > 0.02 && !isCompelete) || (progress < 0.98 && isCompelete)) {
        self.filterAniTiming = YES;
        self.isCompeleteWhenFilterAniBegin = isCompelete;
        self.autoRenderProgress = progress;
        self.filterService.panGestureRecognizerEnabled = NO;
        return;
    }

    self.filterAniTiming = NO;
    self.filterService.panGestureRecognizerEnabled = YES;

    if (isCompelete) {
        self.filterService.currentFilter = self.switchToFilter;
        if (ACCConfigBool(kConfigBool_apply_filter_enable_taptic)) {
            [ACCTapticEngineManager tap];
        }
    }
    [self.filterService sendApplyFilterSignalWith:isCompelete];
    [self filterSwitchFinishWithModel:self.currentFilter];
    [self refreshSelectedFilterWithModel:self.currentFilter];
    self.isSwitchFilter = NO;
}

- (void)changeFilterRelatedUIWithProgress:(CGFloat)progress
{
    CGFloat displayProgress = progress;
    IESEffectModel *leftFilter = self.switchToFilter;
    IESEffectModel *rightFilter = self.currentFilter;
    if (self.switchFilterDirection > 0) {
        displayProgress = 1 - displayProgress;
        leftFilter = self.currentFilter;
        rightFilter =  self.switchToFilter;
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer  == self.filterService.panGestureRecognizer && ![self switchFilterGestureShouldBegin]) {
        return NO;
    }
    return YES;
}

- (BOOL)switchFilterGestureShouldBegin
{
    return !self.viewContainer.isShowingPanel && !self.cameraService.recorder.isRecording;
}

- (void)startSwitchDisplayLink
{
    if (!self.mounted) {
        return;
    }
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }

    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(renderOnMainLoop)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopSwitchDisplayLink
{
    if (!self.mounted) {
        return;
    }
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

- (void)renderOnMainLoop
{
    if (!self.filterAniTiming) {
        return;
    }

    if (self.isCompeleteWhenFilterAniBegin) {
        if (self.autoRenderProgress >= 0.98) {
            [self applyFilterWithBeginProgress:1.0 isCompelete:self.isCompeleteWhenFilterAniBegin];
        } else {
            self.autoRenderProgress += 0.045;
            if (self.autoRenderProgress >= 0.98) {
                self.autoRenderProgress = 1.0;
            }

            IESEffectModel *leftModel = nil;
            IESEffectModel *rightModel = nil;
            CGFloat actualFilterProgress = self.autoRenderProgress;
            if (self.switchFilterDirection == 1) {
                leftModel = self.currentFilter;
                rightModel = self.switchToFilter;
                actualFilterProgress = 1 - self.autoRenderProgress;
            } else {
                leftModel = self.switchToFilter;
                rightModel = self.currentFilter;
            }

            [self.filterService switchFilterWithFilterOne:leftModel FilterTwo:rightModel direction:self.switchFilterDirection progress:actualFilterProgress];

            [self changeFilterRelatedUIWithProgress:self.autoRenderProgress];
        }
    } else {
        if (self.autoRenderProgress <= 0.02) {
            [self applyFilterWithBeginProgress:0.0 isCompelete:self.isCompeleteWhenFilterAniBegin];
        } else {
            self.autoRenderProgress -= 0.045;
            if (self.autoRenderProgress <= 0.02) {
                self.autoRenderProgress = 0.0;
            }
            IESEffectModel *leftModel = nil;
            IESEffectModel *rightModel = nil;
            CGFloat actualFilterProgress = self.autoRenderProgress;
            if (self.switchFilterDirection == 1) {
                leftModel = self.currentFilter;
                rightModel = self.switchToFilter;
                actualFilterProgress = 1 - self.autoRenderProgress;
            } else {
                leftModel = self.switchToFilter;
                rightModel = self.currentFilter;
            }

            [self.filterService switchFilterWithFilterOne:leftModel FilterTwo:rightModel direction:self.switchFilterDirection progress:actualFilterProgress];
            [self changeFilterRelatedUIWithProgress:self.autoRenderProgress];
        }
    }
}

#pragma mark - action

- (void)handleClickFilterAction
{
    if (self.cameraService.recorder.isRecording) {
        return;
    }
    [self.filterService sendFilterViewWillShowSignal];
    self.viewContainer.isShowingPanel = YES;
    [self.viewContainer showItems:NO animated:YES];
    
    [self showOnView:self.viewContainer.interactionView];
    
    [self.trackSender sendFilterViewWillShowSignal];
}

#pragma mark - getter

- (AWETabFilterViewController *)filterController
{
    if (!_filterController) {
        _filterController = [[AWETabFilterViewController alloc] initWithFilterConfiguration:self.filterService.filterConfiguration];
        _filterController.iconStyle = (AWEFilterCellIconStyle)ACCConfigInt(kConfigInt_filter_icon_style);
        _filterController.showFilterBoxButton = ACCConfigBool(kConfigInt_filter_box_should_show); //The filter panel entrance of the shooting page displays the filter management_ filterController
        _filterController.showOnViewController = YES;
        _filterController.repository = self.dataService;
        _filterController.delegate = self;
        _filterController.needDismiss = NO;
        _filterController.filterManager = [AWEColorFilterDataManager defaultManager];
        @weakify(self);
        _filterController.willDismissBlock = ^(void) {
            @strongify(self);
            [self.trackSender sendFilterViewWillDisappearSignalWithFilter:self.filterService.currentFilter];
            [self.viewContainer.panelViewController dismissPanelView:self.filterController duration:0.25];
        };
    }
    return _filterController;
}

- (IESEffectModel *)currentFilter
{
    return self.filterService.currentFilter;
}

- (NSArray<ACCServiceBinding *> *)serviceBindingArray {
    return @[
        ACCCreateServiceBinding(@protocol(ACCFilterTrackSenderProtocol), self.trackSender),
    ];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.switchModeService addSubscriber:self];
    [IESAutoInline(self.serviceProvider, ACCRecordTrackService) registRecordVideoHandler:self];
}

- (ACCFilterTrackerSender *)trackSender
{
    if (!_trackSender) {
        _trackSender = [[ACCFilterTrackerSender alloc] init];
        @weakify(self);
        _trackSender.getPublishModelBlock = ^AWEVideoPublishViewModel * _Nonnull{
            @strongify(self);
            return self.repository;
        };
    }
    return _trackSender;
}

#pragma mark - ACCPanelViewDelegate

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController willDismissPanelView:(id<ACCPanelViewProtocol>)panelView
{
    if (panelView.identifier == ACCFilterContext) {
        self.viewContainer.isShowingPanel = NO;
        [self.viewContainer showItems:YES animated:YES];
    }
}

#pragma mark - ACCRecordVideoEventHandler

- (NSDictionary *)recordVideoEvent
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"filter_name"] = self.filterService.currentFilter.pinyinName ?: @"";
    params[@"filter_id"] = self.filterService.currentFilter.effectIdentifier ?: (self.filterService.hasDeselectionBeenMadeRecently ? @"-1" : @"");
    IESEffectModel *model = self.filterService.currentFilter;
    BOOL hasRatioCache = [self.filterService hasIndensityRatioForColorEffect:model];
    float filterValue = 1;
    if (hasRatioCache) {
        filterValue = [self.filterService indensityRatioCacheForColorEffect:model];
    }
    params[@"is_original_filter"] = hasRatioCache ? @0 : @1;
    params[@"filter_value"] = @(filterValue);
    
    return [params copy];
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarFilterContext];
    if (oldMode.modeId == ACCRecordModeLive && mode.modeId != ACCRecordModeLive) {
        [self.filterService applyFilterForCurrentCameraWithShowFilterName:NO sendManualMessage:NO];
    }
}

@end
