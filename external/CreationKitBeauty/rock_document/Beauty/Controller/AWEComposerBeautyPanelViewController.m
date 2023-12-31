//
//  AWEComposerBeautyPanelViewController.m
//  CameraClient
//
//  Created by HuangHongsen on 2019/10/31.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import "AWEComposerBeautyPanelViewController.h"
#import "AWEComposerBeautyPrimaryItemsViewController.h"
#import "AWEComposerBeautySubItemsViewController.h"
#import "AWEComposerBeautyTopBarViewController.h"
#import <CreationKitArch/IESEffectModel+ACCSticker.h>
#import "AWEBeautyControlConstructor.h"

#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitBeauty/AWEComposerBeautyViewModel+Signal.h>
#import <ReactiveObjC/RACSignal+Operations.h>
#import <Masonry/View+MASAdditions.h>

@interface AWEComposerBeautyPanelViewController ()<
AWEComposerBeautyTopBarViewControllerDelegate,
AWEComposerBeautySubItemsViewControllerDelegate,
AWEComposerBeautyPrimaryItemsViewControllerDelegate>
@property (nonatomic, strong, readwrite) AWEComposerBeautyTopBarViewController *topBarViewController;
@property (nonatomic, strong, readwrite) AWEComposerBeautyPrimaryItemsViewController *primaryViewController;
@property (nonatomic, strong, readwrite) AWEComposerBeautySubItemsViewController *effectsViewController;
@property (nonatomic, strong, readwrite) AWEComposerBeautySubItemsViewController *childEffectsViewController;
@property (nonatomic, strong, readwrite) UIViewController *currentViewController; // current vc
@property (nonatomic, strong, readwrite) UIView *headerView;
@property (nonatomic, strong, readwrite) UILabel *beautyPromptLabel;
@property (nonatomic, strong, readwrite) UIButton *resetButton;
@property (nonatomic, strong, readwrite) AWEComposerBeautyViewModel *viewModel;
@property (nonatomic, strong, readwrite) id<ACCBeautyUIConfigProtocol> uiConfig;
@property (nonatomic, assign) BOOL childEffectsDisplayed;
@property (nonatomic, assign) BOOL couldOptimizeUI;
@property (nonatomic, strong) UILabel *featureNameLabel;
@property (nonatomic, strong) UIView *headerSeparateLineView;
@end

/*    structure:
 --------------------
 topBarVC
 |__itemsVC: primaryVC or effectsVC or childEffectsVC

 all the selections in VCs were delegated to this VC
 so the most of logics of panel were written here.

 self.viewModel.currentCategory and self.viewModel.selectedEffect
 were Observed with RAC. see AWEComposerBeautyViewModel+Signal.m

 primaryVC
 |__effectsVC
    |__ childEffetsVC

 1. change tab
 2. chose subitem in primaryVC --> effectsVC
 3. chose subitem in effectsVC --> childEffectsVC
 4. tap back button from childEffectsVC --> effectsVC
 5. tap back button from effectsVC --> primaryVC
 =====================================================
*/

@implementation AWEComposerBeautyPanelViewController

#pragma mark - LifeCycle

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

- (instancetype)initWithViewModel:(AWEComposerBeautyViewModel *)viewModel
{
    self = [super init];
    if (self) {
        _viewModel = viewModel;
    }
    return self;
}

- (instancetype)initWithViewModelAndOptimizedUI:(AWEComposerBeautyViewModel *)viewModel
{
    self = [self initWithViewModel:viewModel];
    if (self) {
        self.couldOptimizeUI = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupItemsViewController];
    [self p_setupTopBar];
    [self p_bindViewModel];
}

- (void)p_bindViewModel
{
    @weakify(self);
    [[self.viewModel.currentCategorySignal deliverOnMainThread] subscribeNext:^(AWEComposerBeautyEffectCategoryWrapper * _Nullable x) {
        @strongify(self);
        if (!self.viewModel.isPrimaryPanelEnabled && [self.delegate respondsToSelector:@selector(composerBeautyPanelDidSwitch:isManually:)]) {
            BOOL isOn = [self.viewModel.effectViewModel.cacheObj isCategorySwitchOn:self.viewModel.currentCategory];
            [self.delegate composerBeautyPanelDidSwitch:isOn isManually:NO];
        }
        [self reloadPanel];
    }];
}

