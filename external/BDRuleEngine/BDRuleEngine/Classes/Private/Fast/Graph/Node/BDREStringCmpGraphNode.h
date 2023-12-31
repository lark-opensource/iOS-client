//
//  BDREStringCompareGraphNode.h
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/19.
//

#import "BDREGraphNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDREStringCmpGraphNode : BDREGraphNode

- (instancetype)initWithComparedStrs:(NSArray<NSString *> *)comparedStrs;

@end

@interface BDREStartWithGraphNode : BDREStringCmpGraphNode
@end

@interface BDREEndWithGraphNode : BDREStringCmpGraphNode
@end

@interface BDREContainsGraphNode : BDREStringCmpGraphNode
@end

@interface BDREMatchesGraphNode : BDREStringCmpGraphNode
@end

NS_ASSUME_NONNULL_END
