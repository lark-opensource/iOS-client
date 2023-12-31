//
//  CJPayVerifyItemStandardRecogFace.m
//
//
//  Created by shanghuaijun on 2023/6/6.
//

#import "CJPayVerifyItemStandardRecogFace.h"
#import "CJPayGetTicketRequest.h"
#import "CJPayGetTicketResponse.h"
#import "CJPayUIMacro.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayOrderConfirmResponse.h"
#import "CJPayLoadingManager.h"
#import "CJPayBaseVerifyManager.h"
#import "UIViewController+CJTransition.h"
#import "CJPayMetaSecManager.h"
#import "CJPaySafeUtilsHeader.h"
#import "CJPaySettingsManager.h"
#import "CJPayHalfPageBaseViewController.h"
#import "CJPayFaceRecogManager.h"
#import "CJPayFaceRecogConfigModel.h"
#import "CJPayFaceRecogResultModel.h"
#import "CJPayFaceRecogUtil.h"

@implementation CJPayVerifyItemStandardRecogFace

- (BOOL)shouldHandleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    // 需要人脸验证
    if (self.manager.lastConfirmVerifyItem == self) {
        [self event:@"wallet_alivecheck_result"
             params:@{@"result": [response isSuccess] ? @(1) : @(0),
                      @"alivecheck_type":[response.faceVerifyInfo.verifyType isEqualToString:@"1"] ? @(1) : @(0),
                      @"fail_before":@(0),
                      @"fail_code": CJString(response.code),
                      @"fail_reason": CJString(response.msg),
                      @"enter_from":@([self.getTicketResponse getEnterFromValue]),
                      @"url": @"open_bytecert_sdk",
                      @"pop_type" : (Check_ValidString(response.faceVerifyInfo.iconUrl) ? @"1": @"0"),
                      @"alivecheck_scene": CJString(self.getTicketResponse.faceScene)}];
    }
    if ([response.code isEqualToString:@"CD002104"]) {
        return YES;
    }
    return NO;
}

- (void)handleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    if ([response.code isEqualToString:@"CD002104"]) {
        self.verifySource = [self handleSourceType];
        [self tryFaceRecogWithResponse:response];
    }
}

- (void)requestVerifyWithCreateOrderResponse:(CJPayBDCreateOrderResponse *)response
                                       event:(nullable CJPayEvent *)event {
    // 下单转确认支付
    if (self.manager.isOneKeyQuickPay) {
        self.verifySource = @"极速支付-加验";
    }
    [self tryFaceRecogWithResponse:response.confirmResponse];
}

