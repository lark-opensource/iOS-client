//
//  CJPayQuickBindCardManager.m
//  Pods
//
//  Created by xutianxi on 2022/01/26.
//

#import "CJPayQuickBindCardManager.h"
#import "CJPayUserInfo.h"
#import "CJPayQuickBindCardModel.h"
#import "CJPayBindCardManager.h"
#import "CJPayMemCreateBizOrderRequest.h"
#import "CJPayMemVerifyBizOrderRequest.h"
#import "CJPayMemVerifyBizOrderResponse.h"
#import "CJPayMemCreateBizOrderResponse.h"
#import "CJPayBizAuthInfoModel.h"
#import "CJPayCreateOneKeySignOrderRequest.h"
#import "CJPayCreateOneKeySignOrderResponse.h"
#import "CJPayBDButtonInfoHandler.h"
#import "CJPayAuthVerifyViewController.h"
#import "CJPayMetaSecManager.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayRequestParam.h"
#import "CJPayPasswordVerifyViewController.h"
#import "CJPayMemGetOneKeySignBankUrlRequest.h"
#import "CJPayMemGetOneKeySignBankUrlResponse.h"
#import "CJPayNavigationController.h"
#import "CJPayVerifyItemBindCardRecogFace.h"
#import "CJPayFullPageBaseViewController.h"
#import "CJPayBizWebViewController.h"
#import "UIViewController+CJTransition.h"
#import "CJPayWebViewUtil.h"
#import "CJPayQuickBindCardKeysDefine.h"
#import "CJPayQueryOneKeySignRequest.h"
#import "CJPayQueryOneKeySignResponse.h"
#import "CJPaySignCardVerifySMSViewController.h"
#import "CJPayMemberSignResponse.h"
#import "CJPayPasswordSetFirstStepViewController.h"
#import "CJPayBindCardFirstStepViewController.h"
#import "CJPayCommonBindCardUtil.h"
#import "CJPayHandleErrorResponseModel.h"
#import "CJPayPrivacyMethodUtil.h"
#import "UIViewController+CJPay.h"
#import "CJPayPassKitSafeUtil.h"
#import "CJPaySafeUtil.h"
#import "CJPayWebviewStyle.h"

static NSString *const BDPayOneKeySignCardReturnURL = @"https://onekeysigncard";

@implementation BDPayQuickBindCardSignOrderModel

+ (NSDictionary <NSString *, NSString *> *)keyMapperDict {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:@{
        @"cardBindSource" : CJPayBindCardShareDataKeyCardBindSource,
        @"processInfo" : CJPayBindCardShareDataKeyProcessInfo,
        @"isQuickBindCard" : CJPayBindCardShareDataKeyIsQuickBindCard,
        @"quickBindCardModel" : CJPayBindCardShareDataKeyQuickBindCardModel,
        @"specialMerchantId" : CJPayBindCardShareDataKeySpecialMerchantId,
        @"userInfo" : CJPayBindCardShareDataKeyUserInfo,
        @"signOrderNo" : CJPayBindCardShareDataKeySignOrderNo,
        @"title" : CJPayBindCardShareDataKeyTitle,
        @"subTitle" : CJPayBindCardShareDataKeySubTitle,
        @"orderAmount" : CJPayBindCardShareDataKeyOrderAmount,
        @"frontIndependentBindCardSource" : CJPayBindCardShareDataKeyFrontIndependentBindCardSource,
        @"bindCardInfo" : CJPayBindCardShareDataKeyBindCardInfo,
        @"trackerParams" : CJPayBindCardShareDataKeyTrackerParams,
        @"selectedCardType" : CJPayQuickBindCardPageParamsKeySelectedCardType,
    }];
    
    [dict addEntriesFromDictionary:[super keyMapperDict]];
    
    return dict;
}

@end

@interface CJPayQuickBindCardManager()

@property (nonatomic, weak) CJPayBindCardSharedDataModel *bindCardCommonModel;
@property (nonatomic, weak) CJPayFullPageBaseViewController *signOrderFromVC;
@property (nonatomic, copy) void (^signOrderCompletion)(BOOL);
@property (nonatomic, copy) void (^createSignOrderCompletion)(CJPayCreateOneKeySignOrderResponse *);
@property (nonatomic, strong) BDPayQuickBindCardSignOrderModel *signOrderModel;
@property (nonatomic, strong) CJPayCreateOneKeySignOrderResponse *oneKeyCreateOrderResponse;
@property (nonatomic, strong) CJPayPasswordVerifyViewController *passCodeVerifyVC;
@property (nonatomic, strong) CJPayVerifyItemBindCardRecogFace *recogFaceVerifyItem;
@property (nonatomic, assign) NSTimeInterval startPollingTime;
@property (nonatomic, weak) CJPayPasswordSetFirstStepViewController *passCodeSetVC;
@property (nonatomic, assign) NSTimeInterval oneKeyBeginTimeInterval;
@property (nonatomic, assign) double enterBankH5PageTimestamp;
@property (nonatomic, copy) NSString *bankCardId;

@end

@implementation CJPayQuickBindCardManager

#pragma mark - public method

+ (instancetype)shared {
    static CJPayQuickBindCardManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [CJPayQuickBindCardManager new];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 监听工行小程序一键绑卡回跳结果的通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(microQuickBindCardSuccessWithNotify:) name:BDPayMircoQuickBindCardSuccessNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(microQuickBindCardFailWithNotify:) name:BDPayMircoQuickBindCardFailNotification object:nil];
    }
    return self;
}

