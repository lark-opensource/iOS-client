//
//  EMANetworkManager.m
//  EEMicroAppSDK
//
//  Created by owen on 2018/11/20.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "EMANetworkManager.h"
#import <ECOProbe/OPTraceService.h>
#import <ECOProbe/OPMonitor.h>
#import <ECOProbe/OPTrace.h>
#import <ECOInfra/BDPUtils.h>
#import <ECOInfra/BDPLog.h>
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import <ECOInfra/NSURLSession+TMA.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <ECOInfra/ECONetworkGlobalConst.h>
#import <ECOInfra/OPTrace+RequestID.h>
#import <ECOInfra/EMANetworkMonitor.h>

static NSString * const kEventKey_result_type = @"result_type";
static NSString * const kEventValue_success = @"success";
static NSString * const kEventValue_fail = @"fail";

@interface EMANetworkManager()

@property (nonatomic, strong, readwrite) NSURLSession *urlSession;
@property (nonatomic, assign) BOOL kShouldNetworkTransmitOverRustChannel;

@end

@implementation EMANetworkManager

+ (instancetype)shared {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.urlSession = [NSURLSession sessionWithConfiguration:configuration delegate:EMANetworkMonitor.shared delegateQueue:nil];
    }
    return self;
}

#pragma mark - 网络设置
- (void)configSharedURLSessionConfigurationOverRustChannel:(BOOL)shouldNetworkTransmitOverRustChannel {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (shouldNetworkTransmitOverRustChannel) {
            // 设置各个网络代理走Rust SDK
            self.kShouldNetworkTransmitOverRustChannel = shouldNetworkTransmitOverRustChannel;
            Class cls = SwiftToOCBridge.monitorRustHttpURLProtocol;

            // NSURLSession（request, download & upload）
            // Modifying the returned session configuration object does not affect any configuration objects returned by future calls to this method
            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
            configuration.protocolClasses = @[cls];
            self.urlSession = [NSURLSession sessionWithConfiguration:configuration delegate:EMANetworkMonitor.shared delegateQueue:nil];
        }
    });
}

- (BOOL)isNetworkTransmitOverRustChannel {
    return self.kShouldNetworkTransmitOverRustChannel;
}

#pragma mark - 网络请求

- (NSURLSessionTask *)postUrl:(NSString *)urlString params:(NSDictionary *)params header:(NSDictionary *)header completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler eventName:(NSString *)eventName requestTracing:(OPTrace * _Nullable)tracing {
    return [self requestUrl:urlString method:@"POST" params:params header:header completionHandler:completionHandler eventName:eventName requestTracing: tracing];
}

//post请求
- (NSURLSessionTask *)postUrl:(NSString *)urlString params:(NSDictionary *)params completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler eventName:(NSString *)eventName requestTracing:(OPTrace * _Nullable)tracing {
    return [self requestUrl:urlString method:@"POST" params:params header:nil completionHandler:completionHandler eventName:eventName requestTracing:tracing];
}

- (NSURLSessionTask *)postUrl:(NSString *)urlString
                       params:(NSDictionary *)params
                       header:(NSDictionary *)header
       completionWithJsonData:(nonnull void (^)(NSDictionary * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable))completionHandler
                    eventName:(nonnull NSString *)eventName
               requestTracing:(OPTrace * _Nullable)tracing {
    return [self requestUrl:urlString method:@"POST" params:params header:header completionWithJsonData:^(NSDictionary * _Nullable json, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(json, response, error);
        }
    } eventName:eventName requestTracing:tracing];
}

- (NSURLSessionTask *)postUrl:(NSString *)urlString params:(NSDictionary *)params completionWithJsonData:(void (^)(NSDictionary * _Nullable json, NSError * _Nullable error))completionHandler eventName:(NSString *)eventName requestTracing:(OPTrace * _Nullable)tracing {
    return [self requestUrl:urlString method:@"POST" params:params header:nil completionWithJsonData:^(NSDictionary * _Nullable json, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(json, error);
        }
    } eventName:eventName requestTracing:tracing];
}

