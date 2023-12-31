//
//  CJPaySignPayViewController.m
//  Pods
//
//  Created by wangxiaohong on 2022/7/8.
//

#import "CJPaySignPayViewController.h"

#import "CJPayUIMacro.h"
#import "CJPayOuterPayUtil.h"
#import "CJPayAlertUtil.h"
#import "CJPayStyleButton.h"
#import "CJPaySignPayQuerySignInfoResponse.h"
#import "CJPaySignPayQuerySignInfoRequest.h"
#import "CJPayCreateOrderByTokenRequest.h"
#import "CJPayCommonTrackUtil.h"
#import "CJPaySignView.h"
#import "CJPayBindCardSharedDataModel.h"
#import "CJPayBindCardManager.h"
#import "CJPayExceptionViewController.h"
#import "CJPayWebViewUtil.h"
#import "CJPayRequestParam.h"
#import "CJPaySignCardListViewController.h"
#import "CJPaySignQueryMemberPayListRequest.h"
#import "CJPaySignQueryMemberPayListResponse.h"
#import "CJPaySignSetMemberFirstPayTypeRequest.h"
#import "CJPaySignSetMemberFirstPayTypeResponse.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayManagerDelegate.h"
#import "CJPaySDKDefine.h"
#import "CJPayLoadingManager.h"
#import "CJPaySettingsManager.h"
#import "CJPayKVContext.h"

@interface CJPaySignPayViewController ()<CJPayAPIDelegate>

@property (nonatomic, strong) CJPaySignView *contentView;
@property (nonatomic, strong) CJPayCreateOrderResponse *orderResponse; // 埋点用

@property (nonatomic, copy) NSString *zg_app_id;
@property (nonatomic, copy) NSString *zg_merchant_id;

@property (nonatomic, strong) CJPayDefaultChannelShowConfig *selectedShowConfig;

@end

@implementation CJPaySignPayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    self.zg_app_id = self.querySignInfo.signTemplateInfo.zgMerchantAppid;
    self.zg_merchant_id = self.querySignInfo.signTemplateInfo.zgMerchantId;
    [self p_trackForPage:@"wallet_withhold_open_page_imp" params:@{}];
}

- (void)back {
    [self p_trackForPage:@"wallet_withhold_open_back_click" params:@{}];
    [self p_closeCashierDeskAndJumpBackWithResult:CJPayDypayResultTypeCancel];
}

- (void)p_setupUI {
    [self.view addSubview:self.contentView];
    
    [self.navigationBar setTitle:CJString(self.querySignInfo.signTemplateInfo.pageTitle)];
    
    CJPayMasMaker(self.contentView, {
        make.top.equalTo(self.view).offset([self navigationHeight]);
        make.left.right.bottom.equalTo(self.view);
    });
    [self.contentView updateWithSignModel:[self.querySignInfo toSignModel]];
}

- (void)p_onConfirmPayAction {
    if (self.querySignInfo.hasBankCard) {
        [self p_openCashDesk];
    } else {
        [self p_bindCard];
    }
}

- (void)p_alertRequestErrorWithMsg:(NSString *)alertText
                       clickAction:(void(^)(void))clickAction {
    [CJPayAlertUtil customSingleAlertWithTitle:alertText content:@"" buttonDesc:CJPayLocalizedStr(@"知道了") actionBlock:^{
        CJ_CALL_BLOCK(clickAction);
    } useVC:self];
}

