//
//  ACCEditVideoBeautyPanelViewController.m
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2021/1/17.
//

#import "ACCEditVideoBeautyPanelViewController.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitBeauty/AWEComposerBeautySubItemsViewController.h>
#import <CreationKitBeauty/AWEComposerBeautyTopBarViewController.h>
#import <CreationKitBeauty/AWEComposerBeautyViewModel+Signal.h>
#import <CreationKitBeauty/AWEComposerBeautyPanelViewController.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <ReactiveObjC/RACSignal+Operations.h>
#import <Masonry/View+MASAdditions.h>
#import "ACCConfigKeyDefines.h"

static const CGFloat kAWEComposerBeautyPanelContainerViewHeight = 208;
static const CGFloat kAWEComposerBeautyPanelContainerViewOptimizedHeight = 254;

@interface ACCEditVideoBeautyPanelViewController ()<
AWEComposerBeautyTopBarViewControllerDelegate
>

@property (nonatomic, strong) AWEComposerBeautyTopBarViewController *bottomBarViewController;
@property (nonatomic, strong, readwrite) AWEComposerBeautyViewModel *viewModel;
@property (nonatomic, strong, readwrite) id<ACCBeautyUIConfigProtocol> uiConfig;
@property (nonatomic, assign) BOOL childEffectsDisplayed;
@property (nonatomic, strong) AWEComposerBeautyPanelViewController *contentViewController;

@end

@implementation ACCEditVideoBeautyPanelViewController

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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupContentViewController];
    [self setupBottomBarViewController];
    [self bindViewModel];
}

#pragma mark -

- (void)setDelegate:(id<AWEComposerBeautyPanelViewControllerDelegate>)delegate
{
    _delegate = delegate;
    self.contentViewController.delegate = delegate;
}

- (void)updateUIConfig:(id<ACCBeautyUIConfigProtocol>)config
{
    self.uiConfig = config;
}

- (void)reloadPanel
{
    BOOL titlesChagned = NO;
    if ([[self tabTitles] count] != [self.bottomBarViewController.titles count]) {
        titlesChagned = YES;
    } else {
        for (NSInteger index = 0; index < [[self tabTitles] count]; index++) {
            if (![[self tabTitles][index] isEqualToString:self.bottomBarViewController.titles[index]]) {
                titlesChagned = YES;
                break;
            }
        }
    }
    if (titlesChagned) {
        [self.bottomBarViewController updateWithTitles:[self tabTitles]];
    }
    [self.bottomBarViewController selectItemAtIndex:[self.viewModel.filteredCategories indexOfObject:self.viewModel.currentCategory]];
    [self.contentViewController reloadPanel];
}

- (CGFloat)composerPanelHeight
{
    if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) != ACCEditViewUIOptimizationTypeDisabled) {
        return kAWEComposerBeautyPanelContainerViewOptimizedHeight + ACC_IPHONE_X_BOTTOM_OFFSET;;
    }
    return kAWEComposerBeautyPanelContainerViewHeight + ACC_IPHONE_X_BOTTOM_OFFSET;
}

- (void)updateCurrentSelectedEffectWithStrength:(CGFloat)strength
{
    [self.contentViewController updateCurrentSelectedEffectWithStrength:strength];
}

- (BOOL)isShowingChildItems
{
    return [self.contentViewController isShowingChildItems];
}

- (void)updateResetButtonToDisabled:(BOOL)disabled
{
    [self.contentViewController updateResetButtonToDisabled:disabled];
}

#pragma mark - Data Management

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

#pragma mark - UI Helper

- (void)setupContentViewController
{
    _contentViewController = [[AWEComposerBeautyPanelViewController alloc] initWithViewModelAndOptimizedUI:self.viewModel];
    _contentViewController.delegate = self.delegate;
    [self.contentViewController updateUIConfig:self.uiConfig];
    [self addChildViewController:self.contentViewController];
    [self.view addSubview:self.contentViewController.view];
    [self.contentViewController didMoveToParentViewController:self];
    self.contentViewController.topBarViewController.collectionView.hidden = YES;
    [self.contentViewController.topBarViewController.resetButton setTitle:ACCLocalizedString(@"profile_cover_reset", @"还原") forState:UIControlStateNormal];
    
    self.contentViewController.topBarViewController.resetButton.accessibilityLabel = ACCLocalizedString(@"profile_cover_reset", @"还原");
    self.contentViewController.topBarViewController.resetButton.accessibilityTraits = UIAccessibilityTraitButton;

    ACCMasMaker(self.contentViewController.view, {
        make.top.left.right.equalTo(self.view);
        make.height.equalTo(@([self composerPanelHeight]));
    });
}

