//
//  ACCBeautyFeatureComponent.m
//  Pods
//

#import <CreationKitComponents/ACCBeautyFeatureComponent+BeautyDelegate.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectKeys.h>
#import <CreationKitComponents/ACCFilterService.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreationKitInfra/UILabel+ACCAdditions.h>
#import <CreationKitComponents/ACCBeautyComponentConfigProtocol.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitComponents/ACCBeautyService.h>
#import <CreationKitInfra/ACCResponder.h>
#import <CreationKitComponents/ACCBeautyTrackerSender.h>

// sinkage
#import <CreationKitBeauty/AWEComposerBeautyEffectCacheManager.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectDownloader.h>
#import <CreationKitBeauty/ACCBeautyDefine.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectKeys.h>
#import <CreationKitComponents/ACCBeautyManager.h>
#import <CreationKitArch/ACCRecorderToolBarDefines.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCAccessibilityProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitRTProtocol/ACCCameraControlEvent.h>
#import <CreationKitComponents/ACCBeautyDataService.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectViewModel.h>
#import <CreationKitBeauty/CKBConfigKeyDefines.h>
#import <CreationKitComponents/ACCBeautyConfigKeyDefines.h>
#import <CreationKitInfra/UILabel+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitComponents/ACCFilterConfigKeyDefines.h>
#import <CreationKitBeauty/ACCBeautyBuildInDataSource.h>

@interface ACCBeautyFeatureComponent () <
AWEComposerBeautyDelegate,
ACCBeautyFeatureComponentViewDelegate,
ACCCameraLifeCircleEvent,
ACCAlgorithmEvent,
ACCPanelViewDelegate,
ACCCameraControlEvent,
ACCRecordSwitchModeServiceSubscriber>

@property (nonatomic, assign) BOOL genderDetected;
@property (nonatomic, assign) AWEComposerBeautyGender currentGender;
@property (nonatomic, copy) NSArray<AWEComposerBeautyEffectCategoryWrapper *> *categories;
@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCBeautyComponentConfigProtocol> beautyConfig;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, assign) Float64 identificationAsMaleThreshold;
@property (nonatomic, strong) ACCBeautyPanel *beautyPanel;

@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCFilterService> filterService;
@property (nonatomic, strong) id<ACCBeautyDataService> dataService;
@property (nonatomic, strong) id<ACCBeautyService> beautyService;
@property (nonatomic, assign) BOOL isShowingBeautyPanel;

@property (nonatomic, copy) dispatch_block_t didMountAction;
@property (nonatomic, strong) RACSubject *modernBeautyButtonClickedSignal;
@property (nonatomic, strong) RACSubject *beautyPanelDismissSignal;
@property (nonatomic, strong) RACSubject *composerBeautyDidFinishSlidingSignal;

@property (nonatomic, strong, readonly) AWEComposerBeautyEffectViewModel *composerEffectObj;
@property (nonatomic, strong) ACCBeautyTrackerSender *trackSender;
@end

@implementation ACCBeautyFeatureComponent
@synthesize enableSwitchBeauty = _enableSwitchBeauty;

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer);
IESAutoInject(ACCBaseServiceProvider(), beautyConfig, ACCBeautyComponentConfigProtocol)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, filterService, ACCFilterService)
IESAutoInject(self.serviceProvider, dataService, ACCBeautyDataService)
IESAutoInject(self.serviceProvider, beautyService, ACCBeautyService)

#pragma mark - ACCComponentProtocol
- (instancetype)initWithContext:(id<IESServiceProvider>)context
{
    self = [super initWithContext:context];
    if (self) {
        _currentGender = AWEComposerBeautyGenderWomen;
        _identificationAsMaleThreshold = ACCConfigDouble(kConfigDouble_identification_as_male_threshold);
    }
    return self;
}

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
    [[ACCBeautyManager defaultManager] resetWhenQuitRecoder];
}

- (NSArray<ACCServiceBinding *> *)serviceBindingArray {
    return @[
        ACCCreateServiceBinding(@protocol(ACCBeautyTrackSenderProtocol), self.trackSender)
    ];
}

