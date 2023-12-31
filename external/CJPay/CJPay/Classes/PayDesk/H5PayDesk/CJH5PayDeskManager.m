//
//  CJH5PayDeskManager.m
//  CJPay
//
//  Created by 尚怀军 on 2019/8/1.
//

#import "CJH5PayDeskManager.h"
#import "CJPayWebViewUtil.h"
#import "CJPayCookieUtil.h"
#import "CJBizWebDelegate.h"
#import <TTReachability/TTReachability.h>
#import "CJPayPrivateServiceHeader.h"
#import "CJPayCommonUtil.h"
#import "NSDictionary+CJPay.h"
#import "CJPayBizURLBuilder.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayRequestParam.h"
#import "CJPaySafeManager.h"
#import "CJPaySettings.h"
#import "CJPaySettingsManager.h"
#import "CJPayChannelManagerModule.h"
#import "CJPayNavigationController.h"
#import "CJPayWebviewStyle.h"

@interface CJH5PayDeskManager()

@property (nonatomic,weak) CJPayBizWebViewController *h5CashDeskVC;

@end

@implementation CJH5PayDeskManager

+ (instancetype)defaultService {
    static CJH5PayDeskManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CJH5PayDeskManager alloc] init];
    });
    return manager;
}

- (BOOL)isSupportPayCallBackURL:(nonnull NSURL *)URL {
    return [CJ_OBJECT_WITH_PROTOCOL(CJPayChannelManagerModule) i_canProcessURL:URL];
}

- (void)registerPayRefer:(NSString *)referUrl {
    [CJ_OBJECT_WITH_PROTOCOL(CJPayChannelManagerModule) i_registerWXH5PayReferUrlStr:referUrl];
}

#pragma mark - service
- (void)openH5CashDeskWithURL:(NSString *)url
                 orderInfoDic:(NSDictionary *)orderInfoDic
                   merchantId:(NSString *)merchantId
                        appId:(NSString *)appId
                cashDeskStyle:(CJH5CashDeskStyle)cashDeskStyle
                   completion:(void(^)(CJPayManagerResultType result, NSDictionary *resultParam))completionBlock {
   
    CJPayLogInfo(@"调起H5收银台, url = %@, orderInfoDic = %@, merchantId = %@, appId = %@, cashDeskStyle = %@", url, orderInfoDic, merchantId, appId, @(cashDeskStyle));
    if (self.h5CashDeskVC != nil && self.h5CashDeskVC.isViewLoaded && self.h5CashDeskVC.view.window != nil) {
        [self p_reportMonitorWithParams:@{} URL:url merchantId:merchantId appId:appId type:@"multiCall"];
        CJPayLogInfo(@"请不要连续多次调用收银台！");
        return;
    }
    
    NSDictionary * params = [self _prepareCallParam:cashDeskStyle
                                       orderInfoDic:orderInfoDic];
    
    if (![params cj_stringValueForKey:@"order_info"]) {
        CJPayLogInfo(@"没有order_info, 调起收银台失败！");
        [self p_reportMonitorWithParams:params URL:url merchantId:merchantId appId:appId type:@"orderInfoNil"];
        CJ_CALL_BLOCK(completionBlock, CJPayManagerResultOpenFailed, nil);
        return;
    }
    
    NSString *finalUrl = [CJPayCommonUtil appendParamsToUrl:url params:params];
    if (!Check_ValidString(finalUrl)) {
        CJPayLogInfo(@"拼接后的url不合法, 调起收银台失败！");
        [self p_reportMonitorWithParams:params URL:url merchantId:merchantId appId:appId type:@"urlNotLegal"];
        CJ_CALL_BLOCK(completionBlock, CJPayManagerResultOpenFailed, nil);
        return;
    }
    
    TTReachability *reachAbility = [TTReachability reachabilityForInternetConnection];
    if (reachAbility.currentReachabilityStatus == NotReachable) {
        CJPayLogInfo(@"无网，调起收银台失败！");
        CJ_CALL_BLOCK(completionBlock, CJPayManagerResultOpenFailed, nil);
        return;
    }
    
    CJPayBizWebViewController *cashDeskVC = [self buildWebBizVC:cashDeskStyle
                                                       finalUrl:finalUrl
                                                     completion:completionBlock];
    self.h5CashDeskVC = cashDeskVC;
    if (cashDeskStyle == CJH5CashDeskStyleVertivalFullScreen) {
        // 全屏h5收银台，需要支持左滑退出
        if ([[UIViewController cj_foundTopViewControllerFrom:url.cjpay_referViewController].navigationController isKindOfClass:[CJPayNavigationController class]]) {
            [[UIViewController cj_foundTopViewControllerFrom:url.cjpay_referViewController].navigationController pushViewController:cashDeskVC animated:YES];
        } else {
            [cashDeskVC presentWithNavigationControllerFrom:[UIViewController cj_foundTopViewControllerFrom:url.cjpay_referViewController] useMask:NO completion:nil];
        }
    } else {
        // 半屏h5收银台，外部通过端上api拉起的透明webview的h5收银台端上不做自动loading，loading时机交给h5控制
        cashDeskVC.showsLoading = NO;
        [cashDeskVC presentWithNavigationControllerFrom:[UIViewController cj_foundTopViewControllerFrom:url.cjpay_referViewController] useMask:NO completion:nil];
    }
}

