//
//  TSPKNetworkActionUtil.m
//  TSPrivacyKit
//
//  Created by admin on 2022/8/24.
//

#import "TSPKNetworkActionUtil.h"
#import "TSPKCommonRequestProtocol.h"
#import "TSPKNetworkHostEnvProtocol.h"
#import "TSPKNetworkReporter.h"
#import "TSPKNetworkUtil.h"
#import <PNSServiceKit/PNSMonitorProtocol.h>
#import <PNSServiceKit/PNSServiceCenter.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>

static NSString *TSPKNetworkAction = @"action";
static NSString *TSPKNetworkActionFuse = @"fuse";
static NSString *TSPKNetworkActionModify = @"modify";
static NSString *TSPKNetworkActionReport = @"report";
static NSString *TSPKNetworkActionDictRemove = @"remove";
static NSString *TSPKNetworkActionDictAdd = @"add";
static NSString *TSPKNetworkActionDictReplace = @"replace";

@implementation TSPKNetworkOperateHistory

+ (instancetype)initWithTarget:(NSString *)target operate:(NSString *)operate {
    TSPKNetworkOperateHistory *history = [TSPKNetworkOperateHistory new];
    history.target = target;
    history.operate = operate;
    history.pairs = [NSMutableArray array];
    return history;
}

- (NSString *)format2String {
    NSMutableString *pairString = [[NSMutableString alloc] initWithString:@""];
    for (TSPKNetworkOperatePair *pair in self.pairs) {
        [pairString appendFormat:@"%@, ", [pair format2String]];
    }
    
    return [NSString stringWithFormat:@"{\"target\": \"%@\", \"operate\": \"%@\", \"pairs\": [%@]}", self.target, self.operate, pairString];
}

@end

@implementation TSPKNetworkOperatePair

+ (instancetype)initWithOriginKey:(NSString *)originKey changedKey:(NSString *)changedKey {
    TSPKNetworkOperatePair *result = [TSPKNetworkOperatePair new];
    result.originKey = originKey;
    result.changedKey = changedKey;
    return result;
}

- (NSString *)format2String {
    return [[NSString alloc] initWithFormat:@"\"{originKey\": %@, \"changedKey\": %@}", self.originKey, self.changedKey];
}

@end

@implementation TSPKNetworkActionUtil

+ (NSArray *)arrayOfSameStructInModifyConfig {
    return @[@"header", @"query", @"cookie", @"scheme", @"domain", @"path"];
}

/**
 merge confs to conf store, the structure is shown below
 {
 "header/query/cookie": {
 "remove": [key1, key2]
 "add": {key1: value1, key2: value2}
 "replace": {key1: {value: value1, target: "key/value"}, key2: {value: value2, target: "key/value"}}
 }
 **/
+ (NSInteger)merge:(NSDictionary *)source store:(NSMutableDictionary *)store {
    NSInteger result = TSPKNetworkActionTypeNone;
    NSString *action = [source btd_stringValueForKey:TSPKNetworkAction];
    // if action is fuse, remove all info, and save fuse config
    if ([action isEqualToString:TSPKNetworkActionFuse]) {
        [store removeAllObjects];
        // get all info from fuse_config
        NSDictionary *fuseConfig = [source btd_dictionaryValueForKey:@"fuse_config"];
        [store addEntriesFromDictionary:fuseConfig];
        return TSPKNetworkActionTypeFuse;
    } else if ([action isEqualToString:TSPKNetworkActionModify]) {
        result = TSPKNetworkActionTypeModify;
        NSDictionary *modifyConfig = [source btd_dictionaryValueForKey:@"modify_config"];
        for (NSString *sourceKey in modifyConfig.allKeys) {
            // cookie / query / header
            if ([[self arrayOfSameStructInModifyConfig] containsObject:sourceKey]) {
                
                id dictStoreObj = store[sourceKey];
                if (dictStoreObj == nil) {
                    dictStoreObj = [NSMutableDictionary dictionary];
                }
                
                if ([dictStoreObj isKindOfClass:[NSMutableDictionary class]]) {
                    store[sourceKey] = [self headerQueryCookieTargetAction:[modifyConfig btd_dictionaryValueForKey:sourceKey] store:(NSMutableDictionary *)dictStoreObj];
                }
            }
        }
    } else if ([action isEqualToString:TSPKNetworkActionReport]) {
        return TSPKNetworkActionTypeReport;
    }
    
    return result;
}

