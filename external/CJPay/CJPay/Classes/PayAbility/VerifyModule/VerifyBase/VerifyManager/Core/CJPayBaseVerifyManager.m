//
//  CJPayBaseVerifyManager.m
//  CJPay
//
//  Created by 王新华 on 10/10/19.
//

#import "CJPayBaseVerifyManager.h"
#import "CJPayHalfPageBaseViewController.h"
#import "CJPayUIMacro.h"
#import "CJPayOrderConfirmRequest.h"
#import "CJPayWebViewUtil.h"
#import "CJPayBaseVerifyManager+ButtonInfoHandler.h"
#import "CJPayHalfPageBaseViewController.h"
#import <JSONModel/JSONModel.h>
#import "CJPayMetaSecManager.h"
#import "CJPayKVContext.h"
#import "CJPayStayAlertForOrderModel.h"
#import "CJPayOrderConfirmRequest.h"
#import "CJPayBDOrderResultRequest.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayCardSignResponse.h"
#import "CJPayNewCardPayRequest.h"
#import "CJPayBindCardResultModel.h"
#import "CJPayBaseVerifyManagerQueen.h"
#import "CJPaySettingsManager.h"
#import "CJPayDeskUtil.h"
#import "CJPaySafeManager.h"
#import "CJPayBioPaymentPlugin.h"

@interface CJPayBaseVerifyManager()

@property (nonatomic, assign) BOOL isBindCardAndPay;
@property (nonatomic, strong) CJPayOrderConfirmResponse *confirmResponse;
@property (nonatomic, strong) CJPayBDOrderResultResponse *resResponse;
@property (nonatomic, strong) NSMutableDictionary *verifyTypeMap;
@property (nonatomic, strong) CJPayVerifyItem *lastConfirmVerifyItem;
@property (nonatomic, strong) CJPayVerifyItem *lastWakeVerifyItem;
@property (nonatomic, copy) NSDictionary *verifyItemConfig;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *verifyTypeArray;

@property (nonatomic, assign) NSTimeInterval startConfirmTimestamp;
@property (nonatomic, assign) BOOL isNoTradeQuery;
@property (nonatomic, strong, nullable) CJPayBDCreateOrderResponse *lastResponse;

@end

@implementation CJPayBaseVerifyManager

+ (instancetype)managerWith:(id<CJPayHomeVCProtocol>)homePageVC {
    NSDictionary *defaultVerifyItemsDic = @{
        @(CJPayVerifyTypeSignCard)          : @"CJPayVerifyItemSignCard",
        @(CJPayVerifyTypeBioPayment)        : @"CJPayVerifyItemBioPayment",
        @(CJPayVerifyTypePassword)          : @"CJPayVerifyItemPassword",
        @(CJPayVerifyTypeSMS)               : @"CJPayVerifyItemSMS",
        @(CJPayVerifyTypeUploadIDCard)      : @"CJPayVerifyItemUploadIDCard",  // 上传身份证影印件
        @(CJPayVerifyTypeAddPhoneNum)       : @"CJPayVerifyItemAddPhoneNum",  // 补充联系手机号
        @(CJPayVerifyTypeIDCard)            : @"CJPayVerifyItemIDCard", // 账户受限
        @(CJPayVerifyTypeRealNameConflict)  : @"CJPayVerifyItemRealNameConflict",
        @(CJPayVerifyTypeFaceRecog)         : @"CJPayVerifyItemRecogFace",
        @(CJPayVerifyTypeForgetPwdFaceRecog): @"CJPayVerifyItemForgetPwdRecogFace",
        @(CJPayVerifyTypeFaceRecogRetry)    : @"CJPayVerifyItemRecogFaceRetry",
        @(CJPayVerifyTypeSkipPwd)           : @"CJPayVerifyItemSkipPwd",
        @(CJPayVerifyTypeSkip)              : @"CJPayVerifyItemSkip",
        @(CJPayVerifyTypeToken)             : @"CJPayVerifyItemToken"
    };
    return [self managerWith:homePageVC withVerifyItemConfig:defaultVerifyItemsDic];
}

+ (instancetype)managerWith:(id<CJPayHomeVCProtocol>)homePageVC withVerifyItemConfig:(NSDictionary *)verifyItemConfig {
    CJPayBaseVerifyManager *verifyManager = [self.class new];
    verifyManager.homePageVC = homePageVC;
    verifyManager.verifyItemConfig = verifyItemConfig;
    verifyManager.loadingDelegate = homePageVC;
    return verifyManager;
}

