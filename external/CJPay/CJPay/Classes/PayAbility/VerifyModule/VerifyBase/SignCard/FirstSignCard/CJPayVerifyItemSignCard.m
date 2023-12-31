//
//  CJPayVerifyItemSMS.m
//  CJPay
//
//  Created by 王新华 on 2019/6/27.
//

#import "CJPayVerifyItemSignCard.h"
#import "CJPayUIMacro.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayWebViewUtil.h"
#import "CJPayCardSignResponse.h"
#import "CJPayCardSignRequest.h"
#import "CJPayCardUpdateModel.h"
#import "CJPayQuickPayChannelModel.h"
#import "CJPayBaseVerifyManager+ButtonInfoHandler.h"
#import "CJPayHomeVCProtocol.h"
#import "CJPayEnumUtil.h"
#import "CJPayOrderConfirmResponse.h"

@interface CJPayVerifyItemSignCard()

@property (nonatomic, assign) BOOL isUpdatePhoneNumber; //是否走到更新卡信息流程

@end

@implementation CJPayVerifyItemSignCard

- (CJPayHalfVerifySMSViewController *)createVerifySMSVC {
    if (self.verifySMSVC && self.verifySMSVC.navigationController) {
        NSMutableArray *vcs = [self.verifySMSVC.navigationController.viewControllers mutableCopy];
        [vcs removeObjectIdenticalTo:self.verifySMSVC];
        self.verifySMSVC.navigationController.viewControllers = [vcs copy];
    }
    self.verifySMSVC = [[CJPayHalfVerifySMSViewController alloc] initWithAnimationType:HalfVCEntranceTypeNone withBizType:CJPayVerifySMSBizTypeSign];
    self.verifySMSVC.trackDelegate = self;
    self.verifySMSVC.signSource = @"01"; // 展示收银台触发补签约
    [self.verifySMSVC showHelpInfo:YES];
    @CJWeakify(self)
    self.verifySMSVC.closeActionCompletionBlock = ^(BOOL) {
        @CJStrongify(self)
        [self notifyVerifyCancel];
    };
    return self.verifySMSVC;
}

- (CJPayCardUpdateViewController *)createUpdateViewControllerWithResponse:(CJPayCardSignResponse *)response {
    CJPayCardUpdateModel *model = [[CJPayCardUpdateModel alloc] init];
    model.agreements = [response getQuickAgreements];
    model.cardModel = response.card;
    model.cardSignInfo = response.cardSignInfo;
    model.appId = self.manager.response.merchant.appId;
    model.merchantId = self.manager.response.merchant.merchantId;
    CJPayCardUpdateViewController *cardUpdateVC = [[CJPayCardUpdateViewController alloc] initWithCardUpdateModel:model];
    cardUpdateVC.trackDelegate = self;
    @CJWeakify(self)
    @CJWeakify(cardUpdateVC)
    cardUpdateVC.cjBackBlock = ^{
        @CJStrongify(cardUpdateVC)
        [cardUpdateVC closeWithCompletionBlock:^{
            @CJStrongify(self)
            [self notifyVerifyCancel];
        }];
    };
    cardUpdateVC.cardUpdateSuccessCompletion = ^(BOOL isSuccess) {
        if (isSuccess) {
            self.isUpdatePhoneNumber = YES;
            if (self.manager.isStandardDouPayProcess) {
                @CJStrongify(self)
                @CJStrongify(cardUpdateVC)
                [self p_closeCardUpdateVCWithVC:cardUpdateVC completion:^{
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        @CJStrongify(self)
                        [self.manager submitConfimRequest:[self.manager loadSpecificTypeCacheData:CJPayVerifyTypeLast] fromVerifyItem:self];
                    });
                }];
            } else {
                [self.manager sendEventTOVC:CJPayHomeVCEventDismissAllAboveVCs obj:@(0)];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.manager submitConfimRequest:[self.manager loadSpecificTypeCacheData:CJPayVerifyTypeLast] fromVerifyItem:self];
                });
            }
        }
    };
    
    return cardUpdateVC;
}

