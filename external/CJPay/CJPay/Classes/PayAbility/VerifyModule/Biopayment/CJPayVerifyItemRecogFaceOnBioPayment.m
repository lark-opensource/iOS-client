//
//  CJPayVerifyItemBioPaymentRecogFace.m
//  Pods
//
//  Created by 孔伊宁 on 2022/4/1.
//

#import "CJPayVerifyItemRecogFaceOnBioPayment.h"
#import "CJPayFaceRecognitionProtocolViewController.h"
#import "CJPayGetTicketResponse.h"
#import "CJPayMemRecogFaceRequest.h"
#import "CJPayMemberFaceVerifyResponse.h"
#import "CJPayAlertUtil.h"
#import "CJPayMetaSecManager.h"
#import "CJPayFaceRecogAlertViewController.h"
#import "CJPayFaceRecogAlertContentView.h"
#import "CJPayBioPaymentBaseRequestModel.h"
#import "CJPaySafeUtilsHeader.h"
#import "CJPayFaceRecognitionModel.h"
#import "CJPayLoadingManager.h"
#import "CJPayToast.h"
#import "CJPayFaceRecogUtil.h"

@interface CJPayVerifyItemRecogFaceOnBioPayment()

@property (nonatomic, strong) CJPayBDCreateOrderResponse *orderResponse;
@property (nonatomic, strong) CJPayOrderConfirmResponse *confirmResponse;
@property (nonatomic, strong) CJPayBioPaymentBaseRequestModel *requestModel;

@end

NSString * const CJPayBioOpenFaceRecogAlertVCKey = @"CJPayBioOpenFaceRecogAlertVCKey";

@implementation CJPayVerifyItemRecogFaceOnBioPayment

- (void)tryFaceRecogWithResponse:(CJPayBDCreateOrderResponse *)response requestModel:(CJPayBioPaymentBaseRequestModel *)requestModel{
    self.orderResponse = response;
    self.confirmResponse = response.confirmResponse;
    self.requestModel = requestModel;
    self.referVC = requestModel.referVC;
    self.failBefore = 0;
    @CJWeakify(self)
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading title:@"输入密码并开通"];
    [CJKeyboard prohibitKeyboardShow];
    [self.class getTicketWithResponse:self.confirmResponse
                  createOrderResponse:self.orderResponse
                               source:[self getSourceStr]
                               fromVC:[self p_topVC]
                           completion:^(CJPayFaceRecogSignResult signResult, CJPayGetTicketResponse * _Nonnull getTicketResponse) {
        @CJStrongify(self)
        self.getTicketResponse = getTicketResponse;
        [[CJPayLoadingManager defaultService] stopLoading];
        if (signResult == CJPayFaceRecogSignResultSuccess) {
            // 用户已经签了人脸验证协议
            [self p_alertNeedFaceRecogWith:self.confirmResponse getTicketResponse:getTicketResponse];
        } else if (signResult == CJPayFaceRecogSignResultNeedResign) {
            // 用户没有签人脸验证的协议
            [self startSignFaceRecogProtocolWith:self.confirmResponse
                                 getTicketResponse:getTicketResponse];
        }
    }];
}

- (CJPayFaceRecognitionModel *)createFaceRecognitionModelOfFullPage:(CJPayOrderConfirmResponse *)response
                                              withGetTicketResponse:(CJPayGetTicketResponse *)getTicketResponse {
    CJPayFaceRecognitionModel *model = [CJPayFaceRecognitionModel new];
    model.userMaskName  = getTicketResponse.nameMask;
    model.agreementName = getTicketResponse.agreementDesc;
    model.agreementURL = getTicketResponse.agreementUrl;
    model.appId = self.orderResponse.merchant.appId;
    model.merchantId = self.orderResponse.merchant.merchantId;
    model.alivecheckScene = getTicketResponse.faceScene;
    model.alivecheckType = [getTicketResponse.scene isEqualToString:@"cj_live_check"] ? 1 : 0;
    return model;
}

