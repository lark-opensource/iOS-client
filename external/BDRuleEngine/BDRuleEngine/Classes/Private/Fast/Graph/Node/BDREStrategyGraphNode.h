//
//  BDREStrategyGraphNode.h
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/13.
//

#import <Foundation/Foundation.h>

#import "BDREGraphNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDREStrategyGraphNode : BDREGraphNode

@property (nonatomic, copy, readonly) NSString *strategyName;

- (instancetype)initWithStrategyName:(NSString *)strategyName;

@end

NS_ASSUME_NONNULL_END
