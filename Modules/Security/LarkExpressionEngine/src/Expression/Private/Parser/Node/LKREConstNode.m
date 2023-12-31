//
//  LKREConstNode.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "LKREConstNode.h"

@interface LKREConstNode ()
@property (nonatomic, strong) id constValue;
@end

@implementation LKREConstNode

- (instancetype)initWithConstValue:(id)constValue originValue:(NSString *)originValue index:(NSUInteger)index
{
    self = [super initAsBaseNode:originValue index:index];
    if (self) {
        self.constValue = constValue;
    }
    return self;
}

- (id)getValue
{
    return self.constValue;
}

@end