- (void)bindCardWithCommonModel:(CJPayBindCardSharedDataModel *)commonModel
                completionBlock:(nonnull void (^)(BOOL isOpenedSuccess, UIViewController *firstVC))completionBlock {
    self.bindCardCommonModel = commonModel;
    
    if (![commonModel.userInfo.authStatus isEqualToString:@"0"]) {
        // 已实名直接进选卡页
        UIViewController *cardTypeChooseVC = [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeQuickChooseCard params:nil completion:nil];
        BOOL isOpenedPageSuccess = cardTypeChooseVC ? YES : NO;
        CJ_CALL_BLOCK(completionBlock, isOpenedPageSuccess, cardTypeChooseVC);
        return;
    }
    if ([[CJPayABTest getABTestValWithKey:CJPayABBindCardNotRealnameApi] isEqualToString:@"1"]) {
        UIViewController *openPageVC = nil;
        openPageVC = [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeQuickChooseCard params:@{}
        completion:^(BOOL isOpenedSuccessed, NSString *errMsg){}];
        
        BOOL isOpenedPageSuccess = openPageVC ? YES : NO;
        CJ_CALL_BLOCK(completionBlock, isOpenedPageSuccess, openPageVC);
        return;
    }
    
    NSDictionary *extsDic = @{
        @"bind_card_info": commonModel.bindCardInfo ?: @{},
        @"bank_name": CJString(commonModel.quickBindCardModel.bankName)
    };
    
    NSString *abRequestCombineStr = [CJPayABTest getABTestValWithKey:CJPayABBindcardRequestCombine exposure:YES];
    NSMutableDictionary *abVersionDict = [NSMutableDictionary new];
    
    // 未实名走下面的情况
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionaryWithDictionary:@{
        @"app_id" : CJString(commonModel.appId),
        @"merchant_id" : CJString(commonModel.merchantId),
        @"biz_order_type" : @"verify_identity_info",
        @"source" : (commonModel.cardBindSource == CJPayCardBindSourceTypeIndependent) ? @"wallet_bcard_manage" : @"payment_manage",
        @"exts": CJString([CJPayCommonUtil dictionaryToJson:extsDic]),
        @"is_need_bank_list" : [abRequestCombineStr isEqualToString:@"1"] ? @(YES) : @(NO),
        @"ab_version": [CJPayCommonUtil dictionaryToJson:abVersionDict]
    }];
    
    if (commonModel.isCertification) {
        [mutableParams cj_setObject:@"MY_BANKCARD" forKey: @"scene"];
    }
    
    // 未实名用户，在普通绑卡首页会展示授权页面，但是不调用鉴权接口。所以在普通绑卡进一键绑卡时需要主动掉一次鉴权接口，供后端记录一键绑卡流程的鉴权信息
    @CJWeakify(self)
    [CJPayMemCreateBizOrderRequest startWithBizParams:[mutableParams copy] completion:^(NSError * _Nonnull createBizOrderError, CJPayMemCreateBizOrderResponse * _Nonnull memCreatOrderResponse)  {
        @CJStrongify(self)
        if (![memCreatOrderResponse isSuccess]) {
            [CJToast toastText:memCreatOrderResponse.msg inWindow:[UIViewController cj_topViewController].cj_window];
            CJ_CALL_BLOCK(completionBlock, NO, nil);
            [CJMonitor trackServiceAllInOne:@"wallet_rd_create_biz_order_failure"
                                     metric:@{}
                                   category:@{@"code": CJString(memCreatOrderResponse.code),
                                              @"msg": CJString(memCreatOrderResponse.msg)}
                                      extra:@{}];
            return;
        }
        commonModel.memCreatOrderResponse = memCreatOrderResponse;
        commonModel.bankListResponse = memCreatOrderResponse.bindPageInfoResponse;
        if (commonModel.isCertification) {
            // 已经确认授权的话，静默走验证实名的接口
            if (!memCreatOrderResponse.bizAuthInfoModel.isAuthed) {
                [CJToast toastText:CJPayLocalizedStr(@"网络异常，请重试") inWindow:[UIViewController cj_topViewController].cj_window];
                CJ_CALL_BLOCK(completionBlock, NO, nil);
                return;
            }
            
            if (commonModel.bizAuthType == CJPayBizAuthTypeSilent && commonModel.bizAuthInfoModel.isNeedAuthorize) {
                // 静默实名授权不需要鉴权
                UIViewController *openPageVC = [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeQuickChooseCard params:@{CJPayQuickBindCardPageParamsKeyIsSilentAuthorize : @(YES)} completion:nil];
                BOOL isOpenedPageSuccess = openPageVC ? YES : NO;
                CJ_CALL_BLOCK(completionBlock, isOpenedPageSuccess, openPageVC);
                return;
            }
            
            [CJPayMemVerifyBizOrderRequest startWithBizParams:[self p_buildBDPayMemVerifyBizParamWith:commonModel] completion:^(NSError * _Nonnull error, CJPayMemVerifyBizOrderResponse * _Nonnull response) {
                @CJStrongify(self)
                NSMutableDictionary *trackDic = [[[CJPayBindCardManager sharedInstance] bindCardTrackerBaseParams] mutableCopy];
                
                [CJTracker event:@"wallet_businesstopay_auth_result" params:[trackDic cj_mergeDictionary:@{
                    @"result" : [response isSuccess] ? @"1" : @"0",
                    @"url" : @"bytepay.member_product.verify_identity_info",
                    @"error_code" : CJString(response.code),
                    @"error_message" : CJString(response.msg)
                }]];
                
                if (error) {
                    [CJToast toastText:CJString(response.msg) inWindow:[UIViewController cj_topViewController].cj_window];
                    CJ_CALL_BLOCK(completionBlock, NO, nil);
                    return;
                }
                if (![response isSuccess]) {
                    if (response.buttonInfo) {
                        
                        CJPayButtonInfoHandlerActionsModel *actionModel = [CJPayButtonInfoHandlerActionsModel new];
                        
                        actionModel.alertPresentAction = ^{
                            @CJStrongify(self)
                            [CJTracker event:@"wallet_businesstopay_auth_fail_imp" params:trackDic];
                            [self p_trackButtonInfoErrorPopWithCode:CJString(response.code) msg:CJString(response.buttonInfo.page_desc) isClick:NO];
                        };
                        
                        actionModel.closeAlertAction = ^{
                            @CJStrongify(self)
                            [self p_trackButtonInfoErrorPopWithCode:CJString(response.code) msg:CJString(response.buttonInfo.page_desc) isClick:YES];
                        };
                        
                        response.buttonInfo.code = response.code;
                        [[CJPayBDButtonInfoHandler shareInstance] handleButtonInfo:response.buttonInfo
                                                                          fromVC:[UIViewController cj_topViewController]
                                                                        errorMsg:response.msg
                                                                     withActions:actionModel
                                                                       withAppID:commonModel.appId
                                                                      merchantID:commonModel.merchantId];
                    } else {
                        [CJToast toastText:CJString(response.msg) inWindow:[UIViewController cj_topViewController].cj_window];
                    }
                    CJ_CALL_BLOCK(completionBlock, NO, nil);
                } else {
                    // 只有身份证会鉴权通过才进入到这里
                    UIViewController *openPageVC = [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeQuickChooseCard params:nil completion:nil];
                    BOOL isOpenedPageSuccess = openPageVC ? YES : NO;
                    CJ_CALL_BLOCK(completionBlock, isOpenedPageSuccess, openPageVC);
                }
            }];
        } else { //↓未实名授权
            UIViewController *openPageVC = nil;
            openPageVC = [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeQuickChooseCard params:@{}
            completion:^(BOOL isOpenedSuccessed, NSString *errMsg){}];
            
            BOOL isOpenedPageSuccess = openPageVC ? YES : NO;
            CJ_CALL_BLOCK(completionBlock, isOpenedPageSuccess, openPageVC);
        }
    }];
}

