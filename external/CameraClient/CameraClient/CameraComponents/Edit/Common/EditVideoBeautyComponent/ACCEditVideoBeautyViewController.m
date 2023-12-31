//
//  ACCEditVideoBeautyViewController.m
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2021/1/17.
//

#import "ACCEditVideoBeautyViewController.h"

#import "ACCEditVideoBeautyPanelViewController.h"
#import <CreationKitBeauty/AWEComposerBeautyEffectDownloader.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/AWERangeSlider.h>
#import <CreationKitBeauty/AWEComposerBeautyViewModel+Signal.h>
#import <CreationKitInfra/ACCAlertProtocol.h>
#import "ACCEditVideoSmallPreviewController.h"
#import "ACCEditVideoBeautyUIConfig.h"
#import "ACCConfigKeyDefines.h"
#import "AWERepoVideoInfoModel.h"

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <ReactiveObjC/RACSignal+Operations.h>
#import <Masonry/View+MASAdditions.h>

@interface ACCEditVideoBeautyViewController ()<
AWESliderDelegate,
UIGestureRecognizerDelegate,
AWEComposerBeautyPanelViewControllerDelegate>

@property (nonatomic, strong) ACCEditVideoSmallPreviewController *smallPreviewController;
@property (nonatomic, strong) UIView *contentContainerView;
@property (nonatomic, strong) ACCEditVideoBeautyPanelViewController *composerPanelViewController;
@property (nonatomic, strong) UIView *adjustmentContainerView;
@property (nonatomic, strong) AWERangeSlider *slider;
@property (nonatomic, assign) BOOL reappendEffectWhenSliderValueChange;
@property (nonatomic, strong, readwrite) AWEComposerBeautyViewModel *viewModel;
@property (nonatomic, strong, readwrite) id<ACCBeautyUIConfigProtocol> uiConfig;

@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIButton *saveBtn;

@property (nonatomic, strong) ACCStickerContainerView *stickerContainerView;

@end


@implementation ACCEditVideoBeautyViewController

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

- (instancetype)initWithViewModel:(AWEComposerBeautyViewModel *)viewModel
                      editService:(id<ACCEditServiceProtocol>)editService
             stickerContainerView:(ACCStickerContainerView *)stickerContainerView
{
    self = [super init];
    if (self) {
        _viewModel = viewModel;
        _editService = editService;
        _uiConfig = [[ACCEditVideoBeautyUIConfig alloc] init];
        _reappendEffectWhenSliderValueChange = YES;
        _stickerContainerView = stickerContainerView;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self p_bindViewModel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.composerPanelViewController updateResetButtonToDisabled:[self shouldDisableResetButton]];
    self.cancelBtn.hidden = NO;
    self.saveBtn.hidden = NO;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.editService.preview seekToTime:kCMTimeZero completionHandler:nil];
    self.editService.preview.stickerEditMode = YES;
    [self handleSelectEffectWrapper:self.viewModel.selectedEffect];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (void)clearSelection
{
    self.reappendEffectWhenSliderValueChange = YES;
}

- (void)reloadPanel
{
    [self.composerPanelViewController reloadPanel];
    [self composerBeautyPanelDidChangeToCategory:[self.viewModel currentCategory] needTracker:NO];
}

- (void)updateUIConfig:(id<ACCBeautyUIConfigProtocol>)config
{
    self.uiConfig = config;
}

#pragma mark - setup UI

