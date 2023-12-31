//
//  AWEComposerBeautyViewController.m
//  AWEStudio
//
//  Created by Shen Chen on 2019/8/5.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitBeauty/AWEComposerBeautyViewController.h>
#import <CreationKitBeauty/AWEComposerBeautyPanelViewController.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectDownloader.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/AWERangeSlider.h>
#import <CreationKitBeauty/ACCBeautyUIDefaultConfiguration.h>
#import <CreationKitBeauty/AWEComposerBeautyViewModel+Signal.h>
#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <ReactiveObjC/RACSignal+Operations.h>
#import <Masonry/View+MASAdditions.h>
#import <CreativeKit/ACCAccessibilityProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>

#define kAWEComposerBeautyPanelPadding 49
const float kAWESliderLength = 100;

@interface AWEComposerBeautyViewController ()<AWESliderDelegate, UIGestureRecognizerDelegate, AWEComposerBeautyPanelViewControllerDelegate>

@property (nonatomic, strong) UIView *contentContainerView;
@property (nonatomic, strong) UIView *clearView;
@property (nonatomic, strong) AWEComposerBeautyPanelViewController *composerPanelViewController;
@property (nonatomic, strong) UIView *adjustmentContainerView;
@property (nonatomic, strong) AWERangeSlider *slider;
@property (nonatomic, assign) BOOL reappendEffectWhenSliderValueChange;
@property (nonatomic, strong, readwrite) AWEComposerBeautyViewModel *viewModel;
@property (nonatomic, strong, readwrite) id<ACCBeautyUIConfigProtocol> uiConfig;
@end


@implementation AWEComposerBeautyViewController

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

- (instancetype)initWithViewModel:(AWEComposerBeautyViewModel *)viewModel
{
    self = [super init];
    if (self) {
        _viewModel = viewModel;
        _uiConfig = [[ACCBeautyUIDefaultConfiguration alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self p_bindViewModel];
}

- (void)p_bindViewModel
{
    @weakify(self);
    [[self.viewModel.currentCategorySignal deliverOnMainThread] subscribeNext:^(AWEComposerBeautyEffectCategoryWrapper * _Nullable x) {
        @strongify(self);
        [self.composerPanelViewController updateResetButtonToDisabled:[self.viewModel shouldDisableResetButton]];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.composerPanelViewController updateResetButtonToDisabled:[self.viewModel shouldDisableResetButton]];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    CGRect maskFrame = CGRectMake(0, 0, ACC_SCREEN_WIDTH, self.uiConfig.panelContentHeight);
    self.contentContainerView.layer.mask = [self topRoundCornerShapeLayerWithFrame:maskFrame];
}

#pragma mark - setup UI

- (void)setupUI
{
    self.view.acc_width = [UIScreen mainScreen].bounds.size.width;
    self.view.acc_height = [UIScreen mainScreen].bounds.size.height;
    UITapGestureRecognizer *tapGes = [self.view acc_addSingleTapRecognizerWithTarget:self action:@selector(backviewTaped:)];
    tapGes.delegate = self;

    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backviewTaped:)];
    [self.clearView addGestureRecognizer:tapRecognizer];
    if ([ACCAccessibility() respondsToSelector:@selector(setAccessibilityProperty:accessibilityViewIsModal:)]) {
        [ACCAccessibility() setAccessibilityProperty:self.view accessibilityViewIsModal:YES];
    }
    [self.view addSubview:self.clearView];
    ACCMasMaker(self.clearView, {
        make.top.left.right.equalTo(self.view);
        make.height.equalTo(@([UIScreen mainScreen].bounds.size.height - self.uiConfig.panelContentHeight));
    });

    [self.view addSubview:self.contentContainerView];
    self.composerPanelViewController.delegate = self;
    
    [self addChildViewController:self.composerPanelViewController];
    [self.contentContainerView addSubview:self.composerPanelViewController.view];
    [self.composerPanelViewController didMoveToParentViewController:self];

    ACCMasMaker(self.contentContainerView, {
        make.height.equalTo(@(self.uiConfig.panelContentHeight));
        make.left.bottom.right.equalTo(self.view);
    });

    ACCMasMaker(self.composerPanelViewController.view, {
        make.left.bottom.right.equalTo(self.contentContainerView);
        make.height.equalTo(@(self.uiConfig.panelContentHeight));
    });
    
    self.adjustmentContainerView = [[UIView alloc] init];
    self.adjustmentContainerView.hidden = YES;
    if ([ACCAccessibility() respondsToSelector:@selector(setAccessibilityProperty:isAccessibilityElement:)]) {
        [ACCAccessibility() setAccessibilityProperty:self.adjustmentContainerView isAccessibilityElement:NO];
    }
    self.adjustmentContainerView.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:self.adjustmentContainerView];
    
    @weakify(self);
    self.slider.valueDisplayBlock = ^{
        @strongify(self);
        return [NSString stringWithFormat:@"%ld",(long)[@(roundf(self.slider.value)) integerValue]];
    };
    [self.adjustmentContainerView addSubview:self.slider];
    ACCMasMaker(self.adjustmentContainerView, {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.contentContainerView.mas_top).with.offset(-16);
        make.height.equalTo(@28);
    });
    
    ACCMasMaker(self.slider, {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            make.left.equalTo(self.adjustmentContainerView).offset(16);
            make.right.equalTo(self.adjustmentContainerView).offset(-16);
        } else {
            make.width.equalTo(self.adjustmentContainerView).multipliedBy(3.0/5.0);
            make.centerX.equalTo(self.adjustmentContainerView);
        }
        make.height.equalTo(@(20));
        make.centerY.equalTo(self.adjustmentContainerView);
    });
}

