//
//  CJPayVerifyItemBindCardRecogFace.m
//  Pods
//
//  Created by 尚怀军 on 2020/12/29.
//

#import "CJPayVerifyItemBindCardRecogFace.h"
#import "CJPayMemRecogFaceRequest.h"
#import "CJPayCreateOneKeySignOrderResponse.h"
#import "CJPayVerifyItemQuckBindCardRecogFaceRetry.h"
#import "CJPayMemberFaceVerifyInfoModel.h"
#import "CJPayFaceVerifyInfo.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayMemberFaceVerifyResponse.h"
#import "CJPayGetTicketResponse.h"
#import "CJPaySafeUtilsHeader.h"
#import "CJPayFaceRecognitionModel.h"
#import "CJPayUIMacro.h"
#import "CJPayToast.h"

@interface CJPayVerifyItemBindCardRecogFace()

@property (nonatomic, strong) CJPayBDCreateOrderResponse *orderResponse;
@property (nonatomic, strong) CJPayOrderConfirmResponse *confirmResponse;
@property (nonatomic, strong) CJPayVerifyItemQuckBindCardRecogFaceRetry *retryVerifyItem;
@property (nonatomic, copy) NSString *memberBizOrderNo;
@property (nonatomic, copy) void(^faceRecogCompletion)(BOOL);
@property (nonatomic, copy) NSString *bindCardSource;
@property (nonatomic, assign) BOOL shouldShowProtocolView;

@end

@implementation CJPayVerifyItemBindCardRecogFace

- (void)startFaceRecogWithOneKeyResponse:(CJPayCreateOneKeySignOrderResponse *)oneKeySignOrderResponse
                              completion:(void(^)(BOOL))completion {
    self.faceRecogCompletion = completion;
    self.bindCardSource = @"one_key_sign";
    [self p_updateWithOneKeyResponse:oneKeySignOrderResponse];
    [CJPayABTest getABTestValWithKey:CJPayABBindcardFaceRecog];
    [self tryFaceRecogWithResponse:self.confirmResponse];
}
- (void)startSignFaceRecogProtocolWith:(CJPayOrderConfirmResponse *)response getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse {
    self.shouldShowProtocolView = YES;
    [self alertNeedFaceRecogWith:response getTicketResponse:getTicketResponse];
}

- (CJPayFaceRecognitionModel *)createFaceRecognitionModelOfAlert:(CJPayOrderConfirmResponse *)response withGetTicketResponse:(CJPayGetTicketResponse *)getTicketResponse {
    CJPayFaceRecognitionModel *model = [super createFaceRecognitionModelOfAlert:response withGetTicketResponse:getTicketResponse];
    model.showStyle = CJPayFaceRecognitionStyleExtraTestInBindCard;
    model.shouldShowProtocolView = self.shouldShowProtocolView;
    if (self.shouldShowProtocolView) {
        model.appId = [self getCreateOrderResponse].merchant.appId;
        model.merchantId = [self getCreateOrderResponse].merchant.merchantId;
    }
    model.buttonText = self.shouldShowProtocolView ? CJPayLocalizedStr(@"同意并刷脸验证") : CJPayLocalizedStr(@"安全刷脸验证");
    self.shouldShowProtocolView = NO;
    return model;
}

- (void)startFaceRecogWithParams:(NSDictionary *)params faceVerifyInfo:(CJPayFaceVerifyInfo *)verifyInfo completion:(void (^)(BOOL))completion {
    self.faceRecogCompletion = completion;
    
    self.orderResponse.merchant.merchantId = [params cj_stringValueForKey:@"merchant_id"];
    self.orderResponse.merchant.appId = [params cj_stringValueForKey:@"app_id"];
    self.orderResponse.tradeInfo.outTradeNo = [params cj_stringValueForKey:@"member_biz_order_no"];
    self.memberBizOrderNo = self.orderResponse.tradeInfo.outTradeNo;
    self.confirmResponse.faceVerifyInfo = verifyInfo;
    self.bindCardSource = [params cj_stringValueForKey:@"bind_card_source"];;
    
    [self tryFaceRecogWithResponse:self.confirmResponse];
}

- (void)p_updateWithOneKeyResponse:(CJPayCreateOneKeySignOrderResponse *)oneKeySignOrderResponse {
    self.orderResponse.merchant.merchantId = oneKeySignOrderResponse.merchantId;
    self.orderResponse.merchant.appId = oneKeySignOrderResponse.appId;
    self.orderResponse.tradeInfo.outTradeNo = oneKeySignOrderResponse.memberBizOrderNo;
    
    self.confirmResponse.faceVerifyInfo = [oneKeySignOrderResponse.faceVerifyInfoModel getFaceVerifyInfoModel];
    self.memberBizOrderNo = oneKeySignOrderResponse.memberBizOrderNo;
    
}

