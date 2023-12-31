//
//  EMAConfig.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/4/9.
//

#import "EMAConfig.h"
#import "EMADebugUtil.h"
#import "BDPBlankDetectConfig.h"
#import "BDPCommonManager.h"
#import <ECOInfra/BDPMacros.h>
#import "BDPUtils.h"
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import "OPAPIFeatureConfig.h"
#import "BDPSettingsManager.h"
#import "BDPSettingsManager+BDPExtension.h"
#import "BDPVersionManager.h"
#import "BDPSDKConfig.h"
#import <ECOInfra/ECOConfig.h>
#import <ECOInfra/EMAConfigManager.h>


@interface EMAConfig ()

@property (nonatomic) ECOConfig *config;

@end

@implementation EMAConfig

- (instancetype)initWithECOConfig:(ECOConfig *)config {
    if (self = [super init]) {
        _config = config;
    }
    return self;
}

# pragma mark - bizs
# pragma mark -

- (NSArray *)appRouteConfigList {
    return [self.config getArrayValueForKey:@"appRouteConfigList"];
}

/// 判断小程序是否需要灰度
- (BOOL)isMicroAppTestForUniqueID:(BDPUniqueID *)uniqueID {
    if ([EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDDoNotGrayApp].boolValue) {
        BDPLogInfo(@"isMicroAppTest DoNotGrayApp %@", BDPParamStr(uniqueID));
        return NO;
    }
    NSDictionary *configDic = [self getConfigDicByUniqueID:uniqueID];
    BOOL isTest = NO;
    if (configDic != nil) {
        NSString *configKey = @"isTest";
        if ([configDic.allKeys containsObject:configKey]) {
            isTest = [configDic bdp_boolValueForKey:configKey];
        }
    }
    return isTest;
}

//判断JSPAI是否在白名单内（新JSAPI注册机制）
-(BOOL)isJSAPIInAllowlist:(NSString *)jsapi
{
    //jsapiAllowConfig shoule be like below:
    //{"allowlist":["docsPicker","showShareMenu"],"allApproved":"true/false"};
    NSDictionary * jsapiAllowConfig = [self.config getDictionaryValueForKey:@"jsapiAllowlist"];
    NSArray * allowlist = [jsapiAllowConfig bdp_arrayValueForKey:@"allowlist"];
    if ([allowlist containsObject:jsapi]) {
        return YES;
    }else if([jsapiAllowConfig bdp_boolValueForKey:@"allApproved"]){
        return YES;
    }
    return NO;
}

/// 是否开启小程序的调试页面
- (BOOL)isDebug {
    return [self.config getBoolValueForKey:@"debug"];
}

/// 判断小程序是否需要检验域名白名单
- (BOOL)checkDomainsForUniqueID:(BDPUniqueID *)uniqueID {
    // 接口请求失败时，默认返回NO，即不校验域名白名单
    BOOL failResult = NO;
    if (!uniqueID.isValid) {
        BDPLogWarn(@"Invalid uniqueID %@", BDPParamStr(uniqueID));
        return failResult;
    }
    NSDictionary *checkDomainsDict = [self.config getDictionaryValueForKey:@"checkDomains"];
    if (!checkDomainsDict) {
        BDPLogInfo(@"!checkDomainsDict %@", BDPParamStr(uniqueID));
        return failResult;
    }

    NSDictionary *appIDDict = checkDomainsDict[@"appIDs"];
    NSNumber *checkDomainsObj = appIDDict[uniqueID.appID];
    BOOL result = failResult;
    // 如果appIDs包含当前小程序id，则使用其中的值；否则使用default值作为默认值
    if (checkDomainsObj) {
        result = [checkDomainsObj boolValue];
    } else {
        NSNumber *defaultObj = checkDomainsDict[@"default"];
        if (defaultObj) {
            result = [defaultObj boolValue];
        }
    }
    BDPLogDebug(@"checkDomainsForAppID %@", BDPParamStr(@(result)));
    return result;
}

- (NSArray *)cookieUrlsForUniqueID:(BDPUniqueID *)uniqueID {
    if (!uniqueID.isValid) {
        BDPLogWarn(@"Invalid uniqueID %@", BDPParamStr(uniqueID));
        return nil;
    }
    NSArray *cookieDomains = [self.config getArrayValueForKey:@"cookieUrlBlackList"];
    __block NSArray *domains = @[];
    [cookieDomains enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[obj bdp_stringValueForKey:@"app_id"] isEqualToString:uniqueID.appID]) {
            domains = [obj bdp_arrayValueForKey:@"urls"];
        }
    }];
    return domains;
}

