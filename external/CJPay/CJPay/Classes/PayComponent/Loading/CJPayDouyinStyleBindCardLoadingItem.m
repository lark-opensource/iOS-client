//
//  CJPayDouyinStyleBindCardLoadingItem.m
//  Aweme
//
//  Created by liutianyi on 2023/7/27.
//

#import "CJPayDouyinStyleBindCardLoadingItem.h"
#import "CJPayDouyinStyleLoadingView.h"
#import "CJPayUIMacro.h"

@implementation CJPayDouyinStyleBindCardLoadingItem

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
            [self p_stopLoadingWithState:state];
        }];
        return;
    }
    
    [self p_stopLoadingWithState:state];
}

- (void)p_stopLoadingWithState:(CJPayLoadingQueryState)state {
    [self.timerManager stopTimer];
    [[CJPayDouyinStyleLoadingView sharedView] stopLoadingWithState:state];
    [self resetLoadingCount];
}

- (void)startLoadingWithTitle:(NSString *)title {
    [self addLoadingCount];
    [[CJPayDouyinStyleLoadingView sharedView] showLoadingWithTitle:title];
}

- (void)startLoadingWithValidateTimer:(BOOL)isNeedValidateTimer {
    [self addLoadingCount];
    if (!isNeedValidateTimer) {
        [[CJPayDouyinStyleLoadingView sharedView] showLoading];
        return;
    }
    
    if ([CJPayLoadingManager defaultService].bindCardLoadingStyleInfo) {
        [self p_showBindCardLoadingStyleInfo];
    } else if ([CJPayLoadingManager defaultService].loadingStyleInfo) {
        [self p_showLoadingStyleInfo];
    }
}

- (void)p_showBindCardLoadingStyleInfo {
    CJPayLoadingStyleInfo *bindCardPreLoadingStyleInfo = [CJPayLoadingManager defaultService].bindCardLoadingStyleInfo;
    CJPayLoadingShowInfo *bindCardCompleteShowInfo = bindCardPreLoadingStyleInfo.bindCardCompleteShowInfo;
    CJPayLoadingShowInfo *bindCardPreShowInfo = bindCardPreLoadingStyleInfo.bindCardConfirmPreShowInfo;
    CJPayLoadingShowInfo *bindCardPayingShowInfo = bindCardPreLoadingStyleInfo.bindCardConfirmPayingShowInfo;
    
    NSInteger bindCardCompleteShowMinTime = bindCardCompleteShowInfo.minTime;
    NSString *bindCardCompleteShowText = bindCardCompleteShowInfo.text;
    
    [[CJPayDouyinStyleLoadingView sharedView] showLoadingWithTitle:bindCardCompleteShowText];
    if (bindCardCompleteShowText <= 0) {
        [self p_bindCardCompleteShowTimerTrigger];
        return;
    }
    CJPayTimerManager *bindCardCompleteShowTimer = [CJPayLoadingManager defaultService].preShowTimerManger;
    [bindCardCompleteShowTimer startTimer:bindCardCompleteShowMinTime / 1000.0];
    @CJWeakify(bindCardCompleteShowTimer)
    bindCardCompleteShowTimer.timeOutBlock = ^{
        @CJStrongify(bindCardCompleteShowTimer)
        [bindCardCompleteShowTimer stopTimer];
        [self p_bindCardCompleteShowTimerTrigger];
    };
}

- (void)p_showLoadingStyleInfo {
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

- (void)p_bindCardCompleteShowTimerTrigger {
    
    CJPayLoadingStyleInfo *payingLoadingStyleInfo = [CJPayLoadingManager defaultService].bindCardLoadingStyleInfo;
    CJPayLoadingShowInfo *payingShowInfo = payingLoadingStyleInfo.bindCardConfirmPreShowInfo;
    if (payingLoadingStyleInfo.nopwdCombinePayingShowInfo) {
        payingShowInfo = payingLoadingStyleInfo.nopwdCombinePayingShowInfo;
        payingLoadingStyleInfo.nopwdCombinePayingShowInfo = nil;
    }
    
    NSInteger payingShowMinTime = payingShowInfo.minTime;
    NSString *payingShowText = payingShowInfo.text;
    
    [[CJPayDouyinStyleLoadingView sharedView] setLoadingTitle:payingShowText];
    if (payingShowMinTime <= 0) {
        [self p_bindCardPayingShowTimerTrigger];
        return;
    }
    
    CJPayTimerManager *payingShowTimer = [CJPayLoadingManager defaultService].payingShowTimerManger;
    [payingShowTimer startTimer:payingShowMinTime / 1000.0];
    @CJWeakify(payingShowTimer)
    payingShowTimer.timeOutBlock = ^{
        @CJStrongify(payingShowTimer)
        [payingShowTimer stopTimer];
        [self p_bindCardPayingShowTimerTrigger];
    };
}

- (void)p_bindCardPayingShowTimerTrigger {
    
    CJPayLoadingStyleInfo *payingLoadingStyleInfo = [CJPayLoadingManager defaultService].bindCardLoadingStyleInfo;
    CJPayLoadingShowInfo *payingShowInfo = payingLoadingStyleInfo.bindCardConfirmPayingShowInfo;
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
