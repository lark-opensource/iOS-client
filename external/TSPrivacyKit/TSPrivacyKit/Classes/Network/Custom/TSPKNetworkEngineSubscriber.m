//
//  TSPKNetworkEngineSubscriber.m
//  TSPrivacyKit
//
//  Created by admin on 2022/9/2.
//

#import "TSPKNetworkEngineSubscriber.h"
#import "TSPKCommonRequestProtocol.h"
#import "TSPKNetworkEvent.h"
#import "TSPKHandleResult.h"
#import "TSPKThreadPool.h"
#import "TSPKNetworkReporter.h"
#import "TSPKNetworkActionUtil.h"
#import "TSPKNetworkConfigs.h"
#import "TSPKRuleParameterBuilderModel.h"
#import "TSPKNetworkUtil.h"
#import <PNSServiceKit/PNSRuleEngineProtocol.h>
#import <PNSServiceKit/PNSServiceCenter.h>

@implementation TSPKNetworkEngineSubscriber

- (NSString *)uniqueId {
    return @"TSPKNetworkEngineSubscriber";
}

- (BOOL)canHandelEvent:(TSPKEvent *)event {
    return YES;
}

- (TSPKHandleResult *)hanleEvent:(TSPKEvent *)event {
    if (![event isKindOfClass:[TSPKNetworkEvent class]]) {
        return nil;
    }
    TSPKNetworkEvent *networkEvent = (TSPKNetworkEvent *)event;
    
    if ([TSPKNetworkConfigs isAllowEvent:networkEvent]) return nil;
    
    dispatch_async([[TSPKThreadPool shardPool] networkWorkQueue], ^{
        NSDictionary *input = [self convertNetworkModelToParams:networkEvent];
        id<PNSRuleResultProtocol> results = [PNS_GET_INSTANCE(PNSRuleEngineProtocol) validateParams:input];
        if (results.values.count > 0) {
            [self reportWithParams:input results:results networkEvent:networkEvent];
        }
    });
    
    return nil;
}