#pragma mark - Public

- (void)updateUIConfig:(id<ACCBeautyUIConfigProtocol>)config
{
    self.uiConfig = config;
    [self.topBarViewController updateUIConfig:config];
}

// 1. if beautyViewModel.currentCategory(RAC Observed) is changed
// 2. called outside, BeautyPanel will show --> BeautyVC reload panel --> BeautyPanelVC reload Panel
- (void)reloadPanel
{
    BOOL titlesChagned = NO;
    if ([[self tabTitles] count] != [self.topBarViewController.titles count]) {
        titlesChagned = YES;
    } else {
        for (NSInteger index = 0; index < [[self tabTitles] count]; index++) {
            if (![[self tabTitles][index] isEqualToString:self.topBarViewController.titles[index]]) {
                titlesChagned = YES;
                break;
            }
        }
    }
    if (titlesChagned) {
        [self.topBarViewController updateWithTitles:[self tabTitles]];
    }

    NSInteger index = [self.viewModel.filteredCategories indexOfObject:self.viewModel.currentCategory];
    if (([self tabTitles]).count > index) {
        // TODO: need translation, contact PM xumengrong for further progress
        self.beautyPromptLabel.text = @"";
    } else {
        self.beautyPromptLabel.text = @"";
    }

    // change topBar
    [self.topBarViewController selectItemAtIndex:index];

    // reload the itemsViewController's data and ui
    [self p_updateChildEffectsWithCurrentCategory];
}

- (void)updateCurrentSelectedEffectWithStrength:(CGFloat)strength
{
    // set white point and scroll to this item
    [self.effectsViewController reloadCurrentItem];
}

- (BOOL)isShowingChildItems
{
    return self.currentViewController == self.childEffectsViewController;
}

- (BOOL)isShowingEffectsItems
{
    return self.currentViewController == self.effectsViewController;
}

- (BOOL)isShowingPrimayItems
{
    return self.currentViewController == self.primaryViewController;
}

- (void)updateResetButtonToDisabled:(BOOL)disabled
{
    [self.topBarViewController updateResetButtonToDisabled:disabled];
    self.resetButton.enabled = !disabled;
}

- (void)updateBeautySubItemsViewIfIsOn:(BOOL)isOn
{
    [self.effectsViewController setShouldShowAppliedIndicatorForAllCells:isOn];
    [self.childEffectsViewController setShouldShowAppliedIndicatorForAllCells:isOn];
}

- (void)updateBeautySwitchIsOn:(BOOL)isOn isManually:(BOOL)isManually
{
    [self.viewModel.effectViewModel.cacheObj setCategory:self.viewModel.currentCategory switchOn:isOn];
    [self.effectsViewController reloadBeautySubItemsViewIfIsOn:isOn changedByUser:isManually];
    [self updateBeautySubItemsViewIfIsOn:isOn];
}

- (void)updateResetModeButton
{
    [self.effectsViewController updateResetModeButton];
}

#pragma mark - ChildViewController - Setup

- (CGFloat)p_animationOffset
{
    return [self.effectsViewController itemWidth];
}

- (NSTimeInterval)p_animationDuration
{
    return 0.3;
}

- (NSArray <NSString *> *)tabTitles
{
    NSMutableArray *tabTitles = [NSMutableArray array];
    for (AWEComposerBeautyEffectCategoryWrapper *category in self.viewModel.filteredCategories) {
        if (category.categoryName) {
            [tabTitles addObject:category.categoryName];
        }
    }
    return [tabTitles copy];
}

