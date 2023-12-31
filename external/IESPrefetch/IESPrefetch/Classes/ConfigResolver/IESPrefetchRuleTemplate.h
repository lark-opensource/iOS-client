//
//  IESPrefetchRuleTemplate.h
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/2.
//

#import <Foundation/Foundation.h>
#import "IESPrefetchConfigTemplate.h"

NS_ASSUME_NONNULL_BEGIN

/// rule的query参数匹配规则
@interface IESPrefetchRuleQueryNode : NSObject

/// query的参数名称筛选
@property (nonatomic, copy) NSString *key;
/// key对应的参数值的正则匹配
@property (nonatomic, copy) NSString *valueRegex;

@end

/// rule的一条匹配规则，分为hash匹配，query匹配。两者都没有则直接匹配
@interface IESPrefetchRuleItemNode : NSObject

/// hash部分
@property (nonatomic, copy) NSString *fragment;
/// 规则对应的apis
@property (nonatomic, copy) NSArray<NSString *> *apis;
/// query部分的匹配规则节点，数组中的query规则需要都匹配
@property (nonatomic, copy) NSArray<IESPrefetchRuleQueryNode *> *queryNodes;

@end

/// 一条rule节点定义
@interface IESPrefetchRuleNode : NSObject

/// rule的名称
@property (nonatomic, copy) NSString *ruleName;
/// rule的匹配规则数组，数组中每一个元素单独进行匹配验证
@property (nonatomic, copy) NSArray<IESPrefetchRuleItemNode *> *itemNodes;

@end

@interface IESPrefetchRuleRegexNode : IESPrefetchRuleNode

/// 从ruleName中提取出来的参数名称
@property (nonatomic, copy) NSArray<NSString *> * pathComponents;

@end

@interface IESPrefetchRuleTemplate : NSObject<IESPrefetchConfigTemplate>

/// 添加一条rule节点
- (void)addRuleNode:(IESPrefetchRuleNode *)node;
/// 根据rule节点名称获取节点实体
- (IESPrefetchRuleNode *)ruleNodeForName:(NSString *)name;
/// 节点数量
- (NSUInteger)countOfRuleNodes;

- (void)addRegexRuleNode:(IESPrefetchRuleRegexNode *)node;
- (IESPrefetchRuleRegexNode *)regexRuleNodeForName:(NSString *)name;
- (NSUInteger)countOfRegexRuleNodes;

@end

NS_ASSUME_NONNULL_END
