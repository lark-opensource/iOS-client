
//
//  CJPayIntegratedCashierProcessManager.m
//  CJPay
//
//  Created by wangxinhua on 2020/8/6.
//

#import <objc/message.h>
#import "CJPayBasicChannel.h"
#import "CJPayIntegratedCashierProcessManager.h"
#import "CJPayUIMacro.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayChannelManagerModule.h"
#import "CJPayChannelModel.h"
#import "CJPayOrderRequest.h"
#import "CJPayOrderResultRequest.h"
#import "CJPayCreateOrderRequest.h"
#import "CJPayRequestParam.h"
#import "CJPayResultPageViewController.h"
#import "CJPayButtonInfoHandler.h"
#import "CJPayAlertUtil.h"
#import "CJPaySDKDefine.h"
#import "CJPayCommonTrackUtil.h"
#import "CJPayProcessInfo.h"
#import "CJPayKVContext.h"
#import "CJPayNameModel.h"
#import "CJPaySubPayTypeSumInfoModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPayTypeInfo+Util.h"
#import "CJPayBDTypeInfo.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayBDOrderResultResponse.h"
#import "CJPayBizDYPayPlugin.h"
#import "CJPayBizDYPayPluginV2.h"
#import "CJPayBizResultController.h"
#import "CJPayFullResultPageViewController.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayWebViewUtil.h"
#import "CJPayDeskUtil.h"
#import "CJPayResultPageModel.h"
#import "CJPayCreditPayChannelModel.h"
#import "CJPayTransferPayModule.h"
#import "CJPayCreateOrderByTokenRequest.h"

@interface CJPayIntegratedCashierProcessManager() <CJPayQRCodeChannelProtocol>

@property (nonatomic, strong, readwrite) CJPayOrderResultResponse *resResponse;
@property (nonatomic, copy) NSDictionary *createOrderParams;
@property (nonatomic, strong) NSMutableArray<id<CJPayBizDYPayPlugin>> *v1Controllers;
@property (nonatomic, strong) NSMutableArray<id<CJPayBizDYPayPluginV2>> *v2Controllers;

@property (nonatomic, strong) CJPayDefaultChannelShowConfig *curSelectConfig; // 当前选择的支付渠道
@property (nonatomic, assign) NSInteger queryTimes;

@property (nonatomic, strong) id<CJPayBizDYPayPlugin> dypayController;
@property (nonatomic, assign) BOOL isUpdatingCreateOrder;//避免同时处理多个刷单通知

@end

@implementation CJPayIntegratedCashierProcessManager

- (instancetype)initWith:(CJPayCreateOrderResponse *)response bizParams:(NSDictionary *)bizParams {
    self = [super init];
    if (self) {
        _orderResponse = response;
        _createOrderParams = bizParams;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_updateCreateOrderResponse) name:CJPayBindCardSignSuccessNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_updateCreateOrderResponse) name:CJPayH5BindCardSuccessNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_updateCreateOrderResponse) name:BDPayUniversalLoginSuccessNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_updateCreateOrderResponse) name:CJPayBindCardSuccessNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateCreateOrderResponseWithCompletionBlock:(void(^)(NSError *error, CJPayCreateOrderResponse *response))completionBlock {
    [self requestCreateOrderWithBizParams:self.createOrderParams completion:completionBlock];
}

- (void)p_updateCreateOrderResponse {
    if (self.isUpdatingCreateOrder) {
        return;
    }
    
    self.isUpdatingCreateOrder = YES;
    @CJWeakify(self)
    [self updateCreateOrderResponseWithCompletionBlock:^(NSError *error, CJPayCreateOrderResponse *response) {
        @CJStrongify(self);
        self.isUpdatingCreateOrder = NO;
        if (![self p_checkNoNetwrok:response] || ![response isSuccess]) {
            return;
        }
        
        [self.homeVC updateOrderResponse:response];
    }];
}

#pragma mark - API
- (void)confirmPayWithConfig:(CJPayDefaultChannelShowConfig *)currentConfig {
    //获取选择的支付渠道
    self.curSelectConfig = currentConfig;
    [self p_submitConfirmRequest];
}

