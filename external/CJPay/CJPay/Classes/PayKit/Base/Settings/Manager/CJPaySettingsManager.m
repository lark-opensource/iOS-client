//
//  CJPaySettingsManager.m
//  CJPay
//
//  Created by liyu on 2020/3/16.
//

#import "CJPaySettingsManager.h"

#import <sys/sysctl.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import <JSONModel/JSONModel.h>
#import "CJPayBizParam.h"
#import "CJSDKParamConfig.h"
#import "CJPayRequestParam.h"
#import "CJPaySDKMacro.h"
#import "CJPaySettings.h"
#import <ByteDanceKit/UIApplication+BTDAdditions.h>
#import "CJPayBaseRequest.h"
#import "CJPayThemeStyleService.h"
#import "CJPayProtocolManager.h"
#import "CJPayHostModel.h"
#import "CJPayBaseRequest+BDPay.h"
#import <BDNetworkTag/BDNetworkTagManager.h>
#import <BDWebImage/BDWebImageManager.h>

static NSInteger const gSettingsRequestMaxRetryCount = 1;

@interface CJPaySettingsManager ()

@property (nonatomic, strong, readwrite) CJPaySettings *remoteSettings;
@property (nonatomic, strong, readwrite) CJPaySettings *localSettings;
@property (nonatomic, strong, readwrite) CJPayIAPConfigModel *iapConfigModel;
@property (nonatomic, strong, readwrite) CJPayContainerConfig *containerConfig;
@property (nonatomic, copy) NSDictionary *settingsDict;
@property (nonatomic, assign) NSUInteger retryCount;
@property (nonatomic, copy) NSDictionary *themeModelDic;

@end

@implementation CJPaySettingsManager

#pragma mark - Public

+ (instancetype)shared
{
    static CJPaySettingsManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CJPaySettingsManager alloc] init];
    });
    return manager;
}

+ (void)settingsInit
{
    NSDictionary *themeModelDic = [CJPaySettingsManager shared].themeModelDic;
    if (!Check_ValidDictionary(themeModelDic)) {
        themeModelDic = [CJPaySettingsManager shared].currentSettings.themeModelDic;
    }

    [CJ_OBJECT_WITH_PROTOCOL(CJPayThemeStyleService) i_updateThemeStyleWithThemeDic:themeModelDic];

    [[CJPaySettingsManager shared] p_fetchSettings];
}

- (CJPaySettings *)currentSettings
{
    CJPaySettings *settings = self.remoteSettings;
    
    if (!settings) {
        settings = self.localSettings;
    }
    
    if (!settings) {
        [CJMonitor trackService:@"wallet_rd_settings_empty" extra:@{}];
    }
    
    return settings;
}

- (NSDictionary *)settingsDict {
    if (self.currentSettings.dataDict) {
        return [self.currentSettings.dataDict copy];
    } else {
        return [[self.currentSettings toDictionary] copy];
    }
}

#pragma mark - Private

- (void)p_fetchSettings
{
    // 发起settings请求操作移到子线程，避免增加主线程耗时
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *url = @"https://is.snssdk.com/service/settings/v3/";
        CJPayLogInfo(@"开始请求: %@", url);
        [[TTNetworkManager shareInstance] requestForJSONWithResponse:url params:[self p_queryParameters] method:@"GET" needCommonParams:NO headerField:[BDNetworkTagManager tagForType:BDNetworkTagTypeAuto] requestSerializer:nil responseSerializer:nil autoResume:YES callback:^(NSError *error, id obj, TTHttpResponse *response) {
            [CJMonitor trackService:@"wallet_rd_settings_fetch_result" extra:@{
                @"is_success": error ? @"0": @"1"
            }];
            
            [CJPayBaseRequest exampleMonitor:url error:error response:response];
            if (error) {
                CJPayLogInfo(@"settings/v3 error: %@", error);
                [CJMonitor trackService:@"wallet_rd_settings_common_fetch" extra:@{}];
                [self retryRequest];
                return;
            }
            
            if (obj && [obj isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dict = (NSDictionary *)obj;
                [self p_handleSettingsResponse:dict];
            } else {
                [self retryRequest];
            }
        }];
    });
    
}

