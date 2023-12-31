//
//  CJPayOuterPayLoadingViewController.m
//  Aweme
//
//  Created by wangxiaohong on 2022/10/11.
//

#import "CJPayOuterPayLoadingViewController.h"

#import "CJPayCreateOrderByTokenRequest.h"
#import "CJPayUIMacro.h"
#import "CJPayHomePageViewController.h"
#import "CJPaySubPayTypeSumInfoModel.h"
#import "CJPayDYPayBizDeskModel.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayCommonTrackUtil.h"
#import "CJPayRequestParam.h"
#import "CJPayKVContext.h"

@interface CJPayOuterPayLoadingViewController ()<CJPayAPIDelegate>

@property (nonatomic, strong) CJPayCreateOrderResponse *orderResponse; // 埋点用

@property (nonatomic, assign) BOOL isColdLaunch; // 是否为冷启动进入支付
@property (nonatomic, assign) double lastTimestamp; // 上一次上报 event 的时间戳

@end

@implementation CJPayOuterPayLoadingViewController

- (void)didFinishParamsCheck:(BOOL)isSuccess {
    if (!isSuccess) {
        return;
    }
    [self p_openCashDesk];
}

- (void)p_openCashDesk {
    [CJPayPerformanceMonitor trackAPIStartWithAPIScene:CJPayPerformanceAPISceneOuterPay extra:@{}];

    double currentTimestamp = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000;
    double startTimeStamp = [self.schemaParams btd_doubleValueForKey:@"start_time" default:0];
    self.lastTimestamp = currentTimestamp;
    if ([self.schemaParams cj_objectForKey:@"is_cold_launch"]) {
        self.isColdLaunch = [self.schemaParams cj_boolValueForKey:@"is_cold_launch"];
    } else {
        CJPayLogAssert(NO, @"params is_cold_launch is null.");
    }
    NSString *token = [self.schemaParams cj_stringValueForKey:@"token"]; //浏览器
    if (!Check_ValidString(token)) {
        // 未取到 token，可能是抖音以外 App 拉起
        token = [self.schemaParams cj_stringValueForKey:@"pay_token"];
        CJPayLogAssert(Check_ValidString(token), @"params token is null.");
    }
    
    NSDictionary *trackInfo = [self.schemaParams cj_dictionaryValueForKey:@"track_info"] ?: [NSDictionary new];
    NSString *traceID = CJString([trackInfo cj_stringValueForKey:@"trace_id"]);//做一层防护，避免trackInfo为nil
    
    NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
    double durationTime = (startTimeStamp > 100000) ? (currentTimestamp - startTimeStamp) : 0;
    [trackData addEntriesFromDictionary:@{@"client_duration":@(durationTime),
                                          @"duration": @(durationTime)}];
    [CJTracker event:@"wallet_cashier_opendouyin_loading" params:trackData];
    
    if (![[CJPayLoadingManager defaultService] isLoading]) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinOpenDeskLoading vc:self];
    }
    @CJWeakify(self);
    NSDictionary *params = @{@"token": CJString(token),
                                 @"params": @{
                                     @"host_app_name": CJString([self.schemaParams cj_stringValueForKey:@"app_name"])
                                 }};

    __auto_type completionBlock = ^(NSError *error, CJPayCreateOrderResponse *response) {
        @CJStrongify(self);
        [[CJPayLoadingManager defaultService] stopLoading];
    
        [self p_handleWithResponse:response traceID:traceID bizParams:params];
    };
    
    if ([[CJPayABTest getABTestValWithKey:CJPayEnableLaunchOptimize exposure:YES] isEqualToString:@"1"]) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayOuterModule) i_requestCreateOrderBeforeOpenBytePayDeskWith:self.schemaParams completion:^(NSError * _Nonnull error, NSDictionary * _Nonnull response) {
            id createOrderByTokenResponse = [response cj_objectForKey:@"create_order_by_token_response"];
            if (![createOrderByTokenResponse isKindOfClass:[CJPayCreateOrderResponse class]]) {
                createOrderByTokenResponse = nil;
            }
            CJ_CALL_BLOCK(completionBlock, error, createOrderByTokenResponse);
        }];
    } else {
        [CJPayCreateOrderByTokenRequest startWithBizParams:params bizUrl:@"" completion:^(NSError * _Nonnull error, CJPayCreateOrderResponse * _Nonnull response) {
            CJ_CALL_BLOCK(completionBlock, error, response);
        }];
    }
}

- (void)p_handleWithResponse:(CJPayCreateOrderResponse *)response traceID:(NSString *)traceID bizParams:(NSDictionary *)params {
    self.orderResponse = response;
    double totalResponseTime = 0.0; //初试值是0.0 如果上报的值也是0表示超时
    if (response.responseDuration) {
        totalResponseTime = response.responseDuration;
    }
    
    if (response && [response isSuccess]) {
        if (Check_ValidString(response.toastMsg)) {
            NSDictionary *impParam = [self p_mergeCommonParamsWith:@{
                @"toast_msg": CJString(response.toastMsg),
                @"trace_id": CJString(traceID)
            } response:response];
            [CJTracker event:@"wallet_payment_auth_fail_imp" params:impParam];

            @CJWeakify(self)
            [self alertRequestErrorWithMsg:response.toastMsg clickAction:^{
                @CJStrongify(self)
                NSDictionary *clickParam = [self p_mergeCommonParamsWith:@{
                    @"button_name": @"知道了",
                    @"trace_id": CJString(traceID)
                } response:response];
                [CJTracker event:@"wallet_payment_auth_fail_click" params:clickParam];
                [self p_orderCreateSuccessWithResponse:response traceID:traceID bizParams:params];
            }];
        } else {
            [self p_orderCreateSuccessWithResponse:response traceID:traceID bizParams:params];
        }
    } else {
        NSString *outerId = [self.schemaParams cj_stringValueForKey:@"app_id" defaultValue:@""];
        if (!Check_ValidString(outerId)) {
            outerId = [self.schemaParams cj_stringValueForKey:@"merchant_app_id" defaultValue:@""];
        }
        
        [CJTracker event:@"wallet_cashier_douyincashier_result"
                  params:@{@"result": @"0",
                           @"outer_aid" : CJString(outerId),
                           @"error_code": CJString(response.code),
                           @"error_msg": CJString(response.msg),
                           @"loading_time": [NSString stringWithFormat:@"%f", totalResponseTime],
                           @"trace_id" : traceID
                  }];
        NSString *alertText = Check_ValidString(response.msg) ? response.msg : CJPayNoNetworkMessage;
        @CJWeakify(self)
        [self alertRequestErrorWithMsg:alertText clickAction:^{
            @CJStrongify(self)
            [self closeCashierDeskAndJumpBackWithResult:CJPayDypayResultTypeFailed];
        }];
    }
}

