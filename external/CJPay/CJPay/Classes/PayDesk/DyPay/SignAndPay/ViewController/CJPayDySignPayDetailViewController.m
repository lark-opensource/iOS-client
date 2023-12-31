//
//  CJPayDySignPayDetailViewController.m
//  CJPaySandBox
//
//  Created by ByteDance on 2023/6/28.
//

#import "CJPayDySignPayDetailViewController.h"
#import "CJPaySignPayView.h"
#import "CJPaySignPayModel.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPaySignPayChoosePayMethodManager.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayFrontCashierResultModel.h"
#import "CJPayBindCardManager.h"
#import "CJPayMemBankInfoModel.h"
#import "CJPayDyPayCreateOrderRequest.h"
#import "CJPayLoadingManager.h"
#import "CJPayStyleButton.h"
#import "CJPayDyPayManager.h"
#import "CJPaySignPageInfoModel.h"
#import "CJPayRetainUtil.h"
#import "CJPayRetainInfoV2Config.h"
#import "CJPaySettingsManager.h"
#import "CJPayKVContext.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKDefine.h"

@interface CJPayDySignPayDetailViewController () <CJPaySignPayChoosePayMethodDelegate>

@property (nonatomic, strong) CJPayBDCreateOrderResponse *commonPayResponse;
@property (nonatomic, assign) BOOL isCommonPayResponseNeedReQuery;
@property (nonatomic, strong) CJPayBDCreateOrderResponse *deductPayResponse;
@property (nonatomic, assign) BOOL isDeductPayResponseNeedReQuery;
@property (nonatomic, strong) NSDictionary *allParamsDict; // 请求需要携带的参数
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *defaultConfig; // 已经选中的支付方式, 绑卡流程的话，在重新刷新outpre接口的时候更新defaultConfig;普通切卡流程的话在设置优先付款方式接口回来即更新defaultConfig

@property (nonatomic, strong) CJPaySignPayView *contentView;

@property (nonatomic, strong) CJPaySignPayChoosePayMethodManager *signPayChoosePayMethodManager;

@property (nonatomic, copy) void(^startLoadingBlock)(void);
@property (nonatomic, copy) void(^stopLoadingBlock)(void);

#pragma mark tracker

@property (nonatomic, assign) BOOL isReRenderFromRequest; // 是否刷新了接口

@end

@implementation CJPayDySignPayDetailViewController

- (instancetype)initWithResponse:(CJPayBDCreateOrderResponse *)response allParamsDict:(nonnull NSDictionary *)allParamsDict{
    self = [super init];
    if (self) {
        self.deductPayResponse = response;
        self.allParamsDict = allParamsDict;
        self.defaultConfig = [response.payTypeInfo getDefaultDyPayConfig];
        self.isReRenderFromRequest = NO;
    }
    return self;
}

#pragma mark life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self setupConstraints];
    
    [self p_updateMsg];
    
    [self p_postTrack];
}

#pragma mark - public func

- (void)close {
    if (![self p_showRetain]) {
        // 这里不需要 pop当前页面，调用回调会删除该VC的下层VC
        CJ_CALL_BLOCK(self.clickBackBlock);
    }
}

#pragma mark - private func

- (BOOL)p_showRetain {
    if (![self.contentView obtainSwitchStatus]) {
        // O项目 普通支付不需要挽留
        return NO;
    }
    
    CJPayRetainUtilModel *retainUtilModel = [CJPayRetainUtilModel new];
    retainUtilModel.retainInfo = self.deductPayResponse.retainInfo;
    retainUtilModel.intergratedTradeNo = self.deductPayResponse.tradeInfo.tradeNo;
    retainUtilModel.processInfoDic = [self.deductPayResponse.processInfo dictionaryValue];
    retainUtilModel.intergratedMerchantID = self.deductPayResponse.merchant.merchantId;
    
    if ([self p_buildRetainInfoV2Config:retainUtilModel]) {
        return [self p_lynxRetain:retainUtilModel];
    }
    
    @CJWeakify(self)
    retainUtilModel.closeActionBlock = ^{
        @CJStrongify(self)
        [self close];
    };
    
    return [CJPayRetainUtil couldShowRetainVCWithSourceVC:self.navigationController retainUtilModel:retainUtilModel];
}

