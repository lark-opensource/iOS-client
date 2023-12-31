//
//  BDPBaseViewController.m
//  Timor
//
//  Created by 王浩宇 on 2019/1/27.
//

#import "BDPBaseViewController.h"
#import <OPFoundation/BDPDeviceManager.h>
#import <OPFoundation/BDPResponderHelper.h>
#import "BDPNavigationController.h"
#import <OPFoundation/BDPDeviceHelper.h>

#import <OPFoundation/UIColor+BDPExtension.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>
#import <OPSDK/OPSDK-Swift.h>

@interface BDPBaseViewController ()

@end

@implementation BDPBaseViewController

#pragma mark - View & Layout
/*-----------------------------------------------*/
//          View & Layout - 加载及布局相关
/*-----------------------------------------------*/
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupNavigationBar];
    [self updateViewControllerStyle:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ([BDPDeviceHelper OSVersionNumber] >= 13.f) {
        [self updateStatusBarStyle:animated];
    }
    [self updateViewControllerStyle:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // DidAppear改变状态栏样式动画必须设置为NO，避免系统重置样式与设置样式冲突导致的闪烁
    [self updateStatusBarStyle:NO];
//    [self setNeedsStatusBarAppearanceUpdate];
    [self updateViewControllerStyle:animated];
}

- (void)updateViewControllerStyle:(BOOL)animated {
    [self updateNavigationBarStyle:animated];
    [self.navigationController setNavigationBarHidden:[self navigationBarHidden] animated:animated];
    BDPNavigationController *superNavi = (BDPNavigationController *)self.navigationController;
    if ([superNavi isKindOfClass:[BDPNavigationController class]]) {
        [superNavi setNavigationPopGestureEnabled:[self popGestureEnable]];
    }
}

#pragma mark - NavigationBar Style
/*-----------------------------------------------*/
//        NavigationBar Style - 导航栏样式
/*-----------------------------------------------*/
- (void)setupNavigationBar
{
    // do something in subclass
}

- (void)updateNavigationBarStyle:(BOOL)animated
{
    BDPNavigationController *superNavi = (BDPNavigationController *)self.navigationController;
    if ([superNavi isKindOfClass:[BDPNavigationController class]]) {
        
        NSString *title = @"BDPBaseViewController";
        NSDictionary *titleAttributes;
        UIColor *navigationBarBackgroundColor;
        UIColor *navigationBarTintColor;
        titleAttributes = @{NSForegroundColorAttributeName:UDOCColor.textTitle};
        navigationBarBackgroundColor = UDOCColor.bgBody;
        navigationBarTintColor = UDOCColor.iconN1;
        [superNavi setNavigationItemTitle:title viewController:self];
        [superNavi setNavigationBarTitleTextAttributes:titleAttributes viewController:self];
        [superNavi setNavigationBarBackgroundColor:navigationBarBackgroundColor];
        [superNavi setNavigationItemTintColor:navigationBarTintColor viewController:self];
    }
}

- (BOOL)navigationBarHidden {
    return NO;
}

- (BOOL)popGestureEnable {
    return YES;
}

#pragma mark - StatusBar Style
/*-----------------------------------------------*/
//         StatusBar Style - 导航栏样式
/*-----------------------------------------------*/
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationFade;
}

- (void)updateStatusBarStyle:(BOOL)animated
{
    // ViewDidAppear在手势滑动Cancel触发时不会触发BDPNavigationController的willShowVC事件
    // 因此需在具体ViewController的[DidAppear]事件重新设置状态栏样式
    BDPNavigationController *superNavi = (BDPNavigationController *)self.navigationController;
    if ([superNavi isKindOfClass:[BDPNavigationController class]]) {
        [superNavi updateStatusBarHidden:animated];
        [superNavi updateStatusBarStyle:animated];
    }
}

#pragma mark - Orientation
/*------------------------------------------*/
//          Orientation - 屏幕旋转
/*------------------------------------------*/
- (BOOL)shouldAutorotate
{
    return [BDPDeviceManager shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
