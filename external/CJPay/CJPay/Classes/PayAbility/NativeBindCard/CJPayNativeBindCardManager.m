//
//  CJPayNativeBindCardManager.m
//  Aweme
//
//  Created by 陈博成 on 2023/5/6.
//

#import "CJPayNativeBindCardManager.h"
#import "CJPayNativeBindCardPlugin.h"
#import "CJPayBindCardSharedDataModel.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayBizAuthInfoModel.h"
#import "CJPayWebViewUtil.h"
#import "CJPayCardAddLoginProvider.h"
#import "CJPayABTestManager.h"
#import "CJPayBindCardBackgroundInfo.h"
#import "CJPayExceptionViewController.h"
#import "CJPayToast.h"
#import "CJPayQuickBindCardManager.h"
#import "CJPayUnionBindCardPlugin.h"
#import "CJPayPasswordVerifyViewController.h"
#import "CJPayBindCardManager.h"
#import "UIViewController+CJTransition.h"
#import "CJPayCommonBindCardUtil.h"
#import "CJPayQuickBindCardModel.h"
#import "CJPayBindCardFirstStepViewController.h"
#import "CJPayBindCardFourElementsViewController.h"
#import "CJPayQuickBindCardViewController.h"
#import "CJPayQuickBindCardTypeChooseViewController.h"
#import "CJPayAuthVerifyViewController.h"
#import "CJPayBizAuthViewController.h"
#import "CJPayHalfSignCardVerifySMSViewController.h"
#import "CJPayPasswordSetFirstStepViewController.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayBankCardListUtil.h"
#import "CJPayMemCreateBizOrderRequest.h"
#import "CJPayMemCreateBizOrderResponse.h"
#import "CJPaySignCardMap.h"
#import "CJPayBankCardAddResponse.h"

@interface CJPayNativeBindCardManager()<CJPayNativeBindCardPlugin>

@property (nonatomic, strong) CJUniversalLoginManager *universalLoginManager;
@property (nonatomic, strong) CJPayBindCardSharedDataModel *bindCardCommonModel;
@property (nonatomic, strong) CJPayMemCreateBizOrderResponse *createBizOrderResponse;

@end

@implementation CJPayNativeBindCardManager

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(shared), CJPayNativeBindCardPlugin);
});

+ (instancetype)shared {
    static CJPayNativeBindCardManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [CJPayNativeBindCardManager new];
        [manager p_init];
    });
    return manager;
}

- (void)enterQuickBindCardWithCompletionBlock:(nonnull void (^)(BOOL isOpenedSuccess, UIViewController *firstVC))completionBlock {
    [[CJPayQuickBindCardManager shared] bindCardWithCommonModel:self.bindCardCommonModel
                                                completionBlock:completionBlock];
}

- (void)p_init {
    [[CJPayBindCardManager sharedInstance] addPageTypeMaps:@{
        @(CJPayBindCardPageTypeCommonQuickFrontFirstStep) : [CJPayBindCardFirstStepViewController class],
        @(CJPayBindCardPageTypeCommonFourElements) : [CJPayBindCardFourElementsViewController class],
        @(CJPayBindCardPageTypeQuickBindList) : [CJPayQuickBindCardViewController class],
        @(CJPayBindCardPageTypeQuickChooseCard) : [CJPayQuickBindCardTypeChooseViewController class]
    }];
}

#pragma mark - CJPayNativeBindCardPlugin

