//
//  CJPayDouyinFailLoadingItem.m
//  Aweme
//
//  Created by liutianyi on 2022/10/24.
//

#import "CJPayDouyinFailLoadingItem.h"
#import "CJPayUIMacro.h"
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayDouyinLoadingView.h"
#import "CJPayBrandPromoteABTestManager.h"

@implementation CJPayDouyinFailLoadingItem

#pragma mark - CJPayAdvanceLoadingProtocol

- (void)stopLoading {
    [self p_stopDouyinLoading];
}

- (void)startLoading {
    [self p_startLoadingWithTitle:[self loadingTitle]];
}

- (void)startLoadingWithTitle:(NSString *)title {
    [self p_startLoadingWithTitle:title];
}

+ (CJPayLoadingType)loadingType {
    return CJPayLoadingTypeDouyinFailLoading;
}

#pragma mark - Private Method
- (void)p_startLoadingWithTitle:(NSString *)title {
    [self addLoadingCount];
    [CJPayDouyinLoadingView showLoadingOnView:[UIApplication btd_mainWindow] title:title subTitle:CJPayLocalizedStr(@"请选择其他支付方式") icon:[self loadingIcon] animated:YES afterDelay:0];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self p_stopDouyinLoading];
    });
}

- (void)p_stopDouyinLoading {
    [CJPayDouyinLoadingView dismissWithAnimated:NO];
    [self resetLoadingCount];
}

- (NSString *)loadingTitle {
    return CJPayDYPayTitleMessage;
}

- (NSString *)loadingIcon {
    return @"cj_super_pay_result_icon";
}
@end