- (void)backviewTaped:(UIGestureRecognizer *)tapGesture
{
    [self p_dismiss];
}

#pragma mark - lazy init property

- (AWERangeSlider *)slider
{
    if (!_slider) {
        _slider = [self.uiConfig makeNewSlider];
        _slider.indicatorLabel.font = [ACCFont() acc_systemFontOfSize:12 weight:ACCFontWeightBold];
        if ([ACCAccessibility() respondsToSelector:@selector(setAccessibilityProperty:isAccessibilityElement:)]) {
            [ACCAccessibility() setAccessibilityProperty:_slider isAccessibilityElement:NO];
        }
        _slider.delegate = self;
    }
    return _slider;
}


- (AWEComposerBeautyPanelViewController *)composerPanelViewController
{
    if (!_composerPanelViewController) {
        _composerPanelViewController = [[AWEComposerBeautyPanelViewController alloc] initWithViewModel:self.viewModel];
        [_composerPanelViewController updateUIConfig:self.uiConfig];
    }
    return _composerPanelViewController;
}

- (UIView *)contentContainerView
{
    if (!_contentContainerView) {
        _contentContainerView = [[UIView alloc] initWithFrame:CGRectZero];
        _contentContainerView.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainer3);
        CGRect maskFrame = CGRectMake(0, 0, ACC_SCREEN_WIDTH, self.uiConfig.panelContentHeight);
//        [_contentContainerView acc_addBlurEffect];
        _contentContainerView.layer.mask = [self topRoundCornerShapeLayerWithFrame:maskFrame];
    }
    return _contentContainerView;
}

