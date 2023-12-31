//
//  AWETabFilterViewController.m
//  AWEStudio
//
//Created by Li Yansong on July 27, 2018
//  Copyright  ©  Byedance. All rights reserved, 2018
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWETabFilterViewController.h"
#import "AWETabControlledCollectionWrapperView.h"
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitArch/AWEColorFilterDataManager.h>
#import "AWECameraFilterConfiguration.h"
#import "AWEFilterBoxView.h"
#import <CreativeKit/ACCAccessibilityProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "ACCOldFilterDefaultUIConfiguration.h"
#import <CreationKitInfra/AWESlider.h>
#import <CreationKitInfra/ACCRecordFilterDefines.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>
#import "ACCFilterDataService.h"

#define kAWETabFilterPanelPadding 6
static const CGFloat kAWERecordFilterContainerViewHeight = 226;

ACCContextId(ACCFilterContext)

@interface AWETabFilterViewController () <AWETabControlledCollectionWrapperViewDelegate, AWESliderDelegate, UIGestureRecognizerDelegate, UICollectionViewDelegate>

@property (nonatomic) AWETabControlledCollectionWrapperView *tabFilterView;
@property (nonatomic, strong, readwrite) UIView *containerView;
@property (nonatomic, strong) UIView *gestureRecognizerView;

@property(nonatomic) AWECameraFilterConfiguration *filterConfiguration;
@property (nonatomic, strong) id<ACCOldFilterUIConfigurationProtocol> uiConfig;

@property (nonatomic) BOOL shownFilterView;
@property (nonatomic) BOOL hasReportedSelectFilterOnReloadData;
@property (nonatomic, assign) BOOL hasChangeBeautyValue;
@property (nonatomic, assign) BOOL shouldTrackClickBeautifyTab;

@property (nonatomic, strong) AWEFilterBoxView *filterBoxView; //Filter box management view
@property (nonatomic, strong) AWESlider *slider;
@property (nonatomic, strong) UIView *sliderContainerView;
@property (nonatomic, strong) UIView *sliderIndicatorView;

@property (nonatomic, strong) IESEffectModel *incomingEffect;
@property (nonatomic, assign) BOOL incomingEffectFromBox;
@property (nonatomic, assign) BOOL isDataLoadedAfterAppeared;

@end