+ (NSDictionary *)headerQueryCookieTargetAction:(NSDictionary *)target store:(NSMutableDictionary *)store {
    for (NSString *key in target.allKeys) {
        if ([key isEqualToString:@"remove"]) {
            id storeRemoveObj = store[key];
            if (storeRemoveObj == nil) {
                storeRemoveObj = [NSMutableArray array];
            }
            
            if ([storeRemoveObj isKindOfClass:[NSMutableArray class]]) {
                NSMutableArray *storeRemoveArray = (NSMutableArray *)storeRemoveObj;
                NSArray *removeArray = [target btd_arrayValueForKey:key];
                [storeRemoveArray addObjectsFromArray:removeArray];
                
                store[key] = storeRemoveArray;
            }
        }
        
        if ([key isEqualToString:@"add"]) {
            id storeAddObj = store[key];
            if (storeAddObj == nil) {
                storeAddObj = [NSMutableDictionary dictionary];
            }
            
            if ([storeAddObj isKindOfClass:[NSMutableDictionary class]]) {
                NSMutableDictionary *storeAddDict = (NSMutableDictionary *)storeAddObj;
                NSDictionary *addDict = [target btd_dictionaryValueForKey:key];
                [storeAddDict addEntriesFromDictionary:addDict];
                
                store[key] = storeAddDict;
            }
        }
        
        if ([key isEqualToString:@"replace"]) {
            id storeReplaceObj = store[key];
            if (storeReplaceObj == nil) {
                storeReplaceObj = [NSMutableDictionary dictionary];
            }
            
            if ([storeReplaceObj isKindOfClass:[NSMutableDictionary class]]) {
                NSMutableDictionary *storeReplaceDict = (NSMutableDictionary *)storeReplaceObj;
                NSDictionary *replaceDict = [target btd_dictionaryValueForKey:key];
                [storeReplaceDict addEntriesFromDictionary:replaceDict];
                
                store[key] = storeReplaceDict;
            }
        }
    }
    return store;
}

/**
 1. if action type is fuse, drop it and return without any useless action.
 2. if action type is modify, modify it by merged modify_config.the structure is shown below
 {
 "header/query/cookie": {
 "remove": [key1, key2]
 "add": {key1: value1, key2: value2}
 "replace": {key1: {value: value1, target: "key/value"}, key2: {value: value2, target: "key/value"}}
 }
 modify priority: remove > replace > add
 **/
+ (NSArray<TSPKNetworkOperateHistory *> *)doActions:(NSDictionary *)actions request:(id<TSPKCommonRequestProtocol>)request actionType:(NSInteger)actionType {
    if (actionType == TSPKNetworkActionTypeFuse) {
        // abandon other actions, if request need to be dropped
        [request tspk_util_doDrop:actions];
        return nil;
    }
    
    NSMutableArray<TSPKNetworkOperateHistory *> *operateHistory = [NSMutableArray array];
    
    // url
    [self checkURL:request actions:actions store:operateHistory];
    
    // header
    NSDictionary *headerAction = [actions btd_dictionaryValueForKey:@"header"];
    if (headerAction != nil) {
        CFTimeInterval calledTime = CFAbsoluteTimeGetCurrent();
        [self checkHeader:request actions:headerAction store:operateHistory];
        [TSPKNetworkReporter perfWithName:@"modify_header" calledTime:calledTime];
    }
    
    // cookie
    NSDictionary *cookieAction = [actions btd_dictionaryValueForKey:@"cookie"];
    NSString *cookieString = [request tspk_util_valueForHTTPHeaderField:@"cookie"];
    if (cookieAction != nil && cookieString.length > 0) {
        CFTimeInterval calledTime = CFAbsoluteTimeGetCurrent();
        [self checkCookie:request cookieString:cookieString actions:cookieAction store:operateHistory];
        [TSPKNetworkReporter perfWithName:@"modify_cookie" calledTime:calledTime];
    }
    return operateHistory;
}