- (void)useLatestResponse {
    _lastResponse = nil;
}

- (nullable CJPayVerifyItem *)getSpecificVerifyType:(CJPayVerifyType)type {    
    NSDictionary *verifyItemsDic = self.verifyItemConfig;
    if ([self.verifyTypeMap objectForKey:@(type)]) {
        return (CJPayVerifyItem *)[self.verifyTypeMap objectForKey:@(type)];
    }
    // 动态生成实例
    NSString *className = [verifyItemsDic objectForKey:@(type)];
    CJPayVerifyItem *curItem;
    if (className && className.length > 0) {
        Class verifyClass = NSClassFromString(className);
        id verifyInstance = [[verifyClass alloc] init];
        if (verifyInstance && [verifyInstance isKindOfClass:[CJPayVerifyItem class]]) {
            curItem = (CJPayVerifyItem *)verifyInstance;
            [curItem bindManager:self];
            curItem.verifyType = type;
            [self.verifyTypeMap setObject:curItem forKey:@(type)];
        }
    } else {
        CJPayLogAssert(NO, @"不能根据Type拿到类名称");
    }
    return curItem;
}

- (CJPayDefaultChannelShowConfig *)defaultConfig {
    return [self.homePageVC curSelectConfig];
}

- (CJPayBDCreateOrderResponse *)response {
    if (!_lastResponse) {
        _lastResponse = [self.homePageVC createOrderResponse];
    }
    return _lastResponse;
}

- (CJPayVerifyType)lastVerifyType {
    return (CJPayVerifyType)([self.verifyTypeArray.lastObject intValue]);
}

//查询订单状态
- (void)queryOrderResult:(NSInteger)retryCount {
    @CJWeakify(self)
    [CJKeyboard prohibitKeyboardShow];

    [self p_queryResult:retryCount completion:^(NSError *error, CJPayBDOrderResultResponse *response) {
        @CJStrongify(self)
        [CJKeyboard permitKeyboardShow];
        if (!self.notStopLoading) {
            [self p_addLoadingViewInTopHalfVC];
            [self stopLoadingWithResResponse:response];
        }
        self.resResponse = response;
        if (self.verifyManagerQueen && [self.verifyManagerQueen respondsToSelector:@selector(afterLastQueryResultWithResultResponse:)]) {
            [self.verifyManagerQueen afterLastQueryResultWithResultResponse:response];
        }
        [self p_queryOrderFinishWithResultResponse:response];
    }];
}

- (void)p_queryResult:(NSInteger)retryCount completion:(void(^)(NSError *error, CJPayBDOrderResultResponse *response))completionBlock {
    @CJWeakify(self)
    [self requestQueryOrderResultWithTradeNo:self.response.tradeInfo.tradeNo processInfo:self.response.processInfo completion:^(NSError * _Nonnull error, CJPayBDOrderResultResponse * _Nonnull response) {
        NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
        double lastTimestamp = [trackData btd_doubleValueForKey:@"start_time" default:0];
        double durationTime = (lastTimestamp > 100000) ? ([[NSDate date] timeIntervalSince1970] * 1000 - lastTimestamp) : 0;
        [trackData addEntriesFromDictionary:@{
            @"client_duration":@(durationTime),
            @"sdk_err_msg":CJString(response.msg),
            @"biz_err_code":CJString(response.code),
            @"trade_status":CJString(response.tradeInfo.tradeStatusString),
            @"trade_status_msg":CJString(response.tradeInfo.tradeDescMessage)
        }];
        [CJTracker event:@"wallet_cashier_bd_trade_query_result"
                  params:trackData];
        // 前面已经查询过一次，需要先减掉一次，在继续查询
        NSInteger newRetryCount = retryCount - 1;
        
        @CJStrongify(self)
        if ([self needInvokeLoginAndReturn:response]) {
            CJ_CALL_BLOCK(completionBlock,error,response);
            return;
        }
        if ((response.tradeInfo.tradeStatus == CJPayOrderStatusProcess || ![response isSuccess]) && newRetryCount > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self queryOrderResult:newRetryCount];
            });
            return;
        }
        
        // 统计确认支付 + 查询结果的整体耗时
        NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
        NSTimeInterval currentTimestamp = [date timeIntervalSince1970]*1000;
        NSTimeInterval duration = currentTimestamp - self.startConfirmTimestamp;
        // 过滤无效的时间戳数据再上报
        if (duration > 0 && duration < 20*1000) {
            [CJTracker event:@"wallet_comfirm_query_combine_event" params:@{
                @"duration" : @(duration),
                @"isCombine" : @(self.isNoTradeQuery)
            }];
        }
        
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