@implementation AWETabFilterViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithFilterConfiguration:(AWECameraFilterConfiguration *)filterConfiguration
{
    self = [super init];
    if (self) {
        _filterConfiguration = filterConfiguration;
        _shownFilterView = YES;
        _filterManager = [AWEColorFilterDataManager defaultManager];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onEffectListUpdated:) name:kAWEStudioColorFilterListUpdateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onEffectUpdated:) name:kAWEStudioColorFilterUpdateNotification object:nil];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([ACCAccessibility() respondsToSelector:@selector(postAccessibilityNotification:argument:)]) {
        [ACCAccessibility() postAccessibilityNotification:UIAccessibilityScreenChangedNotification argument:self.gestureRecognizerView];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.isDataLoadedAfterAppeared = NO;
    self.tabFilterView.filtersArray = [[self.filterManager allAggregatedEffects] copy];
    [self.filterManager updateEffectFilters];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    // use default ui config if outside not config
    if (!self.uiConfig) {
        [self updateUIConfig:[[ACCOldFilterDefaultUIConfiguration alloc] init]];
    }
    
    [self.view addSubview:self.containerView];
    CGFloat containerHeight = kAWERecordFilterContainerViewHeight + ACC_IPHONE_X_BOTTOM_OFFSET;

    ACCMasMaker(self.containerView, {
        make.leading.trailing.bottom.equalTo(self.view);
        make.height.equalTo(@(containerHeight));
    });
//    [self.containerView acc_addBlurEffect];
    self.containerView.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainer3);

    //Action Container
    UIView *actionContainer = [[UIView alloc] init];
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_onClearBackgroundPress:)];
    [actionContainer addGestureRecognizer:gestureRecognizer];
    [self.view addSubview:actionContainer];
    ACCMasMaker(actionContainer, {
        make.leading.trailing.top.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(- containerHeight - 2 * kAWETabFilterPanelPadding);
    });
    if ([ACCAccessibility() respondsToSelector:@selector(enableAccessibility:traits:label:)]) {
        [ACCAccessibility() enableAccessibility:actionContainer
                                         traits:UIAccessibilityTraitButton
                                          label:ACCLocalizedString(@"off", @"off")];
    }
    if ([ACCAccessibility() respondsToSelector:@selector(setAccessibilityProperty:accessibilityViewIsModal:)]) {
        [ACCAccessibility() setAccessibilityProperty:self.view accessibilityViewIsModal:YES];
    }
    self.gestureRecognizerView = actionContainer;
    
    [self.containerView addSubview:self.tabFilterView];
    ACCMasMaker(self.tabFilterView, {
        make.leading.trailing.top.equalTo(self.containerView);
        make.height.equalTo(@(kAWERecordFilterContainerViewHeight));
    });

    self.tabFilterView.backgroundColor = [UIColor clearColor];
    
    if ([self enableFilterIndensity]) {
        [self.view addSubview:self.sliderContainerView];
        ACCMasMaker(self.sliderContainerView, {
            make.leading.trailing.equalTo(self.view);
            make.bottom.equalTo(self.containerView.mas_top);
            make.height.equalTo(@(40));
        });

        [self.sliderContainerView addSubview:self.slider];
        ACCMasMaker(self.slider, {
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                make.left.equalTo(self.sliderContainerView).offset(16);
                make.right.equalTo(self.sliderContainerView).offset(-16);
            } else {
                make.width.equalTo(self.sliderContainerView).multipliedBy(3.0/5.0);
                make.centerX.equalTo(self.sliderContainerView);
            }
            make.top.equalTo(self.sliderContainerView).offset(1.5);
            make.height.equalTo(@(20));
        });

        [self.slider addSubview:self.sliderIndicatorView];
        ACCMasMaker(self.sliderIndicatorView, {
            make.centerX.equalTo(self.slider).multipliedBy(1.6);
            make.centerY.equalTo(self.slider);
            make.height.width.equalTo(@(5));
        });
        [self applyFilterAndUpdateUiWithFilterModel:self.selectedFilter];
    }
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    CGRect containerViewMaskFrame = CGRectMake(0, 0, ACC_SCREEN_WIDTH, kAWERecordFilterContainerViewHeight + ACC_IPHONE_X_BOTTOM_OFFSET);
    CGRect filterBoxViewMaskFrame = CGRectMake(0, 0, ACC_SCREEN_WIDTH, self.view.acc_height * 0.6);
    self.containerView.layer.mask = [self topRoundCornerShapeLayerWithFrame:containerViewMaskFrame];
    self.filterBoxView.layer.mask = [self topRoundCornerShapeLayerWithFrame:filterBoxViewMaskFrame];
}

#pragma mark - iPhone X Adaption

- (void)viewSafeAreaInsetsDidChange
{
    [super viewSafeAreaInsetsDidChange];
    
    self.containerView.acc_height = kAWERecordFilterContainerViewHeight + self.view.safeAreaInsets.bottom;
    self.tabFilterView.acc_top = self.containerView.acc_height - kAWERecordFilterContainerViewHeight - self.view.safeAreaInsets.bottom;
}

#pragma mark - Public

- (void)showOnViewController:(UIViewController *)controller {
    [self p_showOnViewController:controller animated:YES duration:0.25];
}

- (void)showOnView:(UIView *)view
{
    [self p_showOnView:view fromOffset:CGPointMake(0, view.acc_height) animated:YES duration:0.25];
}

@dynamic selectedFilter;
- (IESEffectModel *)selectedFilter {
    return self.tabFilterView.selectedFilter;
}

- (void)setSelectedFilter:(IESEffectModel *)selectedFilter {
    self.tabFilterView.selectedFilter = selectedFilter;
    [self configSliderValueWithFilter:selectedFilter];
}

- (void)setSelectedFilterIntensityRatio:(NSNumber *)selectedFilterIntensityRatio
{
    _selectedFilterIntensityRatio = selectedFilterIntensityRatio;
    [self configSliderValueWithFilter:self.selectedFilter];
}