+ (void)checkURL:(id<TSPKCommonRequestProtocol>)request actions:(NSDictionary *)actions store:(NSMutableArray *)store {
    NSString *scheme = request.tspk_util_url.scheme;
    NSString *host = request.tspk_util_url.host;
    NSString *path = request.tspk_util_url.path;
    NSString *query = request.tspk_util_url.query;
    
    BOOL isModify = NO;
    
    // scheme
    NSDictionary *schemeAction = [actions btd_dictionaryValueForKey:@"scheme"];
    if (schemeAction) {
        CFTimeInterval calledTime = CFAbsoluteTimeGetCurrent();
        NSString *schemeTmp = [self replaceScheme:scheme actions:schemeAction store:store];
        if (![scheme isEqualToString:schemeTmp]) {
            scheme = schemeTmp;
            [TSPKNetworkReporter perfWithName:@"modify_scheme" calledTime:calledTime];
            isModify = YES;
        }
    }
    
    // domain
    NSDictionary *domainAction = [actions btd_dictionaryValueForKey:@"domain"];
    if (domainAction) {
        CFTimeInterval calledTime = CFAbsoluteTimeGetCurrent();
        NSString *hostTmp = [self replaceDomain:host actions:domainAction store:store];
        if (![host isEqualToString:hostTmp]) {
            host = hostTmp;
            [TSPKNetworkReporter perfWithName:@"modify_domain" calledTime:calledTime];
            isModify = YES;
        }
    }
    
    // path
    NSDictionary *pathAction = [actions btd_dictionaryValueForKey:@"path"];
    if (pathAction && path.length > 0) {
        isModify = YES;
        CFTimeInterval calledTime = CFAbsoluteTimeGetCurrent();
        NSString *pathTmp = [self replacePath:path actions:pathAction store:store];
        if (![path isEqualToString:pathTmp]) {
            path = pathTmp;
            [TSPKNetworkReporter perfWithName:@"modify_path" calledTime:calledTime];
            isModify = YES;
        }
    }
    
    // query
    NSDictionary *queryAction = [actions btd_dictionaryValueForKey:@"query"];
    if (queryAction && query.length > 0) {
        CFTimeInterval calledTime = CFAbsoluteTimeGetCurrent();
        NSString *queryTmp = [self checkQuery:query actions:queryAction store:store];
        if (![query isEqualToString:queryTmp]) {
            query = queryTmp;
            [TSPKNetworkReporter perfWithName:@"modify_query" calledTime:calledTime];
            isModify = YES;
        }
    }
    
    if (isModify && [scheme hasPrefix:@"http"]) {
        [request setTspk_util_url:[TSPKNetworkUtil URLWithURLString:[NSString stringWithFormat:@"%@%@%@%@",
                                                                     (scheme == nil || scheme.length == 0) ? @"" : [NSString stringWithFormat:@"%@://", scheme],
                                                                     host,
                                                                     path,
                                                                     (query == nil || query.length == 0) ? @"" : [NSString stringWithFormat:@"?%@", query]]]];
    }
}

+ (NSString *)replaceScheme:(NSString *)scheme actions:(NSDictionary *)actions store:(NSMutableArray *)store {
    NSDictionary *replaceDict = [actions btd_dictionaryValueForKey:@"replace"];
    NSString *newScheme = [[replaceDict btd_dictionaryValueForKey:scheme] btd_stringValueForKey:@"value"];
    if (newScheme) {
        TSPKNetworkOperateHistory *replaceHistory = [TSPKNetworkOperateHistory initWithTarget:@"scheme" operate:@"replace"];
        [replaceHistory.pairs addObject:[TSPKNetworkOperatePair initWithOriginKey:scheme changedKey:newScheme]];
        [store addObject:replaceHistory];
        return newScheme;
    }
    return scheme;
}