- (void)p_handleSettingsResponse:(NSDictionary *)settingsResponse
{
    if (settingsResponse == nil) {
        CJPayLogInfo(@"settings/v3 empty response");
        return;
    }
    
    [self p_updateSettingsTimeWithSettingsResponse:settingsResponse];
    
    NSDictionary *payload;
    if ([settingsResponse cj_dictionaryValueForKey:@"data"]) {
        NSDictionary *data = [settingsResponse cj_dictionaryValueForKey:@"data"];
        payload = [data cj_dictionaryValueForKey:@"settings"];
    }
    if (payload == nil) {
        CJPayLogInfo(@"settings/v3 empty response payload");
        return;
    }
    self.settingsDict = [payload copy];
    NSError *jsonError = nil;
    CJPaySettings *settings = [[CJPaySettings alloc] initWithDictionary:payload error:&jsonError];
    settings.dataDict = [payload copy];
    if (jsonError) {
        CJPayLogInfo(@"settings/v3 json error: %@", jsonError);
        return;
    }
    
    if (settings == nil) {
        CJPayLogInfo(@"settings/v3 empty payload: %@", payload);
        return;
    }
    
    self.remoteSettings = settings;
    [self p_preloadSecurityLoading];

    if (![self.remoteSettings isEqual:self.localSettings]) {
        [self p_persistSettings:self.remoteSettings];
        _localSettings = nil;
    }
    
    [CJ_OBJECT_WITH_PROTOCOL(CJPayThemeStyleService) i_updateThemeStyleWithThemeDic:self.currentSettings.themeModelDic];

    //可以删除，没有地方接收这个通知
//    [[NSNotificationCenter defaultCenter] postNotificationName:CJPayThemeModeChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:CJPayFetchSettingsSuccessNotification object:nil];
}

- (void)p_updateSettingsTimeWithSettingsResponse:(NSDictionary *)settingsResponse {
    NSDictionary *data = [settingsResponse cj_dictionaryValueForKey:@"data"];
    NSInteger settingsTime = [data cj_intValueForKey:@"settings_time"];
    if (data && settingsTime > 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[NSUserDefaults standardUserDefaults] setInteger:settingsTime forKey:CJPaySettingsTimeKey];
        });
    }
}

- (void)retryRequest {
    if (self.retryCount < gSettingsRequestMaxRetryCount) {
        [self p_fetchSettings];
        self.retryCount ++;
    }
}

- (void)p_preloadSecurityLoading {
    CJPayStyleLoadingConfig *loadingConfig = self.remoteSettings.securityLoadingConfig.breatheStyleLoadingConfig;
    NSArray <NSString *> *preLoadUrlStrings = @[CJString(loadingConfig.dialogPreGif),
                             CJString(loadingConfig.dialogRepeatGif),
                             CJString(loadingConfig.dialogCompleteSuccessGif),
                             CJString(loadingConfig.panelPreGif),
                             CJString(loadingConfig.panelRepeatGif),
                             CJString(loadingConfig.panelCompleteSuccessGif)];
    NSArray <NSURL *> *preLoadUrls = [preLoadUrlStrings btd_compactMap:^id _Nullable(NSString * _Nonnull obj) {
        return [NSURL URLWithString:obj];
    }];
    [BDWebImageManager.sharedManager prefetchImagesWithURLs:preLoadUrls category:nil options:BDImageRequestDefaultPriority];
}

static NSString *CJPaySettingsCacheStringKey = @"CJPaySettingsCacheStringKey";
static NSString *CJPaySettingsTimeKey = @"CJPaySettingsTimeKey";
static NSString *CJPaySettingsIapConfig = @"CJPaySettingsIapConfig";
static NSString *CJPaySettingsContainerConfigKey = @"CJPaySettingsContainerConfigKey";
static NSString *CJPaySettingsThemeModelDicKey = @"CJPaySettingsThemeModelDicKey";