- (void)bindCardWithCommonModel:(CJPayBindCardSharedDataModel *)commonModel {
    self.bindCardCommonModel = commonModel;
    if (commonModel.cardBindSource == CJPayCardBindSourceTypeIndependent ||
        commonModel.cardBindSource == CJPayCardBindSourceTypeFrontIndependent) {
        [self p_startBindCardWithCommonModel:commonModel];
    } else {
        commonModel.bizAuthExperiment = [CJPayABTest getABTestValWithKey:CJPayABBizAuth];
        if (commonModel.cardBindSource == CJPayCardBindSourceTypeBalanceRecharge ||
            commonModel.cardBindSource == CJPayCardBindSourceTypeBalanceWithdraw) {
            commonModel.dismissProcessAnimated = YES;
        }
        @CJWeakify(self)
        [self p_fetchBindCardOrderInfo:commonModel completion:^(BOOL success, NSString * _Nullable failMsg) {
            @CJStrongify(self)
            CJPayBindCardDismissLoadingBlockType dismissLoadingBlock = commonModel.dismissLoadingBlock;
            CJ_CALL_BLOCK(dismissLoadingBlock);
            
            if (success) {
                // 绑卡下单成功
                [self p_startBindCardWithCommonModel:commonModel];
            } else {
                CJPayBindCardResultModel *resModel = [CJPayBindCardResultModel new];
                resModel.result = CJPayBindCardResultFail;
                resModel.failMsg = CJString(failMsg);
                CJ_CALL_BLOCK(commonModel.completion, resModel);
            }
        }];
    }
}

- (void)startOneKeySignOrderFromVC:(UIViewController *)fromVC
                    signOrderModel:(NSDictionary *)model
                         extParams:(NSDictionary *)extDict
         createSignOrderCompletion:(void (^)(CJPayCreateOneKeySignOrderResponse *))createSignOrderCompletion
                        completion:(void (^)(BOOL))completion {
    BDPayQuickBindCardSignOrderModel *signOrderModel = [[BDPayQuickBindCardSignOrderModel alloc] initWithDictionary:model error:nil];
    [[CJPayQuickBindCardManager shared] startOneKeySignOrderFromVC:fromVC
                                                    signOrderModel:signOrderModel
                                                         extParams:extDict
                                         createSignOrderCompletion:createSignOrderCompletion
                                                        completion:completion];
}

- (void)queryOneKeySignState {
    [[CJPayQuickBindCardManager shared] queryOneKeySignState];
}

- (void)bindCardHomePageFromJsbWithParam:(NSDictionary *)param {
    [CJPayBankCardListUtil shared].vc = [UIViewController cj_topViewController];
    [CJPayBankCardListUtil shared].appId = [param cj_stringValueForKey:@"app_id"];
    [CJPayBankCardListUtil shared].merchantId = [param cj_stringValueForKey:@"merchant_id"];
    [CJPayBankCardListUtil shared].isSyncUnionCard = YES;
    NSString *bindCardExperiment = [CJPayABTest getABTestValWithKey:CJPayABBindcardPromotion];
    if ([bindCardExperiment isEqualToString:@"native"]) {
        [[CJPayBankCardListUtil shared] createPromotionOrderWithViewModel:nil];
    } else {
        [[CJPayBankCardListUtil shared] createNormalOrderWithViewModel:nil];
    }
}

- (void)quickBindCardFromJsbWithParam:(NSDictionary *)param {
    [CJPayBankCardListUtil shared].vc = [UIViewController cj_topViewController];
    [CJPayBankCardListUtil shared].appId = [param cj_stringValueForKey:@"app_id"];
    [CJPayBankCardListUtil shared].merchantId = [param cj_stringValueForKey:@"merchant_id"];
    NSDictionary *pageInfo = [param cj_dictionaryValueForKey:@"page_info"];
    [CJPayBankCardListUtil shared].displayIcon = [pageInfo cj_stringValueForKey:@"display_icon"];
    [CJPayBankCardListUtil shared].displayDesc = [pageInfo cj_stringValueForKey:@"display_desc"];
    
    NSDictionary *cardInfo = [param cj_dictionaryValueForKey:@"card_info"];
    CJPayQuickBindCardViewModel *viewModel = [CJPayQuickBindCardViewModel new];
    CJPayQuickBindCardModel *cardModel = [CJPayQuickBindCardModel new];
    cardModel.bankName = [cardInfo cj_stringValueForKey:@"bank_name"];
    cardModel.bankCode = [cardInfo cj_stringValueForKey:@"bank_code"];
    cardModel.iconUrl = [cardInfo cj_stringValueForKey:@"icon_url"];
    cardModel.backgroundUrl = [cardInfo cj_stringValueForKey:@"icon_background"];
    cardModel.cardType = [cardInfo cj_stringValueForKey:@"card_type"];
    
    viewModel.bindCardModel = cardModel;
    [[CJPayBankCardListUtil shared] createNormalOrderWithViewModel:viewModel];
}

