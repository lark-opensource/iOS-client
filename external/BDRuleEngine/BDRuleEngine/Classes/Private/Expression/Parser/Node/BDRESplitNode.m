//
//  BDRESplitNode.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "BDRESplitNode.h"

@implementation BDRESplitNode

- (instancetype)initAsSplitNode:(NSString *)originValue index:(NSUInteger)index
{
    self = [super initAsBaseNode:originValue index:index];
    if (self) {
        [BDRuleEngineLogger info:^NSString * _Nonnull{
            return [NSString stringWithFormat:@"[Expression] get split node : %@", [self class]];
        }];
    }
    return self;
}

@end

@implementation BDRELeftSplitNode

- (instancetype)initAsSplitNode:(NSString *)originValue index:(NSUInteger)index
{
    self = [super initAsSplitNode:originValue index:index];
    if (self) {
        self.isFunctionStart = false;
    }
    return self;
}

@end

@implementation BDRERightSplitNode

@end

@implementation BDRECenterSplitNode

@end
