//
//  CJPayVerifyItemForgetPwdRecogFace.m
//  Pods
//
//  Created by wangxiaohong on 2021/8/3.
//

#import "CJPayVerifyItemForgetPwdRecogFace.h"

#import "CJPayBaseVerifyManager.h"
#import "CJPayFaceRecogAlertContentView.h"
#import "CJPayGetTicketResponse.h"
#import "CJPayPopUpBaseViewController.h"
#import "CJPayLoadingManager.h"
#import "CJPayWebViewUtil.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayFaceRecognitionModel.h"
#import "CJPayFaceRecogAlertViewController.h"
#import "CJPayFaceRecogUtil.h"

@interface CJPayVerifyItemForgetPwdRecogFace()
@property(nonatomic, assign) BOOL isOpenVerifyType;
@property(nonatomic, copy) NSString *verifyTypeStr;


@end

@implementation CJPayVerifyItemForgetPwdRecogFace

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self p_setupBlock];
    }
    return self;
}

- (BOOL)shouldHandleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    if (self.manager.lastConfirmVerifyItem == self) {
        [self event:@"wallet_alivecheck_result"
             params:@{@"result": [response isSuccess] ? @(1) : @(0),
                      @"alivecheck_type":[response.faceVerifyInfo.verifyType isEqualToString:@"1"] ? @(1) : @(0),
                      @"fail_before":@(0),
                      @"fail_code": CJString(response.code),
                      @"fail_reason": CJString(response.msg),
                      @"enter_from":@(self.enterFrom.intValue),
                      @"url": @"open_bytecert_sdk",
                      @"pop_type" : (Check_ValidString(response.faceVerifyInfo.iconUrl) ? @"1": @"0"),
                      @"alivecheck_scene": CJString(self.getTicketResponse.faceScene)}];
    }
    return NO;//
}

- (void)requestVerifyWithCreateOrderResponse:(CJPayBDCreateOrderResponse *)response
                                       event:(nullable CJPayEvent *)event {
    // 覆写基类方法，屏蔽直接调用confirm逻辑
}

- (void)receiveEvent:(CJPayEvent *)event {
    if ([event.name isEqualToString:CJPayVerifyEventRecommandVerifyKey] && [event.data isKindOfClass:CJPayOrderConfirmResponse.class]) {
        [self tryFaceRecogWithResponse:event.data];
        self.isOpenVerifyType = event.boolData;
        self.verifyTypeStr = event.stringData;
        self.verifySource = event.verifySource;
    }
}

- (void)failRecogFace {
    UIViewController *topVC = [self p_findTopHalfViewController];
    if (topVC) {
        [CJPayFaceRecogUtil tryPoptoTopHalfVC:topVC];
    }
    [CJKeyboard permitKeyboardShow];
}

- (void)alertNeedFaceRecogWith:(CJPayOrderConfirmResponse *)response getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse {
    NSString *faceRecogAlertPopUpViewKey = CJConcatStr(CJPayFaceRecogAlertPopUpViewKey, CJString(self.manager.response.userInfo.uid));
    NSArray<NSString *> *skipConfirmPageSources = @[@"挽留弹窗-刷脸支付", @"忘记密码-刷脸支付", @"密码锁定-刷脸支付"];
    BOOL faceRecogAlertPopUpView = [[NSUserDefaults standardUserDefaults] boolForKey:faceRecogAlertPopUpViewKey];
    if (faceRecogAlertPopUpView || [skipConfirmPageSources containsObject:CJString(self.verifySource)]) {
        self.enterFrom = @"2";
        [self startFaceRecogWith:response getTicketResponse:getTicketResponse];
    } else {
        [self p_showNewAlertVCWith:response getTicketResponse:getTicketResponse];
    }

}

