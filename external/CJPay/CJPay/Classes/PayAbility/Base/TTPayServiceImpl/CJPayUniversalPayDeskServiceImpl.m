//
//  CJPayUniversalPayDeskServiceImpl.m
//  Pods
//
//  Created by 王新华 on 2020/11/21.
//

#import "CJPayUniversalPayDeskServiceImpl.h"
#import "CJPayPrivateServiceHeader.h"
#import "NSObject+CJPay.h"
#import "CJPayLoadingManager.h"
#import "CJPayAlertUtil.h"
#import <JSONModel/JSONModel.h>
#import "CJPaySettingsManager.h"
#import "CJPayUIMacro.h"
#import "CJPayUniversalPayDeskService.h"
#import "UIViewController+CJPay.h"
#import "CJPayChannelManagerModule.h"
#import "CJPayCashierModule.h"
#import "CJPayDeskServiceHeader.h"
#import "CJPayBioPaymentPlugin.h"
#import "CJPayBaseRequest.h"
#import "CJPayECCreateOrderModel.h"
#import "CJPayKVContext.h"
#import "CJPayDeskRouteDelegate.h"
#import "CJPayABTestManager.h"
#import "NSMutableDictionary+CJPay.h"

@class CJPayAPIRequestMsgWrapper;
@protocol CJPayAPIWrapperProtocl <NSObject>

- (void)onResponse:(CJPayAPIBaseResponse *)response from:(CJPayAPIRequestMsgWrapper *) msgWrapper;
- (void)callState:(BOOL)success fromScene:(CJPayScene)scene from:(CJPayAPIRequestMsgWrapper *) msgWrapper;

@end

@interface CJPayAPIRequestMsgWrapper : NSObject<CJPayAPIDelegate>

@property (nonatomic, copy, nonnull) NSString *identify;
@property (nonatomic, copy) NSDictionary *reqParams;
@property (nonatomic, strong) id<CJPayAPIDelegate> originalDelegate;
@property (nonatomic, weak) id<CJPayAPIWrapperProtocl> wrapperProtocol;

@end

@implementation CJPayAPIRequestMsgWrapper

+ (CJPayAPIRequestMsgWrapper *)wrapperWithID:(NSString *)identify apiDelegate:(id<CJPayAPIDelegate>)delegate {
    CJPayAPIRequestMsgWrapper *wrapper = [CJPayAPIRequestMsgWrapper new];
    wrapper.identify = identify;
    wrapper.originalDelegate = delegate;
    return wrapper;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:CJPayAPIRequestMsgWrapper.class]) {
        return NO;
    }
    CJPayAPIRequestMsgWrapper *other = (CJPayAPIRequestMsgWrapper *)object;
    return [other.identify isEqualToString:self.identify];
}

- (NSUInteger)hash {
    return [self.identify hash];
}

- (void)onResponse:(CJPayAPIBaseResponse *)response {
    if (self.wrapperProtocol) {
        [self.wrapperProtocol onResponse:response from:self];
    }
}

- (void)callState:(BOOL)success fromScene:(CJPayScene)scene {
    if (self.wrapperProtocol) {
        [self.wrapperProtocol callState:success fromScene:scene from:self];
    }
}

@end


//详细说明，参考文档 https://bytedance.feishu.cn/docs/doccnXLrYkw7BBnxiIuXpQ5bFE3#
@interface CJPayUniversalPayDeskModel :JSONModel

@property (nonatomic, copy) NSDictionary *sdkInfo; // 具体吊起相关能力的参数
@property (nonatomic, assign) NSUInteger service; // 吊起能力路由分发参数
@property (nonatomic, assign) NSUInteger subWay;  // "默认不传，财经SDK默认走App支付 0 app | 1 h5 | 3 公众号 | 4 小程序"
@property (nonatomic, copy) NSString *refer;  // 微信H5支付refer
@property (nonatomic, copy) NSString *ext;
@property (nonatomic, strong) UIViewController *referVC;
@property (nonatomic, strong) id<CJPayDeskRouteDelegate> routeDelegate;

@end

@implementation CJPayUniversalPayDeskModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"sdkInfo": @"sdk_info",
        @"ext": @"ext",
        @"service": @"service",
        @"subWay": @"sub_way",
        @"refer" : @"referer",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@interface CJPayUniversalPayDeskServiceImpl()<CJPayUniversalPayDeskService, CJPayAPIWrapperProtocl>

@property (nonatomic, strong) NSMutableDictionary<NSString *,CJPayAPIRequestMsgWrapper *> *multiApiDelegates;

@end

@implementation CJPayUniversalPayDeskServiceImpl

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassToPtocol(self, CJPayUniversalPayDeskService)
})

- (NSMutableDictionary<NSString *,CJPayAPIRequestMsgWrapper *> *)multiApiDelegates {
    if (!_multiApiDelegates) {
        _multiApiDelegates = [NSMutableDictionary new];
    }
    return _multiApiDelegates;
}

- (void)i_openUniversalPayDeskWithParams:(NSDictionary *)params withDelegate:(nullable id<CJPayAPIDelegate>)delegate {
    [self i_openUniversalPayDeskWithParams:params referVC:params.cjpay_referViewController routeDelegate:nil withDelegate:delegate];
}

- (void)i_openUniversalPayDeskWithParams:(NSDictionary *)params referVC:(UIViewController *)referVC withDelegate:(id<CJPayAPIDelegate>)delegate {
    [self i_openUniversalPayDeskWithParams:params referVC:referVC routeDelegate:nil withDelegate:delegate];
}


- (void)i_openUniversalPayDeskWithParams:(NSDictionary *)params routeDelegate:(id<CJPayDeskRouteDelegate>)routeDelegate withDelegate:(nullable id<CJPayAPIDelegate>)delegate {
    [self i_openUniversalPayDeskWithParams:params referVC:params.cjpay_referViewController routeDelegate:routeDelegate withDelegate:delegate];
}