#pragma mark - 验证流程核心方法
- (NSDictionary *)loadSpecificTypeCacheData:(CJPayVerifyType)type {
    if (type == CJPayVerifyTypeLast) {
        return [self.lastWakeVerifyItem getLatestCacheData];
    }
    return [[self.verifyTypeMap objectForKey:@(type)] getLatestCacheData];
}

- (void)wakeSpecificType:(CJPayVerifyType)type orderRes:(CJPayBDCreateOrderResponse *)response event:(nullable CJPayEvent *)event {
    [self p_addVerifyType:type];
    CJPayVerifyItem *verifyItem = [self getSpecificVerifyType:type];
    self.lastWakeVerifyItem = verifyItem;
    self.lastConfirmVerifyItem = verifyItem;
    [verifyItem requestVerifyWithCreateOrderResponse:response event:event];
    if (event) {
        [verifyItem receiveEvent:event];
    }
}

- (CJPayVerifyType)getVerifyTypeWithPwdCheckWay:(NSString *)pwdCheckWay
{
    BOOL isNeedBioPay = ([pwdCheckWay isEqualToString:@"1"] || [pwdCheckWay isEqualToString:@"2"]) && !self.disableBioPay;
    if (isNeedBioPay) {
        return CJPayVerifyTypeBioPayment;
    } else if ([pwdCheckWay isEqualToString:@"3"]) {
        return CJPayVerifyTypeSkipPwd;
    } else if ([pwdCheckWay isEqualToString:@"5"]) {
        return CJPayVerifyTypeSkip;
    } else if ([pwdCheckWay isEqualToString:@"6"] && Check_ValidString(self.token)) {
        return CJPayVerifyTypeToken;
    } else {
        return CJPayVerifyTypePassword;
    }
}

- (BOOL)shouldHandleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    __block BOOL shouldHandle = NO;
    // 把上次的验证方式排到最前面
    NSArray *verifyItemsSorted = [self.verifyTypeMap.allValues sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        if (obj1 == self.lastConfirmVerifyItem) {
            return NSOrderedAscending;
        } else if (obj2 == self.lastConfirmVerifyItem) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    
    // 如果找到了可以处理的verifyItem就不在遍历了
    [verifyItemsSorted enumerateObjectsUsingBlock:^(CJPayVerifyItem * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        shouldHandle |= [obj shouldHandleVerifyResponse:response];
        if (shouldHandle) {
            *stop = YES;
            self.lastHandleVerifyItem = obj;
            [self p_addVerifyType:obj.verifyType];
        }
    }];
    return shouldHandle;
}

- (void)handleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    // 如果找到了可以处理的verifyItem就不在遍历了
    [self.lastHandleVerifyItem handleVerifyResponse:response];
}

#pragma mark - 对外暴露的方法
- (BOOL)needInvokeLoginAndReturn:(CJPayBaseResponse *)response {
    if ([response.code isEqualToString:@"CA3100"]) { //宿主未登录
        [CJToast toastText:response.msg inWindow:[self.homePageVC topVC].cj_window];
        [[CJPayWebViewUtil sharedUtil] needLogin:^(CJBizWebCode code) {
            
        }];
        [self.homePageVC closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromUnLogin];
        return YES;
    }
    return NO;
}

