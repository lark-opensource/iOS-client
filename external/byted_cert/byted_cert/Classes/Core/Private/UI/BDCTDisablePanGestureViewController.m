//
//  BytedCertRotateViewController.m
//
//  Created by 潘冬冬 on 2019/8/19.
//  Copyright © 2019 潘冬冬. All rights reserved.
//

#import "BDCTDisablePanGestureViewController.h"
#import "BytedCertUIConfig.h"
#import "UIViewController+BDCTAdditions.h"
#import <objc/runtime.h>
#import <objc/message.h>

static NSMutableArray *classList;


@interface BDCTDisablePanGestureViewController () <WKNavigationDelegate>

@end


@implementation BDCTDisablePanGestureViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        if (classList == nil) {
            classList = [[NSMutableArray alloc] init];
        }
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.navigationController && [self.navigationController isKindOfClass:NSClassFromString(@"TTNavigationController")]) {
        [self.navigationController setNavigationBarHidden:YES animated:NO];
    }

    for (UIView *view in self.view.subviews) {
        if ([view isKindOfClass:[WKWebView class]]) {
            ((WKWebView *)view).scrollView.bounces = NO;
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = BytedCertUIConfig.sharedInstance.backgroundColor ?: UIColor.whiteColor;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if ([self.view.subviews.firstObject isKindOfClass:WKWebView.class]) {
        self.view.subviews.firstObject.frame = self.view.bounds;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([objc_getAssociatedObject(self, _cmd) boolValue]) {
        return;
    }
    objc_setAssociatedObject(self, _cmd, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self disablePodGestureIfNeeded];
}

- (void)disablePodGestureIfNeeded {
    if (_disablePodGesture) {
        if (!self.navigationController) {
            return;
        }
        UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe)];
        swipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
        [self.view addGestureRecognizer:swipeGesture];
        UIScreenEdgePanGestureRecognizer *edgePanGesture = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe)];
        edgePanGesture.edges = UIRectEdgeLeft;
        [self.view addGestureRecognizer:edgePanGesture];
        [edgePanGesture requireGestureRecognizerToFail:swipeGesture];
        [self.navigationController.interactivePopGestureRecognizer.view.gestureRecognizers enumerateObjectsUsingBlock:^(__kindof UIGestureRecognizer *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            [obj requireGestureRecognizerToFail:swipeGesture];
        }];
    }
}

- (void)handleSwipe {
    // Dot nothing
}

#pragma mark - system method

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    // 这行代码很重要，每次让状态栏回到竖屏状态
    [[UIDevice currentDevice] setValue:@(UIDeviceOrientationPortrait) forKey:@"orientation"];
    return UIInterfaceOrientationMaskPortrait;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (BytedCertUIConfig.sharedInstance.isDarkMode) {
        return UIStatusBarStyleLightContent;
    } else {
        if (@available(iOS 13.0, *)) {
            return UIStatusBarStyleDarkContent;
        } else {
            return UIStatusBarStyleDefault;
        }
    }
}

- (void)dealloc {
    for (UIView *view in self.view.subviews) {
        if ([view isKindOfClass:[WKWebView class]]) {
            WKWebView *webView = (WKWebView *)view;
            webView.UIDelegate = nil;
            webView.navigationDelegate = nil;
            [webView stopLoading];
            webView.scrollView.delegate = nil;
        }
    }
}

@end


@implementation BDCTPortraitNavigationController

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

@end
