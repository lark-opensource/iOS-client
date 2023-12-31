//
//  CJPayForgetPwdOptController.m
//  Aweme
//
//  Created by 尚怀军 on 2022/12/3.
//

#import "CJPayForgetPwdOptController.h"
#import "CJPaySettingsManager.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPaySettings.h"
#import "CJPaySDKMacro.h"
#import "CJPayCommonUtil.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayWebViewUtil.h"
#import "CJPayFaceRecognitionModel.h"
#import "CJPayFaceRecogAlertViewController.h"
#import "CJPayDeskUtil.h"

@implementation CJPayForgetPwdOptController

// 忘记密码优化实验
- (void)forgetPwdWithSourceVC:(UIViewController *)sourceVC {
    if ([self isNeedFacePay]) {
        [self p_forgetPwdRecommendFacePay:sourceVC];
        return;
    }
    
    if ([self isNeedFaceVerify]) {
        [self p_forgetPwdRecommendFaceVerify:sourceVC];
        return;
    }
   
    [self p_oldGotoForgetPwdVCFromVC:sourceVC];
}

- (void)p_forgetPwdRecommendFacePay:(UIViewController *)sourceVC {
    CJPayFaceRecognitionModel *model = [CJPayFaceRecognitionModel new];
    model.title = CJPayLocalizedStr(@"若忘记抖音支付密码，可通过刷脸支付完成付款");
    model.buttonText = CJPayLocalizedStr(@"安全刷脸支付");
    model.bottomButtonText = CJPayLocalizedStr(@"重置密码");
    model.showStyle = CJPayFaceRecognitionStyleActivelyArouseInPayment;
    model.shouldShowProtocolView = NO;
    model.hideCloseButton = YES;
    model.iconUrl = [self p_getFaceIconUrl];

    CJPayFaceRecogAlertViewController *alertVC = [[CJPayFaceRecogAlertViewController alloc] initWithFaceRecognitionModel:model];
    
    @CJWeakify(self)
    alertVC.confirmBtnBlock = ^{
        @CJStrongify(self)
        CJ_CALL_BLOCK(self.faceRecogPayBlock, @"忘记密码-刷脸支付");
        CJ_CALL_BLOCK(self.trackerBlock, @"wallet_password_forget_keep_pop_click", @{
            @"title": CJString(model.title),
            @"button_name": @"安全刷脸支付"
        });
    };
    
    @CJWeakify(sourceVC)
    alertVC.bottomBtnBlock = ^{
        @CJStrongify(self)
        [self p_oldGotoForgetPwdVCFromVC:sourceVC];
        CJ_CALL_BLOCK(self.trackerBlock, @"wallet_password_forget_keep_pop_click", @{
            @"title": CJString(model.title),
            @"button_name": @"重置密码"
        });
    };
    
    CJ_CALL_BLOCK(self.trackerBlock, @"wallet_password_forget_keep_pop_show", @{
        @"title": CJString(model.title)
    });
    [alertVC showOnTopVC:[UIViewController cj_foundTopViewControllerFrom:sourceVC]];
}

- (void)p_forgetPwdRecommendFaceVerify:(UIViewController *)sourceVC {
    NSString *lynxSchema = [self p_getForgetPWDLynxSchemaWithTitle:CJPayLocalizedStr(@"若忘记抖音支付密码，可通过刷脸进行安全验证")];
    if (!Check_ValidString(lynxSchema)) {
        return;
    }
    
    [CJPayDeskUtil openLynxPageBySchema:lynxSchema
                          completionBlock:^(CJPayAPIBaseResponse * _Nonnull response) {}];
}