- (void)openH5CashDeskWithOrderInfo:(NSDictionary *)orderInfoDic
                         merchantId:(NSString *)merchantId
                              appId:(NSString *)appId
                      cashDeskStyle:(CJH5CashDeskStyle)cashDeskStyle
                         completion:(void (^)(CJPayManagerResultType, NSDictionary * _Nonnull))completionBlock {
    NSString *url = [NSString stringWithFormat:@"%@/cashdesk_offline",[CJPayBizParam shared].configHost];
    [self openH5CashDeskWithURL:url
                   orderInfoDic:orderInfoDic
                     merchantId:merchantId
                          appId:appId
                  cashDeskStyle:cashDeskStyle
                     completion:completionBlock];
}

- (void)closeH5PayDesk {
    [self.h5CashDeskVC closeWebVC];
}


#pragma mark - private
- (CJPayBizWebViewController *)buildWebBizVC:(CJH5CashDeskStyle)cashDeskStyle
                                    finalUrl:(NSString *)finalUrl
                                  completion:(void(^)(CJPayManagerResultType result, NSDictionary *resultParam))completionBlock{
    CJPayBizWebViewController *vc = [CJPayBizWebViewController buildWebBizVC:cashDeskStyle finalUrl:finalUrl completion:^(id _Nonnull data) {
        NSDictionary *resultParam = (NSDictionary *)data;
        CJPayManagerResultType result;
        switch ([resultParam cj_intValueForKey:@"code"]) {
            case 0:
                result = CJPayManagerResultSuccess;
                break;
            case 1:
                result = CJPayManagerResultTimeout;
                break;
            case 2:
                result = CJPayManagerResultFailed;
                break;
            case 3:
                result = CJPayManagerResultCancel;
                break;
            default:
                result = CJPayManagerResultError;
                break;
        }
        CJ_CALL_BLOCK(completionBlock, result, resultParam);
    }];
    return vc;
}

