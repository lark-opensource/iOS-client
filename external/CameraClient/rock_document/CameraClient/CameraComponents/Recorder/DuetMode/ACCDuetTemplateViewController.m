//
//  ACCDuetTemplateViewController.m
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/10/15.
//

#import "ACCDuetTemplateViewController.h"
#import "ACCDuetTemplateSlidingViewController.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>

#import <CreationKitInfra/ACCSlidingTabbarView.h>
#import <CreationKitInfra/ACCSlidingViewController.h>
#import <CreativeKit/ACCAnimatedButton.h>

#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIDevice+ACCHardware.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/ACCConfigManager.h>
#import <Masonry/View+MASAdditions.h>
#import <CameraClient/ACCDuetTemplateDataControllerProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CameraClient/ACCConfigKeyDefines.h>

static const CGFloat kNumberOfTabs = 2;
static const CGFloat kTabTitlesWidth = 33;
static const CGFloat kTabTitlesWidthBigFont = 43;
static const CGFloat kTabTitlesPadding = 25;

@interface ACCDuetTemplateViewController ()<ACCSlidingViewControllerDelegate>

@property (nonatomic, strong) ACCSlidingTabbarView *slidingTabView;
@property (nonatomic, strong) ACCSlidingViewController *slidingViewController;
@property (nonatomic, strong) ACCAnimatedButton *closeButton;
@property (nonatomic, strong) NSArray <ACCDuetTemplateSlidingViewController *> *viewControllers;
@property (nonatomic, strong) NSArray<NSString *> *tabTitlesArray;
@property (nonatomic, assign) NSUInteger currentSelectedVCIndex;

@end

@implementation ACCDuetTemplateViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self p_setupUI];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    ACCBLOCK_INVOKE(self.didAppearBlock);
}