- (void)componentDidMount
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    
    if (self.didMountAction) {
        self.didMountAction();
        self.didMountAction = nil;
    }
    
    [self bindViewModel];

    // expose beauty interface to external business
    [[AWEComposerBeautyEffectCacheManager sharedManager] updateWithBeautyEffectViewModel:self.composerEffectObj];

    [self p_observerNotification];
    [self.viewContainer.panelViewController registerObserver:self];
}

- (void)componentDidUnmount {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [self.viewContainer.panelViewController unregisterObserver:self];
    
    [_modernBeautyButtonClickedSignal sendCompleted];
    [_beautyPanelDismissSignal sendCompleted];
    [_composerBeautyDidFinishSlidingSignal sendCompleted];
}

- (void)componentWillAppear
{
    // mark:TT only
    if ([self.beautyConfig enableSetBeautySwitchButton]) {
        self.componentView.isBeautySwitchButtonSelected = self.beautyService.beautyOn;
    }
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    if ([ACCResponder topViewController] == self.controller.root && self.cameraService.cameraHasInit) {
        [self.cameraService.algorithm forceDetectBuffer:5];
    }
}

- (BOOL)enableBeautyEffectSwitch
{
    AWEComposerBeautyEffectCategoryWrapper *currentCategory = self.beautyPanel.composerVM.currentCategory;
    BOOL isOnShootPage = ![self.dataService.enterFrom isEqualToString:@"video_edit_page"];
    return isOnShootPage && currentCategory.isSwitchEnabled && ACCConfigBool(kConfigBool_studio_enable_record_beauty_switch);
}

#pragma mark -

- (void)bindViewModel
{
    @weakify(self);
    if (!ACCConfigBool(kConfigBool_studio_record_open_optimize)) {
        [[[[RACObserve(self.cameraService.cameraControl, currentCameraPosition) distinctUntilChanged] skip:1] deliverOnMainThread] subscribeNext:^(NSNumber * _Nullable x) {
            @strongify(self);
            [self p_handleCurrentCameraPosition];
        }];
    }
}

- (void)p_observerNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEffectDownloadStatusChange:) name:kAWEComposerBeautyEffectUpdateNotification object:nil];
}

- (void)p_handleCurrentCameraPosition
{
    // If you are currently in the mini-game mode,
    // when you switch between the front and rear cameras, no more filters are set
    if (!self.cameraService.cameraHasInit) {
        return;
    }
    
    if (self.dataService.gameType != ACCGameTypeCatchFruit) {
        if (![self hasDetectGender] || ![self hasAppliedBeautyEffects] || (self.useBeautySwitchButton && !self.beautyService.beautyOn)) {
            [self.filterService applyFilterForCurrentCameraWithShowFilterName:NO sendManualMessage:NO];
        }
    }
    
    if (self.dataService.gameType != ACCGameTypeCatchFruit) {
        [self.beautyService clearAllComposerBeautyEffects];
        [[self composerEffectObj] updateWithGender:self.currentGender cameraPosition:[self p_currentCameraPosition]];
        [self.beautyPanel clearSelection];
        [self p_reapplySavedBeautyConfigAndEnableExternalAlgorithm];
    }

    [self.cameraService.algorithm enableEffectExternalAlgorithm:YES];
    [self.cameraService.algorithm forceDetectBuffer:5];
}

- (void)updateAvailabilityForEffects:(ACCDidApplyEffectPack _Nullable)pack
{
    if (self.isMounted) {
        [self p_updateAvailabilityForEffects:pack];
    } else {
        @weakify(self);
        self.didMountAction = ^{
            @strongify(self);
            [self p_updateAvailabilityForEffects:pack];
        };
    }
}