#pragma mark - Private Methods
// 点击确认按钮，发起支付的网络请求
- (void)p_submitConfirmRequest  {
    // 网络请求发起
    NSDictionary *extraRequestParams = [self p_buildConfirmRequestParams];
    @CJWeakify(self)
    @CJStartLoading(self.homeVC)
    [CJPayOrderRequest startConfirmWithParams:extraRequestParams
                                  traceId:[self.orderResponse.feMetrics cj_stringValueForKey:@"trace_id"]
                            processInfoStr:self.orderResponse.processStr
                                completion:^(NSError *error, CJPayOrderResponse *response) {
        @CJStrongify(self)
        @CJStopLoading(self.homeVC)
        // 处理跳转到ALIPay 杀掉App一直loading的问题
        if (![self p_checkNoNetwrok:response]) {
            return;
        }
        //当processInfo有效时，客户端需要更新其保存的下单接口返回的process_info值
        if (Check_ValidString(response.processStr)) {
            self.orderResponse.processStr = response.processStr;
        }
        if ([self p_buttonInfoHandler:response]) {
            return;
        }
        if ([self p_needInvokeLoginAndReturn:response]) {
            return;
        }
        if (![response isSuccess]) {
            [CJMonitor trackService:@"wallet_rd_paydesk_confirm_failed" category:@{@"code":CJString(response.code), @"msg":CJString(response.msg), @"desk_identify": @"聚合收银台"} extra:@{}];
            [CJToast toastText:response.msg ?: CJPayNoNetworkMessage inWindow:self.homeVC.cj_window];
            return;
        } else {
            [self handleComfirmResponse:response];
        }
    }];
}

//处理confirm接口响应，查询支付结果
- (void)handleComfirmResponse:(CJPayOrderResponse *)response {
    switch (self.curSelectConfig.type) {
        case CJPayChannelTypeWX:
        case CJPayChannelTypeTbPay:
        case CJPayChannelTypeDyPay:
            [self p_payWithChannel:self.curSelectConfig.payChannel response:response];
            break;
        case CJPayChannelTypeQRCodePay:
            [self p_payWithChannel:self.curSelectConfig.payChannel response:response];
            [CJTracker event:@"wallet_cashier_scancode_imp" params:[self buildCommonTrackDic:@{}]];
            break;
        case BDPayChannelTypeAddBankCard:
            [self p_dypayWithResponse:response defaultShowConfig:self.curSelectConfig]; //抖音支付
            break;
        case BDPayChannelTypeTransferPay:
            [self p_transferPayWithResponse:response];
            break;
        default:
            [self p_dypayWithResponse:response defaultShowConfig:self.curSelectConfig]; //抖音支付
            break;
    }
}

// 根据当前选择的支付渠道，创建参数结构
- (NSDictionary *)p_buildConfirmRequestParams {
    NSMutableDictionary *extraRequestParams = [NSMutableDictionary new];
    NSMutableDictionary *channelParamsDic = [[self.curSelectConfig.payChannel buildParams] mutableCopy];
    NSDictionary *ptCodeInfoDic = [[channelParamsDic cj_stringValueForKey:@"ptcode_info"] cj_toDic];
    NSDictionary *promotionProcessDic = [[self.orderResponse.payInfo bdPay] promotionProcessInfo];
    if (ptCodeInfoDic && promotionProcessDic) {
        NSMutableDictionary *mutablePtCodeInfo = [ptCodeInfoDic mutableCopy];
        [mutablePtCodeInfo cj_setObject:promotionProcessDic forKey:@"promotion_process"];
        //非hybrid样式收银台，通过强转payChannel传递此参数，需要统一收敛下
        if ([self.orderResponse.deskConfig currentDeskType] == CJPayDeskTypeBytePayHybrid) {
            if (self.curSelectConfig.type == BDPayChannelTypeCreditPay) {
                [mutablePtCodeInfo cj_setObject:CJString(self.curSelectConfig.payTypeData.creditPayInstallment) forKey:@"credit_pay_installment"];
            } else {
                // 抖音支付下的二级支付方式，也需要在tradeConfirm时带上ext_param
                if ([self.curSelectConfig.payChannel isKindOfClass:CJPaySubPayTypeInfoModel.class]) {
                    NSString *extParam = ((CJPaySubPayTypeInfoModel *)self.curSelectConfig.payChannel).extParamStr;
                    [mutablePtCodeInfo cj_setObject:CJString(extParam) forKey:@"ext_param"];
                }
            }
        }
        if (self.curSelectConfig.lynxExtParams) {
            [mutablePtCodeInfo cj_setObject:self.curSelectConfig.lynxExtParams forKey:@"lynx_extra_param"];
        }
        
        if (Check_ValidString(self.curSelectConfig.payTypeData.subExt)) {
            [mutablePtCodeInfo cj_setObject:self.curSelectConfig.payTypeData.subExt forKey:@"sub_ext"];
        }
        
        [channelParamsDic cj_setObject:[CJPayCommonUtil dictionaryToJson:mutablePtCodeInfo] forKey:@"ptcode_info"];
    }
    [extraRequestParams addEntriesFromDictionary:channelParamsDic];
    [extraRequestParams cj_setObject:self.orderResponse.tradeInfo.tradeNo forKey:@"trade_no"];
    [extraRequestParams cj_setObject:self.curSelectConfig.payChannel.channelInfo.payType forKey:@"channel_pay_type"];
    return [extraRequestParams copy];
}

