//
//  CJPayRequestParam.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/20.
//

#import "CJPayRequestParam.h"
#import <TTReachability/TTReachability+Network.h>
#import <TTReachability/TTReachability+Conveniences.h>
#import <sys/utsname.h>
#import "CJSDKParamConfig.h"
#import "CJPaySDKMacro.h"
#import <ByteDanceKit/UIApplication+BTDAdditions.h>
#import "CJPayBaseRequest+BDPay.h"
#import "CJPaySecService.h"
#import "CJPaySaasSceneUtil.h"

static CJPayAppInfoConfig *g_appInfoConfig;

@implementation CJPayRequestParam

+ (NSHashTable *)curContextInjectedDataProtocols {
    static NSHashTable *hashTable;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hashTable = [NSHashTable weakObjectsHashTable];
    });
    return hashTable;
}

+ (void)injectDataProtocol:(Class<CJPayRequestParamInjectDataProtocol>)protocol {
    NSHashTable *table = [self curContextInjectedDataProtocols];
    if (![table containsObject:protocol]) {
        [table addObject:protocol];
    }
}

+ (NSDictionary *)commonDeviceInfoDic {
    __block NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (!Check_ValidString((CJPayAppName))) {
        CJPayLogAssert(NO, @"Please configure AppName in CJPayBizParam, or configure bundledisplayname in info.plist");
    }
    
    [params cj_setObject:@"iOS" forKey:@"os"];
    [params cj_setObject:@"false" forKey:@"is_h5"];
    [params cj_setObject:[CJSDKParamConfig defaultConfig].settingsVersion forKey:@"cj_sdk_version"];
    // 业务方的did
    if (g_appInfoConfig) {
        if (g_appInfoConfig.deviceIDBlock) {
            [params cj_setObject:g_appInfoConfig.deviceIDBlock() forKey:@"device_id"];
        }
        [params cj_setObject:g_appInfoConfig.appId forKey:@"aid"];
    }
    NSString *uaInfo = [self uaInfoString:CJPayAppName];
    [params cj_setObject:CJString(uaInfo)  forKey:@"ua"];
    NSString *language = ([CJPayLocalizedUtil getCurrentLanguage] == CJPayLocalizationLanguageEn) ? @"en" : @"zh-Hans";
    [params cj_setObject:CJString(language) forKey:@"lang"];
    [params cj_setObject:CJString([self sysVersion]) forKey:@"os_version"];
    [params cj_setObject:@"Apple" forKey:@"vendor"];
    [params cj_setObject:CJString([self deviceType]) forKey:@"model"];
    [params cj_setObject:CJString([TTReachability currentConnectionMethodName].lowercaseString) forKey:@"net_type"];
    [params cj_setObject:CJString([self appVersion]) forKey:@"app_version"];
    [params cj_setObject:CJPayAppName forKey:@"app_name"];
    [params cj_setObject:CJString([UIApplication btd_bundleVersion]) forKey:@"app_update_version"];
    
    [[[self curContextInjectedDataProtocols] allObjects] enumerateObjectsUsingBlock:^(Class<CJPayRequestParamInjectDataProtocol> protocolImp, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *devInfo = [protocolImp injectDevInfoData];
        [params addEntriesFromDictionary:devInfo];
    }];
    
    return [params copy];
}

+ (NSString *)uaInfoString:(NSString *)appName {
    
//    sdk名称 - 版本号 - 操作系统类型 - 接入方app名称 - 手机型号(屏幕高度_屏幕宽度_版本信息）
//                                           ua示例：
    CJSDKParamConfig *config = [CJSDKParamConfig defaultConfig];
    
    //获取SDK名称
    NSString *sdkName = config.sdkName;
    NSString *version = config.version;
    NSString *systemName = @"iOS";
    NSString *systemVersion = CJString([self sysVersion]);
    NSString *iphoneInfo = [NSString stringWithFormat:@"%@_%@_%@",@(CJ_SCREEN_HEIGHT),@(CJ_SCREEN_WIDTH),CJString(systemVersion) ];
    
    return [NSString stringWithFormat:@"%@-%@-%@-%@-%@",CJString(sdkName),CJString(version),
            CJString(systemName),CJString(appName),CJString(iphoneInfo)];
}