- (void)p_updateAvailabilityForEffects:(ACCDidApplyEffectPack _Nullable)pack
{
    NSNumber *success = pack.second;
    if (success.boolValue) {

        NSArray<AWEComposerBeautyEffectCategoryWrapper *> *filteredCategories = self.beautyPanel.composerVM.filteredCategories;
        NSMutableArray *targetCategories = [NSMutableArray array];

        for (AWEComposerBeautyEffectCategoryWrapper *category in filteredCategories) {
            if (category.isPrimaryCategory) {
                [targetCategories acc_addObjectsFromArray:category.childCategories];
            } else {
                [targetCategories acc_addObject:category];
            }
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.beautyService updateAvailabilityForEffectsInCategories:targetCategories];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.beautyPanel reloadCurrentPanel];
            });
        });
    }
}

- (UILabel *)p_createButtonLabel:(NSString *)text
{
    UILabel *label = [[UILabel alloc] acc_initWithFont:[ACCFont() acc_boldSystemFontOfSize:10]
                                             textColor:ACCResourceColor(ACCUIColorConstTextInverse)
                                                  text:text];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 2;
    [label acc_addShadowWithShadowColor:ACCResourceColor(ACCUIColorConstLinePrimary) shadowOffset:CGSizeMake(0, 1) shadowRadius:2];
    if ([ACCAccessibility() respondsToSelector:@selector(setAccessibilityProperty:isAccessibilityElement:)]) {
        [ACCAccessibility() setAccessibilityProperty:label isAccessibilityElement:NO];
    }
    return label;
}

#pragma mark - public method
- (void)applyEffectsWhenTurnOffPureMode {
    if (![self hasDetectGender] || ![self hasAppliedBeautyEffects]) {
        [self.filterService applyFilterForCurrentCameraWithShowFilterName:NO sendManualMessage:NO];
    }
    [self p_reapplySavedBeautyConfigAndEnableExternalAlgorithm];
    AWELogToolInfo2(@"effect", AWELogToolTagRecord, @"publish parallel, recover beauty");
}

#pragma mark - private method
- (void)switchBeauty
{
    self.beautyService.beautyOn = !self.beautyService.beautyOn;
    if (self.beautyService.beautyOn) {
        // TT bugfix
        [self.beautyService clearAllComposerBeautyEffects];
        [self.beautyPanel.composerVM resetAllComposerBeautyEffects];
        [self p_applyAllComposerBeautyEffects];
    } else {
        [self.beautyService clearAllComposerBeautyEffects];
    }
}

- (BOOL)hasAppliedBeautyEffects
{
    if (!ACC_isEmptyArray([[self composerEffectObj] currentEffects])) {
        return YES;
    }
    return NO;
}

- (BOOL)hasDetectGender
{
    return self.genderDetected;
}

#pragma mark - apply saved composer beauty effect

- (BOOL)p_checkIfCanApply:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    return !effectWrapper.categoryWrapper.isSwitchEnabled || [self.composerEffectObj.cacheObj isCategorySwitchOn:effectWrapper.categoryWrapper];
}

- (NSArray<AWEComposerBeautyEffectWrapper *> *)p_filterIfNeededWithEffectWrappers:(NSArray<AWEComposerBeautyEffectWrapper *> *)effectWrappers
{
    BOOL isOnShootPage = ![self.dataService.enterFrom isEqualToString:@"video_edit_page"];
    BOOL enableBeautySwitch = isOnShootPage && ACCConfigBool(kConfigBool_studio_enable_record_beauty_switch);

    if (ACC_isEmptyArray(effectWrappers) || !enableBeautySwitch) {
        return effectWrappers;
    }

    NSMutableArray *filteredEffectWrappers = [NSMutableArray array];
    // If the switch is turned off, all beauty effects are filtered out,
    // and the beauty category has a switch judgment attribute
    for (AWEComposerBeautyEffectWrapper *effectWrapper in effectWrappers) {
        AWEComposerBeautyEffectWrapper *parentEffect = effectWrapper.parentEffect ?: effectWrapper;
        BOOL unfiltered = [self p_checkIfCanApply:parentEffect];
        if (unfiltered) {
            [filteredEffectWrappers acc_addObject:effectWrapper];
        }
    }
    
    return [filteredEffectWrappers copy];
}

