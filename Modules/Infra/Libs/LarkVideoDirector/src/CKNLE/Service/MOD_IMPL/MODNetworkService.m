//
//  MODNetworkService.m
//  Modeo
//
//  Created by yansong li on 2020/12/28.
//

#import "MODNetworkService.h"

#import <ByteDanceKit/BTDMacros.h>
#import <Mantle/Mantle.h>
#import <TTNetworkManager/TTNetworkManager.h>

#import "MODMacros.h"

static NSArray *highProcessQueueWhiteURLList;

NSString * const MODNetworkServiceParseErrorDomain = @"MODNetworkServiceParseErrorDomain";

@implementation MODNetworkService

#pragma mark - Public Methods

+ (TTHttpTask *)postWithURLString:(NSString * _Nonnull)urlString
                           params:(NSDictionary * _Nullable)params
                       completion:(MODNetworkServiceCompletionBlock _Nullable)block
{
    return [self requestWithURLString:urlString
                               params:params
                               method:@"POST"
                     needCommonParams:YES
                           modelClass:nil
                     targetAttributes:nil
                    requestSerializer:nil
                   responseSerializer:nil
                        responseBlock:nil
                      completionBlock:block];
}


+ (TTHttpTask *)postWithURLString:(NSString * _Nonnull)urlString
                           params:(NSDictionary * _Nullable)params
                       modelClass:(Class _Nullable)objectClass
                       completion:(MODNetworkServiceCompletionBlock _Nullable)block
{
    return [self requestWithURLString:urlString
                               params:params
                               method:@"POST"
                     needCommonParams:YES
                           modelClass:objectClass
                     targetAttributes:nil
                    requestSerializer:nil
                   responseSerializer:nil
                        responseBlock:nil
                      completionBlock:block];
}

+ (TTHttpTask *)postWithURLString:(NSString * _Nonnull)urlString
                           params:(NSDictionary * _Nullable)params
                 needCommonParams:(BOOL)needCommonParams
                       completion:(MODNetworkServiceCompletionBlock _Nullable)block
{
    return [self requestWithURLString:urlString
                               params:params
                               method:@"POST"
                     needCommonParams:needCommonParams
                           modelClass:nil
                     targetAttributes:nil
                    requestSerializer:nil
                   responseSerializer:nil
                        responseBlock:nil
                      completionBlock:block];
}

+ (TTHttpTask *)postWithURLString:(NSString *)urlString
                           params:(NSDictionary *)params
                    responseBlock:(MODNetworkServiceCompletionBlock)responseBlock
                  completionBlock:(MODNetworkServiceCompletionBlock)completionBlock
{
    return [self requestWithURLString:urlString
                               params:params
                               method:@"POST"
                     needCommonParams:YES
                           modelClass:nil
                     targetAttributes:nil
                    requestSerializer:nil
                   responseSerializer:nil
                        responseBlock:responseBlock
                      completionBlock:completionBlock];
}

+ (TTHttpTask *)getWithURLString:(NSString * _Nonnull)urlString
                          params:(NSDictionary * _Nullable)params
                      completion:(MODNetworkServiceCompletionBlock _Nullable)block
{
    return [self requestWithURLString:urlString
                               params:params
                               method:@"GET"
                     needCommonParams:YES
                           modelClass:nil
                     targetAttributes:nil
                    requestSerializer:nil
                   responseSerializer:nil
                        responseBlock:nil
                      completionBlock:block];
}

+ (TTHttpTask *)getWithURLString:(NSString * _Nonnull)urlString
                          params:(NSDictionary * _Nullable)params
                needCommonParams:(BOOL)needCommonParams
                      completion:(MODNetworkServiceCompletionBlock _Nullable)block
{
    return [self requestWithURLString:urlString
                               params:params
                               method:@"GET"
                     needCommonParams:needCommonParams
                           modelClass:nil
                     targetAttributes:nil
                    requestSerializer:nil
                   responseSerializer:nil
                        responseBlock:nil
                      completionBlock:block];
}


+ (TTHttpTask *)getWithURLString:(NSString * _Nonnull)urlString
                          params:(NSDictionary *)params
                   responseBlock:(MODNetworkServiceCompletionBlock)responseBlock
                 completionBlock:(MODNetworkServiceCompletionBlock)block
{
    return [self requestWithURLString:urlString
                               params:params
                               method:@"GET"
                     needCommonParams:YES
                           modelClass:nil
                     targetAttributes:nil
                    requestSerializer:nil
                   responseSerializer:nil
                        responseBlock:responseBlock
                      completionBlock:block];
}



