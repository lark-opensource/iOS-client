//
//  ACCSlidingTabViewController.m
//  CameraClient
//
//  Created by long.chen on 2020/3/1.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCSlidingTabViewController.h"

#import <CreationKitInfra/ACCSlidingTabbarView.h>
#import <CreationKitInfra/ACCSlidingViewController.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>

#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>
#import "ACCOneKeyMvEntranceViewController.h"
#import "ACCMvTemplateSupportOneKeyMvConfig.h"
#import "ACCWaterfallViewController.h"
#import <CreativeKit/ACCMacros.h>

@interface ACCSlidingTabViewController () <ACCSlidingViewControllerDelegate>

@property (nonatomic, strong) ACCSlidingTabbarView *slidingTabView;
@property (nonatomic, strong) ACCSlidingViewController *slidingViewController;
// 一键成片
@property (nonatomic, strong) ACCOneKeyMvEntranceViewController *oneKeyMvViewController;

@end

@implementation ACCSlidingTabViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self p_setupUI];
}

- (void)p_setupUI
{
    self.view.backgroundColor = ACCResourceColor(ACCColorBGCreation);
    
    if ([ACCMvTemplateSupportOneKeyMvConfig enabled]) {
        // AB: 添加一键成片入口
        self.view.layer.masksToBounds = YES;
        [self.view addSubview:self.oneKeyMvViewController.view];
        [self addChildViewController:self.oneKeyMvViewController];
        [self.oneKeyMvViewController didMoveToParentViewController:self];
        ACCMasMaker(self.oneKeyMvViewController.view, {
            make.left.top.right.equalTo(self.view);
            make.height.equalTo(@120);
        });

        self.slidingViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
        [self.slidingViewController willMoveToParentViewController:self];
        [self.view insertSubview:self.slidingViewController.view belowSubview:self.oneKeyMvViewController.view];
        [self addChildViewController:self.slidingViewController];
        ACCMasMaker(self.slidingViewController.view, {
            make.top.equalTo(self.view).offset(40);
            make.left.bottom.right.equalTo(self.view);
        });
        [self.slidingViewController didMoveToParentViewController:self];
        
    } else {
        [self.view addSubview:self.slidingTabView];
        ACCMasMaker(self.slidingTabView, {
            make.left.top.right.equalTo(self.view);
            make.height.equalTo(@40);
        });
        
        [self.view addSubview:self.slidingViewController.view];
        [self addChildViewController:self.slidingViewController];
        [self.slidingViewController didMoveToParentViewController:self];
        ACCMasMaker(self.slidingViewController.view, {
            make.top.equalTo(self.slidingTabView.mas_bottom);
            make.left.bottom.right.equalTo(self.view);
        });
    }
    
    self.slidingTabView.slidingViewController = self.slidingViewController;
    [self.slidingViewController setTabbarView:self.slidingTabView];
    self.slidingTabView.selectedIndex = self.contentProvider.initialSelectedIndex;
    [self.slidingTabView updateSelectedLineFrame];
}

#pragma mark - ACCSlidingViewControllerDelegate

- (NSInteger)numberOfControllers:(ACCSlidingViewController *)slidingController
{
    return self.contentProvider.tabTitlesArray.count;
}

- (UIViewController *)slidingViewController:(ACCSlidingViewController *)slidingViewController viewControllerAtIndex:(NSInteger)index
{
    if (index < self.contentProvider.slidingViewControllers.count) {
        UIViewController *vc = self.contentProvider.slidingViewControllers[index];
        if ([ACCMvTemplateSupportOneKeyMvConfig enabled]) {
            [self.oneKeyMvViewController setupUpdateContentOffsetBlock:(ACCWaterfallViewController *)vc];
        }
        return vc;
    }
    return [UIViewController new];
}

- (void)slidingViewController:(ACCSlidingViewController *)slidingViewController didSelectIndex:(NSInteger)index
{
    [self.contentProvider slidingViewController:slidingViewController didSelectIndex:index];
}

#pragma mark - Getters

- (ACCSlidingTabbarView *)slidingTabView
{
    if (!_slidingTabView) {
        _slidingTabView = [[ACCSlidingTabbarView alloc] initWithFrame:CGRectMake(0, 0, self.view.acc_width, 40)
                                                   buttonStyle:ACCSlidingTabButtonStyleTextAndLineEqualLength
                                                     dataArray:self.contentProvider.tabTitlesArray
                                             selectedDataArray:self.contentProvider.tabTitlesArray];
        _slidingTabView.shouldShowBottomLine = NO;
        _slidingTabView.selectionLineColor = ACCResourceColor(ACCColorConstTextInverse2);
        [_slidingTabView configureButtonTextColor:ACCResourceColor(ACCColorConstTextInverse4)
                                selectedTextColor:ACCResourceColor(ACCColorConstTextInverse2)];
    }
    return _slidingTabView;
}

- (ACCSlidingViewController *)slidingViewController
{
    if (!_slidingViewController) {
        _slidingViewController = [[ACCSlidingViewController alloc] initWithSelectedIndex:self.contentProvider.initialSelectedIndex];
        _slidingViewController.slideEnabled = YES;
        _slidingViewController.delegate = self;
    }
    return _slidingViewController;
}

- (ACCOneKeyMvEntranceViewController *)oneKeyMvViewController
{
    if (!_oneKeyMvViewController) {
        _oneKeyMvViewController = [ACCOneKeyMvEntranceViewController slidingTabView:self.slidingTabView
                                                                    contentProvider:self.contentProvider];
    }
    return _oneKeyMvViewController;
}

- (void)registerOneKeyButton:(UIButton *)button finalY:(CGFloat)finalY
{
    if (_oneKeyMvViewController) {
        [self.oneKeyMvViewController registerOneKeyButton:button finalY:finalY];
    }
}

@end
