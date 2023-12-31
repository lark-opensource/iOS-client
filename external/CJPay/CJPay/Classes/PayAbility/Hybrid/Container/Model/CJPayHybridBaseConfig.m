//
//  CJPayLynxBaseUIConfig.m
//  Aweme
//
//  Created by wangxiao on 2023/1/12.
//

#import "CJPayHybridBaseConfig.h"
#import "CJPaySDKMacro.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayABTestManager.h"
#import <HybridKit/HybridContext.h>
#import <HybridKit/HybridSchemaParam.h>
#import "UIColor+CJPay.h"
#import "CJPayRequestParam.h"
#import "CJPayGurdManager.h"
#import <WebKit/WebKit.h>

@interface CJPayHybridBaseConfig()
@property (nonatomic, assign) BOOL useForest;
@end

@implementation CJPayHybridBaseConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        // 设置默认样式
        [self p_setDefaultUIConfig];
    }
    return self;
}

- (void)p_setDefaultUIConfig {
    self.openAnimate = YES;
}

- (NSString *)p_toHybridScheme {
    
    if (!Check_ValidString(self.scheme)) {
        CJPayLogInfo(@"scheme不合法%@", self);
        return self.scheme;
    }
    
    NSString *cjScheme = CJString(self.scheme);
    
    if ([cjScheme hasPrefix:@"aweme"]) {
        cjScheme = [cjScheme stringByReplacingOccurrencesOfString:@"aweme://"
                                                       withString:@"sslocal://"];
    }
    
    if ([cjScheme hasPrefix:@"sslocal://cjpay/lynxview"] || [cjScheme hasPrefix:@"sslocal://cjpay/webview"]) {
        return [cjScheme stringByReplacingOccurrencesOfString:@"sslocal://cjpay/"
                                                            withString:@"sslocal://"];
    } else if ([cjScheme hasPrefix:@"sslocal://cjpay?"]){
        return [cjScheme stringByReplacingOccurrencesOfString:@"sslocal://cjpay?"
                                                   withString:@"sslocal://webview?"];//兼容老逻辑，不传path一律当成webview
    } else {
        return cjScheme;
    }
}

- (NSDictionary *)initialParams {
    NSString *sdkVersion = [CJSDKParamConfig defaultConfig].version;

    NSDictionary *settingsDic = [CJPaySettingsManager shared].settingsDict;

    NSMutableDictionary *settingsParams = [NSMutableDictionary new];
    NSArray *cjSettingsKeys = [self.cjSettingsKeys componentsSeparatedByString:@","];
    [cjSettingsKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (Check_ValidString(obj)) {
            id value = [settingsDic cj_objectForKey:obj];
            [settingsParams cj_setObject:value forKey:obj];
        }
    }];

    NSMutableDictionary *abtestParams = [NSMutableDictionary new];
    NSArray *abtestKeys = [self.cjAbtestKeys componentsSeparatedByString:@","];
    [abtestKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (Check_ValidString(obj)) {
            NSString *abValue = [CJPayABTest getABTestValWithKey:obj exposure:NO];
            [abtestParams cj_setObject:CJString(abValue) forKey:obj];
        }
    }];

    CJPayAppInfoConfig *infoConfig = [CJPayRequestParam gAppInfoConfig];
        
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:@{
        @"cj_sdk_version" : CJString(sdkVersion),
        @"cj_settings_values" : settingsParams,
        @"cj_abtest_values" : abtestParams,
        @"user_id" : infoConfig.userIDBlock()?CJString(infoConfig.userIDBlock()) : @"",
        @"device_id" : infoConfig.deviceIDBlock()?CJString(infoConfig.deviceIDBlock ()) : @"",
        @"app_id" : CJString(infoConfig.appId),
        @"app_name" : CJString(infoConfig.appName),
        @"app_version" : CJString([UIApplication btd_versionName]),
        @"containerInitTime" : @(CFAbsoluteTimeGetCurrent()).stringValue
    }];
    [params addEntriesFromDictionary:_initialParams];

    NSDictionary *queryItems = [[self p_toHybridScheme] cj_urlQueryParams] ?:@{};
    [params cj_setObject:queryItems forKey:@"query_items"];
    return @{@"cj_initial_props" : params};
}

- (HybridEngineType)enginetype {
    NSString *cjScheme = [self p_toHybridScheme];
    
    if ([cjScheme hasPrefix:@"sslocal://lynxview?"]) {
        return HybridEngineTypeLynx;
    } else if([cjScheme hasPrefix:@"sslocal://webview?"]) {
        return HybridEngineTypeWeb;
    } else {
        return HybridEngineTypeUnknown;
    }
}

- (HybridContext *)toContext {
    HybridContext *context = [[HybridContext alloc] init];
    NSString *hybridSchema =  [self p_toHybridScheme];
    CJPayContainerConfig *containerConfig = [CJPaySettingsManager shared].localSettings.containerConfig;
    if ([self enginetype] == HybridEngineTypeWeb && !containerConfig.enableHybridkitUA) {
        hybridSchema = [CJPayCommonUtil appendParamsToUrl:hybridSchema
                                                   params:@{@"use_systemUA": @"1"}];
    }
    if (self.WKDelegate && [self.WKDelegate conformsToProtocol:@protocol(WKNavigationDelegate)]) {
        context.webviewNavigationDelegate = self.WKDelegate;
    }
    
    context.originURL = hybridSchema;
    context.globalProps = self.initialParams;
    context.bid = @"cjpay_webview";
    
    return context;
}


- (NSString *)secLinkScene {
    if (!Check_ValidString(_secLinkScene) && [CJPayRequestParam gAppInfoConfig].transferSecLinkSceneBlock) {
        return [CJPayRequestParam gAppInfoConfig].transferSecLinkSceneBlock([self.scheme cj_urlQueryParams]);
    }
    return _secLinkScene;
}

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"openAnimate" : @"open_animate",
        @"cjSettingsKeys" : @"cj_settings_keys",
        @"cjAbtestKeys" : @"cj_abtest_keys",
        @"useForest" : @"use_forest",
        @"openMethod" : @"open_method"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

+ (BOOL)propertyIsIgnored:(NSString *)propertyName {
    if ([propertyName isEqualToString:@"WKDelegate"]) {
        return YES;
    }
    return NO;
}


@end
