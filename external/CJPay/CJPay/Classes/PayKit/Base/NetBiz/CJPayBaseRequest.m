//
//  CJPayBaseRequest.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/24.
//

#import "CJPayBaseRequest.h"

#import "CJPayJSONResponseSerializer.h"
#import "CJPaySDKJSONRequestSerializer.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"
#import "CJPayRequestCommonConfiguration.h"
#import "CJPaySettingsManager.h"
#import <JSONModel/JSONModel.h>
#import <TTReachability/TTReachability.h>

static NSString *noNetworkDesc = @"No Network";

static NSString *gConfigHost = @"";

@implementation CJPayBaseRequest

+ (NSString *)deskServerHostString {
    NSString *serverUrl = [NSString stringWithFormat:@"%@", [self gConfigHost]];
    return serverUrl;
}

+ (NSString *)deskServerUrlString {
    NSString *deskServerPath = [CJPayRequestParam isSaasEnv] ? @"gateway-u-saas" : @"gateway-u";
    return [NSString stringWithFormat:@"%@/%@", [self deskServerHostString], deskServerPath];
}

+ (NSString *)cashierServerUrlString {
    NSString *deskServerPath = [CJPayRequestParam isSaasEnv] ? @"gateway-cashier2-saas" : @"gateway-cashier2";
    return [NSString stringWithFormat:@"%@/%@", [self deskServerHostString], deskServerPath];
}

+ (NSMutableDictionary *)buildBaseParams {
    return [self buildBaseParamsWithVersion:@"1.0" needTimestamp:YES];
}

+ (NSMutableDictionary *)buildBaseParamsWithVersion:(NSString *)version needTimestamp:(BOOL)needTimestamp {
    NSMutableDictionary *requestParams = [NSMutableDictionary dictionary];
    [requestParams cj_setObject:@"utf-8" forKey:@"charset"];
    [requestParams cj_setObject:@"JSON" forKey:@"format"];
    if (Check_ValidString(version)){
        [requestParams cj_setObject:version forKey:@"version"];
    }
    if (needTimestamp) {
        [requestParams cj_setObject:[NSString stringWithFormat:@"%.0lf",[[NSDate date]timeIntervalSince1970]] forKey:@"timestamp"];
    }
    return requestParams;
}

+ (void)startRequestWithUrl:(NSString *)urlString requestParams:(NSDictionary *)requestParams callback:(TTNetworkJSONFinishBlock)callback {
    [self startRequestWithUrl:urlString
                            serializeType:CJPayRequestSerializeTypeURLEncode
                            requestParams:requestParams
                                 callback:callback];
}

+ (void)startRequestWithUrl:(NSString *)urlString
              serializeType:(CJPayRequestSerializeType)serializeType
              requestParams:(NSDictionary *)requestParams
                   callback:(TTNetworkJSONFinishBlock)callback {
    [self startRequestWithUrl:urlString
                       method:@"POST"
                requestParams:requestParams
                 headerFields:@{}
                serializeType:serializeType
                     callback:callback];
}

+ (void)startRequestWithUrl:(NSString *)urlString
                     method:(NSString *)method
              requestParams:(NSDictionary *)requestParams
               headerFields:(NSDictionary *)headerFields
              serializeType:(CJPayRequestSerializeType)serializeType
                   callback:(TTNetworkJSONFinishBlock)callback {
    [self startRequestWithUrl:urlString method:method requestParams:requestParams headerFields:headerFields serializeType:serializeType callback:callback needCommonParams:YES];
}

+ (void)startRequestWithUrl:(NSString *)urlString
                     method:(NSString *)method
              requestParams:(NSDictionary *)requestParams
               headerFields:(NSDictionary *)headerFields
              serializeType:(CJPayRequestSerializeType)serializeType
                   callback:(TTNetworkJSONFinishBlock)callback
           needCommonParams:(BOOL)needCommonParams {
    [self startRequestWithUrl:urlString method:method requestParams:requestParams headerFields:headerFields serializeType:serializeType callback:callback needCommonParams:needCommonParams highPriority:NO];
}