- (UIView *)clearView
{
    if (!_clearView) {
        _clearView = [[UIView alloc] init];
        _clearView.backgroundColor = [UIColor clearColor];
        [_clearView setExclusiveTouch:YES];
        if ([ACCAccessibility() respondsToSelector:@selector(enableAccessibility:traits:label:)]) {
            [ACCAccessibility() enableAccessibility:_clearView
                                             traits:UIAccessibilityTraitButton
                                              label:ACCLocalizedString(@"off", @"off")];
        }
    }
    return _clearView;
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

#pragma mark - public

- (BOOL)shouldAutorotate
{
    return NO;
}

- (void)clearSelection
{
    self.reappendEffectWhenSliderValueChange = YES;
}

// reload panel
- (void)reloadPanel
{
    [self.composerPanelViewController reloadPanel];
    [self composerBeautyPanelDidChangeToCategory:[self.viewModel currentCategory] needTracker:NO];
}

- (void)updateUIConfig:(id<ACCBeautyUIConfigProtocol>)config
{
    self.uiConfig = config;
}

- (void)showOnViewController:(UIViewController *)controller
{
    [self p_showOnViewController:controller animated:YES duration:0.25];
}

- (void)showOnView:(UIView *)containerView
{
    if (!containerView) {
        return;
    }
    [self p_showOnView:containerView fromOffset:CGPointMake(0, containerView.acc_height) animated:YES duration:0.25];
}

#pragma mark - private

- (void)p_dismiss
{
    [self p_dismissWithAnimated:YES duration:0.15];
}

- (void)p_dismissWithAnimated:(BOOL)animated duration:(NSTimeInterval)duration
{
    self.reappendEffectWhenSliderValueChange = YES;

    // cache applied effects before dismiss
    if ([self.delegate respondsToSelector:@selector(composerBeautyViewControllerWillDismiss)]) {
        [self.delegate composerBeautyViewControllerWillDismiss];
    } else {
        [self.viewModel.effectViewModel cacheAppliedEffects];
    }

    // track
    if (self.viewModel.selectedEffect) {
        [self trackBeautifyValueChanged:self.viewModel.selectedEffect];
    }
    if (!self.view.superview) {
        return;
    }

    // animation
    if (self.externalDismissBlock) {
        self.externalDismissBlock();
    } else {
        if (animated) {
            [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                [self p_moveToYOffset:[UIScreen mainScreen].bounds.size.height];
                [self.view.superview setNeedsLayout];
                [self.view.superview layoutIfNeeded];
            } completion:^(BOOL finished) {
                [self.view removeFromSuperview];
                if (self.dissmissBlock) {
                    self.dissmissBlock();
                }
            }];
        } else {
            [self p_moveToYOffset:[UIScreen mainScreen].bounds.size.height];
            [self.view.superview setNeedsLayout];
            [self.view.superview layoutIfNeeded];
            [self.view removeFromSuperview];
            if (self.dissmissBlock) {
                self.dissmissBlock();
            }
        }
    }
}

- (void)p_showOnViewController:(UIViewController *)controller animated:(BOOL)animated duration:(NSTimeInterval)duration
{
    if (!controller) {
        return;
    }
    
    [self p_showOnView:controller.view
            fromOffset:CGPointMake(0,[UIScreen mainScreen].bounds.size.height)
              animated:animated
              duration:duration];
}

- (void)p_showOnView:(UIView *)superview fromOffset:(CGPoint)offset animated:(BOOL)animated duration:(NSTimeInterval)duration
{
    if (!superview) {
        return;
    }
    
    if (self.view.superview) {
        [self.view removeFromSuperview];
    }
    
    [superview addSubview:self.view];
    [superview bringSubviewToFront:self.view];

    // reload panel
    [self reloadPanel];
    // update slider
    [self handleSelectEffectWrapper:self.viewModel.selectedEffect];
    // update resetButton
    [self.composerPanelViewController updateResetButtonToDisabled:[self.viewModel shouldDisableResetButton]];

    // do animation
    if (animated) {
        [self p_moveToYOffset:offset.y];
        [UIView animateWithDuration:.49
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            [self p_moveToYOffset:0];
        } completion:^(BOOL finished) {
        }];
    } else {
        [self p_moveToYOffset:0];
    }
}

- (void)p_moveToYOffset:(CGFloat)offset
{
    ACCMasUpdate(self.view, {
        make.width.equalTo(@(self.view.acc_width));
        make.height.equalTo(@(self.view.acc_height));
        make.top.equalTo(@(offset));
        make.left.equalTo(@(0));
    });
    [self.view.superview setNeedsLayout];
    [self.view.superview layoutIfNeeded];
}

#pragma mark - Condition & Action

// should enable reset button
- (void)p_handleUserModifiedStatus
{
    // if modified, check effects in viewModel.filteredCategoreis, to enable resetButton
    self.viewModel.effectViewModel.didModifyStatus = YES;
    [self.composerPanelViewController updateResetButtonToDisabled:[self.viewModel shouldDisableResetButton]];
}

