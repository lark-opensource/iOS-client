//
//  CJPayVerifyItemStandardRecogFaceRetry.m
//  transferpay_standard
//
//  Created by shanghuaijun on 2023/6/6.
//

#import "CJPayVerifyItemStandardRecogFaceRetry.h"
#import "CJPayAlertUtil.h"
#import "CJPayUIMacro.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayGetTicketResponse.h"
#import "UIViewController+CJTransition.h"
#import "CJPaySafeUtilsHeader.h"
#import "CJPaySettingsManager.h"
#import "CJPayFaceRecogManager.h"
#import "CJPayFaceRecogConfigModel.h"
#import "CJPayFaceRecogResultModel.h"

@implementation CJPayVerifyItemStandardRecogFaceRetry

- (BOOL)shouldHandleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    // 人脸验证失败，再试一次
    if (self.manager.lastConfirmVerifyItem == self) {
        [self event:@"wallet_alivecheck_result"
             params:@{@"result": [response isSuccess] ? @(1) : @(0),
                      @"alivecheck_type":[response.faceVerifyInfo.verifyType isEqualToString:@"1"] ? @(1) : @(0),
                      @"fail_before": @(1),
                      @"fail_code": CJString(response.code),
                      @"fail_reason": CJString(response.msg),
                      @"enter_from":@([self.getTicketResponse getEnterFromValue]),
                      @"url": @"open_bytecert_sdk",
                      @"alivecheck_scene": CJString(self.getTicketResponse.faceScene)}];
    }
    if ([response.code isEqualToString:@"CD002011"]) {
        return YES;
    }
    return NO;
}

- (void)event:(NSString *)event params:(NSDictionary *)params {
    NSMutableDictionary *trackParamDic = [NSMutableDictionary new];
    if (params) {
        [trackParamDic addEntriesFromDictionary:params];
    }
    NSString *aliveCheckStyleStr = [self.getTicketResponse getLiveRouteTrackStr];
    [trackParamDic cj_setObject:aliveCheckStyleStr forKey:@"alivecheck_style"];
    [super event:event params:trackParamDic];
}

- (void)handleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    if ([response.code isEqualToString:@"CD002011"]) {
        self.verifySource = [self wakeVerifySource];
        [self alertNeedRetryFaceRecogWith:response];
    }    
}

- (void)requestVerifyWithCreateOrderResponse:(CJPayBDCreateOrderResponse *)response
                                       event:(nullable CJPayEvent *)event {
    if (self.manager.isOneKeyQuickPay) {
        self.verifySource = @"极速支付-加验";
    }
    [self alertNeedRetryFaceRecogWith:response.confirmResponse];
}

- (void)alertNeedRetryFaceRecogWith:(CJPayOrderConfirmResponse *)orderConfirmResponse {
    [CJKeyboard prohibitKeyboardShow];
    CJPayFaceRecogConfigModel *faceRecogConfigModel = [CJPayFaceRecogConfigModel new];
    faceRecogConfigModel.popStyle = CJPayFaceRecogPopStyleRetry;
    faceRecogConfigModel.shouldCallBackAfterClose = YES;
    faceRecogConfigModel.appId = self.manager.response.merchant.appId;
    faceRecogConfigModel.merchantId = self.manager.response.merchant.merchantId;
    NSString *memBizOrderNo = self.manager.response.tradeInfo.outTradeNo;
    faceRecogConfigModel.memberBizOrderNo = Check_ValidString(memBizOrderNo) ? memBizOrderNo : CJString(orderConfirmResponse.outTradeNo);
    faceRecogConfigModel.sourceStr = [self getSourceStr];
    faceRecogConfigModel.riskSource = CJString(self.verifySource);
    faceRecogConfigModel.fromVC = [UIViewController cj_topViewController];
    faceRecogConfigModel.faceVerifyInfo = orderConfirmResponse.faceVerifyInfo;
    @CJWeakify(self)
    faceRecogConfigModel.trackerBlock = ^(NSString * _Nonnull event, NSDictionary * _Nonnull params) {
        @CJStrongify(self)
        [self event:event params:params];
    };
    faceRecogConfigModel.getTicketLoadingBlock = ^(BOOL isLoading) {
        @CJStrongify(self)
        [self showLoading:isLoading];
    };
    faceRecogConfigModel.faceRecogCompletion = ^(CJPayFaceRecogResultModel * _Nonnull resultModel) {
        @CJStrongify(self)
        switch (resultModel.result) {
            case CJPayFaceRecogResultTypeSuccess:
                self.getTicketResponse = resultModel.getTicketResponse;
                [self submitFaceDataWithResponse:orderConfirmResponse
                               getTicketResponse:resultModel.getTicketResponse
                                         sdkData:resultModel.faceDataStr];
                break;
            case CJPayFaceRecogResultTypeFail:
                [self failRetryRecogFace];
                break;
            case CJPayFaceRecogResultTypeCancel:
                [self failRetryRecogFace];
                break;
            default:
                [self failRetryRecogFace];
                break;
        }
    };
    [CJKeyboard prohibitKeyboardShow];
    [[CJPayFaceRecogManager sharedInstance] startFaceRecogWithConfigModel:faceRecogConfigModel];
}