- (void)p_alertNeedFaceRecogWith:(CJPayOrderConfirmResponse *)response getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse {
    NSString *bioOpenFaceRecogAlertVCKey = CJConcatStr(CJPayBioOpenFaceRecogAlertVCKey, CJString(self.requestModel.uid));
    BOOL hasShownBioOpenFaceRecogAlertVC = [[NSUserDefaults standardUserDefaults] boolForKey:bioOpenFaceRecogAlertVCKey];
    if (hasShownBioOpenFaceRecogAlertVC) {
        self.enterFrom = @"0";
        [self startFaceRecogWith:response getTicketResponse:getTicketResponse];
    } else {
        self.enterFrom = @"2";
        [self event:@"wallet_alivecheck_safetyassurace_imp" params:@{}];
        CJPayFaceRecognitionModel *model = [CJPayFaceRecognitionModel new];
        model.agreementName = getTicketResponse.agreementDesc;
        model.agreementURL = getTicketResponse.agreementUrl;
        model.showStyle = CJPayFaceRecognitionStyleOpenBioVerify;
        CJPayFaceRecogAlertViewController *faceRecogAlertVC = [[CJPayFaceRecogAlertViewController alloc] initWithFaceRecognitionModel:model];
        faceRecogAlertVC.contentView.trackDelegate = self;
        NSInteger hasSrcNum = [getTicketResponse.scene isEqualToString:@"cj_live_check"] ? 1 : 0;
        @CJWeakify(self)
        faceRecogAlertVC.closeBtnBlock = ^{
            @CJStrongify(self)
            [self failRecogFace];
            [self event:@"wallet_alivecheck_safetyassurace_click" params:@{
                @"button_type": @(0),
                @"alivecheck_scene": CJString(getTicketResponse.faceScene),
                @"alivecheck_type" : @(hasSrcNum)
            }];
        };
        faceRecogAlertVC.confirmBtnBlock = ^{
            @CJStrongify(self)
            if (self) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:bioOpenFaceRecogAlertVCKey];
                [self startFaceRecogWith:response getTicketResponse:getTicketResponse];
            }
            [self event:@"wallet_alivecheck_safetyassurace_click" params:@{
                @"button_type": @(1),
                @"alivecheck_scene": CJString(getTicketResponse.faceScene),
                @"alivecheck_type" : @(hasSrcNum)
            }];
        };
        [self pushWithVC:faceRecogAlertVC];
    }
}


- (void)failRecogFace {
    UIViewController *topVC = [self p_findTopHalfViewController];
    if (topVC) {
        [CJPayFaceRecogUtil tryPoptoTopHalfVC:topVC];
    }
    [CJKeyboard permitKeyboardShow];
}

- (UIViewController *)p_findTopHalfViewController {
    NSArray *viewControllers = [self p_topVC].navigationController.viewControllers;
    __block UIViewController *halfVC = nil;
    [viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:CJPayHalfPageBaseViewController.class]) {
            halfVC = obj;
            *stop = YES;
        }
    }];
    return halfVC;
}


- (void)submitFaceDataWithResponse:(CJPayOrderConfirmResponse *)response
                 getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse
                           sdkData:(NSString *)sdkData {
    // 此处调用会员识别人脸接口  CJPayMemRecogFaceRequest
    NSString *faceTicket = getTicketResponse.ticket;
    NSMutableDictionary *verifyBizParams = [@{@"out_trade_no": CJString(self.requestModel.memberBizOrderNo),
                                              @"ailab_app_id": @"1792",
                                              @"scene" : CJString(getTicketResponse.scene),
                                              @"live_detect_data" : CJString([CJPaySafeUtil encryptField:sdkData]),
                                              @"ticket" : CJString(faceTicket)} mutableCopy];
    [verifyBizParams cj_setObject:self.orderResponse.merchant.merchantId forKey:@"merchant_id"];
    [verifyBizParams cj_setObject:self.orderResponse.merchant.appId forKey:@"app_id"];
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading title:@"输入密码并开通"];
    @CJWeakify(self);
    [CJPayMemRecogFaceRequest startRequestWithParams:verifyBizParams
                                          completion:^(NSError * _Nonnull error, CJPayMemberFaceVerifyResponse * _Nonnull response) {
        @CJStrongify(self);
        [[CJPayLoadingManager defaultService] stopLoading];
        [CJKeyboard permitKeyboardShow];
        if (response && [response isSuccess]) {
            [self event:@"wallet_alivecheck_result"
                 params:@{@"result": @(1),
                          @"alivecheck_type": Check_ValidString(faceTicket) ? @(1) : @(0),
                          @"enter_from": @(self.enterFrom.intValue),
                          @"fail_before": @(self.failBefore),
                          @"fail_code": CJString(response.code),
                          @"fail_reason": CJString(response.msg),
                          @"url": @"open_bytecert_sdk"}];
            CJ_CALL_BLOCK(self.faceRecogCompletion, YES);
        } else if ([response.code isEqualToString:@"MP060005"]) {
            [self event:@"wallet_alivecheck_result"
                 params:@{@"result": @(0),
                          @"alivecheck_type": Check_ValidString(faceTicket) ? @(1) : @(0),
                          @"enter_from": @(self.enterFrom.intValue),
                          @"fail_before": @(self.failBefore),
                          @"fail_code": CJString(response.code),
                          @"fail_reason": CJString(response.msg),
                          @"url": @"open_bytecert_sdk"}];
            self.confirmResponse.faceVerifyInfo.faceContent = response.faceContent;
            self.confirmResponse.faceVerifyInfo.verifyType = response.faceRecognitionType;
            self.failBefore = 1;
            [self p_alertNeedRetryFaceRecog];
        } else {
            [self failRecogFace];
        }
    }];
}

