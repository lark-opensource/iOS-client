//
//  BDREAndGraphNode.m
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/18.
//

#import "BDREAndGraphNode.h"

@interface BDREAndDelegateGraphNode ()
@property (nonatomic, strong) BDREAndGraphNode *andNode;
@end

@implementation BDREAndDelegateGraphNode

- (instancetype)initWithAndNode:(BDREAndGraphNode *)andNode
{
    if (self = [super init]) {
        _andNode = andNode;
        [self updateMinIndex:andNode.minIndex];
    }
    return self;
}

- (NSArray<BDREGraphNode *> *)pointNodes
{
    return [self.andNode pointNodes];
}

- (NSUInteger)minIndex
{
    return self.andNode.minIndex;
}

- (BOOL)canPassWithFootPrint:(BDREGraphFootPrint *)graphFootPrint
{
    return [self.andNode canPassWithFootPrint:graphFootPrint];
}

@end

@implementation BDREAndGraphNode

- (instancetype)init
{
    if (self = [super init]) {
        _leftDelegateNode = [[BDREAndDelegateGraphNode alloc] initWithAndNode:self];
        _rightDelegateNode = [[BDREAndDelegateGraphNode alloc] initWithAndNode:self];
    }
    return self;
}

- (BOOL)canPassWithFootPrint:(BDREGraphFootPrint *)graphFootPrint
{
    return [super canPassWithFootPrint:graphFootPrint] && [self.leftDelegateNode isVisitedWithFootPrint:graphFootPrint] && [self.rightDelegateNode isVisitedWithFootPrint:graphFootPrint];
}

- (void)updateMinIndex:(NSUInteger)index
{
    [super updateMinIndex:index];
    [self.leftDelegateNode updateMinIndex:index];
    [self.rightDelegateNode updateMinIndex:index];
}

@end
