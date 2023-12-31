//
//  IESPrefetchAPITemplate.m
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/2.
//

#import "IESPrefetchAPITemplate.h"
#import "IESPrefetchAPIModel.h"
#import "IESPrefetchLogger.h"
#import "IESPrefetchTemplateOutput.h"

NSString *paramsTypeDescription(IESPrefetchAPIParamsType paramsType)
{
    NSString *description = nil;
    switch (paramsType) {
        case IESPrefetchAPIParamQuery:
            description = @"query";
            break;
        case IESPrefetchAPIParamStatic:
            description = @"static";
            break;
        case IESPrefetchAPIParamVariable:
            description = @"variable";
            break;
        case IESPrefetchAPIParamPathVariable:
            description = @"pathParam";
            break;
        case IESPrefetchAPIParamNested:
            description = @"nested";
            break;
    }
    return description;
}

NSString *paramDataTypeDescription(IESPrefetchAPIParamsDataType dataType)
{
    NSString *description = nil;
    switch (dataType) {
        case IESPrefetchDataTypeBool:
            description = @"bool";
            break;
        case IESPrefetchDataTypeNumber:
            description = @"number";
            break;
        case IESPrefetchDataTypeString:
            description = @"string";
            break;
        case IESPrefetchDataTypeParamsNode:
            description = @"nested";
            break;
        default:
            break;
    }
    return description;
}

@implementation IESPrefetchAPIParamsNode

- (NSDictionary<NSString *, id> *)jsonRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"type"] = paramsTypeDescription(self.type);
    dict[@"data_type"] = paramDataTypeDescription(self.dataType);
    
    if (self.type == IESPrefetchAPIParamNested && [self.valueFrom isKindOfClass:[NSDictionary class]]) {
        NSDictionary<NSString *, IESPrefetchAPIParamsNode *> *paramNodes = self.valueFrom;
        if ([paramNodes isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary<NSString *, NSDictionary *> *jsonValue = [NSMutableDictionary dictionary];
            [paramNodes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, IESPrefetchAPIParamsNode * _Nonnull obj, BOOL * _Nonnull stop) {
                NSDictionary *value = [obj jsonRepresentation];
                if (value) {
                    jsonValue[key] = value;
                }
            }];
            if (jsonValue.count > 0) {
                dict[@"value_from"] = [jsonValue copy];
            }
        }
    } else {
        dict[@"value_from"] = self.valueFrom;
    }
    return [dict copy];
}

@end

@implementation IESPrefetchAPINode

- (NSDictionary<NSString *, id> *)jsonRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"url"] = self.url;
    dict[@"method"] = self.method;
    dict[@"header"] = self.headers;
    NSMutableDictionary *paramsDict = [NSMutableDictionary new];
    [self.params enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, IESPrefetchAPIParamsNode * _Nonnull obj, BOOL * _Nonnull stop) {
        paramsDict[key] = [obj jsonRepresentation];
    }];
    dict[@"params"] = paramsDict.copy;
    NSMutableDictionary *dataDict = [NSMutableDictionary new];
    [self.data enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, IESPrefetchAPIParamsNode * _Nonnull obj, BOOL * _Nonnull stop) {
        dataDict[key] = [obj jsonRepresentation];
    }];
    dict[@"data"] = dataDict.copy;
    dict[@"expire"] = @(self.expire);
    dict[@"extras"] = self.extras;
    return dict.copy;
}

@end

@interface IESPrefetchAPITemplate ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, IESPrefetchAPINode *> *apis;

@end

@implementation IESPrefetchAPITemplate

@synthesize children;

- (void)addAPINode:(IESPrefetchAPINode *)node
{
    if (self.apis == nil) {
        self.apis = [NSMutableDictionary new];
    }
    if (node.apiName.length == 0) {
        return;
    }
    self.apis[node.apiName] = node;
}

- (IESPrefetchAPINode *)apiNodeForName:(NSString *)name
{
    if (name.length == 0 || self.apis.count == 0) {
        return nil;
    }
    IESPrefetchAPINode *node = self.apis[name];
    return node;
}

- (NSUInteger)countOfNodes
{
    return self.apis.count;
}

//MARK: - IESPrefetchConfigTemplate

