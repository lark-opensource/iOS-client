//
//  IESPrefetchRuleTemplate.m
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/2.
//

#import "IESPrefetchRuleTemplate.h"
#import "IESPrefetchTemplateOutput.h"
#import "IESPrefetchFlatSchema+Private.h"
#import "IESPrefetchLogger.h"

@implementation IESPrefetchRuleQueryNode

- (NSDictionary<NSString *, id> *)jsonRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"key"] = self.key;
    dict[@"value"] = self.valueRegex;
    return dict.copy;
}

@end

@implementation IESPrefetchRuleItemNode

- (NSDictionary<NSString *, id> *)jsonRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"hash"] = self.fragment;
    NSMutableArray<NSDictionary<NSString *, id> *> *querys = [NSMutableArray new];
    [self.queryNodes enumerateObjectsUsingBlock:^(IESPrefetchRuleQueryNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [querys addObject:[obj jsonRepresentation]];
    }];
    dict[@"query"] = querys.copy;
    dict[@"apis"] = self.apis;
    return dict.copy;
}

@end

@implementation IESPrefetchRuleNode

- (NSDictionary<NSString *, id> *)jsonRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary new];
    NSMutableArray<NSDictionary<NSString *, id> *> *items = [NSMutableArray new];
    [self.itemNodes enumerateObjectsUsingBlock:^(IESPrefetchRuleItemNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [items addObject:[obj jsonRepresentation]];
    }];
    dict[self.ruleName] = items.copy;
    return dict.copy;
}

@end

@implementation IESPrefetchRuleRegexNode

- (NSDictionary<NSString *, id> *)jsonRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary new];
    NSMutableArray<NSDictionary<NSString *, id> *> *items = [NSMutableArray new];
    [self.itemNodes enumerateObjectsUsingBlock:^(IESPrefetchRuleItemNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [items addObject:[obj jsonRepresentation]];
    }];
    dict[self.ruleName] = items.copy;
    return dict.copy;
}

@end

@interface IESPrefetchRuleTemplate ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, IESPrefetchRuleNode *> *rules;
@property (nonatomic, strong) NSMutableDictionary<NSString *, IESPrefetchRuleRegexNode *> *regexRules;

@end

@implementation IESPrefetchRuleTemplate

@synthesize children;

- (void)addRuleNode:(IESPrefetchRuleNode *)node
{
    if (node.ruleName.length == 0) {
        return;
    }
    if (self.rules == nil) {
        self.rules = [NSMutableDictionary new];
    }
    
    self.rules[node.ruleName] = node;
}

- (IESPrefetchRuleNode *)ruleNodeForName:(NSString *)name
{
    if (name.length == 0 || self.rules.count == 0) {
        return nil;
    }
    IESPrefetchRuleNode *node = self.rules[name];
    
    if (!node && ![[name substringFromIndex:MAX(0, (NSInteger)(name.length - 2))] isEqualToString:@"/"]) {
        NSString *possiblePath = [name stringByAppendingString:@"/"];
        node = self.rules[possiblePath];
    }
    
    return node;
}

- (NSUInteger)countOfRuleNodes
{
    return self.rules.count;
}

- (void)addRegexRuleNode:(IESPrefetchRuleRegexNode *)node
{
    if (node.ruleName.length == 0) {
        return;
    }
    if (self.regexRules == nil) {
        self.regexRules = [NSMutableDictionary new];
    }
    self.regexRules[node.ruleName] = node;
}

- (IESPrefetchRuleRegexNode *)regexRuleNodeForName:(NSString *)name
{
    if (name.length == 0 || self.regexRules.count == 0) {
        return nil;
    }
    IESPrefetchRuleRegexNode *node = self.regexRules[name];
    return node;
}

- (NSUInteger)countOfRegexRuleNodes
{
    return self.regexRules.count;
}

- (id<IESPrefetchTemplateOutput>)process:(id<IESPrefetchTemplateInput>)input
{
    NSString *ruleName = input.name;
    IESPrefetchFlatSchema *schema = input.schema;
    NSDictionary<NSString *, NSString *> *variables = input.variables;
    IESPrefetchRuleNode *ruleNode = [self matchNodeForName:ruleName withSchema:schema];
    IESPrefetchTemplateOutput *result = [IESPrefetchTemplateOutput new];
    if (ruleNode == nil) {
        return result;
    }
    PrefetchMatcherLogV(@"[%@] Hit rule: %@", input.traceId, ruleNode.ruleName);
    [ruleNode.itemNodes enumerateObjectsUsingBlock:^(IESPrefetchRuleItemNode * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
        if (obj.apis.count == 0) {
            return;
        }
        BOOL match = [self matchItemNode:obj withSchema:schema];
        if (match) {
            [obj.apis enumerateObjectsUsingBlock:^(NSString * _Nonnull apiName, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
                id<IESPrefetchTemplateOutput> apiOutput = [self processAPI:apiName withSchema:schema variables:variables traceId:input.traceId];
                [result merge:apiOutput];
            }];
            *stop = YES; // 有一个符合条件就可以结束，不再往下匹配
        }
    }];
    return result;
}