- (void)p_openCashDesk {
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading title:CJPayDYPayTitleMessage];
    @CJWeakify(self);
    NSDictionary *params = @{@"token": CJString(self.token),
                             @"params":@{@"host_app_name":CJString(self.appName),
                                         @"pay_source": @"sign_and_pay"}};
    [CJPayCreateOrderByTokenRequest startWithBizParams:params
                                             bizUrl:@""
                                         completion:^(NSError * _Nonnull error, CJPayCreateOrderResponse * _Nonnull response) {
        @CJStrongify(self);
        [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeDouyinLoading];
        if (![response isSuccess]) {
            
            [self p_trackerEvent:@"wallet_cashier_douyincashier_result" params:@{
                @"result": @"0",
                @"error_code": CJString(response.code),
                @"error_msg": CJString(response.msg)
            }];
            NSString *alertText = Check_ValidString(response.msg) ? response.msg : CJPayNoNetworkMessage;
            [CJToast toastText:alertText inWindow:self.cj_window];
            return;
        }
        
        self.orderResponse = response;
        [self p_configCashRegisterVCWithBizParams:params];
        
        NSDictionary *loadingParams = [self p_mergeCommonParamsWithDict:@{@"loading_time": [NSString stringWithFormat:@"%f", response.responseDuration]}
                                                                          response:response];
        NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
        double lastTimestamp = [trackData btd_doubleValueForKey:@"start_time" default:0];
        double durationTime = (lastTimestamp > 100000) ? ([[NSDate date] timeIntervalSince1970] * 1000 - lastTimestamp) : 0;
        [trackData addEntriesFromDictionary:@{@"client_duration": @(durationTime)}];
        [trackData addEntriesFromDictionary:loadingParams];
        [self p_trackerEvent:@"wallet_cashier_opendouyin_loading" params:trackData];
        
        NSDictionary *resultParams = [self p_mergeCommonParamsWithDict:@{@"result": @"1"} response:response];
        [self p_trackerEvent:@"wallet_cashier_douyincashier_result" params:resultParams];
    }];
}

- (NSDictionary *)p_mergeCommonParamsWithDict:(NSDictionary *)dict response:(CJPayCreateOrderResponse *)response {
    NSMutableDictionary *totalDic = [NSMutableDictionary dictionaryWithDictionary:dict];
    NSDictionary *commonParams = [CJPayCommonTrackUtil getCashDeskCommonParamsWithResponse:response
                                                                         defaultPayChannel:response.payInfo.defaultPayChannel];
    [totalDic addEntriesFromDictionary:commonParams];
    [totalDic addEntriesFromDictionary:@{@"douyin_version": CJString([CJPayRequestParam appVersion])}];
    return totalDic;
}

- (void)p_bindCard {
    CJPayBindCardSharedDataModel *commonModel = [self p_buildCommonModel];
    BOOL enableNativeBindCard = [CJPaySettingsManager shared].currentSettings.nativeBindCardConfig.enableNativeBindCard;
    if (!enableNativeBindCard || [[CJPayBindCardManager sharedInstance] isLynxReady]) {
        [[CJPayBindCardManager sharedInstance] bindCardWithCommonModel:commonModel];
        return;
    }
    
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading title:CJPayDYPayTitleMessage];
    NSDictionary *params = @{
        @"source" : @"payment_manage",
        @"app_id" : CJString(self.zg_app_id),
        @"merchant_id" : CJString(self.zg_merchant_id)
    };
    [[CJPayBindCardManager sharedInstance] onlyBindCardWithCommonModel:commonModel params:params completion:nil stopLoadingBlock:^{
        [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeDouyinLoading];
    }];
}

- (void)p_requestQuerySignInfo {
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading title:CJPayDYPayTitleMessage];
    [CJPaySignPayQuerySignInfoRequest startWithBizParams:@{@"token": self.token} completion:^(NSError * _Nonnull error, CJPaySignPayQuerySignInfoResponse * _Nonnull response) {
        [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeDouyinLoading];
        if ([response isSuccess]) {
            self.querySignInfo = response;
            [self.contentView updateWithSignModel:[self.querySignInfo toSignModel]];
        } else {
            NSString *alertText = Check_ValidString(response.msg) ? response.msg : CJPayNoNetworkMessage;
            [CJToast toastText:alertText inWindow:self.cj_window];
        }
    }];
    
}

- (CJPayBindCardSharedDataModel *)p_buildCommonModel {
    CJPayBindCardSharedDataModel *model = [CJPayBindCardSharedDataModel new];
    model.lynxBindCardBizScence = CJPayLynxBindCardBizScenceSignPay;
    model.cardBindSource = CJPayCardBindSourceTypeFrontIndependent;
    model.appId = self.zg_app_id;
    model.merchantId = self.zg_merchant_id;
    model.referVC = self;
    model.cjpay_referViewController = self;
    @CJWeakify(self);
    model.completion = ^(CJPayBindCardResultModel * _Nonnull cardResult) {
        @CJStrongify(self)
        switch (cardResult.result) {
            case CJPayBindCardResultSuccess:
                [self p_requestQuerySignInfo];
                break;
            case CJPayBindCardResultFail:
            case CJPayBindCardResultCancel:
                CJPayLogInfo(@"绑卡失败 code: %ld", cardResult.result);
                break;
        }
    };
    return model;
}