- (NSMutableDictionary *)p_buildBDPayMemVerifyBizParamWith:(CJPayBindCardSharedDataModel *)commonModel {
    NSMutableDictionary *bizParams = [NSMutableDictionary dictionary];
    CJPayBizAuthInfoModel *bizAuthInfoModel = commonModel.bizAuthInfoModel;
    
    [bizParams cj_setObject:CJString(commonModel.appId) forKey:@"app_id"];
    [bizParams cj_setObject:CJString(commonModel.merchantId) forKey:@"merchant_id"];
    [bizParams cj_setObject:CJString(bizAuthInfoModel.idNameMask) forKey:@"name"];
    [bizParams cj_setObject:CJString(bizAuthInfoModel.idType) forKey:@"identity_type"];
    [bizParams cj_setObject:CJString(bizAuthInfoModel.idCodeMask) forKey:@"identity_code"];
    [bizParams cj_setObject:CJString(commonModel.memCreatOrderResponse.memberBizOrderNo) forKey:@"member_biz_order_no"];
    return bizParams;
}

#pragma mark - 一键绑卡下单
- (void)startOneKeySignOrderFromVC:(UIViewController *)fromVC
                    signOrderModel:(BDPayQuickBindCardSignOrderModel *)model
                         extParams:(nonnull NSDictionary *)extDict
         createSignOrderCompletion:(void (^)(CJPayCreateOneKeySignOrderResponse *))createSignOrderCompletion
                        completion:(void (^)(BOOL))completion {
    self.oneKeyBeginTimeInterval = [extDict cj_doubleValueForKey:@"start_one_key_time"];
    self.signOrderModel = model;
    self.signOrderFromVC = (CJPayFullPageBaseViewController *)fromVC;
    self.signOrderCompletion = completion;
    self.createSignOrderCompletion = createSignOrderCompletion;
    
    [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeRiskFastSignRequest];

    NSString *aid = [CJPayRequestParam gAppInfoConfig].appId;
    __block NSString *appParamStr = @"";
    NSArray *bankParams = [CJPaySettingsManager shared].currentSettings.bankParamsArray;
    [bankParams enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[NSDictionary class]] && [[obj cj_stringValueForKey:@"aid"] isEqualToString:aid]) {
            appParamStr = [obj cj_stringValueForKey:@"appParam"];
            *stop = YES;
        }
    }];
    
    if(!Check_ValidString(appParamStr))
        appParamStr = [self.bankParamsDictionary cj_stringValueForKey:aid];
    
    NSDictionary *paramDict = @{@"appParam": CJString(appParamStr)};
    NSString *returnUrl = [NSString stringWithFormat:@"%@/cardbind/quickbind/notify?afterQuickbind=%@",BDPayOneKeySignCardReturnURL,[[paramDict cj_toStr] cj_base64EncodeString]];
    
    NSDictionary *extParams = @{@"bind_card_info": model.bindCardInfo ?: @{}};
    NSMutableDictionary *params = [@{
        @"app_id" : CJString(model.appId),
        @"merchant_id" : CJString(model.merchantId),
        @"card_type": CJString(model.selectedCardType),
        @"bank_code": CJString(model.quickBindCardModel.bankCode),
        @"return_url": CJString(returnUrl),
        @"source": CJString([self p_getPromotionSource]),
        @"out_trade_no": CJString(model.signOrderNo),
        @"exts": CJString([CJPayCommonUtil dictionaryToJson:extParams]),
        @"ab_version": CJString([CJPayABTest getABTestValWithKey:CJPayABBindcardFaceRecog exposure:NO]),
    } mutableCopy];
    
    if (self.bindCardCommonModel.bizAuthInfoModel.isNeedAuthorize && self.bindCardCommonModel.bizAuthType == CJPayBizAuthTypeSilent) {
        if (self.bindCardCommonModel.memCreatOrderResponse) {
            NSDictionary *identityVerifyInfo = @{
                @"member_biz_order_no": CJString(self.bindCardCommonModel.memCreatOrderResponse.memberBizOrderNo),
                @"identity_type": CJString(self.bindCardCommonModel.memCreatOrderResponse.bizAuthInfoModel.idType),
                @"identity_code": [CJPaySafeUtil encryptField:CJString(self.bindCardCommonModel.memCreatOrderResponse.bizAuthInfoModel.idCodeMask)],
                @"name": [CJPaySafeUtil encryptField:CJString(self.bindCardCommonModel.memCreatOrderResponse.bizAuthInfoModel.idNameMask)]
            };
            
            [params cj_setObject:identityVerifyInfo forKey:@"identity_verify_info"];
            [params cj_setObject:[CJPayPassKitSafeUtil pMemberSecureRequestParams:params] forKey:@"secure_request_params"];
        } else {
            NSDictionary *identityVerifyInfo = @{
                @"identity_type": CJString(self.bindCardCommonModel.bizAuthInfoModel.idType),
                @"identity_code": [CJPaySafeUtil encryptField:CJString(self.bindCardCommonModel.bizAuthInfoModel.idCodeMask)],
                @"name": [CJPaySafeUtil encryptField:CJString(self.bindCardCommonModel.bizAuthInfoModel.idNameMask)]
            };
            
            [params cj_setObject:identityVerifyInfo forKey:@"identity_verify_info"];
            [params cj_setObject:[CJPayPassKitSafeUtil pMemberSecureRequestParams:params] forKey:@"secure_request_params"];
        }
    }
    
    if (([extDict cj_stringValueForKey:@"name"] || [extDict cj_stringValueForKey:@"identity_code"])
        && [[CJPayABTest getABTestValWithKey:CJPayABBindCardNotRealnameApi] isEqualToString:@"1"]) {
        NSDictionary *identityVerifyInfo = @{
            @"member_biz_order_no": CJString(self.bindCardCommonModel.memCreatOrderResponse.memberBizOrderNo),
            @"identity_type": @"ID_CARD",
            @"identity_code": [CJPaySafeUtil encryptField:[extDict cj_stringValueForKey:@"identity_code"]],
            @"name": [CJPaySafeUtil encryptField:[extDict cj_stringValueForKey:@"name"]],
        };
        
        [params cj_setObject:identityVerifyInfo forKey:@"identity_verify_info"];
        [params cj_setObject:[CJPayPassKitSafeUtil pMemberSecureRequestParams:params] forKey:@"secure_request_params"];
    }
    
    // 涉及支付场景传pay
    switch (model.cardBindSource) {
        case CJPayCardBindSourceTypeBindAndPay:
        case CJPayCardBindSourceTypeQuickPay:
            [params addEntriesFromDictionary:@{@"trade_scene" : @"pay"}];
            break;
        case CJPayCardBindSourceTypeBalanceRecharge:
            [params addEntriesFromDictionary:@{@"trade_scene" : @"balance_recharge"}];
            break;
        case CJPayCardBindSourceTypeBalanceWithdraw:
            [params addEntriesFromDictionary:@{@"trade_scene" : @"balance_withdraw"}];
            break;
        default:
            break;
    }
    
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading title:CJPayLocalizedStr(@"跳转银行页面")];
    
    @CJWeakify(self)
    @CJWeakify(fromVC)
    [CJPayCreateOneKeySignOrderRequest startRequestWithParams:[params copy] completion:^(NSError * _Nonnull error, CJPayCreateOneKeySignOrderResponse * _Nonnull response) {
        @CJStrongify(self)
        @CJStrongify(fromVC)
        [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeDouyinLoading];
        if (error) {
            [CJToast toastText:CJPayNoNetworkMessage inWindow:fromVC.cj_window];
            return;
        }

        if (![response isSuccess]) {
            if (response.buttonInfo) {
                CJPayHandleErrorResponseModel *model = [CJPayHandleErrorResponseModel new];
                model.code = CJString(response.code);
                model.msg = CJString(response.buttonInfo.page_desc);
                model.buttonInfo = response.buttonInfo;
                [self p_handleErrorWithResponseParams:model];
            } else {
                [CJToast toastText:response.msg inWindow:fromVC.cj_window];
            }
            CJ_CALL_BLOCK(self.createSignOrderCompletion, response);
            return;
        }
        
        if (response.buttonInfo) {//三方侧成功，但银行侧失败
            CJPayHandleErrorResponseModel *model = [CJPayHandleErrorResponseModel new];
            model.code = CJString(response.code);
            model.msg = CJString(response.buttonInfo.page_desc);
            model.buttonInfo = response.buttonInfo;
            [self p_handleErrorWithResponseParams:model];
            return;
        }
        
        response.merchantId = self.signOrderModel.merchantId;
        response.appId = self.signOrderModel.appId;
        self.oneKeyCreateOrderResponse = response;
        
        CJ_CALL_BLOCK(self.createSignOrderCompletion, response);
        
        if ([response needLiveDetection]) {
            // 一键绑卡触发人脸识别
            [self p_liveDetectionWith:response];
        } else if ([response needVerifyPassWord]) {
            // 一件绑卡触发密码验证
            [self p_passWordVerification:response];
        } else {
            [self p_execOneKeySignCard];
        }
        
        NSMutableDictionary *trackerParams = [[self p_trackerBankTypeParams] mutableCopy];
        [trackerParams cj_setObject:self.signOrderModel.quickBindCardModel.rankType forKey:@"rank_type"];
        [trackerParams cj_setObject:self.signOrderModel.quickBindCardModel.bankRank forKey:@"bank_rank"];
        [self p_trackerWithEventName:@"wallet_addbcard_onestepbind_alivecheck"
                                    params:[trackerParams copy]];
    }];
}