- (void)onlyBindCardWithCommonModel:(CJPayBindCardSharedDataModel *)commonModel params:(NSDictionary *)params completion:(BDPayBindCardCompletion)completion stopLoadingBlock:(void (^)(void))stopLoadingBlock {
    NSString *appId = [params cj_stringValueForKey:@"app_id"];
    NSString *merchantId = [params cj_stringValueForKey:@"merchant_id"];
    @CJWeakify(self);
    [self p_createBizOrderWithParams:params
                        commonModel:commonModel
                         completion:^{
        @CJStrongify(self);
        CJ_CALL_BLOCK(stopLoadingBlock);
        if ([self.createBizOrderResponse.code hasPrefix:@"GW4009"]) {
            [CJPayExceptionViewController gotoThrotterPageWithAppId:appId merchantId:merchantId fromVC:[UIViewController cj_topViewController] closeBlock:^{
                @CJStrongify(self)
                CJ_CALL_BLOCK(completion, CJPayBindCardResultCancel, @"绑卡取消");
            } source:@"绑卡"];
            return;
        }
        
        if (![self.createBizOrderResponse isSuccess]) {
            [CJToast toastText:Check_ValidString(self.createBizOrderResponse.msg) ? self.createBizOrderResponse.msg : CJPayNoNetworkMessage inWindow:[UIViewController cj_topViewController].cj_window];
            CJ_CALL_BLOCK(completion, CJPayBindCardResultFail, @"网络请求失败");
            return;
        }
        NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
        commonModel.startTimestamp = [date timeIntervalSince1970] * 1000;
        commonModel.skipPwd = self.createBizOrderResponse.signCardMap.skipPwd;
        commonModel.signOrderNo = self.createBizOrderResponse.memberBizOrderNo;
        commonModel.userInfo = [self.createBizOrderResponse generateUserInfo];
        commonModel.bankMobileNoMask = self.createBizOrderResponse.signCardMap.mobileMask;
        commonModel.memCreatOrderResponse = self.createBizOrderResponse;
        commonModel.retainInfo = self.createBizOrderResponse.retainInfoModel;
        commonModel.bizAuthInfoModel = self.createBizOrderResponse.bizAuthInfoModel;
        commonModel.bankListResponse = self.createBizOrderResponse.bindPageInfoResponse;
        commonModel.jumpQuickBindCard = self.createBizOrderResponse.signCardMap.jumpQuickBindCard;
        if ([commonModel.jumpQuickBindCard isEqualToString:@"1"]) {
            commonModel.quickBindCardModel = self.createBizOrderResponse.signCardMap.quickCardModel;
            commonModel.displayIcon = self.createBizOrderResponse.signCardMap.displayIcon;
            commonModel.displayDesc = self.createBizOrderResponse.signCardMap.displayDesc;
        }
        
        [self bindCardWithCommonModel:commonModel];
    }];
}

#pragma mark - private method

