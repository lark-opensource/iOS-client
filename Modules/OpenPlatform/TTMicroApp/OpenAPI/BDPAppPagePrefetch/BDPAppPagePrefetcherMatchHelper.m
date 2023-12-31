//
//  BDPAppPagePrefetcherMatchHelper.m
//  TTMicroApp
//
//  Created by 刘焱龙 on 2023/1/29.
//

#import "BDPAppPagePrefetcherMatchHelper.h"
#import "BDPAppPagePrefetchMatchKey.h"
#import <ECOInfra/ECOInfra.h>
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/BDPUtils.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import "BDPAppPagePrefetchDefines.h"

@implementation BDPAppPagePrefetcherMatchHelper

#pragma mark - public

+ (NSString *)matchURLWithQuery:(NSDictionary *)startPageQueryDictionary
                        storage:(NSDictionary *)storageDic
                     enviroment:(NSDictionary *)enviromentDic
         dynamicEnvironmentDict:(NSDictionary *)dynamicEnvironmentDict
                 inTargetString:(NSString *)targetJSONString
              allContentMatched:(BOOL * _Nonnull)isAllMatched
                       matchKey:(BDPAppPagePrefetchMatchKey *)matchKey
                       missKeys:(NSMutableArray *)missKeys
                          appId:(NSString *)appId {
    NSString *result = [BDPAppPagePrefetcherMatchHelper matchAllContentsWithQuery:startPageQueryDictionary
                                                                          storage:storageDic
                                                                       enviroment:enviromentDic
                                                           dynamicEnvironmentDict:dynamicEnvironmentDict
                                                                   inTargetString:targetJSONString
                                                                allContentMatched:isAllMatched
                                                                         missKeys:missKeys
                                                                            appId:appId];
    if (*isAllMatched == NO && matchKey.missKeyItems.count > 0) {
        result = [BDPAppPagePrefetcherMatchHelper matchMissKeyWithTargetURLString:result matchKey:matchKey missKeys:missKeys appId:appId];
        *isAllMatched = [BDPAppPagePrefetcherMatchHelper isAllMatchedWithTargetString:result];
    }
    return result;
}

