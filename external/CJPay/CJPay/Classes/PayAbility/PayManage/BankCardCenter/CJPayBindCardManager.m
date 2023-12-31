    //
//  CJPayBindCardManager.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/24.
//

#import "CJPayBindCardManager.h"
#import "CJPayUserInfo.h"
#import "CJPayNavigationController.h"
#import "CJPayBindCardSharedDataModel.h"
#import "CJPayWebViewUtil.h"
#import "CJPayBizParam.h"
#import "CJPayBaseRequest+BDPay.h"
#import "UIViewController+CJTransition.h"
#import <TTReachability/TTReachability.h>
#import "CJPayUIMacro.h"
#import "CJPayVerifyPasswordRequest.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayAuthVerifyViewController.h"
#import "CJPayQuickBindCardModel.h"
#import "CJPayDegradeModel.h"
#import "CJPayMemCreateBizOrderResponse.h"
#import "CJPayBizAuthInfoModel.h"
#import "CJPayRequestParam.h"
#import "CJPayUnionPaySignInfo.h"
#import "CJPayBindCardController.h"
#import <objc/runtime.h>
#import "CJPayBindCardPageBaseModel.h"
#import "CJPayMemCreateBizOrderRequest.h"
#import "CJPayQuickBindCardKeysDefine.h"
#import "CJPayBizAuthViewController.h"
#import "CJPayHalfSignCardVerifySMSViewController.h"
#import "UIViewController+CJPay.h"
#import "CJPayPasswordSetFirstStepViewController.h"
#import "CJPayUnionBindCardPlugin.h"
#import "CJPayDeskUtil.h"
#import "CJPayUniversalPayDeskService.h"
#import "CJPayDeskUtil.h"
#import "CJPayMyBankCardPlugin.h"
#import "CJPayNativeBindCardPlugin.h"
#import "CJPayMemBankInfoModel.h"

#import "CJPayBankCardModel.h"
#import "CJPayExceptionViewController.h"
#import "CJPayMemberSendSMSRequest.h"
#import "CJPayMemberSignResponse.h"
#import "CJPaySignCardMap.h"
#import "CJPayKVContext.h"
#import "CJPaySaasSceneUtil.h"
#import <IESGeckoKit/IESGeckoKit.h>

@interface CJPayBindCardManager()

@property (nonatomic, weak) CJPayFullPageBaseViewController *bankCardListVC;
@property (nonatomic, strong) CJPayBindCardSharedDataModel *bindCardCommonModel;
@property (nonatomic, strong) NSMutableDictionary *pageTypes;
@property (nonatomic, copy) NSString *entryName;
@property (nonatomic, copy) NSString *geckoAccessKey;
@property (nonatomic, assign) NSTimeInterval startBindTime;//开始绑卡时间，埋点用

@end


@implementation CJPayBindCardManager

+ (instancetype)sharedInstance {
    static CJPayBindCardManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CJPayBindCardManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closePage) name:BDPayClosePayDeskNotification object:nil];
    }
    return self;
}

- (void)openBankCardListWithMerchantId:(NSString *)merchantId
                                 appId:(NSString *)appId
                                userId:(NSString *)userId {
    [self p_openBankCardListWithMerchantId:merchantId appId:appId userId:userId inheritTheme:@""];
    
}

- (void)p_openBankCardListWithMerchantId:(NSString *)merchantId
                                   appId:(NSString *)appId
                                  userId:(NSString *)userId
                            inheritTheme:(NSString *)inheritTheme {
    CJPaySettings *settings = [CJPaySettingsManager shared].currentSettings;
    __block BOOL isCardListUseH5 = NO;
    
    [settings.degradeModels enumerateObjectsUsingBlock:^(CJPayDegradeModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.bdpayAppId isEqualToString:appId] && [obj.bdpayMerchantId isEqualToString:merchantId] && obj.isCardListUseH5) {
            isCardListUseH5 = YES;
            *stop = YES;
        }
    }];
    
    if (isCardListUseH5) {
        NSString *bankCardListUrl = [NSString stringWithFormat:@"%@/usercenter/cards", [CJPayBaseRequest bdpayH5DeskServerHostString]];
        NSDictionary *h5Params = @{
            @"app_id" : CJString(appId),
            @"merchant_id" : CJString(merchantId),
            @"inherit_theme": CJString(inheritTheme),
        };
        
        [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:[UIViewController cj_foundTopViewControllerFrom:merchantId.cjpay_referViewController] toUrl:bankCardListUrl params:h5Params];
        
    } else {
        [CJPayPerformanceMonitor trackAPIStartWithAPIScene:CJPayPerformanceAPISceneBankCardList extra:@{}];
        if(!CJ_OBJECT_WITH_PROTOCOL(CJPayMyBankCardPlugin)) {
            CJPayLogAssert(NO, @"未实现CJPayMyBankCardPlugin的对应方法");
            return;
        }
        self.bankCardListVC = [CJ_OBJECT_WITH_PROTOCOL(CJPayMyBankCardPlugin) openMyCardWithAppId:appId merchantId:merchantId userId:userId extraParams:@{@"inherit_theme": CJString(inheritTheme)}];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)closePage {
    if (self.bankCardListVC) {
        [self.bankCardListVC.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)p_miroQuickBindCardSuccessWithParams:(NSDictionary *)paramDic {
    [[NSNotificationCenter defaultCenter] postNotificationName:BDPayMircoQuickBindCardSuccessNotification
                                                        object:paramDic];
}

- (void)p_miroQuickBindCardFailWithParams:(NSDictionary *)paramDic {
    [[NSNotificationCenter defaultCenter] postNotificationName:BDPayMircoQuickBindCardFailNotification
                                                        object:paramDic];
}

- (void)bindCardWithCommonModel:(CJPayBindCardSharedDataModel *)commonModel {
    self.startBindTime = [[NSDate date] timeIntervalSince1970] * 1000;
    self.bindCardCommonModel = commonModel;
    
    if (commonModel.bindUnionCardType == CJPayBindUnionCardTypeSyncBind) {
        [[CJPayBindCardManager sharedInstance] enterUnionBindCardAndCreateOrderWithFromVC:commonModel.referVC ? : [UIViewController cj_topViewController] completionBlock:^(BOOL isOpenedSuccess, UIViewController * _Nonnull firstVC) {}];
        return;
    }
    
    if ([self p_outerDyPayNativeBindCard:commonModel]) {
        return;
    }
    
    NSString *lynxScheme = [CJPaySettingsManager shared].currentSettings.bindcardLynxUrl;
    if (Check_ValidString(lynxScheme)) {
        if (commonModel.lynxBindCardBizScence == CJPayLynxBindCardBizScenceSignPay) {
            [self p_trackForContainerReadyWithIsNativeBindCard:NO];
        }
        
        [self p_lynxBindCardWithCommonModel:commonModel schema:lynxScheme];
        return;
    }
    
    // 默认的lynx绑卡Scheme
    NSString * const defalutScheme = @"sslocal://webcast_lynxview?url=https%3A%2F%2Flf-webcast-sourcecdn-tos.bytegecko.com%2Fobj%2Fbyte-gurd-source%2F10181%2Fgecko%2Fresource%2Fcj_lynx_cardbind%2Frouter%2Ftemplate.js&hide_loading=1&show_error=1&trans_status_bar=1&type=popup&hide_nav_bar=1&web_bg_color=transparent&width_percent=100&height_percent=100&open_animate=0&mask_alpha=0.1&gravity=center&mask_click_disable=0&top_level=1&host=aweme&engine_type=new&page_name=member_biz&disable_url_handle=1";
    [self p_lynxBindCardWithCommonModel:commonModel schema:defalutScheme];
}

- (void)onlyBindCardWithCommonModel:(CJPayBindCardSharedDataModel *)commonModel
                             params:(NSDictionary *)params
                         completion:(BDPayBindCardCompletion)completion
                   stopLoadingBlock:(void (^)(void))stopLoadingBlock {
    self.startBindTime = [[NSDate date] timeIntervalSince1970] * 1000;
    self.bindCardCommonModel = commonModel;
    if (CJ_OBJECT_WITH_PROTOCOL(CJPayNativeBindCardPlugin)) {
        [self p_trackForContainerReadyWithIsNativeBindCard:YES];
        [CJ_OBJECT_WITH_PROTOCOL(CJPayNativeBindCardPlugin) onlyBindCardWithCommonModel:commonModel
                                                                                 params:params
                                                                             completion:completion
                                                                       stopLoadingBlock:stopLoadingBlock];
    }
}

- (BOOL)isLynxReady {
    NSString *path = [IESGeckoKit rootDirForAccessKey:self.geckoAccessKey channel:@"caijing_native_lynx"];
    return Check_ValidString(path);
}

- (BOOL)p_outerDyPayNativeBindCard:(CJPayBindCardSharedDataModel *)commonModel {
    BOOL isNativeBindCard = NO;
    BOOL enableNativeBindCard = [CJPaySettingsManager shared].currentSettings.nativeBindCardConfig.enableNativeBindCard;
    if (CJ_OBJECT_WITH_PROTOCOL(CJPayNativeBindCardPlugin)) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayNativeBindCardPlugin) bindCardWithCommonModel:commonModel];
        isNativeBindCard = YES;
    }

    if (commonModel.lynxBindCardBizScence == CJPayLynxBindCardBizScenceOuterDypay || commonModel.lynxBindCardBizScence == CJPayLynxBindCardBizScenceSignPayDetail) {
        if (![self isLynxReady] && enableNativeBindCard) {
            if (CJ_OBJECT_WITH_PROTOCOL(CJPayNativeBindCardPlugin)) {
                [CJ_OBJECT_WITH_PROTOCOL(CJPayNativeBindCardPlugin) bindCardWithCommonModel:commonModel];
                isNativeBindCard = YES;
            }
        }
        
        [self p_trackForContainerReadyWithIsNativeBindCard:isNativeBindCard];
    }
    
    return isNativeBindCard;
}

