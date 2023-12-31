//
//  CJPaySuperPayVerifyManager.m
//  Pods
//
//  Created by wangxiaohong on 2022/11/1.
//

#import "CJPaySuperPayVerifyManager.h"

#import "CJPayUIMacro.h"
#import "CJPayOneKeyConfirmRequest.h"
#import "CJPayMetaSecManager.h"
#import "CJPayOrderConfirmResponse.h"
#import "CJPayToast.h"
#import "UIViewController+CJPay.h"
#import "CJPaySuperPayController.h"
#import "CJPayFrontCashierResultModel.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPaySettingsManager.h"
#import "CJPaySuperPayQueryRequest.h"
#import "CJPayMerchantInfo.h"
#import "CJPayHintInfo.h"
#import "CJPayDeskUtil.h"

@implementation CJPaySuperPayVerifyManager

+ (instancetype)managerWith:(id<CJPayHomeVCProtocol>)homePageVC {
    NSDictionary *defaultVerifyItemsDic = @{
        @(CJPayVerifyTypeSignCard)          : @"CJPayVerifyItemSignCard",
        @(CJPayVerifyTypeBioPayment)        : @"CJPayVerifyItemBioPayment",
        @(CJPayVerifyTypePassword)          : @"CJPayVerifyItemPassword",
        @(CJPayVerifyTypeSMS)               : @"CJPaySuperVerifyItemSMS",
        @(CJPayVerifyTypeUploadIDCard)      : @"CJPayVerifyItemUploadIDCard",  // 上传身份证影印件
        @(CJPayVerifyTypeAddPhoneNum)       : @"CJPayVerifyItemAddPhoneNum",  // 补充联系手机号
        @(CJPayVerifyTypeIDCard)            : @"CJPayVerifyItemIDCard", // 账户受限
        @(CJPayVerifyTypeRealNameConflict)  : @"CJPayVerifyItemRealNameConflict",
        @(CJPayVerifyTypeFaceRecog)         : @"CJPayVerifyItemRecogFace",
        @(CJPayVerifyTypeForgetPwdFaceRecog): @"CJPayVerifyItemForgetPwdRecogFace",
        @(CJPayVerifyTypeFaceRecogRetry)    : @"CJPayVerifyItemRecogFaceRetry",
        @(CJPayVerifyTypeSkipPwd)           : @"CJPayVerifyItemSkipPwd",
        @(CJPayVerifyTypeSkip)              : @"CJPayVerifyItemSkip"
    };
    return [self managerWith:homePageVC withVerifyItemConfig:defaultVerifyItemsDic];
}

- (void)requestConfirmPayWithOrderResponse:(CJPayBDCreateOrderResponse *)orderResponse withExtraParams:(NSDictionary *)extraParams completion:(void (^)(NSError * _Nonnull, CJPayOrderConfirmResponse * _Nonnull))completionBlock {
    [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeRiskUserVerifyResult];
    [CJPayOneKeyConfirmRequest startWithOrderResponse:orderResponse
                                      withExtraParams:extraParams
                                           completion:^(NSError * _Nonnull error, CJPayOrderConfirmResponse * _Nonnull response) {
        CJ_CALL_BLOCK(completionBlock,error,response);
    }];
}


- (NSDictionary *)buildConfirmRequestParamsByCurPayChannel {
    NSMutableDictionary *dic = [[super buildConfirmRequestParamsByCurPayChannel] mutableCopy];
    
    CJPayDefaultChannelShowConfig *selectChannel = self.defaultConfig;
    if (selectChannel.type == BDPayChannelTypeCreditPay) {
        NSDictionary *creditItemDict = @{
            @"credit_pay_installment" : CJString(self.homePageVC.createOrderResponse.payInfo.creditPayInstallment),
            @"decision_id" : CJString(self.homePageVC.createOrderResponse.payInfo.decisionId)
        };
        [dic cj_setObject:creditItemDict forKey:@"credit_item"];
    }
    return [dic copy];
}