- (void)i_openUniversalPayDeskWithParams:(NSDictionary *)params referVC:(UIViewController *)referVC routeDelegate:(id<CJPayDeskRouteDelegate>)routeDelegate withDelegate:(id<CJPayAPIDelegate>)delegate {
    //由前端控制关闭银行卡h5页的时机，不需要走后面的了
    if (Check_ValidString([params cj_stringValueForKey:@"back_hook_action"])) {
        [self p_handleBackHookActionCallbackId:params delegate:delegate];
        return;
    }
    
    NSString *timeStampStr = [NSString stringWithFormat:@"%ld", (long)([[NSDate date] timeIntervalSince1970] * 1000)];
    NSString *callBackId = [NSString stringWithFormat:@"cj_callback_id_%@", timeStampStr];
    CJPayAPIRequestMsgWrapper *wrapperDelegate = [CJPayAPIRequestMsgWrapper wrapperWithID:callBackId apiDelegate:delegate];
    wrapperDelegate.wrapperProtocol = self;
    wrapperDelegate.reqParams = [params copy];
    [self.multiApiDelegates cj_setObject:wrapperDelegate forKey:callBackId];
    CJPayUniversalPayDeskModel *model = [[CJPayUniversalPayDeskModel alloc] initWithDictionary:params error:nil];
    model.routeDelegate = routeDelegate;
    model.referVC = referVC ? referVC : params.cjpay_referViewController;
    NSMutableDictionary *mutableDic = [model.sdkInfo mutableCopy];

    [mutableDic addEntriesFromDictionary:[CJPayCommonUtil jsonStringToDictionary:model.ext]];
    
    mutableDic.cjpay_referViewController = model.referVC;
    id bindCardInfoV = [mutableDic valueForKey:@"bind_card_info"];
    if (bindCardInfoV && [bindCardInfoV isKindOfClass:NSString.class]) { // 兼容编码的情况
        [mutableDic cj_setObject:[CJPayCommonUtil jsonStringToDictionary:(NSString *)bindCardInfoV] forKey:@"bind_card_info"];
    }
    NSString *trackInfo = CJString([mutableDic cj_stringValueForKey:@"track_info"]);
    if (Check_ValidString(trackInfo)) {
        [mutableDic cj_setObject:[CJPayCommonUtil jsonStringToDictionary:(NSString *)trackInfo] forKey:@"track_info"];
    }

    [self p_trackTTPayWakeWithExtra:@{} from:wrapperDelegate];
    if (!model) {
        [self p_callState:NO fromScene:CJPayScenePay from:wrapperDelegate];
        [self p_onResponseError:CJPayErrorCodeFail errorDesc:@"传入数据格式不对" from:wrapperDelegate];
        return;
    }
    
    NSString *antiFraudCode = [mutableDic cj_stringValueForKey:@"anti_fraud_code"];
    NSString *alertTipsContent = [mutableDic cj_stringValueForKey:@"anti_fraud_msg"];
    NSDictionary *newCreateOrderResponse = [params cj_dictionaryValueForKey:@"create_order_response"];
    if (Check_ValidDictionary(newCreateOrderResponse)) {
        [mutableDic addEntriesFromDictionary:@{@"create_order_response" : newCreateOrderResponse}];
    }
    
    if([antiFraudCode isEqualToString:@"1"] && Check_ValidString(alertTipsContent)) {
        @CJWeakify(self)
        NSDictionary *trackerParams = [self p_buildTrackerParams:mutableDic];
        void(^leftActionBlock)(void) = ^{
            @CJStrongify(self)
            NSMutableDictionary *antiFraudParams = [[NSMutableDictionary alloc]initWithDictionary:trackerParams];
            [antiFraudParams cj_setObject:@"继续支付" forKey:@"button_name"];
            [CJTracker event:@"wallet_cashier_riskwarn_pop_click" params:antiFraudParams];
            [self p_handlePayService:model sdkInfo:mutableDic withDelegate:wrapperDelegate];
        };
    
        void(^rightActionBlock)(void) = ^{
            @CJStrongify(self)
            NSMutableDictionary *antiFraudParams = [[NSMutableDictionary alloc]initWithDictionary:trackerParams];
            [antiFraudParams cj_setObject:@"取消支付" forKey:@"button_name"];
            [CJTracker event:@"wallet_cashier_riskwarn_pop_click" params:antiFraudParams];
            CJPayAPIBaseResponse *baseResponse = [CJPayAPIBaseResponse new];
            baseResponse.scene = CJPayScenePay;
            baseResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeAntiFraudCanceled userInfo:@{@"errorDesc": @"刷单欺诈风险后取消支付"}];
            baseResponse.data = @{@"code": model.service == 12 ? @(5000): @(116), @"msg": @"刷单欺诈风险后取消支付", @"data":@"", @"create_order_response" :Check_ValidDictionary(newCreateOrderResponse) ? newCreateOrderResponse:@{}};
            [self onResponse:baseResponse from:wrapperDelegate];
            };

        [CJTracker event:@"wallet_cashier_riskwarn_pop_imp" params:trackerParams];
        [CJPayAlertUtil customDoubleAlertWithTitle:CJString(alertTipsContent)
                                           content:nil
                                    leftButtonDesc:CJPayLocalizedStr(@"继续支付")
                                   rightButtonDesc:CJPayLocalizedStr(@"取消支付")
                                   leftActionBlock:leftActionBlock
                                   rightActioBlock:rightActionBlock
                                             useVC:[UIViewController cj_foundTopViewControllerFrom:model.referVC]];
    } else if ([antiFraudCode isEqualToString:@"2"]) {
        // 阻塞性弹窗
        NSDictionary *trackerParams = [self p_buildTrackerParams:mutableDic];
        @CJWeakify(self)
        void(^mainActionBlock)(void) = ^{
            @CJStrongify(self)
            NSMutableDictionary *antiFraudParams = [[NSMutableDictionary alloc]initWithDictionary:trackerParams];
            [antiFraudParams cj_setObject:@"我知道了" forKey:@"button_name"];
            [CJTracker event:@"wallet_cashier_riskwarn_pop_click" params:antiFraudParams];
            CJPayAPIBaseResponse *baseResponse = [CJPayAPIBaseResponse new];
            baseResponse.scene = CJPayScenePay;
            baseResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeAntiFraudCanceled userInfo:@{@"errorDesc": @"风控拦截后取消支付"}];
            baseResponse.data = @{@"code": @(116), @"msg": @"风控拦截后取消支付", @"data":@""};
            [self onResponse:baseResponse from:wrapperDelegate];
        };
        [CJTracker event:@"wallet_cashier_riskwarn_pop_imp" params:trackerParams];
        [CJPayAlertUtil customSingleAlertWithTitle:CJString(alertTipsContent)
                                           content:nil
                                        buttonDesc:CJPayLocalizedStr(@"我知道了")
                                       actionBlock:mainActionBlock
                                             useVC:[UIViewController cj_foundTopViewControllerFrom:model.referVC]];
    } else {
        [self p_handlePayService:model sdkInfo:mutableDic withDelegate:wrapperDelegate];
    }
}

- (void)i_callBackWithCallBackId:(NSString *)callBackId
                        response:(CJPayAPIBaseResponse *)response {
    CJPayAPIRequestMsgWrapper *wrapperDelegate = [self.multiApiDelegates objectForKey:CJString(callBackId)];
    [self.multiApiDelegates removeObjectForKey:CJString(callBackId)];
    if (wrapperDelegate.originalDelegate && response && [wrapperDelegate.originalDelegate respondsToSelector:@selector(onResponse:)]) {
        [self p_handleSuperPayResponse:response];
        [wrapperDelegate.originalDelegate onResponse:response];
    }
}

- (void)p_handleBackHookActionCallbackId:(NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate {
    NSString *callBackId = CJString([params cj_stringValueForKey:@"callback_id"]);
    CJPayAPIRequestMsgWrapper *wrapperDelegate = [CJPayAPIRequestMsgWrapper wrapperWithID:callBackId apiDelegate:delegate];
    wrapperDelegate.wrapperProtocol = self;
    wrapperDelegate.reqParams = [params copy];
    [self.multiApiDelegates cj_setObject:wrapperDelegate forKey:callBackId];
}

- (void)p_handleSuperPayResponse:(CJPayAPIBaseResponse *)response {
    NSDictionary *returnMsg = [[response.data cj_dictionaryValueForKey:@"data"] cj_dictionaryValueForKey:@"msg"]; //前端返回的数据结构里，在详细数据外还包了一层msg
    id<CJPaySuperPayService> superPayManager = CJ_OBJECT_WITH_PROTOCOL(CJPaySuperPayService);
    //process用来判断是否是极速付
    if ([[returnMsg cj_stringValueForKey:@"process"] isEqualToString:@"super_pay_sign_and_pay"] &&[superPayManager respondsToSelector:@selector(getQueryResultData)]) {
         NSDictionary *resDict = [superPayManager performSelector:@selector(getQueryResultData)];
        //resDict为空表示没有进入支付就结束了流程，这里直接返回失败
        if (Check_ValidDictionary(resDict)) {
            response.data = [resDict copy];
        } else {
            response.error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeFail userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(CJString([returnMsg cj_stringValueForKey:@"msg"]), nil)}];
        }
    }
}