- (NSDictionary *)_prepareCallParam:(CJH5CashDeskStyle)cashDeskStyle
                       orderInfoDic:(NSDictionary *)orderInfoDic {
    NSMutableDictionary *paramsDic = [[NSMutableDictionary alloc]init];
    NSMutableDictionary *deviceInfoDic = [[NSMutableDictionary alloc]init];
    deviceInfoDic[@"statusbar_height"] = [NSString stringWithFormat:@"%d", CJ_STATUSBAR_HEIGHT];
    NSData *deviceInfoData = [[CJPayCommonUtil dictionaryToJson:deviceInfoDic] dataUsingEncoding:NSUTF8StringEncoding];
  
    
    NSString *deviceInfoBase64Str = [CJPayCommonUtil replaceNoEncoding:[deviceInfoData base64EncodedStringWithOptions:0]];
    if (Check_ValidString(deviceInfoBase64Str)) {
        paramsDic[@"device_info"] = deviceInfoBase64Str;
    }
    
    NSString *orderInfoBase64Str;
    if (orderInfoDic){
        NSData *orderInfoData = [[CJPayCommonUtil dictionaryToJson:orderInfoDic] dataUsingEncoding:NSUTF8StringEncoding];
        orderInfoBase64Str = [CJPayCommonUtil replaceNoEncoding:[orderInfoData base64EncodedStringWithOptions:0]];
    }
    if Check_ValidString(orderInfoBase64Str) {
        paramsDic[@"order_info"] = orderInfoBase64Str;
    }
 
    NSString *cashDeskStyleString = @"0";
    switch (cashDeskStyle) {
        case CJH5CashDeskStyleVertivalHalfScreen:
            cashDeskStyleString = @"0";
            break;
        case CJH5CashDeskStyleVertivalFullScreen:
            cashDeskStyleString = @"1";
            break;
        case CJH5CashDeskStyleLandscapeHalfScreen:
            cashDeskStyleString = @"2";
            break;
        default:
            break;
    }
    
    paramsDic[@"fullpage"] = cashDeskStyleString;
    paramsDic[@"cashdesk_scene"] = [orderInfoDic cj_stringValueForKey:@"cashdesk_scene"];
    
    return paramsDic;

}

- (void)p_reportMonitorWithParams:(NSDictionary *)params URL:(NSString *)url merchantId:(NSString *)merchantId appId:(NSString *)appId type:(NSString *)type{
    NSMutableDictionary *extraDic = [NSMutableDictionary dictionaryWithDictionary:params];
    [extraDic cj_setObject:url forKey:@"url"];
    [extraDic cj_setObject:merchantId forKey:@"merchantId"];
    [extraDic cj_setObject:appId forKey:@"appId"];
    [CJMonitor trackService:@"wallet_rd_open_h5pay_failure" metric:@{} category:@{@"failure_type":type} extra:@{@"call_stack":extraDic}];
}

@end

@interface CJH5PayDeskManager(ModuleSupport)<CJPayH5DeskModule>

@end

@implementation CJH5PayDeskManager(ModuleSupport)

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(defaultService), CJPayH5DeskModule)
})

#pragma mark - ModuleSupport
- (void)i_openH5PayDesk:(NSString *)url withDelegate:(id<CJPayAPIDelegate>)delegate {
    @CJWeakify(self)
    [self openH5CashDeskWithURL:url orderInfoDic:@{} merchantId:@"" appId:@"" cashDeskStyle:CJH5CashDeskStyleVertivalHalfScreen completion:^(CJPayManagerResultType result, NSDictionary * _Nonnull resultParam) {
        @CJStrongify(self)
        [self p_processCallback:result resultParam:resultParam apiDelegate:delegate];
    }];
}

- (void)i_openH5PayDesk:(NSDictionary *)orderInfoDic deskStyle:(CJH5CashDeskStyle)deskStyle withDelegate:(id<CJPayAPIDelegate>)delegate {
    @CJWeakify(self)
    NSString *appId = [orderInfoDic cj_stringValueForKey:@"app_id"];
    NSString *merchantId = [orderInfoDic cj_stringValueForKey:@"merchant_id"];
    [self openH5CashDeskWithOrderInfo:orderInfoDic merchantId:merchantId appId:appId cashDeskStyle:deskStyle completion:^(CJPayManagerResultType result, NSDictionary * _Nonnull resultParam) {
        @CJStrongify(self)
        [self p_processCallback:result resultParam:resultParam apiDelegate:delegate];
    }];
}

#pragma mark - BDPayH5PayService
- (void)i_openH5PayManagerWithAppId:(NSString *)appId merchantId:(NSString *)merchantId
{
    NSString *payManagerUrl = [NSString stringWithFormat:@"%@/usercenter/paymng?merchant_id=%@&app_id=%@&native_bank=1",[CJPayBaseRequest bdpayH5DeskServerHostString], merchantId, appId];
    [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:[UIViewController cj_foundTopViewControllerFrom:appId.cjpay_referViewController] toUrl:payManagerUrl];
}