- (void)p_setupTopBar
{
    CGFloat headerHeight = 52.0f;
    CGFloat leftOffset = 16;
    CGFloat sepLineHeight = 1 / ACC_SCREEN_SCALE;
    self.headerView = [[UIView alloc] init];
    [self.view addSubview:self.headerView];
    ACCMasMaker(self.headerView, {
        make.leading.trailing.top.equalTo(self.view);
        make.height.equalTo(@(52));
    });
    ACCMasMaker(self.topBarViewController.view, {
        make.leading.trailing.top.equalTo(self.view);
        make.height.equalTo(@(headerHeight));
    });
    
    self.featureNameLabel = [[UILabel alloc] init];
    self.featureNameLabel.font = [ACCFont() acc_systemFontOfSize:16 weight:ACCFontWeightMedium];
    self.featureNameLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
    self.featureNameLabel.text = ACCLocalizedString(@"com_mig_beauty", @"美颜");
    [self.headerView addSubview:self.featureNameLabel];
    ACCMasMaker(self.featureNameLabel, {
        make.leading.equalTo(self.headerView).offset(leftOffset);
        make.centerY.equalTo(self.headerView);
    });
    
    self.resetButton = [AWEBeautyControlConstructor resetButton];
    [self.resetButton addTarget:self action:@selector(composerBeautyTopBarDidTapResetButton) forControlEvents:UIControlEventTouchUpInside];
    self.resetButton.layer.borderWidth = 0.f;
    self.resetButton.layer.borderColor = [UIColor clearColor].CGColor;
    self.resetButton.backgroundColor = [UIColor clearColor];
    [self.resetButton setTitle:nil forState:UIControlStateNormal];
    [self.headerView addSubview:self.resetButton];
    ACCMasMaker(self.resetButton, {
        make.trailing.equalTo(self.headerView).offset(-leftOffset);
        make.centerY.equalTo(self.headerView);
    });
    
    self.headerSeparateLineView = [[UIView alloc] init];
    self.headerSeparateLineView.backgroundColor = ACCResourceColor(ACCUIColorConstLineInverse);
    [self.headerView addSubview:self.headerSeparateLineView];
    ACCMasMaker(self.headerSeparateLineView, {
        make.leading.trailing.bottom.equalTo(self.headerView);
        make.height.equalTo(@(sepLineHeight));
    });
    
    self.topBarViewController = [[AWEComposerBeautyTopBarViewController alloc] initWithTitles:[self tabTitles]];
    self.topBarViewController.resetButton.hidden = YES;
    self.topBarViewController.delegate = self;
    self.topBarViewController.itemHeight = [self.uiConfig topBarHeight];
    [self.topBarViewController updateUIConfig:self.uiConfig];
    [self addChildViewController:self.topBarViewController];
    [self.view addSubview:self.topBarViewController.view];
    [self.topBarViewController didMoveToParentViewController:self];
    ACCMasMaker(self.topBarViewController.view, {
        make.leading.trailing.equalTo(self.view);
        make.height.equalTo(@(self.uiConfig.topBarHeight));
        make.bottom.mas_equalTo(self.view).offset(-ACC_IPHONE_X_BOTTOM_OFFSET);
    });
}

- (void)p_setupItemsViewController
{
    [self p_setupPrimaryViewController];
    [self p_setupEffectViewController];
    [self p_setupChildEffectsViewController];
    [self p_showNeededViewController];
}

- (void)p_showNeededViewController
{
    AWEComposerBeautyEffectCategoryWrapper *currentCategory = self.viewModel.currentCategory;

    if (currentCategory.isPrimaryCategory) {
        [self p_insertViewController:self.primaryViewController removeViewController:nil animated:NO leftToRight:YES completion:nil];
    } else {
        [self p_insertViewController:self.effectsViewController removeViewController:nil animated:NO leftToRight:YES completion:nil];
    }
}

- (void)p_setupPrimaryViewController
{
    self.primaryViewController = [[AWEComposerBeautyPrimaryItemsViewController alloc] initWithViewModel:self.viewModel PrimaryCategory:self.viewModel.currentCategory selectedChildCategory:self.viewModel.currentCategory.selectedChildCategory];

    self.primaryViewController.delegate = self;
    [self.primaryViewController updateUIConfig:self.uiConfig];
}

- (void)p_setupEffectViewController
{
    self.effectsViewController = [[AWEComposerBeautySubItemsViewController alloc] initWithViewModel:self.viewModel parentCategory:nil OrParentEffect:nil];

    self.effectsViewController.delegate = self;
    [self.effectsViewController updateUIConfig:self.uiConfig];
}