- (void)p_trackForContainerReadyWithIsNativeBindCard:(BOOL)isNativeBindCard {
    NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
    NSTimeInterval durationTime = [[NSDate date] timeIntervalSince1970] * 1000 - self.startBindTime;
    [trackData addEntriesFromDictionary:@{@"is_ready":@([self isLynxReady]),
                                          @"params_for_special":@"tppp",
                                          @"client_bankcard_duration":@(durationTime),
                                          @"bankcard_way": isNativeBindCard ? @"native" : @"lynx"
                                        }];
    [self p_track:@"wallet_cashier_host_container_ready_results"
           params:trackData];
}

- (void)p_lynxBindCardWithCommonModel:(CJPayBindCardSharedDataModel *)bindModel schema:(NSString *)schemaStr {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSString *processInfo = [CJPayCommonUtil dictionaryToJson:[bindModel.processInfo toDictionary]];
    NSString *cardTradeScene = [self p_cardTradeScene:bindModel.lynxBindCardBizScence];
    
    if ([cardTradeScene isEqualToString:@"union_bind"] && (!Check_ValidString(bindModel.jhAppId) || !Check_ValidString(bindModel.jhMerchantId))) {
        cardTradeScene = @"zg_bindcard";
    }
    
    if (!Check_ValidString(cardTradeScene)) {
        [CJMonitor trackServiceAllInOne:@"wallet_rd_card_trade_scene_exception"
                                 metric:@{}
                               category:@{@"biz_scene": @(bindModel.lynxBindCardBizScence)}
                                  extra:@{}];
    }
    NSString *bindCardInfoStr = [CJPayCommonUtil dictionaryToJson:bindModel.bindCardInfo];
    NSString *teaSource = [self p_teaSource:bindModel.lynxBindCardBizScence];
    NSString *source = [bindModel.trackInfo cj_stringValueForKey:@"source"];
    if (Check_ValidString(source)) {
        teaSource = source;
    }
    NSDictionary *baseParams = @{
        @"merchant_id" : CJString(bindModel.merchantId),
        @"app_id" : CJString(bindModel.appId),
        @"bind_card_info" : CJString(bindCardInfoStr),
        @"process_info" : CJString(processInfo),
        @"card_trade_scene" : CJString(cardTradeScene),
        @"tea_source" : CJString(teaSource)
    };
    [params addEntriesFromDictionary:baseParams];
    
    if (Check_ValidDictionary(bindModel.trackInfo)) {
        NSString *trackInfoStr = [CJPayCommonUtil dictionaryToJson:bindModel.trackInfo];
        if (Check_ValidString(trackInfoStr)) {
            [params addEntriesFromDictionary:@{@"track_info" : trackInfoStr}];
        }
    }
    
    NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
    NSMutableDictionary *cjExtTea = [NSMutableDictionary new];
    [cjExtTea addEntriesFromDictionary:@{@"trace_id":CJString([bindModel.trackerParams cj_stringValueForKey:@"trace_id"])}];
    if (Check_ValidDictionary(trackData)) {
        [cjExtTea addEntriesFromDictionary:@{
            @"prepay_id":CJString([trackData cj_stringValueForKey:@"prepay_id"]),
            @"outer_aid":CJString([trackData cj_stringValueForKey:@"outer_aid"])
        }];
    }
        
    [params addEntriesFromDictionary:@{@"cj_ext_tea":cjExtTea}];
    [params cj_setObject:[self p_tradeScene:bindModel.lynxBindCardBizScence] forKey:@"trade_scene"];

    if (Check_ValidDictionary(bindModel.bindCardInfo)) {
        [params cj_setObject:@"1" forKey:@"direct_to_quickbind"];
        [params cj_setObject:[bindModel.bindCardInfo cj_stringValueForKey:@"bank_code"] forKey:@"bank_code"];
        [params cj_setObject:[bindModel.bindCardInfo cj_stringValueForKey:@"card_type"] forKey:@"card_type_chosen"];
    }
    
    [params cj_setObject:bindModel.jhMerchantId forKey:@"jh_merchant_id"];
    [params cj_setObject:bindModel.jhAppId forKey:@"jh_app_id"];
    switch (bindModel.cardBindSource) {
        case CJPayCardBindSourceTypeBalanceRecharge:
            [params cj_setObject:@"recharge_wallet_balance" forKey:@"source"];
            break;
        case CJPayCardBindSourceTypeBalanceWithdraw:
            [params cj_setObject:@"withdraw_wallet_balance" forKey:@"source"];
            break;
        default:
            break;
    }
    // 如果处于SaaS环境，绑卡时需在schema带上SaaS标识
    if (bindModel.isSaasScene) {
        [params cj_setObject:@"1" forKey:CJPaySaasKey];
    }
    NSString *schema = [CJPayCommonUtil appendParamsToUrl:schemaStr params:params];
    CJ_CALL_BLOCK(bindModel.dismissLoadingBlock);
    @CJWeakify(self)
    [CJPayDeskUtil openLynxPageBySchema:schema completionBlock:^(CJPayAPIBaseResponse * _Nonnull response) {
        @CJStrongify(self)
        NSDictionary *data = response.data;
        CJPayBindCardResultModel *resultModel = [CJPayBindCardResultModel new];
        resultModel.isLynxBindCard = YES;
        resultModel.result = CJPayBindCardResultCancel;
        if (Check_ValidDictionary(data) && [data cj_dictionaryValueForKey:@"data"]) {
            NSDictionary *dataDic = [data cj_dictionaryValueForKey:@"data"];
            NSDictionary *msgDic = [dataDic cj_dictionaryValueForKey:@"msg"];
            if (msgDic) {
                int code = [msgDic cj_intValueForKey:@"code" defaultValue:0];
                int isCancelPay = [msgDic cj_intValueForKey:@"is_cancel_pay" defaultValue:0];
                if (code == 1) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:CJPayBindCardSignSuccessNotification object:nil];
                    if (isCancelPay == 0) {
                        resultModel.result = CJPayBindCardResultSuccess;
                    }
                    resultModel.signNo = [msgDic cj_stringValueForKey:@"sign_no"];
                    resultModel.token = [msgDic cj_stringValueForKey:@"token"];
                    resultModel.memberBizOrderNo = [msgDic cj_stringValueForKey:@"member_biz_order_no"];
                    CJPayMemBankInfoModel *cardModel = [[CJPayMemBankInfoModel alloc] initWithDictionary:[msgDic cj_dictionaryValueForKey:@"card_info"] error:nil];
                    resultModel.bankCardInfo = cardModel;
                    [[NSNotificationCenter defaultCenter] postNotificationName:CJPayBindCardSuccessNotification object:@{
                        @"bind_scene": @(bindModel.lynxBindCardBizScence),
                        @"bind_order_no": CJString(resultModel.memberBizOrderNo),
                        @"is_cancel_pay" : @(isCancelPay)
                    }];
                }
            }
        }
        [self finishBindCard:resultModel completionBlock:nil];
    }];
}

