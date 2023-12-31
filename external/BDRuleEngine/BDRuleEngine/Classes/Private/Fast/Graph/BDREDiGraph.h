//
//  BDREDiGraph.h
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/13.
//

#import <Foundation/Foundation.h>

#import "BDREOutGraphNode.h"
#import "BDREConstGraphNode.h"
#import "BDREEntryGraphNode.h"
#import "BDREStrategyGraphNode.h"

@class BDRuleModel;
@class BDRETreeNode;

NS_ASSUME_NONNULL_BEGIN

@interface BDREDiGraph : NSObject

- (BDREConstGraphNode *)getConstNodeWithValue:(id<NSCopying>)value;
- (BDREEntryGraphNode *)getEntryNodeWithIdentifier:(NSString *)identifier;
- (BDREStrategyGraphNode *)getStrategyNodeWithName:(NSString *)name;

- (void)addOutGraphNode:(BDREOutGraphNode *)node;

- (void)addFallBackRuleModel:(BDRuleModel *)ruleModel;

- (void)addCommandTree:(BDRETreeNode *)treeNode index:(NSUInteger)index strategyName:(NSString *)strategyName ruleModel:(BDRuleModel *)ruleModel;

- (NSArray <NSString *> *)travelWithParams:(NSDictionary *)params needBreak:(BOOL)needBreak;

@end

NS_ASSUME_NONNULL_END
