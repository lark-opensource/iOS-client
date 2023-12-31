//
//  CJPayVerifyItemStandardForgetPwdRecogFace.m
//  CJPaySandBox
//
//  Created by shanghuaijun on 2023/6/7.
//

#import "CJPayVerifyItemStandardForgetPwdRecogFace.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayFaceRecogAlertContentView.h"
#import "CJPayGetTicketResponse.h"
#import "CJPayPopUpBaseViewController.h"
#import "CJPayLoadingManager.h"
#import "CJPayWebViewUtil.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayFaceRecognitionModel.h"
#import "CJPayFaceRecogAlertViewController.h"
#import "CJPayGetTicketResponse.h"
#import "CJPayFaceRecogUtil.h"
#import "CJPaySafeUtil.h"
#import "CJPayFaceRecogManager.h"
#import "CJPayFaceRecogConfigModel.h"
#import "CJPayFaceRecogResultModel.h"

@interface CJPayVerifyItemStandardForgetPwdRecogFace()

@property(nonatomic, assign) BOOL isOpenVerifyType;
@property(nonatomic, copy) NSString *verifyTypeStr;

@end

@implementation CJPayVerifyItemStandardForgetPwdRecogFace

- (BOOL)shouldHandleVerifyResponse:(CJPayOrderConfirmResponse *)response {
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
    return NO;//
}

- (void)requestVerifyWithCreateOrderResponse:(CJPayBDCreateOrderResponse *)response
                                       event:(nullable CJPayEvent *)event {
    // 覆写基类方法，屏蔽直接调用confirm逻辑
    [self handleEvent:event];
}

- (void)handleEvent:(CJPayEvent *)event {
    if ([event.name isEqualToString:CJPayVerifyEventRecommandVerifyKey] && [event.data isKindOfClass:CJPayOrderConfirmResponse.class]) {
        self.isOpenVerifyType = event.boolData;
        self.verifyTypeStr = event.stringData;
        self.verifySource = event.verifySource;
        [self tryFaceRecogWithResponse:event.data];
    }
}

- (void)tryFaceRecogWithResponse:(CJPayOrderConfirmResponse *)orderConfirmResponse {
    [CJKeyboard prohibitKeyboardShow];
    CJPayFaceRecogConfigModel *faceRecogConfigModel = [CJPayFaceRecogConfigModel new];
    faceRecogConfigModel.popStyle = CJPayFaceRecogPopStyleActivelyArouse;
    faceRecogConfigModel.shouldCallBackAfterClose = YES;
    faceRecogConfigModel.shouldSkipAlertPage = [self p_getShouldSkipAlertPageWithConfirmResponse:orderConfirmResponse];
    faceRecogConfigModel.shouldShowProtocolView = YES;
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
    faceRecogConfigModel.pagePushBlock = ^(CJPayBaseViewController * _Nonnull vc, BOOL animated) {
        @CJStrongify(self)
        [self pushWithVC:vc];
    };
    faceRecogConfigModel.getTicketLoadingBlock = ^(BOOL isLoading) {
        @CJStrongify(self)
        [self showLoading:isLoading];
    };
    faceRecogConfigModel.firstAlertConfirmBlock = ^() {
        NSString *faceRecogAlertPopUpViewKey = CJConcatStr(CJPayFaceRecogAlertPopUpViewKey, CJString(self.manager.response.userInfo.uid));
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:faceRecogAlertPopUpViewKey];
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

- (BOOL)p_getShouldSkipAlertPageWithConfirmResponse:(CJPayOrderConfirmResponse *)orderConfirmResponse {
    NSString *faceRecogAlertPopUpViewKey = CJConcatStr(CJPayFaceRecogAlertPopUpViewKey, CJString(self.manager.response.userInfo.uid));
    NSArray<NSString *> *skipConfirmPageSources = @[@"挽留弹窗-刷脸支付", @"忘记密码-刷脸支付", @"密码锁定-刷脸支付"];
    BOOL faceRecogAlertPopUpView = [[NSUserDefaults standardUserDefaults] boolForKey:faceRecogAlertPopUpViewKey];
    
    if (faceRecogAlertPopUpView || [skipConfirmPageSources containsObject:CJString(self.verifySource)] || orderConfirmResponse.faceVerifyInfo.skipCheckAgreement) {
        return YES;
    }
    return NO;
}

- (void)failRecogFace {
    [CJKeyboard permitKeyboardShow];
    [CJPayFaceRecogUtil tryPoptoTopHalfVC:[self.manager.homePageVC topVC]];
    [self notifyVerifyCancel];
}

- (void)showLoading:(BOOL)isLoading {
    if (isLoading) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading];
    } else {
        [[CJPayLoadingManager defaultService] stopLoading];
    }
}

- (void)pushWithVC:(UIViewController *)vc {
    UIViewController *topVC = [UIViewController cj_foundTopViewControllerFrom:[self.manager.homePageVC topVC]];
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

- (NSString *)getSourceStr {
    return @"cashdesk_pay";
}

- (void)submitFaceDataWithResponse:(CJPayOrderConfirmResponse *)response
                 getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse
                           sdkData:(NSString *)sdkData {
    NSDictionary *requestParams = [self confirmRequestParamsWithResponse:response
                                                       getTicketResponse:getTicketResponse
                                                                 sdkData:sdkData];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.manager.loadingDelegate) {
            @CJStartLoading(self.manager.loadingDelegate)
        } else {
            [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading];
        }
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [CJKeyboard permitKeyboardShow];
        [self.manager submitConfimRequest:requestParams fromVerifyItem:self];
    });
}

- (NSDictionary *)confirmRequestParamsWithResponse:(CJPayOrderConfirmResponse *)response
                                 getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse
                                           sdkData:(NSString *)sdkData {
    
    NSMutableDictionary *params = [NSMutableDictionary new];
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
    [params cj_setObject:verifyParams forKey:@"face_verify_params"];
    [params cj_setObject:CJString(response.payFlowNo) forKey:@"pay_flow_no"];
    [params addEntriesFromDictionary:[self.manager loadSpecificTypeCacheData:CJPayVerifyTypeLast]]; // 获取上次的验证数据
    [params cj_setObject:@"9" forKey:@"req_type"];
    [params cj_setObject:[self p_getFaceRecogScene] forKey:@"face_pay_scene"];
    if (Check_ValidString(self.verifyTypeStr)) {
        [params cj_setObject:@(self.isOpenVerifyType) forKey:self.verifyTypeStr];
    }
    return [params copy];
}

- (NSString *)p_getFaceRecogScene {
    NSDictionary *sceneMapDic = @{
        @"挽留弹窗-刷脸支付": @"retain_face_pay",
        @"忘记密码-刷脸支付": @"forget_pwd_face_pay",
        @"密码锁定-刷脸支付": @"pwd_lock_face_pay"
    };
    NSString *scene = [sceneMapDic cj_stringValueForKey:CJString(self.verifySource)];
    return  Check_ValidString(scene) ? scene: @"top_right_face_pay";
}

@end