// should show slider
- (BOOL)p_shouldShowAdjusmentContainer
{
    AWEComposerBeautyEffectWrapper *effectWrapper = self.viewModel.currentCategory.userSelectedEffect;
    if (effectWrapper.isEffectSet) {
        effectWrapper = effectWrapper.appliedChildEffect ?: effectWrapper.defaultChildEffect;
    }

    AWEEffectDownloadStatus downloadStatus = [[AWEComposerBeautyEffectDownloader defaultDownloader] downloadStatusOfEffect:effectWrapper];
    if (!effectWrapper || !effectWrapper.available || effectWrapper.isNone || [effectWrapper isEffectSet] || (downloadStatus != AWEEffectDownloadStatusDownloaded)) {
        return NO;
    }

    // If the beauty switch experiment is on, the current category is "beauty" and on the recording page, you need to judge whether the switch button is on / off
    if ([self.viewModel enableBeautyCategorySwitch]) {
        return [self.viewModel.effectViewModel.cacheObj isCategorySwitchOn:self.viewModel.currentCategory];
    }

    return YES;
}

- (void)refreshSliderDefaultIndicatorPosition:(CGFloat)position
{
    self.slider.defaultIndicatorPosition = position;
}

- (void)refreshSliderWithEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper {
    if (!effectWrapper || effectWrapper.isNone || [effectWrapper isEffectSet]) {
        return;
    }
    AWEComposerBeautyEffectItem *item = effectWrapper.items.firstObject;
    if (ACC_FLOAT_LESS_THAN(item.minValue, 0)) {
        self.slider.maximumValue = kAWESliderLength / 2;
        self.slider.minimumValue = -kAWESliderLength / 2;
        self.slider.originPosition = 0.5f;
    } else {
        self.slider.maximumValue = kAWESliderLength;
        self.slider.minimumValue = 0;
        self.slider.originPosition = 0.f;
    }
    if (ACC_FLOAT_EQUAL_TO(item.minValue, item.defaultValue)) {
        self.slider.showDefaultIndicator = NO;
    } else {
        self.slider.showDefaultIndicator = YES;
        self.slider.defaultIndicatorPosition = item.defaultPosition;
    }
    // ！！ Here, the effectwrapper cannot be of type effectset
    self.slider.value = effectWrapper.currentRatio * self.slider.maximumValue;
}

#pragma mark - AWESlider - Delegate

- (void)slider:(AWESlider *)slider valueDidChanged:(float)value
{
    if (self.reappendEffectWhenSliderValueChange) {

        // update applied effects
        [self.viewModel.effectViewModel bringEffectWrapperToEnd:self.viewModel.selectedEffect];

        if ([self.delegate respondsToSelector:@selector(selectComposerBeautyEffect:ratio:oldEffect:)]) {
            // delegate to Component, and then use Camera.beauty to apply effect with ratio
            [self.delegate selectComposerBeautyEffect:self.viewModel.selectedEffect
                                                ratio:self.viewModel.selectedEffect.currentRatio
                                            oldEffect:nil];
        }

        // cache applied effects
        [self.viewModel.effectViewModel cacheAppliedEffects];

        self.reappendEffectWhenSliderValueChange = NO;
    }

    AWEComposerBeautyEffectWrapper *effect = self.viewModel.selectedEffect;
    if (effect) {
        float ratio = value / slider.maximumValue;
        [effect updateWithStrength:ratio];
        if ([self.delegate respondsToSelector:@selector(applyComposerBeautyEffect:ratio:)]) {
            // not apply, just modify the ratio of effect in camera
            [self.delegate applyComposerBeautyEffect:effect ratio:ratio];
        }
    }
}

- (void)slider:(AWESlider *)slider didFinishSlidingWithValue:(float)value
{
    float ratio = value / slider.maximumValue;

    AWEComposerBeautyEffectWrapper *effect = self.viewModel.selectedEffect;
    if (effect) {

        // update model
        [effect updateWithStrength:ratio];

        // update cache
        [self.viewModel.effectViewModel.cacheObj setRatio:ratio forEffect:effect];

        // now only useful for skeleton
        if ([self.delegate respondsToSelector:@selector(didFinishSlidingWithValue:forEffect:)]) {
            [self.delegate didFinishSlidingWithValue:ratio forEffect:effect];
        }

        // update panel item ui
        [self.composerPanelViewController updateCurrentSelectedEffectWithStrength:ratio];
        if (self.viewModel.currentCategory.isPrimaryCategory) {
            [self.composerPanelViewController updateResetModeButton];
        }

        // upate modified flag
        [self p_handleUserModifiedStatus];
    }
}

#pragma mark - AWEComposerBeautyPanelViewController - Delegate