- (id<IESPrefetchTemplateOutput>)process:(id<IESPrefetchTemplateInput>)input
{
    if (input == nil) {
        return nil;
    }
    NSString *apiName = input.name;
    IESPrefetchAPINode *node = [self apiNodeForName:apiName];
    IESPrefetchFlatSchema *schema = input.schema;
    NSDictionary<NSString *, id> *variables = input.variables;
    IESPrefetchJSNetworkRequestModel *apiModel = [IESPrefetchJSNetworkRequestModel new];
    apiModel.url = node.url;
    apiModel.method = node.method;
    apiModel.headers = node.headers;
    apiModel.traceId = input.traceId;
    apiModel.needCommonParams = node.needCommonParams;
    apiModel.extras = node.extras;
    
    if (node.params.count > 0) {
        NSDictionary *params = [self buildParamsOfNode:node.params withSchema:schema variables:variables percentEscapes:NO];
        apiModel.params = params;
    }
    if (node.data.count > 0) {
        // 和安卓对齐，所有body里的数据全部decode
        NSDictionary *params = [self buildParamsOfNode:node.data withSchema:schema variables:variables percentEscapes:YES];
        apiModel.data = params;
    }
    PrefetchMatcherLogV(@"[%@] Hit api: %@==>%@", input.traceId, apiName, node.url);
    IESPrefetchTemplateOutput *output = [IESPrefetchTemplateOutput new];
    IESPrefetchAPIModel *model = [IESPrefetchAPIModel new];
    model.expire = node.expire;
    model.request = apiModel;
    [output addRequestModel:model];
    return output;
}

- (NSDictionary *)buildParamsOfNode:(NSDictionary<NSString *, IESPrefetchAPIParamsNode *> *)nodes withSchema:(IESPrefetchFlatSchema *)schema variables:(NSDictionary<NSString *, id> *)variables percentEscapes:(BOOL)escapes
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    [nodes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, IESPrefetchAPIParamsNode * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj.valueFrom == nil) {
            return;
        }
        id value = [self paramsOfNode:obj withSchema:schema variables:variables percentEscapes:escapes];
        params[key] = value;
    }];
    return [params copy];
}

- (id)paramsOfNode:(IESPrefetchAPIParamsNode *)node withSchema:(IESPrefetchFlatSchema *)schema variables:(NSDictionary<NSString *, id> *)variables percentEscapes:(BOOL)escapes
{
    if (node.valueFrom == nil) {
        return nil;
    }
    if (node.type == IESPrefetchAPIParamStatic) {
        return node.valueFrom;
    }
    if (node.type == IESPrefetchAPIParamQuery && schema.queryItems != nil) {
        NSString * query = schema.queryItems[node.valueFrom];
        if ([query isKindOfClass:[NSString class]] == NO) {
            return nil;
        }
        if (escapes) {
            query = [query stringByRemovingPercentEncoding] ?: query;
        }
        return [self paramsOfValue:query dataType:node.dataType];
    }
    if (node.type == IESPrefetchAPIParamPathVariable && schema.pathVariables != nil) {
        NSString *variable = schema.pathVariables[node.valueFrom];
        if ([variable isKindOfClass:[NSString class]] == NO) {
            return nil;
        }
        return [self paramsOfValue:variable dataType:node.dataType];
    }
    if (node.type == IESPrefetchAPIParamVariable && variables != nil) {
        id query = variables[node.valueFrom];
        return [self paramsOfValue:query dataType:node.dataType];
    }
    if (node.type == IESPrefetchAPIParamNested) {
        NSDictionary<NSString *, IESPrefetchAPIParamsNode *> *paramNodes = (NSDictionary *)node.valueFrom;
        if (![paramNodes isKindOfClass:[NSDictionary class]]) {
            return nil;
        }
        NSMutableDictionary<NSString *, NSDictionary *> *resDict = [NSMutableDictionary dictionary];
        [paramNodes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, IESPrefetchAPIParamsNode * _Nonnull obj, BOOL * _Nonnull stop) {
            id value = [self paramsOfNode:obj withSchema:schema variables:variables percentEscapes:escapes];
            if (value) {
                resDict[key] = value;
            }
        }];
        return [resDict copy];
    }
    return nil;
}

- (id)paramsOfValue:(id)value dataType:(IESPrefetchAPIParamsDataType)dataType
{
    if (value == nil) {
        return nil;
    }
    if (dataType == IESPrefetchDataTypeString) {
        if ([value isKindOfClass:[NSString class]]) {
            return value;
        } else {
            return [NSString stringWithFormat:@"%@", value];
        }
    }
    if (dataType == IESPrefetchDataTypeBool) {
        if ([value isKindOfClass:[NSString class]]) {
            return @([value boolValue]);
        } else if ([value isKindOfClass:[NSNumber class]]){
            return value;
        }
    }
    if (dataType == IESPrefetchDataTypeNumber) {
        if ([value isKindOfClass:[NSString class]]) {
            static NSNumberFormatter *numberFormatter = nil;
            if (numberFormatter == nil) {
                numberFormatter = [NSNumberFormatter new];
                numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
            }
            return [numberFormatter numberFromString:(NSString *)value];
        } else if ([value isKindOfClass:[NSNumber class]]) {
            return value;
        }
    }
    return nil;
}

- (NSDictionary<NSString *, id> *)jsonRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary new];
    NSMutableDictionary *apiDict = [NSMutableDictionary new];
    [self.apis enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, IESPrefetchAPINode * _Nonnull obj, BOOL * _Nonnull stop) {
        apiDict[key] = [obj jsonRepresentation];
    }];
    dict[@"api"] = apiDict.copy;
    return dict.copy;
}

@end