- (void)selectFilterByCode:(IESEffectModel *)filter {
    [self.tabFilterView selectFilterByCode:filter scrolling:YES];
    [self configSliderValueWithFilter:filter];
   
}

- (void)configSliderValueWithFilter:(IESEffectModel *)selectedFilter {
    if ([self enableFilterIndensity]) {
        [self applyFilterAndUpdateUiWithFilterModel:selectedFilter];
    }
}

- (void)reloadData  {
    [self.tabFilterView reloadDataAndScrollingToSelected:!self.isDataLoadedAfterAppeared];
    self.isDataLoadedAfterAppeared = YES;
}

- (NSString *)tabNameForFilter:(IESEffectModel *)filter {
    return [self.tabFilterView tabNameForFilter:filter];
}

- (void)updateUIConfig:(id<ACCOldFilterUIConfigurationProtocol>)config {
    self.uiConfig = config;
    [self.tabFilterView updateUIConfig:config];
    self.slider.minimumTrackTintColor = [config sliderMinimumTrackTintColor];
}


#pragma mark - Protocol
#pragma mark AWETabControlledCollectionWrapperViewDelegate

- (BOOL)shouldSelectFilter:(IESEffectModel *)effect
{
    [self trackAdjustFilter];
    return [self selectFilter:effect fromBox:NO];
}

- (BOOL)selectFilter:(IESEffectModel *)effect fromBox:(BOOL)fromBox {
    AWEEffectDownloadStatus status = [self.filterManager downloadStatusOfEffect:effect];
    if (status == AWEEffectDownloadStatusDownloaded) {
        // apply effect
        [self.tabFilterView selectFilterByCode:effect scrolling:YES];
        [self applyFilter:effect fromBox:fromBox];
        return YES;
    } else if (status == AWEEffectDownloadStatusDownloading) {
        // will apply effect when it's downloaded
        self.incomingEffect = effect;
        self.incomingEffectFromBox = fromBox;
        [self.tabFilterView scrollToEffect:effect];
        if (self.selectedFilter) {
            [self.tabFilterView selectFilterByCode:effect scrolling:NO];
        }
        return NO;
    } else {
        // add to download queue
        [self.filterManager addEffectToDownloadQueue:effect];
        self.incomingEffect = effect;
        self.incomingEffectFromBox = fromBox;
        [self.tabFilterView scrollToEffect:effect];
        if (self.selectedFilter) {
            [self.tabFilterView selectFilterByCode:effect scrolling:NO];
        }
        return NO;
    }
}

- (void)didClickedCategory:(IESCategoryModel *)category
{
    if ([self.delegate respondsToSelector:@selector(didClickedCategory:)]) {
        [self.delegate didClickedCategory:category];
    }
}

- (void)didClickedFilter:(IESEffectModel *)item
{
    if ([self.delegate respondsToSelector:@selector(didClickedFilter:)]) {
        [self.delegate didClickedFilter:item];
    }
}

- (void)applyFilter:(IESEffectModel *)effect fromBox:(BOOL)fromBox {
    self.incomingEffect = nil;
    self.selectedFilter = effect;
    
    if ([self enableFilterIndensity]) {
        [self applyFilterAndUpdateUiWithFilterModel:effect];

        //Resources configured with default filter package by default
        if ([self.delegate respondsToSelector:@selector(applyFilter:)]) {
            [self.delegate applyFilter:effect];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(applyFilter:)]) {
            [self.delegate applyFilter:effect];
        }
    }
        
    [self reportSelectFilter:effect tabName:[self.tabFilterView tabNameForFilter:effect] fromBox:fromBox];
}

