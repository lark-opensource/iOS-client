//
//  CJPayVerifyItemAdditionalSignCard.m
//  CJPaySandBox
//
//  Created by 王晓红 on 2023/7/26.
//

#import "CJPayVerifyItemAdditionalSignCard.h"

#import "CJPaySignCardInfo.h"
#import "CJPaySignCardPopUpViewController.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayStyleButton.h"
#import "CJPayCardSignRequest.h"
#import "CJPayCardSignResponse.h"
#import "CJPayHalfVerifySMSViewController.h"

@interface CJPayVerifyItemAdditionalSignCard() <CJPayTrackerProtocol>

@property (nonatomic, copy) NSString *inputContent;
@property (nonatomic, strong) CJPaySignCardPopUpViewController *signCardPopUpVC;

@end

@implementation CJPayVerifyItemAdditionalSignCard

- (BOOL)shouldHandleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    if ([response.code isEqual: @"CD005108"]) { // 需要补签约
        return YES;
    }
    return NO;
}

- (void)handleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    [self p_showSignCardTipsWithSignCardInfo:response.signCardInfo];
}

- (void)p_showSignCardTipsWithSignCardInfo:(CJPaySignCardInfo *)signCardInfo {
    CJPaySignCardPopUpViewController *signCardVC = [[CJPaySignCardPopUpViewController alloc] initWithSignCardInfoModel:signCardInfo];
    signCardVC.trackDelegate = self;
    signCardVC.bankNameTitle = self.manager.defaultConfig.title;
    @CJWeakify(self)
    signCardVC.confirmButtonClickBlock = ^(CJPayStyleButton * _Nonnull confirmButton) {
        @CJStrongify(self)
        [self p_signCardWithConfirmBtn:confirmButton];
    };
    @CJWeakify(signCardVC)
    signCardVC.closeButtonClickBlock = ^{
        @CJStrongify(signCardVC)
        @CJStrongify(self)
        [signCardVC dismissSelfWithCompletionBlock:^{
            [self notifyVerifyCancel];
        }];
    };
    [self.manager.homePageVC push:signCardVC animated:YES];
    self.signCardPopUpVC = signCardVC;
}

- (void)p_signCardWithConfirmBtn:(CJPayStyleButton *)confirmButton {
    [confirmButton startLoading];
    [CJPayCardSignRequest startWithAppId:self.manager.response.merchant.appId
                              merchantId:self.manager.response.merchant.merchantId
                              bankCardId:self.manager.defaultConfig.cjIdentify
                             processInfo:self.manager.response.processInfo
                              completion:^(NSError * _Nonnull error, CJPayCardSignResponse * _Nonnull response) {
        [confirmButton stopLoading];
        if (![response isSuccess]) {
            NSString *toastMsg = Check_ValidString(response.msg) ? CJString(response.msg) : CJPayNoNetworkMessage;
            [CJToast toastText:toastMsg inWindow:[UIViewController cj_topViewController].cj_window];
            return;
        }
        @CJWeakify(self);
        [self.signCardPopUpVC dismissSelfWithCompletionBlock:^{
            @CJStrongify(self);
            [self p_requestVerifyWithBDPayCardSignResponse:response];
        }];
    }];
}

- (void)p_requestVerifyWithBDPayCardSignResponse:(CJPayCardSignResponse *)cardSignResponse {
    CJPayVerifySMSHelpModel *model = [CJPayVerifySMSHelpModel new];
    model.cardNoMask = cardSignResponse.card.cardNoMask;
    model.frontBankCodeName = cardSignResponse.card.frontBankCodeName;
    model.phoneNum = cardSignResponse.card.mobileMask;
    
    CJPayHalfVerifySMSViewController *vc = [[CJPayHalfVerifySMSViewController alloc] initWithAnimationType:HalfVCEntranceTypeNone withBizType:CJPayVerifySMSBizTypeSign];
    vc.trackDelegate = self;
    vc.bankCardID = cardSignResponse.card.bankCardID;
    vc.agreements = [cardSignResponse getQuickAgreements];
    vc.defaultConfig = self.manager.defaultConfig;
    vc.orderResponse = self.manager.response;
    vc.helpModel = model;
    vc.needSendSMSWhenViewDidLoad = NO;
    vc.signSource = @"02"; // 提交支付触发补签约
    [vc showHelpInfo:YES];
    @CJWeakify(self)
    vc.closeActionCompletionBlock = ^(BOOL isSuccess) {
        @CJStrongify(self)
        [self notifyVerifyCancel];
    };
    vc.completeBlock = ^(BOOL success, NSString * _Nonnull content) {
        @CJStrongify(self)
        self.inputContent = content;
        [self p_verifySMS];
    };
    
    [self.manager.homePageVC push:vc animated:YES];
}

- (void)p_verifySMS {
    NSMutableDictionary *pwdDic = [NSMutableDictionary new];
    [pwdDic cj_setObject:self.inputContent forKey:@"sms"];
    [pwdDic cj_setObject:@"4" forKey:@"req_type"]; // 4表示补签约
    [self.manager submitConfimRequest:pwdDic fromVerifyItem:self];
}

- (void)event:(NSString *)event params:(NSDictionary *)params {
    [super event:event params:[params copy]];
}

@end
