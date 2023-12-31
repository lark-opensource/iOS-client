//
//  BDREGraphNodeBuilderFactory.m
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/17.
//

#import "BDREGraphNodeBuilderFactory.h"
#import "BDREGraphNodeBuilder.h"
#import "BDREOperatorCommand.h"
#import "BDREFunctionCommand.h"
#import "BDREValueCommand.h"
#import "BDREAndGraphNode.h"
#import "BDREStringCmpGraphNode.h"
#import "BDREDiGraphBuilder.h"

#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

#pragma mark - Builders
@interface BDREArrayFuncGraphNodeBuiler : BDREGraphNodeBuilder
@end

@implementation BDREArrayFuncGraphNodeBuiler

- (NSArray<BDREGraphNode *> *)innerBuildNodeWithGraph:(BDREDiGraph *)graph treeNode:(BDRETreeNode *)treeNode index:(NSUInteger)index
{
    if (![treeNode.command isKindOfClass:BDREFunctionCommand.class]) return nil;
    if (![((BDREFunctionCommand *)treeNode.command).funcName isEqualToString:@"array"]) return nil;
    
    NSMutableArray *constObjs = [NSMutableArray array];
    for (BDRETreeNode *childNode in treeNode.children) {
        if (![childNode.command isKindOfClass:BDREValueCommand.class]) {
            return nil;
        }
        [constObjs btd_addObject:((BDREValueCommand *)childNode.command).value];
    }
    BDREConstGraphNode *constGraphNode = [[BDREConstGraphNode alloc] initWithValue:constObjs];
    return @[constGraphNode];
}

@end

@interface BDREAndOpGraphNodeBuilder : BDREGraphNodeBuilder
@end

@implementation BDREAndOpGraphNodeBuilder

- (NSArray<BDREGraphNode *> *)innerBuildNodeWithGraph:(BDREDiGraph *)graph treeNode:(BDRETreeNode *)treeNode index:(NSUInteger)index
{
    if (![self buildBasicCheckWithOpName:@"&&" treeNode:treeNode]) return nil;
    
    BDREAndGraphNode *andNode = [[BDREAndGraphNode alloc] init];
    
    NSArray<BDREGraphNode *> *leftNodes = [BDREDiGraphBuilder graphNodesWithGraph:graph treeNode:[treeNode.children btd_objectAtIndex:0] index:index];
    NSArray<BDREGraphNode *> *rightNodes = [BDREDiGraphBuilder graphNodesWithGraph:graph treeNode:[treeNode.children btd_objectAtIndex:1] index:index];
    if (!leftNodes.count || !rightNodes.count) return nil;
    for (BDREGraphNode *node in leftNodes) {
        [node addPointNode:andNode.leftDelegateNode];
    }
    for (BDREGraphNode *node in rightNodes) {
        [node addPointNode:andNode.rightDelegateNode];
    }
    
    return @[andNode];
}

@end

@interface BDREOrOpGraphNodeBuilder : BDREGraphNodeBuilder
@end

@implementation BDREOrOpGraphNodeBuilder

- (NSArray<BDREGraphNode *> *)innerBuildNodeWithGraph:(BDREDiGraph *)graph treeNode:(BDRETreeNode *)treeNode index:(NSUInteger)index
{
    if (![self buildBasicCheckWithOpName:@"||" treeNode:treeNode]) return nil;
    
    NSArray<BDREGraphNode *> *leftNodes = [BDREDiGraphBuilder graphNodesWithGraph:graph treeNode:[treeNode.children btd_objectAtIndex:0] index:index];
    NSArray<BDREGraphNode *> *rightNodes = [BDREDiGraphBuilder graphNodesWithGraph:graph treeNode:[treeNode.children btd_objectAtIndex:1] index:index];
    if (!leftNodes.count || !rightNodes.count) return nil;
    
    return [leftNodes arrayByAddingObjectsFromArray:rightNodes];
}

@end

@interface BDREInOpGraphNodeBuilder : BDREGraphNodeBuilder
@end

@implementation BDREInOpGraphNodeBuilder