- (void)setupBottomBarViewController
{
    self.bottomBarViewController = [[AWEComposerBeautyTopBarViewController alloc] initWithTitles:[self tabTitles]];
    self.bottomBarViewController.hideResetButton = YES;
    self.bottomBarViewController.autoAlignCenter = YES;
    self.bottomBarViewController.hideSelectUnderline = YES;
    self.bottomBarViewController.itemHeight = 44.f;
    [self.bottomBarViewController updateUIConfig:self.uiConfig];
    self.bottomBarViewController.delegate = self;
    [self addChildViewController:self.bottomBarViewController];
    [self.view addSubview:self.bottomBarViewController.view];
    [self.bottomBarViewController didMoveToParentViewController:self];
    ACCMasMaker(self.bottomBarViewController.view, {
        make.left.right.equalTo(self.view);
        make.height.equalTo(@(44));
        make.bottom.equalTo(self.view).offset(-ACC_IPHONE_X_BOTTOM_OFFSET);
    });
    
    UIView *lineView = [[UIView alloc] init];
    lineView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12];
    [self.bottomBarViewController.view addSubview:lineView];
    
    ACCMasMaker(lineView, {
        make.left.right.top.equalTo(self.bottomBarViewController.view);
        make.height.equalTo(@(0.5));
    });
}

- (void)setBottomBarHidden:(BOOL)hidden
                  animated:(BOOL)animated
{
    dispatch_block_t actionBlock = ^{
        if (hidden) {
            CGAffineTransform transform = CGAffineTransformMakeTranslation(-60, 0);
            
            self.bottomBarViewController.view.alpha = 0.f;
            self.bottomBarViewController.view.transform = transform;
            
            { // Edit View UI Optimization
                self.contentViewController.headerView.alpha = 0.f;
                self.contentViewController.headerView.transform = transform;
                
                self.cancelBtn.alpha = 0.f;
                self.cancelBtn.transform = transform;
                
                self.saveBtn.alpha = 0.f;
                self.saveBtn.transform = transform;
            }
        } else {
            CGAffineTransform transform = CGAffineTransformIdentity;
            
            self.bottomBarViewController.view.alpha = 1.f;
            self.bottomBarViewController.view.transform = transform;
            
            { // Edit View UI Optimization
                self.contentViewController.headerView.alpha = 1.f;
                self.contentViewController.headerView.transform = transform;
                
                self.cancelBtn.alpha = 1.f;
                self.cancelBtn.transform = transform;
                
                self.saveBtn.alpha = 1.f;
                self.saveBtn.transform = transform;
            }
        }
    };
    if (animated) {
        [UIView animateWithDuration:[self p_animationDuration]
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            ACCBLOCK_INVOKE(actionBlock);
        } completion:^(BOOL finished) {
            
        }];
    } else {
        ACCBLOCK_INVOKE(actionBlock);
    }
}

- (void)bindViewModel
{
    @weakify(self);
    [[self.viewModel.currentCategorySignal deliverOnMainThread] subscribeNext:^(AWEComposerBeautyEffectCategoryWrapper * _Nullable x) {
        @strongify(self);
        [self reloadPanel];
    }];
}

#pragma mark - AWEComposerBeautyTopBarViewControllerDelegate

- (void)composerBeautyTopBarDidTapBackButton {}

- (void)composerBeautyTopBarDidTapResetButton {}

- (void)composerBeautyTopBarDidSelectTabAtIndex:(NSInteger)index
{
    if (index < [self.viewModel.filteredCategories count]) {
        self.viewModel.currentCategory = self.viewModel.filteredCategories[index];
        self.viewModel.selectedEffect = self.viewModel.currentCategory.userSelectedEffect;
        if ([self.delegate respondsToSelector:@selector(composerBeautyPanelDidChangeToCategory:)]) {
            [self.delegate composerBeautyPanelDidChangeToCategory:self.viewModel.currentCategory];
        }
    }
}

- (NSTimeInterval)p_animationDuration
{
    return 0.3;
}

@end
