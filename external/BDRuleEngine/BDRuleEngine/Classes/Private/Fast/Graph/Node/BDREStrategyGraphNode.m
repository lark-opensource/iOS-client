//
//  BDREStrategyGraphNode.m
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/13.
//

#import "BDREStrategyGraphNode.h"

@implementation BDREStrategyGraphNode

- (instancetype)initWithStrategyName:(NSString *)strategyName
{
    if (self = [super init]) {
        _strategyName = strategyName;
    }
    return self;
}

- (void)travelWithFootPrint:(BDREGraphFootPrint *)graphFootPrint
{
    [graphFootPrint updateMinIndex:self.minIndex];
    [graphFootPrint addHitStrategy:self];
}

@end