- (NSArray<BDREGraphNode *> *)innerBuildNodeWithGraph:(BDREDiGraph *)graph treeNode:(BDRETreeNode *)treeNode index:(NSUInteger)index
{
    if (![self buildBasicCheckWithOpName:@"in" treeNode:treeNode]) return nil;
    
    NSArray<BDREGraphNode *> *leftNodes = [BDREDiGraphBuilder graphNodesWithGraph:graph treeNode:[treeNode.children btd_objectAtIndex:0] index:index];
    NSArray<BDREGraphNode *> *rightNodes = [BDREDiGraphBuilder graphNodesWithGraph:graph treeNode:[treeNode.children btd_objectAtIndex:1] index:index];
    if (!leftNodes.count || !rightNodes.count) return nil;
    
    BDREEntryGraphNode *entryNode = (BDREEntryGraphNode *)[leftNodes btd_objectAtIndex:0];
    BDREConstGraphNode *constNode = (BDREConstGraphNode *)[rightNodes btd_objectAtIndex:0];
    
    if (![entryNode isKindOfClass:BDREEntryGraphNode.class] || ![constNode isKindOfClass:BDREConstGraphNode.class]) return nil;
    
    NSMutableArray<BDREGraphNode *> *nodes = [NSMutableArray array];
    NSArray *constArray = (NSArray *)constNode.value;
    
    if (![constArray isKindOfClass:NSArray.class]) return nil;
    
    for (id obj in constArray) {
        BDREConstGraphNode *node = [graph getConstNodeWithValue:obj];
        [entryNode connectToConstNode:node];
        [nodes btd_addObject:node];
    }
    
    return [nodes copy];
}

@end

@interface BDREIsIntersectOpGraphNodeBuilder : BDREGraphNodeBuilder
@end

@implementation BDREIsIntersectOpGraphNodeBuilder

- (NSArray<BDREGraphNode *> *)innerBuildNodeWithGraph:(BDREDiGraph *)graph treeNode:(BDRETreeNode *)treeNode index:(NSUInteger)index
{
    if (![self buildBasicCheckWithOpName:@"isIntersect" treeNode:treeNode]) return nil;
    NSArray<BDREGraphNode *> *leftNodes = [BDREDiGraphBuilder graphNodesWithGraph:graph treeNode:[treeNode.children btd_objectAtIndex:0] index:index];
    NSArray<BDREGraphNode *> *rightNodes = [BDREDiGraphBuilder graphNodesWithGraph:graph treeNode:[treeNode.children btd_objectAtIndex:1] index:index];
    if (!leftNodes.count || !rightNodes.count) return nil;
    
    BDREEntryGraphNode *entryNode = (BDREEntryGraphNode *)[leftNodes btd_objectAtIndex:0];
    BDREConstGraphNode *constNode = (BDREConstGraphNode *)[rightNodes btd_objectAtIndex:0];
    if (![entryNode isKindOfClass:BDREEntryGraphNode.class] || ![constNode isKindOfClass:BDREConstGraphNode.class]) return nil;
    
    entryNode.isCollection = YES;
    NSMutableArray<BDREGraphNode *> *nodes = [NSMutableArray array];
    NSArray *constArray = (NSArray *)constNode.value;
    if (![constArray isKindOfClass:NSArray.class]) return nil;
    for (id obj in constArray) {
        BDREConstGraphNode *node = [graph getConstNodeWithValue:obj];
        [entryNode connectToConstNode:node];
        [nodes btd_addObject:node];
    }
    
    return [nodes copy];
}

@end

@interface BDREStringCmpOpGraphNodeBuilder : BDREGraphNodeBuilder

- (NSString *)operatorSymbol;
- (BDREStringCmpGraphNode *)stringCompareNodeWithStrs:(NSArray<NSString *> *)strs;

@end

@implementation BDREStringCmpOpGraphNodeBuilder

