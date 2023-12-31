//
//  BDImageManagerConfig.m
//  BDWebImageToB
//
//  Created by 陈奕 on 2020/6/17.
//

#import "BDImageManagerConfig.h"
#import "BDImageConfigUtil.h"
#import "BDImageConfigConstants.h"
#if __has_include("BDBaseToB.h")
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTNetworkManager/TTHTTPBinaryResponseSerializerBase.h>
#import "NSString+BDDSword.h"
#endif

static const NSInteger kBDImageStatusServiceCode = 200;  // 服务器请求成功代码
static const NSUInteger kBDImageSettingDefaultFetchInterval = 3600;
static const NSUInteger kBDImageAuthCodesDefaultFetchInterval = 24 * 3600; // 默认一天拉取一次授权码
static const NSUInteger kBDImagePermanentValidPeriod = 7258089600;  // endTime为2200.01.01 00:00:00时永久有效

@interface BDImageManagerConfig ()

@property (atomic, assign) NSInteger fetchInterval;
@property (nonatomic, strong) dispatch_source_t fetchTimer;
@property (atomic, assign) BOOL isAuthcodesFormWeb;
@property (nonatomic, strong) NSArray *webAuthCodes;

@property (nonatomic, strong) NSDictionary *settingDict;
@property (nonatomic, strong) NSDictionary *authCodesDict;
@property (nonatomic, assign) NSTimeInterval authCodesServerTime;

@end

@implementation BDImageManagerConfig

+ (BDImageManagerConfig *)sharedInstance {
    static BDImageManagerConfig *config = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken,^{
        config = [BDImageManagerConfig new];
    });
    
    return config;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        BOOL stored = [[NSUserDefaults standardUserDefaults] boolForKey:kBDImageSettingsStoredKey];
        if (stored) {
            NSInteger fetchInterval = [[NSUserDefaults standardUserDefaults] integerForKey:kBDImageSettingFetchIntervalKey];
            self.fetchInterval = fetchInterval > kBDImageSettingDefaultFetchInterval ? fetchInterval : kBDImageSettingDefaultFetchInterval;
            self.monitorRate = [[NSUserDefaults standardUserDefaults] integerForKey:kBDImageMonitorRateKey];
            self.errorMonitorRate = [[NSUserDefaults standardUserDefaults] integerForKey:kBDImageErrorMonitorRateKey];
        } else {
            self.fetchInterval = kBDImageSettingDefaultFetchInterval;
            self.monitorRate = 100;
            self.errorMonitorRate = 100;
        }
        self.webAuthCodes = (NSArray *)[[NSUserDefaults standardUserDefaults] objectForKey:kBDImageSettingsAuthCodeKey];
        self.authCodesServerTime = [[NSUserDefaults standardUserDefaults] doubleForKey:kBDImageSettingsServerTimeKey];
        self.isAuthcodesFormWeb = NO;
        self.addedComponents = [NSArray array];
        self.staticAdpativePolicies = [NSArray array];
        self.animatedAdpativePolicies = [NSArray array];
        self.verifyErr = [NSDictionary dictionary];
        self.TTNetDataDic = [[NSUserDefaults standardUserDefaults] valueForKey:kBDImageData];
        self.enabledSR = [[NSUserDefaults standardUserDefaults] boolForKey:kBDImageTTNetEnabledSR];
        self.enabledHttpDNS = [[NSUserDefaults standardUserDefaults] boolForKey:kBDImageTTNetEnabledHttpDNS];
        self.enabledH2 = [[NSUserDefaults standardUserDefaults] boolForKey:kBDImageTTNetEnabledH2];
        self.httpDNSAuthId = [[NSUserDefaults standardUserDefaults] objectForKey:kBDImageHttpDNSAuthId];
        self.httpDNSAuthKey = [[NSUserDefaults standardUserDefaults] objectForKey:kBDImageHttpDNSAuthKey];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(startTTNetNotification)
                                                     name:kBDImageFetchConfigSuccess
                                                   object:nil];
    }
    return self;
}

- (NSString *)settingStr
{
    return [self.settingDict description];
}