- (nullable NSString *)p_tradeScene:(CJPayLynxBindCardBizScence)bizScence {
    switch (bizScence) {
        case CJPayLynxBindCardBizScenceBalanceRecharge:
        case CJPayLynxBindCardBizScenceRechargeBindCardAndPay:
            return @"balance_recharge";
        case CJPayLynxBindCardBizScenceBalanceWithdraw:
        case CJPayLynxBindCardBizScenceWithdrawBindCardAndPay:
            return @"balance_withdraw";
        default:
            break;
    }
    return nil;
}

- (NSString *)p_cardTradeScene:(CJPayLynxBindCardBizScence)bizScence {
    switch (bizScence) {
        case CJPayLynxBindCardBizScenceBalanceRecharge:
        case CJPayLynxBindCardBizScenceBalanceWithdraw:
        case CJPayLynxBindCardBizScenceRechargeBindCardAndPay:
        case CJPayLynxBindCardBizScenceWithdrawBindCardAndPay:
            return @"union_bind";
        case CJPayLynxBindCardBizScenceTTPayOnlyBind:
        case CJPayLynxBindCardBizScenceECLargePay:
        case CJPayLynxBindCardBizScenceSignPay:
        case CJPayLynxBindCardBizScenceSignPayDetail:
            return @"zg_bindcard";
        case CJPayLynxBindCardBizScenceBdpayCashier:
        case CJPayLynxBindCardBizScenceIntegratedCashier:
        case CJPayLynxBindCardBizScencePreStandardPay:
        case CJPayLynxBindCardBizScenceQuickPay:
        case CJPayLynxBindCardBizScenceECCashier:
        case CJPayLynxBindCardBizScenceOuterDypay:
            return @"pay";
        default:
            break;
    }
    return @"";
}

- (NSString *)p_teaSource:(CJPayLynxBindCardBizScence)bizScence {
    switch (bizScence) {
        case CJPayLynxBindCardBizScenceBalanceRecharge:
        case CJPayLynxBindCardBizScenceRechargeBindCardAndPay:
            return @"balance_recharge";
        case CJPayLynxBindCardBizScenceBalanceWithdraw:
        case CJPayLynxBindCardBizScenceWithdrawBindCardAndPay:
            return @"balance_withdraw";
        case CJPayLynxBindCardBizScenceTTPayOnlyBind:
        case CJPayLynxBindCardBizScenceSignPayDetail:
            return @"ttpay_only_bind";
        case CJPayLynxBindCardBizScenceBdpayCashier:
            return @"bdpay_cashier";
        case CJPayLynxBindCardBizScenceIntegratedCashier:
            return @"integrated_cashier";
        case CJPayLynxBindCardBizScencePreStandardPay:
            return @"pre_standard_pay";
        case CJPayLynxBindCardBizScenceQuickPay:
            return @"quick_pay";
        case CJPayLynxBindCardBizScenceSignPay:
            return @"sign_pay";
        case CJPayLynxBindCardBizScenceOuterDypay:
            return @"outer_dypay";
        case CJPayLynxBindCardBizScenceECLargePay:
            return @"large_amount";
        default:
            break;
    }
    return @"";
}

- (void)pushVC:(UIViewController *)vc commonModel: (CJPayBindCardSharedDataModel *)bindCardCommonModel {
    if (!bindCardCommonModel.useNavVC) {
        bindCardCommonModel.useNavVC = [self p_presentNavVCWithRootVC:vc fromVC:bindCardCommonModel.referVC ? : [UIViewController cj_topViewController]];
    } else {
        [bindCardCommonModel.useNavVC pushViewController:vc animated:YES];
    }
}

- (CJPayNavigationController *)p_presentNavVCWithRootVC:(UIViewController *)rootVC fromVC:(UIViewController *)fromVC{
    CJPayNavigationController *navVC;
    if ([rootVC isKindOfClass:CJPayBaseViewController.class]) {
        navVC = [(CJPayBaseViewController *)rootVC presentWithNavigationControllerFrom:fromVC useMask:YES completion:nil];
    } else {
        navVC = [CJPayNavigationController instanceForRootVC:rootVC];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIViewController cj_foundTopViewControllerFrom:fromVC] presentViewController:navVC animated:YES completion:nil];
        });
    }
    return navVC;
}