- (NSURLSessionTask *)getUrl:(NSString *)urlString params:(NSDictionary *)params completionWithJsonData:(void (^)(NSDictionary * _Nullable json, NSError * _Nullable error))completionHandler eventName:(NSString *)eventName {
    return [self requestUrl:urlString method:@"GET" params:params header:nil completionWithJsonData:^(NSDictionary * _Nullable json, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(json, error);
        }
    } eventName:eventName requestTracing:nil];
}

- (NSURLSessionTask *)dataTaskWithMutableRequest:(NSMutableURLRequest *)request
                               completionHandler:(void (^ _Nonnull)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
                                       eventName:(NSString * _Nonnull)eventName
                                      autoResume:(BOOL)autoResume
                                  requestTracing:(OPTrace * _Nullable)tracing {
    OPTrace *requestTracing = tracing ?: [[OPTraceService defaultService] generateTrace];
    [requestTracing genRequestID:OP_REQUEST_ENGINE_SOURCE];
    [[ECONetworkDependency commonConfiguration] addCommonConfigurationForRequest:request];
    // 4.接入Rust SDK，通过调用EMANetworkManager的API
    NSString *safeURL = [request.URL.absoluteString componentsSeparatedByString:@"?"].firstObject;
    // initWithName 存在异常 crash,暂使用 initWithService
    OPMonitorEvent *monitor = [[OPMonitorEvent alloc] initWithService:nil name:kEventName_mp_post_url monitorCode:nil];
    monitor.addCategoryValue(@"_param_for_special",@"micro_app")
    .addCategoryValue(@"js_version",[ECONetworkDependency localLibVersionString])
    .addCategoryValue(@"js_grey_hash",[ECONetworkDependency localLibGreyHash])
    .addCategoryValue(@"url", safeURL)
    .tracing(requestTracing)
    .setPlatform(OPMonitorReportPlatformTea|OPMonitorReportPlatformSlardar)
    .timing();
    NSURLSessionTask *task = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = [response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)response : nil;
        if (error) {
            BDPLogError(@"dataTaskWithRequest error, e=%@", error);
            monitor.addCategoryValue(kEventKey_result_type, kEventValue_fail).setError(error).timing();
        } else {
            monitor.addCategoryValue(kEventKey_result_type, kEventValue_success).timing();
        }
        monitor
        .addCategoryValue(@"http_code", @(httpResponse.statusCode))
        .addCategoryValue(@"request_id", [requestTracing getRequestID])
        .addCategoryValue(@"request_body_length", @(request.HTTPBody ? request.HTTPBody.length : 0))
        .addCategoryValue(@"response_body_length", @(data ? [(NSData*)data length] : 0))
        .flush();
        if (completionHandler) {
            completionHandler(data, response, error);
        }
    } eventName:eventName requestTracing: requestTracing];
    if (autoResume) {
        [task resume];
    }
    return task;
}

