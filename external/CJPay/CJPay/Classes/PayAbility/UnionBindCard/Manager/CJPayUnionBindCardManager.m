//
//  CJPayUnionBindCardManager.m
//  Pods
//
//  Created by wangxiaohong on 2021/9/29.
//

#import "CJPayUnionBindCardManager.h"

#import "CJPayUnionBindCardChooseListViewController.h"
#import "CJPayUnionBindCardListRequest.h"
#import "CJPayUnionBindCardListResponse.h"
#import "CJPayVerifyItemBindCardRecogFace.h"
#import "CJPayUnionPaySignInfo.h"
#import "CJPayMemberFaceVerifyInfoModel.h"
#import "CJPayUnionBindCardAuthorizationRequest.h"
#import "CJPayUnionBindCardAuthorizationResponse.h"
#import "CJPayUnionBindCardHalfAccreditViewController.h"
#import "CJPayUnionCreateOrderRequest.h"
#import "CJPayMemCreateBizOrderResponse.h"
#import "CJPayBDButtonInfoHandler.h"
#import "CJPayQuickBindCardModel.h"
#import "CJPayBindCardVoucherInfo.h"
#import "CJPayDyTextPopUpViewController.h"
#import "CJPayBindCardManager.h"
#import "CJPayUnionBindCardKeysDefine.h"
#import "CJPayUnionBindCardPlugin.h"
#import "CJPayBindCardSharedDataModel.h"
#import "CJPayPasswordVerifyViewController.h"
#import "CJPayPassCodeSetBaseViewController.h"
#import "CJPayPasswordSetFirstStepViewController.h"
#import "CJPayFaceRecognitionProtocolViewController.h"
#import "CJPayToast.h"
#import "CJPayLoadingManager.h"

#import "CJPayRequestParam.h"
#import "CJPayBindCardFetchUrlRequest.h"
#import "CJPayBindCardFetchUrlResponse.h"
#import "CJPaySettingsManager.h"
#import "CJPayExceptionViewController.h"
#import "CJPaySignCardMap.h"

@interface CJPayUnionBindCardManager()<CJPayUnionBindCardPlugin>

@property (nonatomic, strong) CJPayVerifyItemBindCardRecogFace *recogFaceVerifyItem;
@property (nonatomic, strong) CJPayUnionBindCardCommonModel *unionBindCardModel;
@property (nonatomic, weak) CJPayBindCardSharedDataModel *bindCardCommonModel;

@end

@implementation CJPayUnionBindCardManager

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(shared), CJPayUnionBindCardPlugin);
});

#pragma mark - public method

+ (instancetype)shared {
    static CJPayUnionBindCardManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [CJPayUnionBindCardManager new];
        [manager p_init];
    });
    return manager;
}

- (void)bindCardWithCommonModel:(CJPayBindCardSharedDataModel *)bindCardCommonModel completionBlock:(nonnull void (^)(BOOL isOpenedSuccess, UIViewController *firstVC))completionBlock {
    [self p_unionBindCardWithCommonModel:bindCardCommonModel completionBlock:completionBlock];
}

- (void)openLiveDetectWithCompletion:(void (^)(BOOL))completion {
    NSDictionary *params = [self p_requestParams:self.bindCardCommonModel];
    @CJWeakify(self)
    [self.recogFaceVerifyItem startFaceRecogWithParams:params
                                        faceVerifyInfo:[self.bindCardCommonModel.unionBindCardCommonModel.unionPaySignInfo.faceVerifyInfoModel getFaceVerifyInfoModel]
                                            completion:^(BOOL isSuccess) {
        @CJStrongify(self)
        self.bindCardCommonModel.unionBindCardCommonModel.isAliveCheck = YES;
        CJ_CALL_BLOCK(completion, isSuccess);
    }];
}