- (NSDictionary *)i_processCallbackDataWithResponse:(CJPayAPIBaseResponse *)response {
    return [self p_callBackDataWithResponse:response];
}

- (void)p_handlePayService:(CJPayUniversalPayDeskModel *)model sdkInfo:(NSMutableDictionary *)mutableDic withDelegate:(CJPayAPIRequestMsgWrapper *)wrapperDelegate{
    switch (model.service) {
        case 1:
            if (!CJ_OBJECT_WITH_PROTOCOL(CJPayChannelManagerModule)) {
                [self p_onResponseError:CJPayErrorCodeFail errorDesc:[NSString stringWithFormat:@"%@SDK能力未包含", CN_WX] from:wrapperDelegate];
                break;
            }
            [mutableDic cj_setObject:[NSNumber numberWithUnsignedInt:CJPayChannelTypeWX] forKey:@"pay_channel"];
            if (model.subWay && model.subWay == 1) {
                [mutableDic cj_setObject:[NSNumber numberWithUnsignedInt:CJPayChannelTypeWXH5] forKey:@"pay_channel"];
                [mutableDic cj_setObject:model.refer forKey:@"refer"];
            }
            [CJ_OBJECT_WITH_PROTOCOL(CJPayChannelManagerModule) wakeByUniversalPayDesk:mutableDic withDelegate:wrapperDelegate];
            break;
        case 2:
            if (!CJ_OBJECT_WITH_PROTOCOL(CJPayChannelManagerModule)) {
                [self p_onResponseError:CJPayErrorCodeFail errorDesc:[NSString stringWithFormat:@"%@SDK能力未包含", CN_zfb] from:wrapperDelegate];
                break;
            }
            [mutableDic cj_setObject:[NSNumber numberWithUnsignedInt:CJPayChannelTypeTbPay] forKey:@"pay_channel"];
            [CJ_OBJECT_WITH_PROTOCOL(CJPayChannelManagerModule) wakeByUniversalPayDesk:mutableDic withDelegate:wrapperDelegate];
            break;
        case 10:
        {
            if (!CJ_OBJECT_WITH_PROTOCOL(CJPayEcommerceDeskService)) {
                [self p_onResponseError:CJPayErrorCodeFail errorDesc:@"电商收银台能力未包含" from:wrapperDelegate];
                break;
            }
            NSDictionary *extDict = [model.ext cj_toDic];
            //安全感新样式Loading
            NSDictionary *loadingStyleInfo = [[extDict cj_dictionaryValueForKey:@"sdk_show_info"] cj_dictionaryValueForKey:@"loading_style_info"];
            [CJPayLoadingManager defaultService].loadingStyleInfo = [[CJPayLoadingStyleInfo alloc] initWithDictionary:loadingStyleInfo error:nil];
            
            [CJ_OBJECT_WITH_PROTOCOL(CJPayEcommerceDeskService) wakeByUniversalPayDesk:mutableDic withDelegate:wrapperDelegate];
            break;
        }
        case 11:
            if (!CJ_OBJECT_WITH_PROTOCOL(CJPaySignDYPayModule)) {
                [self p_onResponseError:CJPayErrorCodeFail errorDesc:@"抖音签约并支付能力未包含" from:wrapperDelegate];
                break;
            }
            [mutableDic cj_setObject:@"inner" forKey:@"sign_type"];
            [CJ_OBJECT_WITH_PROTOCOL(CJPaySignDYPayModule) wakeByUniversalPayDesk:mutableDic withDelegate:wrapperDelegate];
            break;
        case 12:
            [self p_createOrder:model withDelegate:wrapperDelegate];
            break;
        case 20:
            if (!CJ_OBJECT_WITH_PROTOCOL(CJPayCashierModule)) {
                [self p_onResponseError:CJPayErrorCodeFail errorDesc:@"聚合收银台能力未包含" from:wrapperDelegate];
                break;
            }
            [CJ_OBJECT_WITH_PROTOCOL(CJPayCashierModule) wakeByUniversalPayDesk:mutableDic withDelegate:wrapperDelegate];
            break;
        case 23:
            if (!CJ_OBJECT_WITH_PROTOCOL(CJPayCashierModule)) {
                [self p_onResponseError:CJPayErrorCodeFail errorDesc:@"极速收银台能力未包含" from:wrapperDelegate];
                break;
            }
            [CJ_OBJECT_WITH_PROTOCOL(CJPayFastPayService) i_openFastPayDeskWithConfig:mutableDic
                                                                            params:mutableDic
                                                                          delegate:wrapperDelegate];
            break;
        case 30:
            if (!CJ_OBJECT_WITH_PROTOCOL(CJPayBDCashierModule)) {
                [self p_onResponseError:CJPayErrorCodeFail errorDesc:@"追光收银台能力未包含" from:wrapperDelegate];
                break;
            }
            [CJ_OBJECT_WITH_PROTOCOL(CJPayBDCashierModule) wakeByUniversalPayDesk:wrapperDelegate.reqParams withDelegate:wrapperDelegate];
            break;
        case 41:
            if (!CJ_OBJECT_WITH_PROTOCOL(CJPayCardManageModule)) {
                [self p_onResponseError:CJPayErrorCodeFail errorDesc:@"独立绑卡能力未包含" from:wrapperDelegate];
                break;
            }
            [CJ_OBJECT_WITH_PROTOCOL(CJPayCardManageModule) wakeByUniversalPayDesk:mutableDic withDelegate:wrapperDelegate];
            break;
        case 51: // 微信独立签约
            if (!CJ_OBJECT_WITH_PROTOCOL(CJPayChannelManagerModule)) {
                [self p_onResponseError:CJPayErrorCodeFail errorDesc:[NSString stringWithFormat:@"%@SDK能力未包含", CN_WX] from:wrapperDelegate];
                break;
            }
            if (model.subWay && model.subWay == 1) {
                [mutableDic cj_setObject:[NSNumber numberWithUnsignedInt:CJPayChannelTypeWXH5] forKey:@"pay_channel"];
                [mutableDic setObject:model.refer forKey:@"refer"];
            }
            [CJ_OBJECT_WITH_PROTOCOL(CJPayChannelManagerModule) wakeByUniversalPayDesk:[self p_tryToRemoveTmpTrackInfoFromParams:mutableDic] withDelegate:wrapperDelegate];
            break;
        case 52:
            if (!CJ_OBJECT_WITH_PROTOCOL(CJPaySignAliPayModule)) {
                [self p_onResponseError:CJPayErrorCodeFail errorDesc:[NSString stringWithFormat:@"%@SDK能力未包含", CN_zfb] from:wrapperDelegate];
                break;
            }
            [CJ_OBJECT_WITH_PROTOCOL(CJPaySignAliPayModule) wakeByUniversalPayDesk:mutableDic withDelegate:wrapperDelegate];
            break;
        case 53:
            if (!CJ_OBJECT_WITH_PROTOCOL(CJPaySignDYPayModule)) {
                [self p_onResponseError:CJPayErrorCodeFail errorDesc:@"抖音独立签约能力未包含" from:wrapperDelegate];
                break;
            }
            [mutableDic cj_setObject:@"sign_only" forKey:@"pay_source"];
            [CJ_OBJECT_WITH_PROTOCOL(CJPaySignDYPayModule) wakeByUniversalPayDesk:mutableDic withDelegate:wrapperDelegate];
            break;
        case 61:
            if ([mutableDic cj_intValueForKey:@"loading_status"] == 1) {
                NSString *loadingText = [mutableDic cj_stringValueForKey:@"loading_text"];
                NSDictionary *extDict = [model.ext cj_toDic];
                NSDictionary *loadingStyleInfo = [[extDict cj_dictionaryValueForKey:@"sdk_show_info"] cj_dictionaryValueForKey:@"loading_style_info"];
                loadingText = Check_ValidString(loadingText) ? loadingText : CJPayDYPayTitleMessage;
                if (!loadingStyleInfo) {
                    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading title:loadingText];
                } else {
                    [CJPayLoadingManager defaultService].loadingStyleInfo = [[CJPayLoadingStyleInfo alloc] initWithDictionary:loadingStyleInfo error:nil];
                    
                    if ([loadingStyleInfo cj_objectForKey:@"nopwd_combine_pre_show_info"]) {
                        //前置展示免密接口合并loading
                        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleLoading isNeedValidateTimer:YES];
                    } else {
                        //安全感新样式Loading
                        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleLoading title:loadingText];
                    }
                }
            } else {
                [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeDouyinLoading];
                [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeDouyinStyleLoading];
            }
            [self.multiApiDelegates removeObjectForKey:wrapperDelegate.identify]; // 不需要回调的主动移除
            break;
            
        case 62:
        {
            if (!CJ_OBJECT_WITH_PROTOCOL(CJPaySuperPayService)) {
                [self p_onResponseError:CJPayErrorCodeFail errorDesc:@"极速付能力未包含" from:wrapperDelegate];
                break;
            }
            NSDictionary *extDict = [[model.sdkInfo cj_stringValueForKey:@"extra"] cj_toDic];
            if ([extDict cj_boolValueForKey:@"is_super_pay_open"]) {
                [self p_handleOpenLynxWithModel:model delegate:wrapperDelegate];
            } else {
                [CJ_OBJECT_WITH_PROTOCOL(CJPaySuperPayService) wakeByUniversalPayDesk:mutableDic withDelegate:wrapperDelegate];
            }
            break;
        }
        case 63:
        {
            if (!CJ_OBJECT_WITH_PROTOCOL(CJPayGeneralAbilityService)) {
                [self p_onResponseError:CJPayErrorCodeFail errorDesc:@"使用通用能力未包含" from:wrapperDelegate];
                break;
            }
            [CJ_OBJECT_WITH_PROTOCOL(CJPayGeneralAbilityService) i_wekeByGeneralAbility:mutableDic delegate:wrapperDelegate.originalDelegate];
            break;
        }
        case 71:
            if (!CJ_OBJECT_WITH_PROTOCOL(CJPayChannelManagerModule)) {
                [self p_onResponseError:CJPayErrorCodeFail errorDesc:@"外部 App 拉起抖音支付SDK能力未包含" from:wrapperDelegate];
                break;
            }
            [mutableDic cj_setObject:[NSNumber numberWithUnsignedInt:CJPayChannelTypeDyPay] forKey:@"pay_channel"];
            [CJ_OBJECT_WITH_PROTOCOL(CJPayChannelManagerModule) wakeByUniversalPayDesk:mutableDic withDelegate:wrapperDelegate];
            break;
        case 97:
            if (!CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin)) {
                [self p_onResponseError:CJPayErrorCodeFail
                              errorDesc:@"生物识别模块未包含"
                                   from:wrapperDelegate];
            }
            [mutableDic cj_setObject:@(model.subWay) forKey:@"sub_way"];
            [self p_handleBioService:mutableDic from:wrapperDelegate];
            break;
        case 98:
        {
            if ([[mutableDic cj_stringValueForKey:@"schema"] hasPrefix:@"sslocal://microapp"]) {
                [CJPayKVContext kv_setValue:@{@"callBackId":CJString(wrapperDelegate.identify)}
                                     forKey:CJPayMicroappBindCardCallBack];
            }
            // 依赖宿主打开lynx
            CJPayLynxSchemaParamsConfig *paramsConfig = [CJPaySettingsManager shared].currentSettings.lynxSchemaParamsConfig;
            if (paramsConfig.enable) {
                [self p_addCJExtParamIfNeededWithModel:model];
            }
            [self p_handleOpenLynxWithModel:model delegate:wrapperDelegate];
            break;
        }
        case 99:
            // 打开财经SDK Router
            [self p_handleByRouterWithModel:model delegate:wrapperDelegate];
            break;
        case 200:
            // 前端存或取native内存中的数据
            if (!CJ_OBJECT_WITH_PROTOCOL(CJPayParamsCacheService)) {
                [self p_onResponseError:CJPayErrorCodeFail errorDesc:@"未包含获取缓存参数能力" from:wrapperDelegate];
                break;
            }
            [self p_handleGetParamsServiceWith:mutableDic delegate:wrapperDelegate];
            break;
        default:
            [self p_onResponseError:CJPayErrorCodeFail errorDesc:[NSString stringWithFormat:@"当前传入的service = %lu 不能被处理", (unsigned long)model.service] from:wrapperDelegate];
            break;
    }
}

