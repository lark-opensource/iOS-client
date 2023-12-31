//
//  CJPayAPI.m
//  CJPay
//
//  Created by wangxinhua on 2020/7/16.
//

#import "CJPayAPI.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayBizParam.h"
#import "CJSDKParamConfig.h"
#import "CJPayUIMacro.h"
#import "UIFont+CJPay.h"
#import "CJPayLocalizedUtil.h"
#import "CJPayDeskServiceHeader.h"
#import <Gaia/Gaia.h>
#import "CJPayUniversalPayDeskService.h"
#import "CJPayAIEnginePlugin.h"

@implementation CJPayAppInfo
@end

@implementation CJPayAPI

static BOOL isConfigured;
// static CJPayAppInfo *cjpayAppInfo; 

static Class<CJPayInitDelegate> cjpayInitClass;

+ (void)registerInitClass:(Class<CJPayInitDelegate>)initClass {
    if (cjpayInitClass) {
        CJPayLogInfo([NSString stringWithFormat:@"registerInitClass多次调用:上一次：%@ - 本次：%@", cjpayInitClass, initClass]);
    }
    cjpayInitClass = initClass;
    [GAIAEngine startTasksForKey:@CJPayGaiaInitClassRegisterKey];
}

+ (void)registerAppInfo:(CJPayAppInfo *)appInfo {
    CJPayAppInfoConfig *config = [CJPayAppInfoConfig new];
    config.appId = appInfo.appID;
    config.appName = appInfo.appName;
    config.deviceIDBlock = [appInfo.deviceIDBlock copy];
    config.userIDBlock = [appInfo.userIDBlock copy];
    config.userNicknameBlock = [appInfo.userNicknameBlock copy];
    config.userPhoneNumberBlock = [appInfo.userPhoneNumberBlock copy];
    config.accessTokenBlock = [appInfo.accessTokenBlock copy];
    config.userAvatarBlock = [appInfo.userAvatarBlock copy];
    config.secLinkDomain = [appInfo.secLinkDomain copy];
    config.transferSecLinkSceneBlock = [appInfo.transferSecLinkSceneBlock copy];
    config.adapterIpadStyle = appInfo.adapterIpadStyle;
    config.infoConfigBlock = [appInfo.infoConfigBlock copy];
    config.enableSaasEnv = appInfo.enableSaasEnv;
    
    [[CJPayBizParam shared] setupAppInfoConfig:config];
    [[CJPayBizParam shared] setupRiskInfoBlock:[appInfo.reskInfoBlock copy]];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayChannelManagerModule) i_registerWXH5PayReferUrlStr:appInfo.wxH5PayRefer];
    if (Check_ValidString(appInfo.wxUniversalLink)) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayChannelManagerModule) i_registerWXUniversalLink:appInfo.wxUniversalLink];
    }
    isConfigured = YES;
    CJPayLogInfo(@"[CJPayAPI registerAppInfo]");
    [CJ_OBJECT_WITH_PROTOCOL(CJPaySecService) start];
    // 延迟几秒注册pitaya监听事件
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        id<CJPayAIEnginePlugin> aiEngine = CJ_OBJECT_WITH_PROTOCOL(CJPayAIEnginePlugin);
        if (aiEngine) {
            [aiEngine setup];
        }
    });
}

+ (void)setupLanguage:(CJPayLocalizationLanguage)language {
    [CJPayLocalizedUtil changeToCustomAppLanguage:language];
}

+ (void)setupFontScale:(CGFloat)fontScale {
    // 宿主传递入字体放大倍数
    [UIFont setCjpayFontScale:fontScale];
    [CJTracker addCommonTrackDic:@{@"font_size": @(roundf(fontScale * 100) / 100)}];
}

+ (void)registerDelegate:(id<CJBizWebDelegate>)delegate {
    [CJ_OBJECT_WITH_PROTOCOL(CJPayWebViewService) i_registerBizDelegate:delegate];
}

+ (void)registerMetaSecDelegate:(id<CJMetaSecDelegate>) delegate {
    [CJ_OBJECT_WITH_PROTOCOL(CJPayMetaSecService) i_registerMetaSecDelegate:delegate];
}

+ (void)configHost:(NSString *)hostString {
    [CJPayBizParam shared].configHost = hostString;
}

+ (void)enableMergeGeckoRequest:(BOOL)enable {
    [CJ_OBJECT_WITH_PROTOCOL(CJPayGurdService) i_enableMergeGurdRequest:enable];
}

+ (void)syncResourcesWhenSelectNotify {
    [CJ_OBJECT_WITH_PROTOCOL(CJPayGurdService) syncResourcesWhenSelectNotify];
}