- (void)reportSelectFilter:(IESEffectModel *)item tabName:(NSString *)tabName fromBox:(BOOL)fromBox {
    NSString *label = item.pinyinName;
    NSString *filterName = item ? (item.pinyinName ?: @"") : @"empty";
    NSString *filterId = item ? (item.effectIdentifier ?: @"") : @"0";
    NSString *enterMethod = fromBox ? @"filter_box" : @"click";
    if (self.showOnViewController) {
        NSMutableDictionary *attributes = [@{
                                             @"is_photo" : self.isPhotoMode ? @1 : @0,
                                             @"position" : @"shoot_page",
                                             @"filter_name" : filterName,
                                             @"filter_id" : filterId,
                                             @"tab_name" : tabName ?: @"",
                                             @"shoot_way" : @"direct_shoot"
                                             } mutableCopy];
        if (!fromBox) {
            [ACCTracker() trackEvent:@"filter_click"
                                              label:@"shoot_page"
                                              value:nil
                                              extra:label
                                         attributes:attributes];
        }
        [attributes addEntriesFromDictionary:self.repository.referExtra];
        [attributes addEntriesFromDictionary:@{@"enter_method" : enterMethod}];
        attributes[@"enter_from"] = @"video_shoot_page";
        if (self.repository.recordSourceFrom == AWERecordSourceFromUnknown) {
            [ACCTracker() trackEvent:@"select_filter" params:attributes needStagingFlag:NO];
        }
    } else {
        NSMutableDictionary *attributes = [@{
                                             @"is_photo" : self.isPhotoMode ? @1 : @0,
                                             @"position" : @"mid_page",
                                             @"filter_name" : filterName,
                                             @"filter_id" : filterId,
                                             @"tab_name" : tabName ?: @""
                                             } mutableCopy];
        
        [attributes addEntriesFromDictionary:self.repository.referExtra];
        if (!fromBox) {
            [ACCTracker() trackEvent:@"filter_click"
                                              label:@"record_page"
                                              value:nil
                                              extra:label
                                         attributes:attributes];
        }
        [attributes addEntriesFromDictionary:@{@"enter_method" : enterMethod,
                                               @"enter_from" : @"video_edit_page"
                                               }];
        if (self.repository.recordSourceFrom == AWERecordSourceFromUnknown) {
            [ACCTracker() trackEvent:@"select_filter" params:attributes needStagingFlag:NO];
        }
    }
}

- (void)tabClickedWithName:(NSString *)tabName
{
    NSMutableDictionary *params = self.repository.referExtra.mutableCopy;
    params[@"tab_name"] = tabName ?: @"";
    if (self.showOnViewController) {
        params[@"enter_from"] = @"video_shoot_page";
    }
    if (self.repository.recordSourceFrom == AWERecordSourceFromUnknown) {
        [ACCTracker() trackEvent:@"click_filter_tab" params:params needStagingFlag:NO];
    }
}

- (void)clearFilterApply
{
    [self trackDeleteFilter];
    self.selectedFilter = nil;
    [self.tabFilterView selectClearButton];
    if ([self enableFilterIndensity]) {
        self.sliderContainerView.hidden = YES;
    }
    if ([self.delegate respondsToSelector:@selector(applyFilter:)]) {
        [self.delegate applyFilter:nil];
    }
}