+ (NSString *)ipString {
    NSString *string = AS([[[TTReachability currentIPAddresses] allValues] firstObject], NSString);//cbc
    return CJString(string);
}


+ (NSDictionary *)riskInfoDict {
    
    CJSDKParamConfig *config = [CJSDKParamConfig defaultConfig];
    
    __block NSMutableDictionary *params = [NSMutableDictionary dictionary];
    //收银台类型 2代表iOS
    [params cj_setObject:@"2" forKey:@"platform"];
    //设备操作平台 iPhone或者ipad
    [params cj_setObject:CJString([self devicePlatform]) forKey:@"device_platform"];
    //设备类型
    [params cj_setObject:CJString([self deviceType]) forKey:@"device_type"];
    //设备id 公司install服务统一生成的宿主的设备id
    if (g_appInfoConfig.deviceIDBlock) {
        [params cj_setObject:g_appInfoConfig.deviceIDBlock() forKey:@"did"];
        [params cj_setObject:g_appInfoConfig.deviceIDBlock() forKey:@"device_id"];
    } else {
        [params cj_setObject:@" " forKey:@"did"];
        [params cj_setObject:@" " forKey:@"device_id"];
    }
    //appid 公司统一分配的宿主的appid
    [params cj_setObject:CJString(g_appInfoConfig.appId) forKey:@"aid"];
    //系统的API版本
    [params cj_setObject:CJString([[UIDevice currentDevice] systemVersion]) forKey:@"os_api"];
    //安装渠道，从宿主获取
    [params cj_setObject:CJString([UIApplication btd_currentChannel]) forKey:@"channel"];
    //系统版本
    [params cj_setObject:CJString([self sysVersion]) forKey:@"os_version"];
    //网络类型 5g, 4g, 3g, 2g, mobile, wifi
    [params cj_setObject:CJString([TTReachability currentConnectionMethodName].lowercaseString) forKey:@"ac"];
    //手机品牌
    [params cj_setObject:@"Apple" forKey:@"device_brand"];
    [params cj_setObject:@"Apple" forKey:@"brand"];
    //sdk版本号
    [params cj_setObject:config.version forKey:@"sdk_version"];
    //端版本号
    [params cj_setObject:CJString([self appVersion]) forKey:@"version_code"];
    //收银台的app_name
    [params cj_setObject:CJPayAppName forKey:@"app_name"];
    //分辨率
    NSString *resolutionStr = [NSString stringWithFormat:@"%@*%@",@(CJ_SCREEN_HEIGHT),@(CJ_SCREEN_WIDTH)];
    [params cj_setObject:resolutionStr forKey:@"resolution"];
    
    [[[self curContextInjectedDataProtocols] allObjects] enumerateObjectsUsingBlock:^(Class<CJPayRequestParamInjectDataProtocol> protocolImp, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *reskInfo = [protocolImp injectReskInfoData];
        [params addEntriesFromDictionary:reskInfo];
    }];
    NSMutableDictionary *hostDic = [NSMutableDictionary new];
    [hostDic cj_setObject:[CJPayBaseRequest getGBDPayConfigHost] forKey:@"ulpay"];
    [hostDic cj_setObject:[CJPayBaseRequest gConfigHost] forKey:@"tppay"];
    
    [params cj_setObject:[CJPayCommonUtil dictionaryToJson:hostDic] forKey:@"host"];
    
    // 外面传的风控参数优先级更高一些 TODO:// 废弃掉CJPayBizParams
    if ([CJPayBizParam shared].riskInfoBlock) {
        NSDictionary *bizCustomRiskInfo = [CJPayBizParam shared].riskInfoBlock();
        if (bizCustomRiskInfo != nil && bizCustomRiskInfo.count > 0) {
            [params addEntriesFromDictionary:bizCustomRiskInfo];
        }
    }
    
    return params;
}

