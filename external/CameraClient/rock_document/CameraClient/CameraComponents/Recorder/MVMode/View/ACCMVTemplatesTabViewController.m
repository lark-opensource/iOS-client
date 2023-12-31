//
//  ACCMVTemplatesTabViewController.m
//  CameraClient
//
//  Created by long.chen on 2020/3/1.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCMVTemplatesTabViewController.h"
#import "ACCViewControllerProtocol.h"
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>
#import "UIViewController+ACCStatusBar.h"
#import "ACCMVTemplateTabContentProvider.h"
#import "ACCZoomContextProviderProtocol.h"
#import "ACCMVTemplatesPreloadDataManager.h"
#import "ACCMVTemplatesFetchProtocol.h"
#import "UIViewController+ACCUIKitEmptyPage.h"
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitInfra/ACCModuleService.h>
#import "ACCMVPageStyleABHelper.h"

#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>
#import "ACCConfigKeyDefines.h"
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import "ACCMvTemplateSupportOneKeyMvConfig.h"

@interface ACCMVTemplatesTabViewController () <ACCZoomContextOutterProviderProtocol>

@property (nonatomic, strong) ACCAnimatedButton *closeButton;
@property (nonatomic, strong) UILabel *titleLabel;
// 一键成片入口button
@property (nonatomic, strong) UIButton *oneKeyMVButton;

@property (nonatomic, strong) ACCSlidingTabViewController *mvTemplatesTabViewController;
@property (nonatomic, strong) ACCMVTemplateTabContentProvider *contentProvider;

@end

@implementation ACCMVTemplatesTabViewController

@synthesize publishViewModel, closeBlock, willEnterDetailVCBlock, didAppearBlock, didPickTemplateBlock;

- (void)dealloc
{
    [UIViewController acc_setStatusBarForceShow:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self p_setupUI];
    
    if ([ACCMVTemplatesPreloadDataManager sharedInstance].mvTemplatesCategories.count) {
        self.contentProvider.categories = [ACCMVTemplatesPreloadDataManager sharedInstance].mvTemplatesCategories;
        [self p_showSlidingTabViewController];
        [ACCTracker() track:@"mv_shoot_page_load_status" params:[ACCMVTemplatesPreloadDataManager sharedInstance].trackInfo];
    } else {
        [self p_fetchCategoriesData];
    }
}

- (void)viewDidLayoutSubviews
{
    if ([ACCMvTemplateSupportOneKeyMvConfig enabled]) {
        [self.mvTemplatesTabViewController registerOneKeyButton:self.oneKeyMVButton finalY:self.closeButton.frame.origin.y];
    }
}

- (void)p_setupUI
{
    if (!([UIDevice acc_isIPhoneX] && ACCViewFrameOptimizeContains(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize), ACCViewFrameOptimizeHideStatusBar))) {
        [UIViewController acc_setStatusBarForceShow:YES];
    }
    
    [ACCViewControllerService() viewController:self setPrefersNavigationBarHidden:YES];
    self.view.backgroundColor = ACCResourceColor(ACCColorBGCreation);
    
    [self.view addSubview:self.closeButton];
    ACCMasMaker(self.closeButton, {
        make.top.equalTo(self.view).offset(25).priorityMedium();
        if (@available(iOS 11.0, *)) {
            if ([UIDevice acc_isIPhoneX]) {
                make.top.greaterThanOrEqualTo(self.view.mas_safeAreaLayoutGuideTop).offset(0);  
            }
        }
        make.left.equalTo(self.view.mas_left).offset(6);
        make.size.equalTo(@(CGSizeMake(44, 40)));
    });
    
    [self.view addSubview:self.titleLabel];
    ACCMasMaker(self.titleLabel, {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.closeButton);
    });
    
    UIView *tabbarBackgroundView = [UIView new];
    tabbarBackgroundView.backgroundColor = ACCResourceColor(ACCColorBGCreation2);
    [self.view addSubview:tabbarBackgroundView];
    ACCMasMaker(tabbarBackgroundView, {
        make.left.bottom.right.equalTo(self.view);
        make.height.equalTo(@([UIDevice acc_isIPhoneX] ? 88 : 54));
    });
    
    UIView *lineView = [UIView new];
    lineView.backgroundColor = ACCResourceColor(ACCColorLinePrimary);
    [self.view addSubview:lineView];
    ACCMasMaker(lineView, {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view).offset([UIDevice acc_isIPhoneX] ? -87.5 : -53.5);
        make.height.equalTo(@(0.5));
    });
    
    if ([ACCMvTemplateSupportOneKeyMvConfig enabled]) {
        [self.view addSubview:self.oneKeyMVButton];
        CGFloat buttonTop = [ACCMvTemplateSupportOneKeyMvConfig oneKeyBtnOriginY];
        ACCMasMaker(self.oneKeyMVButton, {
            make.right.equalTo(self.view.mas_right).offset(-6);
            make.top.equalTo(@(buttonTop));
            make.size.equalTo(@(CGSizeMake(100, 40)));
        });
    }
}

- (void)p_fetchCategoriesData
{
    UIView<ACCLoadingViewProtocol> *loadingView = [ACCLoading() showLoadingOnView:self.view];
    [ACCMVTemplatesFetch() fetchMVTemplatesCategories:^(NSError * _Nullable error, NSArray<ACCMVCategoryModel *> * _Nullable categories) {
        [loadingView dismiss];
        if (error || !categories.count) {
            self.accui_viewControllerState = ACCUIKitViewControllerStateError;
        } else {
            self.accui_viewControllerState = ACCUIKitViewControllerStateNormal;
            self.contentProvider.categories = categories;
            [self p_showSlidingTabViewController];
        }
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    ACCBLOCK_INVOKE(self.didAppearBlock);
    if (self.isMovingToParentViewController || self.isBeingPresented) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ACCMVViewControllerDidShow object:self];
    }
}

