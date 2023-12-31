//
//  BDREDiGraphBuilder.h
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/13.
//

#import <Foundation/Foundation.h>
#import "BDREGraphNode.h"
#import "BDREDiGraph.h"
#import "BDRETreeNode.h"

@class BDRuleGroupModel;

NS_ASSUME_NONNULL_BEGIN

@interface BDREDiGraphBuilder : NSObject

+ (nullable BDREDiGraph *)graphWithRuleGroupModel:(BDRuleGroupModel *)ruleGroupModel;

+ (nullable NSArray <BDREGraphNode *> *)graphNodesWithGraph:(BDREDiGraph *)graph treeNode:(BDRETreeNode *)treeNode index:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