+ (NSString *)replaceDomain:(NSString *)domain actions:(NSDictionary *)actions store:(NSMutableArray *)store {
    NSDictionary *replaceDict = [actions btd_dictionaryValueForKey:@"replace"];
    NSString *newDomain = [[replaceDict btd_dictionaryValueForKey:domain] btd_stringValueForKey:@"value"];
    if (newDomain) {
        TSPKNetworkOperateHistory *replaceHistory = [TSPKNetworkOperateHistory initWithTarget:@"domain" operate:@"replace"];
        [replaceHistory.pairs addObject:[TSPKNetworkOperatePair initWithOriginKey:domain changedKey:newDomain]];
        [store addObject:replaceHistory];
        return newDomain;
    }
    return domain;
}

+ (NSString *)replacePath:(NSString *)path actions:(NSDictionary *)actions store:(NSMutableArray *)store {
    NSDictionary *replaceDict = [actions btd_dictionaryValueForKey:@"replace"];
    NSString *newPath = [[replaceDict btd_dictionaryValueForKey:path] btd_stringValueForKey:@"value"];
    if (newPath) {
        TSPKNetworkOperateHistory *replaceHistory = [TSPKNetworkOperateHistory initWithTarget:@"path" operate:@"replace"];
        [replaceHistory.pairs addObject:[TSPKNetworkOperatePair initWithOriginKey:path changedKey:newPath]];
        [store addObject:replaceHistory];
        return newPath;
    }
    return path;
}

+ (NSString *)checkQuery:(NSString *)query actions:(NSDictionary *)actions store:(NSMutableArray *)store {
    NSArray<NSURLQueryItem *> *queryItems = [TSPKNetworkUtil convertQueryToArray:query];
    if (queryItems.count <= 0) {
        return @"";
    }
    
    NSMutableArray *items = [queryItems mutableCopy];
    
    NSDictionary *replaceDict = [actions btd_dictionaryValueForKey:@"replace"];
    NSArray *removeDict = [actions btd_arrayValueForKey:@"remove"];
    
    // add
    TSPKNetworkOperateHistory *addHistory = [TSPKNetworkOperateHistory initWithTarget:@"query" operate:@"add"];
    [[actions btd_dictionaryValueForKey:@"add"] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isKindOfClass:[NSString class]] && ![items containsObject:key] && [obj isKindOfClass:[NSString class]]) {
            id newValue = [self getValueFromAppContextByKey:obj];
            if (newValue && [newValue isKindOfClass:[NSString class]]) {
                [addHistory.pairs addObject:[TSPKNetworkOperatePair initWithOriginKey:nil changedKey:key]];
                NSURLQueryItem *item = [NSURLQueryItem queryItemWithName:key value:newValue];
                [items addObject:item];
            }
        }
    }];
    
    TSPKNetworkOperateHistory *removeHistory = [TSPKNetworkOperateHistory initWithTarget:@"query" operate:@"remove"];
    TSPKNetworkOperateHistory *replaceHistory = [TSPKNetworkOperateHistory initWithTarget:@"query" operate:@"replace"];
    for (NSURLQueryItem *item in items.copy) {
        // 1. replace
        if (replaceDict[item.name]) {
            NSDictionary *value = (NSDictionary *)replaceDict[item.name];
            NSString *target = [value btd_stringValueForKey:@"target"];
            NSString *newValue = [self getValueFromAppContextByKey:[value btd_stringValueForKey:@"value"]];
            NSString *oldValue = item.value;
            
            NSURLQueryItem *newItem;
            if ([target isEqualToString:@"key"] && ![newValue isEqualToString:item.name]) {
                newItem = [NSURLQueryItem queryItemWithName:newValue value:oldValue];
                [replaceHistory.pairs addObject:[TSPKNetworkOperatePair initWithOriginKey:item.name changedKey:newValue]];
            } else if (![newValue isEqualToString:oldValue]) {
                newItem = [item initWithName:item.name value:newValue];
                [replaceHistory.pairs addObject:[TSPKNetworkOperatePair initWithOriginKey:item.name changedKey:item.name]];
            }
            
            if (newItem != nil) {
                [items removeObject:item];
                [items addObject:newItem];
            }
        }
        
        // remove
        if ([removeDict containsObject:item.name]) {
            [removeHistory.pairs addObject:[TSPKNetworkOperatePair initWithOriginKey:item.name changedKey:nil]];
            [items removeObject:item];
        }
    }
    
    if (addHistory.pairs.count != 0) [store addObject:addHistory];
    if (removeHistory.pairs.count != 0) [store addObject:removeHistory];
    if (replaceHistory.pairs.count != 0) [store addObject:replaceHistory];
    
    // if query changed, build new query
    if (addHistory.pairs.count != 0 || removeHistory.pairs.count != 0 || replaceHistory.pairs.count != 0) {
        return [TSPKNetworkUtil convertArrayToQuery:items];
    }
    return query;
}