- (void)p_setupChildEffectsViewController
{
    self.childEffectsViewController = [[AWEComposerBeautySubItemsViewController alloc] initWithViewModel:self.viewModel parentCategory:nil OrParentEffect:nil];

    self.childEffectsViewController.delegate = self;
    [self.childEffectsViewController updateUIConfig:self.uiConfig];
}

- (void)p_makePanelContraintsWithView:(UIView *)view
{
    ACCMasUpdate(view, {
        make.top.equalTo(self.view).with.offset(self.uiConfig.contentCollectionViewTopOffset);
        make.leading.trailing.equalTo(self.view);
        make.height.equalTo(@(self.uiConfig.contentCollectionViewHeight));
    });
}

#pragma mark - ChildViewController - Change

// called if reload Panel
// example: self.viewModel.currentCategory was changed
- (void)p_updateChildEffectsWithCurrentCategory
{
    // only reload data here
    AWEComposerBeautyEffectCategoryWrapper *currentCategory = self.viewModel.currentCategory;

    AWEComposerBeautyEffectWrapper *userSelectedEffect = currentCategory.userSelectedEffect;

    BOOL needPrimaryVC = currentCategory.isPrimaryCategory && currentCategory.userSelectedChildCategory == nil;

    if (needPrimaryVC) { /// a patch, show primary panel at the first time enter shoot page
        [self p_insertViewController:self.primaryViewController removeViewController:self.effectsViewController animated:NO completion:nil];
        currentCategory.userSelectedChildCategory = currentCategory.selectedChildCategory ?: currentCategory.defaultChildCategory;
    }

    BOOL isPrimary = self.currentViewController == self.primaryViewController;

    BOOL isChildEffects = self.currentViewController == self.childEffectsViewController && userSelectedEffect.childEffects.count > 0;

    BOOL isEffect = self.currentViewController == self.effectsViewController;

    if (!isPrimary && currentCategory.isPrimaryCategory && currentCategory.selectedChildCategory) {
        // primary child category, use effectVC
        currentCategory = currentCategory.selectedChildCategory;
        userSelectedEffect = currentCategory.userSelectedEffect;
    }

    if (isPrimary) { // primary
        // update data
        [self.primaryViewController updateWithViewModel:self.viewModel PrimaryCategory:currentCategory selectedChildCategory:currentCategory.selectedChildCategory];

    } else if (isEffect) { // effect
        // update data
        [self.effectsViewController updateWithParentCategory:currentCategory OrParentEffect:nil];

    } else if (isChildEffects) { // effectSet
        // update data
        [self.childEffectsViewController updateWithParentCategory:nil OrParentEffect:userSelectedEffect];
    }

    NSDictionary *infoDict = @{@"currentVC" : self.currentViewController ?: @"",
                               @"currentCategory" : currentCategory.category.categoryName ?: @"",
                               @"userselectedEffect" : userSelectedEffect.effect.effectName ?: @""
    };
    NSString *infoString = [NSString stringWithFormat:@"ComposerBeautyPrimary-DEBUG: updateVC info:%@", infoDict];
    NSString *logString = [@[@"==========", infoString, @"==========="] componentsJoinedByString:@"\n"];
    AWELogToolInfo2(@"beauty", AWELogToolTagRecord, @"%@", logString);
}