- (void)setupUI
{
    self.view.backgroundColor = ACCResourceColor(ACCColorBGCreation);
    
    self.smallPreviewController = [[ACCEditVideoSmallPreviewController alloc] initWithEditService:self.editService stickerContainerView:self.stickerContainerView previewSize:[self mediaSmallMediaContainerFrame].size];
    [self addChildViewController:self.smallPreviewController];
    [self.view addSubview:self.smallPreviewController.view];
    [self.smallPreviewController didMoveToParentViewController:self];
    
    ACCMasMaker(self.smallPreviewController.view, {
        make.width.equalTo(@([self mediaSmallMediaContainerFrame].size.width));
        make.height.equalTo(@([self mediaSmallMediaContainerFrame].size.height));
        make.top.equalTo(@([self mediaSmallMediaContainerFrame].origin.y));
        make.centerX.equalTo(self.view);
    });
    
    [self.view addSubview:self.contentContainerView];
    
    self.composerPanelViewController.delegate = self;
    [self addChildViewController:self.composerPanelViewController];
    [self.contentContainerView addSubview:self.composerPanelViewController.view];
    [self.composerPanelViewController didMoveToParentViewController:self];
    
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    self.contentContainerView.frame = CGRectMake(0, screenHeight, screenWidth, [self containerViewHeight]);
    
    ACCMasMaker(self.composerPanelViewController.view, {
        make.left.bottom.right.equalTo(self.contentContainerView);
        make.height.equalTo(@([self.composerPanelViewController composerPanelHeight]));
    });
    
    self.adjustmentContainerView = [[UIView alloc] init];
    self.adjustmentContainerView.hidden = YES;
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
        make.left.equalTo(self.adjustmentContainerView).offset(16);
        make.right.equalTo(self.adjustmentContainerView).offset(-16);
        make.height.equalTo(@(20));
        make.centerY.equalTo(self.adjustmentContainerView);
    });
    
    [self p_setupUIOptimization];
}

- (CGFloat)containerViewHeight
{
    return [self.composerPanelViewController composerPanelHeight];
}

#pragma mark - lazy init property

- (ACCEditVideoBeautyPanelViewController *)composerPanelViewController
{
    if (!_composerPanelViewController) {
        _composerPanelViewController = [[ACCEditVideoBeautyPanelViewController alloc] initWithViewModel:self.viewModel];
        [_composerPanelViewController updateUIConfig:self.uiConfig];
    }
    return _composerPanelViewController;
}

- (UIView *)contentContainerView
{
    if (!_contentContainerView) {
        _contentContainerView = [[UIView alloc] initWithFrame:CGRectZero];
        _contentContainerView.backgroundColor = ACCResourceColor(ACCColorBGCreation2);
        CGRect maskFrame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [self containerViewHeight]);
        _contentContainerView.layer.mask = [self topRoundCornerShapeLayerWithFrame:maskFrame];
    }
    return _contentContainerView;
}

- (AWERangeSlider *)slider
{
    if (!_slider) {
        _slider = [self.uiConfig makeNewSlider];
        _slider.delegate = self;
    }
    return _slider;
}

#pragma mark - AWESliderDelegate

- (void)slider:(AWESlider *)slider valueDidChanged:(float)value
{
    if (self.reappendEffectWhenSliderValueChange) {
        [self.viewModel.effectViewModel bringEffectWrapperToEnd:self.viewModel.selectedEffect];
        if ([self.delegate respondsToSelector:@selector(selectComposerBeautyEffect:ratio:oldEffect:)]) {
            [self.delegate selectComposerBeautyEffect:self.viewModel.selectedEffect
                                                ratio:self.viewModel.selectedEffect.currentRatio
                                            oldEffect:nil];
        }
        [self.viewModel.effectViewModel cacheAppliedEffects];
        self.reappendEffectWhenSliderValueChange = NO;
    }
    AWEComposerBeautyEffectWrapper *effect = self.viewModel.selectedEffect;
    if (effect) {
        float ratio = value / slider.maximumValue;
        [effect updateWithStrength:ratio];
        if ([self.delegate respondsToSelector:@selector(applyComposerBeautyEffect:ratio:)]) {
            [self.delegate applyComposerBeautyEffect:effect ratio:ratio];
        }
    }
}