- (void)p_oneKeySignBank:(NSString *)memberBizOrderNo {
    NSDictionary *params = @{
        @"app_id" : CJString(self.signOrderModel.appId),
        @"merchant_id" : CJString(self.signOrderModel.merchantId),
        @"member_biz_order_no" : CJString(memberBizOrderNo)
    };
    
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading title:CJPayLocalizedStr(@"跳转银行页面")];
    // 获取一件绑卡银行跳转地址
    @CJWeakify(self)
    [CJPayMemGetOneKeySignBankUrlRequest startWithBizParams:params completion:^(NSError * _Nonnull error, CJPayMemGetOneKeySignBankUrlResponse * _Nonnull response) {
        @CJStrongify(self)
        [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeDouyinLoading];

        if (error) {
            [CJToast toastText:CJPayNoNetworkMessage inWindow:self.signOrderFromVC.cj_window];
            return;
        }
        
        if (![response isSuccess]) {
            if (response.buttonInfo) {
                CJPayHandleErrorResponseModel *model = [CJPayHandleErrorResponseModel new];
                model.code = CJString(response.code);
                model.msg = CJString(response.buttonInfo.page_desc);
                model.buttonInfo = response.buttonInfo;
                [self p_handleErrorWithResponseParams:model];
                return;
            } else {
                [CJToast toastText:response.msg ?: CJPayNoNetworkMessage inWindow:self.signOrderFromVC.cj_window];
                return;
            }
        }
        
        self.oneKeyCreateOrderResponse.bankUrl = response.bankUrl;
        self.oneKeyCreateOrderResponse.postData = response.postData;
        self.oneKeyCreateOrderResponse.isMiniApp = response.isMiniApp;

        [self p_execOneKeySignCard];
    }];
}

- (void)p_passWordVerification:(CJPayCreateOneKeySignOrderResponse *)response {
    CJPayPassCodeVerifyModel *model = [CJPayPassCodeVerifyModel new];
    model.appId = self.signOrderModel.appId;
    model.merchantId = self.signOrderModel.merchantId;
    model.smchId = self.signOrderModel.specialMerchantId;
    model.mobile = self.signOrderModel.userInfo.mobile;
    model.orderNo = self.oneKeyCreateOrderResponse.memberBizOrderNo;
    model.userInfo = self.signOrderModel.userInfo;
    model.title = self.signOrderModel.title;
    model.subTitle = self.signOrderModel.subTitle;
    model.isQuickBindCard = self.signOrderModel.isQuickBindCard;
    model.activityInfo = [self.signOrderModel.quickBindCardModel activityInfoWithCardType:self.signOrderModel.selectedCardType];
    model.trackParams = self.signOrderModel.trackerParams;
    model.source = [self p_getTrackSource];
    @CJWeakify(self)
    model.backBlock = ^{
        @CJStrongify(self)
        // 验密页点击返回后退出到本页面
        [self.signOrderFromVC.navigationController popViewControllerAnimated:YES];
    };
    
    self.passCodeVerifyVC = [[CJPayPasswordVerifyViewController alloc] initWithVerifyModel:model completion:^(BOOL isSuccess, BOOL isCancel) {
        @CJStrongify(self)
        if (isCancel) {
            CJ_CALL_BLOCK(model.backBlock);
            return;
        }
        
        if (isSuccess) {
            [self.signOrderFromVC.navigationController cj_popViewControllerAnimated:YES completion:^{
                @CJStrongify(self)
                [self p_oneKeySignBank:response.memberBizOrderNo];
            }];
        }
    }];
    self.passCodeVerifyVC.cjAllowTransition = YES;
    [self.signOrderFromVC.navigationController pushViewController:self.passCodeVerifyVC animated:YES];
}