- (NSString *)authCodesStr
{
    NSArray *authCodes = [self.authCodesDict objectForKey:kBDImageAuthCode];
    NSMutableArray *authCodeDicts = [NSMutableArray array];
    for (NSString *authCode in authCodes) {
        NSDictionary *authCodeDict = [BDImageConfigUtil decodeWithBase64Str:authCode];
        NSMutableDictionary *mutDict = [authCodeDict mutableCopy];
        [mutDict removeObjectForKey:kBDImageSignature];
        [authCodeDicts addObject:mutDict];
    }
    NSMutableDictionary *newDict = [self.authCodesDict mutableCopy];
    [newDict setObject:authCodeDicts forKey:kBDImageAuthCode];
    return [newDict description];
}
    
- (void)startFetchConfig
{
    NSString *appID = self.startUpConfig.appID;
    NSCAssert(appID.length > 0, @"appID is empty!");
    if (self.webAuthCodes.count > 0) {
        [self updateAddOnComponentsWithAuthCodes:self.webAuthCodes fromWeb:YES];
    } else {
        [self updateAddOnComponentsWithAuthCodes:self.startUpConfig.authCodes fromWeb:NO];
    }
    
    // 拉取配置
    [self startFetchConfigReal];
    
#if __has_include("BDBaseToB.h")
    // 开启ttnet服务
    [self startTTNetService];

    CFTimeInterval time = [[NSDate date] timeIntervalSince1970];
    // 拉取授权码：如果是手机重启或者是卸载重装，那么就会重新拉配置，超过默认间隔也会重新拉配置
    if (time - self.authCodesServerTime > kBDImageAuthCodesDefaultFetchInterval) {
        [self startFetchAuthcodesReal];
    }
#endif
    
    __weak typeof(self) weakSelf = self;
    [self scheduledDispatchTimerWithInterval:self.fetchInterval queue:dispatch_get_main_queue() action:^{
        [weakSelf startFetchConfigReal];
    }];
}

#pragma mark AuthCode

- (void)updateAddOnComponentsWithAuthCodes:(NSArray *)authCodes fromWeb:(BOOL)isFromWeb
{
    NSMutableArray *addOnComponents = [NSMutableArray array];
    for (NSString *authCode in authCodes) {
        if ([authCode isKindOfClass:[NSString class]] && authCode.length > 0) {
            NSString *component = [self verifyAddedComponentsWithAuthCode:authCode];
            if (component != nil) {
                [addOnComponents addObject:[component lowercaseString]];
            }
        }
    }
    if (addOnComponents.count > 0) {
        self.addedComponents = addOnComponents;
    }
    self.isAuthcodesFormWeb = isFromWeb;
}

- (NSString *)verifyAddedComponentsWithAuthCode:(NSString *)authCode
{
    NSData *data = [[NSData alloc] initWithBase64EncodedString:authCode options:0];
    NSString *authCodeStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *authCodeDict = [BDImageConfigUtil decodeWithBase64Str:authCode];
    if (authCodeDict == nil || authCodeStr.length < 1) {
        return nil;
    }
    
    NSString *signature = [authCodeDict objectForKey:kBDImageSignature];
    NSString *suiteID = [authCodeDict objectForKey:kBDImageSuiteID];
    NSString *addOn = [authCodeDict objectForKey:kBDImageAddOn];
    if ([self.addedComponents containsObject:addOn]) {
        return nil;
    }
    
    if (signature == nil || suiteID == nil || addOn == nil) {
        [self updateErr:@"授权码为空" component:addOn];
        return nil;
    }
    
    if (![self verifySignature:authCodeDict authCodeStr:authCodeStr]) {
        [self updateErr:@"授权码校验签名失败" component:addOn];
        return nil;
    }
    if (![self verifyBundleID:authCodeDict]) {
        [self updateErr:@"授权码 BundleID 错误" component:addOn];
        return nil;
    }
    
    if (![self verifyValidPeriod:authCodeDict]) {
        [self updateErr:@"授权码过期" component:addOn];
        return nil;
    }
    
    if (addOn.length > 0) {
        [self updateErr:@"" component:addOn];
        return addOn;
    }
    return nil;
}

- (void)updateErr:(NSString *)err component:(NSString *)component
{
    if (component.length < 1) {
        return;
    }
    NSMutableDictionary *mutDict = [self.verifyErr mutableCopy];
    if (err.length < 1) {
        [mutDict removeObjectForKey:component];
    } else {
        [mutDict setObject:err forKey:component];
    }
    self.verifyErr = mutDict;
}