- (void)p_alertNeedRetryFaceRecog {
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading title:@"输入密码并开通"];
    @CJWeakify(self);
    [CJPayVerifyItemRecogFace getTicketWithResponse:self.confirmResponse
                                createOrderResponse:self.orderResponse
                                             source:[self getSourceStr]
                                             fromVC:[self p_topVC]
                                         completion:^(CJPayFaceRecogSignResult signResult,  CJPayGetTicketResponse * _Nonnull getTicketResponse) {
        @CJStrongify(self);
        self.getTicketResponse = getTicketResponse;
        [[CJPayLoadingManager defaultService] stopLoading];
        
        [self p_showRetryFaceRecogAlertWithConfirmResponse:self.confirmResponse
                                         getTicketResponse:getTicketResponse];
    }];
}

- (void)p_showRetryFaceRecogAlertWithConfirmResponse:(CJPayOrderConfirmResponse *)orderConfirmResponse
                                   getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse  {
    NSInteger hasSrcNum = [getTicketResponse.scene isEqualToString:@"cj_live_check"] ? 1 : 0;
    [self event:@"wallet_alivecheck_fail_pop"
         params:@{@"alivecheck_type": @(hasSrcNum),
                  @"enter_from": @(self.enterFrom.intValue),
                  @"fail_before": @(self.failBefore),
                  @"pop_type" : (Check_ValidString(orderConfirmResponse.faceVerifyInfo.iconUrl) ? @"1": @"0"),
                  @"alivecheck_scene": CJString(getTicketResponse.faceScene)}];

    NSString *headStr = CJPayLocalizedStr(@"人脸识别只能由");
    NSString *tailStr = CJPayLocalizedStr(@"本人操作");
    NSString *messageStr = [NSString stringWithFormat:@"%@ %@ %@",headStr, CJString(getTicketResponse.nameMask), tailStr];
    @CJWeakify(self)
    [CJPayAlertUtil customDoubleAlertWithTitle:CJPayLocalizedStr(@"抱歉，没有认出你") content:messageStr leftButtonDesc:CJPayLocalizedStr(@"取消") rightButtonDesc:CJPayLocalizedStr(@"再试一次") leftActionBlock:^{
        @CJStrongify(self)
        [self event:@"wallet_alivecheck_fail_pop_click"
             params:@{@"alivecheck_type": @(hasSrcNum),
                      @"button_type": @(0),
                      @"enter_from": @(self.enterFrom.intValue),
                      @"fail_before": @(self.failBefore),
                      @"pop_type" : (Check_ValidString(orderConfirmResponse.faceVerifyInfo.iconUrl) ? @"1": @"0"),
                      @"alivecheck_scene": CJString(getTicketResponse.faceScene)}];
        [self failRecogFace];
    } rightActioBlock:^{
        @CJStrongify(self)
        [self event:@"wallet_alivecheck_fail_pop_click"
                  params:@{@"alivecheck_type": @(hasSrcNum),
                           @"button_type": @(1),
                           @"enter_from": @(self.enterFrom.intValue),
                           @"fail_before": @(self.failBefore),
                           @"pop_type" : (Check_ValidString(orderConfirmResponse.faceVerifyInfo.iconUrl) ? @"1": @"0"),
                           @"alivecheck_scene": CJString(getTicketResponse.faceScene)}];
        [self startFaceRecogWith:self.confirmResponse getTicketResponse:getTicketResponse];
    } useVC:[self p_topVC]];
}

- (UIViewController *)p_topVC {
    return [UIViewController cj_foundTopViewControllerFrom:self.referVC];
}

- (BOOL)shouldShowRetainVC {
    return NO;
}

@end