+ (NSDictionary *)riskInfoDictWithFinanceRiskWithPath:(NSString *)path {
    NSMutableDictionary *riskInfo = [[self riskInfoDict] mutableCopy];
    NSDictionary *secDict = [self getFinanceRisk:path];
    [riskInfo addEntriesFromDictionary:secDict];
    return riskInfo.copy;
}

+ (NSDictionary *)getFinanceRisk:(NSString *)path {
    id<CJPaySecService> secImpl = CJ_OBJECT_WITH_PROTOCOL(CJPaySecService);
    NSDictionary *secDict = @{};
    if (secImpl && [secImpl respondsToSelector:@selector(buildSafeInfo:context:)]) {
        secDict = [secImpl buildSafeInfo:@{} context:@{
            @"path" : CJString(path)
        }];
    }
    return secDict;
}

//计算 下单接口 签名
+ (NSString *)calcuBDCreateOrderSign:(NSDictionary *)dataDict appSecret:(NSString *)appSecret {
    
    if (!Check_ValidString(appSecret)) {
        return @"";
    }
    
    //排序
    NSArray *signKeys = @[@"app_id",@"sign_type",@"trade_no",@"out_order_no",@"merchant_id",@"uid",@"product_code",@"trade_time",@"payment_type",@"timestamp",@"total_amount",@"trade_type",@"limit_pay",@"exts", @"version",@"valid_time",@"currency",@"subject",@"body",@"notify_url"];
    return [self calcuSign:dataDict signKeys:signKeys appSecret:appSecret];
}

//计算 下单接口 签名
+ (NSString *)calcuCreateOrderSign:(NSDictionary *)dataDict appSecret:(NSString *)appSecret {
    
    if (!Check_ValidString(appSecret)) {
        return @"";
    }
    
    //排序
    NSArray *signKeys = @[@"app_id",@"sign_type",@"trade_no",@"out_order_no",@"merchant_id",@"uid",@"product_code",@"payment_type",@"timestamp",@"total_amount",@"trade_type",@"limit_pay",@"exts"];
    return [self calcuSign:dataDict signKeys:signKeys appSecret:appSecret];
}

+ (NSString *)calcuIAPSign:(NSDictionary *)dataDic appSecret:(NSString *)appSecret {
    if (!Check_ValidString(appSecret)) {
        return @"";
    }
    //排序
    NSArray *signKeys = @[@"app_id",@"sign_type",@"uid",@"out_subscribe_id",@"this_term_start",@"this_term_end",@"subscribe_start",@"subscribe_end",@"subscribe_period_no",@"subscribe_cycle",@"cycle_unit",@"subscribe_type",@"out_order_no",@"merchant_id",@"product_code",@"payment_type",@"trade_time",@"total_amount",@"trade_type",@"body", @"valid_time", @"currency", @"notify_url",@"exts", @"product_id", @"subject", @"real_amount", @"version", @"trade_no", @"product_use_cache_enable"];
    return [self calcuSign:dataDic signKeys:signKeys appSecret:appSecret];
}

//计算预下单签名
+ (NSString *)calcuPreCreateOrderSign:(NSDictionary *)dataDict appSecret:(NSString *)appSecret {
    
    //排序
    NSArray *signKeys = @[@"app_id",@"method",@"format",@"charset",@"sign_type",@"timestamp",@"version",@"biz_content"];
    return [self calcuSign:dataDict signKeys:signKeys appSecret:appSecret];
}