+ (void)startRequestWithUrl:(NSString *)urlString
                     method:(NSString *)method
              requestParams:(NSDictionary *)requestParams
               headerFields:(NSDictionary *)headerFields
              serializeType:(CJPayRequestSerializeType)serializeType
                   callback:(TTNetworkJSONFinishBlock)callback
           needCommonParams:(BOOL)needCommonParams
               highPriority:(BOOL)highPriority {
    NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:-1009 userInfo:@{@"desc": CJPayLocalizedStr(noNetworkDesc)}];
    [[NSNotificationCenter defaultCenter] postNotificationName:CJPayRequestStartNotifictionName object:@{@"url": CJString(urlString)}];
    
    if ([[TTReachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
        callback(error,nil);
        CJPayLogError(@"网络请求失败, url=%@, 错误原因：网络不可达", urlString);
        [[NSNotificationCenter defaultCenter] postNotificationName:CJPayRequestFinishNotificationName object:@{@"url": CJString(urlString)}];
        return;
    }
    
    Class<TTHTTPRequestSerializerProtocol> requestSerializer = nil;
    // 默认请求体走URL编码的形式
    switch (serializeType) {
        case CJPayRequestSerializeTypeURLEncode:
            requestSerializer = [CJPaySDKHTTPRequestSerializer class];
            break;
        case CJPayRequestSerializeTypeJSON:
            requestSerializer = [CJPaySDKJSONRequestSerializer class];
            break;
        default:
            requestSerializer = [CJPaySDKHTTPRequestSerializer class];
            break;
    }
    
    NSTimeInterval requestStartTime = CFAbsoluteTimeGetCurrent();
    @CJWeakify(self)
    __auto_type callbackBlock = ^(NSError *error, id obj, TTHttpResponse *response) {
        @CJStrongify(self)
        [self monitor:urlString error:error response:response];
        NSTimeInterval requestCostTime = (CFAbsoluteTimeGetCurrent() - requestStartTime) * 1000;
        [self eventTrack:urlString
                costTime:requestCostTime
                   error:error
                response:response];
        
        void(^execCallback)(void) = ^{
            NSMutableDictionary *jsonDic = [[CJPayCommonUtil dictionaryFromJsonObject:obj] mutableCopy];
            NSTimeInterval responseDuration = (CFAbsoluteTimeGetCurrent() - requestStartTime) * 1000;
            [self monitorRequestBizResult:urlString costTime:responseDuration error:error response:response responseJsonDic:jsonDic];
            
            if (jsonDic) {
                jsonDic[@"response_duration"] = @(responseDuration);
                callback(error, jsonDic);
                [[NSNotificationCenter defaultCenter] postNotificationName:CJPayRequestFinishNotificationName object:@{@"url": CJString(urlString)}];
                return;
            }
            callback(error, obj);
            [[NSNotificationCenter defaultCenter] postNotificationName:CJPayRequestFinishNotificationName object:@{@"url": CJString(urlString)}];
        };
        BOOL pluginIsInstall = [[CJPayRequestCommonConfiguration requestInterceptProtocol] interceptResponseCallback:obj requestParams:requestParams retryRequestBlock:^{
            @CJStrongify(self)
            [self startRequestWithUrl:urlString method:method requestParams:requestParams headerFields:headerFields serializeType:serializeType callback:callback needCommonParams:needCommonParams highPriority:highPriority];
        } completionBlock:^{
            CJ_CALL_BLOCK(execCallback);
        }];
        if (pluginIsInstall) {
            return;
        }
        CJ_CALL_BLOCK(execCallback);
    };
    
    
    CJPayLogInfo(@"开始请求: %@", urlString);
    if (highPriority) {
        [[TTNetworkManager shareInstance] requestForJSONWithResponse:urlString
                                                              params:requestParams
                                                              method:method
                                                    needCommonParams:needCommonParams
                                                         headerField:headerFields
                                                          requestSerializer:requestSerializer
                                                  responseSerializer:[CJPayJSONResponseSerializer class]
                                                                 autoResume:YES
                                                              verifyRequest:NO
                                                         isCustomizedCookie:NO
                                                            callback:^(NSError *error, id obj, TTHttpResponse *response) {
            dispatch_async(dispatch_get_main_queue(), ^{
                CJ_CALL_BLOCK(callbackBlock, error, obj, response);
            });
        } callbackQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
    } else {
        [[TTNetworkManager shareInstance] requestForJSONWithResponse:urlString
                                                              params:requestParams
                                                              method:method
                                                    needCommonParams:needCommonParams
                                                         headerField:headerFields
                                                   requestSerializer:requestSerializer
                                                  responseSerializer:[CJPayJSONResponseSerializer class]
                                                          autoResume:YES
                                                            callback:^(NSError *error, id obj, TTHttpResponse *response) {
            CJ_CALL_BLOCK(callbackBlock, error, obj, response);
        }];
    }
}

+ (void)startRequestWithUrl:(NSString *)urlString
                       type:(NSString *)type
              requestParams:(NSDictionary *)requestParams
                     header:(NSDictionary *)headerParams
                   callback:(TTNetworkJSONFinishBlockWithResponse)callback {
    
    NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:-1009 userInfo:@{@"desc": CJPayLocalizedStr(noNetworkDesc)}];
    if ([[TTReachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
        callback(error,nil,nil);
        return;
    }
    
    NSTimeInterval requestStartTime = CFAbsoluteTimeGetCurrent();
    CJPayLogInfo(@"开始请求: %@", urlString);
    [[TTNetworkManager shareInstance] requestForJSONWithResponse:urlString
                                                          params:requestParams
                                                          method:type
                                                needCommonParams:NO
                                                     headerField:headerParams
                                               requestSerializer:[CJPaySDKHTTPRequestSerializer class] responseSerializer:[CJPayJSONResponseSerializer class]
                                                      autoResume:YES
                                                        callback:^(NSError *error, id obj, TTHttpResponse *response) {
        [self monitor:urlString error:error response:response];
        NSTimeInterval requestCostTime = (CFAbsoluteTimeGetCurrent() - requestStartTime) * 1000;
        [self eventTrack:urlString
                costTime:requestCostTime
                   error:error
                response:response];
        
        void(^execCallback)(void) = ^{
            NSMutableDictionary *jsonDic = [[CJPayCommonUtil dictionaryFromJsonObject:obj] mutableCopy];
            if (jsonDic) {
                NSTimeInterval responseDuration = (CFAbsoluteTimeGetCurrent() - requestStartTime) * 1000;
                jsonDic[@"response_duration"] = @(responseDuration);
                callback(error, jsonDic, response);
                return;
            }
            callback(error, obj, response);
        };
        BOOL pluginIsInstall = [[CJPayRequestCommonConfiguration requestInterceptProtocol] interceptResponseCallback:obj requestParams:requestParams retryRequestBlock:^{
            [self startRequestWithUrl:urlString type:type requestParams:requestParams header:headerParams callback:callback];
        } completionBlock:^{
            execCallback();
        }];
        if (pluginIsInstall) {
            return;
        }
        execCallback();
    }];
}

+ (NSDictionary *)p_buildMonitorDataWith:(NSString *)requestUrlStr error:(NSError *)error response:(TTHttpResponse *)response {
    NSURL *url = [NSURL URLWithString:[requestUrlStr cj_safeURLString]];
    if (!url) {
        return @{};
    }
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSMutableDictionary *dic = [NSMutableDictionary new];
    [dic cj_setObject:urlComponents.host forKey:@"host"];
    [dic cj_setObject:urlComponents.path forKey:@"path"];
    [dic cj_setObject:@(error.code)  forKey:@"error_code"];
    [dic cj_setObject:error.localizedDescription forKey:@"error_desc"];
    if ([response isKindOfClass:TTHttpResponse.class]) {
        [dic cj_setObject:@(response.statusCode) forKey:@"status_code"];
    }
    [dic cj_setObject:@(response.timinginfo.total) forKey:@"length"];
    return [dic copy];
}

+ (void)monitor:(NSString *)requestUrlStr error:(NSError *)error response:(TTHttpResponse *)response {
    static NSInteger networkQuality = -1;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSNotificationCenter defaultCenter] addObserverForName:@"kHMDCurrentNetworkQualityDidChange" object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            NSDictionary *dic = (NSDictionary *)note.object;
            if ([dic isKindOfClass:NSDictionary.class]) {
                networkQuality = [dic cj_integerValueForKey:@"network_quality"];
            }
        }];
    });
    
    TTHttpResponseTimingInfo *timinginfo = response.timinginfo;
    NSDictionary *timeInfo = @{
        @"dns": @(timinginfo.dns),
        @"connect": @(timinginfo.connect),
        @"ssl": @(timinginfo.ssl),
        @"send": @(timinginfo.send),
        @"wait": @(timinginfo.wait),
        @"receive": @(timinginfo.receive),
        @"totlal": @(timinginfo.total),
        @"socket_reuse": @(timinginfo.isSocketReused),
        @"network_quality": @(networkQuality),
    };
    if (!error && response) {
        CJPayLogInfo(@"请求成功: %@, 具体耗时情况: %@", requestUrlStr, timeInfo);
    } else {
        CJPayLogError(@"请求失败: %@, 错误信息：code=%ld, msg=%@, 具体耗时情况: %@",requestUrlStr, error.code, error.description, timeInfo);
    }
    [CJMonitor trackService:@"wallet_rd_monitor_network" extra:[self p_buildMonitorDataWith:requestUrlStr error:error response:response]];
}

