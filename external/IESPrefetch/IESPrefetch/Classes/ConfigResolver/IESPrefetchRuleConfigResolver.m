//
//  IESPrefetchRuleConfigResolver.m
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/3.
//

#import "IESPrefetchRuleConfigResolver.h"
#import "IESPrefetchRuleTemplate.h"
#import "IESPrefetchLogger.h"
#import <ByteDanceKit/ByteDanceKit.h>

@interface IESPrefetchRuleConfigResolver ()

- (IESPrefetchRuleNode *)resolveRule:(id)config forName:(NSString *)name;
- (IESPrefetchRuleItemNode *)resolveItem:(NSDictionary *)config;
- (IESPrefetchRuleQueryNode *)resolveQuery:(NSDictionary *)config;

@end

@implementation IESPrefetchRuleConfigResolver

- (id<IESPrefetchConfigTemplate>)resolveConfig:(NSDictionary *)config
{
    if (config.count == 0) {
        PrefetchConfigLogW(@"rule config is empty ");
        return nil;
    }
    NSDictionary *ruleConfig = config[@"rules"];
    if (!([ruleConfig isKindOfClass:[NSDictionary class]] && ruleConfig.count > 0)) {
        PrefetchConfigLogW(@"rule config is empty or invalid.");
        return nil;
    }
    IESPrefetchRuleTemplate *ruleTemplate = [IESPrefetchRuleTemplate new];
    [ruleConfig.allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id value = ruleConfig[obj];
        IESPrefetchRuleNode *node = [self resolveRule:value forName:obj];
        [ruleTemplate addRuleNode:node];
    }];
    if ([ruleTemplate countOfRuleNodes] == 0) {
        return nil;
    }
    
    NSDictionary *regexRuleConfig = config[@"restful_rules"];
    if (!([regexRuleConfig isKindOfClass:[NSDictionary class]] && regexRuleConfig.count > 0)) {
        PrefetchConfigLogD(@"restful_rules config is empty or invalid.");
        return ruleTemplate;
    }
    [regexRuleConfig.allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id value = regexRuleConfig[obj];
        IESPrefetchRuleRegexNode *node = [self resolveRegexRule:value forName:obj];
        [ruleTemplate addRegexRuleNode:node];
    }];
    
    return ruleTemplate;
}

- (IESPrefetchRuleNode *)resolveRule:(id)config forName:(NSString *)name
{
    if (config == nil) {
        return nil;
    }
    if (name.length == 0) {
        return nil;
    }
    NSArray *configArray = nil;
    if ([config isKindOfClass:[NSArray class]]) {
        configArray = (NSArray *)config;
    } else if ([config isKindOfClass:[NSDictionary class]]) {
        configArray = @[config];
    }
    
    if (configArray.count == 0) {
        PrefetchConfigLogD(@"rule config %@'s content is empty", name);
        return nil;
    }
    NSMutableArray<IESPrefetchRuleItemNode *> *items = [NSMutableArray new];
    [configArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        IESPrefetchRuleItemNode *item = [self resolveItem:obj];
        if (item) {
            [items addObject:item];
        }
    }];
    if (items.count == 0) {
        PrefetchConfigLogD(@"rule config %@'s content :%@ is invalid", name, config);
        return nil;
    }
    IESPrefetchRuleNode *node = [IESPrefetchRuleNode new];
    node.ruleName = name;
    node.itemNodes = [items copy];
    return node;
}

- (IESPrefetchRuleRegexNode *)resolveRegexRule:(id)config forName:(NSString *)name
{
    if (config == nil) {
        return nil;
    }
    if (name.length == 0) {
        return nil;
    }
    NSArray *configArray = nil;
    if ([config isKindOfClass:[NSArray class]]) {
        configArray = (NSArray *)config;
    } else if ([config isKindOfClass:[NSDictionary class]]) {
        configArray = @[config];
    }
    
    if (configArray.count == 0) {
        PrefetchConfigLogD(@"restful_rule config %@'s content is empty", name);
        return nil;
    }
    NSMutableArray<IESPrefetchRuleItemNode *> *items = [NSMutableArray new];
    [configArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        IESPrefetchRuleItemNode *item = [self resolveItem:obj];
        if (item) {
            [items addObject:item];
        }
    }];
    if (items.count == 0) {
        PrefetchConfigLogD(@"rule config %@'s content :%@ is invalid", name, config);
        return nil;
    }
    IESPrefetchRuleRegexNode *node = [IESPrefetchRuleRegexNode new];
    NSArray<NSString *> *pathComponents = [name componentsSeparatedByString:@"/"];
    node.pathComponents = [pathComponents copy];
    node.ruleName = name;
    node.itemNodes = [items copy];
    return node;
}

- (IESPrefetchRuleItemNode *)resolveItem:(NSDictionary *)config
{
    if (!([config isKindOfClass:[NSDictionary class]] && config.count > 0)) {
        return nil;
    }
    IESPrefetchRuleItemNode *node = [IESPrefetchRuleItemNode new];
    NSString *fragment = [config btd_stringValueForKey:@"hash"];
    if ([fragment hasPrefix:@"#"] && fragment.length > 1) {
        fragment = [fragment substringFromIndex:1];
    }
    node.fragment = fragment;
    node.apis = config[@"prefetch_apis"];
    if (![node.apis isKindOfClass:[NSArray class]] || node.apis.count == 0) {
        PrefetchConfigLogD(@"matching rules apis is empty，ignore rule: %@", config.description);
        return nil;
    }
    NSArray *queryConfigs = config[@"query"];
    NSMutableArray<IESPrefetchRuleQueryNode *> *queryNodes = [NSMutableArray new];
    if ([queryConfigs isKindOfClass:[NSArray class]] && queryConfigs.count > 0) {
        [queryConfigs enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            IESPrefetchRuleQueryNode *query = [self resolveQuery:obj];
            if (query) {
                [queryNodes addObject:query];
            }
        }];
        node.queryNodes = [queryNodes copy];
    }
    
    return node;
}

- (IESPrefetchRuleQueryNode *)resolveQuery:(NSDictionary *)config
{
    if (!([config isKindOfClass:[NSDictionary class]] && config.count > 0)) {
        return nil;
    }
    IESPrefetchRuleQueryNode *node = [IESPrefetchRuleQueryNode new];
    node.key = [config btd_stringValueForKey:@"key"];
    node.valueRegex = [config btd_stringValueForKey:@"value"];
    if (node.key.length == 0) {
        PrefetchConfigLogD(@"query key is empty，ignore query rule: %@", config.description);
        return nil;
    }
    return node;
}

@end