- (CJPaySettings *)localSettings
{
    if (_localSettings == nil) {
        id settingData = [[NSUserDefaults standardUserDefaults] objectForKey:CJPaySettingsCacheStringKey];
        if ([settingData isKindOfClass:[NSString class]] && settingData) {
            _localSettings = [[CJPaySettings alloc] initWithString:settingData error:NULL];
        } else if ([settingData isKindOfClass:[NSData class]] && settingData) {
            _localSettings = [[CJPaySettings alloc] initWithData:settingData error:NULL];
        }
    }
    
    return _localSettings;
}

- (CJPayIAPConfigModel *)iapConfigModel {
    if (!_iapConfigModel) {
        id settingData = [[NSUserDefaults standardUserDefaults] objectForKey:CJPaySettingsIapConfig];
        if ([settingData isKindOfClass:[NSString class]] && settingData) {
            _iapConfigModel = [[CJPayIAPConfigModel alloc] initWithString:settingData error:NULL];
        } else if ([settingData isKindOfClass:[NSData class]] && settingData) {
            _iapConfigModel = [[CJPayIAPConfigModel alloc] initWithData:settingData error:NULL];
        }
    }
    return _iapConfigModel;
}

- (CJPayContainerConfig *)containerConfig {
    if (!_containerConfig) {
        id settingData = [[NSUserDefaults standardUserDefaults] objectForKey:CJPaySettingsContainerConfigKey];
        if ([settingData isKindOfClass:[NSString class]] && settingData) {
            _containerConfig = [[CJPayContainerConfig alloc] initWithString:settingData error:NULL];
        } else if ([settingData isKindOfClass:[NSData class]] && settingData) {
            _containerConfig = [[CJPayContainerConfig alloc] initWithData:settingData error:NULL];
        }
    }
    return _containerConfig;
}

-(NSDictionary *)themeModelDic {
    if (!_themeModelDic) {
        id settingData = [[NSUserDefaults standardUserDefaults] objectForKey:CJPaySettingsThemeModelDicKey];
        if ([settingData isKindOfClass:[NSString class]] && settingData) {
            _themeModelDic = [(NSString *)settingData cj_toDic];
        } else if ([settingData isKindOfClass:[NSData class]] && settingData) {
            _themeModelDic = [NSJSONSerialization JSONObjectWithData:(NSData *)settingData options:NSJSONReadingMutableContainers error:nil];

        }
    }
    return _themeModelDic;
}

- (void)p_persistSettings:(CJPaySettings *)settings
{
    if (!settings) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NSUserDefaults standardUserDefaults] setObject:[settings toJSONString]
                                                  forKey:CJPaySettingsCacheStringKey];
        if (settings.iapConfigModel) {
            [[NSUserDefaults standardUserDefaults] setObject:[settings.iapConfigModel toJSONString] forKey:CJPaySettingsIapConfig];
        }
        if (settings.containerConfig) {
            [[NSUserDefaults standardUserDefaults] setObject:[settings.containerConfig toJSONString] forKey:CJPaySettingsContainerConfigKey];
        }
        if (Check_ValidDictionary(settings.themeModelDic)) {
            [[NSUserDefaults standardUserDefaults] setObject:[settings.themeModelDic cj_toStr] forKey:CJPaySettingsThemeModelDicKey];
        }
    });
}

#pragma mark - Private

- (NSString *)p_deviceModel
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    
    char *answer = malloc(size);
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    
    NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    free(answer);
    
    if ([results hasSuffix:@"86"] || [results isEqual:@"x86_64"]) {
        BOOL smallerScreen = [[UIScreen mainScreen] bounds].size.width < 768;
        return smallerScreen ? @"iPhone Simulator" : @"iPad Simulator";
    }

    return results;
}