- (NSArray<BDREGraphNode *> *)innerBuildNodeWithGraph:(BDREDiGraph *)graph treeNode:(BDRETreeNode *)treeNode index:(NSUInteger)index
{
    if (![self buildBasicCheckWithOpName:[self operatorSymbol] treeNode:treeNode]) return nil;
    NSArray<BDREGraphNode *> *leftNodes = [BDREDiGraphBuilder graphNodesWithGraph:graph treeNode:[treeNode.children btd_objectAtIndex:0] index:index];
    NSArray<BDREGraphNode *> *rightNodes = [BDREDiGraphBuilder graphNodesWithGraph:graph treeNode:[treeNode.children btd_objectAtIndex:1] index:index];
    if (!leftNodes.count || !rightNodes.count) return nil;
    
    BDREEntryGraphNode *entryNode = (BDREEntryGraphNode *)[leftNodes btd_objectAtIndex:0];
    BDREConstGraphNode *constNode = (BDREConstGraphNode *)[rightNodes btd_objectAtIndex:0];
    
    if (![entryNode isKindOfClass:BDREEntryGraphNode.class] || ![constNode isKindOfClass:BDREConstGraphNode.class]) return nil;
    NSArray *cmpStrs = nil;
    if ([constNode.value isKindOfClass:NSString.class]) {
        cmpStrs = @[constNode.value];
    } else if ([constNode.value isKindOfClass:NSArray.class]) {
        cmpStrs = constNode.value;
    } else if ([constNode.value isKindOfClass:NSSet.class]) {
        cmpStrs = ((NSSet *)constNode.value).allObjects;
    } else {
        return nil;
    }
    BDREStringCmpGraphNode *cmpNode = [self stringCompareNodeWithStrs:cmpStrs];
    [entryNode addPointNode:cmpNode];
    return @[cmpNode];
}

- (NSString *)operatorSymbol
{
    return @"equalwith";
}

- (BDREStringCmpGraphNode *)stringCompareNodeWithStrs:(NSArray<NSString *> *)strs
{
    return [[BDREStringCmpGraphNode alloc] initWithComparedStrs:strs];
}

@end

@interface BDREEndWithOpGraphNodeBuilder: BDREStringCmpOpGraphNodeBuilder
@end

@implementation BDREEndWithOpGraphNodeBuilder

- (NSString *)operatorSymbol
{
    return @"endwith";
}

- (BDREStringCmpGraphNode *)stringCompareNodeWithStrs:(NSArray<NSString *> *)strs
{
    return [[BDREEndWithGraphNode alloc] initWithComparedStrs:strs];
}

@end

@interface BDREStartWithOpGraphNodeBuilder: BDREStringCmpOpGraphNodeBuilder
@end

@implementation BDREStartWithOpGraphNodeBuilder

- (NSString *)operatorSymbol
{
    return @"startwith";
}

- (BDREStringCmpGraphNode *)stringCompareNodeWithStrs:(NSArray<NSString *> *)strs
{
    return [[BDREStartWithGraphNode alloc] initWithComparedStrs:strs];
}

@end

@interface BDREMatchesOpGraphNodeBuilder: BDREStringCmpOpGraphNodeBuilder
@end

@implementation BDREMatchesOpGraphNodeBuilder

- (NSString *)operatorSymbol
{
    return @"matches";
}

- (BDREStringCmpGraphNode *)stringCompareNodeWithStrs:(NSArray<NSString *> *)strs
{
    return [[BDREMatchesGraphNode alloc] initWithComparedStrs:strs];
}

@end

@interface BDREContainsOpGraphNodeBuilder: BDREStringCmpOpGraphNodeBuilder
@end

@implementation BDREContainsOpGraphNodeBuilder

- (NSString *)operatorSymbol
{
    return @"contains";
}

- (BDREStringCmpGraphNode *)stringCompareNodeWithStrs:(NSArray<NSString *> *)strs
{
    return [[BDREContainsGraphNode alloc] initWithComparedStrs:strs];
}

@end

@interface BDREOutOpGraphNodeBuilder : BDREGraphNodeBuilder
@end

@implementation BDREOutOpGraphNodeBuilder