- (void)p_track:(NSString *)event params:(NSDictionary *)params {
    NSMutableDictionary *mutableTrackParams = [NSMutableDictionary new];
    [mutableTrackParams addEntriesFromDictionary:[self bindCardTrackerBaseParams]];
    [mutableTrackParams addEntriesFromDictionary:params];
    [CJTracker event:event params:[mutableTrackParams copy]];
}

- (NSString *)p_getTrackSourceWithCommonModel:(CJPayBindCardSharedDataModel *)model {
    if (model.cardBindSource != CJPayCardBindSourceTypeIndependent) {
        return model.frontIndependentBindCardSource;
    }
    
    // CJPayCardBindSourceTypeIndependent
    if (model.independentBindCardType == CJPayIndependentBindCardTypeNative) {
        return [CJPaySettingsManager shared].currentSettings.jhConfig.source;
    } else {
        return @"wallet_bcard_manage";
    }
}

- (void)createNormalOrderAndSendSMSWithModel:(CJPayBankCardModel *)cardModel
                                       appId:(NSString *)appId
                                  merchantId:(NSString *)merchantId {
    NSMutableDictionary *extDic = [NSMutableDictionary new];
    [extDic cj_setObject:cardModel.bankName forKey:@"bank_name"];
    NSDictionary *params = @{
        @"biz_order_type" : @"card_sign",
        @"source" : @"wallet_bcard_manage",
        @"app_id" : CJString(appId),
        @"merchant_id" : CJString(merchantId),
        @"exts": CJString([CJPayCommonUtil dictionaryToJson:extDic])
    };
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleLoading];
    @CJWeakify(self)
    [self p_createNormalOrder:params completion:^(NSError * _Nonnull error, CJPayMemCreateBizOrderResponse * _Nonnull response) {
        @CJStrongify(self)
        if ([response.code hasPrefix:@"GW4009"]) {
            [self gotoThrottleViewController:NO
                                      source:@"绑卡"
                                       appId:appId
                                  merchantId:merchantId];
            [[CJPayLoadingManager defaultService] stopLoading];
            return;
        }
        UIViewController *vc = [UIViewController cj_topViewController];
        if (![response isSuccess]) {
            [CJToast toastText:Check_ValidString(response.msg) ? response.msg : CJPayNoNetworkMessage inWindow:vc.cj_window];
            [[CJPayLoadingManager defaultService] stopLoading];
            return;
        }
        NSDictionary *baseParam = @{
            @"merchant_id":CJString(merchantId),
            @"app_id":CJString(appId)
        };
        [CJPayMemberSendSMSRequest startWithBDPaySendSMSBaseParam:baseParam
                                                         bizParam:[self p_buildULSMSBizParam:response cardModel:cardModel]
                                                       completion:^(NSError * _Nonnull error, CJPaySendSMSResponse * _Nonnull sendSMSResponse) {
            @CJStrongify(self)
            [[CJPayLoadingManager defaultService] stopLoading];
            if (error || ![sendSMSResponse isSuccess]) {
                [CJToast toastText:Check_ValidString(sendSMSResponse.msg) ? sendSMSResponse.msg : CJPayNoNetworkMessage inWindow:vc.cj_window];
                return;
            }
            [self p_verifySMSViewControllerWithResponse:sendSMSResponse
                                               bizOrder:response
                                              cardModel:cardModel
                                              baseParam:baseParam];
        }];
    }];
}

- (void)createNormalOrderAndSendSMS:(NSDictionary *)param {
    NSDictionary *cardInfo = [param cj_dictionaryValueForKey:@"card_info"];
    CJPayBankCardModel *cardModel = [[CJPayBankCardModel alloc] init];
    cardModel.bankName = [cardInfo cj_stringValueForKey:@"bank_name"];
    cardModel.bankCardId = [cardInfo cj_stringValueForKey:@"bank_card_id"];
    cardModel.cardNoMask = [cardInfo cj_stringValueForKey:@"card_no_mask"];
    cardModel.mobileMask = [cardInfo cj_stringValueForKey:@"mobile_mask"];
    NSString *appId = [param cj_stringValueForKey:@"app_id"];
    NSString *merchantId = [param cj_stringValueForKey:@"merchant_id"];
    [self createNormalOrderAndSendSMSWithModel:cardModel appId:appId merchantId:merchantId];
}

- (NSDictionary *)p_buildULSMSBizParam:(CJPayMemCreateBizOrderResponse *)response cardModel:(CJPayBankCardModel *)cardModel {
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    [bizContentParams cj_setObject:response.signCardMap.memberBizOrderNo forKey:@"sign_order_no"];
    [bizContentParams cj_setObject:response.signCardMap.smchId forKey:@"smch_id"];
    [bizContentParams cj_setObject:cardModel.bankCardId forKey:@"bank_card_id"];
    //后续需加密处理
    NSMutableDictionary *encParams = [NSMutableDictionary dictionary];
    [encParams cj_setObject:cardModel.cardNoMask forKey:@"card_no"];
    [bizContentParams cj_setObject:encParams forKey:@"enc_params"];
    
    return bizContentParams;
}

- (void)gotoThrottleViewController:(BOOL)needRemoveSelf
                            source:(NSString *)source
                             appId:(NSString *)appId
                        merchantId:(NSString *)merchantId {
    CJPayExceptionViewController *throtterVC = [[CJPayExceptionViewController alloc] initWithMainTitle:CJPayLocalizedStr(@"系统拥挤") subTitle:CJPayLocalizedStr(@"排队人数太多了，请休息片刻后再试") buttonTitle:CJPayLocalizedStr(@"知道了")];
    throtterVC.appId = appId;
    throtterVC.merchantId = merchantId;
    throtterVC.source = source;
    UIViewController *vc = [UIViewController cj_topViewController];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (needRemoveSelf && [vc.navigationController isKindOfClass:CJPayNavigationController.class]) {
            CJPayNavigationController *navi = (CJPayNavigationController *)vc.navigationController;
            [navi pushViewControllerSingleTop:throtterVC animated:YES completion:nil];
        } else {
            [vc.navigationController pushViewController:throtterVC animated:YES];
        }
    });
}