- (NSDictionary *)p_abInfoWithRules:(NSArray<CJPayLynxSchemaParamsRule *> *)rules path:(NSString *)path {
    NSMutableDictionary *abInfo = [NSMutableDictionary dictionary];
    for (CJPayLynxSchemaParamsRule *rule in rules) {
        if (rule.url.length > 0 && rule.keys.count > 0 && [path hasSuffix:rule.url]) {
            for (NSString *key in rule.keys) {
                [abInfo cj_setObject:CJString([CJPayABTest getABTestValWithKey:key exposure:NO]) forKey:key];
            }
            break;
        }
    }
    return [abInfo copy];
}

- (NSString *)p_addCJExtParamToSchema:(NSString *)schema {
    NSMutableDictionary *cjDevExt = [NSMutableDictionary dictionary];
    [cjDevExt cj_setObject:CJString([CJSDKParamConfig defaultConfig].version) forKey:@"cj_sdk_version"];
    [cjDevExt cj_setObject:[CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) getPreTradeCreateBioParamDic] forKey:@"bio_info"];
    
    CJPayLynxSchemaParamsConfig *paramsConfig = [CJPaySettingsManager shared].currentSettings.lynxSchemaParamsConfig;
    if (paramsConfig.rules.count > 0) {
        NSDictionary *query = [CJPayCommonUtil parseScheme:schema];
        NSString *urlStr = [query cj_stringValueForKey:@"url"];
        if (urlStr.length > 0) {
            NSURL *url = [NSURL URLWithString:urlStr];
            NSString *path = url.path;
            if (path.length > 0) {
                NSDictionary *abInfo = [self p_abInfoWithRules:paramsConfig.rules path:path];
                [cjDevExt cj_setObject:abInfo forKey:@"ab_test"];
            }
        }
    }
    
    NSString *jsonString = [cjDevExt btd_jsonStringEncoded];
    NSString *finalSchema = [CJPayCommonUtil appendParamsToUrl:schema params:@{@"cj_ext_params": CJString(jsonString)}];

    NSUInteger kbLength = [finalSchema maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding] / 1024;
    if (kbLength < paramsConfig.paramsLimit) {
        return finalSchema;
    }
    return schema;
}

