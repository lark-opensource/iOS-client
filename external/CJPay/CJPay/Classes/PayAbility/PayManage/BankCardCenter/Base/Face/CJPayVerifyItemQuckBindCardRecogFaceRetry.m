//
//  CJPayVerifyItemQuckBindCardRecogFaceRetry.m
//  Pods
//
//  Created by 尚怀军 on 2020/12/29.
//

#import "CJPayVerifyItemQuckBindCardRecogFaceRetry.h"
#import "CJPayMemRecogFaceRequest.h"
#import "CJPayMemberFaceVerifyResponse.h"
#import "CJPaySDKMacro.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayVerifyItemRecogFace.h"
#import "CJPayGetTicketResponse.h"
#import "CJPaySafeUtilsHeader.h"
#import "CJPayToast.h"

@interface CJPayVerifyItemQuckBindCardRecogFaceRetry()

@property (nonatomic, copy) void(^faceRecogCompletion)(BOOL);

@end

@implementation CJPayVerifyItemQuckBindCardRecogFaceRetry

- (void)startFaceRecogRetryWithResponse:(CJPayOrderConfirmResponse *)response
                             completion:(void(^)(BOOL))completion {
    self.faceRecogCompletion = completion;
    self.confirmResponse = response;
    [self alertNeedRetryFaceRecogWith:response];
}

- (void)submitFaceDataWithResponse:(CJPayOrderConfirmResponse *)response
                 getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse
                           sdkData:(NSString *)sdkData {
    // 此处调用会员识别人脸接口 CJPayMemRecogFaceRequest
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
                          @"alivecheck_type":Check_ValidString(faceTicket) ? @(1) : @(0),
                          @"enter_from":@(2),
                          @"fail_before":@(0),
                          @"fail_code": CJString(response.code),
                          @"fail_reason": CJString(response.msg),
                          @"url": @"open_bytecert_sdk",
                          @"alivecheck_scene": CJString(getTicketResponse.faceScene)}];
            CJ_CALL_BLOCK(self.faceRecogCompletion, YES);
        } else if ([response.code isEqualToString:@"MP060005"]) {
            [self event:@"wallet_alivecheck_result"
                 params:@{@"result": @(0),
                          @"alivecheck_type":Check_ValidString(faceTicket) ? @(1) : @(0),
                          @"enter_from":@(2),
                          @"fail_before":@(0),
                          @"fail_code": CJString(response.code),
                          @"fail_reason": CJString(response.msg),
                          @"url": @"open_bytecert_sdk",
                          @"alivecheck_scene": CJString(getTicketResponse.faceScene)}];
            // 更新face_content以及verifyType开始重新试人脸验证
            self.confirmResponse.faceVerifyInfo.faceContent = response.faceContent;
            self.confirmResponse.faceVerifyInfo.verifyType = response.faceRecognitionType;
            [self alertNeedRetryFaceRecogWith:self.confirmResponse];
        } else {
            [CJToast toastText:CJPayLocalizedStr(@"人脸识别失败") inWindow:self.referVC.cj_window];
            CJ_CALL_BLOCK(self.faceRecogCompletion, NO);
        }
    }];
}

- (void)failRetryRecogFace {
    CJ_CALL_BLOCK(self.faceRecogCompletion, NO);
}

- (void)showLoading:(BOOL)isLoading {
    if (self.loadingBlock) {
        self.loadingBlock(isLoading);
    } else {
        [super showLoading:isLoading];
    }
}

- (CJPayBDCreateOrderResponse *)getCreateOrderResponse {
    // 一键绑卡下单的接口传回的数据塞到CJPayBDCreateOrderResponse
    return self.orderResponse;
}

- (NSString *)getSourceStr {
    return @"one_key_sign";
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