- (void)p_verifySMSViewControllerWithResponse:(CJPaySendSMSResponse *)response
                                     bizOrder:(CJPayMemCreateBizOrderResponse *)bizOrderResponse
                                    cardModel:(CJPayBankCardModel *)cardModel
                                    baseParam:(NSDictionary *)baseParam {
    CJPayHalfSignCardVerifySMSViewController *verifySMSVC = [CJPayHalfSignCardVerifySMSViewController new];
    verifySMSVC.viewModel = [CJPayHalfSignCardVerifySMSViewModel new];
    verifySMSVC.viewModel.signOrderNo = bizOrderResponse.signCardMap.memberBizOrderNo;
    verifySMSVC.viewModel.bindUnionCardType = CJPayBindUnionCardTypeSignCard;
    verifySMSVC.ulBaseReqquestParam = baseParam;
    verifySMSVC.sendSMSResponse = response;
    verifySMSVC.sendSMSBizParam = [self p_buildULSMSBizParam:bizOrderResponse cardModel:cardModel];
    if (!CJ_Pad) {
        [verifySMSVC useCloseBackBtn];
    }
    
    CJPayVerifySMSHelpModel *helpModel = [CJPayVerifySMSHelpModel new];
    helpModel.cardNoMask = cardModel.cardNoMask;
    helpModel.frontBankCodeName = cardModel.bankName;
    helpModel.phoneNum = cardModel.mobileMask;

    verifySMSVC.helpModel = helpModel;
    verifySMSVC.animationType = HalfVCEntranceTypeFromBottom;
    [verifySMSVC showMask:YES];
    verifySMSVC.needShowProtocol = YES;
    @CJWeakify(self)
    @CJWeakify(cardModel)
    verifySMSVC.completeBlock = ^(BOOL success, NSString * _Nonnull content) {
        @CJStrongify(self)
        @CJStrongify(cardModel)
        if (success) {
            if ([CJPayBindCardManager sharedInstance].verifySMSCompletionBlock) {
                CJ_CALL_BLOCK([CJPayBindCardManager sharedInstance].verifySMSCompletionBlock);
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:CJPayCardsManageSMSSignSuccessNotification object:CJString(cardModel.bankCardId)];
            }
        }
    };
    UIViewController *vc = [UIViewController cj_topViewController];
    if (![vc isKindOfClass:CJPayBaseViewController.class]) {
        CJPayNavigationController* navVC = [CJPayNavigationController instanceForRootVC:verifySMSVC];
        navVC.modalPresentationStyle = UIModalPresentationCustom;
        dispatch_async(dispatch_get_main_queue(), ^{
            [vc presentViewController:navVC animated:YES completion:nil];
        });
        return;
    }
    
    [vc.navigationController pushViewController:verifySMSVC animated:YES];
}

- (void)p_createNormalOrder:(NSDictionary *)params completion:(void (^)(NSError * _Nonnull error, CJPayMemCreateBizOrderResponse * _Nonnull response))completion {
    @CJWeakify(self)
    [CJPayMemCreateBizOrderRequest startWithBizParams:params completion:^(NSError * _Nonnull error, CJPayMemCreateBizOrderResponse * _Nonnull response) {
        @CJStrongify(self)
        CJ_CALL_BLOCK(completion, error, response);
    }];
}

#pragma mark - getter

- (NSString *)geckoAccessKey {
    _geckoAccessKey = @"5fb33cde3ebff01c8433ddc22aac0816";
    return _geckoAccessKey;
}

@end

#pragma mark - service
@interface CJPayBindCardManager(ModuleSupport)<CJPayCardManageModule>
@property (nonatomic, strong) id<CJPayAPIDelegate> delegate;

@end

@implementation CJPayBindCardManager(ModuleSupport)

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(sharedInstance), CJPayCardManageModule)
})

- (void)setDelegate:(id<CJPayAPIDelegate>)delegate {
    objc_setAssociatedObject(self, @selector(setDelegate:), delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<CJPayAPIDelegate>)delegate {
    return (id<CJPayAPIDelegate>)objc_getAssociatedObject(self, @selector(setDelegate:));
}

#pragma - mark wake by scheme
- (BOOL)openPath:(NSString *)path withParams:(NSDictionary *)params {
    NSString *merchantID = [params cj_stringValueForKey:@"merchant_id"];
    NSString *appID = [params cj_stringValueForKey:@"app_id"];
    merchantID.cjpay_referViewController = params.cjpay_referViewController;
    if ([path isEqualToString:@"bankcardlist"]) {
        if(!CJ_OBJECT_WITH_PROTOCOL(CJPayMyBankCardPlugin)) {
            NSString *lynxSchema = @"sslocal://webcast_lynxview?url=https%3A%2F%2Flf-webcast-sourcecdn-tos.bytegecko.com%2Fobj%2Fbyte-gurd-source%2F10181%2Fgecko%2Fresource%2Fcaijing_native_lynx%2Fmybankcard%2Frouter%2Ftemplate.js&hide_loading=1&show_error=1&trans_status_bar=1&hide_nav_bar=1&web_bg_color=transparent&width_percent=100&height_percent=100&open_animate=1&mask_alpha=0.1&gravity=center&mask_click_disable=0&top_level=1&host=aweme&engine_type=new&page_name=my_bank_card";//线上兜底
            CJPayLynxSchemaConfig *model = [CJPaySettingsManager shared].currentSettings.lynxSchemaConfig;
            if (Check_ValidString(model.myBankCard)) {
                lynxSchema = model.myBankCard;
            }
            NSString *theme = @"light";
            if ([[CJ_OBJECT_WITH_PROTOCOL(CJPayThemeModeService) i_themeModeStr] isEqualToString:@"dark"]) {
                theme = @"dark";
            }
            NSMutableDictionary *shcemaParams = [[NSMutableDictionary alloc] initWithDictionary:@{
                @"merchant_id" : CJString(merchantID),
                @"app_id" : CJString(appID),
                @"theme" : theme,
                @"status_bar_color" : [theme isEqualToString:@"dark"] ? @"white" : @"black",
                @"web_bg_color" : [theme isEqualToString:@"dark"] ? @"#161823" : @"#FFFFFF"
            }];
            NSDictionary *originParams = [[params cj_stringValueForKey:CJPayRouterParameterURL] cj_urlQueryParams];
            [shcemaParams addEntriesFromDictionary:originParams];
            NSString *schema = [CJPayCommonUtil appendParamsToUrl:lynxSchema params:shcemaParams];
            [CJPayDeskUtil openLynxPageBySchema:schema completionBlock:^(CJPayAPIBaseResponse * _Nonnull response) {}];
            return YES;
        }
        [self p_openBankCardListWithMerchantId:merchantID
                                         appId:[params cj_stringValueForKey:@"app_id"]
                                        userId:[params cj_stringValueForKey:@"uid"]
                                  inheritTheme:[params cj_stringValueForKey:@"inherit_theme"]];
        return YES;
    } else if ([path isEqualToString:@"quickbindsign"]) {
        BOOL lynxBind = [self p_miroQuickBindCardCallBackForLynx:@"1" schema:[params cj_stringValueForKey:CJPayRouterParameterURL]];
        if (!lynxBind && CJ_OBJECT_WITH_PROTOCOL(CJPayNativeBindCardPlugin)) {
            [self p_miroQuickBindCardSuccessWithParams:params];
        }
        return YES;
    } else if ([path isEqualToString:@"bindcardpage"]) {
        BOOL lynxBind = [self p_miroQuickBindCardCallBackForLynx:@"0" schema:[params cj_stringValueForKey:CJPayRouterParameterURL]];
        if (!lynxBind && CJ_OBJECT_WITH_PROTOCOL(CJPayNativeBindCardPlugin)) {
            [self p_miroQuickBindCardFailWithParams:params];
        }
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)p_miroQuickBindCardCallBackForLynx:(NSString *)isSuccess schema:(NSString *)schema {
    NSDictionary *dict = [CJPayKVContext kv_valueForKey:CJPayMicroappBindCardCallBack];
    [CJPayKVContext kv_setValue:@{} forKey:CJPayMicroappBindCardCallBack];
    NSString *callBackId = [dict cj_stringValueForKey:@"callBackId"];
    CJPayAPIBaseResponse *response = [CJPayAPIBaseResponse new];
    response.scene = CJPaySceneLynxBindCardCallMiniApp;
    response.data = @{@"code":CJString(isSuccess),
                      @"schema":CJString(schema)};
    NSString *lynxScheme = [CJPaySettingsManager shared].currentSettings.bindcardLynxUrl;
    if ((Check_ValidString(lynxScheme)) && Check_ValidString(callBackId)) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayUniversalPayDeskService) i_callBackWithCallBackId:callBackId response:response];
        return YES;
    }
    return NO;
}

