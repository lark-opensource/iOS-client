//
//  BDREGraphNode.m
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/13.
//

#import "BDREGraphNode.h"

#import <ByteDanceKit/NSArray+BTDAdditions.h>

@interface BDREGraphNode ()

@property (nonatomic, strong) NSMutableArray<BDREGraphNode *> *innerPointNodes;
@property (nonatomic, assign) NSUInteger minIndex;

@end

@implementation BDREGraphNode

- (instancetype)init
{
    if (self = [super init]) {
        _innerPointNodes = [NSMutableArray array];
        _minIndex = NSUIntegerMax;
    }
    return self;
}

- (void)travelWithFootPrint:(BDREGraphFootPrint *)graphFootPrint
{
    if ([self canPassWithFootPrint:graphFootPrint]) {
        for (BDREGraphNode *pointNode in self.pointNodes) {
            [pointNode visitWithFootPrint:graphFootPrint previousNode:self];
            [pointNode travelWithFootPrint:graphFootPrint];
        }
    }
}

- (BOOL)canPassWithFootPrint:(BDREGraphFootPrint *)graphFootPrint
{
    return (!graphFootPrint.needBreak) || (self.minIndex < graphFootPrint.minIndex) || (graphFootPrint.minIndex == NSUIntegerMax);
}

- (void)visitWithFootPrint:(BDREGraphFootPrint *)graphFootPrint previousNode:(BDREGraphNode *)previousNode
{
    BDRENodeFootPrint *nodeFootPrint = [graphFootPrint nodeFootPrintWithGraphNodeID:[self identifier]];
    nodeFootPrint.isVisited = YES;
}

- (BOOL)isVisitedWithFootPrint:(BDREGraphFootPrint *)graphFootPrint
{
    BDRENodeFootPrint *nodeFootPrint = [graphFootPrint nodeFootPrintWithGraphNodeID:[self identifier]];
    return nodeFootPrint.isVisited;
}

- (void)addPointNode:(BDREGraphNode *)node
{
    [self.innerPointNodes btd_addObject:node];
}

- (void)updateMinIndex:(NSUInteger)index
{
    _minIndex = MIN(_minIndex, index);
}

- (id)valueWithFootPrint:(BDREGraphFootPrint *)graphFootPrint
{
    return @1;
}

- (NSArray<BDREGraphNode *> *)pointNodes
{
    return [self.innerPointNodes copy];
}

- (NSString *)identifier
{
    return [NSString stringWithFormat:@"%p", self];
}

@end