- (void)slider:(AWESlider *)slider didFinishSlidingWithValue:(float)value
{
    float ratio = value / slider.maximumValue;
    
    AWEComposerBeautyEffectWrapper *effect = self.viewModel.selectedEffect;
    if (effect) {
        [self.viewModel.effectViewModel.cacheObj setRatio:ratio forEffect:effect];
        if ([self.delegate respondsToSelector:@selector(didFinishSlidingWithValue:forEffect:)]) {
            [self.delegate didFinishSlidingWithValue:ratio forEffect:effect];
        }

        [self.composerPanelViewController updateCurrentSelectedEffectWithStrength:ratio];
        [self p_handleUserModifiedStatus];
        
        self.reappendEffectWhenSliderValueChange = YES;
        [self trackBeautifyValueChanged:effect];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (touch.view == self.view) {
        return YES;
    }
    return NO;
}

#pragma mark - Actions

- (void)didClickCancelBtn:(UIButton *)btn
{
    if ([self.delegate respondsToSelector:@selector(didClickCancelButton)]) {
        [self.delegate didClickCancelButton];
    }
}

- (void)didClickSaveBtn:(UIButton *)btn
{
    if ([self.delegate respondsToSelector:@selector(didClickSaveButton)]) {
        [self.delegate didClickSaveButton];
    }
    
    self.adjustmentContainerView.hidden = YES;
    ACCBLOCK_INVOKE(self.externalDismissBlock);
}

#pragma mark - private

- (void)p_handleUserModifiedStatus
{
    self.viewModel.effectViewModel.didModifyStatus = YES;
    [self.composerPanelViewController updateResetButtonToDisabled:[self shouldDisableResetButton]];
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

- (void)p_bindViewModel
{
    @weakify(self);
    [[self.viewModel.currentCategorySignal deliverOnMainThread] subscribeNext:^(AWEComposerBeautyEffectCategoryWrapper * _Nullable x) {
        @strongify(self);
        [self.composerPanelViewController updateResetButtonToDisabled:[self shouldDisableResetButton]];
    }];
    
}

- (void)refreshSliderDefaultIndicatorPosition:(CGFloat)position
{
    self.slider.defaultIndicatorPosition = position;
}

- (void)refreshSliderWithEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper {
    if (!effectWrapper || effectWrapper.isNone || [effectWrapper isEffectSet]) {
        self.adjustmentContainerView.hidden = YES;
        return;
    }
    AWEComposerBeautyEffectItem *item = effectWrapper.items.firstObject;
    if (ACC_FLOAT_LESS_THAN(item.minValue, 0)) {
        self.slider.maximumValue = 100.0 / 2;
        self.slider.minimumValue = -100.0 / 2;
        self.slider.originPosition = 0.5f;
    } else {
        self.slider.maximumValue = 100.0;
        self.slider.minimumValue = 0;
        self.slider.originPosition = 0.f;
    }
    if (ACC_FLOAT_EQUAL_TO(item.minValue, item.defaultValue)) {
        self.slider.showDefaultIndicator = NO;
    } else {
        self.slider.showDefaultIndicator = YES;
        self.slider.defaultIndicatorPosition = item.defaultPosition;
    }
    // ！！这里effectWrapper 不能是EffectSet类型
    self.slider.value = effectWrapper.currentRatio * self.slider.maximumValue;
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

- (BOOL)shouldDisableResetButton
{
    for (AWEComposerBeautyEffectCategoryWrapper *categoryWrapper in self.viewModel.filteredCategories) {
        for (AWEComposerBeautyEffectWrapper *effectWrapper in categoryWrapper.effects) {
            if (effectWrapper.isEffectSet) {
                for (AWEComposerBeautyEffectWrapper *childEffect in effectWrapper.childEffects) {
                    if (!ACC_FLOAT_EQUAL_ZERO(childEffect.currentRatio)) {
                        return NO;
                    }
                }
            } else {
                if (!ACC_FLOAT_EQUAL_ZERO(effectWrapper.currentRatio)) {
                    return NO;
                }
            }
        }
    }
    return YES;
}

- (void)resetCategoryAllItemToZero:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
{
    [self.viewModel resetComposerCategoryAllItemToZero:categoryWrapper];
    
    [self reloadPanel];
    [self p_handleUserModifiedStatus];
    if ([self.delegate respondsToSelector:@selector(composerBeautyDidClearRatioForCategory:)]) {
        [self.delegate composerBeautyDidClearRatioForCategory:categoryWrapper];
    }
}

#pragma mark - track
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

- (void)trackSelectBeautifyTab:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.viewModel.referExtra];
    params[@"tab_name"] = categoryWrapper.categoryName;
    [ACCTracker() trackEvent:@"click_beautify_tab"
                                     params:params
                            needStagingFlag:NO];
}

- (NSDictionary *)commonTrackerParamsForEffectWrapper:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.viewModel.referExtra];
    params[@"enter_from"] = @"video_edit_page";
    AWEComposerBeautyEffectWrapper *parentEffectWrapper = effectWrapper.parentEffect;
    if (parentEffectWrapper) {
        IESEffectModel *effect = effectWrapper.effect;
        params[@"beautify_name_child"] = effect.effectName ?: @"";
        params[@"beautify_id_child"] = effect.effectIdentifier ?: @"";
    } else {
        parentEffectWrapper = effectWrapper;
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
    params[@"tab_name"] = categoryWrapper.categoryName;
    [ACCTracker() trackEvent:@"click_beautify_tab"
                                     params:params
                            needStagingFlag:NO];
}