#pragma mark - CJPayCardManageModule
- (void)i_openBankCardListWithMerchantId:(NSString *)merchantId appId:(NSString *)appId userId:(NSString *)userId
{
    [self openBankCardListWithMerchantId:merchantId appId:appId userId:userId];
}

- (void)i_bindCardAndPay:(CJPayBindCardSharedDataModel *)commonModel {
    [self bindCardWithCommonModel:commonModel];
}

- (BOOL)wakeByUniversalPayDesk:(NSDictionary *)dictionary withDelegate:(id<CJPayAPIDelegate>)delegate {
    [self p_bindCardWithParams:dictionary withDelegate:delegate];
    return YES;
}

- (void)i_bindCardWithParams:(NSDictionary *)params withDelegate:(id<CJPayAPIDelegate>)delegate {
    
    NSString *appId = [params cj_stringValueForKey:@"app_id"];
    NSString *merchantId = [params cj_stringValueForKey:@"merchant_id"];
    
    if (!Check_ValidString(appId) || !Check_ValidString(merchantId)) {
        if ([delegate respondsToSelector:@selector(callState:fromScene:)]) {
            [delegate callState:NO fromScene:CJPaySceneBindCard];
        }
        [self p_callBackWithBindCardResultType:CJPayBindCardResultFail message:@"请求参数错误"];
        return;
    }
    [CJPayPerformanceMonitor trackAPIStartWithAPIScene:CJPayPerformanceAPISceneBindCardKey extra:@{}];
    [self p_bindCardWithParams:params withDelegate:delegate];
}

- (void)p_bindCardWithParams:(NSDictionary *)params withDelegate:(id<CJPayAPIDelegate>)delegate {
    NSString *appId = [params cj_stringValueForKey:@"app_id"];
    NSString *merchantId = [params cj_stringValueForKey:@"merchant_id"];
    
    if (!Check_ValidString(appId) || !Check_ValidString(merchantId)) {
        if ([delegate respondsToSelector:@selector(callState:fromScene:)]) {
            [delegate callState:NO fromScene:CJPaySceneBindCard];
        }
        [self p_callBackWithBindCardResultType:CJPayBindCardResultFail message:@"请求参数错误"];
        [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneBindCardKey extra:@{}];
        return;
    }
    @CJWeakify(self)
    self.delegate = delegate;
    __block CJPayBindCardController *bindCardController = [CJPayBindCardController new];
    [bindCardController startBindCardWithParams:params completion:^(CJPayBindCardResult type, NSString * _Nonnull errorMsg) {
        @CJStrongify(self)
        [self p_callBackWithBindCardResultType:type message:errorMsg];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            bindCardController = nil;
        });
        [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneBindCardKey extra:@{}];
    }];

}

- (void)p_callBackWithBindCardResultType:(CJPayBindCardResult )resultType message:(NSString *)errorMsg {
    
    CJPayErrorCode errorCode = CJPayErrorCodeFail;
    switch (resultType) {
        case CJPayBindCardResultSuccess:
            errorCode = CJPayErrorCodeSuccess;
            break;
        case CJPayBindCardResultFail:
            errorCode = CJPayErrorCodeFail;
            break;
        case CJPayBindCardResultCancel:
            errorCode = CJPayErrorCodeCancel;
            break;;
        default:
            errorCode = CJPayErrorCodeUnknown;
            break;
    }
    
    CJPayAPIBaseResponse *apiResponse = [CJPayAPIBaseResponse new];
    apiResponse.scene = CJPaySceneBindCard;
    apiResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(CJString(errorMsg), nil)}];
    apiResponse.data = @{
        @"sdk_code": @(errorCode),
        @"sdk_msg": CJString(errorMsg)
    };
    
    if([self.delegate respondsToSelector:@selector(onResponse:)]) {
        [self.delegate onResponse:apiResponse];
    }
    self.delegate = nil;
}

@end

@implementation CJPayBindCardManager (bindCardInner)

- (CJPayJHInformationConfig *)getJHConfig {
    CJPayJHInformationConfig *jhConfig = [CJPaySettingsManager shared].currentSettings.jhConfig;
    if (!jhConfig) {
        jhConfig = [CJPayJHInformationConfig new];
        jhConfig.jhMerchantId = @"1200003766";
        jhConfig.jhAppId = @"800037665481";
        jhConfig.source = @"wallet_bcard_manage_add";
        jhConfig.teaSourceNtv = @"wallet_bcard_manage_add_ntv";
        jhConfig.teaSourceLynx = @"wallet_bcard_manage_add_lynx";
        [CJPaySettingsManager shared].currentSettings.jhConfig = jhConfig;
    }
    return jhConfig;
}

- (void)setEntryName:(NSString *)entryName {
    if (!_entryName && Check_ValidString(entryName)) {
        _entryName = entryName;
    }
}

- (void)enterUnionBindCardAndCreateOrderWithFromVC:(UIViewController *)fromVC
                                   completionBlock:(nonnull void (^)(BOOL isOpenedSuccess, UIViewController *firstVC))completionBlock {
    
    if(CJ_OBJECT_WITH_PROTOCOL(CJPayUnionBindCardPlugin)) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayUnionBindCardPlugin) createUnionOrderWithBindCardModel:self.bindCardCommonModel fromVC:fromVC completionBlock:completionBlock];
    }
    else {
        [CJToast toastText:@"不支持云闪付绑卡" inWindow:fromVC.cj_window];
        CJ_CALL_BLOCK(completionBlock, NO, nil);
    }
}