+ (void)eventTrack:(NSString *)requestUrlStr
          costTime:(NSTimeInterval)costTime
             error:(NSError *)error
          response:(TTHttpResponse *)response {
    NSURL *url = [NSURL URLWithString:[requestUrlStr cj_safeURLString]];
    if (!url) {
        return;
    }
    NSUInteger errorCode = error ? error.code : 0;
    [CJTracker event:@"wallet_rd_network_success_info"
              params:@{@"url": CJString(url.absoluteString),
                       @"host": CJString(url.host),
                       @"path": CJString(url.path),
                       @"status": @(errorCode),
                       @"reason": CJString(error.description),
                       @"length": @(response.timinginfo.receivedResponseContentLength),
                       @"time": @(costTime)}];
}

+ (void)exampleMonitor:(NSString *)requestUrlStr error:(NSError *)error response:(TTHttpResponse *)response {
    if (!error && response) {
        CJPayLogInfo(@"请求成功: %@", requestUrlStr);
    } else {
        CJPayLogError(@"请求失败: %@, 错误信息：code=%ld, msg=%@, response耗时信息: %@",requestUrlStr, error.code, error.description, response.additionalTimeInfo.completionBlockTime);
    }
    [CJMonitor trackService:@"wallet_rd_monitor_network_example" extra:[self p_buildMonitorDataWith:requestUrlStr error:error response:response]];
}

