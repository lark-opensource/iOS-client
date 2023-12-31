//
//  CJPayHalfCardUpdateVerifySMSViewController.m
//  Pods
//
//  Created by wangxiaohong on 2020/4/12.
//

#import "CJPayHalfCardUpdateVerifySMSViewController.h"
#import "CJPayVerifyCodeTimerLabel.h"
#import "CJPayMemberSignRequest.h"
#import "CJPayMemberSignResponse.h"
#import "CJPayMemberSendSMSRequest.h"
#import "CJPayAlertUtil.h"
#import "CJPayBDButtonInfoHandler.h"
#import "CJPayCardUpdateModel.h"
#import "CJPayMetaSecManager.h"
#import "CJPayUIMacro.h"

@interface CJPayHalfCardUpdateVerifySMSViewController ()

@property (nonatomic, strong) CJPaySignSMSResponse *signResponse;
@property (nonatomic, strong) CJPayMemBankInfoModel *bankCardInfo;

@end

@implementation CJPayHalfCardUpdateVerifySMSViewController

- (void)gotoNextStep
{
    if (self.textInputFinished) {
        [self verifySMS];
    }
}

- (void)postSMSCode:(void (^)(CJPayBaseResponse * _Nonnull))success failure:(void (^)(CJPayBaseResponse * _Nonnull))failure
{
    self.timeView.enabled = NO;
    [CJPayMemberSendSMSRequest startWithBDPaySendSMSBaseParam:self.ulBaseReqquestParam
                                                 bizParam:self.sendSMSBizParam
                                                   completion:^(NSError * _Nonnull error, CJPaySendSMSResponse * _Nonnull response) {
        self.timeView.enabled = YES;
        if (response) {
            if ([response isSuccess]) {
                if (success) {
                    success(response);
                }
                self.sendSMSResponse = response;
            } else {
                // 单button alert
                NSString *msg = Check_ValidString(response.msg) ? response.msg : CJPayNoNetworkMessage;
                [CJPayAlertUtil customSingleAlertWithTitle:msg content:nil buttonDesc:CJPayLocalizedStr(@"我知道了") actionBlock:nil useVC:self];
            }
        } else {
            [CJToast toastText:CJPayNoNetworkMessage inWindow:self.cj_window];
        }
    }];
}

- (NSDictionary *)p_buildVerifyParams
{
    NSMutableDictionary *bizParams = [NSMutableDictionary dictionary];
    [bizParams cj_setObject:self.cardUpdateModel.cardSignInfo.signOrderNo forKey:@"sign_order_no"];
    [bizParams cj_setObject:self.cardUpdateModel.cardSignInfo.smchId forKey:@"smch_id"];
    NSMutableDictionary *encParams = [NSMutableDictionary dictionary];
    [encParams cj_setObject:CJString([self.smsInputView getText]) forKey:@"sms"];
    [bizParams cj_setObject:encParams forKey:@"enc_params"];
    [bizParams cj_setObject:CJString(self.sendSMSResponse.smsToken) forKey:@"sms_token"];
    return bizParams;
}

- (void)verifySMS
{
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading];
    [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeRiskUserVerifyResult];
    [CJPayMemberSignRequest startWithBDPayVerifySMSBaseParam:self.ulBaseReqquestParam
                                                bizParam:[self p_buildVerifyParams]
                                              completion:^(NSError * _Nonnull error, CJPaySignSMSResponse * _Nonnull response) {
        [[CJPayLoadingManager defaultService] stopLoading];
        if (response && [response isSuccess]) {
            self.signResponse = response;
            self.bankCardInfo = response.cardInfoModel;
            CJ_CALL_BLOCK(self.cardSignSuccessCompletion, response);
        } else {
            [CJKeyboard becomeFirstResponder:self.smsInputView];
            @CJWeakify(self)
            CJPayButtonInfoHandlerActionsModel *actionModel = [CJPayButtonInfoHandlerActionsModel new];

            actionModel.errorInPageAction = ^(NSString * _Nonnull errorText) {
                //处理返回红色字提示
                [weak_self updateErrorText:CJString(errorText)];
            };
            //buttoninfo 返回处理
            response.buttonInfo.code = response.code;
            [[CJPayBDButtonInfoHandler shareInstance] handleButtonInfo:response.buttonInfo
                                                              fromVC:self
                                                            errorMsg:response.msg
                                                         withActions:actionModel
                                                           withAppID:self.cardUpdateModel.appId
                                                          merchantID:self.cardUpdateModel.merchantId
                                                     alertCompletion:^(UIViewController * _Nullable alertVC, BOOL handled) {
                if (!handled) {
                    [weak_self close];
                }
            }];
        }
    }];
}

@end
