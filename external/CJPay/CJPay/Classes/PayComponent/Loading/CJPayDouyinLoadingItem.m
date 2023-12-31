//
//  CJPayDouyinLoadingItem.m
//  Pods
//
//  Created by 易培淮 on 2021/8/16.
//

#import "CJPayDouyinLoadingItem.h"
#import "CJPayUIMacro.h"
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayDouyinLoadingView.h"
#import "CJPayBrandPromoteABTestManager.h"

@implementation CJPayDouyinLoadingItem

#pragma mark - CJPayAdvanceLoadingProtocol

- (void)stopLoading {
    [self p_stopDouyinLoading];
}

- (void)startLoading {
    [self p_startDouyinLoading:[self loadingTitle] onView:[UIApplication btd_mainWindow]];
}

- (void)startLoadingWithTitle:(NSString *)title {
    [self p_startDouyinLoading:title onView:[UIApplication btd_mainWindow]];
}

- (void)startLoadingWithTitle:(NSString *)title logo:(NSString *)url {
    [self p_startDouyinLoading:title logo:url onView:[UIApplication btd_mainWindow]];
}

- (void)startLoadingWithVc:(UIViewController *)vc {
    [self startLoadingWithVc:vc title:[self loadingTitle]];
}

- (void)startLoadingWithVc:(UIViewController *)vc title:(NSString *)title {
    UIViewController *curVC = vc ?: [UIViewController cj_foundTopViewControllerFrom:vc];
    [self p_startDouyinLoading:title onView:curVC.view];
}

- (void)startLoadingOnView:(UIView *)view {
    [self p_startDouyinLoading:[self loadingTitle] onView:view];
}

- (void)startLoadingWithView:(UIView *)view {
    [self p_startDouyinLoadingWithView:view onView:[UIApplication btd_mainWindow]];
}

+ (CJPayLoadingType)loadingType {
    return CJPayLoadingTypeDouyinLoading;
}

#pragma mark - Private Method
- (void)p_startDouyinLoading:(NSString *)title onView:(UIView *)view {
    if (![self setTimer]) { //超时时间设为0则不展示Loading
        return;
    }
    [self addLoadingCount];
    [CJPayDouyinLoadingView showLoadingOnView:view title:title icon:[self loadingIcon] animated:YES afterDelay:0];
}

- (void)p_startDouyinLoading:(NSString *)title logo:(NSString *)url onView:(UIView *)view {
    if (![self setTimer]) { //超时时间设为0则不展示Loading
        return;
    }
    if (Check_ValidString(url)) {
        self.logoUrl = url;
    }
    [self addLoadingCount];
    [CJPayDouyinLoadingView showLoadingOnView:view title:title icon:[self loadingIcon] animated:YES afterDelay:0];
}

- (void)p_startDouyinLoadingWithView:(UIView *)showView onView:(UIView *)view {
    [self.timerManager startTimer:10];
    [self addLoadingCount];
    [CJPayDouyinLoadingView showLoadingWithView:showView onView:view];
}

- (void)p_stopDouyinLoading {
    self.logoUrl = @"";
    [CJPayDouyinLoadingView dismissWithAnimated:NO];
    [self.timerManager stopTimer];
    [self resetLoadingCount];
}

- (NSString *)loadingTitle {
    return CJPayDYPayTitleMessage;
}

- (NSString *)loadingIcon {
    return Check_ValidString(self.logoUrl) ? self.logoUrl : @"cj_douyin_pay_logo_icon";
}
@end