- (UIViewController *)openPage:(CJPayBindCardPageType)pageType
          params:(nullable NSDictionary *)extraParams
      completion:(nullable void(^)(BOOL isOpenedSuccessed, NSString *errMsg))completionBlock {
    CJPayBindCardSharedDataModel *commonModel = self.bindCardCommonModel;
    // 根据 type 获取页面所需要的参数
    Class cls = [self p_pageClassByType:pageType];
    if (cls == nil) {
        CJ_CALL_BLOCK(completionBlock, NO, @"根据 type 未找到对应的页面");
        return nil;
    }
    if (![cls conformsToProtocol:@protocol(CJPayBindCardPageProtocol)]) {
        CJ_CALL_BLOCK(completionBlock, NO, @"页面未实现 CJPayBindCardPageProtocal 协议");
        return nil;
    }
    
    Class modelClass = [cls associatedModelClass];
    if (![modelClass conformsToProtocol:@protocol(CJPayBindCardPageModelProtocol)]) {
        CJ_CALL_BLOCK(completionBlock, NO, @"页面 model 未实现 CJPayBindCardPageModelProtocol 协议");
        return nil;
    }
    NSArray *defaultParamsKeys = [modelClass keysOfParams];
    NSDictionary *defaultParams = [self p_genDictionaryByKeys:defaultParamsKeys fromCommonModel:commonModel];
    
    // 传递 params 创建页面
    NSMutableDictionary *combinedParams = [NSMutableDictionary new];
    if (defaultParams.count > 0) {
        [combinedParams addEntriesFromDictionary:defaultParams];
    }
    if (extraParams.count > 0) {
        [combinedParams addEntriesFromDictionary:extraParams];
    }
    
    // push 页面
    UIViewController<CJPayBindCardPageProtocol> *vc = [cls new];
    [vc createAssociatedModelWithParams:combinedParams];
    [self pushVC:vc commonModel:commonModel];
    
    // call completionBlock
    CJ_CALL_BLOCK(completionBlock, YES, nil);
    return vc;
}

- (void)modifySharedDataWithDict:(NSDictionary <NSString *, id>*)dict
                      completion:(nullable void(^)(NSArray <NSString *> *modifyedKeysArray))modifyedCompletionBlock {
    if (dict.count <= 0) {
        CJ_CALL_BLOCK(modifyedCompletionBlock, nil);
    }
    
    CJPayBindCardSharedDataModel *commonModel = self.bindCardCommonModel;

    if (commonModel == nil) {
        CJ_CALL_BLOCK(modifyedCompletionBlock, nil);
    }
    
    NSMutableArray *retArray = [NSMutableArray new];
    NSError *error;
    [commonModel mergeFromDictionary:dict useKeyMapping:YES error:&error];
    CJPayLogAssert((error == nil), @"修改 shared data 失败.");
    
    // 校验修改 common model 是否成功
    NSDictionary *allSharedDataDict = [commonModel toDictionary];
    NSArray *neededModifyKeys = [dict allKeys];
    [neededModifyKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([allSharedDataDict.allKeys containsObject:obj]) {
            [retArray btd_addObject:obj];
        }
    }];
    
    CJPayLogAssert((retArray.count == neededModifyKeys.count), @"修改 shared data 失败.");

    CJ_CALL_BLOCK(modifyedCompletionBlock, retArray);
}

- (BOOL)cancelBindCard {
    if(!self.bindCardCommonModel) {
        return NO;
    }
    CJPayBindCardSharedDataModel *commonModel = self.bindCardCommonModel;
    self.bindCardCommonModel = nil;
    
    UINavigationController *nav = commonModel.useNavVC;
    if (nav.presentingViewController) {
        [nav.presentingViewController dismissViewControllerAnimated:YES completion:^{
            if (commonModel.completion) {
                CJPayBindCardResultModel *resultModel = [CJPayBindCardResultModel new];
                resultModel.result = CJPayBindCardResultCancel;
                commonModel.completion(resultModel);
            }
        }];
        return YES;
    } else {
        // nsassert TODO: xutianxi
        return NO;
    }
    
    if (commonModel.completion) {
        CJPayBindCardResultModel *resultModel = [CJPayBindCardResultModel new];
        resultModel.result = CJPayBindCardResultCancel;
        commonModel.completion(resultModel);
    }

    return YES;
}

- (BOOL)finishBindCard:(CJPayBindCardResultModel *)resultModel completionBlock:(void(^)(void))completionBlock {
    if (!self.bindCardCommonModel) {
        return NO;
    }
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    double currentTimestamp = [date timeIntervalSince1970] * 1000;
    [self p_track:@"wallet_rd_custom_scenes_time" params:@{
        @"scenes_name" : @"绑卡",
        @"sub_section" : @"完成绑卡",
        @"time" : @(currentTimestamp - self.bindCardCommonModel.firstStepVCTimestamp)
    }];
    
    if ([self p_shouldOpenResultPageWithResultModel:resultModel]) {
        [self p_openResultPage:resultModel completionBlock:completionBlock];
        return YES;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ //延时作用，避免loading未完全关闭导致转场冲突，待loading切成window后可删除延时
        [self p_finishBindCard:resultModel completionBlock:completionBlock];
    });
    return YES;
}

- (BOOL)p_shouldOpenResultPageWithResultModel:(CJPayBindCardResultModel *)resultModel {
    if (resultModel.isSyncUnionCard) {
        return NO;
    }
    return resultModel.result == CJPayBindCardResultSuccess &&
    self.bindCardCommonModel.cardBindSource == CJPayCardBindSourceTypeIndependent &&
    self.bindCardCommonModel.independentBindCardType == CJPayIndependentBindCardTypeNative &&
    Check_ValidString(self.bindCardCommonModel.endPageUrl);
}

- (void)p_openResultPage:(CJPayBindCardResultModel *)resultModel completionBlock:(void(^)(void))completionBlock{
    NSString *url = self.bindCardCommonModel.endPageUrl;
    if (!Check_ValidString(url)) {
        return;
    }
    
    CJPayJHInformationConfig *jhConfig = [CJPaySettingsManager shared].currentSettings.jhConfig;
    
    NSString *scheme = [CJPayCommonUtil appendParamsToUrl:url params:@{
        @"merchant_id": CJString(self.bindCardCommonModel.merchantId),
        @"app_id": CJString(self.bindCardCommonModel.appId),
        @"jh_merchant_id": CJString(jhConfig.jhMerchantId),
        @"jh_app_id": CJString(jhConfig.jhAppId),
        @"platform_source": @"native",
        @"source": CJString(jhConfig.source),
        @"tea_source": CJString(jhConfig.teaSourceNtv),
        @"bank_name": CJString(resultModel.bankCardInfo.bankName),
        @"bank_type": CJString(resultModel.bankCardInfo.cardType),
        @"member_biz_order_no": CJString(resultModel.memberBizOrderNo),
        @"is_authed": CJString(self.bindCardCommonModel.userInfo.authStatus),
        @"is_set_pwd": CJString(self.bindCardCommonModel.userInfo.pwdStatus),
        @"quickbind": self.bindCardCommonModel.isQuickBindCard ? @"1" : @"0",
    }];
    
    NSMutableDictionary *param = [NSMutableDictionary new];
    NSMutableDictionary *sdkInfo = [NSMutableDictionary new];
    [sdkInfo cj_setObject:scheme forKey:@"schema"];
    [param cj_setObject:@(98) forKey:@"service"];
    [param cj_setObject:sdkInfo forKey:@"sdk_info"];
    
    @CJWeakify(self)
    CJPayAPICallBack *apiCallback = [[CJPayAPICallBack alloc] initWithCallBack:^(CJPayAPIBaseResponse *response) {
        @CJStrongify(self)
        NSDictionary *callbackData = response.data;
        if (![callbackData isKindOfClass:NSDictionary.class]) {
            return;
        }
        
        NSDictionary *data = [callbackData cj_dictionaryValueForKey:@"data"];
        if (![data isKindOfClass:NSDictionary.class]) {
            return;
        }
        
        NSDictionary *msg = [data cj_dictionaryValueForKey:@"msg"];
        if (![msg isKindOfClass:NSDictionary.class]) {
            return;
        }
        
        NSInteger code = [msg cj_integerValueForKey:@"code"];
        NSString *process = [msg cj_stringValueForKey:@"process"];
        if (code == 0 && [process isEqualToString:@"bind_card_open_account"]) {
            [self p_finishBindCard:resultModel completionBlock:completionBlock];
        }
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [CJ_OBJECT_WITH_PROTOCOL(CJPayUniversalPayDeskService) i_openUniversalPayDeskWithParams:param referVC:self.bindCardCommonModel.useNavVC.presentingViewController withDelegate:apiCallback];
    });
}