- (NSDictionary *)getConfigDicByUniqueID:(BDPUniqueID *)uniqueID {

    if (!uniqueID) {
        return nil;
    }

    NSArray *pList = [self.config getArrayValueForKey:@"pList"];
    if (!pList) {
        return nil;
    }

    NSDictionary *resultDic = nil;
    for (id obj in pList) {
        if (![obj isKindOfClass:NSDictionary.class]) {
            continue;
        }
        NSDictionary *maConfig = obj;
        NSString *tID = [maConfig bdp_stringValueForKey:@"id"];
        if ([tID isEqualToString:uniqueID.appID]) {
            resultDic = maConfig;
            break;
        }
    }
    return resultDic;
}

- (NSDictionary *)abTestConfig {
    return [self.config getDictionaryValueForKey:@"ABTestConfig"];
}

#pragma mark - AB Test

- (NSDictionary *)internalapiWhiteList {
    return [self.config getDictionaryValueForKey:@"internalapiWhiteList"];
}

- (NSDictionary *)componentFeatureWhiteList {
    return [self.config getDictionaryValueForKey:@"componentFeatureWhiteList"];
}

- (NSDictionary *)apiFeatureWhiteList {
    return [self.config getDictionaryValueForKey:@"apiFeatureWhiteList"];
}

- (BOOL)setStorageLimitCheck {
    return [self.config getBoolValueForKey:@"setStorageLimitCheck"];
}

- (BOOL)updateMineAboutEnable {
    return [self.abTestConfig bdp_boolValueForKey:@"updateMineAboutEnable"];
}

- (BOOL)returnLocations {
    return [self.abTestConfig bdp_boolValueForKey:@"returnLocations"];
}

- (NSTimeInterval)maxLocationCacheTime{
    return [self.abTestConfig bdp_doubleValueForKey:@"maxLocationCacheTime"] ?: 5;
}

- (BOOL)isOpeningURLInWhiteList:(NSURL *)url
           uniqueID:(BDPUniqueID *)uniqueID
            interceptForWebView:(BOOL)interceptForWebView
                       external:(BOOL)external
{
    /// 小程序openURL域名白名单
    /// 类型：Array[{appid, schema, host}, ...]
    NSString *schema = url.scheme;
    NSString *host = url.host;

    NSArray *urlWhiteList = nil;
    if(interceptForWebView) {
        urlWhiteList = [self.config getArrayValueForKey:@"openURLWhiteList"];
    } else {
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
        BDPModel *appModel = common.model;
        NSNumber* enableWhiteListNum = [appModel.extraDict bdp_objectForKey:@"useOpenSchemaWhiteList" ofClass:[NSNumber class]];
        urlWhiteList = [appModel.extraDict bdp_arrayValueForKey:@"openSchemaWhiteList"];

        // enableWhiteListNum 不存在，为异常情况，不允许跳转
        if(!enableWhiteListNum) {
            BDPLogError(@"useOpenSchemaWhiteList in meta is nil");
            return NO;
        }
        //enableWhiteListNum关闭，可以任意跳转
        if(![enableWhiteListNum boolValue]) {
            return YES;
        }
    }

    for (NSInteger i = 0; i < urlWhiteList.count; i++) {
        NSDictionary *urlWhiteItem;
        if ([urlWhiteList[i] isKindOfClass:[NSDictionary class]]) {
            urlWhiteItem = (NSDictionary *)(urlWhiteList[i]);
        } else {
            continue;
        }
        NSString *whiteAppid = [urlWhiteItem bdp_stringValueForKey:@"appid"];
        NSString *whiteSchema = [urlWhiteItem bdp_stringValueForKey:@"schema"];
        NSString *whiteHost = [urlWhiteItem bdp_stringValueForKey:@"host"];
        // 允许appid为空
        BOOL isAppidOK = (!BDPIsEmptyString(whiteAppid) && [whiteAppid isEqualToString:uniqueID.appID]) || (BDPIsEmptyString(whiteAppid));
        // 允许schema为空
        BOOL isSchemaOK = (!BDPIsEmptyString(whiteSchema) && [whiteSchema isEqualToString:schema]) || (BDPIsEmptyString(whiteSchema));
        // 允许host为空
        BOOL isHostOK = (!BDPIsEmptyString(whiteHost) && [whiteHost isEqualToString:host]) || (BDPIsEmptyString(whiteHost));
        if (isAppidOK && isSchemaOK && isHostOK) {
            return YES;
        }
    }
    
    BDPLogInfo(@"url not in openSchema whiteList");

    return NO;
}