- (void)p_createBizOrderWithParams:(NSDictionary *)params
                      commonModel:(CJPayBindCardSharedDataModel *)commonModel
                       completion:(void (^)(void))completion {
    NSString *appId = [params cj_stringValueForKey:@"app_id"];
    NSString *merchantId = [params cj_stringValueForKey:@"merchant_id"];
    NSString *source = [params cj_stringValueForKey:@"source"];
    NSDictionary *extParams = @{
        @"bind_card_info": commonModel.bindCardInfo ?: @{}, // 透传参数
    };
    
    NSString *abRequestCombineStr = [CJPayABTest getABTestValWithKey:CJPayABBindcardRequestCombine exposure:YES];
    
    NSMutableDictionary *abVersionDict = [NSMutableDictionary new];
    if (Check_ValidString(commonModel.bizAuthExperiment)) {
        [abVersionDict cj_setObject:commonModel.bizAuthExperiment forKey:@"cjpay_silent_authorization_test"];
    }
    
    NSMutableDictionary *requestParams = [@{
        @"biz_order_type" : @"card_sign",
        @"source" : CJString(source),
        @"app_id" : CJString(appId),
        @"merchant_id" : CJString(merchantId),
        @"exts": CJString([CJPayCommonUtil dictionaryToJson:extParams]),
        @"is_need_bank_list" : [abRequestCombineStr isEqualToString:@"1"] ? @(YES) : @(NO)
    } mutableCopy];
    
    if (Check_ValidDictionary(abVersionDict)) {
        [requestParams addEntriesFromDictionary:@{@"ab_version":[CJPayCommonUtil dictionaryToJson:abVersionDict]}];
    }
    
    @CJWeakify(self)
    [CJPayMemCreateBizOrderRequest startWithBizParams:requestParams completion:^(NSError * _Nonnull error, CJPayMemCreateBizOrderResponse * _Nonnull response) {
        @CJStrongify(self)
        if (!self) {
            CJ_CALL_BLOCK(completion);
            return;
        }
        if (![response isSuccess]) {
            [CJMonitor trackServiceAllInOne:@"wallet_rd_create_biz_order_failure"
                                     metric:@{}
                                   category:@{@"code": CJString(response.code),
                                              @"msg": CJString(response.msg)}
                                      extra:@{}];
        }
        self.createBizOrderResponse = response;
        CJ_CALL_BLOCK(completion);
    }];
}

// 绑卡前先下单
- (void)p_fetchBindCardOrderInfo:(CJPayBindCardSharedDataModel *)bindCardCommonModel completion:(void(^)(BOOL success, NSString * _Nullable failMsg))completionBlock {
    NSString *abRequestCombineStr = [CJPayABTest getABTestValWithKey:CJPayABBindcardRequestCombine exposure:YES];
    NSDictionary *bizParams = @{
        @"app_id": CJString(bindCardCommonModel.appId),
        @"merchant_id": CJString(bindCardCommonModel.merchantId),
        @"process_info": [bindCardCommonModel.processInfo toDictionary] ?: @{},
        @"is_need_bank_list" : [abRequestCombineStr isEqualToString:@"1"] ? @(YES) : @(NO),
        @"exts": CJString(([CJPayCommonUtil dictionaryToJson:@{
            @"bind_card_info": bindCardCommonModel.bindCardInfo ?: @{},
            @"cjpay_silent_authorization_test": bindCardCommonModel.bindUnionCardType == CJPayBindUnionCardTypeBindAndSign ? @"0" : CJString(bindCardCommonModel.bizAuthExperiment),
        }
        ]))
    };
    
    CJPayCardAddLoginProvider *loginProvider = [[CJPayCardAddLoginProvider alloc] initWithBizParams:bizParams userInfo:bindCardCommonModel.userInfo];
    loginProvider.continueProgressWhenLoginSuccess = NO;
    
    loginProvider.referVC = [UIViewController cj_topViewController];
    loginProvider.eventBlock = ^(int event) {
        if (event == 0) {
            CJ_CALL_BLOCK(bindCardCommonModel.dismissLoadingBlock);
        } else if (event == 1) {
            // 不处理，只处理loading消失的情况
        }
    };

    self.universalLoginManager = [CJUniversalLoginManager bindManager:loginProvider];
    @CJWeakify(self);
    [self.universalLoginManager execLogin:^(CJUniversalLoginResultType type, CJPayUniversalLoginModel * _Nullable loginModel) {
        @CJStrongify(self);
        if (type == CJUniversalLoginResultTypeSuccess && !loginProvider.continueProgressWhenLoginSuccess) {
            [[NSNotificationCenter defaultCenter] postNotificationName:BDPayUniversalLoginSuccessNotification object:nil];
            CJ_CALL_BLOCK(completionBlock, NO, nil);
            return;
        }
        CJPayBankCardAddResponse *response = loginProvider.cardAddResponse;
        if (response && [response isSuccess]) {
            if (self) {
                bindCardCommonModel.bizAuthInfoModel = response.bizAuthInfoModel;
                bindCardCommonModel.bankListResponse = response.bindPageInfoResponse;
                bindCardCommonModel.firstStepBackgroundImageURL = CJString(response.backgroundInfo.backgroundImageUrl);
                
                [self p_syncDicInfoToCommonModel:bindCardCommonModel cardAddResponse:response];
                CJ_CALL_BLOCK(completionBlock, YES, nil);
            } else {
                CJ_CALL_BLOCK(completionBlock, NO, nil);
            }
        } else {
            [CJMonitor trackServiceAllInOne:@"wallet_rd_card_add_failure"
                                     metric:@{}
                                   category:@{@"code": CJString(response.code),
                                              @"msg": CJString(response.msg)}
                                      extra:@{}];
            if ([response.code hasPrefix:@"GW4009"]) {
                CJ_CALL_BLOCK(completionBlock, NO, nil);
                [CJPayExceptionViewController gotoThrotterPageWithAppId:bindCardCommonModel.appId
                                                             merchantId:bindCardCommonModel.merchantId
                                                                 fromVC:[UIViewController cj_topViewController]
                                                             closeBlock:^{}
                                                                 source:@"绑卡"];
            } else {
                NSString *msg = Check_ValidString(response.msg) ? response.msg : CJPayNoNetworkMessage;
                [CJToast toastText:msg inWindow:[UIViewController cj_topViewController].cj_window];
                CJ_CALL_BLOCK(completionBlock, NO, msg);
            }
        }
        self.universalLoginManager = nil;
    }];
}

