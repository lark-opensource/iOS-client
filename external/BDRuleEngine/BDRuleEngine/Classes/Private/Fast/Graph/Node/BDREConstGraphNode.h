//
//  BDREConstGraphNode.h
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/13.
//

#import <Foundation/Foundation.h>

#import "BDREGraphNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDREConstGraphNode : BDREGraphNode

@property (nonatomic, strong, readonly) id value;

- (instancetype)initWithValue:(id)value;

@end

NS_ASSUME_NONNULL_END