- (void)openHalfAccreditWithCompletion:(void (^)(BOOL))completion {
    @CJWeakify(self);
    [self p_fetchUnionBindCardAuthWithCommonModel:self.bindCardCommonModel completionBlock:^(CJPayUnionBindCardHalfAccreditViewController *accreditVC) {
        @CJStrongify(self);
        if (accreditVC) {
            [accreditVC showMask:self.bindCardCommonModel.unionBindCardCommonModel.isShowMask];
        }

        CJ_CALL_BLOCK(completion, YES);
    }];
}

- (void)openChooseCardListWithCompletion:(void (^)(BOOL))completion {
    @CJWeakify(self);
    [self p_fetchChooseCardListWithCommonModel:self.bindCardCommonModel completionBlock:^(BOOL isSuccess, CJPayUnionBindCardChooseListViewController *listVC) {
        @CJStrongify(self);
        CJ_CALL_BLOCK(completion, isSuccess);
    } failBlock:^{
        @CJStrongify(self);
        [self p_handleOpenChooseCardListFailed];
        [[NSNotificationCenter defaultCenter] postNotificationName:CJPayUnionBindCardUnavailableNotification object:nil];
    }];
}

- (void)authAdditionalVerifyType:(NSString *)verifyType
                    loadingStart:(void (^)(void))loadingStartBlock
                loadingStopBlock:(void (^)(void))loadingStopBlock {
    // 进入活体检测或云闪付授权页
    self.bindCardCommonModel.unionBindCardCommonModel.isShowMask = YES;
    [[CJPayBindCardManager sharedInstance] modifySharedDataWithDict:@{CJPayBindCardShareDataKeyUnionBindCardCommonModel: [self.bindCardCommonModel.unionBindCardCommonModel toDictionary] ?: @{}}
                                                         completion:^(NSArray * _Nonnull modifyedKeysArray) {}];
    if ([verifyType isEqualToString:@"live_detection"]) {
        // 调起活体
        self.bindCardCommonModel.unionBindCardCommonModel.isAliveCheck = YES;
        @CJWeakify(self)
        self.recogFaceVerifyItem.loadingBlock = ^(BOOL isLoading) {
            @CJStrongify(self)
            if (isLoading) {
                CJ_CALL_BLOCK(loadingStartBlock);
            } else {
                CJ_CALL_BLOCK(loadingStopBlock);
            }
        };
        
        [[CJPayUnionBindCardManager shared] openLiveDetectWithCompletion:^(BOOL isSucceed) {
            @CJStrongify(self)
            if (isSucceed) {
                CJ_CALL_BLOCK(loadingStartBlock);
                [[CJPayUnionBindCardManager shared] openHalfAccreditWithCompletion:^(BOOL openSucceed) {
                    @CJStrongify(self)
                    CJ_CALL_BLOCK(loadingStopBlock);
                }];
            }
            else {
                [self.bindCardCommonModel.useNavVC popViewControllerAnimated:YES];
            }
        }];
    } else {
        CJ_CALL_BLOCK(loadingStartBlock);
        @CJWeakify(self)
        // 调起云闪付授权页
        [[CJPayUnionBindCardManager shared] openHalfAccreditWithCompletion:^(BOOL openSucceed) {
            @CJStrongify(self)
            CJ_CALL_BLOCK(loadingStopBlock);
        }];
    }
    
    [self p_trackWithEventName:@"wallet_addbcard_onestepbind_alivecheck"
                          params:@{@"is_alivecheck" : self.bindCardCommonModel.unionBindCardCommonModel.isAliveCheck ? @(1) : @(0)}];
}