+ (void)syncResourcesWhenSelectHomepage {
    [CJ_OBJECT_WITH_PROTOCOL(CJPayGurdService) syncResourcesWhenSelectHomepage];
}

+ (void)syncOfflineWith:(NSString *)appid {
    [CJ_OBJECT_WITH_PROTOCOL(CJPayOfflineService) i_registerOffline:appid];
}

+ (BOOL)canProcessURL:(NSURL *)url {
    return [CJ_OBJECT_WITH_PROTOCOL(CJPayChannelManagerModule) i_canProcessURL:url];
}

+ (BOOL)canProcessUserActivity:(NSUserActivity *)userActivity {
    return [CJ_OBJECT_WITH_PROTOCOL(CJPayChannelManagerModule) i_canProcessUserActivity:userActivity];
}

+ (void)openPayDeskWithConfig:(NSDictionary<CJPayPropertyKey,NSString *> *)configDic orderParams:(NSDictionary *)params withDelegate:(id<CJPayAPIDelegate>)delegate {
    [self lazyInitCJPay];
    if (!params.cjpay_referViewController) {
        params.cjpay_referViewController = [configDic cj_objectForKey:CJPayPropertyReferVCKey];
    }
    [CJ_OBJECT_WITH_PROTOCOL(CJPayCashierModule) i_openPayDeskWithConfig:configDic params:params delegate:delegate];
}

+ (void)openFastPayDeskWithConfig:(nullable NSDictionary<CJPayPropertyKey, id> *)configDic orderParams:(NSDictionary *)params withDelegate:(id<CJPayAPIDelegate>)delegate {
    [self lazyInitCJPay];
    if (!params.cjpay_referViewController) {
        params.cjpay_referViewController = [configDic cj_objectForKey:CJPayPropertyReferVCKey];
    }
    [CJ_OBJECT_WITH_PROTOCOL(CJPayFastPayService) i_openFastPayDeskWithConfig:configDic params:params delegate:delegate];
}

+ (void)openBDPayDeskWithConfig:(nullable NSDictionary<CJPayPropertyKey, id> *)configDic orderParams:(NSDictionary *)params delegate:(nonnull id<CJPayAPIDelegate>)delegate {
    [self lazyInitCJPay];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayBDCashierModule) i_openBDPayDeskWithConfig:configDic orderParams:params delegate:delegate];
}

+ (void)openWithdrawDeskWithConfig:(nullable NSDictionary<CJPayPropertyKey, id> *)configDic orderURL:(NSString *)url withDelegate:(id<CJPayAPIDelegate>)delegate {
    [self lazyInitCJPay];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayWithdrawService) i_openWithdrawDeskWithUrl:url delegate:delegate];
}

+ (void)openBankCardListWithMerchantId:(NSString *)merchantId appId:(NSString *)appId userId:(NSString *)userId {
    [self lazyInitCJPay];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayCardManageModule) i_openBankCardListWithMerchantId:merchantId appId:appId userId:userId];
}

+ (void)openH5PayDeskWithConfig:(nullable NSDictionary<CJPayPropertyKey, id> *)configDic orderURL:(NSString *)url withDelegate:(id<CJPayAPIDelegate>)delegate {
    [self lazyInitCJPay];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayH5DeskModule) i_openH5PayDesk:url withDelegate:delegate];
}

+ (void)openScheme:(NSString *)scheme withDelegate:(nullable id<CJPayAPIDelegate>)delegate {
    [self lazyInitCJPay];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayRouterService) i_openScheme:scheme withDelegate:delegate];
}

+ (void)openWithConfig:(nullable NSDictionary<CJPayPropertyKey, id> *)configDic scheme:(NSString *)scheme withDelegate:(id<CJPayAPIDelegate>)delegate {
    [self lazyInitCJPay];
    if (!scheme.cjpay_referViewController) {
        scheme.cjpay_referViewController = [configDic cj_objectForKey:CJPayPropertyReferVCKey];
    }
    [CJ_OBJECT_WITH_PROTOCOL(CJPayRouterService) i_openScheme:scheme withDelegate:delegate];
}

+ (void)openScheme:(NSString *)scheme callBack:(void (^)(CJPayAPIBaseResponse * _Nonnull))callback {
    [self lazyInitCJPay];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayRouterService) i_openScheme:scheme callBack:callback];
}

+ (void)openSetPasswordDeskWithParams:(NSDictionary *)params withDelegate:(id<CJPayAPIDelegate>)delegate {
    [self lazyInitCJPay];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayH5DeskModule) i_openH5SetPasswordDeskWithParams:params withDelegate:delegate];
}