- (NSString *)getSourceStr {
    return @"cashdesk_pay";
}

- (void)failRetryRecogFace {
    [CJKeyboard permitKeyboardShow];
    if (self.manager.isStandardDouPayProcess) {
        [self notifyVerifyCancel];
    } else {
        [self.manager sendEventTOVC:CJPayHomeVCEventUserCancelRiskVerify obj:@(CJPayVerifyTypeFaceRecogRetry)];
        [self.manager sendEventTOVC:CJPayHomeVCEventDismissAllAboveVCs obj:@(0)];
    }
}

- (UIViewController *)p_topVC {
    if (self.manager.homePageVC) {
        return [UIViewController cj_foundTopViewControllerFrom:[self.manager.homePageVC topVC]];
    } else {
        return [UIViewController cj_foundTopViewControllerFrom:self.referVC];
    }
}

- (void)pushWithVC:(UIViewController *)vc {
    UIViewController *topVC = [self p_topVC];
    if (topVC.navigationController && [topVC.navigationController isKindOfClass:[CJPayNavigationController class]]) {
        if (self.manager.homePageVC) {
            [self.manager.homePageVC push:vc animated:YES];
            return;
        }
        [topVC.navigationController pushViewController:vc animated:YES];
    } else {
        if ([vc isKindOfClass:[CJPayBaseViewController class]]) {
            if (self.manager.homePageVC) {
                [self.manager.homePageVC push:vc animated:YES];
            } else {
                CJPayBaseViewController *baseVC = (CJPayBaseViewController *)vc;
                [baseVC presentWithNavigationControllerFrom:topVC useMask:NO completion:nil];
            }
        }
    }
}

- (void)showLoading:(BOOL)isLoading {
    if (self.manager.loadingDelegate) {
        if (isLoading) {
            @CJStartLoading(self.manager.loadingDelegate)
        } else {
            @CJStopLoading(self.manager.loadingDelegate)
        }
        return;
    }
    
    if (isLoading) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading];
    } else {
        [[CJPayLoadingManager defaultService] stopLoading];
    }
}

- (void)submitFaceDataWithResponse:(CJPayOrderConfirmResponse *)response
                 getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse
                           sdkData:(NSString *)sdkData {
    NSMutableDictionary *requestParams = [NSMutableDictionary new];
    if (Check_ValidString(self.manager.response.processInfo.processId)) {
        sdkData = [NSString stringWithFormat:@"%@%@", sdkData, self.manager.response.processInfo.processId];
    }
    NSDictionary *verifyParams = @{@"face_app_id": @"1792",
                                   @"face_scene" : CJString(getTicketResponse.scene),
                                   @"face_sdk_data" : CJString([CJPaySafeUtil encryptField:sdkData]),
                                   @"face_veri_ticket" : CJString(getTicketResponse.ticket)};
    
    [requestParams cj_setObject:verifyParams forKey:@"face_verify_params"];
    [requestParams cj_setObject:CJString(response.payFlowNo) forKey:@"pay_flow_no"];
    [requestParams cj_setObject:@"5" forKey:@"req_type"];
    [requestParams addEntriesFromDictionary:[self.manager loadSpecificTypeCacheData:CJPayVerifyTypeLast]]; // 获取上次的验证数据
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showLoading:YES];
    });
    [CJKeyboard permitKeyboardShow];
    [self.manager submitConfimRequest:requestParams fromVerifyItem:self];
}

- (NSString *)wakeVerifySource {
    NSString *verifySource = [self.manager.lastWakeVerifyItem checkTypeName];
    NSString *wakeVerifySource = [NSString stringWithFormat:@"%@-加验", verifySource];
    return wakeVerifySource;
}

- (NSString *)checkTypeName {
    return @"人脸";
}

@end