// 卡信息补充页上有短信验证页面，需要一起关掉
- (void)p_closeCardUpdateVCWithVC:(UIViewController *)vc
                       completion:(void(^)(void))completion {
    UINavigationController *navVC = vc.navigationController;
    if (navVC) {
        if (navVC.viewControllers.firstObject == vc) {
            [navVC.presentingViewController dismissViewControllerAnimated:YES
                                                               completion:^{
                CJ_CALL_BLOCK(completion);
            }];
        } else {
            NSInteger index = [navVC.viewControllers indexOfObject:vc];
            NSInteger underVCIndex = index  - 1;
            UIViewController *poptoVC = underVCIndex >= 0 ? [navVC.viewControllers cj_objectAtIndex:underVCIndex] : nil;
            if (poptoVC) {
                [CJPayCommonUtil cj_catransactionAction:^{
                    [navVC popToViewController:poptoVC animated:NO];
                } completion:^{
                    CJ_CALL_BLOCK(completion);
                }];
            } else {
                CJ_CALL_BLOCK(completion);
            }
        }
    } else {
        [vc.presentingViewController dismissViewControllerAnimated:YES
                                                        completion:^{
            CJ_CALL_BLOCK(completion);
        }];
    }
    
}

- (void)signCardFailed:(CJPayCardSignResponse *)response
{
    // 余额不足弹toast
    if (self.manager.isNotSufficient) {
        [CJToast toastText:CJString(response.msg) inWindow:self.cjpay_referViewController.cj_window];
    }
    [self notifyWakeVerifyItemFail];
}

- (void)p_signUp //补签约
{
    if (self.manager.signCardStartLoadingBlock) {
        CJ_CALL_BLOCK(self.manager.signCardStartLoadingBlock);
    } else {
        @CJStartLoading(self.manager.homePageVC)
    }
    [CJPayCardSignRequest startWithAppId:self.manager.response.merchant.appId
                              merchantId:self.manager.response.merchant.merchantId
                              bankCardId:self.manager.defaultConfig.cjIdentify
                             processInfo:self.manager.response.processInfo
                              completion:^(NSError * _Nonnull error, CJPayCardSignResponse * _Nonnull response) {
        if (self.manager.signCardStartLoadingBlock) {
            CJ_CALL_BLOCK(self.manager.signCardStopLoadingBlock);
        } else {        
            @CJStopLoading(self.manager.homePageVC)
        }
        if (!response) {
            [self signCardFailed:response];
            [self.manager sendEventTOVC:CJPayHomeVCEventSignCardFailed obj:@(0)];
            [CJToast toastText:CJPayNoNetworkMessage inWindow:[self.manager.homePageVC topVC].cj_window];
            return;
        }
        
        if ([response isSuccess]) {
            [self p_requestVerifyWithBDPayCardSignResponse:response];
        } else {
            if (response.buttonInfo) { // 补签约用户信息错误
                CJPayOrderConfirmResponse *confirmResponse = [CJPayOrderConfirmResponse new];
                confirmResponse.buttonInfo = response.buttonInfo;
                CJPayButtonInfoHandlerActionsModel *actionsModel = [self.manager commonButtonInfoModelWithResponse:confirmResponse];

                @CJWeakify(self)
                actionsModel.mobileUpdateAction = ^{
                    @CJStrongify(self)
                    CJPayLogInfo(@"跳转更新卡信息页面");
                    [self event:@"update_bank_pop_click" params:@{
                        @"button_name" : @"去更新"
                    }];
                    
                    [self.manager.homePageVC push:[self createUpdateViewControllerWithResponse:response] animated:YES];
                };
                
                actionsModel.closeAlertAction = ^{
                    @CJStrongify(self)
                    [self event:@"update_bank_pop_click" params:@{
                        @"button_name" : @"取消"
                    }];
                    [self notifyVerifyCancel];
                };
                actionsModel.alertPresentAction = ^{ // 复写 alertPresetAction
                    @CJStrongify(self)
                    [self event:@"update_bank_pop_imp" params:nil];
                };
                
                response.buttonInfo.code = response.code;
                [[CJPayBDButtonInfoHandler shareInstance] handleButtonInfo:response.buttonInfo
                                                                  fromVC:[self.manager.homePageVC topVC]
                                                                errorMsg:response.msg
                                                             withActions:actionsModel
                                                               withAppID:self.manager.response.merchant.appId
                                                              merchantID:self.manager.response.merchant.appId];
                return;
            }
            [self signCardFailed:response];
            [CJToast toastText:response.msg inWindow:[self.manager.homePageVC topVC].cj_window];
            [CJMonitor trackService:@"wallet_rd_verify_sign_failed" category:@{@"code":CJString(response.code), @"msg":CJString(response.msg)} extra:@{}];
        }
    }];
}

