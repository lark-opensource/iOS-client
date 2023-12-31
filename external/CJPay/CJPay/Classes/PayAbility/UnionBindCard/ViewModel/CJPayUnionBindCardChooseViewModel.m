//
//  CJPayUnionBindCardChooseViewModel.m
//  Pods
//
//  Created by wangxiaohong on 2021/9/24.
//

#import "CJPayUnionBindCardChooseViewModel.h"

#import "CJPayMemAgreementModel.h"
#import "CJPayUnionBindCardChooseTableViewCell.h"
#import "CJPayUIMacro.h"
#import "CJPayUnionBindCardChooseView.h"
#import "CJPayMemberSendSMSRequest.h"
#import "CJPayStyleButton.h"
#import "CJPayMemberSignResponse.h"
#import "CJPaySafeUtil.h"
#import "CJPayUnionCardInfoModel.h"
#import "CJPayAlertUtil.h"
#import "CJPayUnionBindCardChooseListViewController.h"
#import "CJPayHalfSignCardVerifySMSViewController.h"
#import "CJPayUnionBindCardListRequest.h"
#import "CJPayUnionBindCardSignResponse.h"
#import "CJPayBindCardManager.h"
#import "CJPayUnionBindCardKeysDefine.h"

@implementation CJPayUnionBindCardChooseViewModel

+ (NSDictionary <NSString *, NSString *> *)keyMapperDict {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:@{
        @"signOrderNo" : CJPayBindCardShareDataKeySignOrderNo,
        @"specialMerchantId" : CJPayBindCardShareDataKeySpecialMerchantId,
        @"bindUnionCardType" : CJPayBindCardShareDataKeyBindUnionCardType,
        @"bankMobileNoMask" : CJPayBindCardShareDataKeyBankMobileNoMask,
        @"unionBindCardCommonModel" : CJPayBindCardShareDataKeyUnionBindCardCommonModel,
        @"cardListResponse" : CJPayUnionBindCardPageParamsKeyCardListResponse,
    }];
    
    [dict addEntriesFromDictionary:[super keyMapperDict]];
    
    return dict;
}


- (void)sendSMSWithCompletion:(void(^)(NSError *error, CJPaySendSMSResponse *response))completionBlock {
    @CJWeakify(self)
    [CJPayMemberSendSMSRequest startWithBDPaySendSMSBaseParam:[self p_buildBDPaySendSMSBaseParam]
                                                     bizParam:[self p_buildULSMSBizParam]
                                                   completion:^(NSError * _Nonnull error, CJPaySendSMSResponse * _Nonnull response) {
        
        @CJStrongify(self)
        if (completionBlock) {
            completionBlock(error, response);
        }
    }];
}

- (CJPayHalfSignCardVerifySMSViewController *)verifySMSViewControllerWithResponse:(CJPaySendSMSResponse *)response {
    UIViewController *vc = [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeHalfVerifySMS params:nil completion:nil];
    if (![vc isKindOfClass:CJPayHalfSignCardVerifySMSViewController.class]) {
        return nil;
    }
    CJPayHalfSignCardVerifySMSViewController *verifySMSVC = (CJPayHalfSignCardVerifySMSViewController *)vc;
    verifySMSVC.ulBaseReqquestParam = [self p_buildBDPaySendSMSBaseParam];
    verifySMSVC.sendSMSResponse = response;
    verifySMSVC.sendSMSBizParam = [self p_buildULSMSBizParam];
    if (!CJ_Pad) {
        [verifySMSVC useCloseBackBtn];
    }
    NSMutableString *phoneNoMaskStr = [self.bankMobileNoMask mutableCopy];
    if (self.bindUnionCardType == CJPayBindUnionCardTypeBindAndSign && Check_ValidString(response.mobileMask)) {
        // 云闪付场景时需要取 response 里的手机号
        phoneNoMaskStr = [response.mobileMask mutableCopy];
    }

    if (phoneNoMaskStr.length == 11) {
        [phoneNoMaskStr replaceCharactersInRange:NSMakeRange(3, 4) withString:@"****"];
    }
    CJPayVerifySMSHelpModel *helpModel = [CJPayVerifySMSHelpModel new];
    helpModel.cardNoMask = self.selectedUnionCardInfoModel.cardNoMask;
    helpModel.frontBankCodeName = self.selectedUnionCardInfoModel.bankName;
    helpModel.phoneNum = phoneNoMaskStr;

    verifySMSVC.helpModel = helpModel;
    verifySMSVC.animationType = HalfVCEntranceTypeFromBottom;
    [verifySMSVC showMask:YES];
    
    return verifySMSVC;
}

- (NSDictionary *)p_buildBDPaySendSMSBaseParam {
    NSMutableDictionary *baseParams = [NSMutableDictionary dictionary];
    [baseParams cj_setObject:self.merchantId forKey:@"merchant_id"];
    [baseParams cj_setObject:self.appId forKey:@"app_id"];
    return baseParams;
}

- (NSDictionary *)p_buildULSMSBizParam {
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    [bizContentParams cj_setObject:self.signOrderNo forKey:@"sign_order_no"];
    [bizContentParams cj_setObject:self.specialMerchantId forKey:@"smch_id"];

    NSMutableDictionary *encParams = [NSMutableDictionary dictionary];
    [encParams cj_setObject:[CJPaySafeUtil encryptField:CJString(self.selectedUnionCardInfoModel.cardNoMask)] forKey:@"card_no"];
    
//    [encParams cj_setObject:[CJPaySafeUtil encryptField:CJString(self.bindCardCommonModel.bankMobileNoMask)] forKey:@"mobile"];
    [bizContentParams cj_setObject:encParams forKey:@"enc_params"];
    
    return bizContentParams;
}

@end