- (void)p_applyAllComposerBeautyEffects
{
    NSArray<AWEComposerBeautyEffectWrapper *> *effectsBeforeFilter = [self p_filterIfNeededWithEffectWrappers:[self composerEffectObj].effectsBeforeFilter];
    if (!ACC_isEmptyArray(effectsBeforeFilter)) {
        [self.beautyService applyComposerBeautyEffects:effectsBeforeFilter];
    }
    
    NSArray<AWEComposerBeautyEffectWrapper *> *effectsAfterFilter = [self p_filterIfNeededWithEffectWrappers:[self composerEffectObj].effectsAfterFilter];
    if (!ACC_isEmptyArray(effectsAfterFilter)) {
        [self.beautyService applyComposerBeautyEffects:effectsAfterFilter];
    }
    
    // bring filter to font, here we should not reapply filter, because user may had applyed an effect with filter.
    // if we reapply, will cover the current filter.
    [[self composerEffectObj] bringFilterToFront];
}

- (void)p_applyAllComposerBeautyEffectsAndFilter
{
    NSArray<AWEComposerBeautyEffectWrapper *> *effectsBeforeFilter = [self p_filterIfNeededWithEffectWrappers:[self composerEffectObj].effectsBeforeFilter];
    if (!ACC_isEmptyArray(effectsBeforeFilter)) {
        [self.beautyService applyComposerBeautyEffects:effectsBeforeFilter];
    }
    if (ACCConfigBool(kConfigBool_add_last_used_filter)) {
        NSString *usedFilter = [[self composerEffectObj].cacheObj cachedFilterID];
        [self.filterService applyFilterWithFilterID:usedFilter];
    }

    NSArray<AWEComposerBeautyEffectWrapper *> *effectsAfterFilter = [self p_filterIfNeededWithEffectWrappers:[self composerEffectObj].effectsAfterFilter];
    if (!ACC_isEmptyArray(effectsAfterFilter)) {
        [self.beautyService applyComposerBeautyEffects:effectsAfterFilter];
    }
}

- (void)p_reapplySavedBeautyConfigAndEnableExternalAlgorithm
{
    if ([self.beautyConfig enableClearAllBeautyEffects]) {
        if (self.beautyService.beautyOn) {
            [self p_applyAllComposerBeautyEffectsAndFilter];
        } else {
            [self.beautyService clearAllComposerBeautyEffects];
        }
    } else {
        [self p_applyAllComposerBeautyEffectsAndFilter];
    }
}

#pragma mark - ACCAlgorithmEvent

- (void)onDetectMaleChanged:(BOOL)hasDetectMale {
    [[ACCBeautyManager defaultManager] setHasDetectMale:hasDetectMale];
    self.cameraService.beauty.acc_maleDetected = hasDetectMale;
    
    //for XS project, Hogwarts lib receives the notification
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ACCAlgorithmCallbackComponentDidDetectMaleNotification" object:@(hasDetectMale)];
}

- (void)onExternalAlgorithmCallback:(NSArray<IESMMAlgorithmResultData *> *)result type:(IESMMAlgorithm)type {
    if (self.switchModeService.currentRecordMode.modeId == ACCRecordModeLive) {
        return;
    }
    
    if ((type != self.cameraService.algorithm.externalAlgorithm) || result.count == 0) {
        return;
    }
    
    BOOL hasBoy = NO;
    for (IESMMAlgorithmResultData *data in result) {
        if ([data isMemberOfClass:[IESMMFaceAttributeDetectResultData class]]) {
            IESMMFaceAttributeDetectResultData *resultData = (IESMMFaceAttributeDetectResultData *)data;
            if (resultData.boyProb > self.identificationAsMaleThreshold) {
                hasBoy = YES;
                break;
            }
        }
    }

    self.cameraService.algorithm.hasDetectMale = hasBoy;
    
    if (!self.genderDetected) {
        self.genderDetected = YES;
        AWEComposerBeautyGender gender = self.cameraService.algorithm.hasDetectMale ? AWEComposerBeautyGenderMen : AWEComposerBeautyGenderWomen;
        if ([[self composerEffectObj].cacheObj shouldAlwaysRecognizeAsFemale]) {
            gender = AWEComposerBeautyGenderWomen;
        } else {
            [[self composerEffectObj].cacheObj updateRecognizedGender:gender];
        }
        if (gender != self.currentGender) {
            self.currentGender = gender;
        }
        // Update latest gender, this is for filter function in edit beauty panel
        self.dataService.gender = gender;
        [self handleDataAndApplyBeauty];
    }
}