+ (NSString *)matchDataWithQuery:(NSDictionary *)startPageQueryDictionary
                         storage:(NSDictionary *)storageDic
                      enviroment:(NSDictionary *)enviromentDic
          dynamicEnvironmentDict:(NSDictionary *)dynamicEnvironmentDict
                  inTargetString:(NSString *)targetString
               allContentMatched:(BOOL * _Nonnull)isAllMatched
                        matchKey:(BDPAppPagePrefetchMatchKey *)matchKey
                        missKeys:(NSMutableArray *)missKeys
                           appId:(NSString *)appId {
    if (BDPIsEmptyString(targetString)) {
        return targetString;
    }
    NSDictionary *jsonDic = [targetString JSONDictionary];
    if (jsonDic) {
        NSDictionary *dataResult = [BDPAppPagePrefetcherMatchHelper matchAllContentsWithQuery:startPageQueryDictionary
                                                                                      storage:storageDic
                                                                                   enviroment:enviromentDic
                                                                       dynamicEnvironmentDict:dynamicEnvironmentDict
                                                                                     inTarget:jsonDic
                                                                            allContentMatched:isAllMatched
                                                                                     matchKey:matchKey
                                                                                     missKeys:missKeys
                                                                                        appId:appId];
        //如果出现非法的匹配，（JSON反序列化之后是nil，则出现了字符串""）
        if (BDPIsEmptyDictionary(dataResult)
            &&!BDPIsEmptyDictionary(jsonDic)) {
            *isAllMatched = NO;
        }
        if (@available(iOS 13.0, *)) {
            return [dataResult JSONRepresentationWithOptions:NSJSONWritingWithoutEscapingSlashes];
        } else {
            if (PrefetchLarkFeatureGatingDependcy.prefetchDisableRemoveSlash) {
                return [dataResult JSONRepresentation];
            } else {
                return [[dataResult JSONRepresentation] stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
            }
        }
    }
    NSString *dataResult = [BDPAppPagePrefetcherMatchHelper matchAllContentsWithQuery:startPageQueryDictionary
                                                                              storage:storageDic
                                                                           enviroment:enviromentDic
                                                               dynamicEnvironmentDict:dynamicEnvironmentDict
                                                                       inTargetString:targetString
                                                                    allContentMatched:isAllMatched
                                                                             missKeys:missKeys
                                                                                appId:appId];
    return dataResult;
}

//匹配目标中的所有字段（包含key，value）
+ (NSDictionary *)matchAllContentsWithQuery:(NSDictionary *)startPageQueryDictionary
                                    storage:(NSDictionary *)storageDic
                                 enviroment:(NSDictionary *)enviromentDic
                     dynamicEnvironmentDict:(NSDictionary *)dynamicEnvironmentDict
                                   inTarget:(NSDictionary *)targetDic
                          allContentMatched:(BOOL *)isAllMatched
                                   matchKey:(BDPAppPagePrefetchMatchKey *)matchKey
                                   missKeys:(NSMutableArray *)missKeys
                                      appId:(NSString *)appId {
    //先把需要匹配的字典拍平，变成JSONString
    NSString * targetJSONString = [targetDic JSONRepresentation];
    NSString * matchResultString = [BDPAppPagePrefetcherMatchHelper matchAllContentsWithQuery:startPageQueryDictionary
                                                                                      storage:storageDic
                                                                                   enviroment:enviromentDic
                                                                       dynamicEnvironmentDict:dynamicEnvironmentDict
                                                                               inTargetString:targetJSONString
                                                                            allContentMatched:isAllMatched
                                                                                     missKeys:missKeys
                                                                                        appId:appId];
    NSDictionary *matchResultDic;
    if (*isAllMatched == NO && matchKey.missKeyItems.count > 0) {
        matchResultDic = [BDPAppPagePrefetcherMatchHelper matchMissKeyWithTargetDicString:matchResultString
                                                                                 matchKey:matchKey
                                                                                 missKeys:missKeys
                                                                                    appId:appId];
        *isAllMatched = [BDPAppPagePrefetcherMatchHelper isAllMatchedWithTargetString:[matchResultDic JSONRepresentation]];
    } else {
        matchResultDic = [matchResultString JSONDictionary];
    }
    return matchResultDic;
}


+ (void)checkURLString:(NSString *)urlString
isURLWithoutQueryReady:(BOOL *)isURLWithoutQueryReady
          isQueryReady:(BOOL *)isQueryReady {
    if (!urlString) {
        *isURLWithoutQueryReady = NO;
        return;
    }
    NSString *encodedUrlString = [BDPAppPagePrefetcherMatchHelper partialUrlEncodeWithUrlString:urlString];
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:encodedUrlString];
    if (!urlComponents) {
        *isURLWithoutQueryReady = NO;
        return;
    }

    NSString *query = urlComponents.query.stringByRemovingPercentEncoding;

    urlComponents.query = nil;
    NSString *urlStringWithoutQuery = urlComponents.URL.absoluteString.stringByRemovingPercentEncoding;

    *isURLWithoutQueryReady = [BDPAppPagePrefetcherMatchHelper isAllMatchedWithTargetString:urlStringWithoutQuery];
    *isQueryReady = [BDPAppPagePrefetcherMatchHelper isAllMatchedWithTargetString:query];
}

#pragma mark - missKey

// url 中出现 $、{、} 可能是无效的 url，这里 encode 一下
+ (NSString *)partialUrlEncodeWithUrlString:(NSString *)urlString {
    return [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

/// match missKey for header or data which is  dictionary
+ (NSDictionary *)matchMissKeyWithTargetDicString:(NSString *)targetDicString
                                         matchKey:(BDPAppPagePrefetchMatchKey *)matchKey
                                         missKeys:(NSMutableArray *)missKeys
                                            appId:(NSString *)appId {
    // 1. targetDicString 整体用 default 值进行匹配

    NSString *realTargetDicString = [BDPAppPagePrefetcherMatchHelper matchContentsWithTargetString:targetDicString
                                                                                 allContentMatched:NULL
                                                                                          missKeys:nil
                                                                                             appId:appId
                                                                                    replaceHandler:^NSString *(NSString *replaceKey) {
        NSString *result = [BDPAppPagePrefetcherMatchHelper getDefaultValueWithMissKey:replaceKey matchKey:matchKey];
        if (result) {
            [missKeys removeObject:replaceKey];
        }
        return result;
    }];
    if ([BDPAppPagePrefetcherMatchHelper isAllMatchedWithTargetString:realTargetDicString]) {
        return [realTargetDicString JSONDictionary];
    }

    // 2. 移除 shouldDelete 的 key

    NSDictionary *targetDic = [realTargetDicString JSONDictionary];
    NSMutableDictionary *realTargetDic = [NSMutableDictionary dictionaryWithDictionary:targetDic];

    NSMutableArray *shouldRemoveKey = [NSMutableArray array];
    [realTargetDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (![obj isKindOfClass:[NSString class]]) {
            return;
        }
        NSString *value = (NSString *)obj;
        if (![BDPAppPagePrefetcherMatchHelper shouldDeleteWithValue:value matchKey:matchKey]) {
            return;;
        }
        [shouldRemoveKey addObject:key];

        NSString *valueKey = [BDPAppPagePrefetcherMatchHelper getPureKey:value];
        [missKeys removeObject:valueKey];
    }];
    [shouldRemoveKey enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj isKindOfClass:[NSString class]]) {
            return;
        }
        NSString *key = (NSString *)obj;
        [realTargetDic removeObjectForKey:key];
    }];
    return  realTargetDic;
}

