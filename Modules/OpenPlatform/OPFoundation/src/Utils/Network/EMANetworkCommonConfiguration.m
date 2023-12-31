//
//  EMANetworkCommonConfiguration.m
//  EEMicroAppSDK
//
//  Created by MJXin on 2021/4/9.
//

#import "EMANetworkCommonConfiguration.h"
//#import "EMAAppEngine.h"
#import "EMANetworkAPI.h"
#import "BDPUserAgent.h"
#import <LarkRustHTTP/LarkRustHTTP-Swift.h>
#import "BDPTimorClient.h"
#import "BDPMacroUtils.h"
#import "EMAAppEngineAccount.h"
#import <ECOInfra/BDPLog.h>
#import "OPResolveDependenceUtil.h"

@implementation EMANetworkCommonConfiguration

+ (NSString *)userSession {
    EMAAppEngineAccount *engineAccount = [OPResolveDependenceUtil currentAppEngineAccount];
    return engineAccount.userSession;
}

/// 根据 url 拼接 sessionid
/// 过渡态, 拆分自原 configRequestParamsWithURLString, 目的拆离 EMANetworkManager 中耦合逻辑为下沉做准备
+ (NSDictionary *)getLoginParamsWithURLString:(NSString * _Nonnull)urlString{
    if ([urlString hasPrefix:EMAAPI.userLoginURL]) {
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:5];
//        params[@"sessionid"] = EMAAppEngine.currentEngine.account.userSession;
        params[@"sessionid"] = [self userSession];
        return [params copy];
    }
    
    return @{};
}

/// 根据 url 拼接通用字段
/// 过渡态, 修改自原 configCommonOpenPlatformRequestWithURLString, 目的拆离 EMANetworkManager 中耦合逻辑为下沉做准备
+ (NSDictionary *)getCommonOpenPlatformRequestWithURLString:(NSString *)urlString {
    if ([EMAAPI isOpenPlatformRequestForURLString:urlString]) {
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:5];
        params[@"app_version"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        params[@"platform"] = @"ios";
        return [params copy];
    }
    
    return @{};
}

/// 根据 url 拼接设置超时
/// 过渡态, 拆分自原 configRequestParamsWithURLString, 目的拆离 EMANetworkManager 中耦合逻辑为下沉做准备
+ (NSTimeInterval)getTimeoutWithURLString:(NSString * _Nonnull)urlString timeout:(NSTimeInterval)timeout{
    if ([urlString hasPrefix:EMAAPI.userLoginURL] || [urlString hasPrefix:EMAAPI.userInfoURL]) {
        return timeout = 15;
    }
    return timeout;
}

/// 根据 url 拼接设置 Method
/// 过渡态, 拆分自原 configRequestParamsWithURLString, 目的拆离 EMANetworkManager 中耦合逻辑为下沉做准备
+ (NSString *)getMethodWithURLString:(NSString * _Nonnull)urlString method:(NSString * _Nonnull)method{
    if ([urlString hasPrefix:EMAAPI.userLoginURL] || [urlString hasPrefix:EMAAPI.userInfoURL]) {
        return @"POST";
    }
    return method;
}

/// 接入Rust SDK相关功能
/// 过渡态, 来自原 EMANetworkManager, 目的拆离 EMANetworkManager 中耦合逻辑为下沉做准备
+ (void)addCommonConfigurationForRequest:(NSMutableURLRequest *)request {
    if (![request isKindOfClass:[NSMutableURLRequest class]]) {
        return;
    }

    /// 标识请求来自小程序，便于rust sdk在做打点日志的时候区分
    [request setValue:@"miniapp" forHTTPHeaderField:@"called_from"];

    // 支持复合连接，网络请求超时建议最低 15s
    // 重试次数端上可以不用设置了，sdk 内部已经屏蔽该字段
    request.enableComplexConnect = YES;

    // 判断是开放平台域名，才支持双机房环境
    NSString *urlString = request.URL.absoluteString;
    if ([EMAAPI isOpenPlatformRequestForURLString:urlString]) {
        /// 添加小程序双机房配置参数，由Rust SDK检测此参数替换对应的备份机房域名
        /// 文档参见https://bytedance.feishu.cn/space/doc/doccn97DHActi4X2W75meLyEcjd
        [request setValue:@"open" forHTTPHeaderField:@"domain_alias"];
    }

    // 配置user-agent
    [request setValue:[BDPUserAgent getUserAgentString] forHTTPHeaderField:@"User-Agent"];

    // 增加 LarkSession Header
    if ([EMAAPI needLarkSessionForURLString:urlString]) {
//         [request setValue:EMAAppEngine.currentEngine.account.userSession forHTTPHeaderField:@"X-Session-ID"];
        [request setValue:[self userSession] forHTTPHeaderField:@"X-Session-ID"];
        
    }
}
@end
