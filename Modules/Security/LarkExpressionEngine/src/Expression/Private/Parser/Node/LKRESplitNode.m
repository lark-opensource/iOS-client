//
//  LKRESplitNode.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "LKRESplitNode.h"

@implementation LKRESplitNode

- (instancetype)initAsSplitNode:(NSString *)originValue index:(NSUInteger)index
{
    self = [super initAsBaseNode:originValue index:index];
    return self;
}

@end

@implementation LKRELeftSplitNode

- (instancetype)initAsSplitNode:(NSString *)originValue index:(NSUInteger)index
{
    self = [super initAsSplitNode:originValue index:index];
    if (self) {
        self.isFunctionStart = false;
    }
    return self;
}

@end

@implementation LKRERightSplitNode

@end

@implementation LKRECenterSplitNode

@end
