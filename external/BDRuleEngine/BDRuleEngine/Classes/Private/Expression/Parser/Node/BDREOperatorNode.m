//
//  BDREOperatorNode.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "BDREOperatorNode.h"

@implementation BDREOperatorNode

- (instancetype)initWithOperatorValue:(BDREOperator *)op originValue:(NSString *)originValue index:(NSUInteger)index
{
    self = [super initAsBaseNode:originValue index:index];
    if (self) {
        self.opetator = op;
        self.priority = op.priority;
    }
    [BDRuleEngineLogger info:^NSString * _Nonnull{
        return [NSString stringWithFormat:@"[Expression] get op node : [%@], [%@], [%ld]", [self class], op.symbol, index];
    }];
    return self;
}

@end