+ (NSString *)calcuSign:(NSDictionary *)dataDict
               signKeys:(NSArray *)signKeys
              appSecret:(NSString *)appSecret {
    
    if (!Check_ValidString(appSecret) || signKeys == nil || signKeys.count == 0
        || dataDict == nil || dataDict.count == 0) {
        return @"";
    }
    
    //对数组进行排序
    NSArray *sortSignKeys = [signKeys sortedArrayUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
        return [obj1 compare:obj2]; //升序
    }];
    
    NSMutableArray *signContentArray = [NSMutableArray array];
    for (NSInteger i = 0; i < sortSignKeys.count; i++) {
        NSString *key = sortSignKeys[i];
        id value = [dataDict objectForKey:key];
        if (value != nil) {
            NSString *tempString = @"";
            if (IS(value, NSString)) {
                //字符串处理
                NSString *str = AS(value, NSString);
                if (Check_ValidString(str)) {
                    tempString = [NSString stringWithFormat:@"%@=%@",key,str];
                }
            } else {
                tempString = [NSString stringWithFormat:@"%@=%@",key,value];
            }
            
            if (Check_ValidString(tempString)) {
                [signContentArray addObject:tempString];
            }
        }
    }
    
    NSMutableString *originString = [[signContentArray componentsJoinedByString:@"&"] mutableCopy];
    [originString appendFormat:@"%@",appSecret];
    NSString *signString = [originString cj_md5String];
    return CJString(signString);
}

+ (NSString *)appVersion {
    NSString *appVer = [[[NSBundle mainBundle]infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    return appVer;
}

+ (NSString *)appName {
    NSString *name = [[[NSBundle mainBundle]infoDictionary] objectForKey:@"CFBundleDisplayName"];
    return name;
}

+ (NSString *)deviceID {
    NSString *deviceUUID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    return deviceUUID;
}

+ (NSString *)accessToken {
    if (g_appInfoConfig.accessTokenBlock) {
        return g_appInfoConfig.accessTokenBlock();
    }
    return nil;
}

+ (NSString *)sysVersion {
    NSString *systemVersion = [UIDevice currentDevice].systemVersion;
    return systemVersion;
}

+ (NSString *)devicePlatform {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    if ([deviceString hasPrefix:@"iPad"]) {
        return @"ipad";
    } else {
        return @"iphone";
    }
}

+ (NSString *)deviceType {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    return deviceString;
}

+ (NSDictionary *)getRiskInfoParams {
    return [self getRiskInfoParamsWith:@{}];
}

+ (NSDictionary *)getRiskInfoParamsWith:(NSDictionary *)extParams {
    NSMutableDictionary *mutableDic = [[CJPayRequestParam riskInfoDict] mutableCopy];
    [mutableDic addEntriesFromDictionary:extParams];
    NSDictionary *riskDict = [NSDictionary dictionaryWithObject:[mutableDic copy] forKey:@"risk_str"];
    return riskDict;
}

+ (NSDictionary *)getMergeRiskInfoWithBizParams:(NSDictionary *)bizContentParams {
    NSDictionary *riskDict = [NSDictionary dictionaryWithObject:[self riskInfoDict] forKey:@"risk_str"];
    NSDictionary *hasRiskInfoDic = [bizContentParams cj_dictionaryValueForKey:@"risk_info"];
    if (hasRiskInfoDic && hasRiskInfoDic.count > 0) {
        NSMutableDictionary *mutableRiskInfo = [NSMutableDictionary dictionary];
        [mutableRiskInfo addEntriesFromDictionary:hasRiskInfoDic];
        [mutableRiskInfo addEntriesFromDictionary:riskDict];
        return [mutableRiskInfo copy];
    } else {
        return [riskDict copy];
    }
}

// 标识是否是SaaS链路
+ (BOOL)isSaasEnv {
    if (!g_appInfoConfig.enableSaasEnv) {
        return NO;
    }
    NSString *saasScene = [CJPaySaasSceneUtil getCurrentSaasSceneValue];
    NSString *accessToken = [self accessToken];
    if (Check_ValidString(saasScene) && !Check_ValidString(accessToken)) {
        CJPayLogError(@"SaaS环境下未取到accessToken，Saas_Scene=%@", saasScene);
    }
    return Check_ValidString(saasScene) && Check_ValidString(accessToken);
}

+ (void)setAppInfoConfig:(CJPayAppInfoConfig *)appInfo {
    g_appInfoConfig = appInfo;
}

+ (CJPayAppInfoConfig *)gAppInfoConfig {
    return g_appInfoConfig;
}

@end