- (void)p_liveDetectionWith:(CJPayCreateOneKeySignOrderResponse *)response {
    @CJWeakify(self)
    [self.recogFaceVerifyItem startFaceRecogWithOneKeyResponse:response
                                                          completion:^(BOOL isSuccess) {
        @CJStrongify(self)
        if (isSuccess) {
            [self p_oneKeySignBank:response.memberBizOrderNo];
        } else {
            [self.signOrderFromVC.navigationController popToViewController:self.signOrderFromVC animated:YES];
        }
    }];
}

- (void)p_handleErrorWithResponseParams:(CJPayHandleErrorResponseModel *)model
{
    NSString *code = model.code;
    NSString *msg = model.msg;
    CJPayErrorButtonInfo *buttonInfo = model.buttonInfo;
    
    NSMutableDictionary *trackerParams = [[self p_trackerBankTypeParams] mutableCopy];
    [trackerParams cj_setObject:CJString(code) forKey:@"error_code"];
    [trackerParams cj_setObject:CJString(msg) forKey:@"error_message"];
    [trackerParams cj_setObject:self.signOrderModel.quickBindCardModel.rankType forKey:@"rank_type"];
    [trackerParams cj_setObject:self.signOrderModel.quickBindCardModel.bankRank forKey:@"bank_rank"];
    
    CJPayButtonInfoHandlerActionsModel *actionModel = [CJPayButtonInfoHandlerActionsModel new];

    @CJWeakify(self)
    actionModel.backAction = ^{
        @CJStrongify(self)
        [self.signOrderFromVC back];
        [self p_trackerWithEventName:@"wallet_addbcard_onestepbind_error_pop_click" params:trackerParams];
    };
    
    actionModel.closeAlertAction = ^{
        @CJStrongify(self)
        [self p_trackerWithEventName:@"wallet_addbcard_onestepbind_error_pop_click" params:trackerParams];
    };
    
    actionModel.alertPresentAction = ^{
        @CJStrongify(self)
        [self p_trackerWithEventName:@"wallet_addbcard_onestepbind_error_pop_imp" params:[trackerParams copy]];
    };
    
    actionModel.bindCardAction = ^{
        @CJStrongify(self)
        [trackerParams addEntriesFromDictionary:@{@"pop_type" : @"new_style" ,@"button_name" : @"去绑其他卡"}];
        [self p_trackerWithEventName:@"wallet_addbcard_onestepbind_error_pop_click" params:trackerParams];
        if (![self.signOrderFromVC isKindOfClass:[CJPayBindCardFirstStepViewController class]]) {
            [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeCommonQuickFrontFirstStep
                                                     params:@{}
                                                 completion:nil];
        }
    };
    
    buttonInfo.code = code;
    [[CJPayBDButtonInfoHandler shareInstance] handleButtonInfo:buttonInfo
                                                      fromVC:self.signOrderFromVC
                                                    errorMsg:msg
                                                 withActions:actionModel
                                                   withAppID:self.signOrderModel.appId
                                                  merchantID:self.signOrderModel.merchantId];
    
    [self p_trackerWithEventName:@"wallet_addbcard_onestepbind_error_pop_imp" params:[trackerParams copy]];
}

- (void)p_execOneKeySignCard
{
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval currentTimestamp = [date timeIntervalSince1970] * 1000;
    long duration = currentTimestamp - self.oneKeyBeginTimeInterval;
    
    BOOL openByApp = [self p_oneKeySignCardByApp];
    if (!openByApp) {
        NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
        self.enterBankH5PageTimestamp = [date timeIntervalSince1970] * 1000;
        if (self.oneKeyCreateOrderResponse.isMiniApp) {
            // 小程序一键绑卡
            [self p_oneKeySignCardByMicoApp];
            [self p_trackerWithEventName:@"wallet_rd_one_key_bank" params:@{
                @"page_type": @"micoApp",
                @"duration" : @(duration),
                @"fromVC" : CJString([self.signOrderFromVC cj_trackerName])
            }];
        } else {
            // h5页面一键绑卡
            [self p_oneKeySignCardByWeb];
            [self p_trackerWithEventName:@"wallet_rd_one_key_bank" params:@{
                @"page_type": @"H5",
                @"duration" : @(duration),
                @"fromVC" : CJString([self.signOrderFromVC cj_trackerName])
            }];
        }
    }
}

- (void)p_oneKeySignCardByWeb {
    
    NSString *bankUrl = self.oneKeyCreateOrderResponse.bankUrl;
    
    NSDictionary *extralParamDic = [self getExtralParams];
    if (extralParamDic && extralParamDic.count > 0) {
        bankUrl = [CJPayCommonUtil appendParamsToUrl:bankUrl params:extralParamDic];
    }
    
    NSURL *mURL = [NSURL URLWithString:bankUrl];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest new];
    urlRequest.URL = mURL;
    urlRequest.HTTPMethod = @"POST";
    NSDictionary *epccGwMsgDict = [self.oneKeyCreateOrderResponse.postData cj_toDic];
    NSString *postData = [NSString stringWithFormat:@"epccGwMsg=%@", [[epccGwMsgDict cj_stringValueForKey:@"epccGwMsg"] cj_URLEncode]];
    urlRequest.HTTPBody = [postData dataUsingEncoding:NSUTF8StringEncoding];
    
    [self appendHeaderWithRequest:urlRequest];

    CJPayBizWebViewController *webVC = [[CJPayBizWebViewController alloc] initWithRequest:urlRequest];
    webVC.titleStr = self.signOrderModel.quickBindCardModel.bankName;
    webVC.returnUrl = BDPayOneKeySignCardReturnURL;
    webVC.webviewStyle.enableFontScale = @"0";
    webVC.isShowNewUIStyle = YES;
    @CJWeakify(webVC);
    webVC.cjBackBlock = ^{  // disbale访问历史，点击back直接关闭
        @CJStrongify(webVC);
        [webVC closeWebVC];
    };
    @CJWeakify(self)
    webVC.closeCallBack = ^(id data) {
        @CJStrongify(self)
        if ([data isKindOfClass:NSDictionary.class]) {
            NSDictionary *dic = (NSDictionary *)data;
            if ([[dic cj_stringValueForKey:@"action"] isEqualToString:@"return_by_url"]) {
                CJ_CALL_BLOCK(self.signOrderCompletion, YES);
            } else {
                CJ_CALL_BLOCK(self.signOrderCompletion, NO);
            }
        }
    };
    [self.signOrderFromVC.navigationController pushViewController:webVC animated:YES];
}

// debug 需要 hook, 不能删
- (NSDictionary *)getExtralParams {
    return @{};
}

// debug 需要 hook, 不能删
- (void)appendHeaderWithRequest:(NSMutableURLRequest *)request {
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
}