- (NSString *)p_outerAppId {
    NSString *appID = @"";
    switch (self.signType) {
        case CJPayOuterTypeInnerPay:
            break;
        case CJPayOuterTypeAppPay:
            appID = self.appId;
            break;
        case CJPayOuterTypeWebPay:
            appID = @"browser";
            break;
        default:
            break;
    }
    return appID;
}

- (void)p_configCashRegisterVCWithBizParams:(NSDictionary *)bizParams {
    CJPayDYPayBizDeskModel *deskModel = [CJPayDYPayBizDeskModel new];
    deskModel.isColdLaunch = NO;
    deskModel.isPaymentOuterApp = [self p_isFromOuterPay];
    deskModel.isUseMask = YES;
    deskModel.appName = self.appName;
    deskModel.appId = [self p_outerAppId];
    deskModel.response = self.orderResponse;
    deskModel.isSignAndPay = YES;
    deskModel.lastTimestamp = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000;
    deskModel.bizParams = bizParams;
    
    [CJ_OBJECT_WITH_PROTOCOL(CJPayCashierModule) i_openDYPayBizDeskWithDeskModel:deskModel delegate:self];
}

- (void)p_trackerEvent:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    [mutableParams cj_setObject:CJString([self p_outerAppId]) forKey:@"outer_aid"];
    [mutableParams cj_setObject:CJString(self.orderResponse.merchantInfo.appId) forKey:@"app_id"];
    [mutableParams cj_setObject:CJString(self.orderResponse.merchantInfo.merchantId) forKey:@"merhcant_id"];
    [mutableParams addEntriesFromDictionary:params];
    
    [CJTracker event:CJString(eventName) params:[mutableParams copy]];
}

- (void)p_trackForPage:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
    double lastTimestamp = [trackData btd_doubleValueForKey:@"start_time" default:0];
    double durationTime = (lastTimestamp > 100000) ? ([[NSDate date] timeIntervalSince1970] * 1000 - lastTimestamp) : 0;
    [trackData addEntriesFromDictionary:@{
        @"template_id" : CJString(self.querySignInfo.signTemplateInfo.templateId),
        @"withhold_project" : CJString(self.querySignInfo.signTemplateInfo.serviceName),
        @"original_amount" : CJString([@(self.querySignInfo.tradeAmount) stringValue]),
        @"reduce_amount" : CJString([@(self.querySignInfo.tradeAmount - self.querySignInfo.realTradeAmount) stringValue]),
        @"cashier_style": @"1",
        @"button_name": CJString(self.querySignInfo.signTemplateInfo.buttonDesc),
        @"haspass" : self.querySignInfo.hasBankCard ? @"1" : @"0",
        @"client_duration":@(durationTime)}];
    [trackData addEntriesFromDictionary:params];
    [self p_trackerEvent:eventName params:trackData];
}

- (void)p_closeCashierDeskAndJumpBackWithResult:(CJPayDypayResultType)resultType {
    if (self.signType == CJPayOuterTypeInnerPay) {
        if (resultType == CJPayDypayResultTypeSuccess || resultType == CJPayDypayResultTypeFailed) {
            if (self.immediatelyClose) {
                [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                    CJ_CALL_BLOCK(self.completion,resultType, @"");
                }];
            } else {
                // 支付成功|失败场景，先回调，300ms后关闭签约页面
                CJ_CALL_BLOCK(self.completion,resultType, @"");
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                        
                    }];
                });
            }
        } else {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                CJ_CALL_BLOCK(self.completion,resultType, @"");
            }];
        }
        return;
    } else {
        [CJPayOuterPayUtil closeCashierDeskVC:self signType:self.signType jumpBackURL:self.returnURLStr jumpBackResult:resultType complettion:^(BOOL isSuccess) {
            CJ_CALL_BLOCK(self.completion,resultType, @"");
        }];
    }
}

- (BOOL)p_isFromOuterPay {
    return self.signType == CJPayOuterTypeAppPay || self.signType == CJPayOuterTypeWebPay;
}