// 根据当前选择的支付渠道，创建参数结构
- (NSDictionary *)buildConfirmRequestParamsByCurPayChannel {
    CJPayDefaultChannelShowConfig *selectChannel = self.defaultConfig;
    NSMutableDictionary *dic = [NSMutableDictionary new];
    if ([selectChannel.payChannel conformsToProtocol:@protocol(CJPayRequestParamsProtocol)]) {
        NSDictionary *requestChannelParams = [((id<CJPayRequestParamsProtocol>)selectChannel.payChannel) requestNeedParams];
        [dic addEntriesFromDictionary:requestChannelParams];
    }
    NSString *payChannel = [CJPayBDTypeInfo getChannelStrByChannelType:selectChannel.type
                                                        isCombinePay:selectChannel.isCombinePay];
    [dic cj_setObject:payChannel forKey:@"pay_type"];
    
    if (selectChannel.isCombinePay) {
        if (selectChannel.combineType == BDPayChannelTypeIncomePay) {
            [dic cj_setObject:@"129" forKey:@"combine_type"];
        } else {
            [dic cj_setObject:@"3" forKey:@"combine_type"];
        }
    }
    
    if (self.isBindCardAndPay && self.bindcardResultModel) {
        [dic cj_setObject:self.bindcardResultModel.signNo forKey:@"sign_no"];
        [dic cj_setObject:self.bindcardResultModel.token forKey:@"token"];
    }
    return [dic copy];
}

- (BOOL)sendEventTOVC:(CJPayHomeVCEvent)event obj:(id)object {
    if (self.homePageVC && [self.homePageVC respondsToSelector:@selector(receiveDataBus:obj:)]) {
        return [self.homePageVC receiveDataBus:event obj:object];
    }
    return NO;
}

#pragma mark - 发起支付流程 CJPayVerifyManagerEventFlowProtocol
- (void)begin {
    [self useLatestResponse];
    self.isBindCardAndPay = NO;
    
    CJPayVerifyType type = CJPayVerifyTypePassword;
    if ([self.homePageVC respondsToSelector:@selector(firstVerifyType)]) {
        type = [self.homePageVC firstVerifyType];
    }
    if (self.response.userInfo.isNeedAddPwd && ![self.response.payInfo.businessScene isEqualToString:@"Pre_Pay_Credit"]) {
        //已绑卡未设密, 进入补设密流程
        [self p_gotoLynxSetPassword];
    } else {
        [self p_addVerifyType:type];
        [self wakeSpecificType:type orderRes:self.response event:nil];
    }
    
    self.disableBioPay = NO;
    [self p_trackMainProcessWithProcessName:@"发起验证流程" source:@"begin流程" extParams:@{
        @"type" : @(type)
    }];
}

// 点击确认按钮，发起支付的网络请求
- (void)submitConfimRequest:(NSDictionary *)extraParams fromVerifyItem:(nullable CJPayVerifyItem *)verifyItem {
    if (verifyItem) {
        self.lastConfirmVerifyItem = verifyItem;
    }
    
    // 上报事件
    [[CJPayMetaSecManager defaultService] reportForScene:@"caijing_risk_pay_request"];
    
    CJPayChannelType channelType = self.defaultConfig.type;
    // 月付
    if (channelType == BDPayChannelTypeCreditPay) {
        [[CJPayMetaSecManager defaultService] reportForScene:@"caijing_xyzf_withdraw_request"];
    }
    
    if (self.verifyManagerQueen && [self.verifyManagerQueen respondsToSelector:@selector(beforeConfirmRequest)]) {
        [self.verifyManagerQueen beforeConfirmRequest];
    }
    
    // 判断是否跳过确认支付网络请求（下单接口与确认支付接口合并，下单时已拿到确认支付结果）
    if (self.response.confirmResponse != nil && self.isSkipConfirmRequest) {
        [self p_handleConfirmResponse:self.response.confirmResponse lastVerifyItem:verifyItem];
        self.isSkipConfirmRequest = NO;
        return;
    }
    
    @CJStartLoading(self)
    // 网络请求发起
    NSMutableDictionary *extraRequestParams = [NSMutableDictionary new];
    self.isNeedOpenBioPay = [extraParams cj_boolValueForKey:@"selected_bio_pay"];
    
    if (extraParams != nil) {
        [extraRequestParams addEntriesFromDictionary:extraParams];
        [extraRequestParams removeObjectForKey:@"selected_bio_pay"];
    }
    
    CJPayStayAlertForOrderModel *model = [CJPayKVContext kv_valueForKey:CJPayStayAlertShownKey];
    NSMutableDictionary *exts = [NSMutableDictionary new];
    // 判断当前聚合单号曝光过才会传入参数
    if (Check_ValidString(model.tradeNo) && [model.tradeNo isEqualToString:self.response.intergratedTradeIdentify] && model.hasShow) {
        [exts addEntriesFromDictionary:model.userRetainInfo];
    }

    [exts addEntriesFromDictionary:[self otherExtsParamsForQueryOrder]];
    [extraRequestParams setObject:exts forKey:@"exts"];
    
    NSDictionary *payChannelParams = [self buildConfirmRequestParamsByCurPayChannel];
    if (payChannelParams != nil) {
        [extraRequestParams addEntriesFromDictionary:payChannelParams];
    }
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    self.startConfirmTimestamp = [date timeIntervalSince1970]*1000;
    self.isNoTradeQuery = NO;
    
    @CJWeakify(self)
    [self requestConfirmPayWithOrderResponse:self.response withExtraParams:extraRequestParams completion:^(NSError * _Nonnull error, CJPayOrderConfirmResponse * _Nonnull response) {
        @CJStrongify(self)
        [self p_handleConfirmResponse:response lastVerifyItem:verifyItem];
    }];
}