- (void)p_oneKeySignCardByMicoApp {
    if (!Check_ValidString(self.oneKeyCreateOrderResponse.bankUrl)) {
        CJPayLogInfo(@"No valid schema to open mini app!");
        return;
    }
    
    NSMutableDictionary *trackParam = [[self p_trackerBankTypeParams] mutableCopy];
    [trackParam cj_setObject:@"1" forKey:@"result"];
    [self p_trackerWithEventName:@"wallet_addbcard_onestepbind_by_result"
                          params:trackParam];
    
    [[CJPayWebViewUtil sharedUtil] openCJScheme:self.oneKeyCreateOrderResponse.bankUrl fromVC:self.signOrderFromVC useModal:YES];
}

- (BOOL)p_shouldOpenApp
{
    NSString *aid = [CJPayRequestParam gAppInfoConfig].appId;
    if (![aid isEqualToString:@"1128"]) {
        return NO;
    }
    
    NSString *bankCode = self.signOrderModel.quickBindCardModel.bankCode;
    return ([bankCode isEqualToString:@"CMB"] && [self.signOrderModel.selectedCardType isEqualToString:@"DEBIT"]);
}

- (BOOL)p_oneKeySignCardByApp
{
    if ([self p_shouldOpenApp]) {
        NSDictionary *epccGwMsgDict = [self.oneKeyCreateOrderResponse.postData cj_toDic];
        
        NSString *epccGwMsgStr = [epccGwMsgDict cj_stringValueForKey:@"epccGwMsg"];
        NSString *cmbAppScheme = [NSString stringWithFormat:@"cmbmobilebank://cmbls/functionjump?action=gofuncid&funcid=0026014&requesttype=post&cmb_app_trans_parms_start=here&epccGwMsg=%@", [epccGwMsgStr cj_URLEncode]];
        NSURL *cmbURL = [NSURL URLWithString:cmbAppScheme];
        if ([[UIApplication sharedApplication] canOpenURL:cmbURL]) {
            
            __block BOOL isOpenSuccess = YES;
            // 调用AppJump敏感方法，需走BPEA鉴权
            [CJPayPrivacyMethodUtil applicationOpenUrl:cmbURL
                                            withPolicy:@"bpea-caijing_quick_bindcard_jump_other_app"
                                       completionBlock:^(NSError * _Nullable error) {
                
                if (error) {
                    CJPayLogError(@"error in caijing_quick_bindcard_jump_other_app");
                    isOpenSuccess = NO;
                }
            }];
            return isOpenSuccess;
            
        }
    }
    return NO;
}

- (NSDictionary *)bankParamsDictionary
{
    return @{
        @"13" : @"toutiao",
        @"1128" : @"douyin",
        @"1112" : @"huoshan",
        @"8663" : @"huoshan",
        @"32" : @"xigua",
        @"1319" : @"ppxia",
        @"35" : @"lite",
        @"1378" : @"lark",
        @"1349" : @"duoshan"
    };
}

#pragma mark - track

- (NSDictionary *)p_trackerBankTypeParams
{
    NSString *bankTypeList = [self.signOrderModel.quickBindCardModel.cardType isEqualToString:@"DEBIT"] ? @"储蓄卡" : @"信用卡";
    NSString *normalBankTypeList = [self.signOrderModel.quickBindCardModel.cardType isEqualToString:@"DEBIT"] ? @"信用卡" : @"储蓄卡";//支持跳转手动输入的银行卡类型
    if ([self.signOrderModel.quickBindCardModel.cardType isEqualToString:@"ALL"]) {
        bankTypeList = @"储蓄卡、信用卡";
        normalBankTypeList = @"";
    }
    
    NSString *isAliveCheckStr = self.oneKeyCreateOrderResponse.faceVerifyInfoModel.needLiveDetection ? @"1": @"0";
    
    return @{
        @"bank_name": CJString(self.signOrderModel.quickBindCardModel.bankName),
        @"bank_type": [self.signOrderModel.selectedCardType isEqualToString:@"DEBIT"] ? @"储蓄卡" : @"信用卡",
        @"bank_type_list": CJString(bankTypeList),
        @"is_alivecheck": CJString(isAliveCheckStr),
        @"activity_info": [self.signOrderModel.quickBindCardModel activityInfoWithCardType:self.signOrderModel.selectedCardType] ?: @[],
        @"page_type": @"page",
        @"normal_bank_type": CJString(normalBankTypeList)
    };
}

- (void)p_trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params
{
    NSMutableDictionary *baseParams = [[[CJPayBindCardManager sharedInstance] bindCardTrackerBaseParams] mutableCopy];
    [baseParams addEntriesFromDictionary:params];
    
    [CJTracker event:eventName params:[baseParams copy]];
}

- (void)p_trackButtonInfoErrorPopWithCode:(NSString *)code msg:(NSString *)msg isClick:(BOOL)isClick {
    NSMutableDictionary *trackerParams = [[self p_trackerBankTypeParams] mutableCopy];
    [trackerParams cj_setObject:CJString(code) forKey:@"error_code"];
    [trackerParams cj_setObject:CJString(msg) forKey:@"error_message"];
    if (isClick) {  //弹窗点击
        [self p_trackerWithEventName:@"wallet_addbcard_onestepbind_error_pop_click" params:[trackerParams copy]];
    } else {        //弹窗展现
        [self p_trackerWithEventName:@"wallet_addbcard_onestepbind_error_pop_imp" params:[trackerParams copy]];
    }
}

#pragma mark - 一键绑卡成功后查询结果
- (void)queryOneKeySignStateAppDidEnterForground {
    if (Check_ValidString(self.oneKeyCreateOrderResponse.memberBizOrderNo) &&
        [[UIViewController cj_foundTopViewControllerFrom:self.signOrderFromVC] isKindOfClass:[self.signOrderFromVC class]] &&
        [self p_shouldOpenApp]) {
        [self queryOneKeySignState];
    }
}