- (BOOL)p_lynxRetain:(CJPayRetainUtilModel *)retainUtilModel {
    retainUtilModel.lynxRetainActionBlock = ^(CJPayLynxRetainEventType eventType, NSDictionary * _Nonnull data) {
        switch (eventType) {
            case CJPayLynxRetainEventTypeOnCancelAndLeave: {
                [self close];
                break;
            }
            case CJPayLynxRetainEventTypeOnConfirm: {
                break;
            }
            default:
                break;
        }
    };
    
    return [CJPayRetainUtil couldShowLynxRetainVCWithSourceVC:self.navigationController retainUtilModel:retainUtilModel completion:nil];
}

- (BOOL)p_buildRetainInfoV2Config:(CJPayRetainUtilModel *)retainUtilModel {
    
    if (!Check_ValidDictionary(self.deductPayResponse.retainInfoV2)) {
        return NO;
    }
    NSDictionary *merchantRetainInfo = [self.deductPayResponse.retainInfoV2 cj_dictionaryValueForKey:@"merchant_retain_info"];
    CJPayMerchantInfo *merchantInfo = self.deductPayResponse.merchant;
    
    CJPayRetainInfoV2Config *config = [[CJPayRetainInfoV2Config alloc] init];
    config.retainInfoV2 = self.deductPayResponse.retainInfoV2;
    
    NSString *finalRetainSchema = [CJPayRetainUtil defaultLynxRetainSchema];
    
    NSString *settingsRetainSchema = [CJPaySettingsManager shared].currentSettings.lynxSchemaConfig.keepDialogStandardNew.scheme;
    NSString *merchantRetainSchema = [merchantRetainInfo cj_stringValueForKey:@"lynx_schema"];
    if (Check_ValidString(merchantRetainSchema)) {
        finalRetainSchema = merchantRetainSchema;
    } else if (Check_ValidString(settingsRetainSchema)) {
        finalRetainSchema = settingsRetainSchema;
    }
    
    config.retainSchema = finalRetainSchema;
    config.notShowRetain = (!Check_ValidString(finalRetainSchema));
    config.fromScene = @"sign_and_pay";
    
    config.appId = merchantInfo.appId;
    config.merchantId = merchantInfo.merchantId;
    config.jhMerchantId = merchantInfo.merchantId;
    
    config.templateId = self.deductPayResponse.signPageInfo.templateId;
    
    retainUtilModel.retainInfoV2Config = config;
    
    return YES;
}

- (void)setupUI {
    [self.view addSubview:self.contentView];
}

- (void)setupConstraints {
    CJPayMasMaker(self.contentView, {
        make.top.equalTo(self.view).offset([self navigationHeight]);
        make.left.right.bottom.equalTo(self.view);
    });
}

- (void)p_updateMsg {
    CJPaySignPayModel *model = [[CJPaySignPayModel alloc] initWithResponse:self.deductPayResponse];
    
    @CJWeakify(self)
    self.contentView.confirmBtnClickBlock = ^(CJPayStyleButton * _Nonnull loadingView) {
        @CJStrongify(self)
        [self p_clickConfirmBtn:loadingView];
    };
    
    self.contentView.payMethodClick = ^{
        @CJStrongify(self)
        [self.signPayChoosePayMethodManager gotoSignPayChooseDyPayMethod];
    };
    
    self.contentView.trackerBlock = ^(NSString * _Nonnull eventName, NSDictionary * _Nonnull params) {
        @CJStrongify(self)
        [self trackerWithName:eventName params:params];
    };
    
    [self.contentView updateInitialViewWithSignPayModel:model];
}

