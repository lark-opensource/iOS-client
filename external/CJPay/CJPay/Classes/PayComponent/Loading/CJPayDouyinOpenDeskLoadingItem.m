//
//  CJPayDouyinOpenDeskLoadingItem.m
//  CJPay-Pods-AwemeCore
//
//  Created by 利国卿 on 2022/6/2.
//

#import "CJPayDouyinOpenDeskLoadingItem.h"
#import "CJPayUIMacro.h"
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayDouyinOpenDeskLoadingView.h"

@implementation CJPayDouyinOpenDeskLoadingItem

#pragma mark - CJPayAdvanceLoadingProtocol

+ (CJPayLoadingType)loadingType {
    return CJPayLoadingTypeDouyinOpenDeskLoading;
}

- (void)stopLoading {
    [self p_stopDouyinLoading];
}

- (void)startLoading {
    [self p_startLoadingOnView:[UIApplication btd_mainWindow]];
}

- (void)startLoadingWithVc:(UIViewController *)vc {
    UIViewController *curVC = vc ?: [UIViewController cj_foundTopViewControllerFrom:vc];
    [self p_startLoadingOnView:curVC.view];
}

- (void)startLoadingOnView:(UIView *)view {
    [self p_startLoadingOnView:view];
}

- (void)p_startLoadingOnView:(UIView *)view {
    if (![self setTimer]) { //超时时间设为0则不展示Loading
        return;
    }
    [self addLoadingCount];
    [CJPayDouyinOpenDeskLoadingView showLoadingOnView:view];
}

- (void)p_stopDouyinLoading {
    [CJPayDouyinOpenDeskLoadingView dismissWithAnimated:YES];
    [self.timerManager stopTimer];
    [self resetLoadingCount];
}

@end
