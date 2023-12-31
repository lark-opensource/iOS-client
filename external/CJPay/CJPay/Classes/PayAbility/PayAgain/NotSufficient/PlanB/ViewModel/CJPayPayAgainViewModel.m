//
//  CJPayPayAgainViewModel.m
//  Pods
//
//  Created by wangxiaohong on 2021/7/2.
//

#import "CJPayPayAgainViewModel.h"

#import "CJPayQueryPayTypeRequest.h"
#import "CJPayPayAgainTradeCreateRequest.h"
#import "CJPayIntegratedChannelModel.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPaySDKMacro.h"
#import "CJPayHintInfo.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPayCreateOrderResponse.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayCreditPayMethodModel.h"
#import "CJPayMerchantInfo.h"
#import "CJPayOrderConfirmResponse.h"
#import "CJPayQueryPayTypeResponse.h"
#import "CJPayPayAgainTradeCreateResponse.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayFrontCashierResultModel.h"

@interface CJPayPayAgainViewModel()

@property (nonatomic, copy) NSDictionary *processInfo;
@property (nonatomic, strong) CJPayHintInfo *hintInfo;
@property (nonatomic, strong, readwrite) CJPayBDCreateOrderResponse *createOrderResponse;
@property (nonatomic, strong, readwrite) CJPayIntegratedChannelModel *cardListModel;
@property (nonatomic, strong) CJPayOrderConfirmResponse *confirmResponse;

@end

@implementation CJPayPayAgainViewModel

- (instancetype)initWithConfirmResponse:(CJPayOrderConfirmResponse *)confirmResponse createRespons:(CJPayBDCreateOrderResponse *)createResponse {
    self = [super init];
    if (self) {
        _confirmResponse = confirmResponse;
        _createOrderResponse = createResponse;
        _hintInfo = confirmResponse.hintInfo;
        _defaultShowConfig= [confirmResponse.hintInfo.recPayType buildShowConfig].firstObject;
        _currentShowConfig = _defaultShowConfig;
        _processInfo = [createResponse.processInfo toDictionary];
        _defaultShowConfig.isCombinePay = confirmResponse.hintInfo.recPayType.isCombinePay;
        if (_defaultShowConfig.isCombinePay) {
            _defaultShowConfig.combineType = [confirmResponse.combineType isEqualToString:@"3"] ? BDPayChannelTypeBalance : BDPayChannelTypeIncomePay;
        }
    }
    return self;
}

//用于兼容极速付二次支付
- (instancetype)initWithHintInfo:(CJPayHintInfo *)hintInfo {
    self = [super init];
    if (self) {
        _hintInfo = hintInfo;
        _defaultShowConfig = [hintInfo.recPayType buildShowConfig].firstObject;
        _currentShowConfig = _defaultShowConfig;
    }
    return self;
}

- (void)fetchNotSufficientCardListResponseWithCompletion:(nullable void(^)(BOOL))completionBlock {
    [CJPayQueryPayTypeRequest startWithParams:[self p_cardListParams]
                                                     completion:^(NSError * _Nonnull error, CJPayQueryPayTypeResponse * _Nonnull response) {
        if ([response isSuccess]) {
            self.cardListModel = response.tradeInfo;
        }
        CJ_CALL_BLOCK(completionBlock, YES);
    }];
}

- (void)fetchNotSufficientTradeCreateResponseWithCompletion:(nullable void(^)(BOOL))completionBlock {
    [CJPayPayAgainTradeCreateRequest startWithParams:[self p_createParams]
                                                        completion:^(NSError * _Nonnull error, CJPayPayAgainTradeCreateResponse * _Nonnull response) {
        if ([response isSuccess]) {
            self.createOrderResponse = response.pageInfo;
            [CJPayLoadingManager defaultService].loadingStyleInfo = response.pageInfo.loadingStyleInfo;
        }
        CJ_CALL_BLOCK(completionBlock, [response isSuccess]);
    }];
}

- (void)fetchCombinationPaymentResponseWithCompletion:(nullable void(^)(BOOL))completionBlock {
    [CJPayPayAgainTradeCreateRequest startWithParams:[self p_createCombineParams]
                                                        completion:^(NSError * _Nonnull error, CJPayPayAgainTradeCreateResponse * _Nonnull response) {
        if ([response isSuccess]) {
            self.createOrderResponse = response.pageInfo;
            [CJPayLoadingManager defaultService].loadingStyleInfo = response.pageInfo.loadingStyleInfo;
        }
        CJ_CALL_BLOCK(completionBlock, [response isSuccess]);
    }];
}

