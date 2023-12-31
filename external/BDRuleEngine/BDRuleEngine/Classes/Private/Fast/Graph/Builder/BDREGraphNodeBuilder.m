//
//  BDREGraphNodeBuilder.m
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/13.
//

#import "BDREGraphNodeBuilder.h"
#import "BDREOperatorCommand.h"

@implementation BDREGraphNodeBuilder

- (NSArray<BDREGraphNode *> *)buildNodeWithGraph:(BDREDiGraph *)graph treeNode:(BDRETreeNode *)treeNode index:(NSUInteger)index
{
    NSArray *nodes = [self innerBuildNodeWithGraph:graph treeNode:treeNode index:index];
    for (BDREGraphNode *node in nodes) {
        [node updateMinIndex:index];
    }
    return nodes;
}

- (NSArray<BDREGraphNode *> *)innerBuildNodeWithGraph:(BDREDiGraph *)graph treeNode:(BDRETreeNode *)treeNode index:(NSUInteger)index
{
    return nil;
}

- (BOOL)buildBasicCheckWithOpName:(NSString *)opName treeNode:(BDRETreeNode *)treeNode
{
    if (![treeNode.command isKindOfClass:BDREOperatorCommand.class]) return NO;
    BDREOperator *op = ((BDREOperatorCommand *)treeNode.command).operator;
    if (![op.symbol isEqualToString:opName]) return NO;
    if (treeNode.children.count != op.argsLength) return NO;
    return YES;
}

@end