- (void)p_startBindCardWithCommonModel:(CJPayBindCardSharedDataModel *)bindCardCommonModel {
    if (bindCardCommonModel.bizAuthInfoModel.isConflict) {
        NSString *conflictUrl = [CJPayCommonUtil appendParamsToUrl:bindCardCommonModel.bizAuthInfoModel.conflictActionURL
                                                         params:@{@"service" : @"122", @"source": @"sdk"}];
        
        [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:[UIViewController cj_topViewController] toUrl:conflictUrl params:@{} closeCallBack:^(id  _Nonnull data) {
            if (data && [data isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dic = (NSDictionary *)data;
                NSString *service = [dic cj_stringValueForKey:@"service"];
                if ([service isEqualToString:@"122"]) {
                    [CJMonitor trackService:@"wallet_rd_bizauth_conflict_cancal" category:@{@"is_success": @"1"} extra:@{}];
                    [[NSNotificationCenter defaultCenter] postNotificationName:BDPayClosePayDeskNotification object:nil];
                } else if ([service isEqualToString:@"conflictCancel"] ) {
                    if (bindCardCommonModel.completion) {
                        CJPayBindCardResultModel *resultModel = [CJPayBindCardResultModel new];
                        resultModel.result = CJPayBindCardResultCancel;
                        bindCardCommonModel.completion(resultModel);
                    }
                    [CJMonitor trackService:@"wallet_rd_bizauth_conflict_cancal" category:@{@"is_success": @"0"} extra:@{}];
                } else {
                    CJPayLogInfo(@"无service回调");
                }
            }
        }];
        return;
    }
    if ([bindCardCommonModel.jumpQuickBindCard isEqualToString:@"1"]){
        bindCardCommonModel.isQuickBindCard = true;
        [[CJPayQuickBindCardManager shared] bindCardWithCommonModel:bindCardCommonModel completionBlock:^(BOOL isOpenedSuccess, UIViewController * _Nonnull firstVC) {}];
        return;
    }
    CJPayUserInfo *userInfo = bindCardCommonModel.userInfo;
    if ([userInfo.pwdStatus isEqualToString:@"1"] || [userInfo.pwdStatus isEqualToString:@"2"]) {
        [self p_verifyPwdAndBindCardWithCommonModel:bindCardCommonModel];
    } else {
        [self p_track:@"wallet_addbcard_ispswd_result" params:@{@"result": @(0)}];
        [self p_bindCardAndSetPwdWithCommonModel:bindCardCommonModel];
    }
}

- (void)p_syncDicInfoToCommonModel:(CJPayBindCardSharedDataModel *)bindCardCommonModel
                   cardAddResponse:(CJPayBankCardAddResponse *)response {
    NSDictionary *paramDic = response.ulRequestParams;
    NSDictionary *pwdPageInfo = response.verifyPwdCopywritingInfo;
    bindCardCommonModel.userInfo = [self p_generateUserInfoWithCommonModel:bindCardCommonModel cardAddResponse:response];
    bindCardCommonModel.bankMobileNoMask = [paramDic cj_stringValueForKey:@"mobile_mask"];
    bindCardCommonModel.specialMerchantId = [paramDic cj_stringValueForKey:@"smch_id"];
    bindCardCommonModel.signOrderNo = [paramDic cj_stringValueForKey:@"sign_order_no"];
    bindCardCommonModel.skipPwd = [paramDic cj_stringValueForKey:@"skip_pwd"];
    bindCardCommonModel.jumpQuickBindCard = [paramDic cj_stringValueForKey:@"jump_one_key_sign"];
    bindCardCommonModel.title = [pwdPageInfo cj_stringValueForKey:@"title"];
    bindCardCommonModel.subTitle = [pwdPageInfo cj_stringValueForKey:@"sub_title"];
    bindCardCommonModel.orderAmount = [paramDic cj_stringValueForKey:@"order_amount"];
    bindCardCommonModel.retainInfo = response.retainInfoModel;
    NSDictionary *cardCopywritingInfoDic = [CJPayCommonUtil jsonStringToDictionary:[paramDic cj_stringValueForKey:@"card_copywriting_info"]];
    bindCardCommonModel.jumpOneKeySignOptimizeExp = [paramDic cj_stringValueForKey:@"cjpay_ab_jump_one_key_sign_optimize"];

    bindCardCommonModel.quickBindCardModel = response.quickCardModel;
    bindCardCommonModel.displayIcon = [cardCopywritingInfoDic cj_stringValueForKey:@"display_icon"];
    bindCardCommonModel.displayDesc = [cardCopywritingInfoDic cj_stringValueForKey:@"display_desc"];
    
    
    bindCardCommonModel.orderInfo = [cardCopywritingInfoDic cj_stringValueForKey:@"order_display_desc"];
    bindCardCommonModel.iconURL = [cardCopywritingInfoDic cj_stringValueForKey:@"order_display_icon"];
    bindCardCommonModel.firstStepMainTitle = [cardCopywritingInfoDic cj_stringValueForKey:@"title"];
    
    if (Check_ValidString(response.unionPaySignInfoString)) {
        bindCardCommonModel.bindUnionCardType = CJPayBindUnionCardTypeBindAndSign;
    }
    
    CJPayUnionBindCardCommonModel *unionBindCardModel = [CJPayUnionBindCardCommonModel new];
    unionBindCardModel.unionPaySignInfo = response.unionPaySignInfo;
    
    bindCardCommonModel.unionBindCardCommonModel = unionBindCardModel;
}

- (CJPayUserInfo *)p_generateUserInfoWithCommonModel:(CJPayBindCardSharedDataModel *)bindCardModel cardAddResponse:(CJPayBankCardAddResponse *)response {
    NSDictionary *ulBaseParam = response.ulRequestParams;
    CJPayUserInfo *userInfo = [CJPayUserInfo new];
    NSString *isAuthStr = [ulBaseParam cj_stringValueForKey:@"is_authed"];
    NSString *isSetPwdStr = [ulBaseParam  cj_stringValueForKey:@"is_set_pwd"];
    userInfo.authStatus = isAuthStr && [isAuthStr isEqualToString:@"0"] ? @"0" : @"1";
    userInfo.needAuthGuide = response.userInfo.needAuthGuide;
    userInfo.pwdStatus = isSetPwdStr && [isSetPwdStr isEqualToString:@"0"] ? @"0" : @"1";
    userInfo.mName = [ulBaseParam cj_stringValueForKey:@"id_name_mask"];
    userInfo.mobile = [ulBaseParam cj_stringValueForKey:@"mobile_mask"];
    userInfo.uidMobileMask = [ulBaseParam cj_stringValueForKey:@"uid_mobile_mask"];
    userInfo.certificateType = [ulBaseParam cj_stringValueForKey:@"id_type"];
    return userInfo;
}

- (void)p_bindCardWithCommonModel:(CJPayBindCardSharedDataModel *)bindCardCommonModel {
    [[CJPayQuickBindCardManager shared] bindCardWithCommonModel:bindCardCommonModel completionBlock:^(BOOL isOpenedSuccess, UIViewController * _Nonnull firstVC) {
    }];
}

// 老用户验证密码并绑卡
- (void)p_verifyPwdAndBindCardWithCommonModel:(CJPayBindCardSharedDataModel *)bindCardCommonModel {
    if ([bindCardCommonModel.skipPwd isEqualToString:@"1"]) {
        [self p_track:@"wallet_addbcard_ispswd_result" params:@{@"result": @(0)}];
        
        if (bindCardCommonModel.isQuickBindCard) {
            // 支付管理直接一键绑卡，下发免密
            [self p_bindCardWithCommonModel:bindCardCommonModel];
        }  else if (bindCardCommonModel.bindUnionCardType == CJPayBindUnionCardTypeBindAndSign) {
            [self p_unionBindCardWithCommonModel:bindCardCommonModel];
        } else {
            // 普通绑卡入口下发免密
            UIViewController *firstStepVC = [self p_getFirstStepViewControllerWith:bindCardCommonModel];
            [[CJPayBindCardManager sharedInstance] pushVC:firstStepVC commonModel:bindCardCommonModel];
        }
    } else {
        [self p_track:@"wallet_addbcard_ispswd_result" params:@{@"result": @(1)}];
        CJPayPassCodeVerifyModel *model = [CJPayPassCodeVerifyModel new];
        model.appId = bindCardCommonModel.appId;
        model.merchantId = bindCardCommonModel.merchantId;
        model.smchId = bindCardCommonModel.specialMerchantId;
        model.mobile = bindCardCommonModel.userInfo.mobile;
        model.orderNo = bindCardCommonModel.signOrderNo;
        model.userInfo = bindCardCommonModel.userInfo;
        model.title = bindCardCommonModel.title;
        model.subTitle = bindCardCommonModel.subTitle;
        model.isQuickBindCard = bindCardCommonModel.isQuickBindCard;
        model.isUnionBindCard = bindCardCommonModel.bindUnionCardType == CJPayBindUnionCardTypeBindAndSign || bindCardCommonModel.bindUnionCardType == CJPayBindUnionCardTypeSyncBind;
        @CJWeakify(self);
        model.backBlock = ^{
            @CJStrongify(self);
            [[CJPayBindCardManager sharedInstance] cancelBindCard];
        };
        if (bindCardCommonModel.cardBindSource == CJPayCardBindSourceTypeIndependent) {
            model.isIndependentBindCard = YES;
        }
        
        model.source = [[CJPayBindCardManager sharedInstance] bindCardTrackerSource];
        model.processInfo = bindCardCommonModel.processInfo;
        model.trackParams = bindCardCommonModel.trackerParams;
        CJPayPasswordVerifyViewController *verifyVC = [[CJPayPasswordVerifyViewController alloc] initWithVerifyModel:model completion:^(BOOL isSuccess, BOOL isCancel) {
            @CJStrongify(self)
            if (isCancel) {
                CJ_CALL_BLOCK(model.backBlock);
                return;
            }
            
            if (!isSuccess) {
                return;
            }
            
            if (bindCardCommonModel.bindUnionCardType == CJPayBindUnionCardTypeBindAndSign) {
                [self p_unionBindCardWithCommonModel:bindCardCommonModel];
                return;
            }
            
            UIViewController *firstStepVC;
            if (bindCardCommonModel.isQuickBindCard) {
                if (![bindCardCommonModel.userInfo.authStatus isEqualToString:@"0"]) {
                    [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeQuickChooseCard params:nil completion:nil];
                    return;
                }
                //未实名，需要走二要素实名流程
                firstStepVC = [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeQuickAuthVerify params:@{} completion:nil];
            } else  {
                firstStepVC = [self p_getFirstStepViewControllerWith:bindCardCommonModel];
            }
            
            UINavigationController *navi = bindCardCommonModel.useNavVC;
            if (navi) {
                [navi pushViewController:firstStepVC animated:YES];
            }
        }];

        verifyVC.cjAllowTransition = YES;
        [[CJPayBindCardManager sharedInstance] pushVC:verifyVC commonModel:bindCardCommonModel];
    }
}

- (void)p_unionBindCardWithCommonModel:(CJPayBindCardSharedDataModel *)bindCardCommonModel {
    if(CJ_OBJECT_WITH_PROTOCOL(CJPayUnionBindCardPlugin)) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayUnionBindCardPlugin) bindCardWithCommonModel:bindCardCommonModel completionBlock:^(BOOL isOpenedSuccess, UIViewController *firstVC) {
            CJ_CALL_BLOCK(bindCardCommonModel.dismissLoadingBlock);
        }];
    }
    else {
        [CJToast toastText:@"不支持云闪付绑卡" inWindow:[UIViewController cj_topViewController].cj_window];
        CJ_CALL_BLOCK(bindCardCommonModel.dismissLoadingBlock);
    }
}

