//
//  LKRECommand.m
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "LKRECommand.h"

@implementation LKRECommand

- (void)execute:(NSMutableArray *)cmdStack withEnv:(id<LKREExprEnv>)env error:(NSError **)error
{
    NSAssert(false, @"must implementation this function in subclass! %@", NSStringFromClass(self));
}

- (LKREInstruction *)instruction
{
    return nil;
}

@end