- (void)p_insertViewControllerWithCurrentCategory
{
    AWEComposerBeautyEffectCategoryWrapper *currentCategory = self.viewModel.currentCategory;
    AWEComposerBeautyEffectWrapper *userSelectedEffect = currentCategory.userSelectedEffect;

    BOOL isPrimary = currentCategory.isPrimaryCategory;
    BOOL isChildEffects = userSelectedEffect && userSelectedEffect.childEffects.count > 0;
    BOOL isEffect = !isChildEffects && !isPrimary;

    if (isPrimary) { // primary
        // update data
        [self.primaryViewController updateWithViewModel:self.viewModel PrimaryCategory:currentCategory selectedChildCategory:currentCategory.selectedChildCategory];
        // insert vc
        [self p_insertViewController:self.primaryViewController removeViewController:self.effectsViewController animated:NO completion:nil];
    } else if (isEffect) { // effect
        // update data
        [self.effectsViewController updateWithParentCategory:currentCategory OrParentEffect:nil];
        // insert vc
        [self p_insertViewController:self.effectsViewController removeViewController:self.primaryViewController animated:NO completion:nil];
    } else if (isChildEffects) { // effectSet
        // update data
        [self.childEffectsViewController updateWithParentCategory:nil OrParentEffect:userSelectedEffect];
        // insert vc
        [self p_insertViewController:self.childEffectsViewController removeViewController:self.effectsViewController animated:NO completion:nil];
    }

    NSDictionary *infoDict = @{@"currentVC" : self.currentViewController ?: @"",
                               @"currentCategory" : currentCategory.category.categoryName ?: @"",
                               @"userselectedEffect" : userSelectedEffect.effect.effectName ?: @""
    };
    NSString *infoString = [NSString stringWithFormat:@"ComposerBeautyPrimary-DEBUG: changeVC info:%@", infoDict];
    NSString *logString = [@[@"==========", infoString, @"==========="] componentsJoinedByString:@"\n"];
    AWELogToolInfo2(@"beauty", AWELogToolTagRecord, @"%@", logString);
}

// default animation is from left to right;
-(void)p_insertViewController:(UIViewController *)insertController
         removeViewController:(UIViewController *)removeController
                     animated:(BOOL)animated
                   completion:(dispatch_block_t)completion
{
    [self p_insertViewController:insertController removeViewController:removeController animated:animated leftToRight:YES completion:completion];
}

/// side effect:  remove the removeController.view from superView
-(void)p_insertViewController:(UIViewController *)insertController
         removeViewController:(UIViewController *)removeController
                     animated:(BOOL)animated
                  leftToRight:(BOOL)leftToRight
                   completion:(dispatch_block_t)completion
{
    if (!insertController) {
        return;
    }

    CGFloat duration = animated ? [self p_animationDuration] : 0;
    CGFloat offset = leftToRight ? [self p_animationOffset] : -[self p_animationOffset];

    removeController.view.userInteractionEnabled = NO;

    [self.view addSubview:insertController.view];
    [self p_makePanelContraintsWithView:insertController.view]; // make contraints

    [self addChildViewController:insertController];
    [insertController didMoveToParentViewController:self];
    insertController.view.userInteractionEnabled = NO;

    insertController.view.alpha = 0.1f;
    insertController.view.transform = CGAffineTransformMakeTranslation(offset, 0);

    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        insertController.view.alpha = 1.f;
        insertController.view.transform = CGAffineTransformIdentity;
        removeController.view.alpha = 0.f;
        removeController.view.transform = CGAffineTransformMakeTranslation(-offset, 0);
    } completion:^(BOOL finished) {
        insertController.view.userInteractionEnabled = YES;
        removeController.view.userInteractionEnabled = YES;
        removeController.view.transform = CGAffineTransformIdentity;
        [removeController willMoveToParentViewController:nil];
        [removeController.view removeFromSuperview]; // constraints would be removed
        [removeController removeFromParentViewController];
    }];

    self.currentViewController = insertController ?: self.currentViewController;

    ACCBLOCK_INVOKE(completion);
}

- (void)p_showChildEffectsForEffectWrapper:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    // update vc data
    [self.childEffectsViewController updateWithParentCategory:nil OrParentEffect:effectWrapper];

    // topbar animation
    if (self.viewModel.currentCategory.isPrimaryCategory) {
        [self.topBarViewController showTitleToSubTitleWithSubTitle:effectWrapper.effect.effectName duration:[self p_animationDuration]];
    } else {
        [self.topBarViewController showCollectionToTitleWithTitle:effectWrapper.effect.effectName duration:[self p_animationDuration]];
    }

    // items animation
    [self p_insertViewController:self.childEffectsViewController removeViewController:self.effectsViewController animated:YES completion:nil];
}

