//
//  BDREIdentifierNode.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "BDREIdentifierNode.h"

@implementation BDREIdentifierNode

- (instancetype)initWithIdentifierValue:(id)identifier originValue:(NSString *)originValue index:(NSUInteger)index
{
    self = [super initAsBaseNode:originValue index:index];
    if (self) {
        self.identifier = identifier;
    }
    [BDRuleEngineLogger info:^NSString * _Nonnull{
        return [NSString stringWithFormat:@"[Expression] get identifier node : [%@], [%@], [%ld]", [self class], identifier, index];
    }];
    return self;
}

@end