- (void)createUnionOrderWithBindCardModel:(CJPayBindCardSharedDataModel *)commonModel fromVC:(nonnull UIViewController *)fromVC completionBlock:(nonnull void (^)(BOOL isOpenedSuccess, UIViewController *firstVC))completionBlock {
    // 传入参数: 普通绑卡订单号 和 是否同意授权
    
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionaryWithDictionary:@{
        @"is_agreed_authoration": commonModel.isCertification?@"1":@"0",
        @"app_id" : CJString(commonModel.appId),
        @"out_trade_no" : CJString(commonModel.signOrderNo),
        @"merchant_id" : CJString(commonModel.merchantId),
        @"biz_order_type" : @"verify_identity_info",
        @"source" : (commonModel.cardBindSource == CJPayCardBindSourceTypeIndependent) ? @"wallet_bcard_manage" : @"payment_manage",
    }];
    
    // 涉及支付场景传pay
    switch (commonModel.cardBindSource) {
        case CJPayCardBindSourceTypeBindAndPay:
        case CJPayCardBindSourceTypeQuickPay:
            [mutableParams addEntriesFromDictionary:@{@"trade_scene" : @"pay"}];
            break;
        case CJPayCardBindSourceTypeIndependent:
            [mutableParams addEntriesFromDictionary:@{@"trade_scene" : @""}];
            break;
        default:
            break;
    }
    
    if (commonModel.isBindUnionCardNeedLoading) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading];
    }
    @CJWeakify(self)
    [CJPayUnionCreateOrderRequest startWithBizParams:mutableParams completion:^(NSError * _Nonnull error, CJPayUnionCreateOrderResponse * _Nonnull response) {
        @CJStrongify(self)
        if (commonModel.isBindUnionCardNeedLoading) {
            [[CJPayLoadingManager defaultService] stopLoading];
        }
        // 根据返回的下一步页面决定跳转到哪里
        if (response.buttonInfo) {
            CJPayButtonInfoHandlerActionsModel *actionModel = [CJPayButtonInfoHandlerActionsModel new];
            [[CJPayBDButtonInfoHandler shareInstance] handleButtonInfo:response.buttonInfo fromVC:fromVC errorMsg:response.msg withActions:actionModel withAppID:self.bindCardCommonModel.appId merchantID:self.bindCardCommonModel.merchantId alertCompletion:^(UIViewController * _Nullable alertVC, BOOL handled) {
                CJ_CALL_BLOCK(completionBlock, NO, nil);
            }];
            return;
        }
        
        if (![response isSuccess]) {
            [CJToast toastText:response.msg ?: CJPayNoNetworkMessage inWindow:fromVC.cj_window];
            CJ_CALL_BLOCK(completionBlock, NO, nil);
            return;
        }
        
        if (!commonModel.unionBindCardCommonModel) {
            commonModel.unionBindCardCommonModel = [[CJPayUnionBindCardCommonModel alloc] init];
        }
        
        commonModel.unionBindCardCommonModel.unionIconUrl = response.unionIconUrl;
        commonModel.unionBindCardCommonModel.unionPaySignInfo = response.unionPaySignInfo;
        // 使用绑卡首页透传过来营销信息
        if (!Check_ValidString(response.unionPaySignInfo.voucherLabel) && Check_ValidString(commonModel.quickBindCardModel.unionBindCardVoucherInfo.voucherMsg)) {
            commonModel.unionBindCardCommonModel.unionPaySignInfo.voucherLabel = commonModel.quickBindCardModel.unionBindCardVoucherInfo.voucherMsg;
        }
        commonModel.unionBindCardCommonModel.isShowMask = YES;
        commonModel.signOrderNo = response.memberBizOrderNo;
        [self p_unionBindCardWithCommonModel:commonModel completionBlock:^(BOOL isOpened, UIViewController *firstVC) {
            CJ_CALL_BLOCK(completionBlock, isOpened, firstVC);
        }];
    }];
}