- (void)p_closeChildEffectsViewControllerWithAnimated:(BOOL)animated
{
    [self p_insertViewController:self.effectsViewController removeViewController:self.childEffectsViewController animated:YES completion:nil];
    self.currentViewController = self.effectsViewController;
}

#pragma mark - AWEComposerBeautyTopBarViewController - Delegate

- (void)composerBeautyTopBarDidTapBackButton
{
    self.viewModel.currentCategory.userSelectedEffect = nil;

    if (self.currentViewController == self.effectsViewController) { // effects --> primary
        if (!ACC_isEmptyArray(self.viewModel.currentCategory.childCategories)) {

            [self p_insertViewController:self.primaryViewController
                    removeViewController:self.effectsViewController
                                animated:YES
                             leftToRight:NO
                              completion:nil];

            [self.primaryViewController updateWithViewModel:self.viewModel PrimaryCategory:self.viewModel.currentCategory selectedChildCategory:self.viewModel.currentCategory.selectedChildCategory];

            [self.topBarViewController showTitleToCollectionWithDuration:[self p_animationDuration]];
        } // no else
    } else if (self.currentViewController == self.childEffectsViewController) {
        if (!ACC_isEmptyArray(self.viewModel.currentCategory.childCategories)) { // child effects --> effects --> primary

            AWEComposerBeautyEffectCategoryWrapper *category = self.viewModel.currentCategory.selectedChildCategory;

            [self p_insertViewController:self.effectsViewController
                    removeViewController:self.childEffectsViewController
                                animated:YES
                             leftToRight:NO
                              completion:nil];

            [self.effectsViewController updateWithParentCategory:category OrParentEffect:nil];

            [self.topBarViewController showSubTitleToTitleWithTitle:category.primaryCategoryName duration:[self p_animationDuration]];

        } else { // child effects --> effects
            self.viewModel.currentCategory.userSelectedEffect = nil;

            [self p_insertViewController:self.effectsViewController
                    removeViewController:self.childEffectsViewController
                                animated:YES
                             leftToRight:NO
                              completion:nil];

            [self.effectsViewController updateWithEffectWrappers:self.viewModel.currentCategory.effects
                                                    parentItemID:self.viewModel.currentCategory.category.categoryIdentifier
                                                  selectedEffect:self.viewModel.currentCategory.selectedEffect
                                                       exclusive:NO];

            [self.topBarViewController showTitleToCollectionWithDuration:[self p_animationDuration]];
        }
    }

    // deleagte outside
    if ([self.delegate respondsToSelector:@selector(composerBeautyPanelDidGoBackToCategoryPanel)]) {
        [self.delegate composerBeautyPanelDidGoBackToCategoryPanel];
    }

}

- (void)composerBeautyTopBarDidSelectTabAtIndex:(NSInteger)index
{
    if (index < [self.viewModel.filteredCategories count]) {

        // RACObserve(currentCategory) -> reloadPanel
        // RACObserve(selectedEffect)
        self.viewModel.currentCategory = self.viewModel.filteredCategories[index];

        // insert the currect vc if need change vc
        [self p_insertViewControllerWithCurrentCategory];

        if ([self.delegate respondsToSelector:@selector(composerBeautyPanelDidChangeToCategory:)]) {
            [self.delegate composerBeautyPanelDidChangeToCategory:self.viewModel.currentCategory];
        }
    }
}

- (void)composerBeautyTopBarDidTapResetButton
{
    if ([self.delegate respondsToSelector:@selector(composerBeautyPanelDidTapResetButtonWithCompletion:)]) {
        @weakify(self);
        [self.delegate composerBeautyPanelDidTapResetButtonWithCompletion:^{
            @strongify(self);
            [self updateBeautySubItemsViewIfIsOn:YES];
            [self.effectsViewController reloadPanel];
            [self.childEffectsViewController reloadPanel];
            [self.primaryViewController reloadPanel];
        }];
    }
}

