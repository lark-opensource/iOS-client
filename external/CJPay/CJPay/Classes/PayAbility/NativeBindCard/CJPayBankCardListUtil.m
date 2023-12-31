//
//  CJPayBankCardListUtil.m
//  Aweme
//
//  Created by chenbocheng.moon on 2022/11/22.
//

#import "CJPayBankCardListUtil.h"

#import "CJPayABTestManager.h"
#import "CJPayRequestParam.h"
#import "CJPayBindCardFetchUrlRequest.h"
#import "CJPayBindCardFetchUrlResponse.h"
#import "CJPayBaseListViewModel.h"
#import "CJPayBindCardSharedDataModel.h"
#import "CJPayBindCardManager.h"
#import "CJPaySignCardMap.h"
#import "CJPayMemCreateBizOrderResponse.h"
#import "CJPayUserInfo.h"
#import "CJPaySettings.h"
#import "CJPaySDKMacro.h"
#import "CJPayQuickBindCardViewModel.h"
#import "CJPayExceptionViewController.h"
#import "CJPaySettingsManager.h"
#import "CJPayBankCardModel.h"
#import "CJPayQuickBindCardModel.h"
#import "CJPayMemCreateBizOrderRequest.h"
#import "CJPayMemberSendSMSRequest.h"
#import "CJPayMemberSignResponse.h"
#import "CJPayHalfSignCardVerifySMSViewController.h"
#import "CJPayUIMacro.h"

@interface CJPayBankCardListUtil()

@property (nonatomic, copy) NSString *bizAuthExperiment;

@end

@implementation CJPayBankCardListUtil

+ (instancetype)shared {
    static CJPayBankCardListUtil *util;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        util = [CJPayBankCardListUtil new];
    });
    return util;
}

#pragma mark - public method

- (void)createNormalOrderWithViewModel:(CJPayBaseListViewModel *_Nullable)viewModel {
    self.bizAuthExperiment = [CJPayABTest getABTestValWithKey:CJPayABBizAuth];
    NSMutableDictionary *extDic = [NSMutableDictionary new];
    
    if ([viewModel isKindOfClass:[CJPayQuickBindCardViewModel class]]) {
        NSString *bankName = ((CJPayQuickBindCardViewModel *)viewModel).bindCardModel.bankName;
        [extDic cj_setObject:bankName forKey:@"bank_name"];
    }
    
    NSString *abRequestCombineStr = [CJPayABTest getABTestValWithKey:CJPayABBindcardRequestCombine exposure:YES];
    NSMutableDictionary *abVersionDict = [NSMutableDictionary new];
    [abVersionDict cj_setObject:CJString(self.bizAuthExperiment) forKey:@"cjpay_silent_authorization_test"];
    
    NSDictionary *params = @{
        @"biz_order_type" : @"card_sign",
        @"source" : @"wallet_bcard_manage",
        @"app_id" : CJString(self.appId),
        @"merchant_id" : CJString(self.merchantId),
        @"is_need_bank_list" : [abRequestCombineStr isEqualToString:@"1"] ? @(YES) : @(NO),
        @"exts": CJString([CJPayCommonUtil dictionaryToJson:extDic]),
        @"ab_version": [CJPayCommonUtil dictionaryToJson:abVersionDict]
    };
    
    if ([viewModel isKindOfClass:[CJPayQuickBindCardViewModel class]]) {
        [((CJPayQuickBindCardViewModel *)viewModel) startLoading];
    } else if (![CJPayBindCardManager sharedInstance].stopLoadingBlock) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading vc:self.vc];
    }
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    @CJWeakify(self)
    [self p_createNormalOrder:params completion:^(NSError * _Nonnull error, CJPayMemCreateBizOrderResponse * _Nonnull response) {
        @CJStrongify(self)
        if ([CJPayBindCardManager sharedInstance].stopLoadingBlock) {
            CJ_CALL_BLOCK([CJPayBindCardManager sharedInstance].stopLoadingBlock);
        } else if ([viewModel isKindOfClass:[CJPayQuickBindCardViewModel class]]) {
            [((CJPayQuickBindCardViewModel *)viewModel) stopLoading];
        } else {
            [[CJPayLoadingManager defaultService] stopLoading];
        }
        
        if ([response.code hasPrefix:@"GW4009"]) {
            [[CJPayBindCardManager sharedInstance] gotoThrottleViewController:NO
                                                                       source:@"绑卡"
                                                                        appId:self.appId
                                                                   merchantId:self.merchantId];
            return;
        }
        
        if (![response isSuccess]) {
            [CJToast toastText:Check_ValidString(response.msg) ? response.msg : CJPayNoNetworkMessage inWindow:self.vc.cj_window];
            return;
        }
        
        CJPayBindCardSharedDataModel *commonModel = [self p_buildCommonModelWithViewModel:viewModel signCardMap:response.signCardMap bizAuthInfoModel:response.bizAuthInfoModel];
        commonModel.startTimestamp = [date timeIntervalSince1970] * 1000;
        commonModel.bankListResponse = response.bindPageInfoResponse;
        commonModel.retainInfo = response.retainInfoModel;
        [[CJPayBindCardManager sharedInstance] bindCardWithCommonModel:commonModel];
    }];
}

