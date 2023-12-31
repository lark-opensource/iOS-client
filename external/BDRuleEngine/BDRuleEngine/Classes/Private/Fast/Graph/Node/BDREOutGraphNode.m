//
//  BDREOutGraphNode.m
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/17.
//

#import "BDREOutGraphNode.h"

@implementation BDREOutGraphNode

- (BOOL)canPassWithFootPrint:(BDREGraphFootPrint *)graphFootPrint
{
    return graphFootPrint.isFirstTravelFinished && [super canPassWithFootPrint:graphFootPrint] && ![self isVisitedWithFootPrint:graphFootPrint];
}

@end