- (NSURLSessionTask *)requestUrl:(NSString *)urlString method:(NSString *)method params:(NSDictionary *)params header:(NSDictionary *)header completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler eventName:(NSString *)eventName autoResume:(BOOL)autoResume timeout:(NSTimeInterval)timeout requestTracing:(OPTrace * _Nullable)tracing {
    BDPLogInfo(@"request begin url=%@, method=%@, event=%@", urlString, method, eventName);
    if (BDPIsEmptyString(method)) {
        method = @"GET";
    }
    if (BDPIsEmptyDictionary(params)) {
        params = [NSDictionary dictionary];
    }
    NSMutableDictionary *mutableParams = [params mutableCopy];
    if([ECONetworkDependency commonConfiguration]) {
        [mutableParams addEntriesFromDictionary:[[ECONetworkDependency commonConfiguration] getCommonOpenPlatformRequestWithURLString:urlString]];
        [mutableParams addEntriesFromDictionary:[[ECONetworkDependency commonConfiguration] getLoginParamsWithURLString:urlString]];
        method = [[ECONetworkDependency commonConfiguration] getMethodWithURLString:urlString method:method];
        timeout = [[ECONetworkDependency commonConfiguration] getTimeoutWithURLString:urlString timeout:timeout];
    }

    NSMutableURLRequest *request;
    if ([method isEqualToString:@"POST"]) {
        request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        request.HTTPMethod = @"POST";
        NSError* error;
        NSData *requstData = [NSJSONSerialization dataWithJSONObject:mutableParams options:NSJSONWritingPrettyPrinted error:&error];
        request.HTTPBody = requstData;
    } else {
        NSMutableString *url = [[NSMutableString alloc] initWithString:urlString];
        if (![url containsString:@"?"]) {
            [url appendFormat:@"?"];
        }
        for (NSString *key in mutableParams) {
            NSObject *value = mutableParams[key];
            [url appendFormat:@"%@=%@", key.URLEncodedString, value.description.URLEncodedString];
            [url appendFormat:@"&"];
        }
        request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    }
    NSString *contentType = [header bdp_stringValueForKey:@"Content-Type"]? :[header bdp_stringValueForKey:@"content-type"];
    contentType = contentType? :@"application/json";
    request.allHTTPHeaderFields = header;
    request.timeoutInterval = timeout > 0 ? timeout : 60;
    [request setValue:contentType forHTTPHeaderField:@"content-type"];

    NSURLSessionTask *task = [self dataTaskWithMutableRequest:request completionHandler:completionHandler eventName:eventName autoResume:autoResume requestTracing:tracing];
    return task;
}

- (NSURLSessionTask *)requestUrl:(NSString *)urlString method:(NSString *)method params:(NSDictionary *)params header:(NSDictionary *)header completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler eventName:(NSString *)eventName requestTracing:(OPTrace * _Nullable)tracing {
    return [self requestUrl:urlString method:method params:params header:header completionHandler:completionHandler eventName:eventName autoResume:YES timeout:60 requestTracing:tracing];
}

- (NSURLSessionTask *)requestUrl:(NSString *)urlString method:(NSString *)method params:(NSDictionary *)params header:(NSDictionary *)header completionWithJsonData:(void (^)(NSDictionary * _Nullable json, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler eventName:(nonnull NSString *)eventName autoResume:(BOOL)autoResume timeout:(NSTimeInterval)timeout requestTracing:(OPTrace * _Nullable)tracing {
    BDPLogInfo(@"request begin url=%@, method=%@, event=%@", urlString, method, eventName);
    return [self requestUrl:urlString method:method params:params header:header completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            BDPLogError(@"postUrl error=%@, url=%@, method=%@", BDPParamStr(error), urlString, method);
            completionHandler(nil, response, error);
            return;
        }
        NSError *jsonError;
        NSDictionary *jsonResponse = [data JSONValueWithOptions:0 error:&jsonError];

        if (jsonError) {
            BDPLogError(@"postUrl jsonError=%@, url=%@, method=%@", BDPParamStr(jsonError), urlString, method);
            completionHandler(nil, response, jsonError);
            return;
        }
        completionHandler(jsonResponse, response, nil);
    } eventName:eventName autoResume:autoResume timeout:timeout requestTracing:tracing];
}

- (NSURLSessionTask *)requestUrl:(NSString *)urlString method:(NSString *)method params:(NSDictionary *)params header:(NSDictionary *)header completionWithJsonData:(void (^)(NSDictionary * _Nullable json, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler eventName:(nonnull NSString *)eventName requestTracing:(OPTrace * _Nullable)tracing {
    return [self requestUrl:urlString method:method params:params header:header completionWithJsonData:completionHandler eventName:eventName autoResume:YES timeout:60 requestTracing:tracing];
}

@end
