//
//  LKREFuncNode.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "LKREFuncNode.h"

@interface LKREFuncNode ()

@property (nonatomic, strong) LKREFunc *func;

@end

@implementation LKREFuncNode

- (instancetype)initWithFuncValue:(LKREFunc *)func originValue:(NSString *)originValue index:(NSUInteger)index
{
    self = [super initAsBaseNode:originValue index:index];
    if (self) {
        self.func = func;
        self.priority = 1000;
    }
    return self;
}

- (LKREFunc *)getFunc
{
    return self.func;
}

@end