- (void)createPromotionOrder:(NSDictionary *)params {
    NSString *appId = [params cj_stringValueForKey:@"app_id" defaultValue:@""];
    NSString *merchantId = [params cj_stringValueForKey:@"merchant_id" defaultValue:@""];
    CJPayJHInformationConfig *jhConfig = [[CJPayBindCardManager sharedInstance] getJHConfig];
    NSString *abRequestCombineStr = [CJPayABTest getABTestValWithKey:CJPayABBindcardRequestCombine exposure:YES];
    NSMutableDictionary *abVersionDict = [NSMutableDictionary new];
    [abVersionDict cj_setObject:@"0" forKey:@"cjpay_silent_authorization_test"];
    NSDictionary *bizParam = @{
        @"aid": CJString([CJPayRequestParam gAppInfoConfig].appId),
        @"uid": @"",
        @"merchant_id": CJString(jhConfig.jhMerchantId),
        @"merchant_app_id": CJString(jhConfig.jhAppId),
        @"source": CJString(jhConfig.source),
        @"biz_order_type": @"card_sign",
        @"is_one_key_bind": @(YES),
        @"is_need_end_page_url": @(YES),
        @"is_need_bank_list" : [abRequestCombineStr isEqualToString:@"1"] ? @(YES) : @(NO),
        @"ab_version": [CJPayCommonUtil dictionaryToJson:abVersionDict],
    };
    
    if ([CJPayBindCardManager sharedInstance].stopLoadingBlock) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading vc:[UIViewController cj_topViewController]];
    }
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    [CJPayBindCardFetchUrlRequest startWithAppId:appId merchantId:merchantId bizParam:bizParam completion:^(NSError * _Nonnull error, CJPayBindCardFetchUrlResponse * _Nonnull response) {
        if ([CJPayBindCardManager sharedInstance].stopLoadingBlock) {
            CJ_CALL_BLOCK([CJPayBindCardManager sharedInstance].stopLoadingBlock);
        } else {
            [[CJPayLoadingManager defaultService] stopLoading];
        }
        
        if ([response.code hasPrefix:@"GW4009"]) {
            [[CJPayBindCardManager sharedInstance] gotoThrottleViewController:NO
                                                                       source:@"绑卡"
                                                                        appId:appId
                                                                   merchantId:merchantId];
            return;
        }
        
        if (![response isSuccess]) {
            [CJToast toastText:Check_ValidString(response.msg) ? response.msg : CJPayNoNetworkMessage inWindow:[UIViewController cj_topViewController].cj_window];
            return;
        }
        
        CJPayBindCardSharedDataModel *commonModel = [self p_buildCommonModelWithSignCardMap:response.signCardMap
                                                                           bizAuthInfoModel:response.bizAuthInfoModel
                                                                                      appId:appId
                                                                                 merchantId:merchantId];
        commonModel.startTimestamp = [date timeIntervalSince1970] * 1000;
        commonModel.endPageUrl = response.endPageUrl;
        commonModel.bankListResponse = response.bindPageInfoResponse;
        commonModel.isSyncUnionCard = YES;
        commonModel.bindUnionCardType = CJPayBindUnionCardTypeSyncBind;
        
        [[CJPayBindCardManager sharedInstance] bindCardWithCommonModel:commonModel];
    }];
}

