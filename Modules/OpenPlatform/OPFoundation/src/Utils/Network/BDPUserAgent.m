//
//  BDPUserAgent.m
//  Timor
//
//  Created by zhoushijie on 2019/1/4.
//

#import "BDPUserAgent.h"
#import "BDPUtils.h"
#import "BDPTimorClient.h"
#import "BDPSandBoxHelper.h"
#import "BDPVersionManager.h"
#import <WebKit/WebKit.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import "EEFeatureGating.h"
#import "OPAppUniqueID.h"
#import <ECOInfra/ECOInfra-Swift.h>

static NSString * kBDPOriginUserAgent;
static NSString * kBDPDefaultUserAgent;
static NSString * const kBDPOriginUserAgentKey = @"kBDPOriginUserAgentKey";
static WKWebView * kBDPOriginWebView;

@implementation BDPUserAgent

+ (NSString *)getOriginUserAgentString
{
    if (!BDPIsEmptyString(kBDPOriginUserAgent)) {
        return kBDPOriginUserAgent;
    }
    
    kBDPOriginUserAgent = [[LSUserDefault standard] getStringForKey:kBDPOriginUserAgentKey];
    if (!BDPIsEmptyString(kBDPOriginUserAgent)) {
        //异步更新userDefault中的UA，避免系统升级之后获取老UA而不更新（一次飞书生命周期中只执行一次）
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [BDPUserAgent updateUAInUserDefaultOnMainQueue];
        });
    
        return kBDPOriginUserAgent;
    }

    // 先返回一个默认UA，再异步读取和更新真实值
    kBDPOriginUserAgent = [self defaultUserAgentString];

    [BDPUserAgent updateUAInUserDefaultOnMainQueue];

    return BDPSafeString(kBDPOriginUserAgent);
}
//在主线程中更新一次UA，并持计划
+(void)updateUAInUserDefaultOnMainQueue
{
    BDPExecuteOnMainQueue(^{
        WKWebView *webView = [WKWebView new];
        /// 先持有WebView，获取UA后再释放，避免被提前释放
        kBDPOriginWebView = webView;
        [webView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id _Nullable userAgent, NSError * _Nullable error) {
            if (!BDPIsEmptyString(userAgent)) {
                kBDPOriginUserAgent = userAgent;
                kBDPOriginWebView = nil;
                [[LSUserDefault standard] setString:kBDPOriginUserAgent forKey:kBDPOriginUserAgentKey];
                [[LSUserDefault standard] synchronize];
            }
        }];
    });
}

/// 模拟系统WKWebView返回的默认UA
+ (NSString *)defaultUserAgentString {
    BOOL isIPad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
    NSString *deviceNameForUserAgent = isIPad ? @"iPad" : @"iPhone";
    NSString *osNameForUserAgent = isIPad ? @"OS" : @"iPhone OS";
    NSString *systemMarketingVersion = UIDevice.currentDevice.systemVersion;
    NSString *systemMarketingVersionForUserAgentString = [systemMarketingVersion stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    return [NSString stringWithFormat:@"Mozilla/5.0 "
        "(%@; CPU %@ %@ like Mac OS X) "
        "AppleWebKit/605.1.15 (KHTML, like Gecko) "
         "Mobile/15E148",
            deviceNameForUserAgent,
            osNameForUserAgent,
            systemMarketingVersionForUserAgentString];
}

+ (NSString *)getAppNameAndVersionString
{
    static NSString * kBDPAppNameAndVersion;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
        NSString *marketingVersionNumber = BDPDeviceTool.bundleShortVersion ?: @"";

        NSData *latin1Data = [appName dataUsingEncoding:NSUTF8StringEncoding];
        appName = [[NSString alloc] initWithData:latin1Data encoding:NSISOLatin1StringEncoding];
        kBDPAppNameAndVersion = [NSString stringWithFormat:@"%@/%@", appName, marketingVersionNumber];
    });
    return kBDPAppNameAndVersion;
}

+ (NSString *)getHostUserAgentString
{
    // lint:disable:next lark_storage_check
    NSString *defaultUA = [[NSUserDefaults standardUserDefaults] stringForKey:@"UserAgent"];
    NSString *hostUA = BDPIsEmptyString(defaultUA) ? [self getOriginUserAgentString] : defaultUA;
    if (BDPIsEmptyString(kBDPDefaultUserAgent) || ![kBDPDefaultUserAgent hasPrefix:hostUA]) {
        NSString *appName = [BDPUserAgent getAppNameAndVersionString];
        NSString *timorUA = BDP_STRING_CONCAT(@"Toutiao",@"Mic",@"roA", @"pp");
        kBDPDefaultUserAgent = [NSString stringWithFormat:@"%@ %@ Mobile %@", hostUA, appName, timorUA];
    }
                                
    //JSSDK在宿主启动后有更新的可能性，这里每次取最新的JSSDK版本
    return [NSString stringWithFormat:@"%@/%@", kBDPDefaultUserAgent, [BDPVersionManager localLibVersionString]];
}

+ (NSString *)getUserAgentString
{
    // 若没有实现bdp_customUserAgent方法，则默认UA为头条那边UA
    BDPPlugin(networkPlugin, BDPNetworkPluginDelegate);
    if ([networkPlugin respondsToSelector:@selector(bdp_customUserAgent)]) {
        return [networkPlugin bdp_customUserAgent];
    }
    return [BDPUserAgent getHostUserAgentString];

}

// 需要注意，这里的 uniqueID 有重要用途，会用于 URLProtocol 数据拦截时识别应用上下文
+ (NSString *)getUserAgentStringWithUniqueID:(OPAppUniqueID *)uniqueID {
    NSString *originUA = [BDPUserAgent getUserAgentString];
    if (!uniqueID.isValid) {
        return originUA;
    }
    return [NSString stringWithFormat:@"%@ uniqueID/%@", originUA, uniqueID.fullString];
}

// 需要注意，这里的 uniqueID 有重要用途，会用于 URLProtocol 数据拦截时识别应用上下文
+ (NSString *)getUserAgentStringWithUniqueID:(OPAppUniqueID *)uniqueID webviewID:(NSString *)webviewID {
    NSString *originUA = [BDPUserAgent getUserAgentString];
    if (!uniqueID.isValid) {
        return [NSString stringWithFormat:@"%@ webview/%@", originUA, webviewID?:@""];
    }
    return [NSString stringWithFormat:@"%@ uniqueID/%@ webview/%@", originUA, uniqueID.fullString, webviewID?:@""];
}

@end