//Display the view of filter management box
- (void)filterBoxButtonClicked
{
    //Login verification, the user who has not logged in will log in
    [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) requireLogin:^(BOOL success) {
        if (success) {
            //Display the view of filter management box
            self.filterBoxView = [[AWEFilterBoxView alloc] init];
            [self.view addSubview:self.filterBoxView];
            ACCMasMaker(self.filterBoxView, {
                make.left.right.bottom.equalTo(self.view);
                make.height.equalTo(self.view.mas_height).multipliedBy(0.6f);
            });
            CGRect maskFrame = CGRectMake(0, 0, ACC_SCREEN_WIDTH, self.view.acc_height * 0.6);
            self.filterBoxView.layer.mask = [self topRoundCornerShapeLayerWithFrame:maskFrame];

            self.filterBoxView.transform = CGAffineTransformMakeTranslation(0, self.view.bounds.size.height * 0.6f);
            [UIView animateKeyframesWithDuration:0.5f delay:0 options:0 animations:^{
                [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.25 animations:^{
                    self.containerView.transform = CGAffineTransformMakeTranslation(0, self.containerView.bounds.size.height);
                }];
                [UIView addKeyframeWithRelativeStartTime:0.25 relativeDuration:0.25 animations:^{
                    self.filterBoxView.transform = CGAffineTransformIdentity;
                }];
            } completion:^(BOOL finished) {
                
            }];
            
            //Select filter for processing
            @weakify(self)
            self.filterBoxView.selectionBlock = ^(IESEffectModel * _Nonnull filterModel) {
                @strongify(self);
                [self updateFilterArrayFromBox];
                [self selectFilter:filterModel fromBox:YES];
            };
            
            //When the filter box deselects the currently used filter, select the first filter of the first tab
            self.filterBoxView.unselectionBlock = ^(IESEffectModel * _Nonnull filterModel) {
                @strongify(self);
                IESEffectModel *_selectedEffect = self.selectedFilter;
                [self updateFilterArrayFromBox];
                if ([filterModel isEqual:_selectedEffect]) {
                    NSArray *filtersArray = self.tabFilterView.filtersArray;
                    NSDictionary *categoryDict = filtersArray.firstObject;
                    if (categoryDict) {
                        NSArray *filterModels = categoryDict.allValues.firstObject;
                        IESEffectModel *firstFilterModel = filterModels.firstObject;
                        if (firstFilterModel && firstFilterModel.downloaded && ![firstFilterModel isEqual:filterModel]) {
                            [self selectFilter:firstFilterModel fromBox:YES];
                        } else {
                            [self clearFilterApply];
                        }
                    }
                }
            };
            
            //Get filter management box data
            [self.filterBoxView showLoading:YES];
            [self.filterConfiguration fetchEffectListStateCompletion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
                [self.filterBoxView showLoading:NO];
                if (response.categories) {
                    self.filterBoxView.categories = response.categories;
                    [self.tabFilterView updateTabNameCache:response.categories];
                } else {
                    [self.filterBoxView showError:YES];
                }
            }];
        }
    }];
}

#pragma mark - UIGestureRecognizerDelegate