- (void)confirmRequestSuccess:(CJPayOrderConfirmResponse *)response withChannelType:(CJPayChannelType)channelType
{
    if (![response isSuccess]) {
        @CJStopLoading(self);
        NSString *toastMsg = Check_ValidString(response.msg) ? response.msg : CJPayNoNetworkMessage;
        [CJToast toastText:toastMsg inWindow:[self.homePageVC topVC].cj_window];
        [CJMonitor trackService:@"wallet_rd_paydesk_confirm_failed"
                       category:@{@"code":CJString(response.code),
                                  @"msg":CJString(response.msg),
                                  @"desk_identify": @"极速付收银台",
                                  @"is_pay_newcard": self.isBindCardAndPay ? @"1" : @"0"}
                          extra:@{}];
        [self sendEventTOVC:CJPayHomeVCEventOccurUnHandleConfirmError obj:response];
        
        return;
    }
    // 一键极速支付不用查单, 直接回调聚合支付成功
    NSDictionary *queryResponseDic = @{@"response": response.tradeQueryResponseDic ?: @{}};
    CJPayBDOrderResultResponse *orderResultResponse = [[CJPayBDOrderResultResponse alloc] initWithDictionary:queryResponseDic
                                                                                             error:nil];
    if (self.verifyManagerQueen && [self.verifyManagerQueen respondsToSelector:@selector(afterLastQueryResultWithResultResponse:)]) {
        [self.verifyManagerQueen afterLastQueryResultWithResultResponse:orderResultResponse];
    }
    [self.homePageVC endVerifyWithResultResponse:orderResultResponse];
}

//极速付目前仅有电商场景，所以直接全部走lynx绑卡
- (void)onBindCardAndPayAction {
    [[CJPayLoadingManager defaultService] stopLoading];
    NSString * const defalutBindCardLynxScheme = @"sslocal://webcast_lynxview?url=https%3A%2F%2Flf-webcast-sourcecdn-tos.bytegecko.com%2Fobj%2Fbyte-gurd-source%2F10181%2Fgecko%2Fresource%2Fcj_lynx_cardbind%2Frouter%2Ftemplate.js&hide_loading=1&show_error=1&trans_status_bar=1&type=popup&hide_nav_bar=1&web_bg_color=transparent&width_percent=100&height_percent=100&open_animate=0&mask_alpha=0.1&gravity=center&mask_click_disable=0&top_level=1&host=aweme&engine_type=new&page_name=member_biz";//兜底
    
    NSDictionary *bind_card_info = [self.payContext.extParams cj_dictionaryValueForKey:@"bind_card_info"];
    NSString *bind_card_info_str = [CJPayCommonUtil dictionaryToJson:bind_card_info];
    NSDictionary *trackInfo = [self.payContext.extParams cj_dictionaryValueForKey:@"track_info"]?:@{};
    
    NSDictionary *processDict = [CJPayCommonUtil jsonStringToDictionary:CJString(self.payContext.defaultConfig.cardAddExt)];
    NSMutableDictionary *processInfo = [NSMutableDictionary new];
    [processInfo addEntriesFromDictionary:([processDict cj_dictionaryValueForKey:@"promotion_process"] ?:@{})];
    [processInfo cj_setObject:@"" forKey:@"process_info"];
    NSDictionary *params = @{
        @"merchant_id" : CJString(self.hintInfo.merchantInfo.merchantId),
        @"app_id" : CJString(self.hintInfo.merchantInfo.appId),
        @"bind_card_info" : CJString(bind_card_info_str),
        @"process_info" : CJString([CJPayCommonUtil dictionaryToJson:processInfo]),
        @"track_info" : CJString([CJPayCommonUtil dictionaryToJson:trackInfo]),
        @"card_trade_scene" : @"pay",
        @"tea_source" : @"super_pay"
    };
    NSString *initialScheme = [CJPaySettingsManager shared].currentSettings.bindcardLynxUrl;
    if (!Check_ValidString(initialScheme)) {
        initialScheme = defalutBindCardLynxScheme;
    }
    NSString *schema = [CJPayCommonUtil appendParamsToUrl:initialScheme
                                                params:params];
    [CJPayDeskUtil openLynxPageBySchema:schema completionBlock:^(CJPayAPIBaseResponse * _Nonnull response) {
        NSDictionary *data = response.data;
        BOOL isBindCardSuccess = NO;
        
        if (Check_ValidDictionary(data) && [data cj_dictionaryValueForKey:@"data"]) {
            NSDictionary *dataDic = [data cj_dictionaryValueForKey:@"data"];
            NSDictionary *msgDic = [dataDic cj_dictionaryValueForKey:@"msg"];
            if (msgDic) {
                int code = [msgDic cj_intValueForKey:@"code" defaultValue:0];
                if (code == 1) {
                    NSDictionary *payAgainParams = @{
                        @"channel_code" : @"HZ",
                        @"bank_card_id" : CJString([msgDic cj_stringValueForKey:@"bank_card_id"]),
                    };
                    isBindCardSuccess = YES;
                    [self sendEventTOVC:CJPayHomeVCEventSuperBindCardFinish obj:payAgainParams];
                }
            }
        }
        
        // 绑卡失败，取消绑卡
        if (!isBindCardSuccess) {
            [self sendEventTOVC:CJPayHomeVCEventSuperBindCardFinish obj:@{}];
        }
    }];
}

@end