- (NSArray<BDREGraphNode *> *)innerBuildNodeWithGraph:(BDREDiGraph *)graph treeNode:(BDRETreeNode *)treeNode index:(NSUInteger)index
{
    if (![self buildBasicCheckWithOpName:@"out" treeNode:treeNode]) return nil;
    
    NSArray<BDREGraphNode *> *leftNodes = [BDREDiGraphBuilder graphNodesWithGraph:graph treeNode:[treeNode.children btd_objectAtIndex:0] index:index];
    NSArray<BDREGraphNode *> *rightNodes = [BDREDiGraphBuilder graphNodesWithGraph:graph treeNode:[treeNode.children btd_objectAtIndex:1] index:index];
    if (!leftNodes.count || !rightNodes.count) return nil;
    
    BDREEntryGraphNode *entryNode = (BDREEntryGraphNode *)[leftNodes btd_objectAtIndex:0];
    BDREConstGraphNode *constNode = (BDREConstGraphNode *)[rightNodes btd_objectAtIndex:0];
    
    if (![entryNode isKindOfClass:BDREEntryGraphNode.class] || ![constNode isKindOfClass:BDREConstGraphNode.class]) return nil;
    
    NSArray *constArray = (NSArray *)constNode.value;
    if (![constArray isKindOfClass:NSArray.class]) return nil;
    
    BDREOutGraphNode *outNode = [[BDREOutGraphNode alloc] init];
    [graph addOutGraphNode:outNode];
    for (id value in constArray) {
        BDREConstGraphNode *eachConstNode = [graph getConstNodeWithValue:value];
        [entryNode connectToConstNode:eachConstNode];
        [eachConstNode addPointNode:outNode];
    }
    
    return @[outNode];
}

@end

@interface BDREEqualOpGraphNodeBuilder : BDREGraphNodeBuilder
@end

@implementation BDREEqualOpGraphNodeBuilder

- (NSArray<BDREGraphNode *> *)innerBuildNodeWithGraph:(BDREDiGraph *)graph treeNode:(BDRETreeNode *)treeNode index:(NSUInteger)index
{
    if (![self buildBasicCheckWithOpName:@"==" treeNode:treeNode]) return nil;
    
    NSArray<BDREGraphNode *> *leftNodes = [BDREDiGraphBuilder graphNodesWithGraph:graph treeNode:[treeNode.children btd_objectAtIndex:0] index:index];
    NSArray<BDREGraphNode *> *rightNodes = [BDREDiGraphBuilder graphNodesWithGraph:graph treeNode:[treeNode.children btd_objectAtIndex:1] index:index];
    if (!leftNodes.count || !rightNodes.count) return nil;
    
    BDREEntryGraphNode *entryNode = (BDREEntryGraphNode *)[leftNodes btd_objectAtIndex:0];
    BDREConstGraphNode *constNode = (BDREConstGraphNode *)[rightNodes btd_objectAtIndex:0];
    if (![entryNode isKindOfClass:BDREEntryGraphNode.class] || ![constNode isKindOfClass:BDREConstGraphNode.class]) return nil;
    
    [entryNode connectToConstNode:constNode];
    
    return @[constNode];
}

@end

@interface BDRENotEqualGraphNodeBuilder : BDREGraphNodeBuilder
@end

@implementation BDRENotEqualGraphNodeBuilder

- (NSArray<BDREGraphNode *> *)innerBuildNodeWithGraph:(BDREDiGraph *)graph treeNode:(BDRETreeNode *)treeNode index:(NSUInteger)index
{
    if (![self buildBasicCheckWithOpName:@"!=" treeNode:treeNode]) return nil;
    
    NSArray<BDREGraphNode *> *leftNodes = [BDREDiGraphBuilder graphNodesWithGraph:graph treeNode:[treeNode.children btd_objectAtIndex:0] index:index];
    NSArray<BDREGraphNode *> *rightNodes = [BDREDiGraphBuilder graphNodesWithGraph:graph treeNode:[treeNode.children btd_objectAtIndex:1] index:index];
    if (!leftNodes.count || !rightNodes.count) return nil;
    
    BDREEntryGraphNode *entryNode = (BDREEntryGraphNode *)[leftNodes btd_objectAtIndex:0];
    BDREConstGraphNode *constNode = (BDREConstGraphNode *)[rightNodes btd_objectAtIndex:0];
    
    if (![entryNode isKindOfClass:BDREEntryGraphNode.class] || ![constNode isKindOfClass:BDREConstGraphNode.class]) return nil;
    
    BDREOutGraphNode *outNode = [[BDREOutGraphNode alloc] init];
    [graph addOutGraphNode:outNode];
    [entryNode connectToConstNode:constNode];
    [constNode addPointNode:outNode];
    
    return @[outNode];
}