- (void)p_gotoLynxSetPassword {
    [self p_trackMainProcessWithProcessName:@"进入补设密流程" source:@"拉起验证组件前" extParams:@{
        @"add_pwd_url" : CJString(self.response.userInfo.addPwdUrl)
    }];
    [CJPayDeskUtil openLynxPageBySchema:self.response.userInfo.addPwdUrl completionBlock:^(CJPayAPIBaseResponse * _Nonnull response) {
        [self p_trackMainProcessWithProcessName:@"补设密流程" source:@"补设密流程回调" extParams:@{
            @"data" : response.data ?: @{}
        }];
        NSDictionary *data = response.data;
        NSDictionary *dataDic = [data cj_dictionaryValueForKey:@"data"];
        NSDictionary *msgDic = [dataDic cj_dictionaryValueForKey:@"msg"];
        if (msgDic) {
            int code = [msgDic cj_intValueForKey:@"code" defaultValue:0];
            int isCancelPay = [msgDic cj_intValueForKey:@"is_cancel_pay"defaultValue:0];
            NSString *token = [msgDic cj_stringValueForKey:@"token"];
            if (code == 1 && Check_ValidString(token) && isCancelPay == 0) {
                self.token = token;
                if (self.response.needResignCard) {
                    [self p_addVerifyType:CJPayVerifyTypeSignCard];
                    [self wakeSpecificType:CJPayVerifyTypeSignCard orderRes:self.response event:nil];
                } else {
                    [self p_addVerifyType:CJPayVerifyTypeToken];
                    [self wakeSpecificType:CJPayVerifyTypeToken orderRes:self.response event:nil];
                }
            } else {
                [self sendEventTOVC:CJPayHomeVCEventBindCardNoPwdCancel obj:@(0)];
            }
        }
    }];
}

- (void)p_trackMainProcessWithProcessName:(NSString *)processName source:(NSString *)source extParams:(NSDictionary *)extParams {
    [self.verifyManagerQueen trackVerifyWithEventName:@"wallet_rd_main_process" params:@{
        @"process_name" : CJString(processName),
        @"process_source" : CJString(source),
        @"ext_params" : extParams ?: @{}
    }];
}