- (void)queryOneKeySignState {
    self.startPollingTime = CFAbsoluteTimeGetCurrent();
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading vc:self.signOrderFromVC];
    @CJWeakify(self)
    [self p_pollingOneKeySignState:5 completion:^(NSError * _Nonnull error, CJPayQueryOneKeySignResponse * _Nonnull response) {
        @CJStrongify(self)
        [[CJPayLoadingManager defaultService] stopLoading];
        
        NSMutableDictionary *trackerParams = [[self p_trackerBankTypeParams] mutableCopy];
        [trackerParams cj_setObject:[response.orderStatus isEqualToString:@"success"] ? @"1" : @"0" forKey:@"result"];
        [trackerParams cj_setObject:self.signOrderModel.quickBindCardModel.rankType forKey:@"rank_type"];
        [trackerParams cj_setObject:self.signOrderModel.quickBindCardModel.bankRank forKey:@"bank_rank"];
        [self p_trackerWithEventName:@"wallet_addbcard_onestepbind_result" params:[trackerParams copy]];

        if (error) {
            [CJToast toastText:CJPayNoNetworkMessage inWindow:self.signOrderFromVC.cj_window];
            return;
        }
        
        if (![response isSuccess]) {
            if (response.buttonInfo) {
                
                CJPayHandleErrorResponseModel *model = [CJPayHandleErrorResponseModel new];
                model.code = CJString(response.code);
                model.msg = CJString(response.buttonInfo.page_desc);
                model.buttonInfo = response.buttonInfo;
                [self p_handleErrorWithResponseParams:model];
                return;
            } else {
                [CJToast toastText:CJString(response.msg) inWindow:self.signOrderFromVC.cj_window];
                return;
            }
        }
        
        if ([response.orderStatus isEqualToString:@"success"]) {
            self.bankCardId = response.bankCardId;
            [self p_processAfterSignSuccessWithResponse:response];
        } else if ([response.orderStatus isEqualToString:@"fail"]) {
            if (response.buttonInfo) { //三方侧成功，但银行侧失败
                CJPayHandleErrorResponseModel *model = [CJPayHandleErrorResponseModel new];
                model.code = CJString(response.code);
                model.msg = CJString(response.buttonInfo.page_desc);
                model.buttonInfo = response.buttonInfo;
                [self p_handleErrorWithResponseParams:model];
                return;
            }
            [CJToast toastText:CJPayLocalizedStr(@"银行签约失败，请稍后重试") inWindow:self.signOrderFromVC.cj_window];
        }
    }];
}

- (void)microQuickBindCardSuccessWithNotify:(NSNotification *)notification {
    
    if (![notification.object isKindOfClass:NSDictionary.class]) {
        return;
    }
    
    NSDictionary *paramDic = (NSDictionary *)notification.object;
    if (!paramDic) {
        return;
    }
    
    // 只有顶部vc是自己时才把短验页面推出来
    if ([UIViewController cj_foundTopViewControllerFrom:self.signOrderFromVC] != self.signOrderFromVC) {
        return;
    }
    
    [self p_trackerWithEventName:@"wallet_addbcard_onestepbind_callback_result"
                          params:[self p_trackerBankTypeParams]];
    
    // 全屏短验页签约绑卡
    CJPaySignCardVerifySMSViewController *smsInputVC = [[CJPaySignCardVerifySMSViewController alloc] initWithSchemaParams:paramDic];
    smsInputVC.needSendSMSWhenViewDidLoad = YES;
    smsInputVC.oneKeyOrderResponse = self.oneKeyCreateOrderResponse;
    smsInputVC.cardBindSource = self.signOrderModel.cardBindSource;
    
    NSMutableDictionary *baseParams = [[[CJPayBindCardManager sharedInstance] bindCardTrackerBaseParams] mutableCopy];

    [baseParams addEntriesFromDictionary:[self p_trackerBankTypeParams]];
    smsInputVC.extTrackParam = baseParams;
    @CJWeakify(self)
    smsInputVC.signCardSuccessBlock = ^(CJPaySignSMSResponse *response) {
        @CJStrongify(self)
        self.bankCardId = response.bankCardId;
        CJPayQueryOneKeySignResponse *oneKeySignResponse = [CJPayQueryOneKeySignResponse new];
        oneKeySignResponse.signNo = response.signNo;
        oneKeySignResponse.token = response.pwdToken;
        [self p_processAfterSignSuccessWithResponse:oneKeySignResponse];
    };
    
    smsInputVC.cjBackBlock = ^{
        @CJStrongify(self)
        [self.signOrderFromVC back];
    };
    
    if (self.signOrderFromVC.navigationController && [self.signOrderFromVC.navigationController isKindOfClass:[CJPayNavigationController class]]) {
        [self.signOrderFromVC.navigationController pushViewController:smsInputVC animated:YES];
    } else {
        [smsInputVC presentWithNavigationControllerFrom:[UIViewController cj_foundTopViewControllerFrom:self.signOrderFromVC]
                                                useMask:NO
                                             completion:^{}];
    }
}

- (void)p_processAfterSignSuccessWithResponse:(CJPayQueryOneKeySignResponse *)response {
    if ([self.signOrderModel.userInfo.pwdStatus isEqualToString:@"0"]) { //没有密码，新用户，走设密流程
        [self p_setPwdWithQueryOneKeySignResponse:response];
    } else {
        [self p_completeProcessWithIsSuccess:YES signNo:response.signNo token:response.token];
    }
}

- (void)p_pollingOneKeySignState:(int)retryCount completion:(void (^)(NSError * _Nonnull, CJPayQueryOneKeySignResponse * _Nonnull))completionBlock {
    NSDictionary *params = @{
        @"app_id" : CJString(self.signOrderModel.appId),
        @"merchant_id" : CJString(self.signOrderModel.merchantId),
        @"member_biz_order_no" : CJString(self.oneKeyCreateOrderResponse.memberBizOrderNo),
        @"sign" : CJString(self.oneKeyCreateOrderResponse.signOrder)
    };
    @CJWeakify(self)
    [CJPayQueryOneKeySignRequest startRequestWithParams:params completion:^(NSError * _Nonnull error, CJPayQueryOneKeySignResponse * _Nonnull response) {
        @CJStrongify(self)
        NSArray *knownOrderStatus = @[@"success", @"fail"];
        if (![response.orderStatus isEqualToString:@"success"]) {
            [CJMonitor trackServiceAllInOne:@"wallet_rd_quick_bind_card_fail"
                                     metric:@{}
                                   category:@{@"code": CJString(response.code),
                                              @"msg": CJString(response.msg)}
                                      extra:@{}];
        }
        
        if ([knownOrderStatus containsObject:response.orderStatus]) {
            CJ_CALL_BLOCK(completionBlock, error, response);
            return;
        } else {
            NSTimeInterval deltaTime = CFAbsoluteTimeGetCurrent();
            if ((deltaTime - self.startPollingTime) / 1000 > 5 || retryCount < 1) {
                CJ_CALL_BLOCK(completionBlock, error, response);
            } else {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self p_pollingOneKeySignState:retryCount - 1 completion:completionBlock];
                });
            }
        }
    }];
}