@end

@interface BDRENotGraphNodeBuilder : BDREGraphNodeBuilder
@end

@implementation BDRENotGraphNodeBuilder

- (NSArray<BDREGraphNode *> *)innerBuildNodeWithGraph:(BDREDiGraph *)graph treeNode:(BDRETreeNode *)treeNode index:(NSUInteger)index
{
    if (![self buildBasicCheckWithOpName:@"!" treeNode:treeNode]) return nil;
    
    NSArray<BDREGraphNode *> *nodes = [BDREDiGraphBuilder graphNodesWithGraph:graph treeNode:[treeNode.children btd_objectAtIndex:0] index:index];
    if (!nodes.count) return nil;
    BDREOutGraphNode *outNode = [[BDREOutGraphNode alloc] init];
    [graph addOutGraphNode:outNode];
    
    for (BDREGraphNode *childNode in nodes) {
        [childNode addPointNode:outNode];
    }
    return @[outNode];
}

@end

#pragma mark - Factory
@interface BDREGraphNodeBuilderFactory ()

@property (nonatomic, strong, readonly) NSDictionary<NSString *, BDREGraphNodeBuilder *> *operatorBuilderMap;
@property (nonatomic, strong, readonly) NSDictionary<NSString *, BDREGraphNodeBuilder *> *functionBuilderMap;

@end

@implementation BDREGraphNodeBuilderFactory

+ (instancetype)sharedFactory
{
    static BDREGraphNodeBuilderFactory *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return  shared;
}

- (instancetype)init
{
    if (self = [super init]) {
        _operatorBuilderMap = @{
            @"&&"          : [[BDREAndOpGraphNodeBuilder alloc] init],
            @"||"          : [[BDREOrOpGraphNodeBuilder alloc] init],
            @"=="          : [[BDREEqualOpGraphNodeBuilder alloc] init],
            @"!="          : [[BDRENotEqualGraphNodeBuilder alloc] init],
            @"in"          : [[BDREInOpGraphNodeBuilder alloc] init],
            @"out"         : [[BDREOutOpGraphNodeBuilder alloc] init],
            @"!"           : [[BDRENotGraphNodeBuilder alloc] init],
            @"equalwith"   : [[BDREStringCmpOpGraphNodeBuilder alloc] init],
            @"startwith"   : [[BDREStartWithOpGraphNodeBuilder alloc] init],
            @"endwith"     : [[BDREEndWithOpGraphNodeBuilder alloc] init],
            @"contains"    : [[BDREContainsOpGraphNodeBuilder alloc] init],
            @"matches"     : [[BDREMatchesOpGraphNodeBuilder alloc] init],
            @"isIntersect" : [[BDREIsIntersectOpGraphNodeBuilder alloc] init]
        };
        
        _functionBuilderMap = @{
            @"array" : [[BDREArrayFuncGraphNodeBuiler alloc] init]
        };
    }
    return self;
}

+ (BDREGraphNodeBuilder *)builderWithOpName:(NSString *)name
{
    return [[BDREGraphNodeBuilderFactory sharedFactory].operatorBuilderMap btd_objectForKey:name default:nil];
}

+ (BDREGraphNodeBuilder *)builderWithFuncName:(NSString *)name
{
    return [[BDREGraphNodeBuilderFactory sharedFactory].functionBuilderMap btd_objectForKey:name default:nil];
}

@end