+ (void)checkHeader:(id<TSPKCommonRequestProtocol>)request actions:(NSDictionary *)actions store:(NSMutableArray *)store {
    TSPKNetworkOperateHistory *addHistory = [TSPKNetworkOperateHistory initWithTarget:@"header" operate:@"add"];
    
    [[actions btd_dictionaryValueForKey:@"add"] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isKindOfClass:[NSString class]] && [obj isKindOfClass:[NSString class]]) {
            if ([request tspk_util_valueForHTTPHeaderField:key] == nil) {
                id newValue = [self getValueFromAppContextByKey:obj];
                if (newValue && [newValue isKindOfClass:[NSString class]]) {
                    [addHistory.pairs addObject:[TSPKNetworkOperatePair initWithOriginKey:nil changedKey:key]];
                    [request tspk_util_setValue:newValue forHTTPHeaderField:key];
                }
            }
        }
    }];

    // replace
    TSPKNetworkOperateHistory *replaceHistory = [TSPKNetworkOperateHistory initWithTarget:@"header" operate:@"replace"];
    
    [[actions btd_dictionaryValueForKey:@"replace"] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *oldValue = [request tspk_util_valueForHTTPHeaderField:key];
        if ([obj isKindOfClass:[NSDictionary class]] && oldValue != nil) {
            NSDictionary *value = (NSDictionary *)obj;
            NSString *newValue = [self getValueFromAppContextByKey:[value btd_stringValueForKey:@"value"]];
            NSString *target = [value btd_stringValueForKey:@"target"];
            
            if ([target isEqualToString:@"key"] && ![newValue isEqualToString:key]) {
                [request tspk_util_setValue:nil forHTTPHeaderField:key];
                [request tspk_util_setValue:oldValue forHTTPHeaderField:newValue];
                [replaceHistory.pairs addObject:[TSPKNetworkOperatePair initWithOriginKey:key changedKey:newValue]];
            } else if (![newValue isEqualToString:oldValue]) {
                [request tspk_util_setValue:newValue forHTTPHeaderField:key];
                [replaceHistory.pairs addObject:[TSPKNetworkOperatePair initWithOriginKey:key changedKey:key]];
            }
        }
    }];

    //remove
    TSPKNetworkOperateHistory *removeHistory = [TSPKNetworkOperateHistory initWithTarget:@"header" operate:@"remove"];
    
    [[actions btd_arrayValueForKey:@"remove"] enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([key isKindOfClass:[NSString class]]) {
            NSString *oldValue = [request tspk_util_valueForHTTPHeaderField:key];
            if (oldValue) {
                [removeHistory.pairs addObject:[TSPKNetworkOperatePair initWithOriginKey:key changedKey:nil]];
                [request tspk_util_setValue:nil forHTTPHeaderField:key];
            }
        }
    }];
    
    if (addHistory.pairs.count != 0) [store addObject:addHistory];
    if (removeHistory.pairs.count != 0) [store addObject:removeHistory];
    if (replaceHistory.pairs.count != 0) [store addObject:replaceHistory];
}

