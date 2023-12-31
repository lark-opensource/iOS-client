//
//  CJUniversalLoginManager.m
//  CJPay
//
//  Created by 王新华 on 10/29/19.
//

#import "CJUniversalLoginManager.h"
#import "CJPayWebViewUtil.h"
#import "CJPayBizWebViewController+Biz.h"
#import "CJPayExceptionViewController.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"

@interface CJUniversalLoginManager()

@property (nonatomic, copy) void (^completionBlock)(CJUniversalLoginResultType, CJPayUniversalLoginModel * _Nullable);
@property (nonatomic, weak) CJPayBizWebViewController *payWebVC;
@property (nonatomic, strong) id<CJUniversalLoginProviderDelegate> provider;
@property (nonatomic, strong, readwrite) CJPayNavigationController *universalLoginNavi;
@property (nonatomic, assign) BOOL isInvalid;

@end

@implementation CJUniversalLoginManager

+ (CJUniversalLoginManager *)bindManager:(id<CJUniversalLoginProviderDelegate>)dataDelegate {
    CJUniversalLoginManager *manager = [CJUniversalLoginManager new];
    manager.provider = dataDelegate;
    return manager;
}

- (void)bindDataDelegate:(id<CJUniversalLoginProviderDelegate>)dataDelegate {
    self.provider = dataDelegate;
}

- (void)execLogin:(void(^ _Nullable)(CJUniversalLoginResultType type, CJPayUniversalLoginModel * _Nullable loginModel))completionBlock {
    if (_isInvalid) {
        return;
    }
    self.completionBlock = [completionBlock copy];
    [self p_refreshLoginInfo];
}

- (CJPayNavigationController *)universalLoginNavi {
    if (!_universalLoginNavi) {
        _universalLoginNavi = [CJPayNavigationController customPushNavigationVC];
    }
    return _universalLoginNavi;
}

// 单例处理清空
- (void)cleanLoginEvent {
    if (self.completionBlock) {
        self.completionBlock = nil;
    }
    @CJStopLoading(self.provider)
    self.isInvalid = YES;
}

- (void)p_openLogin:(nullable CJPayUniversalLoginModel *)loginModel {
    if (_isInvalid) {
        return;
    }
    
    if (![loginModel.code isEqualToString:@"GW400009"] && !loginModel.userInfo) {
        [self p_execCompletionBlock:CJUniversalLoginResultTypeFailed loginModel:loginModel];
        CJPayLogInfo(@"universalLogin Error");
        return;
    }
    
    if ([loginModel.code isEqualToString:@"GW400009"] || loginModel.passModel.isNeedLogin) {
        [self p_gotoUniversalLogin:loginModel];
    } else {
        [self p_execCompletionBlock:CJUniversalLoginResultTypeHasLogin loginModel:loginModel];
    }
}

- (void)p_gotoThrottlePage {
    if (self.universalLoginNavi) {
        CJPayExceptionViewController *throtterVC = [[CJPayExceptionViewController alloc] initWithMainTitle:CJPayLocalizedStr(@"系统拥挤") subTitle:CJPayLocalizedStr(@"排队人数太多了，请休息片刻后再试") buttonTitle:CJPayLocalizedStr(@"知道了")];
        throtterVC.appId = CJString([self.provider getAppId]);
        throtterVC.merchantId = CJString([self.provider getMerchantId]);
        throtterVC.source = CJString([self.provider getSourceName]);
        [self.universalLoginNavi pushViewControllerSingleTop:throtterVC animated:YES completion:nil];
    } else {
        [CJPayExceptionViewController gotoThrotterPageWithAppId:[self.provider getAppId]
                                                     merchantId:[self.provider getMerchantId] fromVC:self.provider.referVC
                                                     closeBlock:nil
                                                         source:[self.provider getSourceName]];
    }
}

- (void)p_gotoUniversalLogin:(CJPayUniversalLoginModel *)loginModel {
    if (_isInvalid) {
        return;
    }
    @CJWeakify(self)
    void(^webBlock)(void) = ^{
        @CJStopLoading(weak_self.provider)
        if (Check_ValidString(loginModel.passModel.redirectUrl)) {
            NSString *url = [CJPayCommonUtil appendParamsToUrl:loginModel.passModel.url params:@{@"fullpage": @"0"}];
            CJPayBizWebViewController *webVC = [CJPayBizWebViewController buildWebBizVC:CJH5CashDeskStyleVertivalHalfScreen finalUrl:url completion:nil];
            webVC.closeCallBack = ^(id _Nonnull data) {
               NSDictionary *dic = (NSDictionary *)data;
               NSString *service = [dic cj_stringValueForKey:@"service"];
               if ([service isEqualToString:@"100"] || [service isEqualToString:@"union_login_finish"]) {
                   if (weak_self.provider.continueProgressWhenLoginSuccess) {
                       [weak_self p_refreshLoginInfo];
                   } else {
                       [weak_self p_execCompletionBlock:CJUniversalLoginResultTypeSuccess loginModel:loginModel];
                   }
               } else {
                   [weak_self p_execCompletionBlock:CJUniversalLoginResultTypeFailed loginModel:loginModel];
               }
            };
            self.payWebVC = webVC;
            self.universalLoginNavi.modalPresentationStyle = CJ_Pad ? UIModalPresentationFormSheet : UIModalPresentationOverFullScreen;
            [self.universalLoginNavi pushViewControllerSingleTop:webVC animated:NO completion:nil];
        } else {
            [weak_self p_execCompletionBlock:CJUniversalLoginResultTypeFailed loginModel:loginModel];
        }
    };
    webBlock();
}

- (void)p_execCompletionBlock:(CJUniversalLoginResultType)type loginModel:(CJPayUniversalLoginModel *)loginModel {
    @CJStopLoading(self.provider)
    CJ_CALL_BLOCK(self.completionBlock, type, loginModel);
}

- (void)p_refreshLoginInfo {
    if (_isInvalid) {
        return;
    }
    @CJStartLoading(self.provider)
    if (self.provider) {
        @CJWeakify(self)
        [self.provider loadData:^(CJPayUniversalLoginModel * _Nullable loginModel, BOOL isNeedThrottle) {
            if (isNeedThrottle) {
                @CJStopLoading(weak_self.provider)
                [weak_self p_gotoThrottlePage];
            } else {
                [weak_self p_openLogin:loginModel];
            }
        }];
    }
}

@end