- (BOOL)verifySignature:(NSDictionary *)authCodeDict authCodeStr:(NSString *)authCodeStr
{
    NSString *signature = [authCodeDict objectForKey:kBDImageSignature];
    NSString *suiteID = [authCodeDict objectForKey:kBDImageSuiteID];
    if (signature == nil || suiteID == nil) {
        return NO;
    }
    NSString *publicKey = kBDImageSignaturePublicKey1;
    if ([suiteID isEqualToString:kBDImageSignaturePublicKey2Id]) {
        publicKey = kBDImageSignaturePublicKey2;
    }
    NSString *signStr = [NSString stringWithFormat:@",\"Signature\":\"%@\"", signature];
    NSString *sourceStr = [authCodeStr stringByReplacingOccurrencesOfString:signStr withString:@""];
    if (sourceStr.length < 1) {
        return NO;
    }
    BOOL success = [BDImageConfigUtil verify:sourceStr signature:signature withPublicKey:publicKey];
    return success;
}

- (BOOL)verifyBundleID:(NSDictionary *)authCodeDict
{
    NSString *bundleID = [authCodeDict objectForKey:kBDImageBundleID];
    NSString *localBundleID = [[NSBundle mainBundle] objectForInfoDictionaryKey:kBDImageCFBundleIdentifier];
    if (bundleID.length < 1 || localBundleID.length < 1 || ![bundleID isEqualToString:localBundleID]) {
        return NO;
    }
    return YES;
}

- (BOOL)verifyValidPeriod:(NSDictionary *)authCodeDict
{
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    NSInteger time = interval;
    NSInteger startTime = ((NSNumber *)[authCodeDict objectForKey:kBDImageStartTime]).integerValue;
    NSInteger endTime = ((NSNumber *)[authCodeDict objectForKey:kBDImageEndTime]).integerValue;
    if (endTime >= kBDImagePermanentValidPeriod){
        return YES;
    }
    if (time < startTime || time > endTime) {
        return NO;
    }
    return YES;
}

#pragma mark Fetch

- (void)startFetchAuthcodesReal
{
    BDImageServiceVendor serviceVendor = self.startUpConfig.serviceVendor;
    NSString *token = self.startUpConfig.token;
    NSString *newURL = [NSString stringWithFormat:@"%@?%@=%@", [self requestAuthcodesURLWithServiceVendor:serviceVendor], @"token", token];
    [BDImageConfigUtil networkAsyncRequestForURL:newURL headers:@{} method:@"GET" queue:nil callback:^(NSError * _Nullable error, NSDictionary * _Nullable jsonObj) {
        if (![jsonObj isKindOfClass:[NSDictionary class]] || jsonObj.count < 1) {
            return;
        }
        self.authCodesDict = [jsonObj copy];
        NSInteger status = ((NSNumber *)[jsonObj objectForKey:kBDImageStatusCode]).integerValue;
        if (status == kBDImageStatusServiceCode) {
            NSArray *authCodes = [jsonObj objectForKey:kBDImageAuthCode];
            NSNumber *serverTime = [jsonObj objectForKey:kBDImageServerTime];
            if (![authCodes isKindOfClass:[NSArray class]] || authCodes.count < 1) {
                [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kBDImageSettingsAuthCodeKey];
                [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kBDImageSettingsServerTimeKey];
                return;
            }
            self.webAuthCodes = authCodes;
            if (!self.isAuthcodesFormWeb) {
                [self updateAddOnComponentsWithAuthCodes:self.webAuthCodes fromWeb:YES];
            }
            [[NSUserDefaults standardUserDefaults] setObject:authCodes forKey:kBDImageSettingsAuthCodeKey];
            [[NSUserDefaults standardUserDefaults] setObject:serverTime forKey:kBDImageSettingsServerTimeKey];
        }
    }];
}