- (void)i_openH5BankCardListWithMerchantId:(NSString *)merchantId
                                     appId:(NSString *)appId
                                    userId:(NSString *)userId
{
    NSString *url = [CJPayBizURLBuilder generateURLForType:CJPayURLSceneWebCardList withAppId:appId withMerchantId:merchantId otherParams:@{@"user_id": CJString(userId)}];
    [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:[UIViewController cj_foundTopViewControllerFrom:merchantId.cjpay_referViewController] toUrl:url];
}

- (void)i_openH5BalanceWithdrawDeskWithParams:(NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate
{
    NSString *url = [CJPayBizURLBuilder generateURLForType:CJPayURLSceneWebBalanceWithdraw withAppId:@"" withMerchantId:@"" otherParams:params];
    [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:[UIViewController cj_foundTopViewControllerFrom:params.cjpay_referViewController] toUrl:url];
}

- (void)i_openH5TradeRecordWithAppId:(NSString *)appId merchantId:(NSString *)merchantId
{
    NSString *tradeRecordUrl = [CJPayBizURLBuilder generateURLForType:CJPayURLSceneWebTradeRecord withAppId:appId withMerchantId:merchantId otherParams:@{}];

    [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:[UIViewController cj_foundTopViewControllerFrom:appId.cjpay_referViewController] toUrl:tradeRecordUrl];
}

- (void)i_openH5BDPayDesk:(NSDictionary *)orderInfoDic withDelegate:(id<CJPayAPIDelegate>)delegate
{
    @CJWeakify(self)
    [self p_openBDH5PayDeskWithParams:orderInfoDic openDeskBlock:^(BOOL isSuccess) {
        
        if ([delegate respondsToSelector:@selector(callState:fromScene:)]) {
            [delegate callState:isSuccess fromScene:CJPaySceneBDPay];
        }
        
    } completion:^(CJPayManagerResultType type, NSDictionary * _Nonnull data) {
        
        @CJStrongify(self)
        [self p_processCallback:type resultParam:data apiDelegate:delegate];
        
    }];
}

- (void)p_openBDH5PayDeskWithParams:(NSDictionary *)params openDeskBlock:(void (^)(BOOL))openDeskBlock completion:(void (^)(CJPayManagerResultType, NSDictionary * _Nonnull))completionBlock {
    
    if (self.h5CashDeskVC && self.h5CashDeskVC.isViewLoaded && self.h5CashDeskVC.view.window) {
        CJPayLogInfo(@"请不要连续多次调用收银台！");
        CJ_CALL_BLOCK(openDeskBlock,NO);
        return;
    }
    
    NSString *bdH5PayDeskUrl = [NSString stringWithFormat:@"%@/cashdesk/bytepay",[CJPayBaseRequest bdpayH5DeskServerHostString]];
    
    NSString *orderInfoBase64Str;
    if (params){
        NSData *orderInfoData = [[CJPayCommonUtil dictionaryToJson:params] dataUsingEncoding:NSUTF8StringEncoding];
        orderInfoBase64Str = [CJPayCommonUtil replaceNoEncoding:[orderInfoData base64EncodedStringWithOptions:0]];
    }

    NSString *riskInfoBase64Str;
    NSDictionary *riskInfoDict = [CJPayRequestParam riskInfoDict];
    riskInfoDict = [riskInfoDict cj_dictionaryValueForKey:@"risk_str"];
    if (riskInfoDict) {
        NSData *riskInfoData = [[CJPayCommonUtil dictionaryToJson:riskInfoDict] dataUsingEncoding:NSUTF8StringEncoding];
        riskInfoBase64Str = [CJPayCommonUtil replaceNoEncoding:[riskInfoData base64EncodedStringWithOptions:0]];
    }
    
    NSDictionary *h5Params = @{
        @"order_info": CJString(orderInfoBase64Str),
        @"fullpage": @"0",
        @"risk_info": CJString(riskInfoBase64Str),
    };
    
    NSString *finalUrl = [CJPayCommonUtil appendParamsToUrl:bdH5PayDeskUrl params:h5Params];

    CJPayBizWebViewController *cashDeskVC = [self p_buildWebBizVCWithFinalUrl:finalUrl completion:completionBlock];
    self.h5CashDeskVC = cashDeskVC;
    
    // 半屏h5收银台，外部通过端上api拉起的透明webview的h5收银台端上不做自动loading，loading时机交给h5控制
    cashDeskVC.showsLoading = NO;
    
    CJ_CALL_BLOCK(openDeskBlock,YES);
    [cashDeskVC presentWithNavigationControllerFrom:[UIViewController cj_foundTopViewControllerFrom:params.cjpay_referViewController] useMask:NO completion:nil];
}

- (CJPayBizWebViewController *)p_buildWebBizVCWithFinalUrl:(NSString *)finalUrl completion:(void(^)(CJPayManagerResultType result, NSDictionary *resultParam))completionBlock{
    CJPayBizWebViewController *vc = [CJPayBizWebViewController buildWebBizVC:CJH5CashDeskStyleVertivalHalfScreen
                                                                    finalUrl:finalUrl
                                                                  completion:^(id _Nonnull data) {
        
        NSDictionary *resultParam = (NSDictionary *)data;
        NSString *service = [resultParam cj_stringValueForKey:@"service"];
        if (![service isEqualToString:@"200"]) {
            return;
        }
        
        CJPayManagerResultType result;
        switch ([resultParam cj_intValueForKey:@"code"]) {
            case 0:
                result = CJPayManagerResultSuccess;
                break;
            case 1:
                result = CJPayManagerResultTimeout;
                break;
            case 2:
                result = CJPayManagerResultFailed;
                break;
            case 3:
                result = CJPayManagerResultCancel;
                break;
            case 9:
                result = CJPayManagerResultProcessing;
                break;
            default:
                result = CJPayManagerResultError;
                break;
        }
        CJ_CALL_BLOCK(completionBlock, result, resultParam);
    }];
    return vc;
}


- (void)p_processCallback:(CJPayManagerResultType )result resultParam:(NSDictionary *)resultParam apiDelegate:(id<CJPayAPIDelegate>) delegate {
    CJPayErrorCode code = CJPayErrorCodeFail;
    NSString *errorDesc = @"";
    switch (result) {
        case CJPayManagerResultError:
            code = CJPayErrorCodeFail;
            errorDesc = @"未知错误";
            [CJMonitor trackService:@"wallet_rd_h5pay_result" metric:@{} category:@{@"callback_error":@YES} extra:@{}];
            break;
         case CJPayManagerResultCancel:
            code = CJPayErrorCodeCancel;
            errorDesc = @"取消支付";
            break;
        case CJPayManagerResultSuccess:
            code = CJPayErrorCodeSuccess;
            errorDesc = @"支付成功";
            break;
        case CJPayManagerResultOpenFailed:
            code = CJPayErrorCodeFail;
            errorDesc = @"拉起支付失败";
            break;
        case CJPayManagerResultTimeout:
            code = CJPayErrorCodeOrderTimeOut;
            errorDesc = @"支付订单超时";
            break;
        case CJPayManagerResultProcessing:
            code = CJPayErrorCodeProcessing;
            errorDesc = @"获取支付结果中...";
            break;
        case CJPayManagerResultFailed:
            code = CJPayErrorCodeFail;
            errorDesc = @"支付失败";
            break;
        default:
            break;
    }
    CJPayAPIBaseResponse *resp = [CJPayAPIBaseResponse new];
    resp.error = [NSError errorWithDomain:CJPayErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(errorDesc, nil)}];
    resp.scene = CJPaySceneH5Pay;
    resp.data = resultParam;
    if (delegate && [delegate respondsToSelector:@selector(onResponse:)]) {
        [delegate onResponse:resp];
    }
}