- (void)trackResetAllButtonClick
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.viewModel.referExtra];
    params[@"enter_from"] = @"video_edit_page";
    params[@"tab_name"] = self.viewModel.currentCategory.categoryName;
    [ACCTracker() trackEvent:@"reset_beautify_popup"
                      params:params
             needStagingFlag:NO];
}

- (void)trackResetAllAlertWithConfirm:(BOOL)confirmed
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.viewModel.referExtra];
    params[@"enter_from"] = @"video_edit_page";
    params[@"event_type"] = confirmed ? @"confirm" : @"cancel";
    params[@"tab_name"] = self.viewModel.currentCategory.categoryName;
    [ACCTracker() trackEvent:@"reset_beautify_all"
                      params:params
             needStagingFlag:NO];
    
}

#pragma mark - AWEComposerBeautyPanelViewControllerDelegate

- (void)composerBeautyPanelDidSelectEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                                 oldEffect:(AWEComposerBeautyEffectWrapper *)oldEffectWrapper
                              fromDownload:(BOOL)fromDownload
{
    // 主动更新应用的子项
    if ([effectWrapper.parentEffect isEffectSet]) {
        [self.viewModel.effectViewModel updateAppliedChildEffect:effectWrapper forEffect:effectWrapper.parentEffect];
    }
    if ([effectWrapper isEffectSet]) {
        [self handleSelectEffectWrapper:effectWrapper.appliedChildEffect];
        [self trackBeautifyValueChanged:effectWrapper.appliedChildEffect];
        [self.composerPanelViewController setBottomBarHidden:YES animated:YES];
    } else {
        // 非互斥分类，点击none，把所有的小项强度置为0
        if (effectWrapper.isNone && !effectWrapper.categoryWrapper.exclusive) {
            [self resetCategoryAllItemToZero:effectWrapper.categoryWrapper];
        }
        
        [self.viewModel.effectViewModel updateEffectRatioFromCache:effectWrapper];
        [self handleSelectEffectWrapper:effectWrapper];
        [self trackBeautifyValueChanged:effectWrapper];
        
        if ([self.delegate respondsToSelector:@selector(selectComposerBeautyEffect:ratio:oldEffect:)]) {
            [self.delegate selectComposerBeautyEffect:effectWrapper
                                                ratio:effectWrapper.currentRatio
                                            oldEffect:oldEffectWrapper];
        }
    }
}

- (void)composerBeautyPanelDidSelectEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                           forParentObject:(NSObject *)parentItem
{
    if ([self.delegate respondsToSelector:@selector(selectComposerBeautyEffect:forParentItem:)]) {
        [self.delegate selectComposerBeautyEffect:effectWrapper forParentItem:parentItem];
    } else {
        if ([parentItem isKindOfClass:[AWEComposerBeautyEffectWrapper class]]) {
            [self.viewModel.effectViewModel updateAppliedChildEffect:effectWrapper forEffect:(AWEComposerBeautyEffectWrapper *)parentItem];
            [self p_handleUserModifiedStatus];
        } else if ([parentItem isKindOfClass:[AWEComposerBeautyEffectCategoryWrapper class]]) {
            [self.viewModel.effectViewModel updateSelectedEffect:effectWrapper forCategory:(AWEComposerBeautyEffectCategoryWrapper *)parentItem];
        }
    }
}

- (void)composerBeautyPanelDidUpdateCandidateEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper forParentItem:(NSString *)parentItemID
{
    if ([self.delegate respondsToSelector:@selector(updateCandidateComposerBeautyEffect:forParentItem:)]) {
        [self.delegate updateCandidateComposerBeautyEffect:effectWrapper forParentItem:parentItemID];
    } else {
        [self.viewModel.effectViewModel.cacheObj updateCandidateChildEffect:effectWrapper forParentItemID:parentItemID];
    }
}