// 点击确认按钮的逻辑
- (void)p_clickConfirmBtn:(CJPayStyleButton *)loadingView {
    CJPaySignPageInfoModel *signPageInfo = self.deductPayResponse.signPageInfo;
    [self trackerWithName:@"wallet_withhold_open_open_click" params:@{
        @"template_id" : CJString([self.allParamsDict cj_stringValueForKey:@"template_id"]),
        @"withhold_project" : CJString(signPageInfo.serviceName),
        @"original_amount" : CJString(signPageInfo.tradeAmount),
        @"reduce_amount" : CJString(signPageInfo.realTradeAmount),
        @"button_name" : CJString(signPageInfo.buttonDesc),
    }];
    // 如果目前状态为普通支付的话，不管是默认选择的支付方式是什么，都先拉起收银台。
    @CJWeakify(self)
    self.startLoadingBlock = ^{
        @CJStrongify(self)
        @CJStartLoading(loadingView);
    };
    self.stopLoadingBlock = ^{
        @CJStrongify(self)
        @CJStopLoading(loadingView)
    };
    if ([self.contentView obtainSwitchStatus]) {
        CJPayDefaultChannelShowConfig *config = self.defaultConfig;
        if (config.type == BDPayChannelTypeAddBankCard) {
            //这里设置model 然后进行绑卡
            CJPayBindCardSharedDataModel *model = [self p_buildBindCardSharedDataWithConfig:config];
            //model设置回调
            BOOL enableNativeBindCard = [CJPaySettingsManager shared].currentSettings.nativeBindCardConfig.enableNativeBindCard;
            if (!enableNativeBindCard || [[CJPayBindCardManager sharedInstance] isLynxReady]) {
                [[CJPayBindCardManager sharedInstance] bindCardWithCommonModel:model];
                return;
            }
            
            NSDictionary *params = @{
                @"source" : @"payment_manage",
                @"app_id" : CJString(model.appId),
                @"merchant_id" : CJString(model.merchantId)
            };
            @CJStartLoading(loadingView)
            [[CJPayBindCardManager sharedInstance] onlyBindCardWithCommonModel:model params:params completion:nil stopLoadingBlock:^{
                @CJStopLoading(loadingView)
            }];
        } else {
            if (self.deductPayResponse && !self.isDeductPayResponseNeedReQuery) {
                [self p_openPayDesk];
            } else {
                @CJWeakify(self)
                [self p_refreshPageMessage:YES completion:^(BOOL isRequestSuccess) {
                    @CJStrongify(self)
                    if (isRequestSuccess) {
                        [self p_openPayDesk];
                    }
                }];
            }
        }
        return;
    } else {
        if (self.commonPayResponse && !self.isCommonPayResponseNeedReQuery) {
            [self p_openPayDesk];
        } else {
            @CJWeakify(self)
            [self p_refreshPageMessage:NO completion:^(BOOL isRequestSuccess) {
                @CJStrongify(self)
                if (isRequestSuccess) {
                    [self p_openPayDesk];
                }
            }];
        }
    }
}

- (void)p_openPayDesk {
    NSString *payType = self.contentView.obtainSwitchStatus ? @"deduct": @"";
    NSDictionary *deductParams = @{
        @"is_sign_downgrade" : @(!self.contentView.obtainSwitchStatus)
    };
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.allParamsDict];
    [params cj_setObject:payType forKey:@"pay_type"];
    [params cj_setObject:deductParams forKey:@"deduct_params"];
    
    CJPayBDCreateOrderResponse *response = [self.contentView obtainSwitchStatus] ? self.deductPayResponse : self.commonPayResponse;
    [[CJPayDyPayManager sharedInstance] openDySignPayDesk:params response:response completion:nil];
}