- (CJPayBindCardSharedDataModel *)p_buildCommonModelWithSignCardMap:(CJPaySignCardMap *)signCardMap
                                                   bizAuthInfoModel:(CJPayBizAuthInfoModel *)bizAuthInfoModel
                                                              appId:(NSString *)appId
                                                         merchantId:(NSString *)merchantId {
    CJPayBindCardSharedDataModel *model = [CJPayBindCardSharedDataModel new];
    model.cardBindSource = CJPayCardBindSourceTypeIndependent;
    BOOL shouldUpdateMerchantId = [CJPaySettingsManager shared].currentSettings.bindCardUISettings.updateMerchantId;

    if (shouldUpdateMerchantId) {
        appId = signCardMap.appId;
        merchantId = signCardMap.merchantId;
    }
    model.appId = appId;
    model.merchantId = merchantId;

    model.skipPwd = signCardMap.skipPwd;
    model.signOrderNo = signCardMap.memberBizOrderNo;
    model.userInfo = [self p_generateUserInfo:signCardMap];
    model.bankMobileNoMask = signCardMap.mobileMask;
    model.referVC = [UIViewController cj_topViewController];
    
    model.memCreatOrderResponse = [CJPayMemCreateBizOrderResponse new];
    model.memCreatOrderResponse.memberBizOrderNo = signCardMap.memberBizOrderNo;
    model.memCreatOrderResponse.signCardMap = signCardMap;
    model.memCreatOrderResponse.bizAuthInfoModel = bizAuthInfoModel;
    
    model.bizAuthInfoModel = bizAuthInfoModel;
    model.bizAuthExperiment = [CJPayABTest getABTestValWithKey:CJPayABBizAuth exposure:NO];
    
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
                        [CJToast toastText:CJPayLocalizedStr(@"绑卡成功") duration:0.5 inWindow:[UIViewController cj_topViewController].cj_window];
                    }
                }
                break;
            case CJPayBindCardResultFail:
            case CJPayBindCardResultCancel:
                CJPayLogInfo(@"绑卡失败 code: %tu", cardResult.result);
                break;
        }
    };
    model.cjpay_referViewController = [UIViewController cj_topViewController];
    model.independentBindCardType = [self indepentdentBindCardType];
    
    return model;
}

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
- (void)p_init {
    [[CJPayBindCardManager sharedInstance] addPageTypeMaps:@{
            @(CJPayBindCardPageTypeUnionAccredit) : [CJPayUnionBindCardHalfAccreditViewController class],
            @(CJPayBindCardPageTypeUnionChooseCard) : [CJPayUnionBindCardChooseListViewController class],
    }];
}

