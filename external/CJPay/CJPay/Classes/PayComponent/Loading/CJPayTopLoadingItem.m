//
//  CJPayTopLoadingItem.m
//  CJPay
//
//  Created by 尚怀军 on 2019/11/12.
//

#import "CJPayTopLoadingItem.h"
#import "CJPayUIMacro.h"
#import "CJPayBaseLoadingView.h"
#import "CJPayProtocolManager.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayTopLoadingProtocol.h"

@interface CJPayTopLoadingItem()

@property (nonatomic, strong) CJPayBaseLoadingView *loadingView;

@end

@implementation CJPayTopLoadingItem

#pragma mark - CJPayAdvanceLoadingProtocol

- (void)stopLoading {
    CJ_DECLARE_ID_PROTOCOL(CJPayTopLoadingProtocol);
    if (objectWithCJPayTopLoadingProtocol && [objectWithCJPayTopLoadingProtocol respondsToSelector:@selector(dismissWindowLoading)]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [objectWithCJPayTopLoadingProtocol dismissWindowLoading];
        });
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.loadingView stopAnimating];
            [self.loadingView removeFromSuperview];
        });
    }
    [self.timerManager stopTimer];
    [self resetLoadingCount];
}

- (void)stopLoadingWithState:(CJPayLoadingQueryState)state {
    [self stopLoading];
}

- (void)startLoading {
    [self startLoadingWithVc:[UIViewController cj_topViewController] title:@""];
}

- (void)startLoadingWithValidateTimer:(BOOL)isNeedValiteTimer {
    [self startLoading];
}

- (void)startLoadingWithVc:(UIViewController *)vc {
    [self startLoadingWithVc:vc title:@""];
}

- (void)startLoadingWithTitle:(NSString *)title {
    [self startLoadingWithVc:[UIViewController cj_topViewController] title:title];
}

- (void)startLoadingWithVc:(UIViewController *)vc title:(NSString *)title {
    if (![self setTimer]) {
        return;
    }
    CJ_DECLARE_ID_PROTOCOL(CJPayTopLoadingProtocol);
    UIViewController *curVC = vc ?: [UIViewController cj_foundTopViewControllerFrom:vc];
    [self addLoadingCount];
    if (objectWithCJPayTopLoadingProtocol && [objectWithCJPayTopLoadingProtocol respondsToSelector:@selector(showWindowLoadingWithTitle:)]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [objectWithCJPayTopLoadingProtocol showWindowLoadingWithTitle:CJString(title)];
        });
    } else {
        @CJWeakify(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @CJStrongify(self);
            [self.loadingView removeFromSuperview];
            UIView *vcView = curVC.view;
            [vcView addSubview:self.loadingView];
            CJPayMasReMaker(self.loadingView, {
                make.edges.equalTo(vcView);
            });
            self.loadingView.stateDescText = Check_ValidString(title) ? title : CJPayLocalizedStr(@"加载中...");
            [self.loadingView startAnimating];
        });
    }
}

- (void)startLoadingOnView:(UIView *)view {
    [self startLoading];
}

+ (CJPayLoadingType)loadingType {
    return CJPayLoadingTypeTopLoading;
}

- (BOOL)setTimer {
    //settings未拉取到，设置默认值
    if (![CJPaySettingsManager shared].currentSettings.loadingConfig) {
        [self.timerManager startTimer:15];
        return YES;
    }
    
    NSInteger timeout = [CJPaySettingsManager shared].currentSettings.loadingConfig.loadingTimeOut;
    if (timeout < 0) {
        timeout = 15;
    }
    if (timeout != 0) {
        [self.timerManager startTimer:timeout];
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Getter
- (CJPayBaseLoadingView *)loadingView {
    if (!_loadingView) {
        _loadingView = [[CJPayBaseLoadingView alloc] init];
    }
    return _loadingView;
}

- (CJPayTimerManager *)timerManager {
    if (!_timerManager) {
        _timerManager = [CJPayTimerManager new];
        @CJWeakify(self)
        _timerManager.timeOutBlock = ^{
            @CJStrongify(self)
            [self stopLoading];
        };
    }
    return _timerManager;
}

@end