/// match missKey for URL
+ (NSString *)matchMissKeyWithTargetURLString:(NSString *)targetURLString
                                     matchKey:(BDPAppPagePrefetchMatchKey *)matchKey
                                     missKeys:(NSMutableArray *)missKeys
                                        appId:(NSString *)appId {
    // 1. 先用 missKey 的 default 对 targetURLString 整体替换一波

     NSString *realTargetURLString = [BDPAppPagePrefetcherMatchHelper matchContentsWithTargetString:targetURLString
                                                                                  allContentMatched:NULL
                                                                                           missKeys:nil
                                                                                              appId:appId
                                                                                     replaceHandler:^NSString *(NSString *replaceKey) {
         NSString *result = [BDPAppPagePrefetcherMatchHelper getDefaultValueWithMissKey:replaceKey matchKey:matchKey];
         if (result) {
             [missKeys removeObject:replaceKey];
         }
         return result;
     }];
    if ([BDPAppPagePrefetcherMatchHelper isAllMatchedWithTargetString:realTargetURLString]) {
        return realTargetURLString;
    }

    // 2. 再判断是否需要 delete query 中未匹配的 key

    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:realTargetURLString];
    // 处理一下 url 无效的情况：例如 host 中出现了 ${xxx} 是非法的 url，urlComponents 会是 nil
    if (!urlComponents) {
        return realTargetURLString;
    }
    NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray arrayWithArray:urlComponents.queryItems];
    NSMutableArray *shouldDelIndexs = [NSMutableArray array];
    [urlComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *value = item.value;
        if (![BDPAppPagePrefetcherMatchHelper shouldDeleteWithValue:value matchKey:matchKey]) {
            return;
        }
        [shouldDelIndexs addObject:@(idx)];

        NSString *valueKey = [BDPAppPagePrefetcherMatchHelper getPureKey:value];
        [missKeys removeObject:valueKey];
    }];
    for (NSNumber *idx in shouldDelIndexs) {
        [queryItems removeObjectAtIndex:idx.integerValue];
    }
    urlComponents.queryItems = queryItems;
    return [urlComponents.URL.absoluteString stringByRemovingPercentEncoding];
}

/// Just delete when  value is "${value}"
+ (BOOL)shouldDeleteWithValue:(NSString *)value matchKey:(BDPAppPagePrefetchMatchKey *)matchKey {
    if (value.length <= 3) {
        return NO;
    }
    for (BDPAppPagePrefetchMissKeyItem * item in matchKey.missKeyItems) {
        if ([value isEqualToString:[NSString stringWithFormat:@"${%@}", item.key]] && item.shouldDelete) {
            return YES;
        }
    }
    return NO;
}

/// 删除正则匹配到内容中前缀为${，后缀为}的字符，得到纯净的key
+ (NSString *)getPureKey:(NSString *)unpureKey {
    NSString * key = [unpureKey stringByReplacingOccurrencesOfString:@"${" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"}" withString:@""];
    return key;
}

/// get missKey default value
+ (nullable NSString *)getDefaultValueWithMissKey:(NSString *)missKey
                                         matchKey:(BDPAppPagePrefetchMatchKey *)matchKey {
    for (BDPAppPagePrefetchMissKeyItem *item in matchKey.missKeyItems) {
        if (![item.key isEqualToString:missKey]) {
            continue;
        }
        return item.defaultValue;
    }
    return nil;
}

#pragma mark - match core