// 处理确认支付response
- (void)p_handleConfirmResponse:(CJPayOrderConfirmResponse *)response lastVerifyItem:(nullable CJPayVerifyItem *)verifyItem {
    
    if (verifyItem.verifyType != CJPayVerifyTypePassword) {
        [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeRiskUserVerifyResult];
    }
    self.confirmResponse = response;
    if (self.verifyManagerQueen && [self.verifyManagerQueen respondsToSelector:@selector(afterConfirmRequestWithResponse:)]) {
        [self.verifyManagerQueen afterConfirmRequestWithResponse:response];
    }
    //当processInfo有效时，客户端需要更新其保存的下单接口返回的process_info值
    if ([response.processInfo isValid]) {
        self.response.processInfo = response.processInfo;
    }
    
    if ([self needInvokeLoginAndReturn:response]) {
        @CJStopLoading(self)
        return;
    }
    if ([self shouldHandleVerifyResponse:response]) {
        @CJStopLoading(self)
        [self handleVerifyResponse:response];
        return;
    }
    // 余额不足
    if ([@[@"CD005002", @"CD005027"] containsObject:CJString(response.code)]) {
        @CJStopLoading(self)
        [self sendEventTOVC:CJPayHomeVCEventNotifySufficient obj:response];
        return;
    }
    // 组合受限
    if ([response.code isEqualToString:@"CD005022"] || [response.code isEqualToString:@"CD005104"]) {
        @CJStopLoading(self)
        [self sendEventTOVC:CJPayHomeVCEventCombinePayLimit obj:response];
        return;
    }
    if (response.buttonInfo) {
        @CJStopLoading(self)
        if ([response.buttonInfo.right_button_action integerValue] == CJPayButtonInfoHandlerTypeUploadIDCard) {
            CJPayVerifyItem *verifyItem = [self getSpecificVerifyType:CJPayVerifyTypeUploadIDCard];
            self.lastHandleVerifyItem = verifyItem;
        }
        
        CJPayButtonInfoHandlerActionsModel *actionModels = [self commonButtonInfoModelWithResponse:response];
        response.buttonInfo.code = response.code;
        
        [[CJPayBDButtonInfoHandler shareInstance] handleButtonInfo:response.buttonInfo
                                                          fromVC:[self.homePageVC topVC]
                                                        errorMsg:response.msg
                                                     withActions:actionModels
                                                   trackDelegate:self.verifyManagerQueen
                                                       withAppID:self.response.merchant.appId
                                                      merchantID:self.response.merchant.merchantId];
        
        return;
    }
    
    [self confirmRequestSuccess:response withChannelType:self.defaultConfig.type];
}

- (void)confirmRequestSuccess:(CJPayOrderConfirmResponse *)response withChannelType:(CJPayChannelType) channelType {
    if (response.isSuccess) {
        [self submitQueryRequest];
    }
}

- (void)submitQueryRequest {
    if (self.verifyManagerQueen && [self.verifyManagerQueen respondsToSelector:@selector(beforQueryResult)]) {
        [self.verifyManagerQueen beforQueryResult];
    }
    [self queryOrderResult:[self.response.resultConfig queryResultTimes]];
}

- (void)p_queryOrderFinishWithResultResponse:(CJPayBDOrderResultResponse *)resultResponse {
    self.resResponse.status = (resultResponse.tradeInfo.tradeStatus == CJPayOrderStatusSuccess) ? @"1" : @"0";
    
    if (!self.isStandardDouPayProcess) {
        [self.homePageVC endVerifyWithResultResponse:resultResponse];
        return;
    }
    
    if (![resultResponse isSuccess]) {
        [self.homePageVC endVerifyWithResultResponse:resultResponse];
        return;
    }
    @CJWeakify(self)
    if (self.response.preBioGuideInfo && self.isNeedOpenBioPay) {
        @CJStrongify(self)
        [self p_sendRequestToEnableBioPaymentWithCompletion:^{
            @CJStrongify(self)
            [self.homePageVC endVerifyWithResultResponse:resultResponse];
        }];
        return;
    }
    
    if (Check_ValidString(resultResponse.skipPwdOpenMsg)) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [CJToast toastText:resultResponse.skipPwdOpenMsg inWindow:[self.homePageVC topVC].cj_window];
        });
    }
    [self.homePageVC endVerifyWithResultResponse:resultResponse];
}

- (void)p_sendRequestToEnableBioPaymentWithCompletion:(void (^)(void))completion {
    NSMutableDictionary *requestModel = [NSMutableDictionary new];
    [requestModel cj_setObject:self.response.merchant.appId forKey:@"app_id"];
    [requestModel cj_setObject:self.response.merchant.merchantId forKey:@"merchant_id"];
    [requestModel cj_setObject:self.response.userInfo.uid forKey:@"uid"];
    [requestModel cj_setObject:self.response.tradeInfo.tradeNo forKey:@"trade_no"];
    [requestModel cj_setObject:[self.response.processInfo dictionaryValue] forKey:@"process_info"];
    [requestModel cj_setObject:[CJPaySafeManager buildEngimaEngine:@""] forKey:@"engimaEngine"];
    
    CJ_DECLARE_ID_PROTOCOL(CJPayBioPaymentPlugin);
    NSDictionary *pwdDic = [objectWithCJPayBioPaymentPlugin buildPwdDicWithModel:requestModel lastPWD:self.lastPWD];
    @CJWeakify(self)
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleHalfLoading];
    [objectWithCJPayBioPaymentPlugin openBioPay:requestModel withExtraParams:pwdDic completion:^(NSError * _Nonnull error, BOOL result) {
        @CJStrongify(self)
        BOOL isBioFinger = [[objectWithCJPayBioPaymentPlugin bioType] isEqualToString:@"1"];
        if (result) {
            NSString *msg = isBioFinger ? @"指纹支付已开通" : @"面容支付已开通";
            [CJToast toastText:msg code:@"" duration:1 inWindow:[self.homePageVC topVC].cj_window];
        } else {
            NSString *msg = isBioFinger ? @"指纹支付开通失败" : @"面容支付开通失败";
            [CJToast toastText:msg code:@"" duration:1 inWindow:[self.homePageVC topVC].cj_window];
        }
        [[CJPayLoadingManager defaultService] stopLoading];
        CJ_CALL_BLOCK(completion);
    }];
}