- (void)p_requestVerifyWithBDPayCardSignResponse:(CJPayCardSignResponse *)cardSignResponse {
    CJPayVerifySMSHelpModel *model = [CJPayVerifySMSHelpModel new];
    model.cardNoMask = cardSignResponse.card.cardNoMask;
    model.frontBankCodeName = cardSignResponse.card.frontBankCodeName;
    model.phoneNum = cardSignResponse.card.mobileMask;
    
    CJPayHalfVerifySMSViewController *vc = [self createVerifySMSVC];
    vc.bankCardID = cardSignResponse.card.bankCardID;
    vc.agreements = [cardSignResponse getQuickAgreements];
    vc.defaultConfig = self.manager.defaultConfig;
    vc.orderResponse = self.manager.response;
    vc.helpModel = model;
    vc.needSendSMSWhenViewDidLoad = NO;
    @CJWeakify(self)
//    [vc reset];
    vc.completeBlock = ^(BOOL success, NSString * _Nonnull content) {
        @CJStrongify(self)
        self.inputContent = content;
        [self p_verifySMS];
    };
    
    [self.manager.homePageVC push:vc animated:YES];
}

- (void)p_verifySMS {
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleHalfLoading];
    NSMutableDictionary *pwdDic = [NSMutableDictionary new];
    [pwdDic cj_setObject:self.payFlowNo forKey:@"pay_flow_no"];
    [pwdDic cj_setObject:self.inputContent forKey:@"sms"];
    [pwdDic cj_setObject:@"4" forKey:@"req_type"]; // 4表示补签约
    [pwdDic addEntriesFromDictionary:[self.manager loadSpecificTypeCacheData:CJPayVerifyTypeSignCard]]; // 获取上次的验证数据
    [self.manager submitConfimRequest:pwdDic fromVerifyItem:self];
}

- (void)requestVerifyWithCreateOrderResponse:(CJPayBDCreateOrderResponse *)response
                                       event:(nullable CJPayEvent *)event {
    [self p_signUp];
}

- (BOOL)shouldHandleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    if (self.manager.lastConfirmVerifyItem == self) {
        [self event:@"wallet_bank_signup_result" params:@{
            @"result" : response.cardSignSuccess ? @"1" : @"0",
            @"error_code" : CJString(response.code),
            @"error_message" : CJString(response.msg)
        }];
    }
    
    if ([CJPayBDButtonInfoHandler showErrorTips:response.buttonInfo]) {
        return YES;
    }
    
    [self.verifySMSVC clearInput];
    return NO;
}

- (void)handleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    if ([CJPayBDButtonInfoHandler showErrorTips:response.buttonInfo]) {
        [self.verifySMSVC updateTips:response.buttonInfo.page_desc];
    }
}

- (NSDictionary *)getLatestCacheData {
    return @{};
}

- (void)showState:(CJPayStateType)state {
    [self.verifySMSVC showState:state];
}

- (NSString *)checkTypeName {
    return @"补签约";
}

- (NSString *)checkType {
    return @"100";
}

@end