#pragma mark - ACCCameraLifeCircleEvent

- (void)onCameraDidStartRender:(id<ACCCameraService>)cameraService {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.filterService defaultFilterManagerUpdateEffectFilters];
    });

    if (ACCConfigBool(kConfigBool_studio_record_open_optimize)) {
        [self p_handleCurrentCameraPosition];
        [self.cameraService.cameraControl addSubscriber:self];
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (![self hasDetectGender] || ![self hasAppliedBeautyEffects] || (self.useBeautySwitchButton && !self.beautyService.beautyOn)) {
            [self.filterService applyFilterForCurrentCameraWithShowFilterName:NO sendManualMessage:NO];
        }
    });

    acc_dispatch_main_async_safe(^{
        if (ACCConfigBool(kConfigBool_studio_record_beauty_primary_panel_enable)) {
            [self.beautyPanel.composerVM enablePrimaryPanel];
        }
        if (!ACC_isEmptyArray(self.categories)) {
            [self p_updateDataSourceWithCompletion:nil];
        } else {
            [self.beautyPanel.composerVM fetchBeautyEffects];
        }
    });
}

- (void)p_handleCategoriesLoaded:(NSArray <AWEComposerBeautyEffectCategoryWrapper *> *)categories
{
    self.categories = categories;
    [self handleDataAndApplyBeauty];
}

- (void)currentCameraPositionChanged:(AVCaptureDevicePosition)currentPosition
{
    [self p_handleCurrentCameraPosition];
}

#pragma mark - Update DataSource

- (void)p_updateDataSourceWithCompletion:(void (^)(void))completion
{
    AWEComposerBeautyCameraPosition cameraPosition = [self p_currentCameraPosition];
    @weakify(self);
    [[self composerEffectObj] filterCategories:self.categories
                                                           withGender:self.currentGender
                                                       cameraPosition:cameraPosition
                                                           completion:^(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *categories, BOOL success) {
        @strongify(self);
        if (ACC_isEmptyArray(categories)) {
            NSArray *buildInCategories = [self.beautyPanel.composerVM.dataSource buildInCategories];
            [self.beautyPanel.composerVM setFilteredCategories:buildInCategories];
            [[self composerEffectObj] updateAppliedEffectsWithCategories:buildInCategories];
            [[self composerEffectObj] updateAvailableEffectsWithCategories:buildInCategories];
        } else {
            [self.beautyPanel.composerVM setFilteredCategories:categories];
        }

        // update currentCategory && reloadPanel
        [self.beautyPanel updateCurrentComposerCategory];

        acc_dispatch_main_async_safe(^{
            ACCBLOCK_INVOKE(completion);
        });
    }];
}

- (AWEComposerBeautyCameraPosition)p_currentCameraPosition
{
    AVCaptureDevicePosition position = self.cameraService.cameraControl.currentCameraPosition;
    AWEComposerBeautyCameraPosition cameraPosition = AWEComposerBeautyCameraPositionBack;
    if (position == AVCaptureDevicePositionFront) {
        cameraPosition = AWEComposerBeautyCameraPositionFront;
    }
    return cameraPosition;
}

- (void)handleDataAndApplyBeauty
{
    NSMutableSet<AWEComposerBeautyEffectWrapper *> *prevEffects = [NSMutableSet setWithArray:[self.composerEffectObj currentEffects]];
    @weakify(self)
    [self p_updateDataSourceWithCompletion:^{
        @strongify(self)

        // only remove the old and not use beauty effects,
        // prevent beauty effect jump
        NSSet<AWEComposerBeautyEffectWrapper *> *latestEffects = [NSSet setWithArray:[self.composerEffectObj currentEffects]];
        [prevEffects minusSet:latestEffects];
        [self.beautyService clearComposerBeautyEffects:[prevEffects allObjects]];

        [self p_reapplySavedBeautyConfigAndEnableExternalAlgorithm];
    }];
}