- (void)p_unionBindCardWithCommonModel:(CJPayBindCardSharedDataModel *)commonModel completionBlock:(nonnull void (^)(BOOL isOpenedSuccess, UIViewController *firstVC))completionBlock {
    self.bindCardCommonModel = commonModel;
    self.unionBindCardModel = commonModel.unionBindCardCommonModel;
    @CJWeakify(self);
    void(^unionBindCardBlock)(void) = ^(){
        @CJStrongify(self);
        if (self.unionBindCardModel.unionPaySignInfo.isNeedAuthUnionPay) {
            if ([commonModel.useNavVC.topViewController isKindOfClass:CJPayPasswordVerifyViewController.class]) {
                if (commonModel.useNavVC.viewControllers.count == 1) {
                    //解决导航栈未完全pop完无法成功push的问题
                    [commonModel.useNavVC dismissViewControllerAnimated:YES completion:^{
                        @CJStrongify(self);
                        [self p_fetchUnionBindCardAuthWithCommonModel:commonModel completionBlock:^(CJPayUnionBindCardHalfAccreditViewController *accreditVC) {
                            @CJStrongify(self);
                            if (accreditVC) {
                                [accreditVC showMask:self.unionBindCardModel.isShowMask];
                            }
                            
                            CJ_CALL_BLOCK(completionBlock, YES, accreditVC);
                        }];
                    }];
                    return;
                } else {
                    [commonModel.useNavVC popViewControllerAnimated:YES];
                }
            }
            
            [self p_fetchUnionBindCardAuthWithCommonModel:commonModel completionBlock:^(CJPayUnionBindCardHalfAccreditViewController *accreditVC) {
                @CJStrongify(self);
                if (accreditVC) {
                    [accreditVC showMask:self.unionBindCardModel.isShowMask];
                }
                
                CJ_CALL_BLOCK(completionBlock, YES, accreditVC);
            }];
        } else {
            [self p_fetchChooseCardListWithCommonModel:commonModel completionBlock:^(BOOL isSuccess, CJPayUnionBindCardChooseListViewController *listVC) {
                @CJStrongify(self);
                CJ_CALL_BLOCK(completionBlock, isSuccess, listVC);
            } failBlock:^{
                @CJStrongify(self);
                [self p_handleOpenChooseCardListFailed];
                [[NSNotificationCenter defaultCenter] postNotificationName:CJPayUnionBindCardUnavailableNotification object:nil];
            }];
        }
    };
    
    NSString *actionPage = commonModel.unionBindCardCommonModel.unionPaySignInfo.actionPageType;
    if ([actionPage isEqualToString:@"identity_verify"]) {

        UIViewController *authVerifyVC = [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeQuickAuthVerify params:nil completion:^(BOOL isOpenedSuccessed, NSString * _Nonnull errMsg) {}];
        CJ_CALL_BLOCK(completionBlock, YES, authVerifyVC);
    } else if ([actionPage isEqualToString:@"face_verify"]) {
        @CJWeakify(self);
        commonModel.unionBindCardCommonModel.isAliveCheck = YES;
        [self openLiveDetectWithCompletion:^(BOOL isSuccess) {
            @CJStrongify(self);
            if (isSuccess) {
                CJ_CALL_BLOCK(unionBindCardBlock);
            } else {
                if ([self.bindCardCommonModel.useNavVC.topViewController isKindOfClass:CJPayFaceRecognitionProtocolViewController.class]) {
                    // 点击全屏同意刷脸协议页左上角返回时触发
                    [self.bindCardCommonModel.useNavVC popViewControllerAnimated:YES];
                }
            }
        }];
        [self p_trackWithEventName:@"wallet_addbcard_onestepbind_alivecheck"
                              params:@{@"is_alivecheck" : commonModel.unionBindCardCommonModel.isAliveCheck ? @(1) : @(0)}];
        CJ_CALL_BLOCK(completionBlock, YES, nil);
    } else if ([actionPage isEqualToString:@"password_verify"]) {
        CJPayPasswordVerifyViewController *passCodeVerifyVC = [self p_passWordVerification:commonModel completionBlock:unionBindCardBlock];
        CJ_CALL_BLOCK(completionBlock, YES, passCodeVerifyVC);
    } else if ([actionPage isEqualToString:@"union_pay_sign"] || [actionPage isEqualToString:@"union_pay_card_list"]) {
        [self p_trackWithEventName:@"wallet_addbcard_onestepbind_alivecheck"
                              params:@{@"is_alivecheck" : commonModel.unionBindCardCommonModel.isAliveCheck ? @(1) : @(0)}];
        CJ_CALL_BLOCK(unionBindCardBlock);
    } else {
        CJ_CALL_BLOCK(completionBlock, NO, nil);
        CJPayLogAssert(NO, @"云闪付跳转业务信息异常");
    }
}

- (CJPayPasswordVerifyViewController *)p_passWordVerification:(CJPayBindCardSharedDataModel *)commonModel completionBlock:(nonnull void (^)(void))completionBlock {
    CJPayPassCodeVerifyModel *model = [CJPayPassCodeVerifyModel new];
    model.appId = commonModel.appId;
    model.merchantId = commonModel.merchantId;
    model.smchId = commonModel.specialMerchantId;
    model.mobile = commonModel.userInfo.mobile;
    model.orderNo = commonModel.memCreatOrderResponse.memberBizOrderNo;
    model.userInfo = commonModel.userInfo;
    model.title = commonModel.title;
    model.subTitle = commonModel.subTitle;
    model.isQuickBindCard = NO;
    @CJWeakify(self)
    model.backBlock = ^{
        @CJStrongify(self)
        // 验密页点击返回后退出到本页面
        [commonModel.useNavVC popViewControllerAnimated:YES];
    };
    
    CJPayPasswordVerifyViewController* passCodeVerifyVC = [[CJPayPasswordVerifyViewController alloc] initWithVerifyModel:model completion:^(BOOL isSuccess, BOOL isCancel) {
        @CJStrongify(self)
        if (isCancel) {
            CJ_CALL_BLOCK(model.backBlock);
            return;
        }
        
        if (isSuccess) {
            CJ_CALL_BLOCK(completionBlock);
        }
    }];
    [[CJPayBindCardManager sharedInstance] pushVC:passCodeVerifyVC commonModel:commonModel];
    return passCodeVerifyVC;
}

