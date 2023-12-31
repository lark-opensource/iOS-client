//
//  BDREBaseNode.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "BDREBaseNode.h"

@implementation BDREBaseNode

- (instancetype)initAsBaseNode:(NSString *)originValue index:(NSUInteger)index
{
    self = [super init];
    if (self) {
        self.aOriginValue = originValue;
        self.wordIndex = index;
        self.priority = 10;
    }
    return self;
}

@end
