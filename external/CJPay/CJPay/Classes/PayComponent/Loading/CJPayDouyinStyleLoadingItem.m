//
//  CJPayDouyinStyleLoadingItem.m
//  CJPay
//
//  Created by 孔伊宁 on 2022/8/10.
//

#import "CJPayDouyinStyleLoadingItem.h"
#import "NSDictionary+CJPay.h"
#import "CJPayDouyinStyleLoadingView.h"
#import "CJPayUIMacro.h"

@interface CJPayDouyinStyleLoadingItem ()

@end

@implementation CJPayDouyinStyleLoadingItem
- (void)startLoading {
    [self p_startLoading];
}

- (void)stopLoading {
    [self p_stopLoading];
}

- (void)stopLoadingWithState:(CJPayLoadingQueryState)state {
    CJPayTimerManager *preShowTimer = [CJPayLoadingManager defaultService].preShowTimerManger;
    CJPayTimerManager *payingShowTimer = [CJPayLoadingManager defaultService].payingShowTimerManger;
    if ([preShowTimer isTimerValid]) {
        [preShowTimer appendTimeoutBlock:^{
            [self stopLoadingWithState:state];
        }];
        return;
    }
    
    if ([payingShowTimer isTimerValid]) {
        [payingShowTimer appendTimeoutBlock:^{
            [self p_stoploadingWithState:state];
        }];
        return;
    }
    
    [self p_stoploadingWithState:state];
}

- (void)p_stoploadingWithState:(CJPayLoadingQueryState)state {
    [self.timerManager stopTimer];
    [[CJPayDouyinStyleLoadingView sharedView] stopLoadingWithState:state];
    [self resetLoadingCount];
}

- (void)startLoadingWithTitle:(NSString *)title {
    [self addLoadingCount];
    [[CJPayDouyinStyleLoadingView sharedView] showLoadingWithTitle:title];
}

- (void)startLoadingWithValidateTimer:(BOOL)isNeedValiteTimer {
    [self addLoadingCount];
    if (!isNeedValiteTimer) {
        [[CJPayDouyinStyleLoadingView sharedView] showLoading];
        return;
    }
    
    CJPayLoadingStyleInfo *preLoadingStyleInfo = [CJPayLoadingManager defaultService].loadingStyleInfo;
    CJPayLoadingShowInfo *preShowInfo = preLoadingStyleInfo.preShowInfo;
    if (preLoadingStyleInfo.nopwdCombinePreShowInfo) {
        preShowInfo = preLoadingStyleInfo.nopwdCombinePreShowInfo;
        preLoadingStyleInfo.nopwdCombinePreShowInfo = nil;
    }
    
    NSInteger preShowMinTime = preShowInfo.minTime;
    NSString *preShowText = preShowInfo.text;
    [[CJPayDouyinStyleLoadingView sharedView] showLoadingWithTitle:preShowText];
    if (preShowMinTime <= 0) {
        [self p_preShowTimerTrigger];
        return;
    }
    
    CJPayTimerManager *preShowTimer = [CJPayLoadingManager defaultService].preShowTimerManger;
    [preShowTimer startTimer:preShowMinTime / 1000.0];
    @CJWeakify(preShowTimer)
    preShowTimer.timeOutBlock = ^{
        @CJStrongify(preShowTimer)
        [preShowTimer stopTimer];
        [self p_preShowTimerTrigger];
    };
}

- (void)p_preShowTimerTrigger {
    
    CJPayLoadingStyleInfo *payingLoadingStyleInfo = [CJPayLoadingManager defaultService].loadingStyleInfo;
    CJPayLoadingShowInfo *payingShowInfo = payingLoadingStyleInfo.payingShowInfo;
    if (payingLoadingStyleInfo.nopwdCombinePayingShowInfo) {
        payingShowInfo = payingLoadingStyleInfo.nopwdCombinePayingShowInfo;
        payingLoadingStyleInfo.nopwdCombinePayingShowInfo = nil;
    }
    
    NSInteger payingShowMinTime = payingShowInfo.minTime;
    NSString *payingShowText = payingShowInfo.text;
    
    [[CJPayDouyinStyleLoadingView sharedView] setLoadingTitle:payingShowText];
    if (payingShowMinTime <= 0) {
        return;
    }
    
    CJPayTimerManager *payingShowTimer = [CJPayLoadingManager defaultService].payingShowTimerManger;
    [payingShowTimer startTimer:payingShowMinTime / 1000.0];
    @CJWeakify(payingShowTimer)
    payingShowTimer.timeOutBlock = ^{
        @CJStrongify(payingShowTimer)
        [payingShowTimer stopTimer];
    };
}

#pragma mark - private method
- (void)p_startLoading {
    if (![self setTimer]) { //超时时间设为0则不展示Loading
        return;
    }
    [self addLoadingCount];
    [[CJPayDouyinStyleLoadingView sharedView] showLoading];
}

- (void)p_stopLoading {
    [[CJPayDouyinStyleLoadingView sharedView] dismiss];
    [[CJPayDouyinStyleLoadingView sharedView] removeFromSuperview];
    [self.timerManager stopTimer];
    [self resetLoadingCount];
}

+ (CJPayLoadingType)loadingType {
    return CJPayLoadingTypeDouyinStyleLoading;
}
@end