#pragma mark - ACCBeautyFeatureComponentViewDelegate

- (void)beautySwitchButtonClicked:(UIButton *)sender
{
    if (self.cameraService.recorder.isRecording) {
        return;
    }
    
    if (![self.enableSwitchBeauty evaluate]) {
        [ACCToast() show:ACCLocalizedCurrentString(@"cannot_use_beauty_mode_with_this_filter")];
        return;
    }

    BOOL currentSenderSelected = !sender.selected;
    self.componentView.isBeautySwitchButtonSelected = currentSenderSelected;
    [ACCToast() show: currentSenderSelected ?  ACCLocalizedCurrentString(@"com_mig_beauty_mode_on") : ACCLocalizedCurrentString(@"com_mig_beauty_mode_off")];
    [self switchBeauty];
    
    [self.trackSender sendBeautySwitchButtonClickedSignal:sender.selected];
    
    // selected must be assigned a new value after the UI operation
    // fix the icon in beauty switch button does not change when selected
    sender.selected = currentSenderSelected;
}

- (void)modernBeautyButtonClicked:(UIButton *)sender
{
    if (self.cameraService.recorder.isRecording) {
        return;
    }
    
    [self.viewContainer showItems:NO animated:YES];
    self.viewContainer.isShowingPanel = YES;
    [self.beautyPanel showPanel];
    [self.modernBeautyButtonClickedSignal sendNext:nil];
    
    [self.trackSender sendModernBeautyButtonClickedSignal];
}

- (void)beautyPanelDisplay
{
    self.isShowingBeautyPanel = YES;
}

- (void)beautyPanelDismiss
{
    self.isShowingBeautyPanel = NO;
    self.viewContainer.isShowingPanel = NO;
    [self.viewContainer showItems:YES animated:YES];
    [self.beautyPanelDismissSignal sendNext:nil];
}

- (void)didFinishSlidingWithValue:(CGFloat)value
                        forEffect:(AWEComposerBeautyEffectWrapper *)effect
{
    [self.composerBeautyDidFinishSlidingSignal sendNext:RACTuplePack(@(value), effect)];
}


#pragma mark - Primary - Delegate

// primary
- (void)composerBeautyPanelDidSelectPrimaryCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
                                       lastCategory:(AWEComposerBeautyEffectCategoryWrapper *)lastCategoryWrapper
                                     parentCategory:(AWEComposerBeautyEffectCategoryWrapper *)parentCategoryWrapper
{
    NSMutableArray *currentEffects = [NSMutableArray arrayWithArray:self.composerEffectObj.currentEffects];

    // remove
    NSMutableArray *toRemoveEffects = [NSMutableArray array];
    for (AWEComposerBeautyEffectWrapper *effect in lastCategoryWrapper.effects) {
        if (!effect.isEffectSet) {
            [toRemoveEffects acc_addObject:effect];
        } else {
            [toRemoveEffects acc_addObjectsFromArray:effect.childEffects];
        }
    }
    [currentEffects removeObjectsInArray:toRemoveEffects];

    // apply
    NSMutableArray *toApplyEffects = [NSMutableArray array];
    for (AWEComposerBeautyEffectWrapper *effect in categoryWrapper.effects) {
        if (!effect.isEffectSet) {
            [toApplyEffects acc_addObject:effect];
        } else {
            AWEComposerBeautyEffectWrapper *appliedEffect = effect.appliedChildEffect;
            [toApplyEffects acc_addObject:appliedEffect];
        }
    }
    [currentEffects acc_addObjectsFromArray:toApplyEffects];

    [self.beautyService replaceComposerBeautyWithNewEffects:currentEffects oldEffects:self.composerEffectObj.currentEffects];

}