- (void)handleSelectEffectWrapper:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    if (!effectWrapper.available) {
        self.adjustmentContainerView.hidden = YES;
        return ;
    }
    if (![self.viewModel.selectedEffect isEqual:effectWrapper]) {
        self.reappendEffectWhenSliderValueChange = YES;
    }
    self.viewModel.selectedEffect = effectWrapper;
    AWEEffectDownloadStatus downloadStatus = [[AWEComposerBeautyEffectDownloader defaultDownloader] downloadStatusOfEffect:effectWrapper];
    if (!effectWrapper || effectWrapper.isNone || [effectWrapper isEffectSet] || (downloadStatus != AWEEffectDownloadStatusDownloaded)) {
        self.adjustmentContainerView.hidden = YES;
    } else {
        self.adjustmentContainerView.hidden = NO;
        [self refreshSliderWithEffect:effectWrapper];
    }
}

- (void)composerBeautyPanelDidGoBackToCategoryPanel
{
    [self trackBeautifyValueChanged:self.viewModel.selectedEffect];
    [self handleSelectEffectWrapper:nil];
    [self.composerPanelViewController setBottomBarHidden:NO animated:YES];
}

- (void)composerBeautyPanelDidChangeToCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
{
    [self composerBeautyPanelDidChangeToCategory:categoryWrapper needTracker:YES];
    [self trackSelectBeautifyTab:categoryWrapper];
}

- (void)composerBeautyPanelDidTapResetButtonWithCompletion:(void (^)(void))completion
{
    [self trackResetAllButtonClick];
    [ACCAlert() showAlertWithTitle:ACCLocalizedString(@"beauty_default_tips", @"提示") description:ACCLocalizedString(@"beauty_default", @"确定恢复全部默认效果吗？") image:nil actionButtonTitle:ACCLocalizedString(@"beauty_default_discard", @"确定") cancelButtonTitle:ACCLocalizedString(@"beauty_default_keep", @"取消") actionBlock:^{
        [self trackResetAllAlertWithConfirm:YES];
        if ([self.delegate respondsToSelector:@selector(composerBeautyViewControllerWillReset)]) {
            [self.delegate composerBeautyViewControllerWillReset];
        }
        [self.viewModel resetAllComposerBeautyEffects];
        if ([self.delegate respondsToSelector:@selector(composerBeautyViewControllerDidReset)]) {
            [self.delegate composerBeautyViewControllerDidReset];
        }
        [self refreshSliderWithEffect:self.viewModel.selectedEffect];
        [self p_handleUserModifiedStatus];
        completion();
    } cancelBlock:^{
        [self trackResetAllAlertWithConfirm:NO];
    }];
}

- (void)composerBeautyPanelDidSwitch:(BOOL)isOn isManually:(BOOL)isManually
{
    if ([self.delegate respondsToSelector:@selector(composerBeautyViewControllerDidSwitch:isManually:)]) {
        [self.delegate composerBeautyViewControllerDidSwitch:isOn isManually:isManually];
    }
}

- (void)composerBeautyPanelDidFinishDownloadingAllEffects
{
    if ([self.delegate respondsToSelector:@selector(composerBeautyViewControllerDidFinishDownloadingAllEffects)]) {
        [self.delegate composerBeautyViewControllerDidFinishDownloadingAllEffects];
    }
}

- (void)composerBeautyPanelDidChangeToCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper needTracker:(BOOL)needTracker
{
    if ([categoryWrapper.userSelectedEffect isEffectSet]) {
        if ([self.composerPanelViewController isShowingChildItems]) {
            [self handleSelectEffectWrapper:categoryWrapper.userSelectedEffect.appliedChildEffect];
        } else {
            [self handleSelectEffectWrapper:categoryWrapper.userSelectedEffect];
        }
    } else {
        [self handleSelectEffectWrapper:categoryWrapper.userSelectedEffect];
    }
    [self.viewModel.effectViewModel.cacheObj cacheSelectedCategory:categoryWrapper.category.categoryIdentifier];
    
    if ([self.delegate respondsToSelector:@selector(selectCategory:)]) {
        [self.delegate selectCategory:categoryWrapper];
    }

    if (needTracker) {
        [self trackBeautifyValueChanged:self.viewModel.selectedEffect];
        [self trackChangeBeautifyCategory:categoryWrapper];
    }
}