- (void)p_dypayWithResponse:(CJPayOrderResponse *)response defaultShowConfig:(CJPayDefaultChannelShowConfig *)showConfig {
    if (!CJ_CLASS_WITH_PROCOCOL(CJPayBizDYPayPlugin) && !CJ_CLASS_WITH_PROCOCOL(CJPayBizDYPayPluginV2)) {
        [CJToast toastText:@"未接入抖音支付模块！" inWindow:self.homeVC.cj_window];
        return;
    }
    CJPayLogAssert(self.homeVC, @"homeVC不能为nil!");

    CJPayBizDYPayModel *model = [CJPayBizDYPayModel new];
    model.createResponseStr = response.channelData;
    model.showConfig = showConfig;
    if ([self.homeVC isKindOfClass:CJPayHomePageViewController.class]) {
        model.homeVC = (CJPayHomePageViewController *)self.homeVC;
    }
    model.isPaymentForOuterApp = self.isPaymentForOuterApp;
    model.cj_merchantID = self.orderResponse.tradeInfo.merchantId;
    model.intergratedTradeIdentify = self.orderResponse.tradeInfo.tradeNo;
    model.trackParams = [self p_trackerParams];
    model.processStr = self.orderResponse.processStr;//processstr为空则不去查单，也不会展示结果页
    model.jhResultPageStyle = self.orderResponse.deskConfig.jhResultPageStyle;
    model.processManager = self;
    model.bizCreateOrderResponse = self.orderResponse;
    
    if ([self p_isDouPayProcess]) {
        id<CJPayBizDYPayPluginV2> dypayControllerV2 = [CJ_CLASS_WITH_PROCOCOL(CJPayBizDYPayPluginV2) new];
        [self.v2Controllers btd_addObject:dypayControllerV2];
        @CJWeakify(self)
        @CJWeakify(dypayControllerV2)
        [dypayControllerV2 dyPayWithModel:model
                             completion:^(CJPayOrderStatus orderStatus, CJPayBDOrderResultResponse * _Nonnull response) {
            @CJStrongify(self)
            @CJStrongify(dypayControllerV2)
            CJPayOrderResultResponse *orderResponse = [CJPayOrderResultResponse new];
            orderResponse.tradeInfo = [CJPayTradeInfo new];
            orderResponse.tradeInfo.status = response.tradeInfo.tradeStatusString;
            self.resResponse = orderResponse;
            [self p_callCompletionBlock:self.resResponse orderStatus:orderStatus];
            [self.v2Controllers removeObject:dypayControllerV2];
        }];
    } else {
        id<CJPayBizDYPayPlugin> dypayController = [CJ_CLASS_WITH_PROCOCOL(CJPayBizDYPayPlugin) new];
        [self.v1Controllers btd_addObject:dypayController];
        @CJWeakify(self)
        @CJWeakify(dypayController)
        [dypayController dyPayWithModel:model completion:^(CJPayOrderStatus orderStatus, CJPayBDOrderResultResponse * _Nonnull response) {
            @CJStrongify(self)
            @CJStrongify(dypayController)
            CJPayOrderResultResponse *orderResponse = [CJPayOrderResultResponse new];
            orderResponse.tradeInfo = [CJPayTradeInfo new];
            orderResponse.tradeInfo.status = response.tradeInfo.tradeStatusString;
            self.resResponse = orderResponse;
            [self p_callCompletionBlock:self.resResponse orderStatus:orderStatus];
            [self.v1Controllers removeObject:dypayController];
        }];
    }
}