- (NSDictionary<NSString *, NSString *> *)p_queryParameters
{
    NSMutableDictionary *queries = [@{
        @"caller_name": @"newcjpaysdk",
        @"os_version": CJString([UIDevice currentDevice].systemVersion),
        @"device_brand": @"Apple",
        @"device_model": CJString([self p_deviceModel]),
        @"new_config": @"new_config",
        @"sdk_version_code": CJString([CJSDKParamConfig defaultConfig].settingsVersion),
        @"app_id": CJString([CJPayRequestParam gAppInfoConfig].appId),
        @"aid": CJString([CJPayRequestParam gAppInfoConfig].appId),//ppe校验
    } mutableCopy];

    NSString *platformNameString = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? @"ipad" : @"iphone";
    queries[@"device_platform"] = CJString(platformNameString);
    NSString *currentLanager = ([CJPayLocalizedUtil getCurrentLanguage] == CJPayLocalizationLanguageZhhans) ? @"zh" : @"en" ;
    [queries cj_setObject:currentLanager forKey:@"language"];
    if ([CJPayRequestParam gAppInfoConfig].deviceIDBlock) {
        NSString *deviceId = [CJPayRequestParam gAppInfoConfig].deviceIDBlock();
        queries[@"device_id"] = CJString(deviceId);
    } else {
        queries[@"device_id"] = @" ";
    }
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGSize resolution = CGSizeMake(screenBounds.size.width * scale, screenBounds.size.height * scale);
    queries[@"resolution_width"] = @(resolution.width).stringValue;
    queries[@"resolution_height"] = @(resolution.height).stringValue;
    
    queries[@"version_code"] = CJString([UIApplication btd_versionName]);
    
    NSInteger settingsTime = [[NSUserDefaults standardUserDefaults] integerForKey:CJPaySettingsTimeKey];
    if (settingsTime > 0) {
        queries[@"settings_time"] = @(settingsTime);
    }

    return [queries copy];
}

@end

@interface CJPaySettingsManager(PluginSupport)<CJPayRequestParamInjectDataProtocol>

@end

@implementation CJPaySettingsManager(PluginSupport)

CJPAY_REGISTER_PLUGIN({
    [CJPaySettingsManager settingsInit];
    [CJPayRequestParam injectDataProtocol:self];
})

+ (NSDictionary *)injectReskInfoData {
    CJPaySettings *curSettings = [CJPaySettingsManager shared].currentSettings;
    NSString *tpHost = curSettings.cjpayNewCustomHost.integratedHostDomain ?: [CJPayBaseRequest gConfigHost];
    NSString *bdHost = curSettings.cjpayNewCustomHost.bdHostDomain  ?: [CJPayBaseRequest getGBDPayConfigHost];
    if (Check_ValidString(tpHost) && [tpHost hasPrefix:@"http"]) {
        tpHost = [NSString stringWithFormat:@"https://%@", tpHost];
    }
    if (Check_ValidString(bdHost) && [bdHost hasPrefix:@"http"]) {
        bdHost = [NSString stringWithFormat:@"https://%@", bdHost];
    }
    NSDictionary *hostDic = @{@"tppay": CJString(tpHost), @"bdpay": CJString(bdHost)};
    
    return @{@"host": CJString([hostDic cj_toStr])};
}

+ (NSDictionary *)injectDevInfoData {
    return @{};
}

@end

@implementation CJPaySettingsManager(QuickReadValue)

+ (BOOL)boolValueForKeyPath:(NSString *)keyPath {
    NSDictionary *dict = [CJPaySettingsManager shared].settingsDict;
    if (dict && [dict valueForKeyPath:keyPath]) {
        id value = [dict valueForKeyPath:keyPath];
        if (value && [value isKindOfClass:[NSString class]]) {
            return [(NSString *)value boolValue];
        }
        return (value && [value isKindOfClass:[NSNumber class]]) ? [value boolValue] : false;
    }
    return false;
}

+ (NSString *)stringValueForKeyPath:(NSString *)keyPath {
    NSDictionary *dict = [CJPaySettingsManager shared].settingsDict;
    if (dict && [dict valueForKeyPath:keyPath]) {
        id value = [dict valueForKeyPath:keyPath];
        if (value && [value isKindOfClass:[NSString class]]) {
            return (NSString *)value;
        }
        return @"";
    }
    return @"";
}

+ (int)intValueForKeyPath:(NSString *)keyPath {
    NSDictionary *dict = [CJPaySettingsManager shared].settingsDict;
    if (dict && [dict valueForKeyPath:keyPath]) {
        id value = [dict valueForKeyPath:keyPath];
        if (value && [value isKindOfClass:[NSString class]]) {
            return [(NSString *)value intValue];
        }
        return (value && [value isKindOfClass:[NSNumber class]]) ? [value intValue] : -1;
    }
    return -1;
}

@end