+ (TTHttpTask *)getWithURLString:(NSString * _Nonnull)urlString
                          params:(NSDictionary * _Nullable)params
                      modelClass:(Class _Nullable)objectClass
                      completion:(MODNetworkServiceCompletionBlock _Nullable)block
{
    return [self requestWithURLString:urlString
                               params:params
                               method:@"GET"
                     needCommonParams:YES
                           modelClass:objectClass
                     targetAttributes:nil
                    requestSerializer:nil
                   responseSerializer:nil
                        responseBlock:nil
                      completionBlock:block];
}

+ (TTHttpTask *)requestWithURLString:(NSString *)urlString
                              params:(NSDictionary * _Nullable)params
                              method:(NSString *)method
                    needCommonParams:(BOOL)needCommonParams
                          modelClass:(Class _Nullable)objectClass
                    targetAttributes:(NSArray<NSString *> * _Nullable)targetAttributes
                             timeout:(NSTimeInterval)timeout
                  responseSerializer:(Class<TTJSONResponseSerializerProtocol> _Nullable)responseSerializer
                       responseBlock:(MODNetworkServiceCompletionBlock _Nullable)responseBlock
                     completionBlock:(MODNetworkServiceCompletionBlock _Nullable)completionBlock
{
    return [self requestWithURLString:urlString
                               params:params
                               method:method
                     needCommonParams:needCommonParams
                           modelClass:objectClass
                     targetAttributes:targetAttributes
                    requestSerializer:nil
                   responseSerializer:responseSerializer
                        responseBlock:responseBlock
                      completionBlock:completionBlock];
}

+ (TTHttpTask *)requestWithURLString:(NSString *)urlString
                              params:(NSDictionary * _Nullable)params
                              method:(NSString *)method
                    needCommonParams:(BOOL)needCommonParams
                          modelClass:(Class _Nullable)objectClass
                    targetAttributes:(NSArray<NSString *> * _Nullable)targetAttributes
                   requestSerializer:(Class<TTHTTPRequestSerializerProtocol> _Nullable)requestSerializer
                  responseSerializer:(Class<TTJSONResponseSerializerProtocol> _Nullable)responseSerializer
                       responseBlock:(MODNetworkServiceCompletionBlock _Nullable)responseBlock
                     completionBlock:(MODNetworkServiceCompletionBlock _Nullable)completionBlock
{
    return [self requestWithURLString:urlString
                               params:params
                               method:method
                     needCommonParams:needCommonParams
                               header:nil
                           modelClass:objectClass
                     targetAttributes:targetAttributes
                    requestSerializer:requestSerializer
                   responseSerializer:responseSerializer
                        responseBlock:responseBlock
                      completionBlock:completionBlock];
}

+ (TTHttpTask *)requestWithURLString:(NSString *)urlString
                              params:(NSDictionary * _Nullable)params
                              method:(NSString *)method
                    needCommonParams:(BOOL)needCommonParams
                              header:(NSDictionary * _Nullable)header
                          modelClass:(Class _Nullable)objectClass
                    targetAttributes:(NSArray<NSString *> * _Nullable)targetAttributes
                   requestSerializer:(Class<TTHTTPRequestSerializerProtocol> _Nullable)requestSerializer
                  responseSerializer:(Class<TTJSONResponseSerializerProtocol> _Nullable)responseSerializer
                       responseBlock:(MODNetworkServiceCompletionBlock _Nullable)responseBlock
                     completionBlock:(MODNetworkServiceCompletionBlock _Nullable)completionBlock
{
    return [self requestWithURLString:urlString
                               params:params
                               method:method
                     needCommonParams:needCommonParams
                               header:header
                           modelClass:objectClass
                     targetAttributes:targetAttributes
                    requestSerializer:requestSerializer
                   responseSerializer:responseSerializer
                        responseBlock:responseBlock
                          enableCache:NO
                      completionBlock:completionBlock];
}

+ (TTHttpTask *)requestWithURLString:(NSString *)urlString
                              params:(NSDictionary * _Nullable)params
                              method:(NSString *)method
                    needCommonParams:(BOOL)needCommonParams
                              header:(NSDictionary * _Nullable)header
                          modelClass:(Class _Nullable)objectClass
                    targetAttributes:(NSArray<NSString *> * _Nullable)targetAttributes
                   requestSerializer:(Class<TTHTTPRequestSerializerProtocol> _Nullable)requestSerializer
                  responseSerializer:(Class<TTJSONResponseSerializerProtocol> _Nullable)responseSerializer
                       responseBlock:(MODNetworkServiceCompletionBlock _Nullable)responseBlock
                         enableCache:(BOOL)enableCache
                     completionBlock:(MODNetworkServiceCompletionBlock _Nullable)completionBlock
{
    return (TTHttpTask *)[self _requestWithURLString:urlString
                                              params:params
                                              method:method
                                    needCommonParams:needCommonParams
                                              header:header
                                          modelClass:objectClass
                                    targetAttributes:targetAttributes
                                   requestSerializer:requestSerializer
                                  responseSerializer:responseSerializer
                                       responseBlock:responseBlock
                                         enableCache:enableCache
                                     completionBlock:completionBlock];
}