- (void)p_showSlidingTabViewController
{
    self.mvTemplatesTabViewController.contentProvider = self.contentProvider;
    self.contentProvider.viewController = self.mvTemplatesTabViewController;
    self.contentProvider.willEnterDetailVCBlock = self.willEnterDetailVCBlock;
    self.contentProvider.didPickTemplateBlock = self.didPickTemplateBlock;
    
    [self addChildViewController:self.mvTemplatesTabViewController];
    [self.view addSubview:self.mvTemplatesTabViewController.view];
    [self.mvTemplatesTabViewController didMoveToParentViewController:self];
    ACCMasMaker(self.mvTemplatesTabViewController.view, {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(17);
        make.bottom.equalTo(self.view).offset(-([UIDevice acc_isIPhoneX] ? 88 : 54));
    });
}

#pragma mark - Actions

- (void)p_closeButtonPressed:(UIButton *)button
{
    ACCBLOCK_INVOKE(self.closeBlock);
}

#pragma mark - ACCZoomContextOutterProviderProtocol

- (UIView *)acc_zoomTransitionStartViewForItemOffset:(NSInteger)itemOffset
{
    return [self.contentProvider acc_zoomTransitionStartViewForItemOffset:itemOffset];
}

#pragma mark - ACCUIKitEmptyPage

- (ACCUIKitViewControllerEmptyPageConfig *)accui_emptyPageConfigForState:(ACCUIKitViewControllerState)state
{
    ACCUIKitViewControllerEmptyPageConfig *config = [ACCUIKitViewControllerEmptyPageConfig new];
    config.backgroundColor = ACCResourceColor(ACCColorBGView);
    config.style = ACCUIKitViewControllerEmptyPageStyleB;
    config.iconImage = [UIImage imageNamed:@"img_empty_neterror"];
     
    return config;
}

- (void)accui_emptyPagePrimaryButtonTapped:(UIButton *)sender
{
    [self p_fetchCategoriesData];
    [ACCTracker() trackEvent:@"reload_mv_shoot_page"
                       params:@{
                           @"shoot_way" : self.publishViewModel.repoTrack.referString ?: @"",
                           @"creation_id" : self.publishViewModel.repoContext.createId ?: @"",
                           @"langing_type" : @"default",
                           @"tab_name" : @"",
                           @"reload_type" : @"tab",
                       }];
}

- (UIEdgeInsets)accui_emptyPageEdgeInsets
{
    return UIEdgeInsetsMake(self.titleLabel.acc_bottom, 0, 0, 0);
}

#pragma mark - Getters

- (ACCAnimatedButton *)closeButton
{
    if (!_closeButton) {
        _closeButton = [ACCAnimatedButton new];
        _closeButton.isAccessibilityElement = YES;
        _closeButton.accessibilityTraits = UIAccessibilityTraitButton;
        _closeButton.accessibilityLabel = @"关闭";
        UIImage *image = ACCResourceImage(@"ic_titlebar_close_white");
        [_closeButton setImage:image forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(p_closeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

-(UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [ACCFont() acc_systemFontOfSize:17 weight:ACCFontWeightMedium];
        _titleLabel.textColor = ACCResourceColor(ACCColorConstTextInverse2);
        _titleLabel.text = [ACCMVPageStyleABHelper acc_cutsameTitleText];
    }
    return _titleLabel;
}

- (ACCSlidingTabViewController *)mvTemplatesTabViewController
{
    if (!_mvTemplatesTabViewController) {
        _mvTemplatesTabViewController = [[ACCSlidingTabViewController alloc] init];
    }
    return _mvTemplatesTabViewController;
}

- (ACCMVTemplateTabContentProvider *)contentProvider
{
    if (!_contentProvider) {
        _contentProvider = [[ACCMVTemplateTabContentProvider alloc] init];
        if ([ACCMvTemplateSupportOneKeyMvConfig enabled]) {
            _contentProvider.contentInsets = UIEdgeInsetsMake([ACCMvTemplateSupportOneKeyMvConfig oneKeyViewHeight], 0, 0, 0);
        }
        _contentProvider.publishModel = self.publishViewModel;
    }
    return _contentProvider;
}

- (UIButton *)oneKeyMVButton
{
    if (!_oneKeyMVButton) {
        _oneKeyMVButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _oneKeyMVButton.backgroundColor = [UIColor clearColor];
        [_oneKeyMVButton setImage:ACCResourceImage(@"icon_one_key_mv") forState:0];
        [_oneKeyMVButton setTitle:@"一键成片" forState:UIControlStateNormal];
        _oneKeyMVButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_oneKeyMVButton setTitleColor:[UIColor whiteColor] forState:0];
        [_oneKeyMVButton.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(self);
            make.centerY.mas_equalTo(self);
        }];
        [_oneKeyMVButton.imageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(@(CGSizeMake(20, 20)));
            make.right.mas_equalTo(self.oneKeyMVButton.titleLabel.mas_left).offset(-5);
            make.centerY.mas_equalTo(self);
        }];
        _oneKeyMVButton.alpha = 0.f;
    }
    return _oneKeyMVButton;
}

@end