- (void)p_addCJExtParamIfNeededWithModel:(CJPayUniversalPayDeskModel *)model {
    NSString *schema = [model.sdkInfo cj_stringValueForKey:@"schema"];
    if (schema.length > 0) {
        NSString *finalSchema = [self p_addCJExtParamToSchema:schema];
        if (![finalSchema isEqualToString:schema]) {
            NSMutableDictionary *finalSDKInfo = [model.sdkInfo mutableCopy];
            [finalSDKInfo cj_setObject:finalSchema forKey:@"schema"];
            model.sdkInfo = [finalSDKInfo copy];
        }
    }
}

- (void)p_createOrder:(CJPayUniversalPayDeskModel *)model
         withDelegate:(CJPayAPIRequestMsgWrapper *)wrapperDelegate {
    NSDictionary *createOrderParams = [model.sdkInfo cj_dictionaryValueForKey:@"create_order_params"];
    if (createOrderParams.count) {
        // 参数检查
        NSString *url = [createOrderParams cj_stringValueForKey:@"url"];
        NSString *method = [createOrderParams cj_stringValueForKey:@"method"];
        NSDictionary *header = [createOrderParams cj_dictionaryValueForKey:@"header"];
        NSDictionary *body = [createOrderParams cj_dictionaryValueForKey:@"body"];
        
        if (!(url.length && method.length && body.count)) {
            CJPayAPIBaseResponse *baseResponse = [CJPayAPIBaseResponse new];
            baseResponse.scene = CJPayScenePay;
            baseResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeAntiFraudCanceled userInfo:@{@"errorDesc": @"下单参数格式不对"}];
            baseResponse.data = @{@"code": @(1), @"msg": @"下单参数格式不对", @"data":@""};
            [self onResponse:baseResponse from:wrapperDelegate];
            return;
        }
        
        CJPayRequestSerializeType serializeType = CJPayRequestSerializeTypeURLEncode;
        if (header.count) {
            NSString *contentType = [createOrderParams cj_stringValueForKey:@"data_type"];
            if ([contentType isEqualToString:@"JSON"]) {
                serializeType = CJPayRequestSerializeTypeJSON;
            }
        }
        
        NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
        NSTimeInterval requestTimestamp = [date timeIntervalSince1970] * 1000;
        __block NSTimeInterval responseTimestamp;
        __block NSTimeInterval startTTpayTimestamp;
        @weakify(self);
        // 请求下单接口数据
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading];
        [CJPayBaseRequest startRequestWithUrl:url
                                serializeType:serializeType
                                requestParams:body
                                     callback:^(NSError *error, id jsonObj) {
            responseTimestamp = [date timeIntervalSince1970] * 1000;
            @strongify(self);
            if (error) {
                // 下单失败
                CJPayAPIBaseResponse *baseResponse = [CJPayAPIBaseResponse new];
                baseResponse.scene = CJPayScenePay;
                baseResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeAntiFraudCanceled userInfo:@{@"errorDesc": @"下单失败"}];
                baseResponse.data = @{@"code": @(5000), @"msg": @"下单失败", @"data":@"", @"create_order_response" : jsonObj != nil?jsonObj:@{}};
                [self onResponse:baseResponse from:wrapperDelegate];
                [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeTopLoading];
                return;
            }
            NSError *err = nil;
            CJPayECCreateOrderModel *response = [[CJPayECCreateOrderModel alloc] initWithDictionary:jsonObj error:&err];
            NSString *tradeNo = [response.data cj_stringValueForKey:@"order_id"];
            if (!Check_ValidString(tradeNo)) {
                NSArray *orderIds = [response.data cj_arrayValueForKey:@"orderIds"];
                if (orderIds != nil && orderIds.count) {
                    tradeNo = orderIds[0];
                }
            }
            if (response.st != 0 || tradeNo.length == 0) {
                // 下单失败
                CJPayAPIBaseResponse *baseResponse = [CJPayAPIBaseResponse new];
                baseResponse.scene = CJPayScenePay;
                baseResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeAntiFraudCanceled userInfo:@{@"errorDesc": @"下单失败"}];
                baseResponse.data = @{@"code": @(5000), @"msg": @"下单失败", @"data":@"", @"create_order_response" : jsonObj != nil?jsonObj:@{}};
                [self onResponse:baseResponse from:wrapperDelegate];
                [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeTopLoading];
                return;
            }
            
            // 下单成功，拼接参数
            NSMutableDictionary *newParams = [[NSMutableDictionary alloc] initWithDictionary:wrapperDelegate.reqParams];
            int service = [[newParams cj_dictionaryValueForKey:@"sdk_info"] cj_integerValueForKey:@"sdk_service"];
            [newParams cj_setObject:@(service) forKey:@"service"];
            
            NSDictionary *responseSDKInfo = [[response.data cj_dictionaryValueForKey:@"data"] cj_dictionaryValueForKey:@"sdk_info"];
            [newParams cj_setObject:responseSDKInfo forKey:@"sdk_info"];
            
            [newParams cj_setObject:@([response.data cj_integerValueForKey:@"sub_way"]) forKey:@"sub_way"];
            
            NSMutableDictionary *extDic = [NSMutableDictionary new];
            [extDic addEntriesFromDictionary:[CJPayCommonUtil jsonStringToDictionary:model.ext]];
            NSMutableDictionary *extTrackInfoDic = [[extDic cj_dictionaryValueForKey:@"track_info"] mutableCopy];
            if (Check_ValidString(tradeNo)) {
                [extTrackInfoDic cj_setObject:tradeNo forKey:@"trade_no"];
            }
            if (Check_ValidDictionary(extTrackInfoDic)) {
                [extDic cj_setObject:extTrackInfoDic forKey:@"track_info"];
            }
            [newParams cj_setObject:[extDic cj_toStr] forKey:@"ext"];
            
            startTTpayTimestamp = [date timeIntervalSince1970] * 1000;
            
            NSMutableDictionary *timestampInfoDic = [[extDic cj_dictionaryValueForKey:@"timestamp_info"] mutableCopy];
            [timestampInfoDic cj_setObject:@(requestTimestamp) forKey:@"create_order_request"];
            [timestampInfoDic cj_setObject:@(responseTimestamp) forKey:@"create_order_response"];
            [timestampInfoDic cj_setObject:@(startTTpayTimestamp) forKey:@"launch_ttpay"];
            [newParams cj_setObject:timestampInfoDic forKey:@"timestamp_info"];
            
            [newParams addEntriesFromDictionary:@{@"create_order_response" : jsonObj}];
            
            BOOL isSkipPay = [response.data cj_boolValueForKey:@"skip_pay"];
            if (isSkipPay) {
                // 支付宝免密
                CJPayAPIBaseResponse *baseResponse = [CJPayAPIBaseResponse new];
                baseResponse.scene = CJPayScenePay;
                baseResponse.data = @{@"code": @(5001), @"msg": @"下单成功", @"data":@"", @"create_order_response" : jsonObj};
                [self onResponse:baseResponse from:wrapperDelegate];
                [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeTopLoading];
                return;
            }
            
            // 调用相应的 service
            [self i_openUniversalPayDeskWithParams:newParams referVC:model.referVC withDelegate:wrapperDelegate.originalDelegate];
        }];
    }
}