#pragma mark - 处理网络请求 CJPayVerifyManagerRequestProtocol

- (void)requestQueryOrderResultWithTradeNo:(NSString *)tradeNo processInfo:(CJPayProcessInfo *)processInfo completion:(void (^)(NSError * _Nullable, CJPayBDOrderResultResponse * _Nonnull))completionBlock {
    
    if (self.confirmResponse.orderResultResponse) {
        self.isNoTradeQuery = YES;
        CJPayBDOrderResultResponse *response = self.confirmResponse.orderResultResponse;
        self.confirmResponse.orderResultResponse = nil;
        CJ_CALL_BLOCK(completionBlock, nil, response);
        return;
    }
    
    CJPayStayAlertForOrderModel *model = [CJPayKVContext kv_valueForKey:CJPayStayAlertShownKey];
    NSMutableDictionary *exts = [NSMutableDictionary new];
    // 判断当前聚合单号曝光过才会传入参数
    if (Check_ValidString(model.tradeNo) && [model.tradeNo isEqualToString:self.response.intergratedTradeIdentify] && model.hasShow) {
        [exts addEntriesFromDictionary:model.userRetainInfo];
    }

    [exts addEntriesFromDictionary:[self otherExtsParamsForQueryOrder]];
    
    [CJPayBDOrderResultRequest startWithAppId:self.response.merchant.appId merchantId:self.response.merchant.merchantId tradeNo:tradeNo processInfo:processInfo exts:exts completion:completionBlock];
}

- (void)requestConfirmPayWithOrderResponse:(CJPayBDCreateOrderResponse *)orderResponse withExtraParams:(NSDictionary *)extraParams completion:(void (^)(NSError * _Nonnull, CJPayOrderConfirmResponse * _Nonnull))completionBlock {
    [CJKeyboard prohibitKeyboardShow];
    if (self.isBindCardAndPay) {
        [CJPayNewCardPayRequest startWithOrderResponse:orderResponse withExtraParams:extraParams completion:^(NSError * _Nonnull error, CJPayOrderConfirmResponse * _Nonnull response) {
            [CJKeyboard permitKeyboardShow];
            CJ_CALL_BLOCK(completionBlock,error,response);
        }];
    } else {
        [CJPayOrderConfirmRequest startWithOrderResponse:orderResponse withExtraParams:extraParams completion:^(NSError *error, CJPayOrderConfirmResponse *response) {
            [CJKeyboard permitKeyboardShow];
            NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
            double durationTime = [[NSDate date] timeIntervalSince1970] * 1000 - [trackData btd_doubleValueForKey:@"start_time" default:0];
            [trackData addEntriesFromDictionary:@{
                @"client_duration":@(durationTime),
                @"sdk_err_msg":CJString(response.msg),
                @"biz_err_code":CJString(response.code)
            }];
            [CJTracker event:@"wallet_cashier_bd_trade_confirm_result"
                      params:trackData];
            CJ_CALL_BLOCK(completionBlock,error,response);
        }];
    }
}

- (NSString *)lastVerifyCheckTypeName {
    if (self.lastConfirmVerifyItem) {
        return CJString([self.lastConfirmVerifyItem checkTypeName]);
    } else {
        return @"无";
    }
}

- (void)p_addVerifyType:(CJPayVerifyType)curVerifyType {
    if (![self.verifyTypeArray containsObject:@(curVerifyType)]) {
        [self.verifyTypeArray addObject:@(curVerifyType)];
    }
}