- (CJPayBindCardSharedDataModel *)p_buildBindCardSharedDataWithConfig:(CJPayDefaultChannelShowConfig *)currentConfig {
    CJPayBindCardSharedDataModel *model = [CJPayBindCardSharedDataModel new];
    CJPayMerchantInfo *merchantInfo = self.deductPayResponse.merchant;
    model.merchantId = merchantInfo.merchantId;
    model.jhMerchantId = merchantInfo.intergratedMerchantId;
    model.appId = merchantInfo.appId;
    model.jhAppId = merchantInfo.jhAppId;
    model.lynxBindCardBizScence = CJPayLynxBindCardBizScenceSignPayDetail;
    model.cardBindSource = CJPayCardBindSourceTypeIndependent;
    model.referVC = self;
    model.cjpay_referViewController = self;
    // 这里设置绑卡回调
    @CJWeakify(self)
    model.completion = ^(CJPayBindCardResultModel * _Nonnull resModel) {
        @CJStrongify(self)
        [self trackerWithName:@"wallet_orderqueue_setup_addcard_result" params:@{
            @"result" : resModel.result == CJPayBindCardResultSuccess ? @"1" : @"0"
        }];
        if (resModel.result == CJPayBindCardResultSuccess) {
            //绑卡成功 , 拿着卡信息去设置优先扣款卡 , 然后刷新out_pre...接口，刷新页面
            NSString *payMode = [CJPaySignPayChoosePayMethodManager getPayMode:BDPayChannelTypeBankCard];
            @CJWeakify(self)
            [self p_setMemberFirstPayMethod:payMode bankCardId:resModel.bankCardInfo.bankCardID completion:^(BOOL isSuccess) {
                @CJStrongify(self)
                if (isSuccess) {
                    // 只有绑卡回来的时候会刷新卡列表
                    self.signPayChoosePayMethodManager.needUpdatePayMethodList = YES;
                    [self.signPayChoosePayMethodManager closeSignPayChooseDyPayMethod];
                    self.startLoadingBlock = ^{
                        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading];
                    };
                    self.stopLoadingBlock = ^{
                        [[CJPayLoadingManager defaultService] stopLoading];
                    };
                    self.isCommonPayResponseNeedReQuery = YES;
                    self.isDeductPayResponseNeedReQuery = YES;
                    [self p_refreshPageMessage:YES completion:nil];
                } else {
                    NSString *warningMsg = @"设置优先扣款卡失败";
                    [[CJPayToast sharedToast] toastText:warningMsg inWindow:self.cj_window];
                }
            }];
        } else if (resModel.result == CJPayBindCardResultCancel) {
            //取消绑卡 ， 停在切卡页不动
        } else {
            //绑卡失败 ， 停在切卡页不动，并弹出toast
            [CJToast toastText:@"绑卡失败" inWindow:self.cj_window];
            NSString *failMsg = CJString(resModel.failMsg);
            CJPayLogInfo(failMsg);
        }
    };
    
    NSDictionary *bindCardInfo = @{
        @"bank_code": CJString(currentConfig.frontBankCode),
        @"card_type": CJString(currentConfig.cardType),
        @"card_add_ext": CJString(currentConfig.cardAddExt),
        @"business_scene": CJString([currentConfig bindCardBusinessScene])
    };
    model.bindCardInfo = bindCardInfo;
    
    return model;
}

- (void)p_setMemberFirstPayMethod:(NSString *)payMode bankCardId:(NSString *)bankCardId completion:(void(^)(BOOL isSuccess))completion {
    NSDictionary *bizParams = @{
        @"pay_type_item" : @{
            @"pay_mode" : CJString(payMode),
            @"bank_card_id" : CJString(bankCardId),
        },
        @"app_id" : CJString(self.deductPayResponse.merchant.appId),
        @"merchant_id": CJString(self.deductPayResponse.merchant.merchantId),
    };
    [CJPaySignPayChoosePayMethodManager setMemberFirstPayMethod:bizParams needLoading:YES completion:^(BOOL isSuccess) {
        CJ_CALL_BLOCK(completion, isSuccess);
    }];
}