- (void)i_openH5SetPasswordDeskWithParams:(NSDictionary *)params
                             withDelegate:(id<CJPayAPIDelegate>)delegate {
    
    [self openH5SetPasswordDeskWithParams:params callBack:^(CJPayH5SetPasswordDeskCallBackType callBackType) {
        CJPayAPIBaseResponse *resq = [CJPayAPIBaseResponse new];
        resq.scene = CJPaySceneAuth;
        NSError *error;
        switch (callBackType) {
            case CJPayH5SetPasswordDeskCallBackTypeCancel:
                error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeCancel userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"设密取消", nil)}];
                break;
            case CJPayH5SetPasswordDeskCallBackTypeSuccess:
                error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeSuccess userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"设密成功", nil)}];
                break;
            default:
                error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeFail userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"设密失败", nil)}];
                break;
        }
        resq.error = error;
        if (delegate && [delegate respondsToSelector:@selector(onResponse:)]) {
            [delegate onResponse:resq];
        }
    }];
}

- (void)openH5SetPasswordDeskWithParams:(NSDictionary *)params
callBack:(void (^)(CJPayH5SetPasswordDeskCallBackType callBackType))callBack {
    NSDictionary* paramsDic = [self p_dealChannelOrderInfo:params];
    NSString *url = [self p_getUrl:paramsDic];
    if (!Check_ValidString(url)) {
        return;//直接退出，返回设密失败
    }
    [[CJPayWebViewUtil sharedUtil] openH5ModalViewFrom:[UIViewController cj_foundTopViewControllerFrom:params.cjpay_referViewController]
              toUrl:url
              style:CJH5CashDeskStyleVertivalFullScreen
        showLoading:YES
    backgroundColor:[CJPayWebviewStyle new].webBcgColor
           animated:YES
      closeCallBack:^(id  _Nonnull data) {
          NSDictionary *dic = (NSDictionary *)data;
          if (dic && [dic isKindOfClass:NSDictionary.class]) {
              NSString *service = [dic cj_stringValueForKey:@"service"];
              if ([service isEqualToString:@"43"]) {
                  if (callBack) {
                      callBack(CJPayH5SetPasswordDeskCallBackTypeSuccess);
                      return;
                  }
              }
          }
          if(callBack){
              callBack(CJPayH5SetPasswordDeskCallBackTypeCancel);
              return;
          }
        }backBlock:nil
    justCloseBlock:^{
            if (callBack) {
                callBack(CJPayH5SetPasswordDeskCallBackTypeCancel);
            }
        }];
}