/* {
    data =     {
        "custom_settings" =         {
            "allow_log_type" =             {
                "image_monitor_error_v2" = 1;
                "image_monitor_v2" = 0;
            };
        };
        "general_settings" =         {
            "fetch_settings_interval" = 3600;
        };
    };
    msg = ok;
    "status_code" = 200;
}*/
- (void)startFetchConfigReal
{
    NSString *appID = self.startUpConfig.appID;
    BDImageServiceVendor serviceVendor = self.startUpConfig.serviceVendor;
    NSString *query = [BDImageConfigUtil commonParametersWithAppId:appID];
    NSString *newURL = [NSString stringWithFormat:@"%@?%@", [self requestConfigURLWithServiceVendor:serviceVendor], query];
    [BDImageConfigUtil networkAsyncRequestForURL:newURL headers:[BDImageConfigUtil defalutHeaderFieldWithAppId:appID] method:@"GET" queue:nil callback:^(NSError * _Nullable error, NSDictionary * _Nullable jsonObj) {
        if (![jsonObj isKindOfClass:[NSDictionary class]] || jsonObj.count < 1) {
            return;
        }
        self.settingDict = [jsonObj copy];
        NSInteger status = ((NSNumber *)[jsonObj objectForKey:kBDImageStatusCode]).integerValue;
        NSString *msg = [jsonObj objectForKey:kBDImageMsg];
        if (status == kBDImageStatusServiceCode && [msg isEqualToString:kBDImageOk]) {
            NSDictionary *data = [jsonObj objectForKey:kBDImageData];
            if (![data isKindOfClass:[NSDictionary class]] || data.count < 1) {
                return;
            }
            NSDictionary *customSettings = [data objectForKey:kBDImageCustomSettings];
            if ([customSettings isKindOfClass:[NSDictionary class]] && customSettings.count > 0) {
                NSDictionary *allowLogType = [customSettings objectForKey:kBDImageAllowLogType];
                if ([allowLogType isKindOfClass:[NSDictionary class]] && allowLogType.count > 0) {
                    self.monitorRate = ((NSNumber *)[allowLogType objectForKey:kBDImageLoadMonitor]).floatValue * 100;
                    self.errorMonitorRate = ((NSNumber *)[allowLogType objectForKey:kBDImageLoadErrorMonitor]).floatValue * 100;
                }
                // 下拉ttnet配置
#if __has_include("BDBaseToB.h")
                self.TTNetDataDic = [self setHttpDNSData:customSettings];
                self.enabledSR = [customSettings[kBDImageEnabledSuperResolution] isEqual: @(1)];
#endif
                // 下拉 自适应 配置（暂时只根据静态策略进行适应）
                // 不对自适应配置进行本地化缓存，需要随时更新
                NSDictionary *adaptiveFormats = customSettings[kBDImageAdaptiveFormat];
                if ([adaptiveFormats isKindOfClass:[NSDictionary class]] && adaptiveFormats.count > 0){
                    self.staticAdpativePolicies = adaptiveFormats[kBDImageStaticAdaptivePolicy];
                }
            }
            NSDictionary *generalSettings = [data objectForKey:kBDImageGeneralSettings];
            if ([generalSettings isKindOfClass:[NSDictionary class]] && generalSettings.count > 0) {
                NSInteger interval = ((NSNumber *)[generalSettings objectForKey:kBDImageFetchInterval]).integerValue;
                if (interval >= kBDImageSettingDefaultFetchInterval && interval != self.fetchInterval) {
                    self.fetchInterval = interval;
                    [[NSUserDefaults standardUserDefaults] setInteger:interval forKey:kBDImageSettingFetchIntervalKey];
                    __weak typeof(self) weakSelf = self;
                    [self scheduledDispatchTimerWithInterval:interval queue:dispatch_get_main_queue() action:^{
                        [weakSelf startFetchConfigReal];
                    }];
                }
            }
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kBDImageSettingsStoredKey];
        }
    }];
}

#pragma mark Set and UserDefaults

- (void)setMonitorRate:(NSInteger)monitorRate
{
    _monitorRate = monitorRate;
    [[NSUserDefaults standardUserDefaults] setInteger:monitorRate forKey:kBDImageMonitorRateKey];
}

- (void)setErrorMonitorRate:(NSInteger)errorMonitorRate
{
    _errorMonitorRate = errorMonitorRate;
    [[NSUserDefaults standardUserDefaults] setInteger:errorMonitorRate forKey:kBDImageErrorMonitorRateKey];
}

#if __has_include("BDBaseToB.h")
- (void)setEnabledSR:(BOOL)enabledSR
{
    _enabledSR = enabledSR;
    [[NSUserDefaults standardUserDefaults] setBool:enabledSR forKey:kBDImageTTNetEnabledSR];
}