- (void)composerBeautyPanelDidTapResetPrimaryCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
{
    if (categoryWrapper) {
        // those effects value were first set to default value before this delegate function being called
        NSMutableArray *toApplyEffects = [NSMutableArray array];
        for (AWEComposerBeautyEffectWrapper *effect in categoryWrapper.effects) {
            if (!effect.isEffectSet) {
                [toApplyEffects acc_addObject:effect];
            } else {
                AWEComposerBeautyEffectWrapper *appliedEffect = effect.appliedChildEffect;
                [toApplyEffects acc_addObject:appliedEffect];
            }
        }

        [self.beautyService applyComposerBeautyEffects:toApplyEffects];
    }
}

- (BOOL)p_currentPrimaryCategoryDownloaded
{
    AWEComposerBeautyEffectCategoryWrapper *category = self.beautyPanel.composerVM.currentCategory;
    if (category.isPrimaryCategory) {
        AWEComposerBeautyEffectCategoryWrapper *advancedDownloadedCategory = category.selectedChildCategory ?: category.defaultChildCategory;
        for (AWEComposerBeautyEffectWrapper *effect in advancedDownloadedCategory.effects) {
            if (effect.isEffectSet) {
                for (AWEComposerBeautyEffectWrapper *child in effect.childEffects) {
                    AWEEffectDownloadStatus downloadStatus = [[AWEComposerBeautyEffectDownloader defaultDownloader] downloadStatusOfEffect:child];
                    if (downloadStatus != AWEEffectDownloadStatusDownloaded) {
                        return NO;
                    }
                }
            } else {
                AWEEffectDownloadStatus downloadStatus = [[AWEComposerBeautyEffectDownloader defaultDownloader] downloadStatusOfEffect:effect];
                if (downloadStatus != AWEEffectDownloadStatusDownloaded) {
                    return NO;
                }
            }
        }
        return YES;
    }
    return NO;
}

#pragma mark - getter

- (ACCBeautyFeatureComponentView *)componentView
{
    if (!_componentView) {
        _componentView = [[ACCBeautyFeatureComponentView alloc] initWithModernBeautyButtonLabel:[self p_createButtonLabel:ACCConfigString(kConfigString_beauty_button_title)]
                                                                        beautySwitchButtonLabel:[self p_createButtonLabel:ACCLocalizedCurrentString(@"com_mig_beauty")]
                                                                                     referExtra:self.dataService.referExtra];
        _componentView.delegate = self;
    
        _componentView.beautyPanel = self.beautyPanel;
    }
    return _componentView;
}

- (ACCBeautyPanel *)beautyPanel
{
    if (!_beautyPanel) {
        ACCBeautyPanel *beautyPanel = [[ACCBeautyPanel alloc] initWithViewModel:self.beautyService.beautyPanelViewModel
                                                                effectViewModel:self.composerEffectObj
                                                                   publishModel:self.repository];
        beautyPanel.dataService = self.dataService;
        beautyPanel.composerVMDataSource = IESAutoInline(self.serviceProvider, ACCBeautyBuildInDataSource);
        beautyPanel.composerBeautyDelegate = self;
        beautyPanel.panelViewController = self.viewContainer.panelViewController;
        
        @weakify(self);
        beautyPanel.fetchComposerDataBlock = ^(NSArray<AWEComposerBeautyEffectCategoryWrapper *> * _Nullable categories) {
            @strongify(self);
            [self p_handleCategoriesLoaded:categories];
        };
        _beautyPanel = beautyPanel;
    }
    return _beautyPanel;
}

- (ACCBeautyTrackerSender *)trackSender
{
    if (!_trackSender) {
        _trackSender = [[ACCBeautyTrackerSender alloc] init];
        @weakify(self);
        _trackSender.getPublishModelBlock = ^AWEVideoPublishViewModel * _Nonnull{
            @strongify(self);
            return self.repository;
        };
    }
    return _trackSender;
}

#pragma mark - setter
- (AWEComposerBeautyEffectViewModel *)composerEffectObj
{
    return self.beautyService.effectViewModel;
}

#pragma mark - AWEComposerBeautyDelegate