// 端到端接口业务异常上报
+ (void)monitorRequestBizResult:(NSString *)requestUrlStr
                       costTime:(NSTimeInterval)costTime
                          error:(NSError *)error
                       response:(TTHttpResponse *)response
                responseJsonDic:(NSDictionary *)resJsonDic
{
    if ([CJPaySettingsManager shared].currentSettings.rdOptimizationConfig.isDisableMonitorRequestBizResult) {
        return;
    }
    
    NSURL *url = [NSURL URLWithString:[requestUrlStr cj_safeURLString]];
    if (!url) {
        return;
    }
    NSMutableDictionary *monitorParam = [NSMutableDictionary dictionaryWithDictionary:@{
        @"url": CJString(url.absoluteString),
        @"host": CJString(url.host),
        @"path": CJString(url.path),
        @"cost_time": @(costTime)
    }];

    [monitorParam addEntriesFromDictionary:[self p_analyseBizResult:resJsonDic]]; //业务状态码
    
    [monitorParam cj_setObject:@(error ? error.code : 0) forKey:@"origin_error_code"];
    [monitorParam cj_setObject:CJString(error.localizedDescription) forKey:@"origin_error_desc"];
    [monitorParam cj_setObject:@(response.statusCode) forKey:@"origin_status_code"];
    
    NSString *sdkCode = @"0";
    NSString *sdkMsg = @"";
    if (error || resJsonDic == nil) {
        sdkCode = @"-10002";
        sdkMsg = @"网络错误";
    }
    [monitorParam cj_setObject:CJString(sdkCode) forKey:@"sdk_code"];
    [monitorParam cj_setObject:CJString(sdkMsg) forKey:@"sdk_msg"];
    [CJMonitor trackService:@"wallet_rd_biz_request_result" extra:[monitorParam copy]];
}