- (void)p_handleBioService:(NSDictionary *)params from:(nullable CJPayAPIRequestMsgWrapper *)wrapperDelegate {
    id<CJPayBioPaymentPlugin> bioPlugin = CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin);
    if ([params cj_intValueForKey:@"sub_way"] == 1) {
        [bioPlugin callBioVerifyWithParams:params completionBlock:^(NSDictionary * _Nonnull resultDic) {
            CJPayAPIBaseResponse *response = [CJPayAPIBaseResponse new];
            response.data = resultDic;
            [self p_justOnResponse:response from:wrapperDelegate];
        }];
    } else {
        NSDictionary *bioParamDic = [bioPlugin getPreTradeCreateBioParamDic];
        CJPayAPIBaseResponse *response = [CJPayAPIBaseResponse new];
        response.data = @{@"code": @(0),
                          @"msg" : CJString([bioParamDic cj_toStr]),
                          @"data": CJString([bioParamDic cj_toStr])};
        [self p_justOnResponse:response from:wrapperDelegate];
    }
}

- (void)p_handleOpenLynxWithModel:(CJPayUniversalPayDeskModel *)model
                         delegate:(nullable CJPayAPIRequestMsgWrapper *)delegate {
    if (!CJ_OBJECT_WITH_PROTOCOL(CJPayWebViewService)) {
        [self p_onResponseError:CJPayErrorCodeFail errorDesc:@"webview能力未包含" from:delegate];
    }
    if (delegate) {
        NSString *schema = [model.sdkInfo cj_stringValueForKey:@"schema"];
        if (!Check_ValidString(schema)) {
            schema = [model.sdkInfo cj_stringValueForKey:@"url"];
        }
        
        NSDictionary *schemaQuery = [CJPayCommonUtil parseScheme:schema];

        NSMutableDictionary *extraParams = [NSMutableDictionary new];
        [extraParams cj_setObject:CJString(delegate.identify) forKey:@"callback_id"];
        NSDictionary *extDict = [model.ext cj_toDic];
        if ([[extDict cj_stringValueForKey:@"cj_ttpay_flag"] isEqualToString:@"new"]) { // 标识service=98的回调结构走新链路：新链路下iOS和安卓端回调结构统一
            [extraParams cj_setObject:@"new" forKey:@"cj_ttpay_flag"];
        }
        NSString *finalSchema = [CJPayCommonUtil appendParamsToUrl:schema params:[extraParams copy]];

        if (Check_ValidString([model.sdkInfo cj_stringValueForKey:@"type"])) {
            [CJ_OBJECT_WITH_PROTOCOL(CJPayWebViewService) i_openSchemeByNtvVC:finalSchema fromVC:model.referVC withInfo:model.sdkInfo withDelegate:delegate.originalDelegate];
        } else if ([schemaQuery cj_objectForKey:kCJPayContentHeightKey] && [model.routeDelegate respondsToSelector:@selector(routeToVC:animated:)]) { // 新架构调用过来的才有 routeDelegate
            [CJ_OBJECT_WITH_PROTOCOL(CJPayHybridService) openSchema:finalSchema withInfo:model.sdkInfo routeDelegate:model.routeDelegate];
        } else {
            [CJ_OBJECT_WITH_PROTOCOL(CJPayWebViewService) i_openCjSchemaByHost:finalSchema fromVC:model.referVC useModal:YES];
        }
    }
}

- (void)p_handleByRouterWithModel:(CJPayUniversalPayDeskModel *)model
                        delegate:(nullable CJPayAPIRequestMsgWrapper *)delegate {
    if (!CJ_OBJECT_WITH_PROTOCOL(CJPayWebViewService)) {
        [self p_onResponseError:CJPayErrorCodeFail errorDesc:@"webview能力未包含" from:delegate];
    }
    NSString *schema = [model.sdkInfo cj_stringValueForKey:@"schema"];
    NSString *customUa = CJConcatStr(@"CallbackId/", CJString(delegate.identify));
    NSString *finalSchema = [CJPayCommonUtil appendParamsToUrl:schema
                                                     params:@{@"cj_custom_ua": customUa}];
    if (!finalSchema.cjpay_referViewController) {
        finalSchema.cjpay_referViewController = model.referVC;
    }
    [CJ_OBJECT_WITH_PROTOCOL(CJPayRouterService) i_openScheme:CJString(finalSchema) callBack:^(CJPayAPIBaseResponse * response) {
        NSDictionary *dic = (NSDictionary *)response.data;
        if (dic && [dic isKindOfClass:NSDictionary.class]) {
            NSString *service = [dic cj_stringValueForKey:@"service"];
            NSString *callBackId = [dic cj_stringValueForKey:@"callback_id"];
            if ([service isEqualToString:@"99"] || [service isEqualToString:@"unbind"]) {//h5解绑卡service=unbind
                [CJ_OBJECT_WITH_PROTOCOL(CJPayUniversalPayDeskService) i_callBackWithCallBackId:callBackId response:response];
            } else {
                [self.multiApiDelegates removeObjectForKey:delegate.identify];
            }
        }
    }];
}

- (void)p_handleGetParamsServiceWith:(NSDictionary *)mutableDic delegate:(nullable CJPayAPIRequestMsgWrapper *)wrapperDelegate {
    if (!CJ_OBJECT_WITH_PROTOCOL(CJPayParamsCacheService)) {
        if (wrapperDelegate.originalDelegate) {
            CJPayAPIBaseResponse *response = [CJPayAPIBaseResponse new];
            response.scene = CJPaySceneParamsService;
            response.data = @{
                @"code" : @(0),
                @"msg" : @"未引入参数缓存能力",
                @"data" : @""
            };
            [wrapperDelegate.originalDelegate onResponse:response];
            [self.multiApiDelegates removeObjectForKey:wrapperDelegate.identify];
            return;
        }
    }
    NSString *key = [mutableDic cj_stringValueForKey:@"key"];
    NSString *value = [mutableDic cj_stringValueForKey:@"value"];
    NSString *method = [mutableDic cj_stringValueForKey:@"method"];
    NSString *msg = @"";
    if ([method isEqualToString:@"set"]) {
        msg = Check_ValidString(key) ? msg : @"key值为空";
        msg = Check_ValidString(value) ? msg : [msg stringByAppendingString:@" value值为空"];
        BOOL setParamsResult = [CJ_OBJECT_WITH_PROTOCOL(CJPayParamsCacheService) i_setParams:value key:key];
        if (wrapperDelegate.originalDelegate) {
            CJPayAPIBaseResponse *response = [CJPayAPIBaseResponse new];
            response.scene = CJPaySceneParamsService;
            response.data = @{
                @"code" : @(0),
                @"msg" : (setParamsResult ? @"success" : msg),
                @"data" : @""
            };
            [wrapperDelegate.originalDelegate onResponse:response];
            [self.multiApiDelegates removeObjectForKey:wrapperDelegate.identify];
        }
    } else {
        NSString *cacheValue = CJString([CJ_OBJECT_WITH_PROTOCOL(CJPayParamsCacheService) i_getParamsFromCache:key]);
        
        if (!Check_ValidString(cacheValue)) {
            msg = @"获取缓存参数失败，无对应参数";
        }
        //失败情况下，code也传0
        if (wrapperDelegate.originalDelegate) {
            CJPayAPIBaseResponse *response = [CJPayAPIBaseResponse new];
            response.scene = CJPaySceneParamsService;
            response.data = @{
                @"code" : @(0),
                @"msg" : msg,
                @"data" : cacheValue
            };
            [wrapperDelegate.originalDelegate onResponse:response];
            [self.multiApiDelegates removeObjectForKey:wrapperDelegate.identify];
        }
    }
}

- (void)p_callState:(BOOL)isSuccess fromScene:(CJPayScene)scene from:(CJPayAPIRequestMsgWrapper *)msgWrapper {
    [self callState:isSuccess fromScene:scene from:msgWrapper];
}