- (BOOL)isWebviewSynchronizeCookieInWhiteListOfUniqueID:(BDPUniqueID *)uniqueID
{
    if (!uniqueID.isValid) {
        return NO;
    }
    NSDictionary *componentFeatureWhiteList = [self componentFeatureWhiteList];
    NSArray *whiteList = [componentFeatureWhiteList objectForKey:@"webviewSynchronizeCookie"];
    if (BDPIsEmptyArray(whiteList)) {
        return NO;
    }
    if ([whiteList containsObject:uniqueID.appID]) {
        return YES;
    }

    return NO;
}

- (BOOL)isVideoAvoidSameLayerRenderForUniqueID:(BDPUniqueID *)uniqueID
{
    if (!uniqueID.isValid) {
        return NO;
    }
    NSDictionary *componentFeatureWhiteList = [self componentFeatureWhiteList];
    NSArray *avoidList = [componentFeatureWhiteList bdp_arrayValueForKey:@"videoAvoidSameLayerRender"];
    if (BDPIsEmptyArray(avoidList)) {
        return NO;
    }
    if ([avoidList containsObject:uniqueID.appID]) {
        return YES;
    }

    return NO;
}

- (BOOL)isMapUseSameLayerRenderForUniqueID:(BDPUniqueID *)uniqueID
{
    if (!uniqueID.isValid) {
        return NO;
    }
    NSDictionary *componentFeatureWhiteList = [self componentFeatureWhiteList];
    NSArray *useList = [componentFeatureWhiteList bdp_arrayValueForKey:@"mapUseSameLayerRender"];
    if (BDPIsEmptyArray(useList)) {
        return NO;
    }
    if ([useList containsObject:uniqueID.appID]) {
        return YES;
    }

    return NO;
}

- (BOOL)isGetSystemInfoHeightInWhiteListOfUniqueID:(BDPUniqueID *)uniqueID
{
    if (!uniqueID.isValid) {
        return NO;
    }
    NSDictionary *apiFeatureWhiteList = [self apiFeatureWhiteList];
    NSArray *whiteList = [apiFeatureWhiteList objectForKey:@"getSystemInfoHeight"];
    if (BDPIsEmptyArray(whiteList)) {
        return NO;
    }
    if ([whiteList containsObject:uniqueID.appID]) {
        return YES;
    }

    return NO;
}

- (BOOL)isApiAvailable:(NSString *)apiName forUniqueID:(BDPUniqueID *)uniqueID {
    if (!uniqueID.isValid) {
        return NO;
    }
    NSDictionary *apiWhiteList = [self internalapiWhiteList];
    if (BDPIsEmptyDictionary(apiWhiteList)) {
        return NO;
    }
    NSArray *appIDList = [apiWhiteList bdp_arrayValueForKey:apiName];
    if (BDPIsEmptyArray(appIDList)) {
        return NO;
    }
    return [appIDList containsObject:uniqueID.appID];
}


- (NSDictionary *)preloadConfig {
    return [self.config getLatestDictionaryValueForKey:@"openplatform_gadget_preload"];
}

- (NSUInteger)maxTimesOneDay {
    return [self.preloadConfig bdp_doubleValueForKey:@"maxTimesOneDay"] ?: 15;
}

- (NSTimeInterval)checkDelayAfterNetworkChange {
    return [self.preloadConfig bdp_doubleValueForKey:@"checkDelayAfterNetworkChange"] ?: 30;
}

- (NSTimeInterval)checkDelayAfterLaunch {
    return [self.preloadConfig bdp_doubleValueForKey:@"checkDelayAfterLaunch"] ?: 0;
}

- (NSTimeInterval)minTimeSinceLastCheck {
    return [self.preloadConfig bdp_doubleValueForKey:@"minTimeSinceLastCheck"] ?: (60 * 10);
}

- (NSTimeInterval)minTimeSinceLastUpdate {
    return [self.preloadConfig bdp_doubleValueForKey:@"minTimeSinceLastUpdate"] ?: 30;
}

