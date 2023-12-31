//
//  CJPayPayUpgradeServiceImpl.m
//  Aweme
//
//  Created by 王晓红 on 2023/8/28.
//

#import "CJPayPayUpgradeServiceImpl.h"

#import "CJPaySDKMacro.h"
#import "CJPayDeskUtil.h"
#import "CJPayProtocolManager.h"
#import "CJPayCashierModule.h"
#import "CJPayQueryMergeBindRelationResponse.h"
#import "CJPayQueryMergeBindRelationRequest.h"
#import "CJPaySettingsManager.h"

@interface CJPayPayUpgradeServiceImpl()<CJPayPayUpgradeService>

@end

@implementation CJPayPayUpgradeServiceImpl

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassToPtocol(self, CJPayPayUpgradeService)
})

- (void)i_openPayUpgradeWithParams:(NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate {
    NSString *lynxSchema = [CJPaySettingsManager shared].currentSettings.lynxSchemaConfig.payUpgradeSchema;
    if (!Check_ValidString(lynxSchema)) {
        lynxSchema = @"sslocal://lynxview_popup/?channel=ttpay_lynx_lark&bundle=router%2Ftemplate.js&popup_enter_type=center&container_bg_color=transparent&dynamic=1&hide_nav_bar=1&hide_status_bar=0&trans_status_bar=1&page_name=upgrade&surl=https%3A%2F%2Ftosv.boe.byted.org%2Fobj%2Fgecko-internal%2F10874%2Fgecko%2Fresource%2Fttpay_lynx_lark%2Frouter%2Ftemplate.js&loading_bg_color=transparent&isPresent=true";
    }
    NSString *finalSchema = [CJPayCommonUtil appendParamsToUrl:lynxSchema params:params];
    [CJPayDeskUtil openLynxPageBySchema:finalSchema completionBlock:^(CJPayAPIBaseResponse * _Nullable response) {
        if (delegate && [delegate respondsToSelector:@selector(onResponse:)]) {
            [delegate onResponse:response];
        }
    }];
}

- (void)i_getWalletUrlWithParams:(NSDictionary *)params completion:(void (^)(NSString * _Nonnull walletUrl))completionBlock {
    [CJPayQueryMergeBindRelationRequest startWithParams:@{
        @"app_id" : CJString([params cj_stringValueForKey:@"app_id"]),
        @"merchant_id" : CJString([params cj_stringValueForKey:@"merchant_id"])
    } completion:^(NSError * _Nonnull error, CJPayQueryMergeBindRelationResponse * _Nonnull response) {
        NSString *walletUrl = @"";
        if ([response isSuccess] && Check_ValidString(response.walletPageUrl)) {
            walletUrl = response.walletPageUrl;
        }
        CJ_CALL_BLOCK(completionBlock, walletUrl);
    }];
}

- (BOOL)wakeByUniversalPayDesk:(NSDictionary *)dictionary withDelegate:(nullable id<CJPayAPIDelegate>)delegate {
    [self i_openPayUpgradeWithParams:dictionary delegate:delegate];
    return YES;
}

@end