- (void)p_setupUI
{
    self.view.backgroundColor = ACCResourceColor(ACCColorBGCreation);
    
    CGFloat topMargin = 4;
    if ([UIDevice acc_isIPhoneX]) {
        if (@available(iOS 11.0, *)) {
            topMargin = ACC_STATUS_BAR_NORMAL_HEIGHT + 4;
        }
    }
    CGFloat slidingTabBarHeight = 44;
    [self.view addSubview:self.slidingTabView];
    CGFloat width = 0;
    if ([ACCFont() acc_bigFontModeOn]) {
        width = 2 * (2 * kTabTitlesPadding + kTabTitlesWidthBigFont);
    } else {
        width = 2 * (2 * kTabTitlesPadding + kTabTitlesWidth);
    }
    ACCMasMaker(self.slidingTabView, {
        make.centerY.equalTo(self.view.mas_top).offset(topMargin + slidingTabBarHeight / 2);
        make.centerX.equalTo(self.view.mas_centerX);
        make.width.mas_equalTo(width);
        make.height.equalTo(@44);
    });
    [self.view addSubview:self.closeButton];
    ACCMasMaker(self.closeButton, {
        make.centerY.equalTo(self.slidingTabView.mas_centerY);
        make.left.equalTo(self.view.mas_left).offset(6);
        make.size.equalTo(@(CGSizeMake(44, 44)));
    });
    
    self.view.backgroundColor = ACCResourceColor(ACCColorBGCreation);
    [self.view addSubview:self.slidingViewController.view];
    [self addChildViewController:self.slidingViewController];
    [self.slidingViewController didMoveToParentViewController:self];
    ACCMasMaker(self.slidingViewController.view, {
        make.top.equalTo(self.slidingTabView.mas_bottom);
        make.left.bottom.right.equalTo(self.view);
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
    
    self.slidingTabView.slidingViewController = self.slidingViewController;
    [self.slidingViewController setTabbarView:self.slidingTabView];
    self.slidingTabView.selectedIndex = self.initialSelectedIndex;
    [self.slidingTabView updateSelectedLineFrame];
}

#pragma mark - ACCSlidingViewControllerDelegate

- (NSInteger)numberOfControllers:(ACCSlidingViewController *)slidingController
{
    return kNumberOfTabs;
}

- (UIViewController *)slidingViewController:(ACCSlidingViewController *)slidingViewController viewControllerAtIndex:(NSInteger)index
{
    if (index < self.viewControllers.count) {
        return self.viewControllers[index];
    }
    return [UIViewController new];
}

- (void)slidingViewController:(ACCSlidingViewController *)slidingViewController didSelectIndex:(NSInteger)index
{
    if (index == self.currentSelectedVCIndex) {
        ACCDuetTemplateSlidingViewController *currentVC = self.viewControllers[self.currentSelectedVCIndex];
        [currentVC refreshContent];
    } else {
        self.currentSelectedVCIndex = index;
        NSString *fromStatus = @"";
        NSString *toStatus = @"";
        if (index == 1) {
            fromStatus = @"duet_for_shoot";
            toStatus = @"duet_for_sing";
        } else {
            fromStatus = @"duet_for_sing";
            toStatus = @"duet_for_shoot";
        }
        [ACCTracker() trackEvent:@"change_duet_page"
                          params:@{
            @"from_status": fromStatus,
            @"to_status":toStatus,
            @"shoot_way" : self.publishViewModel.repoTrack.referString ?: @"",
            @"creation_id" : self.publishViewModel.repoContext.createId ?: @"",
        }];
    }
}

#pragma mark - Getters

- (NSInteger) initialSelectedIndex
{
    if (!_initialSelectedIndex)
    {
        NSInteger tab = ACCConfigInt(kConfigInt_familiar_duet_sing_default_landing_tab);
        _initialSelectedIndex = tab == ACCDuetSingLadingTabSingTab ? 1 :0;
    }
    return _initialSelectedIndex;
}

- (ACCSlidingTabbarView *)slidingTabView
{
    if (!_slidingTabView) {
        CGFloat width = 0;
        if ([ACCFont() acc_bigFontModeOn]) {
            width = 2 * (2 * kTabTitlesPadding + kTabTitlesWidthBigFont);
        } else {
            width = 2 * (2 * kTabTitlesPadding + kTabTitlesWidth);
        }
        _slidingTabView = [[ACCSlidingTabbarView alloc] initWithFrame:CGRectMake(0, 0, width, 44)
                                                          buttonStyle:ACCSlidingTabButtonStyleTextAndLineEqualLength
                                                            dataArray:self.tabTitlesArray
                                                    selectedDataArray:self.tabTitlesArray];
        _slidingTabView.shouldShowBottomLine = NO;
        _slidingTabView.shouldShowTopLine = NO;
        [_slidingTabView configureTitlePadding:25.0f buttonStyle:ACCSlidingTabButtonStyleTextAndLineEqualLength];
        _slidingTabView.selectionLineColor = ACCResourceColor(ACCColorConstTextInverse2);
        [_slidingTabView configureButtonTextColor:ACCResourceColor(ACCColorConstTextInverse4)
                                selectedTextColor:ACCResourceColor(ACCColorConstTextInverse2)];
    }
    return _slidingTabView;
}

- (ACCSlidingViewController *)slidingViewController
{
    if (!_slidingViewController) {
        _slidingViewController = [[ACCSlidingViewController alloc] initWithSelectedIndex:self.initialSelectedIndex];
        _slidingViewController.slideEnabled = YES;
        _slidingViewController.delegate = self;
    }
    return _slidingViewController;
}

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

- (nonnull NSArray<NSString *> *)tabTitlesArray
{
    if (!_tabTitlesArray) {
        NSMutableArray<NSString *> *titlesArray = [[NSMutableArray alloc]init];
        [titlesArray acc_addObject:@"合拍"];
        [titlesArray acc_addObject:@"合唱"];
        _tabTitlesArray = titlesArray.copy;
    }
    return _tabTitlesArray;
}

- (NSArray <ACCDuetTemplateSlidingViewController *> *) viewControllers
{
    if (!_viewControllers) {
        NSMutableArray *viewControllers = @[].mutableCopy;
        for (int i = 0; i < kNumberOfTabs; i++) {
            ACCDuetTemplateSlidingViewController *templateVC = [ACCDuetTemplateSlidingViewController new];
            id<ACCDuetTemplateContentProviderProtocol> contentProvider = IESAutoInline(ACCBaseServiceProvider(), ACCDuetTemplateContentProviderProtocol);
            contentProvider.willEnterDetailVCBlock = self.willEnterDetailVCBlock;
            contentProvider.enterFrom = self.publishViewModel.repoTrack.enterFrom;
            contentProvider.logExtraDict = @{
                @"shoot_way" : self.publishViewModel.repoTrack.referString ?: @"",
                @"creation_id" : self.publishViewModel.repoContext.createId ?: @"",
            };
            if (i == 0) {
                NSInteger videoType = ACCConfigInt(kConfigInt_familiar_duet_sing_video_type_in_pool);
                if (videoType == ACCDuetSingVideoTypeOriginal) {
                    contentProvider.scene = AWEDuetSingSceneTypeDuetTabOriginal;
                } else if (videoType == ACCDuetSingVideoTypeDuet) {
                    contentProvider.scene = AWEDuetSingSceneTypeDuetTabDuet;
                }
                contentProvider.fromTab = @"from_duet_tab";
            } else if (i == 1) {
                contentProvider.scene = AWEDuetSingSceneTypeSingTab;
                contentProvider.fromTab = @"from_sing_tab";
            }
            templateVC.contentProvider = contentProvider;
            contentProvider.viewController = templateVC;
            [viewControllers acc_addObject:templateVC];
        }
        _viewControllers = viewControllers ;
    }
    return _viewControllers;
}

#pragma mark - Actions

- (void)p_closeButtonPressed:(UIButton *)button
{
    ACCBLOCK_INVOKE(self.closeBlock);
}


@end
