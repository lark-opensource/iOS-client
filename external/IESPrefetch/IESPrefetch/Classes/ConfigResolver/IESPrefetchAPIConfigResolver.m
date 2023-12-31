//
//  IESPrefetchAPIConfigResolver.m
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/2.
//

#import "IESPrefetchAPIConfigResolver.h"
#import "IESPrefetchAPITemplate.h"
#import "IESPrefetchLogger.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@implementation IESPrefetchAPIConfigResolver

- (id<IESPrefetchConfigTemplate>)resolveConfig:(NSDictionary *)config
{
    if (config.count == 0) {
        PrefetchConfigLogW(@"API config is empty ");
        return nil;
    }
    NSDictionary *apiConfig = config[@"prefetch_apis"];
    if (!([apiConfig isKindOfClass:[NSDictionary class]] && apiConfig.count > 0)) {
        PrefetchConfigLogW(@"API config is empty or invalid.");
        return nil;
    }
    IESPrefetchAPITemplate *template = [IESPrefetchAPITemplate new];
    [apiConfig enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
        IESPrefetchAPINode *node = [self resolveAPI:obj forName:key];
        if (node) {
            [template addAPINode:node];
        }
    }];
    if (template.countOfNodes == 0) {
        return nil;
    }
    return template;
}

- (IESPrefetchAPINode *)resolveAPI:(NSDictionary *)config forName:(NSString *)name
{
    if (!([config isKindOfClass:[NSDictionary class]] && config.count > 0)) {
        PrefetchConfigLogW(@"API config item is invalid: %@", config.description);
        return nil;
    }
    IESPrefetchAPINode *node = [IESPrefetchAPINode new];
    node.apiName = name;
    if (config[@"url"] == nil) {
        PrefetchConfigLogW(@"API config item %@ has no url, skip this one.", name);
        return nil;
    }
    node.url = [config btd_stringValueForKey:@"url"];
    if (config[@"method"] == nil) {
        node.method = @"GET";
    } else {
        node.method = [config btd_stringValueForKey:@"method"];
    }
    node.headers = [config btd_dictionaryValueForKey:@"headers"];
    if (config[@"expire"] == nil) {
        node.expire = 30;
    } else {
        node.expire = [config btd_longlongValueForKey:@"expire"];
    }
    node.needCommonParams = [config btd_boolValueForKey:@"needCommonParams"];
    
    NSDictionary *paramsConfig = [config btd_dictionaryValueForKey:@"params"];
    if ([paramsConfig isKindOfClass:[NSDictionary class]] && paramsConfig.count > 0) {
        NSMutableDictionary<NSString *, IESPrefetchAPIParamsNode *> *paramNodes = [NSMutableDictionary new];
        [paramsConfig enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
            IESPrefetchAPIParamsNode *paramNode = [self resolveParams:obj forName:key];
            // 和安卓对齐，params字段不支持嵌套参数
            if (paramNode && paramNode.type != IESPrefetchAPIParamNested) {
                paramNodes[key] = paramNode;
            }
        }];
        if (paramNodes.count > 0) {
            node.params = [paramNodes copy];
        }
    }
    NSDictionary *dataConfig = [config btd_dictionaryValueForKey:@"data"];
    if ([dataConfig isKindOfClass:[NSDictionary class]] && dataConfig.count > 0) {
        NSMutableDictionary<NSString *, IESPrefetchAPIParamsNode *> *paramNodes = [NSMutableDictionary new];
        [dataConfig enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
            IESPrefetchAPIParamsNode *paramNode = [self resolveParams:obj forName:key];
            if (paramNode) {
                paramNodes[key] = paramNode;
            }
        }];
        if (paramNodes.count > 0) {
            node.data = [paramNodes copy];
        }
    }

    node.extras = [config btd_dictionaryValueForKey:@"extras"];
    
    return node;
}

- (IESPrefetchAPIParamsNode *)resolveParams:(NSDictionary *)config forName:(NSString *)name
{
    if (!([config isKindOfClass:[NSDictionary class]] && config.count > 0)) {
        PrefetchConfigLogD(@"API config param item is invalid: %@", config.description);
        return nil;
    }
    IESPrefetchAPIParamsNode *node = [IESPrefetchAPIParamsNode new];
    node.paramName = name;
    NSString *type = [config btd_stringValueForKey:@"type"];
    if ([type isEqualToString:paramsTypeDescription(IESPrefetchAPIParamStatic)]) {
        node.type = IESPrefetchAPIParamStatic;
    } else if ([type isEqualToString:paramsTypeDescription(IESPrefetchAPIParamQuery)]) {
        node.type = IESPrefetchAPIParamQuery;
    } else if ([type isEqualToString:paramsTypeDescription(IESPrefetchAPIParamVariable)]) {
        node.type = IESPrefetchAPIParamVariable;
    } else if ([type isEqualToString:paramsTypeDescription(IESPrefetchAPIParamPathVariable)]) {
        node.type = IESPrefetchAPIParamPathVariable;
    } else if ([type isEqualToString:paramsTypeDescription(IESPrefetchAPIParamNested)]) {
        node.type = IESPrefetchAPIParamNested;
    } else {
        PrefetchConfigLogD(@"API config params type is invalid: %@", config.description);
        return nil;
    }
    
    NSString *dataType = config[@"dataType"];
    if (dataType == nil || [dataType isKindOfClass:[NSString class]] == NO) {
        node.dataType = IESPrefetchDataTypeString;
    } else if ([dataType.lowercaseString isEqualToString:@"number"]) {
        node.dataType = IESPrefetchDataTypeNumber;
    } else if ([dataType.lowercaseString isEqualToString:@"bool"]) {
        node.dataType = IESPrefetchDataTypeBool;
    } else {
        node.dataType = IESPrefetchDataTypeString;
    }
    // 嵌套的特殊处理
    if (node.type == IESPrefetchAPIParamNested) {
        node.dataType = IESPrefetchDataTypeParamsNode;
    }
    
    
    NSString *valueFrom = config[@"value"];
    if ([valueFrom isKindOfClass:[NSString class]] && valueFrom != nil) {
        node.valueFrom = valueFrom;
    } else if ([valueFrom isKindOfClass:[NSNumber class]]) {
        node.valueFrom = (NSNumber *)valueFrom;
    } else if ([valueFrom isKindOfClass:[NSDictionary class]] &&
               node.type == IESPrefetchAPIParamNested) {
        NSMutableDictionary<NSString *, IESPrefetchAPIParamsNode *> *paramNodes = [NSMutableDictionary new];
        [(NSDictionary *)valueFrom enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
            IESPrefetchAPIParamsNode *paramNode = [self resolveParams:obj forName:key];
            if (paramNode) {
                paramNodes[key] = paramNode;
            }
        }];
        if (paramNodes.count > 0) {
            node.valueFrom = [paramNodes copy];
        } else {
            // 没有一个序列化成功的子节点，直接return，类似解析失败
            return nil;
        }
    } else {
        PrefetchConfigLogD(@"API config params value is invalid: %@", config.description);
        return nil;
    }
    
    return node;
}

@end
