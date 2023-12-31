//
//  CJPayCookieUtil.m
//  CJPay
//
//  Created by wangxinhua on 2018/10/30.
//

#import "CJPayCookieUtil.h"
#import "CJPayBizParam.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"

@implementation CJPayCookieUtil

+ (instancetype)sharedUtil{
    static CJPayCookieUtil *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [CJPayCookieUtil new];
    });
    return instance;
}

- (CJPayConfigBlock)cookieBlock{
    return _cookieBlock;
}

- (void)setupCookie:(void(^)(BOOL)) completion {
    CJ_CALL_BLOCK(completion, YES);
    // setupCookie依赖宿主本身的Cookies，SDK不自己设置
}

- (void)cleanCookies {
    // 不在处理清空逻辑, 由宿主来处理
}

- (NSString *)getWKCookieScript:(NSString *)forUrl {
    NSDictionary *cookieDic = [self _getCookieDic:forUrl];
    // build cookie script
    NSMutableString *cookieScript = [NSMutableString new];
    [cookieDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [cookieScript appendFormat:@"%@=%@;", key, obj];
    }];
    return [cookieScript copy];
}

- (NSString *)getWebCommonScipt:(NSString *)forUrl {
    // 设置业务方需要注入的cookie
    NSMutableString *script = [NSMutableString new];
    NSDictionary *bizCookieParams = [self _getCookieDic:forUrl];
    [bizCookieParams enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [script appendString:[NSString stringWithFormat:@"document.cookie='%@=%@;path=/';", key,obj]];
    }];
    return script;
}

- (NSDictionary *)_getCookieDic:(NSString *)forUrl {
    if (!Check_ValidString(forUrl)) {
        return @{};
    }
    
    if (![NSURL URLWithString:forUrl]) {
        [CJMonitor trackService:@"wallet_rd_get_cookie_url_error"
                         metric:@{}
                       category:@{}
                          extra:@{@"url": CJString(forUrl)}];
        return @{};
    }
    
    NSMutableDictionary *cookieDic = [NSMutableDictionary new];
    [cookieDic addEntriesFromDictionary:[self getEnvParams]];
    NSArray<NSHTTPCookie *> *cookiesForCurUrl = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:forUrl]];
    [cookiesForCurUrl enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [cookieDic cj_setObject:obj.value forKey:obj.name];
    }];
    
    return [cookieDic copy];
}

- (NSDictionary<NSString *, NSString *> *)cjpayExtraParams {
    NSMutableDictionary *webAndRequestNeedParams = [NSMutableDictionary new];
    
    [webAndRequestNeedParams addEntriesFromDictionary:[self getEnvParams]];
    
    NSString *language = ([CJPayLocalizedUtil getCurrentLanguage] == CJPayLocalizationLanguageEn) ? @"en" : @"cn";
    [webAndRequestNeedParams cj_setObject:[CJPayRequestParam gAppInfoConfig].appId forKey:@"tp_aid"];
    [webAndRequestNeedParams cj_setObject:language forKey:@"tp_lang"];
    return [webAndRequestNeedParams copy];
}

- (NSDictionary *)getEnvParams {
    return @{};
}

@end