- (void)setTTNetDataDic:(NSDictionary *)TTNetDataDic
{
    _TTNetDataDic = TTNetDataDic;
    if (self.TTNetDataDic.count > 0) {
        [[NSUserDefaults standardUserDefaults] setValue:TTNetDataDic forKey:kBDImageData];
    }
}

- (void)setEnabledH2:(BOOL)enabledH2
{
    _enabledH2 = enabledH2;
    [[NSUserDefaults standardUserDefaults] setBool:enabledH2 forKey:kBDImageTTNetEnabledH2];
}

- (void)setEnabledHttpDNS:(BOOL)enabledHttpDNS
{
    _enabledHttpDNS = enabledHttpDNS;
    [[NSUserDefaults standardUserDefaults] setBool:enabledHttpDNS forKey:kBDImageTTNetEnabledHttpDNS];
}

- (void)setHttpDNSAuthId:(NSString *)httpDNSAuthId
{
    _httpDNSAuthId = httpDNSAuthId;
    [[NSUserDefaults standardUserDefaults] setObject:httpDNSAuthId forKey:kBDImageHttpDNSAuthId];
}

- (void)setHttpDNSAuthKey:(NSString *)httpDNSAuthKey
{
    _httpDNSAuthKey = httpDNSAuthKey;
    [[NSUserDefaults standardUserDefaults] setObject:httpDNSAuthKey forKey:kBDImageHttpDNSAuthKey];
}

/* 配置httpdns和h2的data */
- (NSDictionary *) setHttpDNSData:(NSDictionary *)customSettings
{
    NSMutableDictionary *TTNetDataMutableDic = [[NSMutableDictionary alloc] init];
    NSDictionary *httpdnsSettings = [customSettings objectForKey:kBDImageHttpDNSSettings];
    NSDictionary *ttnetSettings = [customSettings objectForKey:kBDImageTTNetSettings];
    if (([httpdnsSettings isKindOfClass:[NSDictionary class]] && httpdnsSettings.count > 0) ||
        ([ttnetSettings isKindOfClass:[NSDictionary class]] && ttnetSettings.count > 0)){
        NSMutableDictionary *httpSettings = [[NSMutableDictionary alloc] initWithDictionary:httpdnsSettings];
        [self setEnabledHttpDNS:[httpSettings[kBDImageEnabledHttpDNS] isEqual:@(1)]];
        [self setEnabledH2:[ttnetSettings[kBDImageEnabledH2] isEqual:@(1)]];
        [self setHttpDNSAuthId:(NSString *)[httpSettings objectForKey:kBDImageHttpServiceId]];
        NSString *secretKey = [httpSettings objectForKey:kBDImageHttpSecretkey];
        if (secretKey != nil){
//            NSString *decryptSecretKey = secretKey;
            NSString *decryptSecretKey = [secretKey bd_unpackedData];
            if (decryptSecretKey != nil){       // 成功解密
                decryptSecretKey = [decryptSecretKey stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                [httpSettings setObject:decryptSecretKey forKey:kBDImageHttpSecretkey];
                [self setHttpDNSAuthKey:decryptSecretKey];
            }
        }
        [httpSettings addEntriesFromDictionary:ttnetSettings];
        [TTNetDataMutableDic setValue:httpSettings forKey:kBDImageData];
    }
    // 发送拉取配置的通知，告知 TTNet / HttpDNS 当前可以开启对应的服务了
    [[NSNotificationCenter defaultCenter] postNotificationName:kBDImageFetchConfigSuccess object:self];
    return TTNetDataMutableDic;
}

#pragma mark TTNet

- (void)startTTNetNotification
{
    if (self.enabledHttpDNS){
        [self startHTTPDNSService];
#ifdef DEBUG
        NSLog(@"[BDWebImageToB] open HttpDNS");
#endif
    }
}

/* 开启ttnet服务 : 第一次启动无法使用 h2 服务
    ttnet 默认开启，h2 需要相关配置才会开启
    httpdns 的开启也需要先开启 ttnet 才能生效
 */
- (void)startTTNetService
{
    [[TTNetworkManager shareInstance] setDefaultBinaryResponseSerializerClass:[TTHTTPBinaryResponseSerializerBase class]];
//    [TTNetworkManager setLibraryImpl:TTNetworkManagerImplTypeLibChromium];
    [[TTNetworkManager shareInstance] setCommonParamsblock:^NSDictionary<NSString *,NSString *> *{
        return [NSMutableDictionary dictionary];
    }];
    [TTNetworkManager setMonitorBlock:^(NSDictionary* data, NSString* logType) {
        NSLog(@"json: %@, log type: %@", data, logType);
    }];
    
    [TTNetworkManager shareInstance].DomainHttpDns = @"xxx.xxx";
    [TTNetworkManager shareInstance].DomainNetlog = @"xxx.xxx";
    [TTNetworkManager shareInstance].DomainBoe = @"xxx.xxx";
    
#ifdef DEBUG
    [[TTNetworkManager shareInstance] enableVerboseLog];
#endif
    
    // 本地配置授权码时能立即开启TTNet服务
    if(self.TTNetDataDic == nil){
        [[TTNetworkManager shareInstance] start];
        return ;
    }
    
    NSData *TTNetData = [NSJSONSerialization dataWithJSONObject:self.TTNetDataDic options:0 error:0];
    NSString *TTNetDataString = [[NSString alloc] initWithData:TTNetData encoding:NSUTF8StringEncoding];
    [[TTNetworkManager shareInstance] setGetDomainDefaultJSON:self.enabledH2 ? TTNetDataString : nil];
    [[TTNetworkManager shareInstance] start];
}

/*
   开启httpdns服务
   httpdns依赖与TTNet，因此需要先开启TTNet才能使用
 */
- (BOOL)startHTTPDNSService
{
    // 用于请求服务端通过httpdns解析ip，将第一个参数设置为NO将关闭服务
    // 返回值为 YES 时，表示 cronet 初始化完成
    return [[TTNetworkManager shareInstance] enableTTBizHttpDns:self.enabledHttpDNS
                                                         domain:kBDImageDomainHttpDNS
                                                         authId:self.httpDNSAuthId
                                                        authKey:self.httpDNSAuthKey
                                                        tempKey:NO
                                               tempKeyTimestamp:nil];
}
#endif

#pragma mark Utils

- (void)scheduledDispatchTimerWithInterval:(NSTimeInterval)interval
                                 queue:(dispatch_queue_t)queue
                                action:(dispatch_block_t)action
{
    if (interval < 0.0001f) return;
    if (!action) return;
    if (!queue) queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    if (!self.fetchTimer) {
        self.fetchTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        dispatch_resume(self.fetchTimer);
    }
    
    /* timer精度为1毫秒 */
    dispatch_source_set_timer(self.fetchTimer, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), interval * NSEC_PER_SEC, NSEC_PER_MSEC);
    dispatch_source_set_event_handler(self.fetchTimer, ^{
        if (action) {
            action();
        }
    });
}