/// 匹配所有目标字符串中带 ${format}内容的字符串
/// @param startPageQueryDictionary 启动参数scheme
/// @param storageDic 本地storage中的表
/// @param enviromentDic 环境参数
/// @param targetJSONString 需要正则匹配的目标
/// @param isAllMatched 是否已将内容中待匹配的内容都匹配完毕
+ (NSString *)matchAllContentsWithQuery:(NSDictionary *)startPageQueryDictionary
                                storage:(NSDictionary *)storageDic
                             enviroment:(NSDictionary *)enviromentDic
                 dynamicEnvironmentDict:(NSDictionary *)dynamicEnvironmentDict
                         inTargetString:(NSString *)targetJSONString
                      allContentMatched:(BOOL * _Nonnull)isAllMatched
                               missKeys:(NSMutableArray *)missKeys
                                  appId:(NSString *)appId {
    return [BDPAppPagePrefetcherMatchHelper matchContentsWithTargetString:targetJSONString
                                                        allContentMatched:isAllMatched
                                                                 missKeys:missKeys
                                                                    appId:appId
                                                           replaceHandler:^NSString *(NSString *key) {
        //优先匹配启动Query中的内容，如果没有取本地storage中命中的内容
        NSString * result = startPageQueryDictionary[key] ?: storageDic[key];
        //最后匹配环境参数
        result = result ?: enviromentDic[key];
        result = result ?: dynamicEnvironmentDict[key];
        return result;
    }];
}

+ (NSString *)matchContentsWithTargetString:(NSString *)targetString
                          allContentMatched:(BOOL * _Nonnull)isAllMatched
                                   missKeys:(nullable NSMutableArray *)missKeys
                                      appId:(nullable NSString *)appId
                             replaceHandler:(nullable NSString *(^)(NSString *))replaceHandler {
    //安全检查，避免NPE错误
    if (BDPIsEmptyString(targetString)) {
        return targetString;
    }
    NSArray<NSString *> *blackList = [BDPAppPagePrefetcherMatchHelper decodedKeyBlackList];
    //通过正则找到其中需要匹配的所有key \${(.*?)}
    //匹配规则，${Key}，Key即为匹配到的内容
    NSError * error = nil;
    NSArray *matches = [BDPAppPagePrefetcherMatchHelper getMatchResultWithTargetString:targetString error:error];
    //匹配到内容即进行替换
    if (matches.count>0) {
        __block NSString * matchResultString = targetString;
        [matches enumerateObjectsUsingBlock:^(NSTextCheckingResult *  _Nonnull result, NSUInteger idx, BOOL * _Nonnull stop) {
            if (result.range.location!=NSNotFound) {
                NSString * matchedString = [targetString substringWithRange:result.range];
                //删除正则匹配到内容中前缀为${，后缀为}的字符，得到纯净的key
                NSString * key = [BDPAppPagePrefetcherMatchHelper getPureKey:matchedString];

                NSString * result;
                if (replaceHandler) {
                    result = replaceHandler(key);
                }
                if (result&&[result isKindOfClass:[NSString class]]) {
                    NSString *replaceString;
                    if ([PrefetchLarkSettingDependcy shouldFixDecodeWithAppID:appId]) {
                        replaceString = result;
                    } else {
                        replaceString = [blackList containsObject:key] ? result : [result URLDecodedString];
                        replaceString = replaceString ? replaceString : result;
                    }
                    //替换JSON字符串中待匹配的内容
                    matchResultString = [matchResultString stringByReplacingOccurrencesOfString:matchedString withString:replaceString];
                } else {
                    [missKeys addObject:key];
                    BDPLogTagInfo(kLogTagPrefetch, @"Variable matching failed, because %@ cannot find value", key);
                }
            }
        }];
        //最后做一个匹配检查，看一下是否所有的内容都已经替换完成
        if (isAllMatched) {
            *isAllMatched = [BDPAppPagePrefetcherMatchHelper isAllMatchedWithTargetString:matchResultString];
        }
        return matchResultString;
    } else if (error) {
        BDPLogTagError(kLogTagPrefetch, @"matchAllContentsWithQuery regularExpression with error:%@", error);
    } else {
        BDPLogTagInfo(kLogTagPrefetch, @"matchAllContentsWithQuery match nothing here");
    }
    if (isAllMatched) {
        *isAllMatched = YES;
    }
    return targetString;
}

#pragma mark - utils

+ (BOOL)isAllMatchedWithTargetString:(NSString *)targetString {
    return [BDPAppPagePrefetcherMatchHelper getMatchResultWithTargetString:targetString error:nil].count <= 0;
}

+ (nullable NSArray<NSTextCheckingResult *> *)getMatchResultWithTargetString:(NSString *)targetString error:(nullable NSError *)error {
    if (targetString.length <= 0) {
        return nil;
    }
    NSString * regrexPattern = @"\\$\\{.+?\\}";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regrexPattern
                                                                                options:0
                                                                                  error:(error ? &error : NULL)];
    NSArray *matches = [expression matchesInString:targetString
                                           options:0
                                             range:NSMakeRange(0, targetString.length)];
    return matches;
}

+ (NSArray<NSString *> *)decodedKeyBlackList {
    return @[kPrefetchCustomDate];
}

@end