- (void)p_createNormalOrder:(NSDictionary *)params completion:(void (^)(NSError * _Nonnull error, CJPayMemCreateBizOrderResponse * _Nonnull response))completion {
    @CJWeakify(self)
    [CJPayMemCreateBizOrderRequest startWithBizParams:params completion:^(NSError * _Nonnull error, CJPayMemCreateBizOrderResponse * _Nonnull response) {
        @CJStrongify(self)
        CJ_CALL_BLOCK(completion, error, response);
    }];
}

- (void)createPromotionOrderWithViewModel:(CJPayBaseListViewModel *_Nullable)viewModel {
    self.bizAuthExperiment = [CJPayABTest getABTestValWithKey:CJPayABBizAuth];
    CJPayJHInformationConfig *jhConfig = [[CJPayBindCardManager sharedInstance] getJHConfig];
    NSString *abRequestCombineStr = [CJPayABTest getABTestValWithKey:CJPayABBindcardRequestCombine exposure:YES];
    NSMutableDictionary *abVersionDict = [NSMutableDictionary new];
    [abVersionDict cj_setObject:CJString(self.bizAuthExperiment) forKey:@"cjpay_silent_authorization_test"];
    
    NSDictionary *bizParam = @{
        @"aid": CJString([CJPayRequestParam gAppInfoConfig].appId),
        @"uid": CJString(self.userId),
        @"merchant_id": CJString(jhConfig.jhMerchantId),
        @"merchant_app_id": CJString(jhConfig.jhAppId),
        @"source": CJString(jhConfig.source),
        @"biz_order_type": @"card_sign",
        @"is_one_key_bind": @(YES),
        @"is_need_end_page_url": @(YES),
        @"is_need_bank_list" : [abRequestCombineStr isEqualToString:@"1"] ? @(YES) : @(NO),
        @"ab_version": [CJPayCommonUtil dictionaryToJson:abVersionDict],
    };
    
    if ([viewModel isKindOfClass:[CJPayQuickBindCardViewModel class]]) {
        [((CJPayQuickBindCardViewModel *)viewModel) startLoading];
    } else if (![CJPayBindCardManager sharedInstance].stopLoadingBlock) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading vc:self.vc];
    }
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    [CJPayBindCardFetchUrlRequest startWithAppId:self.appId merchantId:self.merchantId bizParam:bizParam completion:^(NSError * _Nonnull error, CJPayBindCardFetchUrlResponse * _Nonnull response) {
        if ([CJPayBindCardManager sharedInstance].stopLoadingBlock) {
            CJ_CALL_BLOCK([CJPayBindCardManager sharedInstance].stopLoadingBlock);
        } else if ([viewModel isKindOfClass:[CJPayQuickBindCardViewModel class]]) {
            [((CJPayQuickBindCardViewModel *)viewModel) stopLoading];
        } else {
            [[CJPayLoadingManager defaultService] stopLoading];
        }
        
        if ([response.code hasPrefix:@"GW4009"]) {
            [[CJPayBindCardManager sharedInstance] gotoThrottleViewController:NO
                                                                       source:@"绑卡"
                                                                        appId:self.appId
                                                                   merchantId:self.merchantId];
            return;
        }
        
        if (![response isSuccess]) {
            [CJToast toastText:Check_ValidString(response.msg) ? response.msg : CJPayNoNetworkMessage inWindow:self.vc.cj_window];
            return;
        }
        
        CJPayBindCardSharedDataModel *commonModel = [self p_buildCommonModelWithViewModel:viewModel signCardMap:response.signCardMap bizAuthInfoModel:response.bizAuthInfoModel];
        commonModel.startTimestamp = [date timeIntervalSince1970] * 1000;
        commonModel.endPageUrl = response.endPageUrl;
        commonModel.bankListResponse = response.bindPageInfoResponse;
        
        if (self.isSyncUnionCard) {
            commonModel.isSyncUnionCard = YES;
        }
        
        if ([viewModel isKindOfClass:NSClassFromString(@"CJPaySyncUnionViewModel")]) {
            commonModel.bindUnionCardType = CJPayBindUnionCardTypeSyncBind;
        }
        
        [[CJPayBindCardManager sharedInstance] bindCardWithCommonModel:commonModel];
    }];
}

