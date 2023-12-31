//
//  LKREOperatorNode.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "LKREOperatorNode.h"

@implementation LKREOperatorNode

- (instancetype)initWithOperatorValue:(LKREOperator *)op originValue:(NSString *)originValue index:(NSUInteger)index
{
    self = [super initAsBaseNode:originValue index:index];
    if (self) {
        self.opetator = op;
        self.priority = op.priority;
    }
    return self;
}

@end
