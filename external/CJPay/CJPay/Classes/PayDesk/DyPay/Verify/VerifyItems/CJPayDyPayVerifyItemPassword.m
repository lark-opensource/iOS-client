//
//  CJPayDyPayVerifyItemPassword.m
//  AlipaySDK-AlipaySDKBundle
//
//  Created by 利国卿 on 2022/9/28.
//

#import "CJPayDyPayVerifyItemPassword.h"
#import "CJPayDyPayVerifyManager.h"
#import "CJPayHalfVerifyPasswordNormalViewController.h"
#import "CJPayVerifyPasswordViewModel.h"
#import "CJPayRetainInfoV2Config.h"
#import "CJPayUIMacro.h"
#import "CJPaySettingsManager.h"
#import "CJPayBaseRequest+CJPayCustomHost.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CJPayDyPayVerifyItemPassword

- (void)createVerifyPasscodeVC {
    [super createVerifyPasscodeVC];
    
    // 唤端追光需在密码页展示金额和营销信息
    if (self.manager.isPaymentForOuterApp && [self.verifyPasscodeVC isKindOfClass:CJPayHalfVerifyPasswordNormalViewController.class]) {
        //唤端追光场景，有营销则在验密页展示金额和营销
        CJPayDefaultChannelShowConfig *curSelectConfig = self.viewModel.defaultConfig;
        NSDictionary *standardParams = [curSelectConfig getStandardAmountAndVoucher];
        NSString *payVoucherMsg = [standardParams cj_stringValueForKey:@"pay_voucher"];
        ((CJPayHalfVerifyPasswordNormalViewController *)self.verifyPasscodeVC).isForceNormal = !Check_ValidString(payVoucherMsg);
    }
}

- (CJPayVerifyPasswordViewModel *)createPassCodeViewModel {
    CJPayVerifyPasswordViewModel *viewModel = [super createPassCodeViewModel];
    viewModel.isPaymentForOuterApp = self.manager.isPaymentForOuterApp;
    return viewModel;
}

// 唤端追光从response.retainInfo中取得挽留信息
- (CJPayRetainUtilModel *)buildRetainUtilModel {
    CJPayRetainUtilModel *model = [CJPayRetainUtilModel new];
    model.intergratedTradeNo = self.manager.response.intergratedTradeIdentify;
    model.intergratedMerchantID = self.manager.response.merchant.intergratedMerchantId;
    model.processInfoDic = [self.manager.response.processInfo dictionaryValue];
    model.trackDelegate = self;
    model.retainInfo = self.manager.response.retainInfo;
    model.retainInfoV2Config = [self p_buildRetainInfoV2Config];
    model.notSumbitServerEvent = self.manager.isPaymentForOuterApp;
    
    NSInteger voucherType = [self.manager.response.payInfo.voucherType integerValue];
    model.isHasVoucher = voucherType != 0 && voucherType != 10;
    
    return model;
}

- (CJPayRetainInfoV2Config *)p_buildRetainInfoV2Config {
    CJPayRetainInfoV2Config *retainV2Config = [[CJPayRetainInfoV2Config alloc] init];
    retainV2Config.appId = self.manager.response.merchant.jhAppId;
    retainV2Config.zgAppId = self.manager.response.merchant.appId;
    retainV2Config.merchantId = self.manager.response.merchant.merchantId;
    retainV2Config.jhMerchantId = self.manager.response.merchant.intergratedMerchantId;
    retainV2Config.traceId = [self.manager.trackInfo cj_stringValueForKey:@"trace_id"];
    retainV2Config.retainInfoV2 = self.manager.response.retainInfoV2;
    retainV2Config.hostDomain = [CJPayBaseRequest jhHostString];
    NSDictionary *merchantRetainInfo = [self.manager.response.retainInfoV2 cj_dictionaryValueForKey:@"merchant_retain_info"];
    retainV2Config.retainSchema = [merchantRetainInfo cj_stringValueForKey:@"lynx_schema"];
    retainV2Config.processInfo = [self.manager.response.processInfo dictionaryValue];
    retainV2Config.isOnlyShowNormalRetainStyle = self.manager.hasChangeSelectConfigInVerify;
    return retainV2Config;
}

- (void)closeAction {
    [self.manager sendEventTOVC:CJPayHomeVCEventClosePayDesk obj:@(CJPayHomeVCCloseActionSourceFromBack)];
}

@end
NS_ASSUME_NONNULL_END