- (CJPayIndependentBindCardType)indepentdentBindCardType {
    NSString *bindCardExperiment = [CJPayABTest getABTestValWithKey:CJPayABBindcardPromotion];
    if ([bindCardExperiment isEqualToString:@"native"]) {
        return CJPayIndependentBindCardTypeNative;
    }
    
    if ([bindCardExperiment isEqualToString:@"lynx"]) {
        return CJPayIndependentBindCardTypeLynx;
    }
    
    return CJPayIndependentBindCardTypeDefault;
}

#pragma mark - private method

- (CJPayUserInfo *)p_generateUserInfo:(CJPaySignCardMap *)signCardMap {
    CJPayUserInfo *userInfo = [CJPayUserInfo new];
    userInfo.certificateType = signCardMap.idType;
    userInfo.mobile = signCardMap.mobileMask;
    userInfo.uidMobileMask = signCardMap.uidMobileMask;
    userInfo.authStatus = signCardMap.isAuthed;
    userInfo.pwdStatus = signCardMap.isSetPwd;
    userInfo.mName = signCardMap.idNameMask;
    return userInfo;
}

- (void)p_bindCardSuccessToast {
    [CJToast toastText:CJPayLocalizedStr(@"绑卡成功") duration:0.5 inWindow:self.vc.cj_window];
}

- (CJPayBindCardSharedDataModel *)p_buildCommonModelWithViewModel:(CJPayBaseListViewModel *)viewModel signCardMap:(CJPaySignCardMap *)signCardMap bizAuthInfoModel:(CJPayBizAuthInfoModel *)bizAuthInfoModel {
    
    CJPayBindCardSharedDataModel *model = [CJPayBindCardSharedDataModel new];
    model.cardBindSource = CJPayCardBindSourceTypeIndependent;
    BOOL shouldUpdateMerchantId = [CJPaySettingsManager shared].currentSettings.bindCardUISettings.updateMerchantId;

    if (shouldUpdateMerchantId) {
        self.appId = signCardMap.appId;
        self.merchantId = signCardMap.merchantId;
    }
    model.appId = self.appId;
    model.merchantId = self.merchantId;

    model.skipPwd = signCardMap.skipPwd;
    model.signOrderNo = signCardMap.memberBizOrderNo;
    model.userInfo = [self p_generateUserInfo:signCardMap];
    if ([viewModel isKindOfClass:[CJPayQuickBindCardViewModel class]]) {
        CJPayQuickBindCardViewModel *bindCardViewModel = (CJPayQuickBindCardViewModel *)viewModel;
        CJPayQuickBindCardModel *bindCardModel = bindCardViewModel.bindCardModel;
        model.isQuickBindCard = YES;
        model.quickBindCardModel = bindCardModel;
    }
    model.bankMobileNoMask = signCardMap.mobileMask;
    model.referVC = self.vc;
    
    model.memCreatOrderResponse = [CJPayMemCreateBizOrderResponse new];
    model.memCreatOrderResponse.memberBizOrderNo = signCardMap.memberBizOrderNo;
    model.memCreatOrderResponse.signCardMap = signCardMap;
    model.memCreatOrderResponse.bizAuthInfoModel = bizAuthInfoModel;
    
    model.bizAuthInfoModel = bizAuthInfoModel;
    model.bizAuthExperiment = self.bizAuthExperiment;
    model.displayDesc = self.displayDesc;
    model.displayIcon = self.displayIcon;
    
    @CJWeakify(self)
    @CJWeakify(model);
    model.completion = ^(CJPayBindCardResultModel * _Nonnull cardResult) {
        @CJStrongify(self)
        @CJStrongify(model);
        
        switch (cardResult.result) {
            case CJPayBindCardResultSuccess:
                if (model.isQuickBindCard || model.bindUnionCardType == CJPayBindUnionCardTypeSyncBind) {
                    if ([CJPayBindCardManager sharedInstance].bindCardSuccessBlock) {
                        CJ_CALL_BLOCK([CJPayBindCardManager sharedInstance].bindCardSuccessBlock);
                    } else {
                        [self p_bindCardSuccessToast];
                    }
                }
                break;
            case CJPayBindCardResultFail:
            case CJPayBindCardResultCancel:
                CJPayLogInfo(@"绑卡失败 code: %tu", cardResult.result);
                break;
        }
    };
    model.cjpay_referViewController = self.vc;
    model.independentBindCardType = [self indepentdentBindCardType];
    
    return model;
}

@end