- (NSMutableArray<id<CJPayBizDYPayPlugin>> *)v1Controllers {
    if (!_v1Controllers) {
        _v1Controllers = [NSMutableArray new];
    }
    return _v1Controllers;
}

- (NSMutableArray<id<CJPayBizDYPayPluginV2>> *)v2Controllers {
    if (!_v2Controllers) {
        _v2Controllers = [NSMutableArray new];
    }
    return _v2Controllers;
}

- (void)p_transferPayWithResponse:(CJPayOrderResponse *)response {
    NSMutableDictionary *tranferDataDic = [[response.channelData cj_toDic] mutableCopy] ?: [NSMutableDictionary new];
    @CJWeakify(self)
    tranferDataDic[@"custom_loading_block"] = ^(BOOL isNeedLoading) {
        @CJStrongify(self)
        if (isNeedLoading) {
            [self.homeVC startLoading];
        } else {
            [self.homeVC stopLoading];
        }
    };
    [CJ_OBJECT_WITH_PROTOCOL(CJPayTransferPayModule) startTransferPayWithParams:tranferDataDic
                                                                     completion:^(CJPayManagerResultType type, NSString * _Nonnull errorMsg) {
        if (type == CJPayManagerResultSuccess) {
            CJPayOrderResultResponse *orderResponse = [CJPayOrderResultResponse new];
            orderResponse.tradeInfo = [CJPayTradeInfo new];
            orderResponse.tradeInfo.status = @"SUCCESS";
            self.resResponse = orderResponse;
            [self p_queryOrderResult:CJPayResultTypeSuccess];
        }
    }];
}

- (NSDictionary *)p_trackerParams {
    NSMutableDictionary *trackerParams = [[self buildCommonTrackDic:@{
        @"method" : CJString([CJPayTypeInfo getTrackerMethodByChannelConfig:self.curSelectConfig])
    }] mutableCopy];
    if ([self.homeVC respondsToSelector:@selector(trackerParams)]) {
        [trackerParams addEntriesFromDictionary:[self.homeVC performSelector:@selector(trackerParams)]];
    }
    [trackerParams addEntriesFromDictionary:self.lynxRetainTrackerParams];
    return [trackerParams copy];
}

- (BOOL)p_needInvokeLoginAndReturn:(CJPayIntergratedBaseResponse *)response {
    if ([response.code isEqualToString:@"GW400008"]) { //宿主未登录
        [CJToast toastText:response.msg inWindow:self.homeVC.cj_window];
        [self.homeVC closeDesk];
        return YES;
    }
    return NO;
}

//调起支付渠道并处理结果  wechat alipay qrcodepay dypay wxh5pay
- (void)p_payWithChannel:(CJPayChannelModel *)channelModel response: (CJPayOrderResponse *)response {
    NSDictionary *dataDict = [response payDataDict];
    CJPayChannelType payChannelType = [self p_getChannelWith:channelModel.code tradeType:response.tradeType];
    if (payChannelType == CJPayChannelTypeQRCodePay) {
        dataDict = [self QRCodeParams:response];
        NSMutableDictionary *newDataDic = [dataDict mutableCopy];
        [newDataDic cj_setObject:self forKey:@"delegate"];
        dataDict = [newDataDic copy];
    } else if (payChannelType == CJPayChannelTypeDyPay) {
        NSMutableDictionary *newDataDic = [dataDict mutableCopy];
        
        if ([newDataDic cj_integerValueForKey:@"dypay_version"] == 0) {
            [newDataDic cj_setObject:@"1" forKey:@"dypay_version"];
        } else {
            [newDataDic cj_setObject:@([newDataDic cj_integerValueForKey:@"dypay_version"]).stringValue forKey:@"dypay_version"];
        }
        
        dataDict = [newDataDic copy];
    }
    @CJWeakify(self)
    [CJ_OBJECT_WITH_PROTOCOL(CJPayChannelManagerModule) i_payActionWithChannel:payChannelType
                                                                       dataDict:dataDict
                                                                completionBlock:^(CJPayChannelType channelType, CJPayResultType resultType, NSString *errorCode) {
        @CJStrongify(self)
        [self p_handleChannelResult:channelType resultType:resultType];
    }];
}

