//
//  CJPaySDKHTTPRequestSerializer.m
//  CJPay
//
//  Created by jiangzhongping on 2018/9/3.
//

#import "CJPaySDKHTTPRequestSerializer.h"

#import "CJPayTracker.h"
#import "CJPayRequestParam.h"
#import "CJPaySaasSceneUtil.h"
#import "CJPayCookieUtil.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestCommonConfiguration.h"
#import <TTNetworkManager/TTNetworkManager.h>
#import "CJPayKVContext.h"

@interface CJPaySDKHTTPRequestSerializer()

@end

@implementation CJPaySDKHTTPRequestSerializer

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                              params:(NSDictionary *)params
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam
{
    NSURL *origURL = [NSURL URLWithString:URL];
    NSURL *convertUrl = [self _transferedURL:origURL];
    TTHttpRequest *mutableURLRequest = [super URLRequestWithURL:convertUrl.absoluteString params:params method:method constructingBodyBlock:bodyBlock commonParams:commonParam];
    mutableURLRequest.timeoutInterval = 10;
    //我们自己的 一些Header 在这一步加入
    [self buildRequestHeaders:mutableURLRequest parameters:params];
    
    return mutableURLRequest;
}

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                         headerField:(NSDictionary *)headField
                              params:(NSDictionary *)params
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam {
    
    NSURL *origURL = [NSURL URLWithString:URL];
    NSURL *convertUrl = [self _transferedURL:origURL];
    
    TTHttpRequest *mutableURLRequest = [super URLRequestWithURL:convertUrl.absoluteString headerField:headField params:params method:method constructingBodyBlock:bodyBlock commonParams:commonParam];
    
    //我们自己的 一些Header 在这一步加入
    [self buildRequestHeaders:mutableURLRequest parameters:params];
    
    return mutableURLRequest;
}

- (TTHttpRequest *)URLRequestWithRequestModel:(TTRequestModel *)requestModel commonParams:(NSDictionary *)commonParam {
    //规范一下 requestModel;
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:requestModel._requestURL.absoluteString];
    requestModel._uri = urlComponents.path;
    requestModel._host = [urlComponents.scheme stringByAppendingFormat:@"://%@", urlComponents.host];
    
    NSURL *origURL = [requestModel._requestURL copy];
    NSURL *convertUrl = [self _transferedURL:origURL];
    
    requestModel._host = [convertUrl.scheme stringByAppendingFormat:@"://%@", convertUrl.host];
    
    TTHttpRequest *mutableURLRequest = [super URLRequestWithRequestModel:requestModel commonParams:commonParam];
    
    //我们自己的 一些Header 在这一步加入
    [self buildRequestHeaders:mutableURLRequest parameters:requestModel._requestParams];
    
    return mutableURLRequest;
}

- (NSURL *)_transferedURL:(NSURL *)url {
    return [[TTNetworkManager shareInstance] transferedURL:url];
}

+ (instancetype)serializer
{
    return [[[self class] alloc] init];
}

- (void)buildRequestHeaders:(TTHttpRequest*)request parameters:(id)parameters
{
    if (!request || !request.URL) {
        return;
    }
    [self applyCookieHeader:request];
    
    NSDictionary *envDic = [self getEnvParams];
    [envDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (key && obj) {
            [request setValue:obj forHTTPHeaderField:key];
        }
    }];

    NSString *ua = [CJPayRequestParam uaInfoString:[CJPayRequestParam gAppInfoConfig].appId];
    if ([[request valueForHTTPHeaderField:@"User-Agent"] length] == 0) {
        [request setValue:ua forHTTPHeaderField:@"User-Agent"];
    }
    
    BOOL needAccessToken = NO;
    if ([CJPayRequestParam isSaasEnv]) {
        // 处于ntv支付流程 && SaaS环境时，请求header需带上saasscene
        [request setValue:CJString([CJPaySaasSceneUtil getCurrentSaasSceneValue]) forHTTPHeaderField:@"saasscene"]; //增加SaaS环境标识
        needAccessToken = YES;
    } else if ([[request.allHTTPHeaderFields cj_stringValueForKey:@"cj_need_access_token"] isEqualToString:@"1"]) {
        // 非支付流程且处于SaaS环境下需要accessToken
        [request setValue:nil forHTTPHeaderField:@"cj_need_access_token"];
        needAccessToken = YES;
    }
    // SaaS环境下请求头内需带上accessToken
    if (needAccessToken) {
        NSString *accessToken = [CJPayRequestParam accessToken];
        [request setValue:accessToken forHTTPHeaderField:@"bd-ticket-guard-target"]; //增加开放平台证书
        NSString *bearerAccessToken = [NSString stringWithFormat:@"Bearer %@", CJString(accessToken)]; //用户鉴权信息为Bearer XXX
        [request setValue:bearerAccessToken forHTTPHeaderField:@"authorization"];
    }

    NSString *deviceInfo = [self commonDeviceInfoString];
    [request setValue:deviceInfo forHTTPHeaderField:@"x-native-devinfo"];

    [[CJPayRequestCommonConfiguration httpRequestHeaderProtocols].allObjects enumerateObjectsUsingBlock:^(Class<CJPaySDKHTTPRequestCustomHeaderProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj appendCustomRequestHeaderFor:request];
    }];

    if ([[request valueForHTTPHeaderField:@"devinfo"] length] == 0) {
        [request setValue:deviceInfo forHTTPHeaderField:@"devinfo"];
    }
    
    NSString *headerData = [CJPayKVContext kv_stringForKey:CJPayWithDrawAddHeaderData];
    if (Check_ValidString(headerData)) {
        [request setValue:CJString(headerData) forHTTPHeaderField:@"lark-union-gateway-strategy"]; //飞书提现需要通过header区分来源
    }
    
    // 加上request time
    NSUInteger requestTime = [[NSDate date] timeIntervalSince1970] * 1000;
    [request setValue:[@(requestTime) stringValue] forHTTPHeaderField:@"tt-request-time"];
}

// debug工具swizzle
- (NSDictionary *)getEnvParams {
    return @{};
}


- (NSString *)commonDeviceInfoString
{
    NSString *jsonString = [CJPayCommonUtil dictionaryToJson:[CJPayRequestParam commonDeviceInfoDic]];
    NSString *urlEncodeString = [jsonString cj_URLEncode];
    return CJString(urlEncodeString);
}

- (void)applyCookieHeader:(TTHttpRequest*)request
{
    __block NSString *cookieHeader = nil;
    NSMutableString *cookieStr = [NSMutableString new];
    NSDictionary *extraParams = [[CJPayCookieUtil sharedUtil] _getCookieDic:request.URL.absoluteString];
    if (extraParams) {
        [extraParams enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
           [cookieStr appendFormat:@"%@:%@", key, obj];
           if (!cookieHeader) {
               cookieHeader = [NSString stringWithFormat: @"%@=%@",key,obj];
           } else {
               cookieHeader = [NSString stringWithFormat: @"%@; %@=%@",cookieHeader,key,obj];
           }
        }];
    }
    if (cookieHeader) {
        [request setValue: cookieHeader forHTTPHeaderField:@"Cookie"];
        [request setValue: cookieHeader forHTTPHeaderField:@"X-SS-Cookie"];
    }
}

@end