- (NSDictionary *)convertNetworkModelToParams:(TSPKNetworkEvent *)networkEvent {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"source"] = @"network";
    // common
    dict[@"is_request"] = @(NO);
    dict[@"method"] = networkEvent.request.tspk_util_HTTPMethod ?: @"";
    dict[@"event_type"] = networkEvent.request.tspk_util_eventType ?: @"";
    dict[@"event_source"] = networkEvent.request.tspk_util_eventSource ?: @"";
    dict[@"is_redirect"] = @(networkEvent.request.tspk_util_isRedirect);
    // NSURL
    /// request
    dict[@"domain"] = networkEvent.request.tspk_util_url.host ?: @"";
    dict[@"path"] = [TSPKNetworkUtil realPathFromURL:networkEvent.request.tspk_util_url] ?: @"";
    dict[@"scheme"] = networkEvent.request.tspk_util_url.scheme ?: @"";
    dict[@"url"] = networkEvent.request.tspk_util_url.absoluteString ?: @"";
    /// response
    dict[@"res_domain"] = networkEvent.response.tspk_util_url.host ?: @"";
    dict[@"res_path"] = [TSPKNetworkUtil realPathFromURL:networkEvent.response.tspk_util_url] ?: @"";
    dict[@"res_scheme"] = networkEvent.response.tspk_util_url.scheme ?: @"";
    dict[@"res_url"] = networkEvent.response.tspk_util_url.absoluteString ?: @"";
    // Header
    dict[@"header_keys"] = networkEvent.request.tspk_util_headers.allKeys ?: @[];
    dict[@"res_header_keys"] = networkEvent.response.tspk_util_headers.allKeys ?: @[];
    
    // header additional
    NSString *reqContentType = [networkEvent.request tspk_util_valueForHTTPHeaderField:@"content-type"];
    if (reqContentType) {
        dict[@"content_type"] = reqContentType;
    }
    
    NSString *resContentType = [networkEvent.response tspk_util_valueForHTTPHeaderField:@"content-type"];
    if (resContentType) {
        dict[@"res_content_type"] = resContentType;
    }
    
    NSString *cookie = [networkEvent.request tspk_util_valueForHTTPHeaderField:@"cookie"];
    if (cookie) {
        // cookie
        TSPKRuleParameterBuilderModel *cookieBuilderModel = [TSPKRuleParameterBuilderModel new];
        cookieBuilderModel.key = @"cookie_keys";
        cookieBuilderModel.origin = PNSRuleParameterOriginInput;
        cookieBuilderModel.type = PNSRuleParameterTypeArray;
        cookieBuilderModel.builder = ^NSArray * _Nonnull() {
            return [TSPKNetworkUtil cookieString2MutableDict:cookie].allKeys;
        };
        dict[@"cookie_keys"] = cookieBuilderModel;
    }
    
    NSString *resCookie = [networkEvent.response tspk_util_valueForHTTPHeaderField:@"cookie"];
    if (resCookie) {
        // cookie
        TSPKRuleParameterBuilderModel *resCookieBuilderModel = [TSPKRuleParameterBuilderModel new];
        resCookieBuilderModel.key = @"res_cookie_keys";
        resCookieBuilderModel.origin = PNSRuleParameterOriginInput;
        resCookieBuilderModel.type = PNSRuleParameterTypeArray;
        resCookieBuilderModel.builder = ^NSArray * _Nonnull() {
            // todo code fix
            return [TSPKNetworkUtil cookieString2MutableDict:resCookie].allKeys;
        };
        dict[@"res_cookie_keys"] = resCookieBuilderModel;
    }
    
    // body
    TSPKRuleParameterBuilderModel *dataBuilderModel = [TSPKRuleParameterBuilderModel new];
    dataBuilderModel.key = @"res_content";
    dataBuilderModel.origin = PNSRuleParameterOriginInput;
    dataBuilderModel.type = PNSRuleParameterTypeString;
    dataBuilderModel.builder = ^NSString * _Nonnull() {
        if (networkEvent.responseData) {
            return [[NSString alloc] initWithData:networkEvent.responseData encoding:kCFStringEncodingUTF8];
        }
        return @"";
    };
    dict[@"res_content"] = dataBuilderModel;
    
    // query_keys
    TSPKRuleParameterBuilderModel *queryKeysBuilderModel = [TSPKRuleParameterBuilderModel new];
    queryKeysBuilderModel.key = @"query_keys";
    queryKeysBuilderModel.origin = PNSRuleParameterOriginInput;
    queryKeysBuilderModel.type = PNSRuleParameterTypeArray;
    queryKeysBuilderModel.builder = ^NSArray<NSString *> * _Nonnull() {
        [TSPKNetworkUtil convertQueryToArray:networkEvent.request.tspk_util_url.query];
        NSMutableArray<NSString *> *result = [NSMutableArray array];
        NSArray<NSURLQueryItem *> *queryItems = [TSPKNetworkUtil convertQueryToArray:networkEvent.request.tspk_util_url.query];
        for (NSURLQueryItem *item in queryItems) {
            [result addObject:item.name];
        }
        return result;
    };
    dict[@"query_keys"] = queryKeysBuilderModel;
    
    TSPKRuleParameterBuilderModel *resQueryKeysBuilderModel = [TSPKRuleParameterBuilderModel new];
    resQueryKeysBuilderModel.key = @"res_query_keys";
    resQueryKeysBuilderModel.origin = PNSRuleParameterOriginInput;
    resQueryKeysBuilderModel.type = PNSRuleParameterTypeArray;
    resQueryKeysBuilderModel.builder = ^NSArray<NSString *> * _Nonnull() {
        NSMutableArray<NSString *> *result = [NSMutableArray array];
        NSArray<NSURLQueryItem *> *queryItems = [TSPKNetworkUtil convertQueryToArray:networkEvent.response.tspk_util_url.query];
        for (NSURLQueryItem *item in queryItems) {
            [result addObject:item.name];
        }
        return result;
    };
    dict[@"res_query_keys"] = resQueryKeysBuilderModel;
    
    return dict;
}

- (void)reportWithParams:(NSDictionary *)params results:(id<PNSRuleResultProtocol>)results networkEvent:(TSPKNetworkEvent *)networkEvent{
    NSMutableDictionary *category = params.mutableCopy;
    NSArray<NSString *> *categoryKeys = category.allKeys;
    for (NSString *key in categoryKeys) {
        if ([category[key] conformsToProtocol:@protocol(PNSRuleParameterBuilderModelProtocol)]) {
            [category removeObjectForKey:key];
        }
    }
    
    if (results.usedParameters.count > 0) {
        [category addEntriesFromDictionary:results.usedParameters];
    }
    
    NSMutableArray *hitPolicys = [NSMutableArray array];
    for (id<PNSSingleRuleResultProtocol> result in results.values) {
        [hitPolicys addObject:result.key];
    }
    if (hitPolicys.count > 0) {
        [category setValue:[hitPolicys componentsJoinedByString:@","] forKey:@"monitor_scenes"];
    }
    
    [TSPKNetworkReporter reportWithCommonInfo:category networkEvent:networkEvent];
}

@end