// select effect
- (void)composerBeautyPanelDidSelectEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                                 oldEffect:(AWEComposerBeautyEffectWrapper *)oldEffectWrapper
                              fromDownload:(BOOL)fromDownload
{
    if ([effectWrapper isEffectSet]) {
        [self handleSelectEffectWrapper:effectWrapper.appliedChildEffect];
        [self trackSelectBeautifyTab:effectWrapper];
    } else {
        // For non mutually exclusive categories, click none to set the intensity of all small items to 0
        if (effectWrapper.isNone && !effectWrapper.categoryWrapper.exclusive) {
            [self resetCategoryAllItemToZero:effectWrapper.categoryWrapper];
        }

        // restore cache ratio
        [effectWrapper updateWithStrength:[self.viewModel.effectViewModel.cacheObj ratioForEffect:effectWrapper]];

        // update ui
        [self handleSelectEffectWrapper:effectWrapper];

        // actually use the effect
        if ([self.delegate respondsToSelector:@selector(selectComposerBeautyEffect:ratio:oldEffect:)]) {
            [self.delegate selectComposerBeautyEffect:effectWrapper
                                                ratio:effectWrapper.currentRatio
                                            oldEffect:oldEffectWrapper];
        }
    }
}

- (void)composerBeautyPanelDidSelectEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                                lastEffect:(AWEComposerBeautyEffectWrapper *)lastEffectWrapper
{
    [self trackBeautifyValueChanged:lastEffectWrapper];
}

// clicked none effect
- (void)resetCategoryAllItemToZero:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
{
    [self.viewModel resetComposerCategoryAllItemToZero:categoryWrapper];

    [self reloadPanel]; // reload panel to make items gray

    [self p_handleUserModifiedStatus];

    if ([self.delegate respondsToSelector:@selector(composerBeautyDidClearRatioForCategory:)]) {
        [self.delegate composerBeautyDidClearRatioForCategory:categoryWrapper];
    }
}

// select effect of parentObject
- (void)composerBeautyPanelDidSelectEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                           forParentObject:(NSObject *)parentItem
{
    self.adjustmentContainerView.hidden = NO;

    if ([self.delegate respondsToSelector:@selector(selectComposerBeautyEffect:forParentItem:)]) {
        [self.delegate selectComposerBeautyEffect:effectWrapper forParentItem:parentItem];

    } else {
        // update selectedEffect of effect/category,
        // update applied effects,
        // update cache
        if ([parentItem isKindOfClass:[AWEComposerBeautyEffectWrapper class]]) {
            [self.viewModel.effectViewModel updateAppliedChildEffect:effectWrapper forEffect:(AWEComposerBeautyEffectWrapper *)parentItem];
            [self p_handleUserModifiedStatus];
        } else if ([parentItem isKindOfClass:[AWEComposerBeautyEffectCategoryWrapper class]]) {
            [self.viewModel.effectViewModel updateSelectedEffect:effectWrapper forCategory:(AWEComposerBeautyEffectCategoryWrapper *)parentItem];
        }
    }
}

// effect
- (void)composerBeautyPanelDidUpdateCandidateEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper forParentItem:(NSString *)parentItemID
{
    self.adjustmentContainerView.hidden = NO;
    if ([self.delegate respondsToSelector:@selector(updateCandidateComposerBeautyEffect:forParentItem:)]) {
        [self.delegate updateCandidateComposerBeautyEffect:effectWrapper forParentItem:parentItemID];
    } else {
        [self.viewModel.effectViewModel.cacheObj updateCandidateChildEffect:effectWrapper forParentItemID:parentItemID];
    }
}

// back
- (void)composerBeautyPanelDidGoBackToCategoryPanel
{
    [self trackBeautifyValueChanged:self.viewModel.selectedEffect];
    [self handleSelectEffectWrapper:nil];
}

// change category tab
- (void)composerBeautyPanelDidChangeToCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
{
    [self composerBeautyPanelDidChangeToCategory:categoryWrapper needTracker:YES];
}

- (void)composerBeautyPanelDidChangeToCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper needTracker:(BOOL)needTracker
{
    if (needTracker) {
        [self trackBeautifyValueChanged:self.viewModel.selectedEffect];
        [self trackChangeBeautifyCategory:categoryWrapper];
    }

    if ([self.composerPanelViewController isShowingPrimayItems]) {
        self.adjustmentContainerView.hidden = YES;
        self.viewModel.selectedEffect = nil;
    } else if ([categoryWrapper.userSelectedEffect isEffectSet]) {
        if ([self.composerPanelViewController isShowingChildItems]) {
            [self handleSelectEffectWrapper:categoryWrapper.userSelectedEffect.appliedChildEffect];
        } else {
            [self handleSelectEffectWrapper:categoryWrapper.userSelectedEffect];
        }
    } else {
        [self handleSelectEffectWrapper:categoryWrapper.userSelectedEffect];
    }

    // cache selected category
    [self.viewModel.effectViewModel.cacheObj cacheSelectedCategory:categoryWrapper.category.categoryIdentifier];

    if ([self.delegate respondsToSelector:@selector(selectCategory:)]) {
        [self.delegate selectCategory:categoryWrapper];
    }
}

// reset
- (void)composerBeautyPanelDidTapResetButtonWithCompletion:(void (^)(void))completion
{
    [self trackResetAllButtonClick];
    [ACCAlert() showAlertWithTitle:ACCLocalizedString(@"beauty_default_tips", nil) description:ACCLocalizedString(@"beauty_default", nil) image:nil actionButtonTitle:ACCLocalizedString(@"beauty_default_discard", nil) cancelButtonTitle:ACCLocalizedString(@"beauty_default_keep", nil) actionBlock:^{
        [self trackResetAllAlertWithConfirm:YES];
 
        [self.viewModel resetCategorySwitchState];

        if ([self.delegate respondsToSelector:@selector(composerBeautyViewControllerWillReset)]) {
            [self.delegate composerBeautyViewControllerWillReset];
        }

        [self.viewModel resetAllComposerBeautyEffects];

        if ([self.delegate respondsToSelector:@selector(composerBeautyViewControllerDidReset)]) {
            [self.delegate composerBeautyViewControllerDidReset];
        }

        [self refreshSliderWithEffect:self.viewModel.selectedEffect];
        self.adjustmentContainerView.hidden = ![self p_shouldShowAdjusmentContainer];
        [self p_handleUserModifiedStatus];

        completion();
    } cancelBlock:^{
        [self trackResetAllAlertWithConfirm:NO];
    }];
}

// switch
- (void)composerBeautyPanelDidSwitch:(BOOL)isOn isManually:(BOOL)isManually
{
    // If you click the switch button, you don't need to show the slider
    if (isManually) {
        self.viewModel.selectedEffect = nil;
        self.viewModel.currentCategory.selectedEffect = nil;
        self.viewModel.currentCategory.userSelectedEffect = nil;
        self.adjustmentContainerView.hidden = YES;
    } else {
        self.adjustmentContainerView.hidden = ![self p_shouldShowAdjusmentContainer];
    }

    if ([self.delegate respondsToSelector:@selector(composerBeautyViewControllerDidSwitch:isManually:)]) {
        [self.delegate composerBeautyViewControllerDidSwitch:isOn isManually:isManually];
    }
}

// finish download
- (void)composerBeautyPanelDidFinishDownloadingAllEffects
{
    if ([self.delegate respondsToSelector:@selector(composerBeautyViewControllerDidFinishDownloadingAllEffects)]) {
        [self.delegate composerBeautyViewControllerDidFinishDownloadingAllEffects];
    }
}

// handle adjustmentContainerView and Slider with EffectWrapper, and assign the selectedEffect
- (void)handleSelectEffectWrapper:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    if (effectWrapper && !effectWrapper.available) {
        self.adjustmentContainerView.hidden = YES;
        return;
    }
    if (![self.viewModel.selectedEffect isEqual:effectWrapper]) {
        self.reappendEffectWhenSliderValueChange = YES;
    }

    // assign the selected Effect!
    self.viewModel.selectedEffect = effectWrapper;

    AWEEffectDownloadStatus downloadStatus = [[AWEComposerBeautyEffectDownloader defaultDownloader] downloadStatusOfEffect:effectWrapper];
    if (!effectWrapper || effectWrapper.isNone || [effectWrapper isEffectSet] || (downloadStatus != AWEEffectDownloadStatusDownloaded)) {
        self.adjustmentContainerView.hidden = YES;
    } else {
        self.adjustmentContainerView.hidden = NO;
        [self refreshSliderWithEffect:effectWrapper];
    }
}


