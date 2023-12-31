//
//  BDTuringPresentView.m
//  BDTuring
//
//  Created by bob on 2019/8/28.
//

#import "BDTuringPresentView.h"
#import "UIColor+TuringHex.h"
#import "BDTuringUIHelper.h"
#import "BDTuringViewController.h"
#import "BDTuringNavigationController.h"
#import "BDTuringCoreConstant.h"
#import "BDTuringEventService.h"

@interface BDTuringPresentView ()

@property (nonatomic, strong) NSMutableSet<UIView *> *presentingViews;
@property (nonatomic, strong) NSMutableSet<UIViewController *> *presentingViewControllers;
@property (nonatomic, strong) BDTuringNavigationController *turingNavi;
@property (nonatomic, weak) UIWindow *preKeyWindow;


@end

@implementation BDTuringPresentView

+ (instancetype)defaultPresentView {
    static BDTuringPresentView *presentView = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        presentView = [[self alloc] initWithFrame:[UIScreen mainScreen].bounds];
    });

    return presentView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.windowLevel = UIWindowLevelStatusBar - 1;
        self.clipsToBounds = YES;
        self.presentingViews = [NSMutableSet set];
        self.presentingViewControllers = [NSMutableSet set];
    }

    return self;
}

- (void)sendEvent:(UIEvent *)event {
    /// to collect event data
    if (!self.hidden) {
        [[BDTuringEventService sharedInstance] collectTouchEventsFromEvent:event];
    }
    [super sendEvent:event];
}

- (void)presentVerifyView:(UIView *)verifyView {
    if (verifyView == nil) {
        return;
    }
    #ifdef __IPHONE_13_0
    
    self.preKeyWindow = [BDTuringUIHelper keyWindow];
    //make sure self visible
    if (self.preKeyWindow != nil &&
                                (self.windowLevel < self.preKeyWindow.windowLevel + 1) ) {
        self.windowLevel = self.preKeyWindow.windowLevel + 1;
    }
        
    
    if (@available(iOS 13.0, *)) {
        self.windowScene = [BDTuringUIHelper keyWindow].windowScene;
    }
    #endif
    verifyView.hidden = NO;
    BDTuringNavigationController *nav = self.turingNavi;
    if (nav == nil) {
        nav = [[BDTuringNavigationController alloc] initWithRootViewController:[BDTuringViewController new]];
        self.turingNavi = nav;
        self.rootViewController = nav;
    }
    
    UIView *parent = self.turingNavi.topViewController.view;
    if (verifyView.superview != parent) {
        [verifyView removeFromSuperview];
    }
    if (verifyView.superview == nil) {
        [parent addSubview:verifyView];
    }
    /// reset frame to vc
    verifyView.frame = parent.bounds;
    [parent bringSubviewToFront:verifyView];
    [self.presentingViews addObject:verifyView];
    
    self.hidden = NO;
}

- (void)hideVerifyView:(UIView *)verifyView {
    if (verifyView == nil) {
        return;
    }
    verifyView.hidden = YES;
    [self.presentingViews removeObject:verifyView];
    if (self.presentingViews.count < 1) {
        self.hidden = YES;
        // 防止事件污染
        [[BDTuringEventService sharedInstance] clearAllTouchEvents];
    }
}

- (void)dismissVerifyView {
    if (self.presentingViews.count < 1 && self.presentingViewControllers.count < 1) {
        self.turingNavi = nil;
        self.rootViewController = nil;
        if(@available(iOS 13.0, *)) {
            self.windowScene = nil;
        }
        [self.preKeyWindow makeKeyWindow];
    }
}

- (void)presentTwiceVerifyViewController:(UIViewController *)twiceVerifyViewController {
    if (twiceVerifyViewController == nil) {
        return;
    }
    #ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        self.windowScene = [BDTuringUIHelper keyWindow].windowScene;
    }
    #endif
    BDTuringNavigationController *nav = self.turingNavi;
    if (nav == nil) {
        nav = [[BDTuringNavigationController alloc] initWithRootViewController:[BDTuringViewController new]];
        self.turingNavi = nav;
        self.rootViewController = nav;
    }
    
    UIViewController *parentViewController = self.turingNavi.topViewController;
    [self.presentingViewControllers addObject:twiceVerifyViewController];
    self.hidden = NO;
    [parentViewController presentViewController:twiceVerifyViewController animated:YES completion:nil];
}

- (void)hideTwiceVerifyViewController:(UIViewController *)twiceVerifyViewController {
    if (twiceVerifyViewController == nil) {
        return;
    }
    // 防止事件污染
    [[BDTuringEventService sharedInstance] clearAllTouchEvents];
    [self.presentingViewControllers removeObject:twiceVerifyViewController];
    if (self.presentingViews.count < 1 && self.presentingViewControllers.count < 1) {
        self.hidden = YES;
        self.turingNavi = nil;
        self.rootViewController = nil;
    }
}

@end
