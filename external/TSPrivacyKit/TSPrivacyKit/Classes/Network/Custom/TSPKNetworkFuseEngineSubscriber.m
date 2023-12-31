//
//  TSPKNetworkSyncEngineSubscriber.m
//  TSPrivacyKit
//
//  Created by admin on 2022/8/24.
//

#import "TSPKNetworkFuseEngineSubscriber.h"
#import "TSPKNetworkEvent.h"
#import "TSPKNetworkActionUtil.h"
#import "TSPKHandleResult.h"
#import "TSPKNetworkReporter.h"
#import "TSPKNetworkConfigs.h"
#import "TSPKNetworkUtil.h"
#import "TSPKUtils.h"
#import "TSPKRuleParameterBuilderModel.h"
#import <PNSServiceKit/PNSRuleEngineProtocol.h>
#import <PNSServiceKit/PNSServiceCenter.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

static NSString *_Nonnull TSPKNetworkActionsKey = @"actions";

@implementation TSPKNetworkFuseEngineSubscriber

- (NSString *)uniqueId {
    return @"TSPKNetworkSyncEngineSubscriber";
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
    
    NSDictionary *input = [self convertRequestToParams:networkEvent.request];
    id<PNSRuleResultProtocol> results = [PNS_GET_INSTANCE(PNSRuleEngineProtocol) validateParams:input];
    
    NSMutableDictionary *mergeActions = [NSMutableDictionary dictionary];
    NSMutableArray<NSString *> *reportRules = [NSMutableArray array];
    TSPKHandleResult *returnObj = [TSPKHandleResult new];
    NSMutableDictionary<NSString *, NSDictionary *> *modifyConfCheckedDict = [NSMutableDictionary dictionary];
    
    if (results.values.count > 0) {
        for (id<PNSSingleRuleResultProtocol> singleRuleResult in results.values) {
            NSInteger action = [TSPKNetworkActionUtil merge:singleRuleResult.conf store:mergeActions];
            if (action == TSPKNetworkActionTypeFuse) {
                [TSPKNetworkActionUtil doActions:mergeActions request:networkEvent.request actionType:TSPKNetworkActionTypeFuse];
                [self reportWithParams:input hitActions:nil results:results singleRuleResult:singleRuleResult actionType:TSPKNetworkActionTypeFuse networkEvent:networkEvent modifyConfCheckedDict:nil reportRules:nil];
                returnObj.action = TSPKResultActionFuse;
                return returnObj;
            }
            
            if (action == TSPKNetworkActionTypeModify) {
                BOOL needCheckModifyConfig = [singleRuleResult.conf[@"check_modify_config_hit"] boolValue];
                if (needCheckModifyConfig) {
                    [modifyConfCheckedDict setValue:[singleRuleResult.conf btd_dictionaryValueForKey:@"modify_config"] forKey:singleRuleResult.key];
                }
            } else if (action == TSPKNetworkActionTypeReport) {
                [reportRules addObject:singleRuleResult.key];
            }
        }
    }
    
    if (mergeActions.count > 0) {
        NSArray<TSPKNetworkOperateHistory *> *hitActions = [TSPKNetworkActionUtil doActions:mergeActions request:networkEvent.request actionType:TSPKNetworkActionTypeModify];
        if (hitActions.count > 0 || reportRules.count > 0) {
            [self reportWithParams:input hitActions:hitActions results:results singleRuleResult:nil actionType:TSPKNetworkActionTypeModify networkEvent:networkEvent modifyConfCheckedDict:modifyConfCheckedDict reportRules:reportRules];
        }
    } else if (reportRules.count > 0) {
        [self reportWithParams:input hitActions:nil results:results singleRuleResult:nil actionType:TSPKNetworkActionTypeReport networkEvent:networkEvent modifyConfCheckedDict:nil reportRules:reportRules];
    }
    
    return nil;
}