#pragma mark - Private Methods



+ (TTHttpTask *)_requestWithURLString:(NSString *)urlString
                               params:(NSDictionary *)params
                               method:(NSString *)method
                     needCommonParams:(BOOL)needCommonParams
                               header:(NSDictionary *)header
                           modelClass:(Class)objectClass
                     targetAttributes:(NSArray<NSString *> *)targetAttributes
                    requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                   responseSerializer:(Class<TTJSONResponseSerializerProtocol>)responseSerializer
                        responseBlock:(MODNetworkServiceCompletionBlock)responseBlock
                          enableCache:(BOOL)enableCache
                      completionBlock:(MODNetworkServiceCompletionBlock)completionBlock
{
    __block dispatch_queue_t callbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    [highProcessQueueWhiteURLList enumerateObjectsUsingBlock:^(NSString * _Nonnull keywords, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([urlString containsString:keywords]) {
            callbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        }
    }];
    return [[TTNetworkManager shareInstance] requestForJSONWithResponse:urlString
                                                                 params:params
                                                                 method:method
                                                       needCommonParams:needCommonParams
                                                            headerField:header
                                                      requestSerializer:requestSerializer
                                                     responseSerializer:responseSerializer
                                                             autoResume:YES
                                                          verifyRequest:NO
                                                     isCustomizedCookie:NO
                                                               callback:^(NSError *error, id jsonObj, TTHttpResponse *response) {
        if (enableCache && !error) {
            // TODO(modeo): cache
        }
        if (responseBlock) {
            btd_dispatch_async_on_main_queue(^{
                MODBLOCK_INVOKE(responseBlock, jsonObj, error);
            });
        }
        @autoreleasepool {
            [self processJsonObject:jsonObj URL:urlString error:error modelClass:objectClass targetAttributes:targetAttributes completion:completionBlock];
        }
                                                                        }
                                                          callbackQueue:callbackQueue];
}

+ (void)processJsonObject:(id)jsonObj
                      URL:(NSString *)URL
                    error:(NSError *)error
               modelClass:(Class)objectClass
         targetAttributes:(NSArray<NSString *> *)targetAttributes
               completion:(MODNetworkServiceCompletionBlock)block
{
    if (jsonObj == nil || ![jsonObj isKindOfClass:[NSDictionary class]]) {
        if (block) {
            block(nil, error);
        }
        // TODO(modeo)
        //NSError *customError = [NSError errorWithDomain:error.domain code:error.code userInfo:error.userInfo];
        //AWELogInfraError(@"invalide reuqest response, %@", customError.description ?: @"");
        return;
    }
    
    // 找到指定的数据
    if (targetAttributes) {
        for (NSString *attribute in targetAttributes) {
            if (![jsonObj objectForKey:attribute]) {
                if (block) {
                    NSError *parseError = [[NSError alloc] initWithDomain:MODNetworkServiceParseErrorDomain
                                                                     code:MODNetworkServiceErrorTypeAttribute
                                                                 userInfo:error.userInfo];
                    block(nil, parseError);
                }
                return;
            }
            jsonObj = [jsonObj objectForKey:attribute];
        }
        NSMutableDictionary *temp = [jsonObj mutableCopy];
        jsonObj = [temp copy];
    }
    
    // 没有模型：直接返回原始数据
    if (!objectClass) {
        if (block) {
            block(jsonObj, error);
        }
        return;
    }
    
    // 模型化
    __autoreleasing NSError *mappingError = nil;
    id response = [MTLJSONAdapter modelOfClass:objectClass
                            fromJSONDictionary:jsonObj
                                         error:&mappingError];

    if (mappingError) {
        NSMutableDictionary *userInfo = @{}.mutableCopy;
        if (error.userInfo) {
            [userInfo addEntriesFromDictionary:error.userInfo];
        }
        
        if (mappingError.userInfo) {
            [userInfo addEntriesFromDictionary:mappingError.userInfo];
        }
        NSError *resultError = [[NSError alloc] initWithDomain:mappingError.domain
                                                          code:mappingError.code
                                                      userInfo:userInfo];
        
        if (block) {
            block(nil, resultError);
        }
        return;
    }
    
    if ([response isKindOfClass:AWEBaseApiModel.class]) {
        [response mergeAllPropertyKeysWithRequestId];
        [response mergeAllPropertyKeysWithLogPassback];
    }
    
    // 成功
    if (block) {
        block(response, error);
    }
}

@end