- (void)p_onResponseError:(CJPayErrorCode)errorCode errorDesc:(NSString *)errorDesc from:(CJPayAPIRequestMsgWrapper *)delegate {
    CJPayAPIBaseResponse *baseResponse = [CJPayAPIBaseResponse new];
    baseResponse.scene = CJPayScenePay;
    baseResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:errorCode userInfo:@{@"errorDesc": CJString(errorDesc)}];
    baseResponse.data = @{@"code": @(112), @"msg": @"参数异常", @"data":@""};
    [self onResponse:baseResponse from:delegate];
}

#pragma - mark 埋点

- (void)p_trackTTPayWakeWithExtra:(NSDictionary *)params from:(CJPayAPIRequestMsgWrapper *)msgWrapper {
    NSMutableDictionary *mutableTrackParams = [NSMutableDictionary new];
    NSDictionary *ext = [CJPayCommonUtil jsonStringToDictionary:[msgWrapper.reqParams cj_stringValueForKey:@"ext"]];
    if ([ext cj_dictionaryValueForKey:@"track_info"] && [[ext cj_dictionaryValueForKey:@"track_info"] isKindOfClass:NSDictionary.class]) {
        [mutableTrackParams addEntriesFromDictionary:[ext cj_dictionaryValueForKey:@"track_info"]];
    }
    [mutableTrackParams cj_setObject:msgWrapper.reqParams forKey:@"pay_params"];
    [mutableTrackParams cj_setObject:[msgWrapper.reqParams cj_stringValueForKey:@"service"] forKey:@"service"];
    [mutableTrackParams addEntriesFromDictionary:params];
    [CJTracker event:@"wallet_cashier_by_sdk" params:[mutableTrackParams copy]];
}

- (void)p_trackTTPayCallbackWithResponse:(CJPayAPIBaseResponse *)response from:(CJPayAPIRequestMsgWrapper *)msgWrapper {
    // ttpay 回调的时候记个埋点
    NSMutableDictionary *mutableTrackParams = [NSMutableDictionary new];
    NSDictionary *ext = [CJPayCommonUtil jsonStringToDictionary:[msgWrapper.reqParams cj_stringValueForKey:@"ext"]];
    if ([ext cj_dictionaryValueForKey:@"track_info"] && [[ext cj_dictionaryValueForKey:@"track_info"] isKindOfClass:NSDictionary.class]) {
        [mutableTrackParams addEntriesFromDictionary:[ext cj_dictionaryValueForKey:@"track_info"]];
    }
    [mutableTrackParams cj_setObject:msgWrapper.reqParams forKey:@"pay_params"];
    [mutableTrackParams cj_setObject:[msgWrapper.reqParams cj_stringValueForKey:@"service"] forKey:@"service"];
    [mutableTrackParams addEntriesFromDictionary:@{@"error_code": CJString([response.data cj_stringValueForKey:@"code"]), @"error_message": CJString([response.data cj_stringValueForKey:@"msg"]), @"sdK_code": @(response.error.code), @"sdk_msg": CJString(response.error.description), @"result": response.error.code == CJPayErrorCodeSuccess ? @"1" : @"0"}];
    [CJTracker event:@"wallet_cashier_callback_sdk" params:[mutableTrackParams copy]];
}

- (NSDictionary *)p_tryToRemoveTmpTrackInfoFromParams:(NSDictionary *)params {
    NSMutableDictionary *mutableParams = [params mutableCopy];
    NSMutableDictionary *mutableTrackInfo = [[params cj_dictionaryValueForKey:@"track_info"] mutableCopy];
    if (mutableTrackInfo) {
        [mutableTrackInfo removeObjectForKey:@"app_id"];
        [mutableTrackInfo removeObjectForKey:@"merchant_id"];
        [mutableParams cj_setObject:[mutableTrackInfo copy] forKey:@"track_info"];
    }
    return [mutableParams copy];
}

- (NSDictionary *)p_buildTrackerParams:(NSMutableDictionary *)mutableDic {
    NSMutableDictionary *trackerParams = [NSMutableDictionary dictionary];
    NSDictionary *trackDict = [mutableDic cj_dictionaryValueForKey:@"track_info"];
    NSString *preMethod = @"";
    NSString *zgInfo = [mutableDic cj_stringValueForKey:@"zg_info"];
    [trackerParams cj_setObject:CJString([trackDict cj_stringValueForKey:@"trace_id"]) forKey:@"trace_id"];
    if(Check_ValidString(zgInfo)) {
        NSDictionary *zgDict = [[NSDictionary alloc] initWithDictionary:[zgInfo cj_toDic] ?: @{}];
        preMethod = [[zgDict cj_dictionaryValueForKey:@"pay_info"] cj_stringValueForKey:@"business_scene"];
        [trackerParams cj_setObject:[[zgDict cj_dictionaryValueForKey:@"merchant_info"] cj_stringValueForKey:@"app_id"] forKey:@"app_id"];
        [trackerParams cj_setObject:[[zgDict cj_dictionaryValueForKey:@"merchant_info"] cj_stringValueForKey:@"merchant_id"] forKey:@"merchant_id"];
        NSDictionary *tradeInfo = [zgDict cj_dictionaryValueForKey:@"trade_info"]?:@{};
        [trackerParams cj_setObject:[tradeInfo cj_stringValueForKey:@"trade_no"] forKey:@"trade_no"];

    } else {
        NSInteger payType = [trackDict cj_integerValueForKey:@"pay_type"];
        switch (payType) {
            case 1:
                preMethod = @"wx";
                break;
            case 2:
                preMethod = EN_zfb;
                break;
            default:
                break;
        }
        [trackerParams cj_setObject:[trackDict cj_stringValueForKey:@"app_id"] forKey:@"app_id"];
        [trackerParams cj_setObject:[trackDict cj_stringValueForKey:@"merchant_id"] forKey:@"merchant_id"];//支付宝微信在继续支付页，这两个参数会不下发
    }

    
    if([preMethod isEqualToString:@"Pre_Pay_Combine"]) {//区分两种组合支付方式
        NSString *primaryPayType = [trackDict cj_stringValueForKey:@"primary_pay_type"];
        if([primaryPayType isEqualToString:@"13_4"]) {
            preMethod = @"Pre_Pay_Balance_Bankcard";
        } else if ([primaryPayType isEqualToString:@"13_9"]) {
            preMethod = @"Pre_Pay_Balance_Newcard";
        }
    }
    [trackerParams cj_setObject:preMethod forKey:@"pre_method"];
    
    return [trackerParams copy];
}

#pragma - mark CJPayAPIWrapperProtocol
- (void)callState:(BOOL)success fromScene:(CJPayScene)scene from:(CJPayAPIRequestMsgWrapper *)msgWrapper {
    if (msgWrapper.originalDelegate) {
        [msgWrapper.originalDelegate callState:success fromScene:scene];
    }
}

- (void)onResponse:(CJPayAPIBaseResponse *)response from:(CJPayAPIRequestMsgWrapper *)msgWrapper {
    response.data = [self p_callBackDataWithResponse:response];
    if (msgWrapper.originalDelegate) {
        [msgWrapper.originalDelegate onResponse:response];
        [self p_trackTTPayCallbackWithResponse:response from:msgWrapper];
        [self.multiApiDelegates removeObjectForKey:msgWrapper.identify];
    }
}

- (void)p_justOnResponse:(CJPayAPIBaseResponse *)response from:(CJPayAPIRequestMsgWrapper *)msgWrapper {
    if (msgWrapper.originalDelegate) {
        [msgWrapper.originalDelegate onResponse:response];
        [self p_trackTTPayCallbackWithResponse:response from:msgWrapper];
        [self.multiApiDelegates removeObjectForKey:msgWrapper.identify];
    }
}