- (NSDictionary *)convertRequestToParams:(id<TSPKCommonRequestProtocol>)request {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"source"] = @"network_fuse";
    // common
    dict[@"is_request"] = @(YES);
    dict[@"event_type"] = request.tspk_util_eventType ?: @"";
    dict[@"event_source"] = request.tspk_util_eventSource ?: @"";
    dict[@"method"] = request.tspk_util_HTTPMethod ?: @"";
    dict[@"is_redirect"] = @(request.tspk_util_isRedirect);
    // NSURL
    dict[@"domain"] = request.tspk_util_url.host ?: @"";
    dict[@"path"] = [TSPKNetworkUtil realPathFromURL:request.tspk_util_url] ?: @"";
    dict[@"scheme"] = request.tspk_util_url.scheme ?: @"";
    dict[@"url"] = request.tspk_util_url.absoluteString ?: @"";
    
    // body
    id<PNSRuleParameterBuilderModelProtocol> bodyBuilderModel = [TSPKRuleParameterBuilderModel new];
    bodyBuilderModel.key = @"json_body";
    bodyBuilderModel.origin = PNSRuleParameterOriginInput;
    bodyBuilderModel.type = PNSRuleParameterTypeString;
    bodyBuilderModel.builder = ^NSString * _Nonnull() {
        if (![TSPKNetworkConfigs canReportJsonBody]) {
            return @"";
        }
        NSData *data = nil;
        if (request.tspk_util_HTTPBody) {
            data = request.tspk_util_HTTPBody;
        } else if (request.tspk_util_HTTPBodyStream) {
            data = [TSPKNetworkUtil bodyStream2Data:request.tspk_util_HTTPBodyStream];
        }
        if (data) {
            id dataJsonStruct = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            if (dataJsonStruct) {
                id value = [TSPKUtils parseJsonStruct:dataJsonStruct];
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:value options:NSJSONWritingPrettyPrinted error:nil];
                return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            }
        }
        return @"";
    };
    dict[@"json_body"] = bodyBuilderModel;
    
    // query_keys
    id<PNSRuleParameterBuilderModelProtocol> queryKeysBuilderModel = [TSPKRuleParameterBuilderModel new];
    queryKeysBuilderModel.key = @"query_keys";
    queryKeysBuilderModel.origin = PNSRuleParameterOriginInput;
    queryKeysBuilderModel.type = PNSRuleParameterTypeArray;
    queryKeysBuilderModel.builder = ^NSArray<NSString *> * _Nonnull() {
        NSMutableArray<NSString *> *result = [NSMutableArray array];
        NSArray<NSURLQueryItem *> *queryItems = [TSPKNetworkUtil convertQueryToArray:request.tspk_util_url.query];
        for (NSURLQueryItem *item in queryItems) {
            [result addObject:item.name];
        }
        return result;
    };
    dict[@"query_keys"] = queryKeysBuilderModel;
    
    // Header
    dict[@"header_keys"] = request.tspk_util_headers.allKeys;
    
    // header additional
    NSString *contentType = [request tspk_util_valueForHTTPHeaderField:@"content-type"];
    if (contentType) {
        dict[@"content_type"] = contentType;
    }
    
    NSString *cookie = [request tspk_util_valueForHTTPHeaderField:@"cookie"];
    if (cookie) {
        TSPKRuleParameterBuilderModel *cookieBuilderModel = [TSPKRuleParameterBuilderModel new];
        cookieBuilderModel.key = @"cookie_keys";
        cookieBuilderModel.origin = PNSRuleParameterOriginInput;
        cookieBuilderModel.type = PNSRuleParameterTypeArray;
        cookieBuilderModel.builder = ^NSArray * _Nonnull() {
            return [TSPKNetworkUtil cookieString2MutableDict:cookie].allKeys;
        };
        dict[@"cookie_keys"] = cookieBuilderModel;
    }
    
    return dict;
}