- (IESPrefetchRuleNode *)matchNodeForName:(NSString *)ruleName withSchema:(IESPrefetchFlatSchema *)schema
{
    __block IESPrefetchRuleNode *node = [self ruleNodeForName:ruleName];
    if (node) {
        return node;
    }
    if (schema == nil) {
        return nil;
    }
    NSArray<NSString *> *pathComponents = [ruleName componentsSeparatedByString:@"/"];
    NSMutableDictionary<NSString *, NSString *> *pathVariables = [NSMutableDictionary new];
    [self.regexRules enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, IESPrefetchRuleRegexNode * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj.pathComponents.count == pathComponents.count) {
            BOOL matchSuccess = YES;
            for (NSUInteger i = 0; i < obj.pathComponents.count; i++) {
                NSString *currentPathItem = obj.pathComponents[i];
                if ([currentPathItem hasPrefix:@":"] && currentPathItem.length > 1) {
                    matchSuccess = YES;
                    pathVariables[[currentPathItem substringFromIndex:1]] = pathComponents[i];
                } else if ([currentPathItem isEqualToString:pathComponents[i]] == NO) {
                    matchSuccess = NO;
                    break;
                }
            }
            if (matchSuccess) {
                node = obj;
                *stop = YES;
            }
        }
    }];
    schema.pathVariables = [pathVariables copy];
    return node;
}

- (id<IESPrefetchTemplateOutput>)processAPI:(NSString *)api withSchema:(IESPrefetchFlatSchema *)schema variables:(NSDictionary<NSString *, NSString *> *)variables traceId:(NSString *)traceId
{
    IESPrefetchTemplateInput *nextInput = [IESPrefetchTemplateInput new];
    nextInput.name = api;
    nextInput.schema = schema;
    nextInput.variables = variables;
    nextInput.traceId = traceId;
    id<IESPrefetchTemplateOutput> output = [IESPrefetchTemplateOutput new];
    for (id<IESPrefetchConfigTemplate> child in self.children) {
        id<IESPrefetchTemplateOutput> nextOutput = [child process:nextInput];
        [output merge:nextOutput];
    }
    return output;
}

- (BOOL)matchItemNode:(IESPrefetchRuleItemNode *)node withSchema:(IESPrefetchFlatSchema *)schema
{
    if (node.fragment) {
        if ([node.fragment isEqualToString:schema.fragment] == NO) {
            return NO;
        }
    }
    if (node.queryNodes && node.queryNodes.count > 0) {
        __block BOOL matchResult = YES;
        if (schema.queryItems.count == 0) {
            return NO;
        }
        [node.queryNodes enumerateObjectsUsingBlock:^(IESPrefetchRuleQueryNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.key == nil) {
                return;
            }
            NSString *value = schema.queryItems[obj.key];
            if (value == nil) {
                matchResult = NO;
            } else if (obj.valueRegex.length > 0) {
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:obj.valueRegex options:0 error:nil];
                NSTextCheckingResult *regResult = [regex firstMatchInString:value options:0 range:NSMakeRange(0, value.length)];
                if (regResult == nil) {
                    matchResult = NO;
                }
            }
            if (matchResult == NO) {
                *stop = YES;
            }
        }];
        return matchResult;
    }
    return YES;
    
}

- (NSDictionary<NSString *,id> *)jsonRepresentation
{
    NSMutableDictionary<NSString *, id> *dict = [NSMutableDictionary new];
    NSMutableDictionary<NSString *, id> *ruleDict = [NSMutableDictionary new];
    [self.rules enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, IESPrefetchRuleNode * _Nonnull obj, BOOL * _Nonnull stop) {
        [ruleDict addEntriesFromDictionary:[obj jsonRepresentation]];
    }];
    NSMutableDictionary<NSString *, id> *regexRuleDict = [NSMutableDictionary new];
    [self.regexRules enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, IESPrefetchRuleRegexNode * _Nonnull obj, BOOL * _Nonnull stop) {
        [regexRuleDict addEntriesFromDictionary:[obj jsonRepresentation]];
    }];
    dict[@"rule"] = ruleDict.copy;
    dict[@"restful_rule"] = regexRuleDict.copy;
    [self.children enumerateObjectsUsingBlock:^(id<IESPrefetchConfigTemplate>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [dict addEntriesFromDictionary:[obj jsonRepresentation]];
    }];
    return dict.copy;
}

@end
