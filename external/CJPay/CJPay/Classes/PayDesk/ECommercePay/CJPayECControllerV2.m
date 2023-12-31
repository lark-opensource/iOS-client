//
//  CJPayECControllerV2.m
//  CJPaySandBox
//
//  Created by wangxiaohong on 2023/6/2.
//

#import "CJPayECControllerV2.h"

#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPayECController.h"
#import "CJPayDouPayProcessController.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayStayAlertForOrderModel.h"
#import "CJPayKVContext.h"
#import "CJPayAlertUtil.h"
#import "CJPayDouPayProcessVerifyManager.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"

@interface CJPayECControllerV2 ()

@property (nonatomic, assign) CJPayCashierScene cashierScene; //标识前置收银台使用场景

@property (nonatomic, copy, nullable) void (^completion)(CJPayDouPayResultCode, NSString *);

@property (nonatomic, strong) CJPayDouPayProcessController *douPayController;

@end

@implementation CJPayECControllerV2

- (void)startPaymentWithParams:(NSDictionary *)params completion:(nonnull void (^)(CJPayDouPayResultCode, NSString * _Nonnull))completion {
    
    [self p_setCashierScene:params];
    NSString *channelData = [params cj_stringValueForKey:@"channel_data"];
    CJPayBDCreateOrderResponse *response = [[CJPayBDCreateOrderResponse alloc] initWithDictionary:@{@"response": [channelData cj_toDic] ?: @{}} error:nil];
    self.completion = completion;
    [self p_handleParams:params response:response]; // 根据业务入参来解析部分配置
    CJPayDouPayProcessModel *model = [CJPayDouPayProcessModel new];
    model.createResponse = response;
    model.showConfig = [self p_getDefaultShowConfigWithResponse:response];
    model.homeVC = self;
    model.extParams = params;
    model.bizParams = params;
    
    if (self.cashierScene == CJPayCashierSceneEcommerce) {
        model.cashierType = CJPayCashierTypeFullPage;
        model.resultPageStyle = CJPayDouPayResultPageStyleHiddenAll;
        model.isShowMask = YES;
        model.lynxBindCardBizScence = CJPayLynxBindCardBizScenceECCashier;
    } else {
        model.resultPageStyle = [[params cj_stringValueForKey:@"need_result_page"] isEqualToString:@"1"] ? CJPayDouPayResultPageStyleShowAll : CJPayDouPayResultPageStyleHiddenAll; //是否需要展示结果页
        model.cashierType = [[params cj_stringValueForKey:@"cashier_page_mode"] isEqualToString:@"halfpage"] ? CJPayCashierTypeHalfPage : CJPayCashierTypeFullPage; //前置页面类型
        model.lynxBindCardBizScence = CJPayLynxBindCardBizScencePreStandardPay;
        model.isCallBackAdvance = YES;
    }
    @CJWeakify(self)
    [self.douPayController douPayProcessWithModel:model completion:^(CJPayDouPayProcessResultModel * _Nonnull resultModel) {
        @CJStrongify(self)
        [self p_handleDouPayResultWithResultModel:resultModel];
    }];
}

- (void)p_handleDouPayResultWithResultModel:(CJPayDouPayProcessResultModel *)resultModel {
    CJ_CALL_BLOCK(self.completion, resultModel.resultCode, resultModel.errorDesc);
}

//从params解析收银台配置
- (void)p_handleParams:(NSDictionary *)params response:(CJPayBDCreateOrderResponse *)response {
    [CJPayKVContext kv_setValue:[[CJPayStayAlertForOrderModel alloc] initWithTradeNo:response.intergratedTradeIdentify] forKey:CJPayStayAlertShownKey];
    CJPayStayAlertForOrderModel *model = [CJPayKVContext kv_valueForKey:CJPayStayAlertShownKey];
    model.hasShow = [[params cj_stringValueForKey:@"has_cashier_show_retain"] isEqualToString:@"1"]; //是否需要展示挽留
}

- (CJPayDefaultChannelShowConfig *)p_getDefaultShowConfigWithResponse:(CJPayBDCreateOrderResponse *)response {
    CJPayChannelType channelType = [CJPayBDTypeInfo getChannelTypeBy:response.payInfo.businessScene];
    CJPayDefaultChannelShowConfig *defaultShowConfig = [CJPayDefaultChannelShowConfig new];
    defaultShowConfig.type = channelType;
    
    if (channelType == BDPayChannelTypeAddBankCard ||
        channelType == BDPayChannelTypeAfterUsePay ||
        channelType == BDPayChannelTypeIncomePay ||
        channelType == BDPayChannelTypeFundPay) {
        return defaultShowConfig;
    }
    
    if (channelType == BDPayChannelTypeCreditPay) {
        defaultShowConfig.mobile = response.userInfo.mobile;
        if ([defaultShowConfig.payChannel isKindOfClass:CJPaySubPayTypeInfoModel.class]) {
            defaultShowConfig.payTypeData = ((CJPaySubPayTypeInfoModel *)defaultShowConfig.payChannel).payTypeData;
        } else {
            defaultShowConfig.payTypeData = [CJPaySubPayTypeData new];
        }
        [defaultShowConfig.payTypeData updateDefaultCreditModel:[response.payInfo buildCreditPayMethodModel]];
        defaultShowConfig.decisionId = response.payInfo.decisionId;
        return defaultShowConfig;
    }
    
    if (channelType == BDPayChannelTypeBankCard) {
        return [response getCardModelBy:response.payInfo.bankCardId];
    }
    
    if (channelType == BDPayChannelTypeCombinePay) {
        if ([response.payInfo.primaryPayType isEqualToString:@"new_bank_card"]) {
            defaultShowConfig.type = BDPayChannelTypeAddBankCard;
        } else {
            defaultShowConfig = [response getCardModelBy:response.payInfo.bankCardId];
        }
        defaultShowConfig.isCombinePay = YES;
        CJPayChannelType combineType = CJPayChannelTypeNone;
        NSString *combineTypeStr = response.payInfo.combineType;
        if ([combineTypeStr isEqualToString:@"3"]) {
            combineType = BDPayChannelTypeBalance;
        } else if ([combineTypeStr isEqualToString:@"129"]) {
            combineType = BDPayChannelTypeIncomePay;
        }
        defaultShowConfig.combineType = combineType;
        return defaultShowConfig;
    }
    
    if (channelType == BDPayChannelTypeBalance) {
        return [response getPreTradeBalanceChannelShowConfig];
    }
    return nil;
}

// 解析收银台调用场景
- (void)p_setCashierScene:(NSDictionary *)params {
    BOOL isPreStandardPay = [[params cj_stringValueForKey:@"cashier_scene"] isEqualToString:@"standard"];
    BOOL isCashierSourceLynx = [[params cj_stringValueForKey:@"cashier_source_temp"] isEqualToString:@"lynx"];
    self.cashierScene = isPreStandardPay && isCashierSourceLynx ? CJPayCashierScenePreStandard : CJPayCashierSceneEcommerce; //根据入参区分是电商场景还是本地生活场景
}

- (NSDictionary *)getPerformanceInfo {
    return [self.douPayController getPerformanceInfo];
}

- (NSString *)checkTypeName {
    return [self.douPayController.verifyManager.lastWakeVerifyItem checkTypeName];
}

#pragma mark - Getter
- (CJPayDouPayProcessController *)douPayController {
    if (!_douPayController) {
        _douPayController = [CJPayDouPayProcessController new];
    }
    return _douPayController;
}

@end