+ (void)requestAuth:(NSDictionary *)params withDelegate:(id<CJPayAPIDelegate>)delegate {
    [self lazyInitCJPay];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayAuthService) i_authWith:params delegate:delegate];
}

+ (void)openBalanceWithdrawDeskWithParams:(NSDictionary *)params withDelegate:(id<CJPayAPIDelegate>)delegate {
    [self lazyInitCJPay];
    if (!params.cjpay_referViewController) {
        params.cjpay_referViewController = [params cj_objectForKey:CJPayPropertyReferVCKey];
    }
    [CJ_OBJECT_WITH_PROTOCOL(CJPayUserCenterModule) i_openNativeBalanceWithdrawDeskWithParams:params delegate:delegate];
}

+ (void)openBalanceRechargeDeskWithParams:(NSDictionary *)params withDelegate:(id<CJPayAPIDelegate>)delegate {
    [self lazyInitCJPay];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayUserCenterModule) i_openNativeBalanceRechargeDeskWithParams:params delegate:delegate];
}

+ (void)openUniteSign:(NSDictionary *)params withDelegate:(id<CJPayAPIDelegate>)delegate {
    [self lazyInitCJPay];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayUniteSignModule) i_uniteSignOnlyWithDataDict:params delegate:delegate];
}

+ (void)setTheme:(NSString *)param {
    [CJ_OBJECT_WITH_PROTOCOL(CJPayThemeModeService) i_setThemeModeWithParam:param];
}

+ (void)openBytePayDeskWithSchemaParams:(NSDictionary *)schemaParams withDelegate:(nonnull id<CJPayAPIDelegate>)delegate {
    [self lazyInitCJPay];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayOuterModule) i_openOuterDeskWithSchemaParams:schemaParams withDelegate:delegate];
}

+ (void)requestCreateOrderBeforeOpenBytePayDesk:(NSDictionary *)schemaParams {
    [self lazyInitCJPay];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayOuterModule) i_requestCreateOrderBeforeOpenBytePayDeskWith:schemaParams completion:nil];
}

+ (void)openEcommercePayDeskWithParams:(NSDictionary *)params withDelegate:(nonnull id<CJPayAPIDelegate>)delegate {
    [self lazyInitCJPay];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayEcommerceDeskService) i_openEcommercePayDeskWithParams:params delegate:delegate];
}

+ (void)openUniversalPayDeskWithParams:(NSDictionary *)params withDelegate:(nonnull id<CJPayAPIDelegate>)delegate {
    [self lazyInitCJPay];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayUniversalPayDeskService) i_openUniversalPayDeskWithParams:params withDelegate:delegate];
}

+ (void)openPayUpgradeWithParams:(NSDictionary *)params withDelegate:(id<CJPayAPIDelegate>)delegate {
    [self lazyInitCJPay];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayPayUpgradeService) i_openPayUpgradeWithParams:params delegate:delegate];
}

+ (void)getWalletUrlWithParams:(NSDictionary *)params completion:(void (^)(NSString * _Nonnull walletUrl))completionBlock {
    [self lazyInitCJPay];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayPayUpgradeService) i_getWalletUrlWithParams:params completion:completionBlock];
}

+ (NSString *)getAPIVersion {
    return [CJSDKParamConfig defaultConfig].version;
}

+ (void)lazyInitCJPay {
    if (cjpayInitClass && [cjpayInitClass respondsToSelector:@selector(initCJPay)]) {
        if (!isConfigured) {
            [cjpayInitClass initCJPay];
            isConfigured = YES;
        }
    } else {
        CJPayLogInfo(@"wallet did not impl lazy init");
        [CJTracker event:@"wallet_not_impl_lazy_init" params:@{@"is_configured": [@(isConfigured) stringValue] ?: @""}]; // 通过埋点监控懒加载未实现的情况
    }
}

@end


@implementation CJPayAPI(Deprecated)

+ (void)openTradeRecordWithAppId:(NSString *)appId merchantId:(NSString *)merchantId {
    [self lazyInitCJPay];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayH5DeskModule) i_openH5TradeRecordWithAppId:appId merchantId:merchantId];
}

+ (void)openPayManagerWithAppId:(NSString *)appId merchantId:(NSString *)merchantId {
    [self lazyInitCJPay];
    [CJ_OBJECT_WITH_PROTOCOL(CJPayH5DeskModule) i_openH5PayManagerWithAppId:appId merchantId:merchantId];
}


@end