- (void)p_setPwdWithQueryOneKeySignResponse:(CJPayQueryOneKeySignResponse *)response
{
    NSArray *sourceArray = @[@(CJPayCardBindSourceTypeBalanceWithdraw),@(CJPayCardBindSourceTypeBalanceRecharge),@(CJPayCardBindSourceTypeIndependent)];

    CJPayPasswordSetModel *model = [CJPayPasswordSetModel new];
    model.appID = self.signOrderModel.appId;
    model.merchantID = self.signOrderModel.merchantId;
    model.smchID = self.signOrderModel.specialMerchantId;
    model.signOrderNo = self.oneKeyCreateOrderResponse.memberBizOrderNo;
    model.mobile = self.signOrderModel.userInfo.mobile;
    model.isSetAndPay = self.bindCardCommonModel.cardBindSource == CJPayCardBindSourceTypeBindAndPay;
    model.isNeedCardInfo = [sourceArray containsObject:@(self.signOrderModel.cardBindSource)];
    NSString *cardType = self.signOrderModel.selectedCardType;
    model.activityInfos = [self.signOrderModel.quickBindCardModel activityInfoWithCardType:cardType];
    @CJWeakify(self)
    model.backCompletion = ^{
        @CJStrongify(self)
        [self p_completeProcessWithIsSuccess:NO signNo:@"" token:@""];
    };
    model.source = [self p_getTrackSource];
    model.subTitle = self.bindCardCommonModel.displayDesc;
    model.processInfo = self.signOrderModel.processInfo;
    
    UIViewController *vc = [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageSetPWDFirstStep params:@{} completion:nil];
    
    if (![vc isKindOfClass:[CJPayPasswordSetFirstStepViewController class]]) {
        CJPayLogAssert(NO, @"vc类型异常%@", [vc cj_trackerName]);
        return;
    }
    
    CJPayPasswordSetFirstStepViewController *setPassViewController = (CJPayPasswordSetFirstStepViewController *)vc;
    
    setPassViewController.setModel = model;
    setPassViewController.completion = ^(NSString * _Nullable token, BOOL isSuccess, BOOL isExit) {
        @CJStrongify(self)
        if (isSuccess) {
            if (self) {
                [self p_completeProcessWithIsSuccess:YES signNo:response.signNo token:token];
            }
        }
        
        // exit: 主动退出设密流程
        if (isExit) {
            [self p_completeProcessWithIsSuccess:NO signNo:response.signNo token:@""];
        }
        
        self.passCodeSetVC = nil;
    };
    if (!self.passCodeSetVC) {
        // 避免重复 push 页面
        self.passCodeSetVC = setPassViewController;
    }
}

- (void)p_completeProcessWithIsSuccess:(BOOL)isSuccess signNo:(NSString *)signNo token:(NSString *)token
{
    [[NSNotificationCenter defaultCenter] postNotificationName:CJPayBindCardSignSuccessNotification object:nil];

    [self p_trackerWithEventName:@"wallet_addbcard_page_toast_info" params:[self p_trackerBankTypeParams]];
    CJPayBindCardResultModel *resultModel = [CJPayBindCardResultModel new];
    resultModel.result = isSuccess ? CJPayBindCardResultSuccess : CJPayBindCardResultFail;
    resultModel.signNo = signNo;
    resultModel.token = token;
    resultModel.memberBizOrderNo = self.oneKeyCreateOrderResponse.memberBizOrderNo;
    resultModel.bankCardInfo = [CJPayMemBankInfoModel new];
    resultModel.bankCardInfo.bankCardID = self.bankCardId;
    self.bankCardId = @"";
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    double currentTimestamp = [date timeIntervalSince1970] * 1000;
    [self p_trackerWithEventName:@"wallet_rd_custom_scenes_time" params:@{
        @"scenes_name" : @"绑卡",
        @"sub_section" : @"一键绑卡进入银行页到完成绑卡",
        @"time" : @(currentTimestamp - self.enterBankH5PageTimestamp)
    }];
    
    [self p_buildCardInfoForResultModel:resultModel];
    [[CJPayBindCardManager sharedInstance] finishBindCard:resultModel completionBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:CJPayBindCardSuccessNotification object:nil];
        [self p_clearModelData];
    }];

}

- (void)p_buildCardInfoForResultModel:(CJPayBindCardResultModel *)resultModel {
    if (self.bindCardCommonModel.cardBindSource != CJPayCardBindSourceTypeIndependent
        || self.bindCardCommonModel.independentBindCardType != CJPayIndependentBindCardTypeNative
        || resultModel.bankCardInfo) {
        return;
    }
    
    resultModel.bankCardInfo = [CJPayMemBankInfoModel new];
    resultModel.bankCardInfo.bankName = self.signOrderModel.quickBindCardModel.bankName;
    resultModel.bankCardInfo.cardType = self.signOrderModel.selectedCardType;
}

- (void)p_clearModelData{
    self.bindCardCommonModel = nil;
    self.signOrderFromVC = nil;
    self.signOrderModel = nil;
    self.passCodeVerifyVC = nil;
    self.recogFaceVerifyItem = nil;
    self.oneKeyCreateOrderResponse = nil;
}

- (void)microQuickBindCardFailWithNotify:(NSNotification *)notification {
    if ([UIViewController cj_foundTopViewControllerFrom:self.signOrderFromVC] != self.signOrderFromVC) {
        return;
    }
    
    [self p_trackerWithEventName:@"wallet_addbcard_onestepbind_callback_result"
                          params:[self p_trackerBankTypeParams]];
    [self.signOrderFromVC back];
}

- (NSString *)p_getPromotionSource {
    if (self.signOrderModel.cardBindSource != CJPayCardBindSourceTypeIndependent) {
        return @"payment_manage";
    }
    
    if (self.bindCardCommonModel.independentBindCardType == CJPayIndependentBindCardTypeNative) {
        CJPayJHInformationConfig *jhConfig = [CJPaySettingsManager shared].currentSettings.jhConfig;
        return jhConfig.source;
    }
    
    return @"wallet_bcard_manage";
}

- (NSString *)p_getTrackSource {
    if (self.signOrderModel.cardBindSource != CJPayCardBindSourceTypeIndependent) {
        return self.signOrderModel.frontIndependentBindCardSource;
    }
    
    if (self.bindCardCommonModel.independentBindCardType == CJPayIndependentBindCardTypeNative) {
        CJPayJHInformationConfig *jhConfig = [CJPaySettingsManager shared].currentSettings.jhConfig;
        return jhConfig.source;
    }
    
    return @"wallet_bcard_manage";
}

#pragma mark - getter

- (CJPayVerifyItemBindCardRecogFace *)recogFaceVerifyItem {
    if (!_recogFaceVerifyItem) {
        _recogFaceVerifyItem = [CJPayVerifyItemBindCardRecogFace new];
        _recogFaceVerifyItem.loadingBlock = ^(BOOL isLoading) {
            if (isLoading) {
                [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading title:@"跳转银行页面"];
            } else {
                [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeDouyinLoading];
            }
        };
        _recogFaceVerifyItem.referVC = self.signOrderFromVC;
        _recogFaceVerifyItem.verifySource = @"一键绑卡";
    }
    return _recogFaceVerifyItem;
}

@end