- (void)composerBeautyTopBarDidSwitch:(BOOL)isOn isManually:(BOOL)isManually
{
    if (isManually) {
        [self trackToggleBeautySwitchManuallyWithFinalState:isOn];
    }
    if ([self.delegate respondsToSelector:@selector(composerBeautyPanelDidSwitch:isManually:)]) {
        [self.delegate composerBeautyPanelDidSwitch:isOn isManually:isManually];
    }
    [self.effectsViewController setShouldShowAppliedIndicatorForAllCells:isOn];
    [self.childEffectsViewController setShouldShowAppliedIndicatorForAllCells:isOn];
}

#pragma mark - AWEComposerBeautySubItemsViewController - Delegate
// select an effectSet
- (void)composerSubItemsViewController:(AWEComposerBeautySubItemsViewController *)viewController
                    didSelectEffectSet:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    if ([self.viewModel enableBeautyCategorySwitch]) {
        [self updateBeautySwitchIsOn:YES isManually:NO];
    }

    if ([self.delegate respondsToSelector:@selector(composerBeautyPanelDidSelectEffect:forParentObject:)]) {
        [self.delegate composerBeautyPanelDidSelectEffect:effectWrapper forParentObject:self.viewModel.currentCategory];
    }

    // update viewModel selected effectWrapper
    [self.viewModel.effectViewModel updateSelectedEffect:effectWrapper forCategory:self.viewModel.currentCategory];

    // show childEffects viewController
    [self p_showChildEffectsForEffectWrapper:effectWrapper];

    if ([self.delegate respondsToSelector:@selector(composerBeautyPanelDidSelectEffect:oldEffect:fromDownload:)]) {
        [self.delegate composerBeautyPanelDidSelectEffect:effectWrapper oldEffect:nil fromDownload:NO];
    }
    [self.effectsViewController reloadCurrentItem];
}

// select an effect, if exclusive, canceledEffect works
- (void)composerSubItemsViewController:(AWEComposerBeautySubItemsViewController *)viewController
                       didSelectEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                        canceledEffect:(AWEComposerBeautyEffectWrapper *)canceledEffect
                          fromDownload:(BOOL)fromDownload
{
    self.currentViewController = viewController;

    if ([self.viewModel enableBeautyCategorySwitch]) {
        [self updateBeautySwitchIsOn:YES isManually:NO];
    }

    // Select at the category level
    NSObject *parentItem = nil;
    if ([viewController isEqual:self.effectsViewController]) { // effects
        parentItem = self.viewModel.currentCategory;
        [self.effectsViewController reloadCurrentItem];
        // update selected effectWrapper
        [self.viewModel.effectViewModel updateSelectedEffect:effectWrapper forCategory:self.viewModel.currentCategory];

    } else if ([viewController isEqual:self.childEffectsViewController]){ // child effects

        parentItem = self.viewModel.selectedEffect.parentEffect;
        [self.childEffectsViewController reloadCurrentItem];
    }

    if ([self.delegate respondsToSelector:@selector(composerBeautyPanelDidSelectEffect:forParentObject:)]) {
        [self.delegate composerBeautyPanelDidSelectEffect:effectWrapper forParentObject:parentItem];
    }
    if ([self.delegate respondsToSelector:@selector(composerBeautyPanelDidSelectEffect:oldEffect:fromDownload:)]) {
        [self.delegate composerBeautyPanelDidSelectEffect:effectWrapper oldEffect:canceledEffect fromDownload:fromDownload];
    }
}

- (void)composerSubItemsViewController:(AWEComposerBeautySubItemsViewController *)viewController
                       didSelectEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                            lastEffect:(AWEComposerBeautyEffectWrapper *)lastEffectWrapper
{
    if ([self.delegate respondsToSelector:@selector(composerBeautyPanelDidSelectEffect:lastEffect:)]) {
        [self.delegate composerBeautyPanelDidSelectEffect:effectWrapper lastEffect:lastEffectWrapper];
    }
}


- (void)composerSubItemsViewController:(AWEComposerBeautySubItemsViewController *)viewController
                       didSelectEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                         forParentItem:(NSString *)parentItemID
{
    if ([self.viewModel enableBeautyCategorySwitch]) {
        [self updateBeautySwitchIsOn:YES isManually:NO];
    }
    
    [self.delegate composerBeautyPanelDidUpdateCandidateEffect:effectWrapper forParentItem:parentItemID];
}