- (void)p_orderCreateSuccessWithResponse:(CJPayCreateOrderResponse *)response traceID:(NSString *)traceID bizParams:(NSDictionary *)bizParams {
    self.tipLabel.text = CJString(response.deskConfig.headerTitle);
    
    if (Check_ValidString(self.orderResponse.dypayReturnURL)) {
        self.returnURL = self.orderResponse.dypayReturnURL;
    } else {
        self.returnURL = @"";
    }
    
    [self p_configCashRegisterVCWithResponse:response bizParams:bizParams];
    
    double totalResponseTime = 0.0; //初试值是0.0 如果上报的值也是0表示超时
    if (response.responseDuration) {
        totalResponseTime = response.responseDuration;
    }
    
    NSString *outerId = [self.schemaParams cj_stringValueForKey:@"app_id" defaultValue:@""];
    if (!Check_ValidString(outerId)) {
        outerId = [self.schemaParams cj_stringValueForKey:@"merchant_app_id" defaultValue:@""];
    }
    
    NSDictionary *resultTrackDic = @{
        @"result": @"1",
        @"outer_aid" : CJString(outerId),
        @"app_id": CJString(response.merchantInfo.appId),
        @"loading_time": [NSString stringWithFormat:@"%f", totalResponseTime]
    };
    NSMutableDictionary *eventParams = [NSMutableDictionary dictionaryWithDictionary:[self p_mergeCommonParamsWith:resultTrackDic response:response]];
    [eventParams cj_setObject:traceID forKey:@"trace_id"];
    [CJTracker event:@"wallet_cashier_douyincashier_result"
              params:eventParams];
}

- (void)p_configCashRegisterVCWithResponse:(CJPayCreateOrderResponse *)response bizParams:(NSDictionary *)bizParams {
    double currentTimestamp = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000;
    double duration = currentTimestamp - self.lastTimestamp;
    NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
    [trackData addEntriesFromDictionary:@{@"from": @"outerpay_finish_request",
                                          @"duration" : @(duration),
                                          @"channel" : CJString([UIApplication btd_currentChannel])}];
    [CJTracker event:@"wallet_cashier_outerpay_track_event"
              params:trackData];
    self.lastTimestamp = currentTimestamp;
    
    NSString *appID = [self.schemaParams cj_stringValueForKey:@"app_id"];
    if (!Check_ValidString(appID)) {
        appID = @"browser";
    }
    
    NSString *appName = [self.schemaParams cj_stringValueForKey:@"app_name"];
    if (Check_ValidString(appName)) {
        appName = [appName stringByRemovingPercentEncoding];
    }
    
    CJPayDYPayBizDeskModel *deskModel = [CJPayDYPayBizDeskModel new];
    deskModel.isColdLaunch = self.isColdLaunch;
    deskModel.isPaymentOuterApp = YES;
    deskModel.isUseMask = YES;
    deskModel.appName = appName;
    deskModel.appId = appID;
    deskModel.response = response;
    deskModel.lastTimestamp = self.lastTimestamp;
    deskModel.bizParams = bizParams;
    
    [CJ_OBJECT_WITH_PROTOCOL(CJPayCashierModule) i_openDYPayBizDeskWithDeskModel:deskModel delegate:self];
}

#pragma mark - CJPayAPIDelegate
- (void)onResponse:(CJPayAPIBaseResponse *)response {
    if ([self.apiDelegate respondsToSelector:@selector(onResponse:)]) {
        [self.apiDelegate onResponse:response];
    }
    
    NSInteger resultCode = response.error.code;
    CJPayDypayResultType type = [CJPayOuterPayUtil dypayResultTypeWithErrorCode:resultCode];
    if (type >= 0) {
        CJPayLogInfo(@"支付结果%ld", type);
    }
    [self closeCashierDeskAndJumpBackWithResult:type];
}

- (NSDictionary *)p_mergeCommonParamsWith:(NSDictionary *)dic
                                 response:(CJPayCreateOrderResponse *)response {
    NSMutableDictionary *totalDic = [NSMutableDictionary dictionaryWithDictionary:dic];
    NSDictionary *commonParams = [CJPayCommonTrackUtil getCashDeskCommonParamsWithResponse:response
                                                                         defaultPayChannel:response.payInfo.defaultPayChannel];
    [totalDic addEntriesFromDictionary:commonParams];
    [totalDic addEntriesFromDictionary:@{@"douyin_version": CJString([CJPayRequestParam appVersion])}];
    return totalDic;
}

@end