- (void)submitFaceDataWithResponse:(CJPayOrderConfirmResponse *)response
                 getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse
                           sdkData:(NSString *)sdkData {
    // 此处调用会员识别人脸接口  CJPayMemRecogFaceRequest
    NSString *faceTicket = getTicketResponse.ticket;
    NSMutableDictionary *verifyBizParams = [@{@"out_trade_no": CJString(self.memberBizOrderNo),
                                              @"ailab_app_id": @"1792",
                                              @"scene" : CJString(getTicketResponse.scene),
                                              @"live_detect_data" : CJString([CJPaySafeUtil encryptField:sdkData]),
                                              @"ticket" : CJString(faceTicket),
                                              @"face_scene" : CJString(getTicketResponse.faceScene)} mutableCopy];
    [verifyBizParams cj_setObject:self.orderResponse.merchant.merchantId forKey:@"merchant_id"];
    [verifyBizParams cj_setObject:self.orderResponse.merchant.appId forKey:@"app_id"];
    [self showLoading:YES];
    @CJWeakify(self);
    [CJPayMemRecogFaceRequest startRequestWithParams:verifyBizParams
                                          completion:^(NSError * _Nonnull error, CJPayMemberFaceVerifyResponse * _Nonnull response) {
        @CJStrongify(self);
        [self showLoading:NO];
        if (response && [response isSuccess]) {
            [self event:@"wallet_alivecheck_result"
                 params:@{@"result": @(1),
                          @"alivecheck_type": Check_ValidString(faceTicket) ? @(1) : @(0),
                          @"enter_from": @(self.enterFrom.intValue),
                          @"fail_before": @(1),
                          @"fail_code": CJString(response.code),
                          @"fail_reason": CJString(response.msg),
                          @"url": @"open_bytecert_sdk",
                          @"alivecheck_scene": CJString(getTicketResponse.faceScene)}];
            CJ_CALL_BLOCK(self.faceRecogCompletion, YES);
        } else if ([response.code isEqualToString:@"MP060005"]) {
            [self event:@"wallet_alivecheck_result"
                 params:@{@"result": @(0),
                          @"alivecheck_type": Check_ValidString(faceTicket) ? @(1) : @(0),
                          @"enter_from": @(self.enterFrom.intValue),
                          @"fail_before": @(1),
                          @"fail_code": CJString(response.code),
                          @"fail_reason": CJString(response.msg),
                          @"url": @"open_bytecert_sdk",
                          @"alivecheck_scene": CJString(getTicketResponse.faceScene)}];
            // 更新face_content以及verifyType开始重新试人脸验证
            self.confirmResponse.faceVerifyInfo.faceContent = response.faceContent;
            self.confirmResponse.faceVerifyInfo.verifyType = response.faceRecognitionType;
            self.retryVerifyItem.memberBizOrderNo = self.memberBizOrderNo;
            self.retryVerifyItem.orderResponse = self.orderResponse;
            self.retryVerifyItem.loadingBlock = [self.loadingBlock copy];
            self.retryVerifyItem.referVC = self.referVC;
            self.retryVerifyItem.verifySource = self.verifySource;
            [self.retryVerifyItem startFaceRecogRetryWithResponse:self.confirmResponse
                                                       completion:[self.faceRecogCompletion copy]];
        } else {
            [CJToast toastText:CJPayLocalizedStr(@"人脸识别失败") inWindow:self.referVC.cj_window];
            CJ_CALL_BLOCK(self.faceRecogCompletion, NO);
        }
    }];
}

- (void)failRecogFace {
    CJ_CALL_BLOCK(self.faceRecogCompletion, NO);
}

- (NSString *)getSourceStr {
    if (Check_ValidString(self.bindCardSource)) {
        return self.bindCardSource;
    }
    
    return @"bind_card_sign";
}

#pragma - mark  override
- (void)showLoading:(BOOL)isLoading {
    if (self.loadingBlock) {
        self.loadingBlock(isLoading);
    } else {
        [super showLoading:isLoading];
    }
}

- (CJPayBDCreateOrderResponse *)getCreateOrderResponse {
    return self.orderResponse;
}

- (CJPayVerifyItemQuckBindCardRecogFaceRetry *)retryVerifyItem {
    if (!_retryVerifyItem) {
        _retryVerifyItem = [CJPayVerifyItemQuckBindCardRecogFaceRetry new];
    }
    return _retryVerifyItem;
}

- (CJPayBDCreateOrderResponse *)orderResponse {
    if (!_orderResponse) {
        _orderResponse = [CJPayBDCreateOrderResponse new];
        CJPayMerchantInfo *merchant = [CJPayMerchantInfo new];
        CJPayUserInfo *userInfo = [CJPayUserInfo new];
        _orderResponse.merchant = merchant;
        _orderResponse.userInfo = userInfo;
        CJPayBDTradeInfo *tradeInfo = [CJPayBDTradeInfo new];
        _orderResponse.tradeInfo = tradeInfo;
    }
    return _orderResponse;
}

- (CJPayOrderConfirmResponse *)confirmResponse {
    if (!_confirmResponse) {
        _confirmResponse = [CJPayOrderConfirmResponse new];
    }
    return _confirmResponse;
}

- (void)event:(NSString *)event params:(NSDictionary *)params {
    NSMutableDictionary *trackParam = [NSMutableDictionary new];
    if (params) {
        [trackParam addEntriesFromDictionary:params];
    }
    [trackParam cj_setObject:CJString(self.orderResponse.merchant.merchantId) forKey:@"merchant_id"];
    [trackParam cj_setObject:CJString(self.orderResponse.merchant.appId) forKey:@"app_id"];
    [trackParam cj_setObject:@"1" forKey:@"is_chaselight"];
    [trackParam cj_setObject:CJString(self.verifySource) forKey:@"risk_source"];
    NSString *aliveCheckStyleStr = [self.getTicketResponse getLiveRouteTrackStr];
    [trackParam cj_setObject:aliveCheckStyleStr forKey:@"alivecheck_style"];
    [CJTracker event:event params:trackParam];
}

- (NSString *)checkTypeName {
    return @"人脸";
}

@end