- (NSString*)p_getUrl:(NSDictionary*)params {
    NSString *url = [NSString stringWithFormat:@"%@/usercenter/setpass", [CJPayBaseRequest deskServerHostString]];
    NSString *finalUrl = [CJPayCommonUtil appendParamsToUrl:url params:params];
    finalUrl = [CJPayCommonUtil appendParamsToUrl:finalUrl params:@{@"service":@"43", @"auth_type": @"1"}];
    return finalUrl;
}

- (NSDictionary*)p_dealChannelOrderInfo:(NSDictionary*)params {
    NSString *orderInfoBase64Str;
    NSString *channelOrderInfo = [params cj_stringValueForKey:@"channel_order_info"];
    NSMutableDictionary *paramsDic = [[NSMutableDictionary alloc]initWithDictionary:params];
    if (channelOrderInfo){
        orderInfoBase64Str = [CJPayCommonUtil replaceNoEncoding:[CJPayCommonUtil cj_base64:channelOrderInfo]];
    }
    if Check_ValidString(orderInfoBase64Str) {
        paramsDic[@"channel_order_info"] = orderInfoBase64Str;
    }
    return [paramsDic copy];
}

@end

@implementation CJH5PayDeskManager(Deprecated)

/**
 * 预加载支付渠道信息
 **/
- (void)preloadPayChannelInfoWithAppId:(NSString *)appId
                            merchantId:(NSString *)merchantId
                                userId:(NSString *)uid{
    // 废弃代码，下掉预加载
}

/**
 * 预加载支付渠道信息,可以通过传入ext字段(json字符串)的形式自定义一些样式
 **/
- (void)preloadPayChannelInfoWithAppId:(NSString *)appId
                            merchantId:(NSString *)merchantId
                                userId:(NSString *)uid
                                  exts:(NSString *)exts {
    // 废弃代码，下掉预加载
}

@end