#pragma mark - CJPayChooseDyPayMethodDelegate
- (void)changePayMethod:(CJPayFrontCashierContext *)payContext loadingView:(UIView *)view {
    CJPayDefaultChannelShowConfig *config = payContext.defaultConfig;
    if (config.type == BDPayChannelTypeAddBankCard) {
        //这里设置model 然后进行绑卡
        CJPayBindCardSharedDataModel *model = [self p_buildBindCardSharedDataWithConfig:config];
        model.referVC = [UIViewController cj_topViewController];
        //model设置回调
        BOOL enableNativeBindCard = [CJPaySettingsManager shared].currentSettings.nativeBindCardConfig.enableNativeBindCard;
        if (!enableNativeBindCard || [[CJPayBindCardManager sharedInstance] isLynxReady]) {
            [[CJPayBindCardManager sharedInstance] bindCardWithCommonModel:model];
            return;
        }
        
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading title:CJPayDYPayTitleMessage];
        NSDictionary *params = @{
            @"source" : @"payment_manage",
            @"app_id" : CJString(model.appId),
            @"merchant_id" : CJString(model.merchantId)
        };
        [[CJPayBindCardManager sharedInstance] onlyBindCardWithCommonModel:model params:params completion:nil stopLoadingBlock:^{
            [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeDouyinLoading];
        }];
    } else {
        // 更新详情页卡片信息
        NSString *payMode = [CJPaySignPayChoosePayMethodManager getPayMode:config.type];
        @CJWeakify(self)
        [self p_setMemberFirstPayMethod:payMode bankCardId:config.bankCardId completion:^(BOOL isSuccess) {
            @CJStrongify(self)
            if (isSuccess) {
                [self.contentView updateDeductMethodView:config buttonTitle:self.deductPayResponse.signPageInfo.buttonDesc];
            } else {
                NSString *warningMsg = @"设置优先扣款卡失败";
                [[CJPayToast sharedToast] toastText:warningMsg inWindow:self.cj_window];
            }
        }];
    }
}

// 刷新out_pre... 接口 更新页面
- (void)p_refreshPageMessage:(BOOL)isRefreshDeductPayResponse completion:(void(^)(BOOL isRequestSuccess))completion {
    self.isReRenderFromRequest = YES;
    
    NSString *merchantId = [self.allParamsDict cj_stringValueForKey:@"partnerid" defaultValue:@""];
    NSMutableDictionary *bizContent = [NSMutableDictionary dictionaryWithDictionary:self.allParamsDict];
    [bizContent cj_setObject:@(![self.contentView obtainSwitchStatus]) forKey:@"is_sign_downgrade"];
    
    NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
    double lastTimestamp = [trackData btd_doubleValueForKey:@"start_time" default:0];
    double durationTime = (lastTimestamp > 100000) ? ([[NSDate date] timeIntervalSince1970] * 1000 - lastTimestamp) : 0;
    [trackData addEntriesFromDictionary:@{@"client_duration":@(durationTime)}];
    [self trackerWithName:@"wallet_cashier_SDK_pull_start" params:trackData];
    
    [self p_startLoading];
    @CJWeakify(self)
    [CJPayDyPayCreateOrderRequest startWithMerchantId:merchantId bizParams:bizContent completion:^(NSError * _Nonnull error, CJPayBDCreateOrderResponse * _Nonnull response) {
        @CJStrongify(self)
        [self p_stopLoading];
        NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
        double lastTimestamp = [trackData btd_doubleValueForKey:@"start_time" default:0];
        double durationTime = (lastTimestamp > 100000) ? ([[NSDate date] timeIntervalSince1970] * 1000 - lastTimestamp) : 0;
        [trackData addEntriesFromDictionary:@{@"client_duration":@(durationTime),
                                              @"error_msg":CJString(response.msg),
                                              @"error_code":CJString(response.code)
                                            }];
        [self trackerWithName:@"wallet_cashier_SDK_pull_result" params:trackData];
        
        BOOL isRequestSuccess = [response isSuccess];
        if (isRequestSuccess) {
            if (isRefreshDeductPayResponse) {
                CJPayDefaultChannelShowConfig *selectedConfig = [response.payTypeInfo getDefaultDyPayConfig];
                // 更新详情页页面,如果开关状态为签约并支付的时候才刷新页面
                self.deductPayResponse = response;
                self.defaultConfig = selectedConfig;
                self.isDeductPayResponseNeedReQuery = NO;
                [self.contentView updateDeductMethodView:selectedConfig buttonTitle:self.deductPayResponse.signPageInfo.buttonDesc];
                self.signPayChoosePayMethodManager.response = response;
            } else {
                self.isCommonPayResponseNeedReQuery = NO;
                self.commonPayResponse = response;
            }
            // 更新切卡页页面
        } else {
            NSString *warningMsg = Check_ValidString(response.msg) ? response.msg : @"网络超时";
            [[CJPayToast sharedToast] toastText:warningMsg inWindow:self.cj_window];
        }
        CJ_CALL_BLOCK(completion, isRequestSuccess);
    }];
}