- (NSDictionary *)p_requestParams:(CJPayBindCardSharedDataModel *)bindCardCommonModel {
    return @{
        @"app_id" : CJString(bindCardCommonModel.appId),
        @"merchant_id" : CJString(bindCardCommonModel.merchantId),
        @"member_biz_order_no" : CJString(bindCardCommonModel.signOrderNo),
        @"bind_card_source" : @"union_card_sign"
    };
}

- (void)p_handleOpenChooseCardListFailed {
    if (!self.bindCardCommonModel.quickBindCardModel || self.bindCardCommonModel.bindUnionCardSourceType == CJPayBindUnionCardSourceTypeLynxBindCardFirstPage) {
        [self p_closeUnionBindCardAndCallBack];
        return;
    }
    
    if (self.bindCardCommonModel.quickBindCardModel) {
        //无卡失败时，绑卡首页进来的停留在绑卡首页
        for (UIViewController *vc in self.bindCardCommonModel.useNavVC.viewControllers) {
            if ([vc isKindOfClass:NSClassFromString(@"CJPayBindCardFirstStepViewController")]) {
                [self.bindCardCommonModel.useNavVC popToViewController:vc animated:YES];
                break;
            }
        }
    } else {
        CJPayBindCardResultModel *resultModel = [CJPayBindCardResultModel new];
        resultModel.result = CJPayBindCardResultFail;
        CJ_CALL_BLOCK(self.bindCardCommonModel.completion, resultModel);
    }
}

- (void)p_closeUnionBindCardAndCallBack {
    if (self.bindCardCommonModel.useNavVC.presentingViewController) {
        @CJWeakify(self);
        [self.bindCardCommonModel.useNavVC.presentingViewController dismissViewControllerAnimated:YES completion:^{
            @CJStrongify(self);
            if (self.bindCardCommonModel.completion) {
                CJPayBindCardResultModel *resultModel = [CJPayBindCardResultModel new];
                resultModel.result = CJPayBindCardResultCancel;
                self.bindCardCommonModel.completion(resultModel);
            }
        }];
    } else {
        CJPayBindCardResultModel *resultModel = [CJPayBindCardResultModel new];
        resultModel.result = CJPayBindCardResultFail;
        CJ_CALL_BLOCK(self.bindCardCommonModel.completion, resultModel);
    }
}

- (void)p_fetchChooseCardListWithCommonModel:(CJPayBindCardSharedDataModel *)commonModel
                             completionBlock:(void (^)(BOOL isSuccess, CJPayUnionBindCardChooseListViewController *listVC))completionBlock
                                   failBlock:(void (^)(void))failBlock {
    @CJWeakify(self);
    [CJPayUnionBindCardListRequest startRequestWithParams:[self p_requestParams:commonModel] completion:^(NSError * _Nonnull error, CJPayUnionBindCardListResponse * _Nonnull response) {
        @CJStrongify(self);
        if (![response isSuccess]) {
            [CJToast toastText: response.msg ?: CJPayNoNetworkMessage inWindow:[UIViewController cj_topViewController].cj_window];
            CJ_CALL_BLOCK(completionBlock, NO, nil);
            return;
        }
        
        if ([response.hasBindableCard isEqualToString:@"1"]) {
            
            UIViewController *vc = [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeUnionChooseCard params:@{CJPayUnionBindCardPageParamsKeyCardListResponse : [response toDictionary]} completion:nil];
            if ([vc isKindOfClass:CJPayUnionBindCardChooseListViewController.class]) {
                CJPayUnionBindCardChooseListViewController *listVC = (CJPayUnionBindCardChooseListViewController *)vc;
                CJ_CALL_BLOCK(completionBlock, YES, listVC);
            }
        } else {
            [self p_trackWithEventName:@"wallet_ysf_auth_fail_pop" params:@{}];
            CJ_CALL_BLOCK(completionBlock, NO, nil);
            [[CJPayUnionBindCardManager shared] p_alertNoCardTipsWithCopywritingInfo:response.unionCopywritingInfo InVC:[UIViewController cj_topViewController] completion:^{
                @CJStrongify(self);
                [self p_trackWithEventName:@"wallet_ysf_auth_fail_click" params:@{}];
                CJ_CALL_BLOCK(failBlock);
            }];
        }
    }];
}

