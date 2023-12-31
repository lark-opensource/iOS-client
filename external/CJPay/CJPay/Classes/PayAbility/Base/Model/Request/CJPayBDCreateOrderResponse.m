//
//  CJPayBDCreateOrderResponse.m
//  Pods
//
//  Created by wangxiaohong on 2020/2/19.
//

#import "CJPayBDCreateOrderResponse.h"
#import "CJPayErrorButtonInfo.h"
#import "CJPayQuickPayChannelModel.h"
#import "CJPayCustomSettings.h"
#import "CJPayUIMacro.h"
#import "CJPayOrderConfirmResponse.h"
#import "CJPayBDRetainInfoModel.h"

@implementation CJPayBDCreateOrderResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{
                                    @"deskConfig" : @"response.cashdesk_show_conf",
                                    @"resultConfig" : @"response.result_page_show_conf",
                                    @"merchant" : @"response.merchant_info",
                                    @"tradeInfo" : @"response.trade_info",
                                    @"payTypeInfo" : @"response.paytype_info",
                                    @"payInfo" : @"response.pay_info",
                                    @"forgetPwdInfo" : @"response.forget_pwd_btn_info",
                                    @"skipPwdGuideInfoModel" : @"response.nopwd_guide_info",
                                    @"userInfo" : @"response.user_info",
                                    @"processInfo" : @"response.process_info",
                                    @"buttonInfo": @"button_info",
                                    @"passModel": @"response.pass_params",
                                    @"needResignCard": @"response.need_resign_card",
                                    @"customSettingStr": @"response.custom_settings",
                                    @"tradeConfirmInfo": @"response.trade_confirm_info",
                                    @"skippwdConfirmResponseDict": @"response.trade_confirm_response",
                                    @"nopwdPreShow": @"response.nopwd_pre_show",
                                    @"skipNoPwdConfirm": @"response.skip_no_pwd_confirm",
                                    @"showNoPwdConfirm": @"response.show_no_pwd_button",
                                    @"showNoPwdConfirmPage": @"response.show_no_pwd_confirm_page",
                                    @"secondaryConfirmInfo": @"response.secondary_confirm_info",
                                    @"preBioGuideInfo": @"response.pre_bio_guide_info",
                                    @"preTradeInfo" : @"response.used_paytype_info",
                                    @"topRightBtnInfo": @"response.top_right_btn_info",
                                    @"showConfirmBioGuideInfo" : @"response.show_confirm_bio_guide_info",
                                    @"skipBioConfirmPage": @"response.skip_bio_confirm_page",
                                    @"retainInfo": @"response.retain_info",
                                    @"retainInfoV2": @"response.retain_info_v2",
                                    @"loadingStyleInfo": @"response.sdk_show_info.loading_style_info",
                                    @"bindCardLoadingStyleInfo": @"response.sdk_show_info.bind_card_loading_style_info",
                                    @"signPageInfo": @"response.sign_page_info",
                                    @"originGetResponse": @"response",
                                    @"balancePromotionModel": @"response.small_change_bind_card_promotion",
                                    @"lynxShowInfo": @"response.lynx_show_info"
                                    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (int)closeAfterTime {
    return self.resultConfig.remainTime.intValue;
}

- (CJPayCustomSettings *)customSetting {
    if (Check_ValidString(self.customSettingStr)) {
        NSError *err = nil;
        CJPayCustomSettings *setting = [[CJPayCustomSettings alloc] initWithString:CJString(self.customSettingStr) error:&err];
        return setting;
    } else {
        NSString *defaultSettingsString = @"{ \"withdraw_page_title\": \"提现\",\n            \"withdraw_page_middle_text\": \"预计3天以内到账，高峰期可能延迟\",\n            \"withdraw_page_bottom_text\": \"\",\n            \"withdraw_result_page_desc\": {\n                \"INIT\": \"\",\n                \"REVIEWING\": \"你的提现申请已经提交，预计3天内完成处理，请耐心等待\",\n                \"PROCESSING\": \"正在为你处理，预计2天内到账，请耐心等待\",\n                \"SUCCESS\": \"到账成功\",\n                \"FAIL\": \"提现失败，查看原因\",\n                \"CLOSED\": \"提现失败，查看原因\",\n                \"TIMEOUT\": \"提现失败，查看原因\",\n                \"REEXCHANGE\": \"提现失败，查看原因\"\n            } }";
        NSError *err = nil;
        CJPayCustomSettings *setting = [[CJPayCustomSettings alloc] initWithString:CJString(defaultSettingsString) error:&err];
        return setting;
    }
}

- (NSString *)intergratedTradeIdentify {
    if (_intergratedTradeIdentify && _intergratedTradeIdentify.length > 0) {
        return _intergratedTradeIdentify;
    }
    return self.tradeInfo.tradeNo;
}

- (CJPayOrderConfirmResponse *)confirmResponse {
    if (!_confirmResponse) {
        NSDictionary *confirmDic = nil;
        if (self.tradeConfirmInfo.count) {
            confirmDic = @{
                @"response": self.tradeConfirmInfo ?: @{}
            };
        } else if (self.skippwdConfirmResponseDict.count) {
            // 免密下单接口和确认支付接口合并
            confirmDic = @{
                @"response": self.skippwdConfirmResponseDict ?: @{}
            };
        }
        _confirmResponse = [[CJPayOrderConfirmResponse alloc] initWithDictionary:confirmDic error:nil];
    }
    return  _confirmResponse;
}

- (BOOL)isSkippwdMerged {
    return Check_ValidDictionary(self.skippwdConfirmResponseDict) && [self.nopwdPreShow isEqualToString:@"1"];
}

@end

@implementation CJPayBDCreateOrderResponse(preTradeWrapper)


- (CJPayPreTradeInfo *)preTradeInfoWrapper {
    CJPayPreTradeInfo *preTradeInfo = nil;
    if (self.preTradeInfo) {
        preTradeInfo = self.preTradeInfo;
    } else if (self.payTypeInfo){
        CJPayPreTradeInfo *tradeInfo = [CJPayPreTradeInfo new];
        tradeInfo.trackInfo = [CJPayPreTradeTrackInfo new];
        tradeInfo.trackInfo.balanceStatus = self.payTypeInfo.balance ? @"1" : @"0";
        tradeInfo.trackInfo.bankCardStatus = [self.payTypeInfo.quickPay hasValidBankCard] ? @"1" : @"0";
        if ([self.payTypeInfo getDefaultBankCardPayConfig]) {
            // 唤端追光不下发 quickPay，需要通过获取第一个张卡来判断是否已绑卡
            tradeInfo.trackInfo.bankCardStatus = @"1";
        }
        tradeInfo.trackInfo.creditStatus = @"";
        
        preTradeInfo = tradeInfo;
    }
    return preTradeInfo;
}

- (CJPayDefaultChannelShowConfig *)getCardModelBy:(NSString *)bankCardId {
    __block CJPayDefaultChannelShowConfig *selectedConfig = nil;
    if (self.preTradeInfo) {
        CJPayQuickPayCardModel *cardModel = [CJPayQuickPayCardModel new];
        cardModel.bankCardID = self.preTradeInfo.bankCardID;
        cardModel.cardNoMask = self.preTradeInfo.cardNoMask;
        cardModel.mobileMask = self.preTradeInfo.mobileMask;
        cardModel.frontBankCodeName = self.preTradeInfo.bankName;
        selectedConfig = [cardModel buildShowConfig].firstObject;
    } else if (self.payTypeInfo) {
        NSArray<CJPayQuickPayCardModel *> *cards = self.payTypeInfo.quickPay.cards;
        [cards enumerateObjectsUsingBlock:^(CJPayQuickPayCardModel * _Nonnull card, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([card.bankCardID isEqualToString:bankCardId]) {
                selectedConfig = [card buildShowConfig].firstObject;
                *stop = YES;
            }
        }];
    }
    CJPayLogAssert(selectedConfig, @"不能根据bankCardId找到对应的卡数据");
    return selectedConfig;
}

- (CJPayDefaultChannelShowConfig *)getPreTradeBalanceChannelShowConfig {
    if (!self.preTradeInfo && self.payTypeInfo) {
        return [self.payTypeInfo.balance buildShowConfig].firstObject;
    }
    CJPayBalanceModel *balanceModel = [CJPayBalanceModel new];
    return [balanceModel buildShowConfig].firstObject;
}

@end