- (NSString *)requestConfigURLWithServiceVendor:(BDImageServiceVendor)vendor
{
    if (self.startUpConfig.isInBoe) {
        return @"http://imagex-settings-boe.byted.org/app/monitor/settings";
    }
    switch (vendor) {
        case BDImageServiceVendorCN:
            return @"https://imagex-settings.bytedanceapi.com/app/monitor/settings";
        case BDImageServiceVendorSG:
            return @"https://imagex-settings-sg.bytedanceapi.com/app/monitor/settings";
        case BDImageServiceVendorVA:
            return @"https://imagex-settings-va.bytedanceapi.com/app/monitor/settings";
        default:
            break;
    }
    NSCAssert(0, @"vendor is not in the list");
    return @"https://imagex-settings.bytedanceapi.com/app/monitor/settings";
}

- (NSString *)requestAuthcodesURLWithServiceVendor:(BDImageServiceVendor)vendor
{
    if (self.startUpConfig.isInBoe) {
        return @"http://imagex-settings-boe.byted.org/app/monitor/authcodes";
    }
    switch (vendor) {
        case BDImageServiceVendorCN:
            return @"https://imagex-settings.bytedanceapi.com/app/monitor/authcodes";
        case BDImageServiceVendorSG:
            return @"https://imagex-settings-sg.bytedanceapi.com/app/monitor/authcodes";
        case BDImageServiceVendorVA:
            return @"https://imagex-settings-va.bytedanceapi.com/app/monitor/authcodes";
        default:
            break;
    }
    NSCAssert(0, @"vendor is not in the list");
    return @"https://imagex-settings.bytedanceapi.com/app/monitor/authcodes";
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kBDImageFetchConfigSuccess
                                                  object:nil];
}

@end