#pragma mark - Primary - Delegate

// primary select category
- (void)composerBeautyPanelDidSelectPrimaryCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
                                       lastCategory:(AWEComposerBeautyEffectCategoryWrapper *)lastCategoryWrapper
                                     parentCategory:(AWEComposerBeautyEffectCategoryWrapper *)parentCategoryWrapper;
{
    self.adjustmentContainerView.hidden = YES;

    // update reset ui
    [self.composerPanelViewController updateResetButtonToDisabled:[self.viewModel shouldDisableResetButton]];

    if ([self.delegate respondsToSelector:@selector(composerBeautyPanelDidSelectPrimaryCategory:lastCategory:parentCategory:)]) {
        [self.delegate composerBeautyPanelDidSelectPrimaryCategory:categoryWrapper lastCategory:lastCategoryWrapper parentCategory:parentCategoryWrapper];
    }

    // cache selected child category
    [self.viewModel.effectViewModel updateSelectedChildCateogry:categoryWrapper lastChildCategory:lastCategoryWrapper forPrimaryCategory:parentCategoryWrapper];

    // track
    [self trackSelectBeautyMode:categoryWrapper];
}

// priamry enter category
- (void)composerBeautyPanelDidEnterCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper parentCategory:(AWEComposerBeautyEffectCategoryWrapper *)parentCategoryWrapper
{
    if (categoryWrapper.userSelectedEffect != nil) {
        [self handleSelectEffectWrapper:categoryWrapper.userSelectedEffect];
    }
    [self trackClickBeautyModeEdit:categoryWrapper];
}

// primary reset category (reset mode)
- (void)composerBeautyPanelDidTapResetPrimaryCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
{
    // update data
    [self.viewModel resetAllComposerBeautyEffectsOfCategory:categoryWrapper]; // set to default value

    // update ui
    [self.composerPanelViewController updateResetButtonToDisabled:[self.viewModel shouldDisableResetButton]];
    if (categoryWrapper.userSelectedEffect) {
        [self refreshSliderWithEffect:categoryWrapper.userSelectedEffect];
    }

    // delegate outside to reapply effects
    if ([self.delegate respondsToSelector:@selector(composerBeautyPanelDidTapResetPrimaryCategory:)]) {
        [self.delegate composerBeautyPanelDidTapResetPrimaryCategory:categoryWrapper];
    }

    // track
    [self trackResetBeautyMode:categoryWrapper];
}

#pragma mark - UIGestureRecognizer - Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (touch.view == self.view) {
        return YES;
    }
    return NO;
}


#pragma mark - track

/// track selectedEffect
/// 1. before change tab
/// 2. before change effect
- (void)trackBeautifyValueChanged:(AWEComposerBeautyEffectWrapper *)effectWrapper {
    if (!effectWrapper) {
        return ;
    }
    NSMutableDictionary *params = [[self commonTrackerParamsForEffectWrapper:effectWrapper] mutableCopy];
    // check if the parent effectWrapper has a default child effectWrapper.
    if (effectWrapper.appliedChildEffect) {
        IESEffectModel *defaultEffect = effectWrapper.appliedChildEffect.effect;
        params[@"beautify_name_child"] = defaultEffect.effectName ?: @"";
        params[@"beautify_id_child"] = defaultEffect.effectIdentifier ?: @"";
    }
    [ACCTracker() trackEvent:@"select_beautify"
                       params:params
              needStagingFlag:NO];
}

- (void)trackSelectBeautifyTab:(AWEComposerBeautyEffectWrapper *)effectWrapper {
    NSDictionary *params = [self commonTrackerParamsForEffectWrapper:effectWrapper];
    [ACCTracker() trackEvent:@"click_beautify_tab"
                                     params:params
                            needStagingFlag:NO];
}