+ (void)checkCookie:(id<TSPKCommonRequestProtocol>)request cookieString:(NSString *)cookieString actions:(NSDictionary *)actions store:(NSMutableArray *)store {
    NSMutableDictionary *cookieSerialize = [TSPKNetworkUtil cookieString2MutableDict:cookieString];
    
    if (cookieSerialize == nil) return;
    
    // add
    TSPKNetworkOperateHistory *addHistory = [TSPKNetworkOperateHistory initWithTarget:@"cookie" operate:@"add"];
    [[actions btd_dictionaryValueForKey:@"add"] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isKindOfClass:[NSString class]] && cookieSerialize[key] == nil && [obj isKindOfClass:[NSString class]]) {
            id newValue = [self getValueFromAppContextByKey:obj];
            if (newValue) {
                [addHistory.pairs addObject:[TSPKNetworkOperatePair initWithOriginKey:nil changedKey:key]];
                [cookieSerialize setValue:newValue forKey:key];
            }
        }
    }];
    
    //replace
    TSPKNetworkOperateHistory *replaceHistory = [TSPKNetworkOperateHistory initWithTarget:@"cookie" operate:@"replace"];
    [[actions btd_dictionaryValueForKey:@"replace"] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *oldValue = [cookieSerialize btd_stringValueForKey:key];
        if ([obj isKindOfClass:[NSDictionary class]] && oldValue != nil) {
            NSDictionary *value = (NSDictionary *)obj;
            NSString *target = [value btd_stringValueForKey:@"target"];
            NSString *newValue = [self getValueFromAppContextByKey:[value btd_stringValueForKey:@"value"]];
            
            if ([target isEqualToString:@"key"] && ![newValue isEqualToString:key]) {
                [cookieSerialize setValue:oldValue forKey:newValue];
                [cookieSerialize setValue:nil forKey:key];
                [replaceHistory.pairs addObject:[TSPKNetworkOperatePair initWithOriginKey:key changedKey:newValue]];
            } else if (![newValue isEqualToString:oldValue]) {
                [cookieSerialize setValue:newValue forKey:key];
                [replaceHistory.pairs addObject:[TSPKNetworkOperatePair initWithOriginKey:key changedKey:key]];
            }
        }
    }];
    
    // remove
    TSPKNetworkOperateHistory *removeHistory = [TSPKNetworkOperateHistory initWithTarget:@"cookie" operate:@"remove"];
    [[actions btd_arrayValueForKey:@"remove"] enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([key isKindOfClass:[NSString class]] && cookieSerialize[key]) {
            [removeHistory.pairs addObject:[TSPKNetworkOperatePair initWithOriginKey:key changedKey:nil]];
            [cookieSerialize setValue:nil forKey:key];
        }
    }];
    // set new cookie value
    [request tspk_util_setValue:[TSPKNetworkUtil cookieDict2String:cookieSerialize] forHTTPHeaderField:@"cookie"];
    
    if (addHistory.pairs.count != 0) [store addObject:addHistory];
    if (removeHistory.pairs.count != 0) [store addObject:removeHistory];
    if (replaceHistory.pairs.count != 0) [store addObject:replaceHistory];
}

+ (NSString *)getValueFromAppContextByKey:(NSString *)key {
    if ([key hasPrefix:@"$"]) {
        Class clazz = PNS_GET_CLASS(TSPKNetworkHostEnvProtocol);
        if ([clazz respondsToSelector:@selector(getValueFromAppContextByKey:)]) {
            NSString *result = [clazz getValueFromAppContextByKey:[key substringFromIndex:1]];
            return result != nil ? result : key;
        }
    }
    return key;
}

@end
