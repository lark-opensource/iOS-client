//
//  LKREIdentifierNode.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "LKREIdentifierNode.h"

@implementation LKREIdentifierNode

- (instancetype)initWithIdentifierValue:(id)identifier originValue:(NSString *)originValue index:(NSUInteger)index
{
    self = [super initAsBaseNode:originValue index:index];
    if (self) {
        self.identifier = identifier;
    }
    return self;
}

@end