- (void)handleEffectDownloadStatusChange:(NSNotification *)notification
{
    if (![notification.object isKindOfClass:[AWEComposerBeautyEffectWrapper class]]) {
        return;
    }

    @weakify(self);
    if ([self p_currentPrimaryCategoryDownloaded]) {
        acc_dispatch_main_async_safe(^{
            @strongify(self);
            [self p_reapplySavedBeautyConfigAndEnableExternalAlgorithm];
        });
    }
}

- (void)composerBeautyViewControllerDidSwitch:(BOOL)isOn isManually:(BOOL)isManually
{
    [self.trackSender sendComposerBeautyViewControllerDidSwitchSignal:isOn isManually:isManually];
    
    if (isOn == self.beautyService.beautyOn) {
        return;
    }
    self.beautyService.beautyOn = isOn;
    if (self.beautyService.beautyOn) {
        [self p_applyAllComposerBeautyEffects];
    } else {
        if ([self enableBeautyEffectSwitch]) {
            // delete all beauty effects
            [self.beautyService clearComposerBeautyEffects:self.beautyPanel.composerVM.currentCategory.effects];
        } else {
            [self.beautyService clearAllComposerBeautyEffects];
        }
    }
}

- (void)composerBeautyViewControllerWillReset
{
    [self.beautyService clearAllComposerBeautyEffects];
}

- (void)composerBeautyViewControllerDidReset
{
    [self p_applyAllComposerBeautyEffects];
}

- (BOOL)useBeautySwitchButton
{
    return [self.beautyConfig useBeautySwitch];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.cameraService addSubscriber:self];
    [self.cameraService.algorithm addSubscriber:self];
    [self.switchModeService addSubscriber:self];
}

#pragma mark - ACCPanelViewDelegate
- (void)panelViewController:(id<ACCPanelViewController>)panelViewController
          willShowPanelView:(id<ACCPanelViewProtocol>)panelView
{
    if ([panelView identifier] == self.beautyPanel.beautyPanelView.identifier) {
        [self beautyPanelDisplay];
    }
}

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController
        didDismissPanelView:(id<ACCPanelViewProtocol>)panelView
{
    if ([panelView identifier] == self.beautyPanel.beautyPanelView.identifier) {
        [self beautyPanelDismiss];
    }
}
#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode
                               oldMode:(ACCRecordMode *)oldMode
{
    if (oldMode.modeId == ACCRecordModeLive && mode.modeId != ACCRecordModeLive) {
        [self.composerEffectObj updateWithGender:self.currentGender cameraPosition:[self p_currentCameraPosition]];
        [self p_reapplySavedBeautyConfigAndEnableExternalAlgorithm];
        [self.beautyPanel reloadCurrentPanel];
    } else if (mode.modeId == ACCRecordModeLive) {
        [self.beautyService clearAllComposerBeautyEffects];
    }
    
    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarModernBeautyContext];
}


#pragma mark - @synthesize

@synthesize currentGender = _currentGender;
@synthesize componentView = _componentView;

- (ACCGroupedPredicate *)enableSwitchBeauty
{
    if (!_enableSwitchBeauty) {
        _enableSwitchBeauty = [[ACCGroupedPredicate alloc] init];
    }
    return _enableSwitchBeauty;
}

- (RACSubject *)modernBeautyButtonClickedSignal
{
    if (!_modernBeautyButtonClickedSignal) {
        _modernBeautyButtonClickedSignal = [RACSubject subject];
    }
    return _modernBeautyButtonClickedSignal;
}

- (RACSubject *)beautyPanelDismissSignal
{
    if (!_beautyPanelDismissSignal) {
        _beautyPanelDismissSignal = [RACSubject subject];
    }
    return _beautyPanelDismissSignal;
}

- (RACSubject *)composerBeautyDidFinishSlidingSignal
{
    if (!_composerBeautyDidFinishSlidingSignal) {
        _composerBeautyDidFinishSlidingSignal = [RACSubject subject];
    }
    return _composerBeautyDidFinishSlidingSignal;
}
@end