- (CJPayFrontCashierContext *)payContext {
    CJPayFrontCashierContext *context = [CJPayFrontCashierContext new];
    context.defaultConfig = self.currentShowConfig;
    CJPayDefaultChannelShowConfig *currentConfig = self.currentShowConfig;
    
    currentConfig.isSecondPayCombinePay = currentConfig.isCombinePay;
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (self.extParams.count > 0) {
        [params addEntriesFromDictionary:self.extParams];
    }
    
    NSDictionary *bindCardInfo = @{
        @"bank_code": CJString(currentConfig.frontBankCode),
        @"card_type": CJString(currentConfig.cardType),
        @"card_add_ext": CJString(currentConfig.cardAddExt)
    };
    [params cj_setObject:bindCardInfo forKey:@"bind_card_info"];
    context.extParams = params;
    
    @CJWeakify(self);
    context.latestOrderResponseBlock = ^CJPayBDCreateOrderResponse * _Nonnull{
        @CJStrongify(self);
        return self.createOrderResponse;
    };
    context.defaultConfig.isCombinePay = self.currentShowConfig.isCombinePay;
    return context;
}

- (NSDictionary *)trackerParams {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (self.confirmResponse) {
        [params cj_setObject:CJString(self.confirmResponse.code) forKey:@"error_code"];
        [params cj_setObject:CJString(self.confirmResponse.msg) forKey:@"error_message"];
        NSString *secondPayType = [self.confirmResponse.payType isEqualToString:@"creditpay"] ? @"creditpay" : @"bytepay";
        [params cj_setObject:secondPayType forKey:@"second_pay_type"];
    }
    NSMutableArray *activityInfos = [NSMutableArray array];
    NSDictionary *activityInfo = [self.currentShowConfig toActivityInfoTracker];
    if (self.currentShowConfig.isCombinePay) {
        activityInfo = [self.currentShowConfig toCombinePayActivityInfoTracker];
    }
    if (activityInfo.count > 0 ) {
        [activityInfos addObject:activityInfo];
    }
    [params cj_setObject:activityInfos forKey:@"activity_info"];
    
    return params;
}

- (NSString *)p_getCurrentCombineTypeStr {
    CJPayDefaultChannelShowConfig *showConfig = self.currentShowConfig;
    if (!showConfig.isCombinePay) {
        return @"";
    }
    return showConfig.combineType == BDPayChannelTypeBalance ? @"3" : @"129";
}

- (NSDictionary *)p_createParams {
    CJPayDefaultChannelShowConfig *showConfig = self.currentShowConfig;
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params cj_setObject:self.processInfo forKey:@"process_info"];
    [params cj_setObject:showConfig.businessScene forKey:@"business_scene"];
    if (showConfig.isCombinePay) {
        [params cj_setObject:@"Pre_Pay_Combine" forKey:@"business_scene"];
        [params cj_setObject:[self p_getCurrentCombineTypeStr] forKey:@"combine_type"];
        [params cj_setObject:showConfig.subPayType forKey:@"primary_pay_type"];
    }
    if (showConfig.type == BDPayChannelTypeBankCard) {
        [params cj_setObject:showConfig.bankCardId forKey:@"bank_card_id"];
    }
    
    NSArray *vouchers = [showConfig.voucherInfo.vouchers valueForKey:@"voucherNo"];
    if (vouchers) {
        [params cj_setObject:vouchers forKey:@"voucher_no_list"];
    }
    [params cj_setObject:[self.confirmResponse.exts cj_objectForKey:@"ext_param"] forKey:@"ext_param"];
    [params cj_setObject:self.createOrderResponse.merchant.appId forKey:@"app_id"];
    [params cj_setObject:self.createOrderResponse.merchant.merchantId forKey:@"merchant_id"];
    // 后台存在下发抖分期没有勾选分期方案的case
    NSString *installmentStr = Check_ValidString(self.installment) ? self.installment : @"1";
    [params cj_setObject:installmentStr forKey:@"credit_pay_installment"];
    return [params copy];
}

- (NSDictionary *)p_createCombineParams {
    CJPayDefaultChannelShowConfig *showConfig = self.currentShowConfig;
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params cj_setObject:self.processInfo forKey:@"process_info"];
    [params cj_setObject:@"Pre_Pay_Combine" forKey:@"business_scene"];
    [params cj_setObject:[self p_getCurrentCombineTypeStr] forKey:@"combine_type"];
    [params cj_setObject:showConfig.subPayType forKey:@"primary_pay_type"];
        
    if (showConfig.type == BDPayChannelTypeBankCard) {
        [params cj_setObject:showConfig.bankCardId forKey:@"bank_card_id"];
    }
    
    id vouchers = [showConfig.voucherInfo.vouchers valueForKey:@"voucherNo"];
    if (vouchers && [vouchers isKindOfClass:NSArray.class]) {
        [params cj_setObject:(NSArray *)vouchers forKey:@"voucher_no_list"];
    }
    [params cj_setObject:[self.confirmResponse.exts cj_objectForKey:@"ext_param"] forKey:@"ext_param"];
    [params cj_setObject:self.createOrderResponse.merchant.appId forKey:@"app_id"];
    [params cj_setObject:self.createOrderResponse.merchant.merchantId forKey:@"merchant_id"];
    return [params copy];
}

- (NSDictionary *)p_cardListParams {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params cj_setObject:self.processInfo forKey:@"process_info"];
    [params cj_setObject:self.createOrderResponse.merchant.appId forKey:@"app_id"];
    [params cj_setObject:self.createOrderResponse.merchant.merchantId forKey:@"merchant_id"];
    return params;
}

@end