- (void)p_showNewAlertVCWith:(CJPayOrderConfirmResponse *)response getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse {
    [self event:@"wallet_alivecheck_safetyassurace_imp" params:@{
        @"pop_type" : (Check_ValidString(response.faceVerifyInfo.iconUrl) ? @"1": @"0")
    }];
    // 主动刷脸是否跳过确认弹窗
    if (response.faceVerifyInfo.skipCheckAgreement) {
        [self startFaceRecogWith:response getTicketResponse:getTicketResponse];
        return;
    }
    CJPayFaceRecognitionModel *model = [CJPayFaceRecognitionModel new];
    model.agreementName = getTicketResponse.agreementDesc;
    model.agreementURL = getTicketResponse.agreementUrl;
    model.buttonText = response.faceVerifyInfo.buttonDesc;
    model.title = response.faceVerifyInfo.title;
    model.iconUrl = response.faceVerifyInfo.iconUrl;
    model.protocolCheckBox = getTicketResponse.protocolCheckBox;
    model.showStyle = CJPayFaceRecognitionStyleActivelyArouseInPayment;
    model.shouldShowProtocolView = YES;
    CJPayFaceRecogAlertViewController *alertVC = [[CJPayFaceRecogAlertViewController alloc] initWithFaceRecognitionModel:model];
    alertVC.contentView.trackDelegate = self;
    NSInteger hasSrcNum = [getTicketResponse.scene isEqualToString:@"cj_live_check"] ? 1 : 0;
    
    @CJWeakify(self)
    alertVC.closeBtnBlock = ^{
        @CJStrongify(self)
        [self failRecogFace];
        [self event:@"wallet_alivecheck_safetyassurace_click" params:@{
            @"button_type": @(0),
            @"alivecheck_scene": CJString(getTicketResponse.faceScene),
            @"alivecheck_type" : @(hasSrcNum),
            @"pop_type" : (Check_ValidString(response.faceVerifyInfo.iconUrl) ? @"1": @"0")
        }];
    };
    
    alertVC.confirmBtnBlock = ^{
        @CJStrongify(self)
        if (self) {
            self.enterFrom = @"2";
            NSString *faceRecogAlertPopUpViewKey = CJConcatStr(CJPayFaceRecogAlertPopUpViewKey, CJString(self.manager.response.userInfo.uid));
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:faceRecogAlertPopUpViewKey];
            [self startFaceRecogWith:response getTicketResponse:getTicketResponse];
        }
        [self event:@"wallet_alivecheck_safetyassurace_click" params:@{
            @"button_type": @(1),
            @"alivecheck_scene": CJString(getTicketResponse.faceScene),
            @"alivecheck_type" : @(hasSrcNum),
            @"pop_type" : (Check_ValidString(response.faceVerifyInfo.iconUrl) ? @"1": @"0")
        }];
    };
    
    [self p_dismissPopUpViewControllerWithCompletion:^{
        @CJStrongify(self);
        [alertVC showOnTopVC:[self.manager.homePageVC topVC]];
    }];
}

- (void)p_setupBlock {
    self.getTicketLoadingBlock = ^(BOOL isLoading) {
        if (isLoading) {
            [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading];
        } else {
            [[CJPayLoadingManager defaultService] stopLoading];
        }
    };
}

- (void)p_dismissPopUpViewControllerWithCompletion:(void (^)(void))completion {
    UIViewController *topVC = [UIViewController cj_topViewController];
    if ([topVC isKindOfClass:CJPayPopUpBaseViewController.class]) {
        [((CJPayPopUpBaseViewController *)topVC) dismissSelfWithCompletionBlock:^{
            CJ_CALL_BLOCK(completion);
        }];
    } else {
        CJ_CALL_BLOCK(completion);
    }
}


- (NSDictionary *)confirmRequestParasmWithResponse:(CJPayOrderConfirmResponse *)response getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse sdkData:(NSString *)sdkData {
    NSMutableDictionary *params = [[super confirmRequestParasmWithResponse:response getTicketResponse:getTicketResponse sdkData:sdkData] mutableCopy];
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

- (UIViewController *)p_findTopHalfViewController {
    NSArray *viewControllers = [self.manager.homePageVC topVC].navigationController.viewControllers;
    __block UIViewController *halfVC = nil;
    [viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:CJPayHalfPageBaseViewController.class]) {
            halfVC = obj;
            *stop = YES;
        }
    }];
    return halfVC;
}

@end