- (UIButton *)cancelBtn
{
    if (!_cancelBtn) {
        _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelBtn.alpha = 0;
        [_cancelBtn setTitle:ACCLocalizedCurrentString(@"cancel") forState:UIControlStateNormal];
        [_cancelBtn.titleLabel setFont:[ACCFont() acc_systemFontOfSize:17 weight:ACCFontWeightRegular]];
        UIColor *titleColor = ACCResourceColor(ACCUIColorConstTextInverse);
        [_cancelBtn setTitleColor:titleColor forState:UIControlStateNormal];
        [_cancelBtn addTarget:self action:@selector(didClickCancelBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}

- (UIButton *)saveBtn
{
    if (!_saveBtn) {
        _saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _saveBtn.alpha = 0;
        [_saveBtn setTitle:ACCLocalizedString(@"save", @"save") forState:UIControlStateNormal];
        [_saveBtn.titleLabel setFont:[ACCFont() acc_systemFontOfSize:17 weight:ACCFontWeightMedium]];
        UIColor *titleColor = ACCResourceColor(ACCUIColorConstTextInverse);
        [_saveBtn setTitleColor:titleColor forState:UIControlStateNormal];
        [_saveBtn addTarget:self action:@selector(didClickSaveBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _saveBtn;
}

#pragma mark - ACCEditTransitionViewControllerProtocol

- (UIImage *)dismissSnapImage
{
    return [self.smallPreviewController.view acc_snapshotImageAfterScreenUpdates:NO withSize:self.view.bounds.size];
}

#pragma mark - AWEMediaSmallAnimationProtocol

- (UIView *)mediaSmallMediaContainer
{
    return self.smallPreviewController.view;
}

- (UIView *)mediaSmallBottomView
{
    return self.contentContainerView;
}

- (CGRect)mediaSmallMediaContainerFrame
{
    CGFloat playerY = ACC_STATUS_BAR_NORMAL_HEIGHT;
    if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypeDisabled) {
        playerY += 52;
    }
    
    CGFloat playerHeight = [UIScreen mainScreen].bounds.size.height - (playerY + [self containerViewHeight] + 16);
    CGFloat playerWidth = self.view.acc_width;
    CGFloat playerX = (self.view.bounds.size.width - playerWidth) / 2;
    CGSize videoSize = CGSizeMake(540, 960);
    if (!CGRectEqualToRect(self.viewModel.publishModel.repoVideoInfo.playerFrame, CGRectZero)) {
        videoSize = self.viewModel.publishModel.repoVideoInfo.playerFrame.size;
    }
    return AVMakeRectWithAspectRatioInsideRect(videoSize, CGRectMake(playerX, playerY, playerWidth, playerHeight));
}

- (NSArray<UIView *>*)displayTopViews
{
    NSMutableArray<UIView *> *topViews = [NSMutableArray array];
    [topViews acc_addObject:self.cancelBtn];
    [topViews acc_addObject:self.saveBtn];
    return topViews.copy;
}

#pragma mark - UI Optimization

/// Adjust UI according to AB
- (void)p_setupUIOptimization
{
    if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypeDisabled) {
        [self p_setupUIOptimizationPlayBtn:NO];
        [self p_setupUIOptimizationSaveCancelBtn:NO];
    } else if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypeSaveCancelBtn) {
        [self p_setupUIOptimizationPlayBtn:NO];
        [self p_setupUIOptimizationSaveCancelBtn:YES];
    } else if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypePlayBtn) {
        [self p_setupUIOptimizationPlayBtn:YES];
        [self p_setupUIOptimizationSaveCancelBtn:YES];
        [self p_setupUIOptimizationReplaceIconWithText:YES];
    } else if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypeReplaceIconWithText) {
        [self p_setupUIOptimizationPlayBtn:YES];
        [self p_setupUIOptimizationSaveCancelBtn:YES];
        [self p_setupUIOptimizationReplaceIconWithText:NO];
    }
}

- (void)p_setupUIOptimizationSaveCancelBtn:(BOOL)shouldOptimized
{
    if (shouldOptimized) {
        [self.contentContainerView addSubview:self.cancelBtn];
        [self.contentContainerView addSubview:self.saveBtn];
        self.composerPanelViewController.cancelBtn = self.cancelBtn;
        self.composerPanelViewController.saveBtn = self.saveBtn;
        
        ACCMasReMaker(self.cancelBtn, {
            make.left.equalTo(@16);
            make.top.mas_equalTo(self.contentContainerView).offset(14);
            make.height.equalTo(@(24));
        });
        
        ACCMasReMaker(self.saveBtn, {
            make.right.equalTo(@-16);
            make.top.mas_equalTo(self.contentContainerView).offset(14);
            make.height.equalTo(@(24));
        });
    } else {
        [self.view addSubview:self.cancelBtn];
        [self.view addSubview:self.saveBtn];

        ACCMasReMaker(self.cancelBtn, {
            make.left.equalTo(@16);
            make.centerY.equalTo(self.view.mas_top).offset(52/2 + ([UIDevice acc_isIPhoneX] ? 44 : 0));
            make.height.equalTo(@(44));
        });
        
        ACCMasReMaker(self.saveBtn, {
            make.right.equalTo(@-16);
            make.centerY.equalTo(self.view.mas_top).offset(52/2 + ([UIDevice acc_isIPhoneX] ? 44 : 0));
            make.height.equalTo(@(44));
        });
    }
}

- (void)p_setupUIOptimizationPlayBtn:(BOOL)shouldOptimized
{
    if (shouldOptimized) {
        self.composerPanelViewController.stopAndPlayBtn = self.smallPreviewController.stopAndPlayBtn;
        
        [self.smallPreviewController.stopAndPlayBtn removeFromSuperview];
        for(UIView *subview in [self.smallPreviewController.stopAndPlayBtn subviews]) {
           [subview removeFromSuperview];
        }
        [self.smallPreviewController.stopAndPlayBtn setImage:ACCResourceImage(@"cameraStickerPlay") forState:UIControlStateNormal];
        [self.smallPreviewController.stopAndPlayBtn setImage:ACCResourceImage(@"cameraStickerPause") forState:UIControlStateSelected];
        [self.contentContainerView addSubview:self.smallPreviewController.stopAndPlayBtn];
        ACCMasReMaker(self.smallPreviewController.stopAndPlayBtn, {
            make.centerX.mas_equalTo(self.contentContainerView);
            make.width.height.mas_equalTo(@28);
            make.top.mas_equalTo(self.contentContainerView).offset(12);
        });
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self.smallPreviewController action:@selector(didClickStopAndPlay)];
        [self.smallPreviewController.playerContainer addGestureRecognizer:tapGesture];
        self.smallPreviewController.playerContainer.userInteractionEnabled = YES;
    }
}