+ (NSDictionary *)p_analyseBizResult:(NSDictionary *)resJsonDic {
    
    if (!Check_ValidDictionary(resJsonDic)) {
        return @{};
    }
    // 解析各业务域网络请求结果
    NSString *code = @"";
    NSString *msg = @"";
    if ([[resJsonDic cj_objectForKey:@"response"] isKindOfClass:NSDictionary.class]) {
        // 追光域结果解析
        NSDictionary *responseDict = [resJsonDic cj_objectForKey:@"response"];
        code = [responseDict cj_stringValueForKey:@"code"];
        msg = [responseDict cj_stringValueForKey:@"msg"];
    } else if (Check_ValidString([resJsonDic cj_stringValueForKey:@"code"]) &&
               [[resJsonDic allKeys] containsObject:@"error"]) {
        // 聚合域结果解析
        code = [resJsonDic cj_stringValueForKey:@"code"];
        id resError = [resJsonDic cj_objectForKey:@"error"];
        if ([resError isKindOfClass:NSDictionary.class]) {
            msg = [(NSDictionary *)resError cj_stringValueForKey:@"msg"];
        }
    } else if ([resJsonDic cj_objectForKey:@"code"] != nil &&
               Check_ValidString([resJsonDic cj_stringValueForKey:@"msg"])) {
        // 消金域结果解析
        msg = [resJsonDic cj_stringValueForKey:@"msg"];
        NSInteger codeInt = [resJsonDic cj_integerValueForKey:@"code"];
        code = [NSString stringWithFormat:@"%ld", codeInt];
    } else if ([[resJsonDic cj_objectForKey:@"header"] isKindOfClass:NSDictionary.class]) {
        // 保险域结果解析
        NSDictionary *responseHeader = [resJsonDic cj_objectForKey:@"header"];
        NSInteger codeInt = [responseHeader cj_integerValueForKey:@"code"];
        code = [NSString stringWithFormat:@"%ld", codeInt];
        msg = [responseHeader cj_stringValueForKey:@"msg"];
    }
    NSDictionary *bizResult = @{
        @"code": CJString(code),
        @"msg": CJString(msg)
    };
    return bizResult;
}

@end


@implementation CJPayBaseRequest(Config)

+ (void)setGConfigHost:(NSString *)configHost {
    if (configHost && configHost.length > 0) {
        gConfigHost = configHost;
    }
}

+ (NSString *)gConfigHost {
    CJPayLogAssert(gConfigHost && gConfigHost.length > 1, @"please configure request Host");
    return gConfigHost;
}

@end