//获取支付渠道对象
- (CJPayChannelType)p_getChannelWith:(NSString *)channelName tradeType:(NSString *)tradeType{
    CJPayChannelType payChannelType = CJPayChannelTypeNone;
    if ([channelName isEqualToString:@"wx"]) {
        if ([tradeType isEqualToString:@"MWEB"]) {
            payChannelType = CJPayChannelTypeWXH5;
        } else {
            payChannelType = CJPayChannelTypeWX;
        }
    } else if ([channelName isEqualToString:@"alipay"]) {
        payChannelType = CJPayChannelTypeTbPay;
    } else if ([channelName isEqualToString:@"dypay"]) {
        payChannelType = CJPayChannelTypeDyPay;
    } else if ([channelName isEqualToString:@"qrcode"]) {
        payChannelType = CJPayChannelTypeQRCodePay;
    }
    return payChannelType;
}

- (void)p_handleChannelResult:(CJPayChannelType)channelType resultType:(CJPayResultType)resultType {
    if (![self p_checkOrderValidation]) {
        return;
    }
    switch (resultType) {
        case CJPayResultTypeSuccess:
        case CJPayResultTypeBackToForeground:
            [self p_queryOrderResult:resultType];
            break;
        case CJPayResultTypeUnInstall:
            [self p_handleUnistallCase:channelType];
            break;
        default:
            return;
    }
}

//处理未安装微信或未引入二维码支付模块的情况
- (void)p_handleUnistallCase:(CJPayChannelType)channelType {
    if (channelType == CJPayChannelTypeWX) {
        NSString *toastStr = [NSString stringWithFormat:@"尚未安装%@，请选择其他支付方式", CN_WX];
        [CJToast toastText:CJPayLocalizedStr(toastStr) inWindow:self.homeVC.cj_window];
        [CJTracker event:@"pay_apply_confirm_click" params:@{@"toast": toastStr}];
    } else if (channelType == CJPayChannelTypeQRCodePay) {
        [CJToast toastText:CJPayLocalizedStr(@"暂不支持二维码支付，请选择其他支付方式") inWindow:self.homeVC.cj_window];
    }
}

- (BOOL)p_buttonInfoHandler:(CJPayOrderResponse *)response {
    CJPayButtonInfoHandlerActionModel *actionModel = [CJPayButtonInfoHandlerActionModel new];
    @CJWeakify(self)
    actionModel.singleBtnAction = ^(NSInteger type) {
        @CJStrongify(self)
        if (type == 1) {
//            [self.homeVC closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromBack];//已回调
            [self.homeVC closeActionAfterTime:0 closeActionSource:CJPayOrderStatusCancel];
        }
    };
    return [CJPayButtonInfoHandler handleResponse:response fromVC:self.homeVC withActionsModel:actionModel];
}

- (void)p_queryOrderResult:(CJPayResultType)resultType {
    @CJWeakify(self)
    void(^completion)(NSError *error, CJPayOrderResultResponse *response) = ^(NSError *error, CJPayOrderResultResponse *response){
        @CJStrongify(self)
        [self handleQueryResult:response];
    };
    
    if (resultType == CJPayResultTypeBackToForeground) {
        [self p_queryResult:1 withResultType:resultType completion:^(NSError *error, CJPayOrderResultResponse *response) {
            if ([response isSuccess] && response.tradeInfo.tradeStatus == CJPayOrderStatusSuccess) {
                CJ_CALL_BLOCK(completion, error, response);
            }
        }];
    } else {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading];
        [self p_queryResult:self.orderResponse.deskConfig.queryResultTime withResultType:resultType completion:^(NSError *error, CJPayOrderResultResponse *response) {
            [[CJPayLoadingManager defaultService] stopLoading];
            CJ_CALL_BLOCK(completion, error, response);
        }];
    }
}