// 新用户绑卡并设置密码
- (void)p_bindCardAndSetPwdWithCommonModel:(CJPayBindCardSharedDataModel *)bindCardCommonModel {
    if (bindCardCommonModel.isQuickBindCard) {
        [self p_bindCardWithCommonModel:bindCardCommonModel];
    } else if (bindCardCommonModel.bindUnionCardType == CJPayBindUnionCardTypeBindAndSign) {
        [self p_unionBindCardWithCommonModel:bindCardCommonModel];
    } else {
        UIViewController *firstStepVC = [self p_getFirstStepViewControllerWith:bindCardCommonModel];
        [[CJPayBindCardManager sharedInstance] pushVC:firstStepVC commonModel:bindCardCommonModel];
    }
}

- (BOOL)p_hasQuickBindCardInfo {
    // 银行不支持一键绑卡但是支持输入卡号进行绑卡（quickBindCardModel有值）
    if (!self.bindCardCommonModel.isQuickBindCard && self.bindCardCommonModel.quickBindCardModel) {
        return YES;
    }
    return NO;
}

- (UIViewController *)p_getFirstStepViewControllerWith:(CJPayBindCardSharedDataModel *)bindCardCommonModel {
    // 实验值往后传递，避免实验重复曝光
    NSDictionary *vcParams = @{};
    BOOL forceShowTopSafe = NO;
    if ([self p_hasQuickBindCardInfo]) {
        forceShowTopSafe = YES;
        vcParams = @{
            CJPayBindCardPageParamsKeyIsQuickBindCardListHidden : @(YES),
            CJPayBindCardPageParamsKeyIsFromQuickBindCard : @(YES),
            CJPayBindCardPageParamsKeyIsShowKeyboard : @(YES),
            CJPayBindCardPageParamsKeyFirstStepVCShowOrderView : @(YES),
            CJPayBindCardShareDataKeyJumpQuickBindCard : @(YES),
            CJPayBindCardPageParamsKeyPageFromCashierDesk : @(YES),
            CJPayBindCardPageParamsKeySelectedBankIcon : CJString(bindCardCommonModel.quickBindCardModel.iconUrl),
            CJPayBindCardPageParamsKeySelectedBankName : CJString(bindCardCommonModel.quickBindCardModel.bankName),
            CJPayBindCardPageParamsKeySelectedBankType : CJString(bindCardCommonModel.quickBindCardModel.selectedCardType)
        };
    }
    UIViewController *bdpayBindCardFirstStepVC = [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeCommonQuickFrontFirstStep
                                                         params:vcParams
                                                     completion:nil];
    if (forceShowTopSafe && [bdpayBindCardFirstStepVC isKindOfClass:CJPayBindCardFirstStepViewController.class]) {
        CJPayBindCardFirstStepViewController *vc = (CJPayBindCardFirstStepViewController *)bdpayBindCardFirstStepVC;
        vc.forceShowTopSafe = YES;
    }
    return bdpayBindCardFirstStepVC;
}

- (void)p_track:(NSString *)event params:(NSDictionary *)params {
    NSMutableDictionary *mutableTrackParams = [NSMutableDictionary new];
    [mutableTrackParams addEntriesFromDictionary:[[CJPayBindCardManager sharedInstance] bindCardTrackerBaseParams]];
    [mutableTrackParams addEntriesFromDictionary:params];
    [CJTracker event:event params:[mutableTrackParams copy]];
}

@end