- (void)panSwitchFilter:(UIPanGestureRecognizer *)gestureRecognizer {
    //This pangesteure is designed to intercept pan gestures and do nothing
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

#pragma mark - AWESliderDelegate

- (void)slider:(AWESlider *)slider valueDidChanged:(float)value {
    float ratio = value / slider.maximumValue;
    //Store the intensity ratio of the corresponding filter
    [self.repository setColorFilterIntensityRatio:@(ratio)];
    AWEColorFilterConfigurationHelper *helper;
    if ([self.delegate respondsToSelector:@selector(currentFilterHelper)]) {
        helper = [self.delegate currentFilterHelper];
    }
    IESEffectModel *model = self.selectedFilter;
    [helper setIndensityRatioForColorEffect:model ratio:ratio];
    if ([self.delegate respondsToSelector:@selector(onUserSlideIndensityValueChanged:)]) {
        [self.delegate onUserSlideIndensityValueChanged:ratio];
    }
    //Configure the default strength of the slider
    float defaultIndensity = 0.0;
    if ([self.delegate respondsToSelector:@selector(filterIndensity:)]) {
        defaultIndensity = [self.delegate filterIndensity:model];
    }
    defaultIndensity = [helper getEffectIndensityWithDefaultIndensity:defaultIndensity Ratio:ratio];
    if ([self.delegate respondsToSelector:@selector(applyFilter:indensity:)]) {
        [self.delegate applyFilter:model indensity:defaultIndensity];
    }
}

#pragma mark - Private

- (void)onEffectListUpdated:(NSNotification *)notification
{
    acc_dispatch_main_async_safe(^{
        BOOL updated = [notification.object boolValue];
        if (updated) {
            [self.filterConfiguration updateFilterData];
            self.tabFilterView.filtersArray = [[self.filterManager allAggregatedEffects] copy];
            [self reloadData];
        }
    });
}

- (void)onEffectUpdated:(NSNotification *)notification {
    acc_dispatch_main_async_safe(^{
        IESEffectModel *effect = notification.object;
        if (self.incomingEffect == effect && effect.downloaded) {
            [self applyFilter:effect fromBox:self.incomingEffectFromBox];
        } else if ([self.selectedFilter.effectIdentifier isEqualToString:effect.effectIdentifier]) {
            [self applyFilter:self.selectedFilter fromBox:self.incomingEffectFromBox];
        }
        [self.tabFilterView updateEffect:effect];
    });
}

- (void)updateFilterArrayFromBox {
    if (!self.filterBoxView) {
        return;
    }
    
    //Update ViewModel, update UI
    //Here, you need to manually synthesize data and update the local panel UI before synchronizing to the server
    NSMutableArray *aggregatedEffects = [[NSMutableArray alloc] init];
    for (IESCategoryModel *category in self.filterBoxView.categories) {
        NSMutableArray *selectedEffects = [NSMutableArray array];
        for (IESEffectModel *model in category.effects) {
            if (model.isBuildin || model.isChecked) {
                [selectedEffects addObject:model];
            }
        }
        if (selectedEffects.count > 0) {
            NSDictionary *categoryDict = @{category : [selectedEffects copy]};
            [aggregatedEffects addObject:categoryDict];
        }
    }
    self.tabFilterView.filtersArray = [aggregatedEffects copy];
    [self reloadData];
}

- (void)p_onClearBackgroundPress:(UITapGestureRecognizer *)g {
    if (self.filterBoxView) {
        //The filter management box has been changed: there are check or uncheck filter operations
        //1. Synchronize the changes to the server (synchronization failure will not be handled)
        //2. After the synchronization is successful, the filter list data is forced to be pulled again and cached
        //3. Update the filter panel UI
        
        NSArray *checkArray = [self.filterBoxView.checkArray copy];
        NSArray *uncheckArray = [self.filterBoxView.uncheckArray copy];
        //Synchronize the server and pull the latest data
        if (checkArray.count > 0 || uncheckArray.count > 0) {
            [self.filterConfiguration updateFilterCheckStatusWithCheckArray:checkArray uncheckArray:uncheckArray];
        }
        
        //Close the filter box panel
        [UIView animateKeyframesWithDuration:0.5f delay:0 options:0 animations:^{
            [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.25f animations:^{
                self.filterBoxView.transform = CGAffineTransformMakeTranslation(0, self.view.bounds.size.height * 0.6f);
            }];
            [UIView addKeyframeWithRelativeStartTime:0.25f relativeDuration:0.25f animations:^{
                self.containerView.transform = CGAffineTransformIdentity;
            }];
        } completion:^(BOOL finished) {
            [self.filterBoxView removeFromSuperview];
            self.filterBoxView = nil;
        }];
        
        return;
    }
    
    [self p_dismiss];
}

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] init];
        _containerView.backgroundColor = ACCResourceColor(ACCColorBGCreation2);
        CGRect maskFrame = CGRectMake(0, 0, ACC_SCREEN_WIDTH, kAWERecordFilterContainerViewHeight + ACC_IPHONE_X_BOTTOM_OFFSET);
        _containerView.layer.mask = [self topRoundCornerShapeLayerWithFrame:maskFrame];
    }
    return _containerView;
}

- (AWETabControlledCollectionWrapperView *)tabFilterView {
    if (!_tabFilterView) {
        _tabFilterView = [[AWETabControlledCollectionWrapperView alloc] initWithFrame:CGRectZero shouldShowClearFilterButton:YES filterManager:self.filterManager];
        _tabFilterView.delegate = self;
        _tabFilterView.showFilterBoxButton = self.showFilterBoxButton;
        _tabFilterView.iconStyle = self.iconStyle;
        _tabFilterView.filtersArray = [[self.filterManager allAggregatedEffects] copy];
    }
    return _tabFilterView;
}

- (UIView *)bottomTabFilterView
{
    return self.tabFilterView;
}