- (NSTimeInterval)minTimeSinceLastPullUpdateInfo {
    return [self.preloadConfig bdp_doubleValueForKey:@"minTimeSinceLastPullUpdateInfo"] ?: (60 * 60 * 8);
}

- (NSDictionary *)getPreloadLocationParamsForUniqueID:(BDPUniqueID *)uniqueID {
    return [[self.preloadConfig bdp_dictionaryValueForKey:@"preloadLocation"] bdp_dictionaryValueForKey:uniqueID.appID];
}

- (NSDictionary *)getPreloadDNSParamsForUniqueID:(BDPUniqueID *)uniqueID {
    return [[self.preloadConfig bdp_dictionaryValueForKey:@"preloadDNS"] bdp_dictionaryValueForKey:uniqueID.appID];
}

- (NSDictionary *)getPreloadConnectedWifiParamsForUniqueID:(BDPUniqueID *)uniqueID {
    return [[self.preloadConfig bdp_dictionaryValueForKey:@"preloadConnectedWifi"] bdp_dictionaryValueForKey:uniqueID.appID];
}


#pragma mark 对不同小程序定制动画时间

- (NSDictionary *)appearanceConfig {
    return [self.config getDictionaryValueForKey:@"appearanceConfig"];
}

- (id)appearanceConfig:(NSString *)configName uniqueID:(BDPUniqueID *)uniqueID ofClass:(Class)aClass {
    if (!configName) {
        return nil;
    }
    NSDictionary *appearanceConfig = self.appearanceConfig;
    NSDictionary *appConfig = [appearanceConfig bdp_dictionaryValueForKey:@"appConfig"];
    NSDictionary *app = uniqueID.appID ? [appConfig bdp_dictionaryValueForKey:uniqueID.appID] : nil;
    id config = [app bdp_objectForKey:configName ofClass:(Class)aClass];
    if (config) {
        return config;
    }
    NSDictionary *defaultConfig = [appearanceConfig bdp_dictionaryValueForKey:@"defaultConfig"];
    return [defaultConfig bdp_objectForKey:configName ofClass:(Class)aClass];
}

- (NSTimeInterval)loadingDismissAnimationDurationForUniqueID:(BDPUniqueID *)uniqueID {
    NSNumber *loadingDismissAnimationDuration = [self appearanceConfig:@"loadingDismissAnimationDuration" uniqueID:uniqueID ofClass:NSNumber.class];
    if (loadingDismissAnimationDuration) {
        return loadingDismissAnimationDuration.integerValue / 1000.0;
    }
    return 0.3f;
}

- (NSTimeInterval)loadingDismissScaleAnimationDurationForUniqueID:(BDPUniqueID *)uniqueID {
    NSNumber *loadingDismissScaleAnimationDuration = [self appearanceConfig:@"loadingDismissScaleAnimationDuration" uniqueID:uniqueID ofClass:NSNumber.class];
    if (loadingDismissScaleAnimationDuration) {
        return loadingDismissScaleAnimationDuration.integerValue / 1000.0;
    }
    return 0.15f;
}

#pragma mark app切后台杀掉热缓存
// app切后台杀掉热缓存
- (BOOL)killBackgroundAppEnabled {
    return [self.abTestConfig bdp_boolValueForKey:@"killBackgroundAppEnabled"];
}

- (NSTimeInterval)backgroundAppAliveTimeInterval {
    return [self.abTestConfig bdp_doubleValueForKey:@"backgroundAppAliveTimeInterval"] ?: 5;
}

#pragma mark 启动埋点灰度
- (BOOL)enableAppLaunchDetailEvent {
    return [self.abTestConfig bdp_boolValueForKey:@"enableAppLaunchDetailEvent"] ?: NO;
}

#pragma mark Monitor
- (NSDictionary *)monitorConfig {
    return [self.config getDictionaryValueForKey:@"monitor"] ?: [self.config getDictionaryValueForKey:@"op_monitor"];
}

- (NSDictionary *)performanceMonitorConfig {
    return [self.monitorConfig bdp_dictionaryValueForKey:@"op_performance_monitor"];
}

- (NSDictionary *)networkMonitor {
    return [self.monitorConfig bdp_dictionaryValueForKey:@"network_monitor"];
}