- (void)p_startLoading {
    CJ_CALL_BLOCK(self.startLoadingBlock);
}

- (void)p_stopLoading {
    CJ_CALL_BLOCK(self.stopLoadingBlock);
}

- (void)trackerWithName:(NSString *)trackerName params:(NSDictionary *)params {
    CJPayBDCreateOrderResponse *response = [self.contentView obtainSwitchStatus] ? self.deductPayResponse : self.commonPayResponse;
    NSString *appId = [self.allParamsDict cj_stringValueForKey:@"app_id"];
    NSString *merchantId = response.merchant.merchantId;
    NSString *prepayId = [self.allParamsDict cj_stringValueForKey:@"prepayid"];
    NSString *tradeNo = response.tradeInfo.tradeNo;
    
    NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
    double durationTime = [[NSDate date] timeIntervalSince1970] * 1000 - [trackData btd_doubleValueForKey:@"start_time" default:0];
    [trackData addEntriesFromDictionary:@{
        @"cashier_style" : [self.contentView obtainSwitchStatus] ? @"1" : @"0",
        @"re_render_from_request" : self.isReRenderFromRequest ? @"1": @"0",
        @"app_id" : CJString(appId),
        @"appid": CJString(appId),
        @"merchant_id" : CJString(merchantId),
        @"prepay_id": CJString(prepayId),
        @"trade_no" : CJString(tradeNo),
        @"is_chaselight" : @"1",
        @"client_duration":@(durationTime)
    }];
    [trackData addEntriesFromDictionary:params];
    
    [CJTracker event:trackerName params:trackData];
}

- (void)p_postTrack {
    CJPayBDCreateOrderResponse *response = [self.contentView obtainSwitchStatus] ? self.deductPayResponse : self.commonPayResponse;
    CJPaySignPageInfoModel *signPageInfo = response.signPageInfo;
    NSString *switchStatus;
    if ([signPageInfo.paySignSwitch isEqualToString:@"none"]) {
        switchStatus = @"0";
    } else if ([signPageInfo.paySignSwitch isEqualToString:@"close"]) {
        switchStatus = @"1";
    } else {
        switchStatus = @"2";
    }
    [self trackerWithName:@"wallet_withhold_open_page_imp" params:@{
        @"template_id" : CJString([self.allParamsDict cj_stringValueForKey:@"template_id"]),
        @"withhold_project" : CJString(signPageInfo.serviceName),
        @"original_amount" : CJString(signPageInfo.tradeAmount),
        @"reduce_amount" : CJString(signPageInfo.realTradeAmount),
        @"button_name" : CJString(signPageInfo.buttonDesc),
        @"payment_switch" : CJString(switchStatus),
        @"activity_title" : CJString(signPageInfo.promotionDesc),
    }];
}

#pragma mark - CJPayChooseDyPayMethodDelegate

- (void)trackEvent:(NSString *)event params:(NSDictionary *)params {
    [self trackerWithName:event params:params];
}

#pragma mark - lazy load

- (CJPaySignPayView *)contentView {
    if (!_contentView) {
        _contentView = [CJPaySignPayView new];
        _contentView.isNewUser = self.deductPayResponse.userInfo.isNewUser;
    }
    return _contentView;
}

- (CJPaySignPayChoosePayMethodManager *)signPayChoosePayMethodManager {
    if (!_signPayChoosePayMethodManager) {
        _signPayChoosePayMethodManager = [[CJPaySignPayChoosePayMethodManager alloc] initWithOrderResponse:self.deductPayResponse];
        _signPayChoosePayMethodManager.delegate = self;
        _signPayChoosePayMethodManager.closeChoosePageAfterChangeMethod = YES;
    }
    return _signPayChoosePayMethodManager;
}

@end