- (void)p_setupUIOptimizationReplaceIconWithText:(BOOL)shouldUseText
{
    if (!shouldUseText) {
        [self.cancelBtn setImage:ACCResourceImage(@"icon_edit_bar_cancel") forState:UIControlStateNormal];
        [self.cancelBtn setImage:ACCResourceImage(@"icon_edit_bar_cancel") forState:UIControlStateHighlighted];
        [self.cancelBtn setTitle:nil forState:UIControlStateNormal];
        [self.cancelBtn setTitle:nil forState:UIControlStateHighlighted];
        ACCMasReMaker(self.cancelBtn, {
            make.top.equalTo(@14);
            make.left.equalTo(@16);
            make.width.height.equalTo(@(24));
        });
        
        [self.saveBtn setImage:ACCResourceImage(@"icon_edit_bar_done") forState:UIControlStateNormal];
        [self.saveBtn setImage:ACCResourceImage(@"icon_edit_bar_done") forState:UIControlStateHighlighted];
        [self.saveBtn setTitle:nil forState:UIControlStateNormal];
        [self.saveBtn setTitle:nil forState:UIControlStateHighlighted];
        ACCMasReMaker(self.saveBtn, {
            make.top.equalTo(@14);
            make.right.equalTo(@-16);
            make.width.height.equalTo(@(24));
        });
    }
}

@end