- (void)pwdLockRecommendFacePay:(UIViewController *)sourceVC
                          title:(NSString *)title {
    CJPayFaceRecognitionModel *model = [CJPayFaceRecognitionModel new];
    model.title = title;
    model.buttonText = CJPayLocalizedStr(@"安全刷脸支付");
    model.bottomButtonText = CJPayLocalizedStr(@"重置密码");
    model.showStyle = CJPayFaceRecognitionStyleActivelyArouseInPayment;
    model.shouldShowProtocolView = NO;
    model.hideCloseButton = YES;
    model.iconUrl = [self p_getFaceIconUrl];

    CJPayFaceRecogAlertViewController *alertVC = [[CJPayFaceRecogAlertViewController alloc] initWithFaceRecognitionModel:model];
    
    @CJWeakify(self)
    alertVC.confirmBtnBlock = ^{
        @CJStrongify(self)
        CJ_CALL_BLOCK(self.faceRecogPayBlock, @"密码锁定-刷脸支付");
        CJ_CALL_BLOCK(self.trackerBlock, @"wallet_alert_pop_click", @{
            @"title": CJString(model.title),
            @"button_name": @"安全刷脸支付"
        });
    };
    
    @CJWeakify(sourceVC)
    alertVC.bottomBtnBlock = ^{
        @CJStrongify(self)
        [self p_oldGotoForgetPwdVCFromVC:sourceVC];
        CJ_CALL_BLOCK(self.trackerBlock, @"wallet_alert_pop_click", @{
            @"title": CJString(model.title),
            @"button_name": @"重置密码"
        });
    };
    
    CJ_CALL_BLOCK(self.trackerBlock, @"wallet_alert_pop_imp", @{
        @"title": CJString(model.title)
    });
    [alertVC showOnTopVC:[UIViewController cj_foundTopViewControllerFrom:sourceVC]];
}

- (void)pwdLockRecommendFaceVerify:(UIViewController *)sourceVC
                             title:(NSString *)title {
    NSString *lynxSchema = [self p_getForgetPWDLynxSchemaWithTitle:title];
    if (!Check_ValidString(lynxSchema)) {
        return;
    }
    [CJPayDeskUtil openLynxPageBySchema:lynxSchema
                          completionBlock:^(CJPayAPIBaseResponse * _Nonnull response) {}];
}

- (void)p_oldGotoForgetPwdVCFromVC:(UIViewController *)sourceVC {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params cj_setObject:self.response.merchant.merchantId forKey:@"merchant_id"];
    [params cj_setObject:self.response.merchant.appId forKey:@"app_id"];
    CJPayMigrateH5PageToLynx *model = [CJPaySettingsManager shared].currentSettings.migrateH5PageToLynx;
    if (Check_ValidString(model.forgetpassSchema)) {
        [CJPayDeskUtil openLynxPageBySchema:[CJPayCommonUtil appendParamsToUrl:model.forgetpassSchema params:params]
                              completionBlock:^(CJPayAPIBaseResponse * _Nonnull response) {}];
        return;
    }
    
    [params cj_setObject:@"21" forKey:@"service"];
    NSString *url = [NSString stringWithFormat:@"%@/usercenter/setpass/guide",[CJPayBaseRequest bdpayH5DeskServerHostString]];
    [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:sourceVC
                                                  useNewNavi:YES
                                                       toUrl:url
                                                      params:params
                                           nativeStyleParams:@{}
                                               closeCallBack:^(id _Nonnull data) {}];
}

-(NSString *)p_getForgetPWDLynxSchemaWithTitle:(NSString *)title {
    NSString *schema = [self.response.forgetPwdInfo cj_stringValueForKey:@"schema"];
    if (!Check_ValidString(schema)) {
        return @"";
    }
    
    NSDictionary *params = @{
        @"forget_pass_modal_title" : CJString(title)
    };
    
    return [CJPayCommonUtil appendParamsToUrl:schema params:params];
}

- (BOOL)isNeedFacePay {
    NSString *forgetPwdAction = [self.response.forgetPwdInfo cj_stringValueForKey:@"action"];
    return [forgetPwdAction isEqualToString:@"forget_pwd_recommend_face_pay"];
}

- (BOOL)isNeedFaceVerify {
    NSString *forgetPwdAction = [self.response.forgetPwdInfo cj_stringValueForKey:@"action"];
    return [forgetPwdAction isEqualToString:@"forget_pwd_recommend_face_verify"];
}

- (NSString *)p_getFaceIconUrl {
    return  [self.response.forgetPwdInfo cj_stringValueForKey:@"icon_url"];
}

@end
