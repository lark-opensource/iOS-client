//
//  CJPayBizParam.m
//  CJPay
//
//  Created by 王新华 on 2019/5/5.
//

#import "CJPayBizParam.h"
#import "CJPayRequestParam.h"
#import "CJPaySDKMacro.h"
#import "CJPayBaseRequest.h"
#import "CJPayProtocolManager.h"
#import <Gaia/Gaia.h>

@interface CJPayBizParam()

@property (nonatomic, copy, readwrite) CJPayConfigBlock riskInfoBlock;

@end

@implementation CJPayBizParam

+ (instancetype)shared {
    static CJPayBizParam *share;
    if (!share) {
        [GAIAEngine startTasksForKey:@CJPayGaiaRegisterComponentKey];
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        share = [[CJPayBizParam alloc] init];
    });
    return share;
}

- (NSString *)appName {
    return _appName ?: @"";
}

- (void)setupLanguage:(CJPayLocalizationLanguage)language {
    [CJPayLocalizedUtil changeToCustomAppLanguage:language];
}

- (void)setConfigHost:(NSString *)configHost {
    [CJPayBaseRequest setGConfigHost:configHost];
}

- (NSString *)configHost{
    return [CJPayBaseRequest gConfigHost];
}


- (void)setupRiskInfoBlock:(CJPayConfigBlock)riskInfoBlock {
    self.riskInfoBlock = riskInfoBlock;
    NSMutableDictionary *trackParams = [NSMutableDictionary new];
    if (self.riskInfoBlock) {
        NSDictionary *dic = self.riskInfoBlock();
        [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [trackParams cj_setObject:obj forKey:key];
        }];
    }
    [CJTracker event:@"wallet_config_riskinfo" params:[trackParams copy]];
}

- (void)setupCookieWith:(nullable CJPayConfigBlock)cookieBlock {
    [CJPayCookieUtil sharedUtil].cookieBlock = [cookieBlock copy];
}

- (void)cleanCookies {
    [[CJPayCookieUtil sharedUtil] cleanCookies];
}

- (void)setupTrackerDelegate: (id<CJPayManagerBizDelegate>) trackerDelegate {
    [CJPayTracker shared].trackerDelegate = trackerDelegate;
}

- (void)setupAppInfoConfig:(CJPayAppInfoConfig *)appInfoConfig {
    [CJPayRequestParam setAppInfoConfig:appInfoConfig];
    NSString *did = @"";
    if (appInfoConfig.deviceIDBlock) {
        did = appInfoConfig.deviceIDBlock();
    }
    [CJTracker event:@"wallet_config_appinfo" params:@{@"aid": CJString(appInfoConfig.appId), @"did": CJString(did)}];
    // 进行相关插件的注册和启动
    [GAIAEngine startTasksForKey:@CJPayGaiaRegisterPluginInitKey];
}

@end

