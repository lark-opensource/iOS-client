//
//  CJPayDebugManager.m
//  CJPay
//
//  Created by wangxiaohong on 2020/1/16.
//

#import "CJPayDebugManager.h"
#import "CJPayDebugBOEConfig.h"

@implementation CJPayDebugManager

+ (void)enableBoe
{
    [[CJPayDebugBOEConfig shared] enableBoe];
}

+ (void)disableBoe
{
    [[CJPayDebugBOEConfig shared] disableBoe];
}

+ (BOOL)boeIsOpen
{
    return [CJPayDebugBOEConfig shared].boeIsOpen;
}

+ (void)setupConfigHost:(NSString *)configHost
{
    Class cjpayBaseRequest = NSClassFromString(@"CJPayBaseRequest");
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([cjpayBaseRequest respondsToSelector:@selector(setGConfigHost:)] && configHost && configHost.length > 0) {
        [cjpayBaseRequest performSelector:@selector(setGConfigHost:) withObject:configHost];
    }
    #pragma clang diagnostic pop
    
}

+ (void)setupBDConfigHost:(NSString *)configHost {
    Class cjpayBaseRequest = NSClassFromString(@"CJPayBaseRequest");
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([cjpayBaseRequest respondsToSelector:@selector(setGBDPayConfigHost:)] && configHost && configHost.length > 0) {
        [cjpayBaseRequest performSelector:@selector(setGBDPayConfigHost:) withObject:configHost];
    }
    #pragma clang diagnostic pop
}

+ (void)setupBoeSuffix:(NSString *)boeSuffix
{
    [CJPayDebugBOEConfig shared].boeSuffix = boeSuffix;
}

+ (NSString *)boeSuffix
{
    return [CJPayDebugBOEConfig shared].boeSuffix;
}

+ (void)setupBoeUrlWhiteList:(NSArray *)boeWhiteList
{
    [CJPayDebugBOEConfig shared].boeWhiteList = boeWhiteList;
}

+ (NSArray *)boeUrlWhiteList
{
    return [CJPayDebugBOEConfig shared].boeWhiteList;
}

+ (void)setupBoeEnvDictionary:(NSDictionary *)boeEnvDictionary
{
    [CJPayDebugBOEConfig shared].boeEnv = boeEnvDictionary;
}

+ (NSDictionary *)boeEnvDictionary
{
    return [CJPayDebugBOEConfig shared].boeEnv;
}

/**
* 更新boe环境的cookies
*/
+ (void)updateBoeCookies
{
    [[CJPayDebugBOEConfig shared] updateBoeCookies];
}

+ (void)p_setBOEHeader:(NSMutableURLRequest *)request {
    if ([self boeIsOpen]) {
        [[self boeEnvDictionary] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
    }
}

@end