#pragma - mark 回调参数处理
- (NSDictionary *)p_callBackDataWithResponse:(CJPayAPIBaseResponse *)response
{
    switch (response.scene) {
        case CJPaySceneEcommercePay:
        case CJPayScenePay:
        case CJPayScenePreStandardPay:
            return [self p_buildCallbackPayDictWithResponse:response];
        case CJPaySceneBindCard:
            return [self p_callbackBindCardDictWithResponse:response];
        case CJPaySceneParamsService:
            return [self p_buildParamsSeriveDictWithResponse:response];
        case CJPaySceneGeneralAbilityService:
            return [self p_buildGeneralAbilityServiceDictWithResponse:response];
        case CJPaySceneLynxCard:
            return [self p_buildLynxCardDictWithResponse:response];
        case CJPaySceneLynxBindCardCallMiniApp:
            return [self p_buildCallBackLynxBindCardCallMiniAppWithResponse:response];
        default:
            break;
    }
    return [self p_buildCallbackPayDictWithResponse:response]; //默认走支付的回调
}

- (NSDictionary *)p_buildCallBackLynxBindCardCallMiniAppWithResponse:(CJPayAPIBaseResponse *)response {
    NSDictionary *dict = @{
        @"code":CJString([response.data cj_stringValueForKey:@"code"]),
        @"data":CJString([response.data cj_stringValueForKey:@"schema"])
    };
    return dict;
}

- (NSDictionary *)p_buildLynxCardDictWithResponse:(CJPayAPIBaseResponse *)response {
    
    NSInteger resCode;
    if (response.error.code == CJPayErrorCodeCallFailed) {
        resCode = 500;
    }
    NSString *errorMessage = CJString(response.error.domain);
    NSDictionary *dict = @{
        @"code": @(resCode),
        @"msg" : errorMessage,
    };
    return dict;
}

- (NSDictionary *)p_buildGeneralAbilityServiceDictWithResponse:(CJPayAPIBaseResponse *)response {
    NSUInteger resCode = 0;
    NSString *errorMessage = CJString([response.data cj_stringValueForKey:@"msg"]);
    NSDictionary *dict = @{
        @"code": @(resCode),
        @"msg" : errorMessage,
        @"data": [response.data cj_toStr]?: @{}
    };
    return dict;
}

- (NSDictionary *)p_buildParamsSeriveDictWithResponse:(CJPayAPIBaseResponse *)response {
    NSUInteger resCode = 0;
    NSString *errorMessage = CJString([response.data cj_stringValueForKey:@"msg"]);
    NSDictionary *dict = @{
        @"code": @(resCode),
        @"msg" : errorMessage,
        @"data": [response.data cj_stringValueForKey:@"data"] ?: @{}
    };
    return dict;
}

- (NSDictionary *)p_buildCallbackPayDictWithResponse:(CJPayAPIBaseResponse *)response {
    
    NSDictionary *data = response.data;
    // ttcjpay.ttpay service=98时，若cj_ttpay_flag=new，则返回新的统一回调结构
    if ([[data cj_stringValueForKey:@"service"] isEqualToString:@"98"] && [[data cj_stringValueForKey:@"cj_ttpay_flag"] isEqualToString:@"new"]) {
        return [self p_buildUnifiedCallbackDictWithResponse:data];
    }
    
    NSUInteger resCode;
    NSString *errorMessage = @"";
    NSString *extStr = @"";
    switch (response.error.code) {
        case CJPayErrorCodeSuccess:
            resCode = 0;
            errorMessage = @"支付成功";
            break;
        case CJPayErrorCodeOrderTimeOut:
            resCode = 1;
            errorMessage = @"支付超时";
            break;
        case CJPayErrorCodeFail:
            resCode = 2;
            errorMessage = @"支付失败";
            break;
        case CJPayErrorCodeCancel:
            resCode = 4;
            errorMessage = @"支付取消";
            break;
        case CJPayErrorCodeProcessing:
            resCode = 9;
            errorMessage = @"支付处理中";
            break;
        case CJPayErrorCodeInsufficientBalance:
            resCode = 113;
            errorMessage = @"余额不足";
            extStr = [response.error.userInfo cj_stringValueForKey:NSLocalizedDescriptionKey];
            break;
        case CJPayErrorCodeUnLogin:
            resCode = 108;
            errorMessage = @"用户未登录";
            break;
        case CJPayErrorCodeAntiFraudCanceled:
            resCode = 116;
            errorMessage = @"风险提示后取消支付";
            break;
        case CJPayErrorCodeBackToForground:
            resCode = 117;
            errorMessage = @"用户切前台";
            break;
        default:
            resCode = 109;
            errorMessage = @"网络异常";
            break;
    }
    
    if (!response.error) {
        resCode = 2;
        errorMessage = @"支付失败";
    }
    
    NSString *msg = errorMessage;
    if (response.scene == CJPayScenePreStandardPay) {
        NSMutableDictionary *msgDictionary = [NSMutableDictionary dictionaryWithDictionary:@{
            @"result_msg": CJString(errorMessage),
            @"has_sdk_show_retain": CJString([response.data cj_stringValueForKey:@"has_cashier_show_retain"])
        }];
        if (extStr.length > 0) {
            NSDictionary *extDict = [extStr cj_toDic];
            [msgDictionary addEntriesFromDictionary:extDict];
        }
        msg = CJString([msgDictionary cj_toStr]);
    }
    NSDictionary *dict = @{
        @"code": @(resCode),
        @"msg" : CJString(msg),
        @"data": [response.data cj_toStr] ?: @{}
    };
    [CJTracker event:@"finance_ecommerce_ttpay_result" params:dict];
    
    return dict;
}

- (NSDictionary *)p_callbackBindCardDictWithResponse:(CJPayAPIBaseResponse *)response {
    NSUInteger resCode;
    NSString *errorMessage = @"";
    switch (response.error.code) {
        case CJPayErrorCodeSuccess:
            resCode = 4100;
            errorMessage = @"绑卡成功";
            break;
        case CJPayErrorCodeFail:
            resCode = 4101;
            errorMessage = @"绑卡失败";
            break;
        case CJPayErrorCodeCancel:
            resCode = 4102;
            errorMessage = @"绑卡取消";
            break;
        default:
            resCode = 109;
            errorMessage = @"网络异常";
            break;
    }
    
    NSDictionary *dict = @{
        @"code": @(resCode),
        @"msg" : errorMessage,
        @"data": [response.data cj_toStr] ?: @{}
    };
    [CJTracker event:@"finance_ecommerce_ttpay_result" params:dict];
    return dict;
}

// 命中ttcjpay.ttpay service=98的新路径时，回调结构与安卓端、宿主app.ttpay的jsb保持一致
- (NSDictionary *)p_buildUnifiedCallbackDictWithResponse:(NSDictionary *)data {
    
    if (![[data cj_stringValueForKey:@"service"] isEqualToString:@"98"]) {
        CJPayLogAssert(YES, @"ttcjpay.ttpay统一回调结构仅适配service=98");
    }
    
    NSMutableDictionary *callbackData = [NSMutableDictionary new];
    [callbackData cj_setObject:CJString([data cj_stringValueForKey:@"cj_ttpay_flag"]) forKey:@"cj_ttpay_flag"];
    [callbackData addEntriesFromDictionary:[data cj_dictionaryValueForKey:@"data"] ?: @{}];

    return [callbackData copy];
}
@end
