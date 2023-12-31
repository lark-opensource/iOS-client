//
//  BDREGraphNodeBuilder.h
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/13.
//

#import <Foundation/Foundation.h>

#import "BDREGraphNode.h"
#import "BDREDiGraph.h"
#import "BDRETreeNode.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDREGraphNodeBuilderProtocol <NSObject>

@required
- (nullable NSArray<BDREGraphNode *> *)innerBuildNodeWithGraph:(BDREDiGraph *)graph treeNode:(BDRETreeNode *)treeNode index:(NSUInteger)index;

@end

@interface BDREGraphNodeBuilder : NSObject<BDREGraphNodeBuilderProtocol>

- (nullable NSArray<BDREGraphNode *> *)buildNodeWithGraph:(BDREDiGraph *)graph treeNode:(BDRETreeNode *)treeNode index:(NSUInteger)index;

- (BOOL)buildBasicCheckWithOpName:(NSString *)opName treeNode:(BDRETreeNode *)treeNode;

@end

NS_ASSUME_NONNULL_END