- (BOOL)p_isDouPayProcess {
    return [[CJPayABTest getABTestValWithKey:CJPayABIsDouPayProcess exposure:YES] isEqualToString:@"1"];
}

- (void)handleQueryResult:(CJPayOrderResultResponse *)response {
    [self.homeVC invalidateCountDownView];
    NSString *secondMethodList = [[self.homeVC trackerParams] cj_stringValueForKey:@"second_method_list"];
    NSMutableDictionary *trackerParams = [[NSMutableDictionary alloc] initWithDictionary: @{
        @"result" : (response.tradeInfo.tradeStatus == CJPayOrderStatusSuccess) ? @"1" : @"0",
        @"method" : CJString(response.tradeInfo.ptCode),
        @"second_method_list" : CJString(secondMethodList)
    }];//这里展示支付宝结果页
    [trackerParams addEntriesFromDictionary:[self.createOrderParams btd_dictionaryValueForKey:@"track_info"]];
    [trackerParams addEntriesFromDictionary:self.lynxRetainTrackerParams];
    [CJTracker event:@"wallet_cashier_result"
              params:[self buildCommonTrackDic:[trackerParams copy]]];
    
    if (![self p_checkNoNetwrok:response]) {//无网弱网提示
        return;
    }
    self.resResponse = response;
    
    if ([self p_isDouPayProcess]) {
        //抖音支付标准化收敛聚合推结果页的逻辑
        __block CJPayBizResultController *bizResultController = [CJPayBizResultController new];
        bizResultController.homeVC = self.homeVC;
        bizResultController.bizCreateOrderResponse = self.orderResponse;
        bizResultController.showConfig = self.curSelectConfig;
        bizResultController.trackParams = [self p_trackerParams];
        @CJWeakify(self)
        [bizResultController showResultPageWithOrderResultResponse:response
                                                   completionBlock:^{
            @CJStrongify(self)
            [self p_callCompletionBlock:self.resResponse orderStatus:CJPayOrderStatusNull];
            bizResultController = nil;
        }];
        return;
    }
    
    NSString *CJPayCJOrderResultCacheStringKey = @"CJPayCJPayOrderResultResponse";
    NSString *dataJsonStr = [[[response toDictionary] cj_dictionaryValueForKey:@"data"] btd_jsonStringEncoded];
    if (CJ_OBJECT_WITH_PROTOCOL(CJPayParamsCacheService)) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayParamsCacheService) i_setParams:dataJsonStr key:CJPayCJOrderResultCacheStringKey];
    }

    if (response.resultPageInfo) {
        NSString *renderType = response.resultPageInfo.renderInfo.type;
        if ([renderType isEqualToString:@"native"]) {
            [self p_resultPageLynxCard:response];
        } else if ([renderType isEqualToString:@"lynx"]){
            [self p_resultPageLynx:response];
        } else {//这里不可能下发h5，只可能是错误
            [self p_resultPageNative:response];
        }
    } else {
        [self p_resultPageNative:response];
    }
    
}