- (BOOL)networkMonitorEnable {
    return self.networkMonitor != nil;
}

- (BOOL)shouldMonitorNetworkForUniqueID:(BDPUniqueID *)uniqueID domain:(NSString *)domain {
    NSDictionary *networkMonitor = self.networkMonitor;
    if (!networkMonitor) {
        return NO;
    }
    NSArray *domainWhiteList = [networkMonitor bdp_arrayValueForKey:@"domain_white_list"];
    if (!BDPIsEmptyString(domain) && !BDPIsEmptyArray(domainWhiteList)) {
        if ([domainWhiteList containsObject:domain]) {
            return YES;
        }
    }
    NSArray *appWhiteList = [networkMonitor bdp_arrayValueForKey:@"app_white_lilst"];
    if (uniqueID.isValid && !BDPIsEmptyArray(appWhiteList)) {
        if ([appWhiteList containsObject:uniqueID.appID]) {
            return YES;
        }
    }
    if (BDPIsEmptyArray(domainWhiteList) && BDPIsEmptyArray(appWhiteList)) {
        return YES;
    }
    return NO;
}

- (NSArray<NSString *> *)tea2slardarList {
    return [self.monitorConfig bdp_arrayValueForKey:@"tea2slardar"];
}

- (NSUInteger)jsRuntimeOvercountNumber {
    return [self.performanceMonitorConfig bdp_unsignedIntegerValueForKey:@"js_runtime_overcount_number"];
}

- (NSUInteger)appPageOvercountNumber {
    return [self.performanceMonitorConfig bdp_unsignedIntegerValueForKey:@"app_page_overcount_number"];
}

- (NSUInteger)taskOvercountNumber {
    return [self.performanceMonitorConfig bdp_unsignedIntegerValueForKey:@"task_overcount_number"];
}

#pragma mark 引擎开发者高级配置
- (NSDictionary *)magicConfig {
    return [self.config getDictionaryValueForKey:@"magicConfig"];
}

- (BOOL)isSuperDeveloper {
    return [self.magicConfig bdp_boolValueForKey:@"sp"];
}

- (BOOL)enableDebugApp {
    NSDictionary *magicConfig = [self magicConfig];
    if (BDPIsEmptyDictionary(magicConfig)) {
        return NO;
    }
    if (!magicConfig[@"enableDebugApp"]) {
        return NO;
    }

    return YES;
}

- (NSString *)debuggerAppID {
    NSDictionary * magicConfig = [self magicConfig];
    if (BDPIsEmptyDictionary(magicConfig)) {
        return nil;
    }
    NSString * appID = [magicConfig bdp_stringValueForKey:@"debugAppID"];
    if (BDPIsEmptyString(appID)) {
        return nil;
    }
    return appID;
}

#pragma mark 是否特化分享裸链
- (BOOL)shouldShareOnlyLinkSpeciallyWithUniqueID:(BDPUniqueID *)uniqueID {
    if (!uniqueID.isValid) {
        return NO;
    }
    return [[self.config getArrayValueForKey:@"shareOnlyLinkApps"] containsObject:uniqueID.appID];
}

#pragma mark webview 白屏监测配置
- (BDPBlankDetectConfig *)getDetectConfig {
    NSDictionary *blankDetectConfig = [self.config getDictionaryValueForKey:@"blank_detect"];
    if (!blankDetectConfig) {
        return nil;
    }
    NSDictionary *strategy = [blankDetectConfig bdp_dictionaryValueForKey:@"strategy"];
    if (!strategy) {
        return nil;
    }
    NSString *jsonStrategy = [strategy JSONRepresentation];
    if (BDPIsEmptyString(jsonStrategy)) {
        return nil;
    }
    BDPBlankDetectConfig *config = [[BDPBlankDetectConfig alloc] init];
    config.strategy = jsonStrategy;
    return config;
}

#pragma mark 动态启动参数下发相关配置[止血版本]
- (NSArray *)configSchemeParameterAppList {
    NSDictionary * config = [self.config getLatestDictionaryValueForKey:@"configSchemaParameterLittleAppList"];
    return [config bdp_arrayValueForKey:@"configAppList"];
}

#pragma mark H5 调用TT.系列api是否需要授权, 默认需要授权，在白名单里的不需要授权
- (BOOL)shouldAuthForWebAppWithUniqueID:(BDPUniqueID *)uniqueID {
    if (!uniqueID.isValid) {
        return YES;
    }
    return ![[self.config getArrayValueForKey:@"web_app_api_auth_pass_list"] containsObject:uniqueID.appID];
}


