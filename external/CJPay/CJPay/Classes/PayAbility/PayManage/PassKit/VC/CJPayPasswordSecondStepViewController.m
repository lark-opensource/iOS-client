//
//  CJPayPasswordSecondStepViewController.m
//  Pods
//
//  Created by wangxiaohong on 2021/1/5.
//

#import "CJPayPasswordSecondStepViewController.h"
#import "CJPayPasswordView.h"
#import "CJPayStyleErrorLabel.h"
#import "CJPaySafeKeyboard.h"
#import "CJPaySafeInputView.h"
#import "CJPayWebViewUtil.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPaySDKDefine.h"
#import "CJPayStyleButton.h"
#import "CJPayBDButtonInfoHandler.h"
#import "CJPaySafeUtil.h"
#import "CJPayPassKitSafeUtil.h"
#import "CJPaySettingPasswordRequest.h"
#import <TTReachability/TTReachability.h>
#import "CJPayFullPageBaseViewController+Biz.h"
#import "CJPayPasswordSetFirstStepViewController.h"
#import "CJPayMetaSecManager.h"
#import "CJPayBindCardManager.h"

@implementation CJPayPasswordSecondStepViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    @CJWeakify(self)
    self.passwordView.completeButtonTappedBlock = ^{
        @CJStrongify(self)
        [self p_completionButtonTapped];
    };
    
    [self updateWithPassCodeType:self.setModel.isSetAndPay ? CJPayPassCodeTypeSetAgainAndPay : CJPayPassCodeTypeSetAgain];

    self.setModel.backFirstStepCompletion = ^(NSString * _Nonnull errorText) {
        @CJStrongify(self);
        self.setModel.password = nil;
        [self clearInputContent];

        UIViewController *vc = [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageSetPWDFirstStep params:@{} completion:nil];
        
        if (![vc isKindOfClass:[CJPayPasswordSetFirstStepViewController class]]) {
            CJPayLogAssert(NO, @"vc类型异常%@", [vc cj_trackerName]);
            return;
        }
        
        CJPayPasswordSetFirstStepViewController *firstStepVC = (CJPayPasswordSetFirstStepViewController *)vc;
        
        firstStepVC.setModel = self.setModel;
        firstStepVC.completion = self.completion;
        firstStepVC.errorText = CJString(errorText);
    };
    
    [self trackerEventName:@"wallet_second_password_imp" params:@{}];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    @CJStopLoading([self getLoadingView])
}

- (void)p_completionButtonTapped {
    [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeRiskSetPayPWDRequest];
    [self trackerEventName:@"wallet_second_password_click" params:@{}];
     
    NSDictionary *params = @{
        @"app_id": CJString(self.setModel.appID),
        @"merchant_id": CJString(self.setModel.merchantID),
        @"smch_id": CJString(self.setModel.smchID),
        @"sign_order_no": CJString(self.setModel.signOrderNo),
        @"password": CJString([CJPaySafeUtil encryptPWD:self.setModel.password]),
        @"is_need_card_info": @(self.setModel.isNeedCardInfo)
    };
    
 
    @CJWeakify(self);
    @CJStartLoading([self getLoadingView])
    [CJPaySettingPasswordRequest startWithParams:params completion:^(NSError * _Nonnull error, CJPaySettingPasswordResponse * _Nonnull response) {
        @CJStrongify(self);
        @CJStopLoading([self getLoadingView])
        
        if (![response isSuccess]) {
            
            [CJMonitor trackService:@"wallet_rd_passkit_set_exception" extra:@{
                @"code": CJString(response.code),
                @"reason": CJString(response.msg)
            }];
            
            [self trackerEventName:@"wallet_second_password_error_info" params:@{
                @"url" : @"bytepay.member_product.set_password",
                @"fail_code" : [NSString stringWithFormat:@"%ld", (long)error.code],
                @"fail_reason": CJString(response.msg)
            }];
            
            [self clearInputContent];
            
            response.buttonInfo.code = response.code;
            @CJWeakify(self)
            [[CJPayBDButtonInfoHandler shareInstance] handleButtonInfo:response.buttonInfo
                                                              fromVC:self
                                                            errorMsg:response.msg
                                                         withActions:[self buttonInfoActions:response]
                                                           withAppID:self.setModel.appID
                                                          merchantID:self.setModel.merchantID
                                                     alertCompletion:^(UIViewController * _Nullable alertVC, BOOL handled) {
                @CJStrongify(self)
                
                [CJMonitor trackService:@"wallet_rd_passkit_set_password_break" extra:@{
                    @"code": CJString(response.code),
                    @"reason": CJString(response.msg)
                }];

                if ([response.code isEqualToString:@"MP020406"] ||
                    [response.code isEqualToString:@"MP020409"] ||
                    [response.code isEqualToString:@"MP020410"]) {
                    self.setModel.password = nil;
                    [self clearInputContent];
                    CJ_CALL_BLOCK(self.setModel.backFirstStepCompletion, CJString(response.msg));
                    return;
                }
                
                if (alertVC) {
                    self.setModel.password = nil;
                    [self clearInputContent];
                }
            }];
            
        }
        
        [CJMonitor trackService:@"wallet_rd_passkit_set_password" extra:@{
            @"result": [response isSuccess] ? @"1" : @"0",
            @"source": CJString(self.setModel.source)
        }];
        
        [self trackerEventName:@"wallet_second_password_check"
                              params:@{@"status": [response isSuccess] ? @"1" : @"0"}];
        
        if (self.completion) {
            self.setModel.bankCardInfo = response.bankCardInfo;
            self.completion(response.token, [response isSuccess], NO);
        }
    }];
}

- (void)inputView:(CJPaySafeInputView *)inputView completeInputWithCurrentInput:(NSString *)currentStr {
    
    [self trackerEventName:@"wallet_second_password_input" params:@{}];

    [self clearErrorText];
    if (![currentStr isEqualToString:self.setModel.password]) {
        CJ_CALL_BLOCK(self.setModel.backFirstStepCompletion, CJPayLocalizedStr(@"两次输入不一致"));
        return;
    }

    if ([[TTReachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
        [self showNoNetworkToast];
        [self clearInputContent];
        return;
    }
    
    if (self.setModel.isSetAndPay) {
        self.passwordView.completeButton.enabled = YES;
    } else {
        [self p_completionButtonTapped];
    }
    
}
@end