- (NSDictionary *)commonTrackerParamsForEffectWrapper:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.viewModel.referExtra];
    params[@"enter_from"] = @"video_shoot_page";
    AWEComposerBeautyEffectWrapper *parentEffectWrapper = effectWrapper.parentEffect;
    if (parentEffectWrapper) {
        IESEffectModel *effect = effectWrapper.effect;
        params[@"beautify_name_child"] = effect.effectName ?: @"";
        params[@"beautify_id_child"] = effect.effectIdentifier ?: @"";
    } else {
        parentEffectWrapper = effectWrapper;
    }
    if (self.viewModel.currentCategory.isPrimaryCategory) {
        AWEComposerBeautyEffectCategoryWrapper *currentChildCategory = self.viewModel.currentCategory.selectedChildCategory;
        params[@"beautify_category_name"] = currentChildCategory.primaryCategoryName ?: @"";
        params[@"beautify_category_id"] = currentChildCategory.category.categoryIdentifier ?: @"";
    }
    IESEffectModel *parentEffect = parentEffectWrapper.effect;
    params[@"beautify_name_parent"] = parentEffect.effectName ?: @"";
    params[@"beautify_id_parent"] = parentEffect.effectIdentifier ?: @"";
    if (![effectWrapper isEffectSet]) {
        params[@"beautify_value"] = @((int)effectWrapper.currentSliderValue);
    }
    return params;
}

- (void)trackChangeBeautifyCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.viewModel.referExtra];
    params[@"beautify_category_name"] = categoryWrapper.category.categoryName ?: @"";
    params[@"beautify_category_id"] = categoryWrapper.category.categoryIdentifier ?: @"";
    [ACCTracker() trackEvent:@"click_beautify_category"
                       params:params
              needStagingFlag:NO];
}

- (void)trackResetAllButtonClick
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.viewModel.referExtra];
    params[@"enter_from"] = @"video_shoot_page";
    [ACCTracker() trackEvent:@"reset_beautify_all"
                       params:params
              needStagingFlag:NO];
}

- (void)trackResetAllAlertWithConfirm:(BOOL)confirmed
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.viewModel.referExtra];
    params[@"event_type"] = confirmed ? @"confirm" : @"cancel";
    params[@"enter_from"] = @"video_shoot_page";
    [ACCTracker() trackEvent:@"reset_beautify_popup"
                       params:params
              needStagingFlag:NO];
}

- (void)trackSelectBeautyMode:(AWEComposerBeautyEffectCategoryWrapper *)category
{
    NSDictionary *referExtra = self.viewModel.referExtra;
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"beautify_category_id"] = category.category.categoryIdentifier;
    params[@"beautify_category_name"] = category.primaryCategoryName;
    params[@"enter_from"] = @"video_shoot_page";
    params[@"shoot_way"] = referExtra[@"shoot_way"];
    params[@"content_type"] = referExtra[@"content_type"];
    params[@"content_source"] = referExtra[@"content_source"];
    params[@"creation_id"] = referExtra[@"creation_id"];

    [ACCTracker() trackEvent:@"select_beautify_mode" params:params needStagingFlag:NO];
}

- (void)trackClickBeautyModeEdit:(AWEComposerBeautyEffectCategoryWrapper *)category
{
    NSDictionary *referExtra = self.viewModel.referExtra;
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"beautify_category_id"] = category.category.categoryIdentifier;
    params[@"beautify_category_name"] = category.primaryCategoryName;
    params[@"enter_from"] = @"video_shoot_page";
    params[@"shoot_way"] = referExtra[@"shoot_way"];
    params[@"content_type"] = referExtra[@"content_type"];
    params[@"content_source"] = referExtra[@"content_source"];
    params[@"creation_id"] = referExtra[@"creation_id"];

    [ACCTracker() trackEvent:@"click_beautify_mode_edit" params:params needStagingFlag:NO];
}

- (void)trackResetBeautyMode:(AWEComposerBeautyEffectCategoryWrapper *)category
{
    NSDictionary *referExtra = self.viewModel.referExtra;
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"beautify_category_id"] = category.category.categoryIdentifier;
    params[@"beautify_category_name"] = category.primaryCategoryName;
    params[@"enter_from"] = @"video_shoot_page";
    params[@"shoot_way"] = referExtra[@"shoot_way"];
    params[@"content_type"] = referExtra[@"content_type"];
    params[@"content_source"] = referExtra[@"content_source"];
    params[@"creation_id"] = referExtra[@"creation_id"];

    [ACCTracker() trackEvent:@"reset_beautify_mode" params:params needStagingFlag:NO];
}


@end
