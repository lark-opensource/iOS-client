//
//  BDREDiGraphBuilder.m
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/13.
//

#import "BDREDiGraphBuilder.h"
#import "BDREIdentifierCommand.h"
#import "BDREFunctionCommand.h"
#import "BDREOperatorCommand.h"
#import "BDREValueCommand.h"
#import "BDRuleParameterRegistry.h"
#import "BDREGraphNodeBuilderFactory.h"
#import "BDStrategyCenterConstant.h"
#import "BDRECommandTreeBuildUtil.h"
#import "BDRuleGroupModel.h"

#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@implementation BDREDiGraphBuilder

+ (BDREDiGraph *)graphWithRuleGroupModel:(BDRuleGroupModel *)ruleGroupModel
{
    BDREDiGraph *graph = [[BDREDiGraph alloc] init];
    for (NSUInteger index = 0; index < ruleGroupModel.rules.count; index++) {
        BDRuleModel *ruleModel = [ruleGroupModel.rules btd_objectAtIndex:index];
        NSString *strategyName = [ruleModel.conf btd_stringValueForKey:BDStrategyMapResultKey];
        BDRETreeNode *treeNode = [BDRECommandTreeBuildUtil generateWithCommands:ruleModel.commands];
        [graph addCommandTree:treeNode index:index strategyName:strategyName ruleModel:ruleModel];
    }
    return graph;
}

+ (NSArray<BDREGraphNode *> *)graphNodesWithGraph:(BDREDiGraph *)graph treeNode:(BDRETreeNode *)treeNode index:(NSUInteger)index
{
    NSMutableArray<BDREGraphNode *> *nodes = [NSMutableArray array];
    if ([treeNode.command isKindOfClass:BDREIdentifierCommand.class]) {
        BDREIdentifierCommand *idCommand = (BDREIdentifierCommand *)treeNode.command;
        NSString *identifier = idCommand.identifier;
        BDRuleParameterBuilderModel *buildermodel = [BDRuleParameterRegistry builderForKey:identifier];
        if (buildermodel) {
            switch (buildermodel.origin) {
                case BDRuleParameterOriginState:
                {
                    BDREEntryGraphNode *entryNode = [graph getEntryNodeWithIdentifier:identifier];
                    entryNode.isRegisterParam = YES;
                    if (!entryNode) return nil;
                    [nodes btd_addObject:entryNode];
                }
                    break;
                case BDRuleParameterOriginConst:
                {
                    id constValue = buildermodel.builder(nil);
                    BDREConstGraphNode *constNode = [graph getConstNodeWithValue:constValue];
                    if (!constNode) return nil;
                    [nodes btd_addObject:constNode];
                }
                    break;
            }
        } else {
            BDREEntryGraphNode *entryNode = [graph getEntryNodeWithIdentifier:identifier];
            if (!entryNode) return nil;
            [nodes btd_addObject:entryNode];
        }
    } else if ([treeNode.command isKindOfClass:BDREValueCommand.class]) {
        id constValue = ((BDREValueCommand *)treeNode.command).value;
        BDREConstGraphNode *constNode = [graph getConstNodeWithValue:constValue];
        if (!constNode) return nil;
        [nodes btd_addObject:constNode];
    } else if ([treeNode.command isKindOfClass:BDREOperatorCommand.class]) {
        BDREGraphNodeBuilder *builder = [BDREGraphNodeBuilderFactory builderWithOpName:((BDREOperatorCommand *)treeNode.command).operator.symbol];
        if (!builder) return nil;
        return [builder buildNodeWithGraph:graph treeNode:treeNode index:index];
    } else if ([treeNode.command isKindOfClass:BDREFunctionCommand.class]) {
        BDREGraphNodeBuilder *builder = [BDREGraphNodeBuilderFactory builderWithFuncName:((BDREFunctionCommand *)treeNode.command).funcName];
        if (!builder) return nil;
        return [builder buildNodeWithGraph:graph treeNode:treeNode index:index];
    }
    
    for (BDREGraphNode *node in nodes) {
        [node updateMinIndex:index];
    }
    
    return nodes.count ? [nodes copy] : nil;
}

@end