- (AWESlider *)slider {
    if (!_slider) {
        AWESlider *slider = [[AWESlider alloc] init];
        slider.minimumValue = 0;
        slider.maximumValue = 100;
        slider.showIndicatorLabel = YES;
        slider.minimumTrackTintColor = [self.uiConfig sliderMinimumTrackTintColor];
        slider.maximumTrackTintColor = ACCResourceColor(ACCUIColorConstTextInverse4);
        slider.indicatorLabelTextColor = UIColor.whiteColor;
        slider.indicatorLabel.font = [ACCFont() acc_systemFontOfSize:12 weight:ACCFontWeightBold];
        slider.indicatorLabelBotttomMargin = 2;
        @weakify(slider);
        slider.valueDisplayBlock = ^{
            @strongify(slider);
            if ([ACCAccessibility() respondsToSelector:@selector(enableAccessibility:traits:label:)]) {
                [ACCAccessibility() enableAccessibility:slider
                                                 traits:UIAccessibilityTraitNone
                                                  label:nil];
            }
            if ([ACCAccessibility() respondsToSelector:@selector(setAccessibilityProperty:accessibilityValue:)]) {
                [ACCAccessibility() setAccessibilityProperty:slider accessibilityValue:nil];
            }
            return [NSString stringWithFormat:@"%ld",(long)[@(roundf(slider.value)) integerValue]];
        };
        if ([ACCAccessibility() respondsToSelector:@selector(setAccessibilityProperty:isAccessibilityElement:)]) {
            [ACCAccessibility() setAccessibilityProperty:_slider isAccessibilityElement:YES];
        }
        _slider = slider;
        _slider.delegate = self;
    }
    return _slider;
}

- (UIView *)sliderContainerView {
    if (!_sliderContainerView) {
        _sliderContainerView = [[UIView alloc] init];
    }
    return _sliderContainerView;
}

- (UIView *)sliderIndicatorView {
    if (!_sliderIndicatorView) {
        _sliderIndicatorView = [[UIView alloc] init];
        _sliderIndicatorView.backgroundColor = UIColor.whiteColor;
        _sliderIndicatorView.layer.cornerRadius = 2.5;
    }
    return _sliderIndicatorView;
}

- (BOOL)enableFilterIndensity {
    if ([self.delegate respondsToSelector:@selector(enableFilterIndensity)]) {
        return [self.delegate enableFilterIndensity];
    } else {
        return NO;
    }
}

- (void)applyFilterAndUpdateUiWithFilterModel:(IESEffectModel *)filterModel {

    float defaultIndensity = 0.0;
    float ratio = 0.0;
    if ([self.delegate respondsToSelector:@selector(filterIndensity:)]) {
        defaultIndensity = [self.delegate filterIndensity:filterModel];
    }
    if ((defaultIndensity == 0) || filterModel == nil) { //If the default filter strength is 0, the slider will be hidden and the filter setting will not take effect
        self.sliderContainerView.hidden = YES;
        self.slider.value = 0;
    } else {
        self.sliderContainerView.hidden = NO;
        if (defaultIndensity == 1) {
            self.sliderIndicatorView.hidden = YES;
            self.slider.value = 100;
        } else {
            self.sliderIndicatorView.hidden = NO;
            self.slider.value = 80;
        }

        BOOL hasCacheIndensityRatio = [self p_hasCacheIndensityRatioWithFilterModel:filterModel];
        if (hasCacheIndensityRatio) {  //If there is a buffer, use the buffer filter strength
            ratio = [self p_getCacheIndensityRatioWithFilterModel:filterModel];
            self.slider.value = ratio * 100;
        }
    }
}

- (void)trackAdjustFilter {
    if (self.selectedFilter) {
        IESEffectModel *filterModel = self.selectedFilter;
        // float defaultIndensity = 0.0;
        float ratio = 0.0;
        BOOL hasCacheIndensityRatio = [self p_hasCacheIndensityRatioWithFilterModel:filterModel];
        if (hasCacheIndensityRatio) {  //If there is a buffer, use the buffer filter strength
            NSString *filterName = filterModel ? (filterModel.pinyinName ?: @"") : @"empty";
            NSString *filterId = filterModel ? (filterModel.effectIdentifier ?: @"") : @"0";
            ratio = [self p_getCacheIndensityRatioWithFilterModel:filterModel];
            NSMutableDictionary *attributes = [@{
                @"enter_from" : self.repository.enterFrom ?: @"",
                @"creation_id" : self.repository.createId ?: @"",
                @"shoot_way" : self.repository.referString ?: @"",
                @"filter_id" : filterId,
                @"filter_name" : filterName ?: @"",
                @"value" : @(ratio)
            } mutableCopy];
            
             [ACCTracker() trackEvent:@"adjust_filter_complete" params:attributes needStagingFlag:NO];
        }
    }
}

