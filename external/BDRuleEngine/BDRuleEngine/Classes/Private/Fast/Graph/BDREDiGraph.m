//
//  BDREDiGraph.m
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/13.
//

#import "BDREDiGraph.h"
#import "BDREGraphNode.h"
#import "BDREGraphFootPrint.h"
#import "BDRuleExecutor.h"
#import "BDRuleResultModel.h"
#import "BDStrategyCenterConstant.h"
#import "BDREValueCommand.h"
#import "BDRETreeNode.h"
#import "BDREDiGraphBuilder.h"
#import "BDStrategyCenterConstant.h"
#import "BDRuleGroupModel.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>

@interface BDREDiGraph ()

@property (nonatomic, strong) NSMutableDictionary<id<NSCopying>, BDREConstGraphNode *> *constNodeMap;
@property (nonatomic, strong) NSMutableDictionary<id<NSCopying>, BDREStrategyGraphNode *> *strategyNodeMap;

@property (nonatomic, strong) NSMutableArray<BDREEntryGraphNode *> *entryNodes;
@property (nonatomic, strong) NSMutableArray<BDREOutGraphNode *> *outNodes;

@property (nonatomic, strong) NSMutableArray<BDRuleModel *> *fallBackRuleModels;
@property (nonatomic, strong) NSMutableArray<NSString *> *defaultStratgies;

@end

@implementation BDREDiGraph

- (instancetype)init
{
    if (self = [super init]) {
        _constNodeMap = [NSMutableDictionary dictionary];
        _strategyNodeMap = [NSMutableDictionary dictionary];
        _entryNodes = [NSMutableArray array];
        _outNodes = [NSMutableArray array];
        _fallBackRuleModels = [NSMutableArray array];
        _defaultStratgies = [NSMutableArray array];
    }
    return self;
}

- (NSArray <NSString *> *)travelWithParams:(NSDictionary *)params needBreak:(BOOL)needBreak
{
    BDREGraphFootPrint *graphFootPrint = [[BDREGraphFootPrint alloc] initWithParams:params needBreak:needBreak];
    
    // Step 1: traversal begins with entry nodes
    for (BDREEntryGraphNode *entryNode in self.entryNodes) {
        [entryNode travelWithFootPrint:graphFootPrint];
    }
    graphFootPrint.isFirstTravelFinished = YES;
    // Step 2: traversal resume with out nodes
    for (BDREOutGraphNode *outNode in self.outNodes) {
        [outNode travelWithFootPrint:graphFootPrint];
    }
    // Step 3: process fallback rules
    if (self.fallBackRuleModels.count) {
        BDRuleGroupModel *ruleGroup = [[BDRuleGroupModel alloc] initWithArray:self.fallBackRuleModels name:@""];
        BDRuleResultModel *result = [[[BDRuleExecutor alloc] initWithParameters:params] executeRule:ruleGroup execAllRules:needBreak];
        for (BDSingleRuleResult *singleRes in result.values) {
            NSString *strategyName = [singleRes.conf btd_stringValueForKey:BDStrategyMapResultKey];
            BDREStrategyGraphNode *strategyNode = [self getStrategyNodeWithName:strategyName];
            [strategyNode travelWithFootPrint:graphFootPrint];
        }
    }
    NSArray *hitStrategyNames = [graphFootPrint hitStrategyNames];
    
    if (!needBreak) {
        return [hitStrategyNames arrayByAddingObjectsFromArray:self.defaultStratgies];
    }
    if (hitStrategyNames.count) return hitStrategyNames;
    return [self.defaultStratgies copy];
}

- (void)addCommandTree:(BDRETreeNode *)treeNode index:(NSUInteger)index strategyName:(NSString *)strategyName ruleModel:(BDRuleModel *)ruleModel
{
    if (!treeNode.children.count && [treeNode.command isKindOfClass:BDREValueCommand.class]) {
        BDREValueCommand *valueCmd = (BDREValueCommand *)treeNode.command;
        if ([valueCmd.value isEqual:@1]) {
            NSString *strategy = [ruleModel.conf btd_stringValueForKey:BDStrategyMapResultKey];
            [self.defaultStratgies btd_addObject:strategy];
            return;
        }
    }
    BDREStrategyGraphNode *strategyNode = [self getStrategyNodeWithName:strategyName];
    [strategyNode updateMinIndex:index];
    NSArray<BDREGraphNode *> *topNodes = [BDREDiGraphBuilder graphNodesWithGraph:self treeNode:treeNode index:index];
    if (topNodes.count) {
        for (BDREGraphNode *topNode in topNodes) {
            [topNode addPointNode:strategyNode];
        }
    } else {
        [self addFallBackRuleModel:ruleModel];
    }
}

- (BDREConstGraphNode *)getConstNodeWithValue:(id<NSCopying>)value
{
    if (!value) return nil;
    BDREConstGraphNode *node = [self.constNodeMap btd_objectForKey:value default:nil];
    if (!node) {
        node = [[BDREConstGraphNode alloc] initWithValue:value];
        [self.constNodeMap btd_setObject:node forKey:value];
    }
    return node;
}

- (BDREStrategyGraphNode *)getStrategyNodeWithName:(NSString *)name
{
    if (!name) return nil;
    BDREStrategyGraphNode *node = [self.strategyNodeMap btd_objectForKey:name default:nil];
    if (!node) {
        node = [[BDREStrategyGraphNode alloc] initWithStrategyName:name];
        [self.strategyNodeMap btd_setObject:node forKey:name];
    }
    return node;
}

- (BDREEntryGraphNode *)getEntryNodeWithIdentifier:(NSString *)identifier
{
    if (!identifier) return nil;
    BDREEntryGraphNode *node = nil;
    for (BDREEntryGraphNode *entryNode in self.entryNodes) {
        if ([entryNode.identifier isEqualToString:identifier]) {
            node = entryNode;
            break;
        }
    }
    if (!node) {
        node = [[BDREEntryGraphNode alloc] initWithIdentifier:identifier];
        [self.entryNodes btd_addObject:node];
    }
    return node;
}

- (void)addOutGraphNode:(BDREOutGraphNode *)node
{
    [_outNodes btd_addObject:node];
}

- (void)addFallBackRuleModel:(BDRuleModel *)ruleModel
{
    [_fallBackRuleModels btd_addObject:ruleModel];
}

@end