- (NSString *)allRiskVerifyTypes {
    NSMutableArray *array = [NSMutableArray new];
    [self.verifyTypeArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CJPayVerifyItem *verifyItem = [self getSpecificVerifyType:(CJPayVerifyType)([obj intValue])];
        if (verifyItem) {
            [array addObject:CJString([verifyItem checkTypeName])];
        }
    }];
    if (array.count <= 0) {
        return @"无";
    }
    return [array componentsJoinedByString:@","];
}

- (NSString *)issueCheckType {
    CJPayVerifyType type = [self.homePageVC firstVerifyType];
    return [[self getSpecificVerifyType:type] checkType];
    
}

- (NSDictionary *)otherExtsParamsForQueryOrder {
    return nil;
}

#pragma mark - CJPayVerifyManagerPayNewCardProtocol
- (void)onBindCardAndPayAction {
    self.isBindCardAndPay = YES;
    [self useLatestResponse];
    //子类实现具体的绑卡并支付逻辑
}

#pragma mark - CJPayBaseLoadingProtocol
- (void)startLoading {
    if (self.loadingDelegate) {
        @CJStartLoading(self.loadingDelegate)
    } else if ([[UIViewController cj_topViewController] isKindOfClass:CJPayHalfPageBaseViewController.class]) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading];
    } else {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading];
    }
}

- (void)stopLoading {
    if (self.loadingDelegate) {
        @CJStopLoading(self.loadingDelegate)
    } else {
        [[CJPayLoadingManager defaultService] stopLoading];
    }
}

- (void)stopLoadingWithResResponse:(CJPayBDOrderResultResponse *)response {
    if (self.loadingDelegate) {
        if ([self.loadingDelegate respondsToSelector:@selector(stopLoadingWithState:)]) {
            switch (response.tradeInfo.tradeStatus) {
                case CJPayOrderStatusSuccess:
                    [self.loadingDelegate stopLoadingWithState:CJPayLoadingQueryStateSuccess];
                    break;
                case CJPayOrderStatusFail:
                    [self.loadingDelegate stopLoadingWithState:CJPayLoadingQueryStateFail];
                    break;
                case CJPayOrderStatusTimeout:
                    [self.loadingDelegate stopLoadingWithState:CJPayLoadingQueryStateTimeout];
                    break;
                case CJPayOrderStatusProcess:
                    [self.loadingDelegate stopLoadingWithState:CJPayLoadingQueryStateProcessing];
                    break;
                default:
                    @CJStopLoading(self.loadingDelegate)
                    break;
            }
        } else {
            @CJStopLoading(self.loadingDelegate)
        }
    } else {
        [[CJPayLoadingManager defaultService] stopLoading];
    }
}

- (void)p_addLoadingViewInTopHalfVC {
    if (![CJPaySettingsManager shared].currentSettings.rdOptimizationConfig.isAddLoadingViewInTopHalfPage) {
        return;
    }
    
    UIView *topLoadingView = [[CJPayLoadingManager defaultService] getCurrentHalfLoadingView];
    if ([CJPayLoadingManager defaultService].isLoading && topLoadingView) {
        UIViewController *topVC = [UIViewController cj_topViewController];
        if ([topVC isKindOfClass:CJPayHalfPageBaseViewController.class] && [topVC.navigationController isKindOfClass:CJPayNavigationController.class]) {
            
            UIImage *loadingSnapImage = [CJPayCommonUtil snapViewToImageView:topLoadingView];
            UIImageView *loadingSnapImageView = [[UIImageView alloc] initWithImage:loadingSnapImage];
            [(CJPayHalfPageBaseViewController *)topVC addLoadingViewInTopLevel:loadingSnapImageView];
        }
    }
}

- (void)exitBindCardStatus {
    self.isBindCardAndPay = NO;
}

#pragma mark - Getter
- (NSMutableDictionary *)verifyTypeMap {
    if (!_verifyTypeMap) {
        _verifyTypeMap = [NSMutableDictionary new];
        [_verifyItemConfig enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([key isKindOfClass:NSNumber.class]) {
                NSNumber *type = (NSNumber *)key;
                [self getSpecificVerifyType:(CJPayVerifyType)type.intValue];
            }
        }];
    }
    return _verifyTypeMap;
}

- (NSMutableArray *)verifyTypeArray {
    if (!_verifyTypeArray) {
        _verifyTypeArray = [NSMutableArray array];
    }
    return _verifyTypeArray;
}

@end