- (CGFloat)p_getCacheIndensityRatioWithFilterModel:(IESEffectModel *)filterModel
{
    if (self.selectedFilterIntensityRatio != nil) {
        return self.selectedFilterIntensityRatio.floatValue;
    }
    
    AWEColorFilterConfigurationHelper *helper;
    if ([self.delegate respondsToSelector:@selector(currentFilterHelper)]) {
        helper = [self.delegate currentFilterHelper];
    }
    return [helper indensityRatioForColorEffect:filterModel];
}

- (BOOL)p_hasCacheIndensityRatioWithFilterModel:(IESEffectModel *)filterModel
{
    if (self.selectedFilterIntensityRatio != nil) {
        return YES;
    }
    
    AWEColorFilterConfigurationHelper *helper;
    if ([self.delegate respondsToSelector:@selector(currentFilterHelper)]) {
        helper = [self.delegate currentFilterHelper];
    }
    return [helper hasIndensityRatioForColorEffect:filterModel];
}

- (void)trackDeleteFilter
{
    NSDictionary *attributes = @{
        @"enter_from": self.repository.enterFrom ? : @"",
        @"shoot_way": self.repository.referString ? : @"",
        @"creation_id": self.repository.createId ? : @"",
        @"filter_id": @"-1",
    };

    [ACCTracker() trackEvent:@"filter_deleted" params:attributes needStagingFlag:NO];
}

- (CAShapeLayer *)topRoundCornerShapeLayerWithFrame:(CGRect)frame
{
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    CGFloat maskRadius = 8;
    shapeLayer.path = [UIBezierPath bezierPathWithRoundedRect:frame
                                            byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                                                  cornerRadii:CGSizeMake(maskRadius, maskRadius)].CGPath;
    return shapeLayer;
}

#pragma mark - show

- (void)p_dismiss
{
    [self trackAdjustFilter];
    if (self.willDismissBlock) {
        self.willDismissBlock();
    }
    
    if (self.needDismiss) {
        [self p_dismissWithAnimated:YES duration:0.25];
    }
}

- (void)p_dismissWithAnimated:(BOOL)animated duration:(NSTimeInterval)duration
{
    if (!self.view.superview) {
        return;
    }
    
    if (animated) {
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.view.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, self.view.acc_width, self.view.acc_height);
        } completion:^(BOOL finished) {
            [self.view removeFromSuperview];
            if (self.didDismissBlock) {
                self.didDismissBlock();
            }
        }];
    } else {
        self.view.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, self.view.acc_width, self.view.acc_height);
        [self.view removeFromSuperview];
        if (self.didDismissBlock) {
            self.didDismissBlock();
        }
    }
}

- (void)p_showOnViewController:(UIViewController *)controller
                      animated:(BOOL)animated
                      duration:(NSTimeInterval)duration
{
    if (!controller) {
        return;
    }
    
    [self p_showOnView:controller.view
            fromOffset:CGPointMake(0,[UIScreen mainScreen].bounds.size.height)
              animated:animated
              duration:duration];
}

- (void)p_showOnView:(UIView *)superview
          fromOffset:(CGPoint)offset
            animated:(BOOL)animated
            duration:(NSTimeInterval)duration
{
    if (!superview) {
        return;
    }
    
    if (self.view.superview) {
        [self.view removeFromSuperview];
    }
    
    [superview addSubview:self.view];
    [superview bringSubviewToFront:self.view];
    
    if (animated) {
        self.view.frame = CGRectMake(offset.x, offset.y, self.view.acc_width, self.view.acc_height);
        [UIView animateWithDuration:0.49 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.view.frame = CGRectMake(0, 0, self.view.acc_width, self.view.acc_height);
        } completion:^(BOOL finished) {
        }];
    } else {
        self.view.frame = CGRectMake(0, 0, self.view.acc_width, self.view.acc_height);
    }
}

#pragma mark - ACCPanelViewProtocol

- (CGFloat)panelViewHeight
{
    return self.view.frame.size.height;
}

- (void *)identifier
{
    return ACCFilterContext;
}

@end