- (void)p_gotoCardListVC {
    NSDictionary *requestParmas = @{
        @"app_id" : CJString(self.zg_app_id),
        @"merchant_id" : CJString(self.zg_merchant_id),
        @"support_pay_type" : self.querySignInfo.signTemplateInfo.supportPayType ?: @[]
    };
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading];
    [CJPaySignQueryMemberPayListRequest startWithBizParams:requestParmas completion:^(NSError * _Nonnull error, CJPaySignQueryMemberPayListResponse * _Nonnull response) {
        [[CJPayLoadingManager defaultService] stopLoading];
        if (error || ![response isSuccess]) {
            [CJToast toastText:Check_ValidString(response.msg) ? CJString(response.msg) : CJPayNoNetworkMessage inWindow:self.cj_window];
            return;
        }
        if (!self.selectedShowConfig) { //缓存首次扣款方式，一次签约流程中，除非用户手动设置，否则扣款方式不变
            self.selectedShowConfig = [response.firstPayTypeItem buildShowConfig].firstObject;
        }
        
        CJPaySignCardListViewController *listVC = [CJPaySignCardListViewController new];
        listVC.animationType = HalfVCEntranceTypeFromBottom;
        [listVC showMask:YES];
        listVC.listResponse = response;
        listVC.defaultShowConfig = self.selectedShowConfig;
        listVC.payTypeListUrl = self.querySignInfo.deductOrderUrl;
        listVC.requestParams = requestParmas;
        listVC.zgAppId = self.zg_app_id;
        listVC.zgMerchantId = self.zg_merchant_id;
        listVC.trackParams = @{
            @"app_id" : CJString(self.zg_app_id),
            @"merchant_id" : CJString(self.zg_merchant_id),
            @"button_name": CJString(self.querySignInfo.signTemplateInfo.buttonDesc),
            @"haspass" : self.querySignInfo.hasBankCard ? @"1" : @"0",
        };
        @CJWeakify(self);
        listVC.didClickMethodBlock = ^(CJPayDefaultChannelShowConfig * _Nonnull showConfig) {
            @CJStrongify(self);
            [self p_updateDeductMethodWithShowConfig:showConfig];
        };
        [self.navigationController pushViewController:listVC animated:YES];
    }];
}

- (void)p_updateDeductMethodWithShowConfig:(CJPayDefaultChannelShowConfig *)showConfig {
    NSDictionary *params = @{
        @"app_id": CJString(self.zg_app_id),
        @"merchant_id": CJString(self.zg_merchant_id),
        @"pay_type_item": [showConfig.payChannel toDictionary]
    };
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading];
    [CJPaySignSetMemberFirstPayTypeRequest startWithBizParams:params completion:^(NSError * _Nonnull error, CJPaySignSetMemberFirstPayTypeResponse * _Nonnull response) {
        [[CJPayLoadingManager defaultService] stopLoading];
        if (![response isSuccess]) {
            [CJToast toastText:Check_ValidString(response.msg) ? CJString(response.msg) : CJPayNoNetworkMessage inWindow:self.cj_window];
            return;
        }
        self.contentView.deductMethodLabel.text = response.displayName;
        self.selectedShowConfig = nil;
    }];
}

#pragma mark - CJPayAPIDelegate

- (void)onResponse:(CJPayAPIBaseResponse *)response {
    NSInteger resultCode = response.error.code;
    CJPayDypayResultType type = [CJPayOuterPayUtil dypayResultTypeWithErrorCode:resultCode];
    BOOL isCloseFromRetain = [[response.error.userInfo cj_stringValueForKey:@"is_close_from_retain"] isEqualToString:@"1"];
    if (type >= 0) {
        CJPayLogInfo(@"支付结果%ld", type);
    }
    if (type == CJPayDypayResultTypeCancel && !isCloseFromRetain) { //无挽留取消支付，停留在当前页面
        return;
    }
    [self p_closeCashierDeskAndJumpBackWithResult:type];
}

#pragma mark - lazy view
     
- (CJPaySignView *)contentView {
    if (!_contentView) {
        _contentView = [CJPaySignView new];
        @CJWeakify(self)
        _contentView.confirmActionBlock = ^(void) {
            @CJStrongify(self)
            [self p_trackForPage:@"wallet_withhold_open_open_click" params:@{@"button_name" : CJString(self.contentView.confirmButton.titleLabel.text)}];
            [self p_onConfirmPayAction];
        };
        
        _contentView.changePayMethodBlock = ^(void) {
            @CJStrongify(self)
            [self p_trackForPage:@"wallet_withhold_open_method_click" params:@{}];
            [self p_gotoCardListVC];
        };
    }
    return _contentView;
}

@end