- (void)p_resultPageLynx:(CJPayOrderResultResponse *)resultResponse {
    NSString *url = resultResponse.resultPageInfo.renderInfo.lynxUrl;
    CJPayNavigationController *navi = [UIViewController cj_topViewController].navigationController;
    if (navi) {
        [navi.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else if (navi.presentingViewController) {
        [navi.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
    @CJWeakify(self)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [CJPayDeskUtil openLynxPageBySchema:url completionBlock:^(CJPayAPIBaseResponse * _Nullable response) {
            [weak_self p_callCompletionBlock:weak_self.resResponse orderStatus:CJPayOrderStatusNull];
        }];
    });
}

- (void)p_resultPageNative:(CJPayOrderResultResponse *)response {
    if (self.curSelectConfig.type == BDPayChannelTypeTransferPay) {
        // 大额支付在聚合收银台必出结果页，后台只能按照商户配置停留时长，微信支付宝可能配置成不需要结果页，客户端做一下兜底
        if (self.orderResponse.deskConfig.remainTime == 0) {
            self.orderResponse.deskConfig.remainTime = -1;
        }
    }
    
    if ([self.orderResponse closeAfterTime] == 0) {
        [self.homeVC closeDesk];// 这个方法会做closeCompletion的回调
    } else {
        if (![self p_checkOrderValidation]) {// 超时订单不展示结果页
            return;
        }
        CJPayResultPageViewController *resultPage = [CJPayResultPageViewController new];// 新增聚合结果页处理
        resultPage.resultResponse = response;
        resultPage.orderResponse = self.orderResponse;
        resultPage.commonTrackerParams = [self buildCommonTrackDic:@{
            @"method" : CJString([CJPayTypeInfo getTrackerMethodByChannelConfig:self.curSelectConfig]),
            @"second_method_list" : CJString([[self.homeVC trackerParams] cj_stringValueForKey:@"second_method_list"])
        }];
        @CJWeakify(self)
        resultPage.closeActionCompletionBlock = ^(BOOL isClose) {
            [weak_self p_callCompletionBlock:weak_self.resResponse orderStatus:CJPayOrderStatusNull];
        };
        [(CJPayNavigationController *)self.homeVC.navigationController pushViewControllerSingleTop:resultPage animated:NO completion:nil];
    }
}

- (CJPayResultPageModel *)p_resultmodelwithResponse:(CJPayOrderResultResponse *)response {
    CJPayResultPageModel *model = [[CJPayResultPageModel alloc] init];
    model.orderType = response.tradeInfo.ptCode;
    model.amount = response.tradeInfo.amount;
//    model.tradeInfo = response.tradeInfo;
    //    model.paymentInfo = response.paymentInfo;
    model.remainTime = response.remainTime;
    model.resultPageInfo = response.resultPageInfo;
    model.openSchema = response.openSchema;
    model.openUrl = response.openUrl;
    model.orderResponse = [response toDictionary]?:@{};
    return model;
}


- (void)p_resultPageLynxCard:(CJPayOrderResultResponse *)response {
    NSString *CJPayBDOrderResultCacheStringKey = @"CJPayCJPayOrderResultResponse";
    
    @CJWeakify(self)
    CJPayFullResultPageViewController *resultPage = [[CJPayFullResultPageViewController alloc] initWithCJResultModel:[self p_resultmodelwithResponse:response] trackerParams:([self p_trackerParams] ?: @{})];
    resultPage.closeCompletion = ^{
        @CJStrongify(self)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self p_handleClose:response];
            [self p_callCompletionBlock:weak_self.resResponse orderStatus:CJPayOrderStatusNull];
        });
        
    };

    [(CJPayNavigationController *)self.homeVC.navigationController pushViewControllerSingleTop:resultPage animated:NO completion:nil];
}

- (void)p_handleClose:(CJPayOrderResultResponse *)response {
    NSString *buttonAction = response.resultPageInfo.buttonInfo.action;
    NSString *url = response.openUrl;
    if ([buttonAction isEqualToString:@"open"] && Check_ValidString(url)) {
        if ([url hasPrefix:@"http"]) {
            [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:[UIViewController cj_topViewController] toUrl:url params:@{}];
        } else {
            [CJPayDeskUtil openLynxPageBySchema:url completionBlock:nil];
        }
    }
}


- (void)p_queryResult:(NSInteger)retryCount withResultType:(CJPayResultType) resultType completion:(void(^)(NSError *error, CJPayOrderResultResponse *response))completionBlock {
    @CJWeakify(self)
    [self requestQueryOrderResultWithTradeNo:self.orderResponse.tradeInfo.tradeNo processInfo:self.orderResponse.processStr completion:^(NSError * _Nonnull error, CJPayOrderResultResponse * _Nonnull response) {
        
        if ([weak_self p_needInvokeLoginAndReturn:response]) {
            CJ_CALL_BLOCK(completionBlock,error,response);
            return;
        }
        // 此种情况需要重试，通过后台返回，是如果response是有效的，就不在进行重试了
        switch (resultType) {
            case CJPayResultTypeBackToForeground:
                if (![response isSuccess] && retryCount > 0) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [weak_self p_queryResult:retryCount - 1 withResultType:resultType completion:completionBlock];
                    });
                    return;
                }
                break;
            default:
                if ((response.tradeInfo.tradeStatus == CJPayOrderStatusProcess || ![response isSuccess]) && retryCount > 0) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [weak_self p_queryResult:retryCount - 1 withResultType:resultType completion:completionBlock];
                    });
                    return;
                }
                break;
        }
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