- (void)composerSubItemsViewControllerDidFinishDownloadingAllEffects
{
    [self.delegate composerBeautyPanelDidFinishDownloadingAllEffects];
}

- (void)composerSubItemsViewController:(AWEComposerBeautySubItemsViewController *)viewController didTapOnToggleView:(BOOL)isOn isManually:(BOOL)isManually
{
    if (isManually) {
        [self trackToggleBeautySwitchManuallyWithFinalState:isOn];
    }

    [self updateBeautySwitchIsOn:isOn isManually:isManually];

    if ([self.delegate respondsToSelector:@selector(composerBeautyPanelDidSwitch:isManually:)]) {
        [self.delegate composerBeautyPanelDidSwitch:isOn isManually:isManually];
    }
}


// there would be a reset mode button in primary category's effectsViewController
- (void)composerSubItemsViewController:(AWEComposerBeautySubItemsViewController *)viewController didTapResetCategory:(AWEComposerBeautyEffectCategoryWrapper *)resetCategoryWrapper
{
    // tap
    if ([self.delegate respondsToSelector:@selector(composerBeautyPanelDidTapResetPrimaryCategory:)]) {
        [self.delegate composerBeautyPanelDidTapResetPrimaryCategory:resetCategoryWrapper];
    }
}

// should enable reset mode button
- (BOOL)composerSubItemsViewController:(AWEComposerBeautySubItemsViewController *)viewController shouldResetButtonEnabledWithCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
{
    return ![self.viewModel isDefaultStatusCategory:categoryWrapper];
}

#pragma mark - AWEComposerBeautyPrimaryItemsViewController - Delegate

// select, apply effects of this category
- (void)composerPrimaryItemsViewController:(AWEComposerBeautyPrimaryItemsViewController *)viewController
                         didSelectCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
                            parentCategory:(AWEComposerBeautyEffectCategoryWrapper *)parentCategoryWrapper
{
    AWEComposerBeautyEffectCategoryWrapper *lastSelectCategory = self.viewModel.currentCategory.selectedChildCategory;
    self.viewModel.currentCategory.selectedChildCategory = categoryWrapper;
    self.viewModel.currentCategory.userSelectedChildCategory = categoryWrapper;

    if ([self.delegate respondsToSelector:@selector(composerBeautyPanelDidSelectPrimaryCategory:lastCategory:parentCategory:)]) {
        [self.delegate composerBeautyPanelDidSelectPrimaryCategory:categoryWrapper lastCategory:lastSelectCategory parentCategory:parentCategoryWrapper];
    }
}

// enter
- (void)composerPrimaryItemsViewController:(AWEComposerBeautyPrimaryItemsViewController *)viewController
                          didEnterCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
                            parentCategory:(AWEComposerBeautyEffectCategoryWrapper *)parentCategoryWrapper
{
    self.viewModel.currentCategory.selectedChildCategory = categoryWrapper;

    // change To child category VC
    [self p_showSubEffectsForCategoryWrapper:categoryWrapper];

    if ([self.delegate respondsToSelector:@selector(composerBeautyPanelDidEnterCategory:parentCategory:)]) {
        [self.delegate composerBeautyPanelDidEnterCategory:categoryWrapper parentCategory:parentCategoryWrapper];
    }
}

- (void)p_showSubEffectsForCategoryWrapper:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
{
    [self.effectsViewController updateWithParentCategory:categoryWrapper OrParentEffect:nil];

    [self p_insertViewController:self.effectsViewController removeViewController:self.primaryViewController animated:YES completion:nil];

    [self.topBarViewController showCollectionToTitleWithTitle:categoryWrapper.primaryCategoryName duration:[self p_animationDuration]];
}

#pragma mark - Event Tracker

- (void)trackToggleBeautySwitchManuallyWithFinalState:(BOOL)isOn
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.viewModel.referExtra];
    [params setValue:isOn ? @"on" : @"off" forKey:@"final_status"];
    [ACCTracker() trackEvent:@"click_beauty_switch"
                       params:params
              needStagingFlag:NO];
}

@end
