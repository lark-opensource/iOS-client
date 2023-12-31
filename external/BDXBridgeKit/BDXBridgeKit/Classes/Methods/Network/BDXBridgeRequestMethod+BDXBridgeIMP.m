//
//  BDXBridgeRequestMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/16.
//

#import "BDXBridgeRequestMethod+BDXBridgeIMP.h"
#import "BDXBridgeServiceManager.h"
#import "BDXBridge+Internal.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTNetworkManager/TTNetworkUtil.h>
#import <TTNetworkManager/TTPostDataHttpRequestSerializer.h>
#import <TTReachability/TTReachability.h>

static NSString * const BDXBridgeGraphQLParamKey = @"BDXBridgeGraphQLParamKey";

@interface BDXBridgeGraphQLRequestSerializer : TTDefaultHTTPRequestSerializer

@end

@implementation BDXBridgeGraphQLRequestSerializer

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL headerField:(NSDictionary *)headField params:(NSDictionary *)params method:(NSString *)method constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock commonParams:(NSDictionary *)commonParam
{
    TTHttpRequest *request = [super URLRequestWithURL:URL headerField:headField params:params method:method constructingBodyBlock:bodyBlock commonParams:commonParam];
    if (params) {
        NSString *bodyString = [params btd_stringValueForKey:BDXBridgeGraphQLParamKey];
        if (!bodyString) {
            return nil;
        }
        NSData *body = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
        [request setHTTPBody:body];
        [request setValue:@"application/graphql" forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    }
    return request;
}

@end

@implementation BDXBridgeRequestMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeRequestMethod);

- (void)callWithParamModel:(BDXBridgeRequestMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    id<BDXBridgeNetworkServiceProtocol> networkService = bdx_get_service(BDXBridgeNetworkServiceProtocol);
    
    NSString *urlString = paramModel.url;
    NSString *method = paramModel.method;
    NSDictionary *body = paramModel.body;
    NSDictionary *params = paramModel.params;
    NSDictionary *header = paramModel.header;
    
    if (![TTReachability isNetworkConnected]) {
        bdx_invoke_block(completionHandler, nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeNetworkUnreachable message:@"Network is unreachable."]);
        return;
    }
    
    if (urlString.length == 0) {
        bdx_invoke_block(completionHandler, nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"The URL is should not be nil."]);
        return;
    }
    
    if (![self isSupportedMethod:method]) {
        bdx_invoke_block(completionHandler, nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"The HTTP method '%@' is unsupported.", method]);
        return;
    }
    
    BOOL isGetMethod = [method.uppercaseString isEqualToString:@"GET"];
    if (!isGetMethod) {
        if (params.count > 0) {
            urlString = [TTNetworkUtil URLString:urlString appendCommonParams:params];
        }
        if ([body isKindOfClass:NSDictionary.class] && body.count > 0) {
            params = body;
        }
        
        if ([body isKindOfClass:NSString.class]) {
            if (!params) {
                params = [NSDictionary dictionary];
            }
            NSMutableDictionary *newParams = [params mutableCopy];
            newParams[BDXBridgeGraphQLParamKey] = body;
            params = [newParams copy];
        }
    }
    
    // Determine request serializer according to the content-type.
    BOOL isPostMethod = [method.uppercaseString isEqualToString:@"POST"];
    __block Class<TTHTTPRequestSerializerProtocol> requestSerializer = nil;
    __block BOOL isGraphQLRequest = NO;
    if (isPostMethod && params) {
        [header enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
            if ([key isKindOfClass:NSString.class] && [key.lowercaseString isEqualToString:@"content-type"]) {
                if ([obj.lowercaseString containsString:@"application/json"]) {
                    requestSerializer = TTPostDataHttpRequestSerializer.class;
                    *stop = YES;
                } else if ([obj.lowercaseString containsString:@"application/graphql"]) {
                    requestSerializer = BDXBridgeGraphQLRequestSerializer.class;
                    isGraphQLRequest = YES;
                    *stop = YES;
                }
            }
        }];
    }
    if (isGraphQLRequest) {
        if (![body isKindOfClass:NSString.class]) {
            bdx_invoke_block(completionHandler, nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:@"Graphql request body is supposed to be a NSString type."]);
            return;
        }
    }
    
    BDXBridgeRequestCompletionHandler wrappedCompletionHandler = ^(TTHttpResponse *response, id object, NSError *error) {
        BDXBridgeStatusCode statusCode = BDXBridgeStatusCodeSucceeded;
        BDXBridgeRequestMethodResultModel *resultModel = [BDXBridgeRequestMethodResultModel new];
        NSString *message = nil;
        
        if ([object isKindOfClass:NSDictionary.class]) {
            resultModel.httpCode = @(response.statusCode);
            resultModel.header = response.allHeaderFields;
            resultModel.response = object;
        } else if (error) {
            statusCode = BDXBridgeStatusCodeFailed;
            message = [NSString stringWithFormat:@"Failed to request with error [code: %@, description: %@].", @(error.code), error.localizedDescription];
        } else {
            statusCode = BDXBridgeStatusCodeMalformedResponse;
            message = @"The response returned from server is malformed.";
        }
        
        bdx_invoke_block(completionHandler, resultModel, [BDXBridgeStatus statusWithStatusCode:statusCode message:message]);
    };
    
    if ([networkService respondsToSelector:@selector(requestWithParam:completionHandler:)]) {
        BDXBridgeRequestParam *param = [BDXBridgeRequestParam new];
        param.urlString = urlString;
        param.httpMethod = method;
        param.headers = header;
        param.params = params;
        param.needCommonParams = YES;
        param.requestSerializer = requestSerializer;
        param.responseSerializer = nil;
        [networkService requestWithParam:param completionHandler:wrappedCompletionHandler];
    } else {
        bdx_alog_info(@"Use default implementation of '%@' with TTNetworkManager.", self.methodName);
        [TTNetworkManager.shareInstance requestForJSONWithResponse:urlString params:params method:method needCommonParams:YES headerField:header requestSerializer:requestSerializer responseSerializer:nil autoResume:YES callback:^(NSError *error, id obj, TTHttpResponse *response) {
            bdx_invoke_block(wrappedCompletionHandler, response, obj, error);
        }];
    }
}

- (BOOL)isSupportedMethod:(NSString *)method
{
    NSSet<NSString *> *supportedMethods = [NSSet setWithArray:@[
        @"GET",
        @"POST",
        @"DELETE",
        @"PUT",
    ]];
    return [supportedMethods containsObject:[method uppercaseString]];
}

@end