#pragma mark API 全形态适配灰度策略
// see: https://bytedance.feishu.cn/docs/doccnkBm38qgbJbnFh4TQOoBIH0#CVsltD
- (NSDictionary *)apiDispatchConfig {
    return [self.config getDictionaryValueForKey:@"universalAPI"];
}

- (OPAPIFeatureConfig *)apiIDispatchConfig:(NSDictionary *)config forAppType:(OPAppType)appType apiName:(NSString *)apiName {
    NSString *appTypeKey = @"";
    switch (appType) {
        case OPAppTypeUnknown:
            break;
        case OPAppTypeGadget:
            appTypeKey = @"gadget";
            break;
        case OPAppTypeWebApp:
            appTypeKey = @"webApp";
            break;
        case OPAppTypeWidget:
            appTypeKey = @"widget";
            break;
        case OPAppTypeBlock:
            appTypeKey = @"block";
            break;
        case OPAppTypeDynamicComponent:
            appTypeKey = @"dynamicComponent";
            break;
        case OPAppTypeThirdNativeApp:
            appTypeKey = @"thirdNativeApp";
            break;
        case OPAppTypeSDKMsgCard:
            appTypeKey = @"msgCardTemplate";
            break;
    }
    NSDictionary *apiCommandList = [config bdp_dictionaryValueForKey:appTypeKey];
    NSString *apiConfig = [apiCommandList bdp_stringValueForKey:apiName];
    return [[OPAPIFeatureConfig alloc] initWithCommandString:apiConfig];
}

- (BOOL)wkwebviewInput {
    return [self.config getBoolValueForKey:@"WKWebViewInput"];
}

- (NSDictionary *)jssdkConfig {
    return [self.config getDictionaryValueForKey:@"jssdk"];
}

- (NSDictionary *)blockJSSdkConfig {
    return [self.config getDictionaryValueForKey:@"blockit_mobile_jssdk"];
}

- (NSDictionary *)msgCardTemplateConfig {
    return [self.config getDictionaryValueForKey:@"msg_card_template_config"];
}

- (void)registerBackgroundAppSettings {
    [BDPSettingsManager.sharedManager addSettings:@{
        kBDPSABTestBackGroundKillEnable: @([self killBackgroundAppEnabled]),
        kBDPSABTestBackGroundAliveTime: @([self backgroundAppAliveTimeInterval])
    }];
}

- (void)checkTMASwitch {
    BDPLogInfo(@"checkTMASwitch");

    NSDictionary *config = [self.config getDictionaryValueForKey:@"jssdk"];
    if (!config) {
        BDPLogWarn(@"!config");
        return;
    }

    // 控制小服务功能是否启用 0表示启用，1表示关闭，默认为启用
    BOOL tmaSwitch = [config bdp_boolValueForKey:@"tmaSwitch"];
    // lint:disable:next lark_storage_check
    [[NSUserDefaults standardUserDefaults] setObject:@(tmaSwitch) forKey:kLocalTMASwitchKeyV2];

    BDPLogInfo(@"%@", BDPParamStr(tmaSwitch))
}

- (void)updateJSSDKConfig {
    // 将 JSSDK 版本、greyHash、下载地址透传至 BDPSDKConfig 内，用于真机调试时的 initWorker
    NSDictionary *jssdk = [self.config getDictionaryValueForKey:@"jssdk"];
    if(!BDPIsEmptyDictionary(jssdk)) {
        NSString *sdkVersion = [jssdk bdp_stringValueForKey:@"sdkVersion"] ?: @"";
        NSString *sdkDownloadURL = [jssdk bdp_stringValueForKey:@"latestSDKUrl"] ?: @"";
        NSString *sdkUpdateVersion = [jssdk bdp_stringValueForKey:@"sdkUpdateVersion"]; // fallback 到 sdkVersion,不需要判 nil
        BDPSDKConfig *config = [BDPSDKConfig sharedConfig];
        config.jssdkVersion = sdkUpdateVersion ?: sdkVersion;
        config.jssdkDownloadURL = sdkDownloadURL;
        config.jssdkGreyHash = [jssdk bdp_stringValueForKey:@"greyHash"] ?: @"";
    }
}

@end