- (void)tryFaceRecogWithResponse:(CJPayOrderConfirmResponse *)orderConfirmResponse {
    [CJKeyboard prohibitKeyboardShow];
    CJPayFaceRecogConfigModel *faceRecogConfigModel = [CJPayFaceRecogConfigModel new];
    faceRecogConfigModel.popStyle = CJPayFaceRecogPopStyleRiskVerifyInPay;
    faceRecogConfigModel.shouldCallBackAfterClose = YES;
    faceRecogConfigModel.appId = self.manager.response.merchant.appId;
    faceRecogConfigModel.merchantId = self.manager.response.merchant.merchantId;
    NSString *memBizOrderNo = self.manager.response.tradeInfo.outTradeNo;
    faceRecogConfigModel.memberBizOrderNo = Check_ValidString(memBizOrderNo) ? memBizOrderNo : CJString(orderConfirmResponse.outTradeNo);
    faceRecogConfigModel.sourceStr = [self getSourceStr];
    faceRecogConfigModel.riskSource = CJString(self.verifySource);
    faceRecogConfigModel.fromVC = [UIViewController cj_topViewController];
    faceRecogConfigModel.faceVerifyInfo = orderConfirmResponse.faceVerifyInfo;
    faceRecogConfigModel.retainUtilModel = [self buildRetainUtilModel];
    @CJWeakify(self)
    faceRecogConfigModel.trackerBlock = ^(NSString * _Nonnull event, NSDictionary * _Nonnull params) {
        @CJStrongify(self)
        [self event:event params:params];
    };
    faceRecogConfigModel.pagePushBlock = ^(CJPayBaseViewController * _Nonnull vc, BOOL animated) {
        @CJStrongify(self)
        [self pushWithVC:vc];
    };
    faceRecogConfigModel.getTicketLoadingBlock = ^(BOOL isLoading) {
        @CJStrongify(self)
        [self showLoading:isLoading];
    };
    faceRecogConfigModel.faceRecogCompletion = ^(CJPayFaceRecogResultModel * _Nonnull resultModel) {
        @CJStrongify(self)
        switch (resultModel.result) {
            case CJPayFaceRecogResultTypeSuccess:
                if (self.manager) {
                    [CJPayFaceRecogUtil tryPoptoTopHalfVC:[self.manager.homePageVC topVC]];
                }
                self.getTicketResponse = resultModel.getTicketResponse;
                [self submitFaceDataWithResponse:orderConfirmResponse
                               getTicketResponse:resultModel.getTicketResponse
                                         sdkData:resultModel.faceDataStr];
                break;
            case CJPayFaceRecogResultTypeFail:
                [self failRecogFace];
                break;
            case CJPayFaceRecogResultTypeCancel:
                [self failRecogFace];
                break;
            default:
                [self failRecogFace];
                break;
        }
    };
    [CJKeyboard prohibitKeyboardShow];
    [[CJPayFaceRecogManager sharedInstance] startFaceRecogWithConfigModel:faceRecogConfigModel];
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

- (void)event:(NSString *)event params:(NSDictionary *)params {
    NSMutableDictionary *trackParamDic = [NSMutableDictionary new];
    if (params) {
        [trackParamDic addEntriesFromDictionary:params];
    }
    NSString *aliveCheckStyleStr = [self.getTicketResponse getLiveRouteTrackStr];
    [trackParamDic cj_setObject:aliveCheckStyleStr forKey:@"alivecheck_style"];
    [super event:event params:trackParamDic];
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

- (void)failRecogFace {
    [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeRiskUserVerifyResult];
    // 增加0.5s的延时，避免人脸SDK回调太早，导致topVC错乱问题
    [CJKeyboard permitKeyboardShow];
    if (self.manager.isStandardDouPayProcess) {
        [CJKeyboard permitKeyboardShow];
        [self notifyVerifyCancel];
    } else {
        [self.manager sendEventTOVC:CJPayHomeVCEventUserCancelRiskVerify obj:@(CJPayVerifyTypeFaceRecog)];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [CJKeyboard delayPermitKeyboardShow:0.5];
            [self.manager sendEventTOVC:CJPayHomeVCEventDismissAllAboveVCs obj:@(0)];
        });
    }
}

- (CJPayBDCreateOrderResponse *)getCreateOrderResponse {
    return self.manager.response;
}

- (NSDictionary *)confirmRequestParasmWithResponse:(CJPayOrderConfirmResponse *)response
                                 getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse
                                           sdkData:(NSString *)sdkData {
    NSMutableDictionary *requestParams = [NSMutableDictionary new];
    NSString *scene = @"cj_live_check_no_src";
    if ([response.faceVerifyInfo.verifyType isEqualToString:@"1"]) {
        scene = @"cj_live_check";
    }
    if (Check_ValidString(self.manager.response.processInfo.processId)) {
        sdkData = [NSString stringWithFormat:@"%@%@", sdkData, self.manager.response.processInfo.processId];
    }
    NSDictionary *verifyParams = @{@"face_app_id": @"1792",
                                   @"face_scene" : scene,
                                   @"face_sdk_data" : CJString([CJPaySafeUtil encryptField:sdkData]),
                                   @"face_veri_ticket" : CJString(getTicketResponse.ticket)
    };
    [requestParams cj_setObject:verifyParams forKey:@"face_verify_params"];
    [requestParams cj_setObject:CJString(response.payFlowNo) forKey:@"pay_flow_no"];
    [requestParams cj_setObject:@"5" forKey:@"req_type"];
    [requestParams addEntriesFromDictionary:[self.manager loadSpecificTypeCacheData:CJPayVerifyTypeLast]]; // 获取上次的验证数据
    return [requestParams copy];
}

- (void)submitFaceDataWithResponse:(CJPayOrderConfirmResponse *)response
                 getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse
                           sdkData:(NSString *)sdkData {
    NSDictionary *requestParams = [self confirmRequestParasmWithResponse:response getTicketResponse:getTicketResponse sdkData:sdkData];
    // 延迟到下一个runloop，避免提交请求时的loading把现有的loading打断
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showLoading:YES];
    });
    [CJKeyboard prohibitKeyboardShow];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [CJKeyboard permitKeyboardShow];
        [self.manager submitConfimRequest:requestParams fromVerifyItem:self];
    });
}

- (NSString *)getSourceStr {
    return @"cashdesk_pay";
}

- (NSString *)checkTypeName {
    return @"人脸";
}

@end