- (NSDictionary*)QRCodeParams:(CJPayOrderResponse *)response {
    NSMutableDictionary *QRParams =  [[NSMutableDictionary alloc]initWithDictionary:[response payDataDict]];
    CJPayNameModel *nameModel = [CJPayKVContext kv_valueForKey:CJPayDeskTitleKVKey];
    NSDictionary *dic = @{
        @"payDeskTitle" : CJString(nameModel.payName),
        @"amount" : [NSString stringWithFormat:@"%.2f", self.orderResponse.tradeInfo.amount/100.0],
        @"tradeName" : CJString(self.orderResponse.tradeInfo.tradeName),
    };
    [QRParams addEntriesFromDictionary:dic];
    return [QRParams copy];
}

//检查弱网无网环境
- (BOOL)p_checkNoNetwrok:(id)response {
    if (response == nil) {
        @CJStopLoading(self.homeVC)
        [CJToast toastText:CJPayNoNetworkMessage inWindow:self.homeVC.cj_window];
        return NO;
    }
    return YES;
}

//检查订单有效性
- (BOOL)p_checkOrderValidation {
    if (self.orderIsInvalid) {
        CJPayLogInfo(@"订单失效");
        return NO;
    }
    return YES;
}

//调用回调block
- (void)p_callCompletionBlock:(CJPayOrderResultResponse *)response orderStatus:(CJPayOrderStatus)orderStatus {
    CJ_CALL_BLOCK(self.completionBlock, response, orderStatus);
}

#pragma mark 处理网络请求 CJPayVerifyManagerRequestProtocol
- (void)requestCreateOrderWithBizParams:(NSDictionary *)bizParams completion:(void(^)(NSError *error, CJPayCreateOrderResponse *response))completionBlock {
    if (self.isPaymentForOuterApp) {
        [CJPayCreateOrderByTokenRequest startWithBizParams:bizParams ?: @{} bizUrl:@"" completion:completionBlock];
    } else {
        [CJPayCreateOrderRequest startWithBizParams:bizParams ?: @{} bizUrl:@"" completion:completionBlock];
    }
}

- (void)requestQueryOrderResultWithTradeNo:(NSString *)tradeNo processInfo:(NSString *)processInfoStr completion:(void (^)(NSError * _Nonnull, CJPayOrderResultResponse * _Nonnull))completionBlock {
    [CJPayOrderResultRequest startWithTradeNo:tradeNo processInfo:processInfoStr completion:completionBlock];
}

#pragma mark 埋点方法

- (NSDictionary *)buildCommonTrackDic:(NSDictionary *)dic {//传入的字典若包含通参则使用传入的新值
    NSMutableDictionary *mutableDic = [[CJPayCommonTrackUtil getBytePayDeskCommonTrackerWithResponse:self.orderResponse] mutableCopy];
    [mutableDic cj_setObject:CJString([self.createOrderParams cj_stringValueForKey:@"cashier_source" defaultValue:@"0"]) forKey:@"cashier_source"];
    [mutableDic addEntriesFromDictionary:dic];
    if ([self.homeVC respondsToSelector:@selector(trackerParams)]) {
        [mutableDic addEntriesFromDictionary:[self.homeVC performSelector:@selector(trackerParams)]];
    }
    return [mutableDic copy];
}

#pragma mark CJPayQRCodeChannelProtocol Impl
- (void)queryQROrderResult:(void(^)(BOOL))completionBlock {
    [self p_queryResult:0 withResultType:CJPayResultTypeBackToForeground completion:^(NSError *error, CJPayOrderResultResponse *response) {
        //查单完成后走channel回调
        if(!completionBlock) {
            return;
        }
        if ([response isSuccess] && response.tradeInfo.tradeStatus != CJPayOrderStatusProcess) {
            completionBlock(YES);
        } else {
            completionBlock(NO);
        }
    }];
}

- (void)trackWithName:(NSString*)name params:(NSDictionary*)dic {
    [CJTracker event:name params:[self buildCommonTrackDic:dic]];
}

- (void)pushViewController:(UIViewController *)vc {
    [self.homeVC.navigationController pushViewController:vc animated:YES];
}

@end