- (BOOL)p_finishBindCard:(CJPayBindCardResultModel *)resultModel completionBlock:(void(^)(void))completionBlock {
    if (resultModel.result == CJPayBindCardResultSuccess) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CJPayBindCardSuccessPreCloseNotification object:nil];
    }

    CJPayBindCardSharedDataModel *commonModel = self.bindCardCommonModel;
    self.bindCardCommonModel = nil;
    
    UIViewController *bindCardOriginalVC = commonModel.useNavVC.presentingViewController;
    if (bindCardOriginalVC) {
        [bindCardOriginalVC dismissViewControllerAnimated:commonModel.dismissProcessAnimated
                                               completion:^{
            // 回调给外层绑卡结果
            if (commonModel.completion) {
                commonModel.completion(resultModel);
                CJ_CALL_BLOCK(completionBlock);
            }
        }];
    } else if (resultModel.isLynxBindCard) {
        if (commonModel.completion) {
            commonModel.completion(resultModel);
            CJ_CALL_BLOCK(completionBlock);
        }
    } else {
        CJPayLogError(@"bind card finish. bindCardOriginalVC is null.")
    }
    
    
    return YES;
}

// track event
- (NSDictionary *)bindCardTrackerBaseParams {
    return [self p_getBindCardTrackerBaseParamWithCommonModel:self.bindCardCommonModel];
}

- (NSString *)bindCardTrackerSource {
    return [self p_getTrackSourceWithCommonModel:self.bindCardCommonModel];
}

/// 绑卡来源，目前仅支持充值提现
- (NSString *)bindCardTeaSource {
    switch (self.bindCardCommonModel.cardBindSource) {
        case CJPayCardBindSourceTypeBalanceRecharge:
            return @"balance_recharge";
        case CJPayCardBindSourceTypeBalanceWithdraw:
            return @"balance_withdraw";
        default:
            break;
    }
    return @"";
}

- (NSDictionary *)p_getBindCardTrackerBaseParamWithCommonModel:(CJPayBindCardSharedDataModel *)commonModel {
    NSString *needIdentify = [commonModel.userInfo.authStatus isEqualToString:@"1"] ? @"0" : @"1";
    NSString *hasPass = [commonModel.userInfo.pwdStatus isEqualToString:@"0"] ? @"0" : @"1";
    
    BOOL isShowMaskPhoneNum = Check_ValidString(commonModel.bankMobileNoMask) && [commonModel.userInfo hasValidAuthStatus];
    BOOL isShowAuthPhoneNum = Check_ValidString(commonModel.userInfo.uidMobileMask) && !Check_ValidString(commonModel.userInfo.mobile);
    BOOL isShowPhone = isShowAuthPhoneNum || isShowMaskPhoneNum;
    
    NSDictionary * bindCardBaseDic = @{@"app_id" : CJString(commonModel.appId),
                                       @"merchant_id" : CJString(commonModel.merchantId),
                                       @"is_chaselight" : @"1",
                                       @"needidentify" : CJString(needIdentify),
                                       @"haspass" : CJString(hasPass),
                                       @"is_onestep" : commonModel.isQuickBindCard ? @"1" : @"0",
                                       @"is_auth" : commonModel.bizAuthInfoModel.isNeedAuthorize ? @"1" : @"0",
                                       @"is_showphone" : isShowPhone ? @"1" : @"0",
                                       @"source" : CJString([self p_getTrackSourceWithCommonModel:commonModel]),
                                       @"process_id": CJString(commonModel.processInfo.processId),
                                       @"addbcard_type" : commonModel.bindUnionCardType == CJPayBindUnionCardTypeBindAndSign || commonModel.bindUnionCardType == CJPayBindUnionCardTypeSyncBind ? @"云闪付" : @"",
                                       @"activity_info" : [commonModel.quickBindCardModel activityInfoWithCardType:commonModel.quickBindCardModel.cardType] ?: @[],
                                       @"entry_name" : CJString(self.entryName)
    };
    
    NSMutableDictionary *paramDic = [[NSMutableDictionary alloc] initWithDictionary:bindCardBaseDic];
    [paramDic addEntriesFromDictionary:commonModel.trackerParams];
    return paramDic;
}

- (NSDictionary *)p_genDictionaryByKeys:(NSArray <NSString *>*)keys fromCommonModel:(CJPayBindCardSharedDataModel *)commonModel {
    if (keys == nil || keys.count == 0 || commonModel == nil) {
        return nil;
    }
    
    NSDictionary *allSharedDataDict = [commonModel toDictionary];
    NSMutableDictionary *returnDict = [NSMutableDictionary new];
    [keys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([allSharedDataDict cj_objectForKey:key]) {
            [returnDict cj_setObject:[allSharedDataDict cj_objectForKey:key] forKey:key];
        }
    }];
    
    return [returnDict copy];
}

- (Class)p_pageClassByType:(CJPayBindCardPageType)type {
    Class cls = [[self p_pageTypeMaps] btd_objectForKey:@(type) default:nil];
    return cls;
}

// 映射 page type 与 page viewController
- (void)addPageTypeMaps:(NSDictionary *)dictionary {
    [self.pageTypes addEntriesFromDictionary:dictionary];
}

- (NSDictionary *)p_pageTypeMaps {
    NSDictionary *map = [NSDictionary dictionaryWithDictionary:self.pageTypes];
    return map;
}

- (NSMutableDictionary *)pageTypes {
    if(!_pageTypes) {
        _pageTypes = [NSMutableDictionary new];
        [_pageTypes addEntriesFromDictionary:@{
                @(CJPayBindCardPageTypeQuickAuthVerify) : [CJPayAuthVerifyViewController class],
                @(CJPayBindCardPageTypeHalfBizAuth) : [CJPayBizAuthViewController class],
                @(CJPayBindCardPageTypeHalfVerifySMS) : [CJPayHalfSignCardVerifySMSViewController class],
                @(CJPayBindCardPageSetPWDFirstStep) : [CJPayPasswordSetFirstStepViewController class]
        }];
    }
    return _pageTypes;
}

// copy new common model

@end
