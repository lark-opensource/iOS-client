//
//  BDREConstNode.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "BDREConstNode.h"

@interface BDREConstNode ()
@property (nonatomic, strong) id constValue;
@end

@implementation BDREConstNode

- (instancetype)initWithConstValue:(id)constValue originValue:(NSString *)originValue index:(NSUInteger)index
{
    self = [super initAsBaseNode:originValue index:index];
    if (self) {
        self.constValue = constValue;
    }
    [BDRuleEngineLogger info:^NSString * _Nonnull{
        return [NSString stringWithFormat:@"[Expression] get const node : [%@], [%@], [%ld]", [self class], constValue, index];
    }];
    return self;
}

- (id)getValue
{
    return self.constValue;
}

@end