- (void)reportWithParams:(NSDictionary *)params
              hitActions:(NSArray<TSPKNetworkOperateHistory *> *)hitActions
                 results:(id<PNSRuleResultProtocol>)results
        singleRuleResult:(id<PNSSingleRuleResultProtocol>)singleRuleResult
              actionType:(NSInteger)actionType
            networkEvent:(TSPKNetworkEvent *)networkEvent
   modifyConfCheckedDict:(NSDictionary *)modifyConfCheckedDict
             reportRules:(NSArray<NSString *> *)reportRules {
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
    
    if (hitActions.count > 0) {
        NSMutableString *hitActionsString = [[NSMutableString alloc] initWithString:@""];
        for (TSPKNetworkOperateHistory *history in hitActions) {
            [hitActionsString appendFormat:@"%@, ", [history format2String]];
        }
        [hitActionsString appendString:@"]"];
        [category setValue:hitActionsString forKey:@"operate_history"];
    }
    
    
    if (actionType == TSPKNetworkActionTypeFuse) {
        [category setValue:@[singleRuleResult.key] forKey:@"monitor_scenes"];
    } else if (actionType == TSPKNetworkActionTypeModify) {
        // do it when action type is modify
        NSArray *hitPolicys = [self checkHitPoilcy:results modifyConfCheckedDict:modifyConfCheckedDict hitActions:hitActions];
        [category setValue:hitPolicys forKey:@"monitor_scenes"];
    } else if (actionType == TSPKNetworkActionTypeReport) {
        [category setValue:reportRules forKey:@"monitor_scenes"];
    }
    
    [category setValue:[self actionStrFromActionType:actionType] forKey:@"action"];
    
    [TSPKNetworkReporter reportWithCommonInfo:category networkEvent:networkEvent];
}

- (NSString *)actionStrFromActionType:(TSPKResultAction)actionType {
    switch(actionType) {
        case TSPKResultActionFuse: return @"fuse";
        case TSPKNetworkActionTypeModify: return @"modify";
        default: return @"report";
    }
}

- (NSArray<NSString *> *)checkHitPoilcy:(id<PNSRuleResultProtocol>)results
                  modifyConfCheckedDict:(NSDictionary *)modifyConfCheckedDict
                             hitActions:(NSArray<TSPKNetworkOperateHistory *> *)hitActions {
    NSMutableArray<NSString *> *hitPolicys = [NSMutableArray array];
    for (id<PNSSingleRuleResultProtocol> result in results.values) {
        NSDictionary *modifyConfig = [modifyConfCheckedDict btd_dictionaryValueForKey:result.key];
        if (modifyConfig == nil) {
            [hitPolicys addObject:result.key];
            continue;
        }
        // {"query": {"remove": [], "replace": {}}}
        [modifyConfig enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull outterKey, id  _Nonnull outterObj, BOOL * _Nonnull outterStop) {
            __block BOOL isHit = NO;
            if ([outterObj isKindOfClass:[NSDictionary class]]) {
                // {"remove": [], "replace": {}}
                [outterObj enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull actionKey, id  _Nonnull actionObj, BOOL * _Nonnull actionStop) {
                    [hitActions enumerateObjectsUsingBlock:^(TSPKNetworkOperateHistory * _Nonnull innerObj, NSUInteger inneridx, BOOL * _Nonnull innerStop) {
                        if ([innerObj.target isEqualToString:outterKey]) {
                            if ([actionKey isEqualToString:@"remove"]) {
                                NSArray *actionArray = [outterObj btd_arrayValueForKey:actionKey];
                                for (TSPKNetworkOperatePair *pair in innerObj.pairs) {
                                    isHit = [actionArray containsObject:pair.originKey];
                                    * innerStop = isHit;
                                    if (isHit) break;
                                }
                            } else if ([actionKey isEqualToString:@"add"] || [actionKey isEqualToString:@"replace"]) {
                                NSDictionary *actionDict = [outterObj btd_dictionaryValueForKey:actionKey];
                                for (TSPKNetworkOperatePair *pair in innerObj.pairs) {
                                    isHit = actionDict[pair.changedKey] != nil;
                                    * innerStop = isHit;
                                    if (isHit) break;
                                }
                            }
                        }
                        if (isHit) {
                            [hitPolicys addObject:result.key];
                            *actionStop = isHit;
                            *outterStop = isHit;
                        }
                    }];
                }];
            }
        }];
    }
    return hitPolicys;
}

@end