- (void)p_alertNoCardTipsWithCopywritingInfo:(CJPayUnionCopywritingInfo *)unionWritingInfo InVC:(UIViewController *)viewController completion:(void (^)(void))completionBlock {
    CJPayDyTextPopUpModel *model = [CJPayDyTextPopUpModel new];
    model.type = CJPayTextPopUpTypeDefault;
    model.title = unionWritingInfo.title;
    model.content = unionWritingInfo.displayDesc;
    model.contentAlignment = CJPayTextPopUpContentAlignmentTypeLeft;
    model.mainOperation = CJPayLocalizedStr(@"知道了");
    CJPayDyTextPopUpViewController *alertVC = [[CJPayDyTextPopUpViewController alloc] initWithPopUpModel:model];
    @CJWeakify(alertVC)
    model.didClickMainOperationBlock = ^{
        @CJStrongify(alertVC)
        [alertVC dismissSelfWithCompletionBlock:completionBlock];
    };
    [alertVC showOnTopVC:[UIViewController cj_topViewController]];
}

- (void)p_fetchUnionBindCardAuthWithCommonModel:(CJPayBindCardSharedDataModel *)commonModel completionBlock:(nonnull void (^)(CJPayUnionBindCardHalfAccreditViewController *))completionBlock {
    @CJWeakify(self)
    [CJPayUnionBindCardAuthorizationRequest startRequestWithParams:[self p_requestParams:commonModel] completion:^(NSError * _Nonnull error, CJPayUnionBindCardAuthorizationResponse * _Nonnull response) {
        @CJStrongify(self)
        if (![response isSuccess]) {
            [CJToast toastText:response.msg ?: CJPayNoNetworkMessage inWindow:[UIViewController cj_topViewController].cj_window];
            CJ_CALL_BLOCK(completionBlock, nil);
            return;
        }
        UIViewController *accreditVC = [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeUnionAccredit params:@{CJPayUnionBindCardPageParamsKeyAuthorizationResponse : [response toDictionary]} completion:nil];
        if ([accreditVC isKindOfClass:CJPayUnionBindCardHalfAccreditViewController.class]) {
            CJPayUnionBindCardHalfAccreditViewController *halfAccreditVC = (CJPayUnionBindCardHalfAccreditViewController *)accreditVC;
            CJ_CALL_BLOCK(completionBlock, halfAccreditVC);
        }
    }];
}

#pragma mark - getter

- (CJPayVerifyItemBindCardRecogFace *)recogFaceVerifyItem {
    if (!_recogFaceVerifyItem) {
        _recogFaceVerifyItem = [CJPayVerifyItemBindCardRecogFace new];
        _recogFaceVerifyItem.verifySource = @"云闪付";
    }
    return _recogFaceVerifyItem;
}

#pragma mark - tracker
    
- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *baseParams = [[[CJPayBindCardManager sharedInstance] bindCardTrackerBaseParams] mutableCopy];
    [baseParams addEntriesFromDictionary:params];
    
    [CJTracker event:eventName params:[baseParams copy]];
}

@end
